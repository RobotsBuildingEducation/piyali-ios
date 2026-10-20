import XCTest
import CryptoKit
import NostrSDK
import CashuSwift
import secp256k1
import Bolt11
@testable import Piyali

@MainActor final class WalletFixtureMint:WalletMintNetworking {
    let invoice="lnbc2500u1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpu9qrsgquk0rl77nj30yxdy8j9vdx85fkpmdla2087ne0xh8nhedh8w27kyke0lp53ut353s06fv3qfegext0eh0ymjpf39tuven09sam30g4vgpfna3rh"
    var date:Date { Date(timeIntervalSince1970:Double(try! Bolt11Decoder.decode(invoice).timestamp)+1) }
    var paid=false,issued=false,loseResponse=false,delayQuote=false,v2=false
    var mintCalls=0,quoteCalls=0,restoreCalls=0
    private let key=try! secp256k1.Signing.PrivateKey(dataRepresentation:Data(repeating:1,count:32))
    private var issuedOutputs:[String:(CashuSwift.Output,CashuSwift.Promise)]=[:]
    func loadMint(_ value:String) async throws -> CashuSwift.Mint {
        let amounts=(0..<20).map { 1 << $0 },publicKey=CashuMintBatch.hex(key.publicKey.dataRepresentation),keys=Dictionary(uniqueKeysWithValues:amounts.map { (String($0),publicKey) })
        let raw=try amounts.reduce(into:Data()) { bytes,amount in bytes.append(try CashuMintBatch.bytes(keys[String(amount)]!)) }
        let id=v2 ? "01"+CashuMintBatch.hex(Data(SHA256.hash(data:Data((amounts.map { "\($0):\(publicKey)" }.joined(separator:",")+"|unit:sat").utf8)))) : "00"+CashuMintBatch.hex(Data(SHA256.hash(data:raw))).prefix(14)
        let keyset=try JSONDecoder().decode(CashuSwift.Keyset.self,from:JSONSerialization.data(withJSONObject:["id":id,"unit":"sat","active":true,"keys":keys]))
        return CashuSwift.Mint(url:URL(string:value)!,keysets:[keyset])
    }
    func states(_ proofs:[CashuSwift.Proof],mint:CashuSwift.Mint) async throws -> [CashuSwift.Proof.ProofState] { proofs.map { _ in .unspent } }
    private func issue(_ output:CashuSwift.Output) throws -> CashuSwift.Promise {
        let B=try secp256k1.Signing.PublicKey(dataRepresentation:CashuMintBatch.bytes(output.B_),format:.compressed),C=try B.multiply(Array(key.dataRepresentation)),nonce=try secp256k1.Signing.PrivateKey()
        let points=[nonce.publicKey,try B.multiply(Array(nonce.dataRepresentation)),key.publicKey,C]
        let e=Data(SHA256.hash(data:Data(points.map { CashuMintBatch.hex($0.uncompressedRepresentation) }.joined().utf8))),s=try key.multiply(Array(e)).add(Array(nonce.dataRepresentation))
        return try JSONDecoder().decode(CashuSwift.Promise.self,from:JSONSerialization.data(withJSONObject:["id":output.id,"amount":output.amount,"C_":CashuMintBatch.hex(C.dataRepresentation),"dleq":["e":CashuMintBatch.hex(e),"s":CashuMintBatch.hex(s.dataRepresentation)]]))
    }
    private func json<T:Encodable>(_ value:T) throws -> JSONValue { try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(value)) }
    func request(mint:String,path:String,body:JSONValue?) async throws -> JSONValue {
        if path == "v1/mint/quote/bolt11",body != nil { quoteCalls += 1;if delayQuote { try await Task.sleep(for:.milliseconds(150)) };return .object(["quote":.string("local-quote"),"request":.string(invoice),"unit":.string("sat"),"amount":.number(250000),"state":.string("UNPAID"),"expiry":.number(date.timeIntervalSince1970+30)]) }
        if path == "v1/mint/quote/bolt11/local-quote" { return .object(["quote":.string("local-quote"),"state":.string(issued ? "ISSUED" : paid ? "PAID" : "UNPAID")]) }
        if path == "v1/mint/bolt11",let body {
            mintCalls += 1;guard paid,!issued else { throw URLError(.badServerResponse) }
            let outputs=try JSONDecoder().decode([CashuSwift.Output].self,from:JSONEncoder().encode(body["outputs"]))
            var signatures:[CashuSwift.Promise]=[]
            for output in outputs { let signature=try issue(output);issuedOutputs[output.B_]=(output,signature);signatures.append(signature) };issued=true
            if loseResponse { loseResponse=false;throw URLError(.networkConnectionLost) }
            return .object(["signatures":try json(signatures)])
        }
        if path == "v1/restore",let body {
            restoreCalls += 1;let outputs=try JSONDecoder().decode([CashuSwift.Output].self,from:JSONEncoder().encode(body["outputs"]))
            let known=outputs.compactMap { issuedOutputs[$0.B_] }.reversed()
            return .object(["outputs":try json(known.map { $0.0 }),"signatures":try json(known.map { $0.1 })])
        }
        XCTFail("Unexpected fixture mint endpoint: "+path);throw URLError(.unsupportedURL)
    }
}
@MainActor final class WalletServiceTests:XCTestCase {
    private func identity() throws -> IdentityService {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { throw XCTSkip("Run with an isolated test identity.") }
        let identity=IdentityService();try identity.create();return identity
    }
    private func relay(reject:@escaping (Int)->Bool = { _ in false }) async throws -> LocalNostrRelay {
        let relay=LocalNostrRelay();var events:[[String:Any]]=[]
        try await relay.start { frame,connection in
            if frame.first as? String == "REQ",let subscription=frame[1] as? String { for event in events { relay.send(["EVENT",subscription,event],to:connection) };relay.send(["EOSE",subscription],to:connection) }
            else if frame.first as? String == "EVENT",let event=frame[1] as? [String:Any],let id=event["id"] as? String { if !events.contains(where:{ $0["id"] as? String == id }) { events.append(event) };relay.send(["OK",id,!reject(event["kind"] as? Int ?? 0),"local fixture"],to:connection) }
        };return relay
    }
    func testCreateEncryptsSeparateWalletKeyAndDepositResumesAcrossServiceRestart() async throws {
        let identity=try identity(),owner=identity.hex,mint=WalletFixtureMint(),relay=try await relay();defer { relay.stop();try? WalletVault().removeTestState(owner:owner);try? identity.disconnect() }
        let client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2)),service=WalletService(client:client,mint:mint,now:{ mint.date })
        try await service.refresh(identity:identity);XCTAssertTrue(service.canCreate);try await service.create(identity:identity);XCTAssertTrue(service.ready)
        let wallet=try XCTUnwrap(WalletVault().load(owner:owner));XCTAssertNotEqual(wallet.walletPrivateKey,identity.keypair?.privateKey.hex);XCTAssertNotEqual(Keypair(hex:wallet.walletPrivateKey)?.publicKey.hex,owner)
        let events=relay.frames().filter { $0.first as? String == "EVENT" }.compactMap { $0[1] as? [String:Any] };XCTAssertEqual(events.count,2);XCTAssertFalse(events.contains { ($0["content"] as? String ?? "").contains(wallet.walletPrivateKey) })
        try await service.deposit(amount:250000,identity:identity);XCTAssertEqual(service.invoice,mint.invoice);XCTAssertEqual(mint.quoteCalls,1)
        let restarted=WalletService(client:client,mint:mint,now:{ mint.date });try await restarted.refresh(identity:identity);XCTAssertEqual(restarted.invoice,mint.invoice)
        try await restarted.deposit(amount:250000,identity:identity);XCTAssertEqual(mint.quoteCalls,1)
        try await restarted.checkDeposit(identity:identity);XCTAssertEqual(mint.mintCalls,0)
        mint.paid=true;try await restarted.checkDeposit(identity:identity);XCTAssertEqual(restarted.balance,250000);XCTAssertFalse(restarted.pending);XCTAssertTrue(restarted.invoice.isEmpty)
        try await restarted.checkDeposit(identity:identity);XCTAssertEqual(mint.mintCalls,1)
        let final=WalletService(client:client,mint:mint,now:{ mint.date });try await final.refresh(identity:identity);XCTAssertEqual(final.balance,250000)
        let stored=try XCTUnwrap(WalletVault().load(owner:owner));XCTAssertNil(stored.pending);XCTAssertEqual(try stored.ledger.balance(mint:WalletContract.defaultMint),250000)
    }
    func testMintedTokensSurviveLostHTTPResponseAndRecoverWithoutAnotherMint() async throws {
        let identity=try identity(),owner=identity.hex,mint=WalletFixtureMint(),relay=try await relay();defer { relay.stop();try? WalletVault().removeTestState(owner:owner);try? identity.disconnect() }
        mint.v2=true
        let client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2)),service=WalletService(client:client,mint:mint,now:{ mint.date })
        try await service.refresh(identity:identity);try await service.create(identity:identity);try await service.deposit(amount:250000,identity:identity)
        mint.paid=true;mint.loseResponse=true
        do { try await service.checkDeposit(identity:identity);XCTFail("The simulated lost response was not surfaced") } catch { }
        let pending=try XCTUnwrap(WalletVault().load(owner:owner)?.pending);XCTAssertEqual(pending.phase,.submitted);XCTAssertFalse(pending.batch.secrets.isEmpty);XCTAssertEqual(mint.mintCalls,1)
        let restarted=WalletService(client:client,mint:mint,now:{ mint.date });try await restarted.refresh(identity:identity);try await restarted.checkDeposit(identity:identity)
        XCTAssertEqual(restarted.balance,250000);XCTAssertFalse(restarted.pending);XCTAssertEqual(mint.restoreCalls,1);XCTAssertEqual(mint.mintCalls,1)
        try await restarted.checkDeposit(identity:identity);XCTAssertEqual(mint.restoreCalls,1)
    }
    func testExpiredQuoteIsRetainedAndLatePaymentCanBeRecoveredFromArchive() async throws {
        let identity=try identity(),owner=identity.hex,mint=WalletFixtureMint(),relay=try await relay();defer { relay.stop();try? WalletVault().removeTestState(owner:owner);try? identity.disconnect() }
        var clock=mint.date
        let service=WalletService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)),mint:mint,now:{ clock })
        try await service.refresh(identity:identity);try await service.create(identity:identity);try await service.deposit(amount:250000,identity:identity)
        clock=clock.addingTimeInterval(100000);try await service.checkDeposit(identity:identity)
        XCTAssertFalse(service.invoice.isEmpty);XCTAssertTrue(service.invoiceExpired);try await service.archiveInvoice(identity:identity);XCTAssertTrue(service.invoice.isEmpty);XCTAssertEqual(service.archivedCount,1)
        mint.paid=true;try await service.checkArchived(identity:identity);XCTAssertFalse(service.invoice.isEmpty);XCTAssertEqual(service.archivedCount,0)
        try await service.checkDeposit(identity:identity);XCTAssertEqual(service.balance,250000);XCTAssertEqual(mint.mintCalls,1)
    }
    func testRelayAcknowledgmentFailureKeepsMintedProofsAndRetriesOnlyTheOutbox() async throws {
        var refuseHistory=true
        let identity=try identity(),owner=identity.hex,mint=WalletFixtureMint(),relay=try await relay(reject:{ $0 == 7376 && refuseHistory });defer { relay.stop();try? WalletVault().removeTestState(owner:owner);try? identity.disconnect() }
        let client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2)),service=WalletService(client:client,mint:mint,now:{ mint.date })
        try await service.refresh(identity:identity);try await service.create(identity:identity);try await service.deposit(amount:250000,identity:identity);mint.paid=true
        do { try await service.checkDeposit(identity:identity);XCTFail("Rejected history should leave a pending outbox") } catch { }
        let pending=try XCTUnwrap(WalletVault().load(owner:owner)?.pending);XCTAssertEqual(pending.phase,.publishing);XCTAssertFalse(pending.received!.isEmpty);XCTAssertEqual(pending.acknowledged.count,1)
        refuseHistory=false
        let restarted=WalletService(client:client,mint:mint,now:{ mint.date });try await restarted.refresh(identity:identity);try await restarted.checkDeposit(identity:identity)
        XCTAssertEqual(restarted.balance,250000);XCTAssertFalse(restarted.pending);XCTAssertEqual(mint.mintCalls,1)
        let tokens=relay.frames().filter { $0.first as? String == "EVENT" }.compactMap { $0[1] as? [String:Any] }.filter { $0["kind"] as? Int == 7375 };XCTAssertEqual(tokens.count,1)
    }
    func testRelayListAloneDoesNotBlockCreationButLegacyWalletIsNotOverwritten() async throws {
        let identity=try identity(),owner=identity.hex,mint=WalletFixtureMint(),relay=try await relay();defer { relay.stop();try? WalletVault().removeTestState(owner:owner);try? identity.disconnect() }
        let client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2))
        try await client.publish(identity.sign(kind:10002,tags:[["r","wss://relay.example"]],content:""))
        let service=WalletService(client:client,mint:mint,now:{ mint.date });try await service.refresh(identity:identity);XCTAssertTrue(service.canCreate)
        try await client.publish(identity.sign(kind:37513,tags:[],content:"legacy fixture"));do { try await service.create(identity:identity);XCTFail("A wallet created after discovery was overwritten") } catch { };XCTAssertNil(try WalletVault().load(owner:owner));try await service.refresh(identity:identity);XCTAssertFalse(service.canCreate);XCTAssertFalse(service.ready);XCTAssertNil(try WalletVault().load(owner:owner))
    }
    func testTwoServiceInstancesCannotOverwriteAConcurrentDepositOrUseAStaleSnapshot() async throws {
        let identity=try identity(),owner=identity.hex,mint=WalletFixtureMint(),relay=try await relay();defer { relay.stop();try? WalletVault().removeTestState(owner:owner);try? identity.disconnect() }
        let client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2)),first=WalletService(client:client,mint:mint,now:{ mint.date }),second=WalletService(client:client,mint:mint,now:{ mint.date })
        try await first.refresh(identity:identity);try await first.create(identity:identity);try await second.refresh(identity:identity);mint.delayQuote=true
        let request=Task { try await first.deposit(amount:250000,identity:identity) }
        for _ in 0..<100 where mint.quoteCalls == 0 { try await Task.sleep(for:.milliseconds(5)) };XCTAssertEqual(mint.quoteCalls,1)
        do { try await second.deposit(amount:250000,identity:identity);XCTFail("Concurrent wallet operation was allowed") } catch { }
        try await request.value;try await second.deposit(amount:250000,identity:identity)
        XCTAssertEqual(mint.quoteCalls,1);XCTAssertEqual(second.invoice,mint.invoice)
    }
    func testInvoiceAmountSignatureAndExpiryAreValidated() throws {
        let mint=WalletFixtureMint(),quote:JSONValue = .object(["quote":.string("local-quote"),"request":.string(mint.invoice)])
        XCTAssertNoThrow(try CashuHTTPClient.validateQuote(quote,amount:250000,now:mint.date))
        XCTAssertThrowsError(try CashuHTTPClient.validateQuote(quote,amount:10,now:mint.date))
        XCTAssertThrowsError(try CashuHTTPClient.validateQuote(quote,amount:250000,now:Date()))
        XCTAssertThrowsError(try CashuHTTPClient.validateQuote(quote.setting("request",.string(String(mint.invoice.dropLast())+"q")),amount:250000,now:mint.date))
    }
}
