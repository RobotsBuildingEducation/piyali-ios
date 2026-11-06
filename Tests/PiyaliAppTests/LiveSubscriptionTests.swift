import XCTest
@testable import Piyali

@MainActor final class LiveSubscriptionTests:XCTestCase {
 func testFreshNativeKeyRestoreAndSignedOAuthStartWithoutConnectingOrPaying()async throws{
  let env=ProcessInfo.processInfo.environment;guard env["PIYALI_LIVE_SUBSCRIPTION_TESTS"] == "1",env["PIYALI_LIVE_API_TESTS"] == "1",env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Opt-in isolated signed Patreon API check required")}
  let identity=IdentityService();try identity.create();defer{try? identity.disconnect()};let service=SubscriptionService();service.bind(identity);service.updatePracticeXP(300)
  try await service.restoreWeb();XCTAssertFalse(service.webAuthorized);XCTAssertFalse(service.statusPayload["linked"].boolean);XCTAssertFalse(service.hasAccess)
  await service.connect(language:"ar");XCTAssertNil(service.error);let browser=try XCTUnwrap(service.browser);XCTAssertEqual(browser.url.host,"www.patreon.com");XCTAssertFalse(browser.url.absoluteString.contains("nsec"));XCTAssertFalse(service.webAuthorized)
  // The Safari controller is never mounted. No Patreon login, account link,
  // checkout, membership move or payment is performed; OAuth state expires.
 }
}
