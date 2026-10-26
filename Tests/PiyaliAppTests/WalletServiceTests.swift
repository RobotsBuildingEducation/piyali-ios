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
    var mintCalls=0,quoteCalls=0,restoreCalls=0,swapCalls=0
    var inputFeePPK=0,loseSwapResponse=false,supportsLock=true,delayInfo=false
    var infoCalls=0
    private var spent=Set<String>()
    private let key=try! secp256k1.Signing.PrivateKey(dataRepresentation:Data(repeating:1,count:32))
    private var issuedOutputs:[String:(CashuSwift.Output,CashuSwift.Promise)]=[:]
    func loadMint(_ value:String) async throws -> CashuSwift.Mint {
        let amounts=(0..<20).map { 1 << $0 },publicKey=CashuMintBatch.hex(key.publicKey.dataRepresentation),keys=Dictionary(uniqueKeysWithValues:amounts.map { (String($0),publicKey) })
        let raw=try amounts.reduce(into:Data()) { bytes,amount in bytes.append(try CashuMintBatch.bytes(keys[String(amount)]!)) }
        let id=v2 ? "01"+CashuMintBatch.hex(Data(SHA256.hash(data:Data((amounts.map { "\($0):\(publicKey)" }.joined(separator:",")+"|unit:sat"+(inputFeePPK == 0 ? "" : "|input_fee_ppk:\(inputFeePPK)")).utf8)))) : "00"+CashuMintBatch.hex(Data(SHA256.hash(data:raw))).prefix(14)
        let keyset=try JSONDecoder().decode(CashuSwift.Keyset.self,from:JSONSerialization.data(withJSONObject:["id":id,"unit":"sat","active":true,"keys":keys,"input_fee_ppk":inputFeePPK]))
        return CashuSwift.Mint(url:URL(string:value)!,keysets:[keyset])
    }
    func states(_ proofs:[CashuSwift.Proof],mint:CashuSwift.Mint) async throws -> [CashuSwift.Proof.ProofState] { proofs.map { spent.contains($0.secret) ? .spent : .unspent } }
    private func issue(_ output:CashuSwift.Output) throws -> CashuSwift.Promise {
        let B=try secp256k1.Signing.PublicKey(dataRepresentation:CashuMintBatch.bytes(output.B_),format:.compressed),C=try B.multiply(Array(key.dataRepresentation)),nonce=try secp256k1.Signing.PrivateKey()
        let points=[nonce.publicKey,try B.multiply(Array(nonce.dataRepresentation)),key.publicKey,C]
        let e=Data(SHA256.hash(data:Data(points.map { CashuMintBatch.hex($0.uncompressedRepresentation) }.joined().utf8))),s=try key.multiply(Array(e)).add(Array(nonce.dataRepresentation))
        return try JSONDecoder().decode(CashuSwift.Promise.self,from:JSONSerialization.data(withJSONObject:["id":output.id,"amount":output.amount,"C_":CashuMintBatch.hex(C.dataRepresentation),"dleq":["e":CashuMintBatch.hex(e),"s":CashuMintBatch.hex(s.dataRepresentation)]]))
    }
    private func json<T:Encodable>(_ value:T) throws -> JSONValue { try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(value)) }
    private func hashToCurve(_ secret:String) throws -> secp256k1.Signing.PublicKey {
        let message=Data(SHA256.hash(data:Data("Secp256k1_HashToCurve_Cashu_".utf8)+Data(secret.utf8)))
        for counter in UInt32(0)..<65536 {
            var little=counter.littleEndian;let bytes=withUnsafeBytes(of:&little) { Data($0) },hash=Data(SHA256.hash(data:message+bytes))
            if let point=try? secp256k1.Signing.PublicKey(dataRepresentation:Data([2])+hash,format:.compressed) { return point }
        };throw URLError(.cannotDecodeContentData)
    }
    func request(mint:String,path:String,body:JSONValue?) async throws -> JSONValue {
        if path == "v1/info" { infoCalls += 1;if delayInfo { try await Task.sleep(for:.milliseconds(150)) };return .object(["nuts":.object(["11":.object(["supported":.bool(supportsLock)]),"12":.object(["supported":.bool(true)]),"9":.object(["supported":.bool(true)])])]) }
        if path == "v1/swap",let body {
            swapCalls += 1
            let inputs=try JSONDecoder().decode([CashuSwift.Proof].self,from:JSONEncoder().encode(body["inputs"])),outputs=try JSONDecoder().decode([CashuSwift.Output].self,from:JSONEncoder().encode(body["outputs"]))
            guard !inputs.isEmpty,Set(inputs.map(\.secret)).count == inputs.count,inputs.allSatisfy({ !spent.contains($0.secret) }),outputs.reduce(0,{ $0+$1.amount }) == inputs.reduce(0,{ $0+$1.amount })-(inputs.count*inputFeePPK+999)/1000 else { throw URLError(.badServerResponse) }
            for proof in inputs {
                let expected=try hashToCurve(proof.secret).multiply(Array(key.dataRepresentation));guard CashuMintBatch.hex(expected.dataRepresentation) == proof.C else { throw URLError(.cannotDecodeContentData) }
                if let parsed=try? JSONDecoder().decode(JSONValue.self,from:Data(proof.secret.utf8)),parsed.array.first?.string == "P2PK" {
                    let publicKey=try secp256k1.Schnorr.PublicKey(dataRepresentation:CashuMintBatch.bytes(parsed.array[1]["data"].string),format:.compressed),witness=try JSONDecoder().decode(JSONValue.self,from:Data((proof.witness ?? "").utf8))
                    guard witness["signatures"].array.count == 1 else { throw URLError(.userAuthenticationRequired) }
                    let signature=try secp256k1.Schnorr.SchnorrSignature(dataRepresentation:CashuMintBatch.bytes(witness["signatures"].array[0].string))
                    guard publicKey.xonly.isValidSignature(signature,for:Data(proof.secret.utf8)) else { throw URLError(.userAuthenticationRequired) }
                }
            }
            let signatures=try outputs.map(issue)
            for (output,signature) in zip(outputs,signatures) { issuedOutputs[output.B_]=(output,signature) };spent.formUnion(inputs.map(\.secret))
            if loseSwapResponse { loseSwapResponse=false;throw URLError(.networkConnectionLost) }
            return .object(["signatures":try json(signatures)])
        }
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
    private func browserEvent(_ identity:IdentityService,kind:Int,keys:[String],client:NostrRelayClient) async throws {
        let tags=keys.map { ["privkey",$0] }+[["mint",WalletContract.defaultMint]]
        let payload=JSONValue.array(tags.map { .array($0.map(JSONValue.string)) })
        let content=try await identity.encryptWallet(payload.json,expectedAuthor:identity.hex)
        try await client.publish(identity.sign(kind:kind,tags:[],content:content))
    }
    func testBrowserBackupRetainsAllKeysAndOnlyPublishesAfterExplicitRestore() async throws {
        let identity=try identity(),owner=identity.hex,mint=WalletFixtureMint(),relay=try await relay();defer { relay.stop();try? WalletVault().removeTestState(owner:owner);try? identity.disconnect() }
        let client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2)),keys=(0..<3).map { _ in Keypair()!.privateKey.hex }
        try await browserEvent(identity,kind:375,keys:keys,client:client)
        let service=WalletService(client:client,mint:mint,now:{ mint.date });try await service.refresh(identity:identity)
        XCTAssertTrue(service.canRestore);XCTAssertFalse(service.canCreate);XCTAssertFalse(service.ready)
        let before=try XCTUnwrap(WalletVault().load(owner:owner));XCTAssertEqual(Set([before.walletPrivateKey]+(before.additionalReceivingKeys ?? [])),Set(keys))
        XCTAssertEqual(relay.frames().filter { $0.first as? String == "EVENT" }.count,1)
        try await service.restoreBrowserWallet(identity:identity);XCTAssertTrue(service.ready);XCTAssertFalse(service.canRestore);XCTAssertFalse(service.needsReceivingInfo)
        let saved=try XCTUnwrap(WalletVault().load(owner:owner));XCTAssertEqual(saved.walletPrivateKey,before.walletPrivateKey)
        let config=try XCTUnwrap(relay.frames().filter { $0.first as? String == "EVENT" }.compactMap { $0[1] as? [String:Any] }.first { $0["kind"] as? Int == 17375 })
        let clear=try await identity.decryptWallet(try XCTUnwrap(config["content"] as? String),expectedAuthor:owner)
        XCTAssertEqual(Set(try ImportedWalletConfiguration(JSONDecoder().decode(JSONValue.self,from:Data(clear.utf8))).privateKeys),Set(keys))
        try WalletVault().removeTestState(owner:owner)
        let restarted=WalletService(client:client,mint:mint,now:{ mint.date });try await restarted.refresh(identity:identity);XCTAssertTrue(restarted.ready)
        XCTAssertEqual(Set(try XCTUnwrap(WalletVault().load(owner:owner)).additionalReceivingKeys ?? []),Set(keys.filter { $0 != saved.walletPrivateKey }))
    }
    func testBrowserQuoteWithoutInvoiceCanRecoverPaidDepositExactlyOnce() async throws {
        let identity=try identity(),owner=identity.hex,mint=WalletFixtureMint(),relay=try await relay();defer { relay.stop();try? WalletVault().removeTestState(owner:owner);try? identity.disconnect() }
        let client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2)),payload:JSONValue = .object(["quoteId":.string("local-quote"),"mint":.string(WalletContract.defaultMint),"amount":.number(250000),"unit":.string("sat")])
        let clear=try await identity.encryptWallet(payload.json,expectedAuthor:owner);try await client.publish(identity.sign(kind:7374,tags:[],content:clear))
        let service=WalletService(client:client,mint:mint,now:{ mint.date });try await service.refresh(identity:identity)
        XCTAssertTrue(service.canRestore);XCTAssertEqual(service.archivedCount,1);XCTAssertEqual(mint.quoteCalls,0);XCTAssertEqual(mint.mintCalls,0)
        try await service.restoreBrowserWallet(identity:identity);try await service.checkArchived(identity:identity);XCTAssertTrue(service.depositID.isEmpty)
        mint.paid=true;try await service.checkArchived(identity:identity);XCTAssertEqual(service.depositID,"local-quote");XCTAssertTrue(service.invoice.isEmpty)
        try await service.checkDeposit(identity:identity);XCTAssertEqual(service.balance,250000);XCTAssertEqual(mint.mintCalls,1);XCTAssertTrue(service.depositID.isEmpty)
        let restarted=WalletService(client:client,mint:mint,now:{ mint.date });try await restarted.refresh(identity:identity)
        XCTAssertEqual(restarted.archivedCount,0);XCTAssertEqual(restarted.balance,250000);try await restarted.checkDeposit(identity:identity);XCTAssertEqual(mint.mintCalls,1)
    }
    func testBrowserTokensWithoutConfigurationPreserveSpendableProofs() async throws {
        let mint=WalletFixtureMint(),oldRelay=try await relay(),newRelay=try await relay();defer { oldRelay.stop();newRelay.stop() }
        let (identity,_)=try await funded(mint,client:NostrRelayClient(relays:[oldRelay.url],timeout:.seconds(2))),owner=identity.hex
        defer { try? WalletVault().removeTestState(owner:owner);try? identity.disconnect() }
        let original=try XCTUnwrap(WalletVault().load(owner:owner)),proofs=original.ledger.records.values.flatMap(\.proofs)
        let clean=proofs.map { $0.wire.setting("dleq",.null).setting("witness",.null) },payload:JSONValue = .object(["proofs":.array(clean),"del":.array([])])
        let content=try await identity.encryptWallet(payload.json,expectedAuthor:owner),client=NostrRelayClient(relays:[newRelay.url],timeout:.seconds(2))
        try await client.publish(identity.sign(kind:7375,tags:[["mint",WalletContract.defaultMint]],content:content));try WalletVault().removeTestState(owner:owner)
        let service=WalletService(client:client,mint:mint,now:{ mint.date });try await service.refresh(identity:identity)
        XCTAssertEqual(service.balance,250000);XCTAssertTrue(service.canRestore);XCTAssertFalse(service.ready);XCTAssertEqual(newRelay.frames().filter { $0.first as? String == "EVENT" }.count,1)
        try await service.restoreBrowserWallet(identity:identity);let restored=try XCTUnwrap(WalletVault().load(owner:owner))
        XCTAssertNotEqual(restored.walletPrivateKey,original.walletPrivateKey);XCTAssertEqual(Set(restored.ledger.records.values.flatMap(\.proofs).map(\.secret)),Set(proofs.map(\.secret)));XCTAssertEqual(service.balance,250000)
        let receiver=try self.identity(),b=receiver.hex,destination=WalletService(client:client,mint:mint,now:{ mint.date });defer { try? WalletVault().removeTestState(owner:b);try? receiver.disconnect() }
        try await destination.refresh(identity:receiver);try await destination.create(identity:receiver);try await service.sendOneSat(to:receiver.npub,maximumFee:0,identity:identity);try await destination.receiveNutzaps(identity:receiver)
        XCTAssertEqual(service.balance,249999);XCTAssertEqual(destination.balance,1);XCTAssertEqual(mint.mintCalls,1)
    }
    func testModernBrowserWalletMergesBackupKeysAndRedeemsToAnOlderReceivingKey() async throws {
        let mint=WalletFixtureMint(),relay=try await relay(),client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2));defer { relay.stop() }
        let (sender,wallet)=try await funded(mint,client:client),receiver=try identity(),a=sender.hex,b=receiver.hex,old=Keypair()!,current=Keypair()!
        defer { try? WalletVault().removeTestState(owner:a);try? WalletVault().removeTestState(owner:b);try? sender.disconnect();try? receiver.disconnect() }
        try await browserEvent(receiver,kind:17375,keys:[current.privateKey.hex],client:client);try await browserEvent(receiver,kind:375,keys:[old.privateKey.hex],client:client)
        try await client.publish(receiver.sign(kind:10019,tags:[["pubkey",old.publicKey.hex],["mint",WalletContract.defaultMint]],content:""))
        let destination=WalletService(client:client,mint:mint,now:{ mint.date });try await destination.refresh(identity:receiver)
        let restored=try XCTUnwrap(WalletVault().load(owner:b));XCTAssertTrue(restored.additionalReceivingKeys?.contains(old.privateKey.hex) ?? false);XCTAssertEqual(restored.walletPrivateKey,current.privateKey.hex)
        try await wallet.sendOneSat(to:receiver.npub,maximumFee:0,identity:sender);try await destination.receiveNutzaps(identity:receiver)
        XCTAssertEqual(destination.balance,1);XCTAssertEqual(mint.swapCalls,2)
        try await destination.publishReceivingInformation(identity:receiver);XCTAssertFalse(destination.needsReceivingInfo)
        XCTAssertEqual(try WalletVault().load(owner:b)?.walletPrivateKey,current.privateKey.hex)
    }
    func testLegacyMainIdentityReceivingKeyMigratesWithoutDiscardingItsKey() async throws {
        let identity=try identity(),owner=identity.hex,mint=WalletFixtureMint(),relay=try await relay();defer { relay.stop();try? WalletVault().removeTestState(owner:owner);try? identity.disconnect() }
        let client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2)),key=try XCTUnwrap(identity.keypair?.privateKey.hex)
        try await browserEvent(identity,kind:375,keys:[key],client:client)
        let service=WalletService(client:client,mint:mint,now:{ mint.date });try await service.refresh(identity:identity);try await service.restoreBrowserWallet(identity:identity)
        let saved=try XCTUnwrap(WalletVault().load(owner:owner));XCTAssertNotEqual(saved.walletPrivateKey,key);XCTAssertTrue(saved.additionalReceivingKeys?.contains(key) ?? false);XCTAssertTrue(service.ready)
        try await service.refresh(identity:identity);XCTAssertEqual(try WalletVault().load(owner:owner)?.walletPrivateKey,saved.walletPrivateKey)
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
    private func funded(_ mint:WalletFixtureMint,client:NostrRelayClient) async throws -> (IdentityService,WalletService) {
        let identity=try identity(),service=WalletService(client:client,mint:mint,now:{ mint.date })
        try await service.refresh(identity:identity);try await service.create(identity:identity);try await service.deposit(amount:250000,identity:identity);mint.paid=true;try await service.checkDeposit(identity:identity);return(identity,service)
    }
    func testOneSatNutzapUsesSeparateReceiverKeyAndRedeemsOnceAcrossDevices() async throws {
        let mint=WalletFixtureMint();mint.v2=true
        let relay=try await relay(),client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2));defer { relay.stop() }
        let (sender,wallet)=try await funded(mint,client:client),receiver=try identity(),destination=WalletService(client:client,mint:mint,now:{ mint.date }),a=sender.hex
        let signer=LocalRemoteSigner();try await signer.start();defer { signer.stop() };try await receiver.connect(signer.token);let b=receiver.hex
        XCTAssertNil(receiver.keypair)
        defer { try? WalletVault().removeTestState(owner:a);try? WalletVault().removeTestState(owner:b);try? sender.disconnect();try? receiver.disconnect() }
        try await destination.refresh(identity:receiver);try await destination.create(identity:receiver)
        try await wallet.previewTip(to:receiver.npub,identity:sender);XCTAssertEqual(wallet.tipPreview?.fee,0)
        try await wallet.sendOneSat(to:receiver.npub,maximumFee:0,identity:sender);XCTAssertEqual(wallet.balance,249999)
        let sent=try XCTUnwrap(WalletVault().load(owner:a)?.sentReceipts?.last),receiverKey=try XCTUnwrap(WalletVault().load(owner:b)?.walletPrivateKey)
        XCTAssertEqual(sent.content,WalletCopy.publicNote);XCTAssertEqual(sent.tag("alt"),"This is a nutzap");XCTAssertNotNil(WalletPublicTransaction.parse(sent));XCTAssertEqual(sent.kind,9321);XCTAssertEqual(sent.tag("p"),b);XCTAssertEqual(sent.tag("u"),WalletContract.defaultMint)
        let proof=try WalletProof(JSONDecoder().decode(JSONValue.self,from:Data(sent.tag("proof").utf8)));XCTAssertTrue(proof.locked(to:"02"+Keypair(hex:receiverKey)!.publicKey.hex));XCTAssertFalse(proof.locked(to:"02"+b))
        let forged=proof.wire.setting("C",.string("02"+String(repeating:"1",count:64)))
        try await client.publish(sender.sign(kind:9321,tags:[["proof",forged.json],["p",b],["u",WalletContract.defaultMint],["unit","sat"]],content:"invalid proof fixture"))
        try await destination.receiveNutzaps(identity:receiver);XCTAssertEqual(destination.balance,1);XCTAssertEqual(mint.swapCalls,2)
        try await destination.receiveNutzaps(identity:receiver);XCTAssertEqual(mint.swapCalls,2)
        try WalletVault().removeTestState(owner:b)
        let restored=WalletService(client:client,mint:mint,now:{ mint.date });try await restored.refresh(identity:receiver);XCTAssertEqual(restored.balance,1);try await restored.receiveNutzaps(identity:receiver);XCTAssertEqual(mint.swapCalls,2)
    }
    func testLostSwapResponseRecoversLockedProofsAndDoesNotSendTwice() async throws {
        let mint=WalletFixtureMint(),relay=try await relay(),client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2));defer { relay.stop() }
        let (sender,wallet)=try await funded(mint,client:client),receiver=try identity(),destination=WalletService(client:client,mint:mint,now:{ mint.date }),a=sender.hex,b=receiver.hex
        defer { try? WalletVault().removeTestState(owner:a);try? WalletVault().removeTestState(owner:b);try? sender.disconnect();try? receiver.disconnect() }
        try await destination.refresh(identity:receiver);try await destination.create(identity:receiver);mint.loseSwapResponse=true
        do { try await wallet.sendOneSat(to:receiver.npub,maximumFee:0,identity:sender);XCTFail("Lost swap response should leave a saved operation") } catch { }
        XCTAssertEqual(mint.swapCalls,1);XCTAssertEqual(try WalletVault().load(owner:a)?.pending?.phase,.submitted)
        let restored=WalletService(client:client,mint:mint,now:{ mint.date });try await restored.refresh(identity:sender);try await restored.checkDeposit(identity:sender)
        XCTAssertEqual(restored.balance,249999);XCTAssertEqual(mint.swapCalls,1)
        let receipts=relay.frames().filter { $0.first as? String == "EVENT" }.compactMap { $0[1] as? [String:Any] }.filter { $0["kind"] as? Int == 9321 };XCTAssertEqual(receipts.count,1)
        try await restored.checkDeposit(identity:sender);XCTAssertEqual(mint.swapCalls,1)
    }
    func testMintFeeIsQuotedCappedAndTinyReceivedTipsAccumulateForRedemption() async throws {
        let mint=WalletFixtureMint();mint.inputFeePPK=100
        let relay=try await relay(),client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2));defer { relay.stop() }
        let (sender,wallet)=try await funded(mint,client:client),receiver=try identity(),destination=WalletService(client:client,mint:mint,now:{ mint.date }),a=sender.hex,b=receiver.hex
        defer { try? WalletVault().removeTestState(owner:a);try? WalletVault().removeTestState(owner:b);try? sender.disconnect();try? receiver.disconnect() }
        try await destination.refresh(identity:receiver);try await destination.create(identity:receiver)
        try await wallet.previewTip(to:receiver.npub,identity:sender);XCTAssertEqual(wallet.tipPreview?.fee,1)
        do { try await wallet.sendOneSat(to:receiver.npub,maximumFee:0,identity:sender);XCTFail("Unapproved fee should be rejected") } catch { };XCTAssertEqual(mint.swapCalls,0)
        try await wallet.sendOneSat(to:receiver.npub,maximumFee:1,identity:sender);XCTAssertEqual(wallet.balance,249998)
        try await destination.receiveNutzaps(identity:receiver);XCTAssertEqual(destination.balance,0);XCTAssertEqual(mint.swapCalls,1)
        try await wallet.sendOneSat(to:receiver.npub,maximumFee:1,identity:sender);try await destination.receiveNutzaps(identity:receiver);XCTAssertEqual(destination.balance,1);XCTAssertEqual(mint.swapCalls,3)
    }
    func testTipRelayFailureRetriesTheSameReceiptAndIncomingLostResponseRecoversOnce() async throws {
        var rejectTip=true
        let mint=WalletFixtureMint(),relay=try await relay(reject:{ $0 == 9321 && rejectTip }),client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2));defer { relay.stop() }
        let (sender,wallet)=try await funded(mint,client:client),receiver=try identity(),destination=WalletService(client:client,mint:mint,now:{ mint.date }),a=sender.hex,b=receiver.hex
        defer { try? WalletVault().removeTestState(owner:a);try? WalletVault().removeTestState(owner:b);try? sender.disconnect();try? receiver.disconnect() }
        try await destination.refresh(identity:receiver);try await destination.create(identity:receiver)
        do { try await wallet.sendOneSat(to:receiver.npub,maximumFee:0,identity:sender);XCTFail("Unacknowledged tip must retain its outbox") } catch { }
        XCTAssertEqual(mint.swapCalls,1);let saved=try XCTUnwrap(WalletVault().load(owner:a)?.pending);XCTAssertEqual(saved.phase,.publishing);XCTAssertNotNil(saved.outbox.first { $0.kind == 9321 })
        rejectTip=false;try await wallet.checkDeposit(identity:sender);XCTAssertEqual(mint.swapCalls,1)
        let events=relay.frames().filter { $0.first as? String == "EVENT" }.compactMap { $0[1] as? [String:Any] }.filter { $0["kind"] as? Int == 9321 };XCTAssertEqual(events.count,2);XCTAssertEqual(Set(events.compactMap { $0["id"] as? String }).count,1)
        mint.loseSwapResponse=true
        do { try await destination.receiveNutzaps(identity:receiver);XCTFail("Lost redemption response should retain its outputs") } catch { }
        XCTAssertEqual(mint.swapCalls,2);let restored=WalletService(client:client,mint:mint,now:{ mint.date });try await restored.refresh(identity:receiver);try await restored.checkDeposit(identity:receiver)
        XCTAssertEqual(restored.balance,1);XCTAssertEqual(mint.swapCalls,2);try await restored.receiveNutzaps(identity:receiver);XCTAssertEqual(mint.swapCalls,2)
    }
    func testMissingAdvertisementMainKeyAndUnsupportedMintNeverSpendFunds() async throws {
        let mint=WalletFixtureMint(),relay=try await relay(),client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2));defer { relay.stop() }
        let (sender,wallet)=try await funded(mint,client:client),receiver=try identity(),a=sender.hex,b=receiver.hex
        defer { try? WalletVault().removeTestState(owner:a);try? sender.disconnect();try? receiver.disconnect() }
        do { try await wallet.sendOneSat(to:receiver.npub,maximumFee:0,identity:sender);XCTFail("Missing recipient advertisement accepted") } catch { }
        for (index,tags) in [[["pubkey",b],["mint",WalletContract.defaultMint]],[["pubkey",String(repeating:"f",count:64)],["mint","https://not-supported.invalid"]]].enumerated() {
            try await client.publish(identityEvent(receiver,kind:10019,tags:tags,createdAt:Int64(Date().timeIntervalSince1970)+Int64(index)))
            do { try await wallet.sendOneSat(to:receiver.npub,maximumFee:0,identity:sender);XCTFail("Invalid recipient advertisement accepted") } catch { }
        }
        let separate=try XCTUnwrap(Keypair())
        try await client.publish(identityEvent(receiver,kind:10019,tags:[["pubkey",separate.publicKey.hex],["mint",WalletContract.defaultMint]],createdAt:Int64(Date().timeIntervalSince1970)+2))
        mint.supportsLock=false;do { try await wallet.sendOneSat(to:receiver.npub,maximumFee:0,identity:sender);XCTFail("Mint without P2PK support accepted") } catch { }
        XCTAssertEqual(mint.swapCalls,0);XCTAssertEqual(wallet.balance,250000)
    }
    private func identityEvent(_ identity:IdentityService,kind:Int,tags:[[String]],createdAt:Int64) throws -> NostrEventPayload { try identity.sign(kind:kind,tags:tags,content:"",createdAt:createdAt) }
    func testPartiallySpentNutzapStillRedeemsItsRemainingValidProof() async throws {
        let mint=WalletFixtureMint(),relay=try await relay(),client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2));defer { relay.stop() }
        let (sender,wallet)=try await funded(mint,client:client),receiver=try identity(),destination=WalletService(client:client,mint:mint,now:{ mint.date }),a=sender.hex,b=receiver.hex
        defer { try? WalletVault().removeTestState(owner:a);try? WalletVault().removeTestState(owner:b);try? sender.disconnect();try? receiver.disconnect() }
        try await destination.refresh(identity:receiver);try await destination.create(identity:receiver)
        try await wallet.sendOneSat(to:receiver.npub,maximumFee:0,identity:sender);let first=try XCTUnwrap(WalletVault().load(owner:a)?.sentReceipts?.last);try await destination.receiveNutzaps(identity:receiver);XCTAssertEqual(destination.balance,1)
        mint.loseSwapResponse=true;do { try await wallet.sendOneSat(to:receiver.npub,maximumFee:0,identity:sender);XCTFail("Fixture must retain a lost response") } catch { }
        let pending=try XCTUnwrap(WalletVault().load(owner:a)?.pending),outputs=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(pending.batch.outputs))
        let restored=try await mint.request(mint:pending.mint,path:"v1/restore",body:.object(["outputs":outputs])),known=try JSONDecoder().decode([CashuSwift.Output].self,from:JSONEncoder().encode(restored["outputs"])),signatures=try JSONDecoder().decode([CashuSwift.Promise].self,from:JSONEncoder().encode(restored["signatures"]))
        let loaded=try await mint.loadMint(pending.mint),proofs=try pending.batch.recover(outputs:known,signatures:signatures,mint:loaded),new=try XCTUnwrap(proofs.last),wire=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(new))
        try await client.publish(sender.sign(kind:9321,tags:[["proof",first.tag("proof")],["proof",wire.json],["p",b],["u",WalletContract.defaultMint],["unit","sat"]],content:"partial fixture"))
        try await destination.receiveNutzaps(identity:receiver);XCTAssertEqual(destination.balance,2);XCTAssertEqual(mint.swapCalls,4)
        try await wallet.checkDeposit(identity:sender);try await destination.receiveNutzaps(identity:receiver);XCTAssertEqual(mint.swapCalls,4)
    }
    func testDefaultSupportRecipientAdvertisementReadOnly() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_LIVE_NOSTR_TESTS"] == "1" else { throw XCTSkip("Read-only support-recipient lookup requires explicit opt-in.") }
        let key=try XCTUnwrap(PublicKey(npub:WalletContract.defaultRecipient)),events=try await NostrRelayClient().querySnapshots(filter:["kinds":[10019],"authors":[key.hex]])
        guard let latest=events.max(by:{ $0.created_at < $1.created_at }) else { print("LIVE WALLET SUPPORT: no signed NIP-61 advertisement retrieved; no wallet data was changed");return }
        do { let recipient=try NutzapRecipient(author:key.hex,tags:latest.tags);_=try recipient.compatibleMint(holding:[WalletContract.defaultMint]);print("LIVE WALLET SUPPORT: default recipient advertises a separate receiving key and supported mint; no payment or publication made") }
        catch { print("LIVE WALLET SUPPORT: default recipient advertisement requires receiving-key/mint migration; no wallet data was changed") }
    }
    private func practiceChange() -> PracticeChange { PracticeChange(dayKey:"2026-10-20",target:"es",level:"A1",amount:10,source:.practice) }
    func testAutomaticTipHasOneReceiptAcrossRetryAndIntentJournalRollback() async throws {
        let mint=WalletFixtureMint(),relay=try await relay(),client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2));defer { relay.stop() }
        let (sender,wallet)=try await funded(mint,client:client),receiver=try identity(),destination=WalletService(client:client,mint:mint,now:{ mint.date }),a=sender.hex,b=receiver.hex
        defer { try? WalletVault().removeTestState(owner:a);try? WalletVault().removeTestState(owner:b);try? sender.disconnect();try? receiver.disconnect() }
        try await destination.refresh(identity:receiver);try await destination.create(identity:receiver)
        let change=practiceChange();try wallet.enqueueAutomaticTips([change],identity:sender);XCTAssertTrue(try WalletVault().automaticTips(owner:a).queue.isEmpty)
        try wallet.configureAutomaticTips(enabled:true,recipient:receiver.npub,maximumFee:0,identity:sender);try wallet.enqueueAutomaticTips([change,change],identity:sender)
        let before=try WalletVault().automaticTips(owner:a);XCTAssertEqual(before.queue.count,1);let processed=try await wallet.processAutomaticTip(identity:sender);XCTAssertTrue(processed);XCTAssertEqual(mint.swapCalls,1)
        try WalletVault().saveAutomaticTips(before,owner:a)
        let restored=WalletService(client:client,mint:mint,now:{ mint.date });let reconciled=try await restored.processAutomaticTip(identity:sender);XCTAssertTrue(reconciled);XCTAssertEqual(mint.swapCalls,1)
        try restored.enqueueAutomaticTips([change],identity:sender);XCTAssertTrue(try WalletVault().automaticTips(owner:a).queue.isEmpty)
    }
    func testAutomaticTipLostResponseResumesAndStoppingPreservesSubmittedRecovery() async throws {
        let mint=WalletFixtureMint(),relay=try await relay(),client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2));defer { relay.stop() }
        let (sender,wallet)=try await funded(mint,client:client),receiver=try identity(),destination=WalletService(client:client,mint:mint,now:{ mint.date }),a=sender.hex,b=receiver.hex
        defer { try? WalletVault().removeTestState(owner:a);try? WalletVault().removeTestState(owner:b);try? sender.disconnect();try? receiver.disconnect() }
        try await destination.refresh(identity:receiver);try await destination.create(identity:receiver);try wallet.configureAutomaticTips(enabled:true,recipient:receiver.npub,maximumFee:0,identity:sender)
        let change=practiceChange();try wallet.enqueueAutomaticTips([change],identity:sender);mint.loseSwapResponse=true
        do { _=try await wallet.processAutomaticTip(identity:sender);XCTFail("Lost response must retain the operation") } catch { }
        XCTAssertEqual(mint.swapCalls,1);XCTAssertEqual(try WalletVault().load(owner:a)?.pending?.automaticTrigger,change.id.uuidString.lowercased())
        try wallet.configureAutomaticTips(enabled:false,recipient:receiver.npub,maximumFee:0,identity:sender);let stopped=try await wallet.processAutomaticTip(identity:sender);XCTAssertFalse(stopped);XCTAssertEqual(mint.swapCalls,1)
        XCTAssertNotNil(try WalletVault().load(owner:a)?.pending);try await wallet.checkDeposit(identity:sender);XCTAssertNil(try WalletVault().load(owner:a)?.pending);XCTAssertEqual(mint.swapCalls,1)
    }
    func testAutomaticTipQueueCannotOverwriteAnInFlightWalletOperation() async throws {
        let mint=WalletFixtureMint(),relay=try await relay(),client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2));defer { relay.stop() }
        let (sender,wallet)=try await funded(mint,client:client),receiver=try identity(),destination=WalletService(client:client,mint:mint,now:{ mint.date }),a=sender.hex,b=receiver.hex
        defer { try? WalletVault().removeTestState(owner:a);try? WalletVault().removeTestState(owner:b);try? sender.disconnect();try? receiver.disconnect() }
        try await destination.refresh(identity:receiver);try await destination.create(identity:receiver);try wallet.configureAutomaticTips(enabled:true,recipient:receiver.npub,maximumFee:0,identity:sender)
        mint.loseSwapResponse=true;do { try await wallet.sendOneSat(to:receiver.npub,maximumFee:0,identity:sender) } catch { }
        let operation=try XCTUnwrap(WalletVault().load(owner:a)?.pending);try wallet.enqueueAutomaticTips([practiceChange()],identity:sender)
        XCTAssertEqual(try WalletVault().load(owner:a)?.pending?.id,operation.id);let blocked=try await wallet.processAutomaticTip(identity:sender);XCTAssertFalse(blocked);XCTAssertEqual(mint.swapCalls,1)
    }
    func testAppModelOnlyQueuesNewXPEventsAndDoesNotReplayPersistence() async throws {
        let mint=WalletFixtureMint(),relay=try await relay(),client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2));defer { relay.stop() }
        let (sender,wallet)=try await funded(mint,client:client),receiver=try identity(),destination=WalletService(client:client,mint:mint,now:{ mint.date }),a=sender.hex,b=receiver.hex
        defer { try? WalletVault().removeTestState(owner:a);try? WalletVault().removeTestState(owner:b);try? sender.disconnect();try? receiver.disconnect() }
        try await destination.refresh(identity:receiver);try await destination.create(identity:receiver);try wallet.configureAutomaticTips(enabled:true,recipient:receiver.npub,maximumFee:0,identity:sender)
        try sender.importKey(try XCTUnwrap(sender.keypair).privateKey.nsec)
        let auto=WalletService(client:client,mint:mint,now:{ mint.date }),model=AppModel(automaticWallet:auto)
        XCTAssertEqual(model.identity.hex,a);model.learner.onboardingComplete=false;model.learner.award(10);model.persist()
        for _ in 0..<200 { if mint.swapCalls == 1,(try WalletVault().automaticTips(owner:a)).queue.isEmpty { break };try await Task.sleep(for:.milliseconds(10)) }
        XCTAssertEqual(mint.swapCalls,1);XCTAssertTrue(try WalletVault().automaticTips(owner:a).queue.isEmpty)
        model.persist();try await Task.sleep(for:.milliseconds(150));XCTAssertEqual(mint.swapCalls,1)
    }
    func testStoppingAutomaticTipsDuringPlanningPreventsMintSubmission() async throws {
        let mint=WalletFixtureMint(),relay=try await relay(),client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2));defer { relay.stop() }
        let (sender,wallet)=try await funded(mint,client:client),receiver=try identity(),destination=WalletService(client:client,mint:mint,now:{ mint.date }),a=sender.hex,b=receiver.hex
        defer { try? WalletVault().removeTestState(owner:a);try? WalletVault().removeTestState(owner:b);try? sender.disconnect();try? receiver.disconnect() }
        try await destination.refresh(identity:receiver);try await destination.create(identity:receiver);try wallet.configureAutomaticTips(enabled:true,recipient:receiver.npub,maximumFee:0,identity:sender);try wallet.enqueueAutomaticTips([practiceChange()],identity:sender)
        mint.delayInfo=true;let running=Task { try await wallet.processAutomaticTip(identity:sender) }
        for _ in 0..<100 where mint.infoCalls == 0 { try await Task.sleep(for:.milliseconds(5)) };XCTAssertGreaterThan(mint.infoCalls,0)
        try wallet.configureAutomaticTips(enabled:false,recipient:receiver.npub,maximumFee:0,identity:sender)
        do { _=try await running.value;XCTFail("A cancelled intent was submitted") } catch { }
        XCTAssertEqual(mint.swapCalls,0);XCTAssertNil(try WalletVault().load(owner:a)?.pending)
    }
    func testAutomaticTipPausesWhenFeesExceedApprovalAndRecoveryIgnoresPreOptInXP() async throws {
        let mint=WalletFixtureMint(),relay=try await relay(),client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2));defer { relay.stop() }
        let (sender,wallet)=try await funded(mint,client:client),receiver=try identity(),destination=WalletService(client:client,mint:mint,now:{ mint.date }),a=sender.hex,b=receiver.hex
        defer { try? WalletVault().removeTestState(owner:a);try? WalletVault().removeTestState(owner:b);try? sender.disconnect();try? receiver.disconnect() }
        try await destination.refresh(identity:receiver);try await destination.create(identity:receiver)
        let old=practiceChange();try await Task.sleep(for:.milliseconds(2));try wallet.configureAutomaticTips(enabled:true,recipient:receiver.npub,maximumFee:0,identity:sender)
        try wallet.enqueueAutomaticTips([old],identity:sender,resuming:true);XCTAssertTrue(try WalletVault().automaticTips(owner:a).queue.isEmpty)
        try wallet.enqueueAutomaticTips([practiceChange()],identity:sender,resuming:true);mint.inputFeePPK=100;_=try await wallet.processAutomaticTip(identity:sender)
        XCTAssertEqual(mint.swapCalls,0);let preferences=try WalletVault().automaticTips(owner:a);XCTAssertFalse(preferences.enabled);XCTAssertTrue(preferences.queue.isEmpty);XCTAssertTrue(preferences.pauseReason!.contains("fee"))
    }
    func testInvoiceAmountSignatureAndExpiryAreValidated() throws {
        let mint=WalletFixtureMint(),quote:JSONValue = .object(["quote":.string("local-quote"),"request":.string(mint.invoice)])
        XCTAssertNoThrow(try CashuHTTPClient.validateQuote(quote,amount:250000,now:mint.date))
        XCTAssertThrowsError(try CashuHTTPClient.validateQuote(quote,amount:10,now:mint.date))
        XCTAssertThrowsError(try CashuHTTPClient.validateQuote(quote,amount:250000,now:Date()))
        XCTAssertThrowsError(try CashuHTTPClient.validateQuote(quote.setting("request",.string(String(mint.invoice.dropLast())+"q")),amount:250000,now:mint.date))
    }
}

