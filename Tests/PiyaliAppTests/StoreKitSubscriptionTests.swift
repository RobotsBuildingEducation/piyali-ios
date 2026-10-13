import XCTest
import StoreKit
import StoreKitTest
import Combine
@testable import Piyali

private final class UnavailableWebSubscriptionProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let response = HTTPURLResponse(url:request.url!,statusCode:503,httpVersion:nil,headerFields:["Content-Type":"application/json"])!
        client?.urlProtocol(self,didReceive:response,cacheStoragePolicy:.notAllowed)
        client?.urlProtocol(self,didLoad:Data("{\"error\":\"Web service unavailable in local testing\"}".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
private final class AuthorizedWebSubscriptionProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let challenge = String(repeating:"c",count:32), content = "Authorize Piyali Patreon restore: " + String(repeating:"n",count:43)
        var status = 200
        let value: [String:Any]
        if request.url?.lastPathComponent == "link-challenge" {
            value = ["challengeId":challenge,"eventTemplate":["kind":27235,"created_at":Int64(Date().timeIntervalSince1970),"tags":[["action","restore"],["challenge",challenge],["expires",WebProgressContract.iso(Date().addingTimeInterval(120))]],"content":content]]
        } else {
            var data = request.httpBody
            if data == nil, let stream = request.httpBodyStream {
                stream.open(); defer { stream.close() }
                var bytes = Data(), buffer = [UInt8](repeating:0,count:4096)
                while stream.hasBytesAvailable && bytes.count <= 65536 { let count = stream.read(&buffer,maxLength:buffer.count); if count <= 0 { break }; bytes.append(contentsOf:buffer.prefix(count)) }
                data = bytes
            }
            let payload = data.flatMap { try? JSONDecoder().decode(RestoreRequest.self,from:$0) }
            let valid = payload.map { $0.challengeId == challenge && $0.signedEvent.kind == 27235 && $0.signedEvent.content == content && $0.signedEvent.tag("action") == "restore" && $0.signedEvent.tag("challenge") == challenge && IdentityService.verify($0.signedEvent) } ?? false
            status = valid ? 200 : 401; value = valid ? ["authorized":true] : ["error":"Invalid test proof"]
        }
        let response = HTTPURLResponse(url:request.url!,statusCode:status,httpVersion:nil,headerFields:["Content-Type":"application/json"])!
        client?.urlProtocol(self,didReceive:response,cacheStoragePolicy:.notAllowed)
        client?.urlProtocol(self,didLoad:try! JSONSerialization.data(withJSONObject:value)); client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
    private struct RestoreRequest: Decodable { let challengeId: String; let signedEvent: NostrEventPayload }
}
@MainActor final class StoreKitSubscriptionTests: XCTestCase {
    private func context() async throws -> (SKTestSession,SubscriptionService,IdentityService) {
        guard ProcessInfo.processInfo.environment["PIYALI_STOREKIT_TESTS"] == "1",
              ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",
              UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { throw XCTSkip("Run scripts/test-storekit.sh for isolated local StoreKit transactions.") }
        let file = try XCTUnwrap(Bundle(for:Self.self).url(forResource:"PiyaliSubscriptions",withExtension:"storekit"))
        let session = try SKTestSession(contentsOf:file)
        session.resetToDefaultState(); session.clearTransactions(); session.disableDialogs = true; session.timeRate = .realTime
        let identity = IdentityService(); try identity.create()
        let config = URLSessionConfiguration.ephemeral; config.protocolClasses = [UnavailableWebSubscriptionProtocol.self]
        let service = SubscriptionService(webSession:URLSession(configuration:config)); service.bind(identity)
        try await service.loadAppleProducts()
        XCTAssertEqual(Set(service.products.map(\.id)),["app.piyali.ios.monthly","app.piyali.ios.annual"])
        return (session,service,identity)
    }
    private func product(_ service: SubscriptionService, _ id: String = "app.piyali.ios.monthly") throws -> Product { try XCTUnwrap(service.products.first { $0.id == id }) }
    func testPurchaseAndRestoreUseVerifiedStoreKitEntitlementAndNostrAccountToken() async throws {
        let (session,service,identity) = try await context()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        XCTAssertFalse(service.hasAccess)
        await service.buy(try product(service))
        XCTAssertNil(service.error); XCTAssertTrue(service.appleAuthorized); XCTAssertTrue(service.authorized); XCTAssertTrue(service.hasAccess)
        let transaction = try XCTUnwrap(session.allTransactions().first)
        XCTAssertEqual(transaction.productIdentifier,"app.piyali.ios.monthly")
        var matched = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let value) = entitlement, value.productID == transaction.productIdentifier { XCTAssertEqual(value.appAccountToken,identity.accountToken); XCTAssertEqual(value.environment,.xcode); matched = true }
        }
        XCTAssertTrue(matched)
        let restored = SubscriptionService(); restored.bind(identity)
        try await restored.restoreApple()
        XCTAssertTrue(restored.appleAuthorized); XCTAssertTrue(restored.hasAccess)
    }
    func testDifferentNostrKeyCannotClaimExistingApplePurchase() async throws {
        let (session,service,identity) = try await context()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        await service.buy(try product(service)); XCTAssertTrue(service.hasAccess)
        let original = identity.exportKey(); try identity.create(); service.bind(identity)
        await service.refreshApple(); XCTAssertFalse(service.appleAuthorized); XCTAssertFalse(service.hasAccess)
        try identity.importKey(original); service.bind(identity)
        try await service.restoreApple(); XCTAssertTrue(service.hasAccess)
    }
    func testExpiredSubscriptionLosesAccess() async throws {
        let (session,service,_) = try await context()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        await service.buy(try product(service)); XCTAssertTrue(service.hasAccess)
        let expired = expectation(description:"Expiration update removes access")
        let observer = service.$authorized.filter { !$0 }.prefix(1).sink { _ in expired.fulfill() }
        try session.expireSubscription(productIdentifier:"app.piyali.ios.monthly")
        await fulfillment(of:[expired],timeout:10); observer.cancel(); service.checkExpiry()
        XCTAssertFalse(service.appleAuthorized); XCTAssertFalse(service.authorized); XCTAssertFalse(service.hasAccess)
    }
    func testRefundRevokesAccess() async throws {
        let (session,service,_) = try await context()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        await service.buy(try product(service)); XCTAssertTrue(service.hasAccess)
        let refunded = expectation(description:"Refund update removes access")
        let observer = service.$authorized.filter { !$0 }.prefix(1).sink { _ in refunded.fulfill() }
        try session.refundTransaction(identifier:try XCTUnwrap(session.allTransactions().first).identifier)
        await fulfillment(of:[refunded],timeout:10); observer.cancel(); XCTAssertFalse(service.appleAuthorized); XCTAssertFalse(service.hasAccess)
    }
    func testPendingAskToBuyUnlocksOnlyAfterApprovalUpdate() async throws {
        let (session,service,_) = try await context()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        session.askToBuyEnabled = true
        await service.buy(try product(service)); XCTAssertFalse(service.hasAccess); XCTAssertEqual(service.error,"Purchase pending approval.")
        let pending = try XCTUnwrap(session.allTransactions().first { $0.pendingAskToBuyConfirmation })
        let approved = expectation(description:"Verified transaction update grants access")
        let observer = service.$authorized.filter { $0 }.prefix(1).sink { _ in approved.fulfill() }
        try session.approveAskToBuyTransaction(identifier:pending.identifier)
        await fulfillment(of:[approved],timeout:10); observer.cancel()
        XCTAssertTrue(service.appleAuthorized); XCTAssertTrue(service.hasAccess); XCTAssertNil(service.error)
    }
    func testAppleRestoreSucceedsWhenWebProviderIsUnavailable() async throws {
        let (session,service,_) = try await context()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        await service.buy(try product(service))
        await service.restore()
        XCTAssertTrue(service.appleAuthorized); XCTAssertTrue(service.hasAccess); XCTAssertFalse(service.webAuthorized); XCTAssertNil(service.error)
    }
    func testAnnualSubscriptionGrantsSameNativeAccess() async throws {
        let (session,service,_) = try await context()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        await service.buy(try product(service,"app.piyali.ios.annual"))
        XCTAssertTrue(service.hasAccess); XCTAssertNil(service.error)
        XCTAssertEqual(session.allTransactions().first?.productIdentifier,"app.piyali.ios.annual")
    }
    func testUnconfiguredPlanCannotStartPurchase() async throws {
        let (session,source,identity) = try await context()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        let restricted = SubscriptionService(configuration:AppConfiguration(values:["SubscriptionProductIDs":["unconfigured.plan"]]))
        restricted.bind(identity); await restricted.buy(try product(source))
        XCTAssertFalse(restricted.hasAccess); XCTAssertTrue(session.allTransactions().isEmpty)
        XCTAssertEqual(restricted.error,"This subscription plan is unavailable.")
    }
    func testUnverifiedApplePurchaseCannotUnlockApp() async throws {
        let (session,service,_) = try await context()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        try await session.setSimulatedError(.verification(.invalidSignature),forAPI:.verification)
        await service.buy(try product(service))
        XCTAssertFalse(service.appleAuthorized); XCTAssertFalse(service.authorized); XCTAssertFalse(service.hasAccess)
        XCTAssertEqual(service.error,"Apple could not verify this purchase.")
    }
    func testSignedWebRestoreWorksWhenAppleSyncIsUnavailable() async throws {
        let (session,_,identity) = try await context()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        let config = URLSessionConfiguration.ephemeral; config.protocolClasses = [AuthorizedWebSubscriptionProtocol.self]
        let service = SubscriptionService(webSession:URLSession(configuration:config)); service.bind(identity)
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))),forAPI:.appStoreSync)
        await service.restore()
        XCTAssertFalse(service.appleAuthorized); XCTAssertTrue(service.webAuthorized); XCTAssertTrue(service.authorized); XCTAssertTrue(service.hasAccess); XCTAssertNil(service.error)
    }
    func testBothUnavailableProvidersKeepPaywallAndReportFailures() async throws {
        let (session,service,_) = try await context()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))),forAPI:.appStoreSync)
        await service.restore()
        XCTAssertFalse(service.authorized); XCTAssertFalse(service.hasAccess); XCTAssertFalse(service.busy)
        XCTAssertTrue(service.error?.contains("Apple:") == true); XCTAssertTrue(service.error?.contains("Web:") == true)
    }

}