extension WalletServiceTests {
    func testSourceSupportAdoptsFundedWalletRetargetsAndKeepsExplicitStop()async throws {
        let mint=WalletFixtureMint(),relay=try await relay(),client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2));defer{relay.stop()}
        let(sender,wallet)=try await funded(mint,client:client),owner=sender.hex,receiver=try identity(),target=receiver.hex
        defer{try? WalletVault().removeTestState(owner:owner);try? WalletVault().removeTestState(owner:target);try? sender.disconnect();try? receiver.disconnect()}
        let destination=WalletService(client:client,mint:mint,now:{mint.date});try await destination.refresh(identity:receiver);try await destination.create(identity:receiver)
        XCTAssertFalse(try WalletVault().hasAutomaticPreference(owner:owner));try wallet.adoptSourceSupport(identity:sender,recipient:receiver.npub)
        var historical=practiceChange();historical.date=Date(timeIntervalSinceNow:-3600);try wallet.enqueueAutomaticTips([historical],identity:sender,resuming:true);XCTAssertTrue(try WalletVault().automaticTips(owner:owner).queue.isEmpty);XCTAssertEqual(mint.swapCalls,0)
        var journal=try WalletVault().automaticTips(owner:owner);XCTAssertTrue(journal.enabled);XCTAssertEqual(journal.sourceManaged,true);XCTAssertEqual(journal.maximumFee,0)
        let change=practiceChange();try wallet.enqueueAutomaticTips([change,change],identity:sender);let processed=try await wallet.processAutomaticTip(identity:sender);XCTAssertTrue(processed);XCTAssertEqual(mint.swapCalls,1)
        let restored=WalletService(client:client,mint:mint,now:{mint.date});try restored.adoptSourceSupport(identity:sender,recipient:WalletContract.defaultRecipient);journal=try WalletVault().automaticTips(owner:owner);XCTAssertEqual(journal.recipient,WalletContract.defaultRecipient);XCTAssertEqual(journal.maximumFee,0);try restored.enqueueAutomaticTips([change],identity:sender);XCTAssertTrue(try WalletVault().automaticTips(owner:owner).queue.isEmpty)
        try restored.configureAutomaticTips(enabled:false,recipient:journal.recipient,maximumFee:0,identity:sender);try restored.adoptSourceSupport(identity:sender,recipient:receiver.npub);XCTAssertFalse(try WalletVault().automaticTips(owner:owner).enabled)
    }
}

extension WalletServiceTests {
    func testSourceRecipientChangeRecoversSubmittedTipToOriginalRecipientOnce()async throws {
        let mint=WalletFixtureMint(),relay=try await relay(),client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2));defer{relay.stop()}
        let(sender,wallet)=try await funded(mint,client:client),owner=sender.hex,receiver=try identity(),target=receiver.hex
        defer{try? WalletVault().removeTestState(owner:owner);try? WalletVault().removeTestState(owner:target);try? sender.disconnect();try? receiver.disconnect()}
        let destination=WalletService(client:client,mint:mint,now:{mint.date});try await destination.refresh(identity:receiver);try await destination.create(identity:receiver)
        try wallet.adoptSourceSupport(identity:sender,recipient:receiver.npub);let change=practiceChange();try wallet.enqueueAutomaticTips([change],identity:sender);mint.loseSwapResponse=true
        do{_=try await wallet.processAutomaticTip(identity:sender);XCTFail("The submitted swap response must be lost")}catch{}
        XCTAssertNotNil(try WalletVault().load(owner:owner)?.pending)
        try wallet.adoptSourceSupport(identity:sender,recipient:WalletContract.defaultRecipient);let journal=try WalletVault().automaticTips(owner:owner)
        XCTAssertEqual(journal.recipient,WalletContract.defaultRecipient);XCTAssertEqual(journal.queue.first?.recipient,receiver.npub)
        XCTAssertTrue(wallet.hasAutomaticWork(identity:sender));let recovered=try await wallet.processAutomaticTip(identity:sender);XCTAssertTrue(recovered);XCTAssertEqual(mint.swapCalls,1)
        let receipts=try XCTUnwrap(WalletVault().load(owner:owner)?.sentReceipts);XCTAssertEqual(receipts.count,1);XCTAssertEqual(receipts[0].tag("p"),target)
        try wallet.enqueueAutomaticTips([change],identity:sender);XCTAssertTrue(try WalletVault().automaticTips(owner:owner).queue.isEmpty)
    }
}
