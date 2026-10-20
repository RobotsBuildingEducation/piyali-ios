import XCTest
import NostrSDK
@testable import Piyali

@MainActor final class RemoteSignerTests:XCTestCase {
    private func fixture() async throws -> LocalRemoteSigner {
        let signer=LocalRemoteSigner();try await signer.start();return signer
    }
    private func connected(_ fixture:LocalRemoteSigner) async throws -> (RemoteSignerService,RemoteSignerRecord) {
        let connection=try BunkerConnection(fixture.token,allowLoopback:true),keys=try XCTUnwrap(Keypair())
        let service=try RemoteSignerService(signer:connection.signer,relays:connection.relays,clientNsec:keys.privateKey.nsec,allowLoopback:true,timeout:.seconds(2))
        let record=try await service.connected(connection,onAuthorization:{ _ in });return(service,record)
    }
    private func identity() throws -> IdentityService {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { throw XCTSkip("Run scripts/test-nostr.sh for isolated Keychain tests.") }
        return IdentityService()
    }
    func testEncryptedHandshakeUsesActualUserKeyAndSignsExactUnicodeTemplate() async throws {
        let signer=try await fixture();defer { signer.stop() };let (service,record)=try await connected(signer)
        XCTAssertEqual(record.signer,signer.peer.publicKey.hex);XCTAssertEqual(record.user,signer.user.publicKey.hex);XCTAssertNotEqual(record.signer,record.user)
        let tags=[["d","learning-team:local"],["name","日本語 / café"]],content="A private test phrase that must remain inside encrypted RPC."
        let event=try await service.sign(kind:30078,tags:tags,content:content,createdAt:1700000000,user:record.user,onAuthorization:{ _ in })
        XCTAssertTrue(IdentityService.verify(event));XCTAssertEqual(event.pubkey,signer.user.publicKey.hex);XCTAssertEqual(event.content,content);XCTAssertEqual(event.tags,tags);XCTAssertEqual(event.created_at,1700000000)
        XCTAssertEqual(signer.methods(),["connect","get_public_key","switch_relays","sign_event"])
        let events=signer.relay.frames().filter { $0.first as? String == "EVENT" }.compactMap { $0[1] as? [String:Any] }
        XCTAssertTrue(events.allSatisfy { ($0["kind"] as? Int) == 24133 && !($0["content"] as? String ?? "").contains(content) && ($0["pubkey"] as? String) != record.user })
    }
    func testAlteredContentAndDifferentUserSignaturesAreRejected() async throws {
        let signer=try await fixture();defer { signer.stop() };let (service,record)=try await connected(signer)
        signer.alterSignedContent=true
        do { _=try await service.sign(kind:27235,tags:[],content:"exact challenge",createdAt:1700000000,user:record.user,onAuthorization:{ _ in });XCTFail("An altered signed template was accepted") } catch { }
        signer.alterSignedContent=false;signer.wrongUser=true
        do { _=try await service.sign(kind:27235,tags:[],content:"exact challenge",createdAt:1700000000,user:record.user,onAuthorization:{ _ in });XCTFail("A signer transport key impersonated the learner") } catch { }
    }
    func testPermissionDenialCannotProduceASignedEvent() async throws {
        let signer=try await fixture();defer { signer.stop() };signer.denySigning=true;let (service,record)=try await connected(signer)
        do { _=try await service.sign(kind:30078,tags:[],content:"test",createdAt:1700000000,user:record.user,onAuthorization:{ _ in });XCTFail("Denied signing was accepted") } catch { }
    }
    func testAuthorizationChallengeContinuesTheSameRequest() async throws {
        let signer=try await fixture();defer { signer.stop() };signer.challenge=true;let (service,record)=try await connected(signer)
        actor URLs { var urls:[URL]=[];func append(_ url:URL) { urls.append(url) };func all() -> [URL] { urls } }
        let received=URLs()
        let event=try await service.sign(kind:22242,tags:[["relay",signer.relay.url],["challenge","test"]],content:"",createdAt:Int64(Date().timeIntervalSince1970),user:record.user,onAuthorization:{ await received.append($0) })
        let urls=await received.all();XCTAssertEqual(urls.map(\.absoluteString),["https://signer.example/approve"]);XCTAssertTrue(IdentityService.verify(event));XCTAssertEqual(signer.methods().filter { $0 == "sign_event" }.count,1)
    }
    func testKeychainRestoresOnlyClientSessionAndKeepsAccountBindingStable() async throws {
        let signer=try await fixture();defer { signer.stop() };let identity=try identity();try identity.create();try await identity.connect(signer.token)
        XCTAssertTrue(identity.isRemote);XCTAssertEqual(identity.npub,signer.user.publicKey.npub);XCTAssertNil(identity.keypair);XCTAssertTrue(identity.exportKey().isEmpty)
        let restored=IdentityService();XCTAssertEqual(restored.npub,identity.npub);XCTAssertEqual(restored.accountToken,identity.accountToken);XCTAssertTrue(restored.exportKey().isEmpty)
        let event=try await restored.signEvent(kind:27235,tags:[["challenge","local"]],content:"proof",expectedAuthor:signer.user.publicKey.hex)
        XCTAssertTrue(IdentityService.verify(event));XCTAssertEqual(event.pubkey,signer.user.publicKey.hex)
        XCTAssertEqual(signer.methods().filter { $0 == "connect" }.count,1)
        try restored.disconnect();XCTAssertTrue(IdentityService().npub.isEmpty)
    }
    func testAccountReplacementCancelsAnOutstandingSignature() async throws {
        let signer=try await fixture();defer { signer.stop() };let identity=try identity();try await identity.connect(signer.token);signer.delaySigning=true
        let pending=Task { try await identity.signEvent(kind:30078,tags:[],content:"stale") }
        for _ in 0..<100 where !signer.methods().contains("sign_event") { try await Task.sleep(for:.milliseconds(10)) }
        XCTAssertTrue(signer.methods().contains("sign_event"));try identity.create();signer.release()
        do { _=try await pending.value;XCTFail("An old account signature escaped cancellation") } catch { }
        XCTAssertFalse(identity.isRemote);XCTAssertNotEqual(identity.npub,signer.user.publicKey.npub)
    }
    func testExpectedAuthorFencePreventsSigningForChangedAccount() async throws {
        let identity=try identity();try identity.create()
        do { _=try await identity.signEvent(kind:27235,tags:[],content:"old challenge",expectedAuthor:String(repeating:"a",count:64));XCTFail("A changed account signed the old challenge") } catch { }
    }
    func testForgedStaleWrongRecipientAndUnrelatedRepliesCannotResolveRequest() async throws {
        let signer=try await fixture();defer { signer.stop() };signer.injectNoise=true;let (service,record)=try await connected(signer)
        let event=try await service.sign(kind:30078,tags:[],content:"legitimate",createdAt:1700000000,user:record.user,onAuthorization:{ _ in })
        XCTAssertEqual(event.content,"legitimate");XCTAssertTrue(IdentityService.verify(event))
    }
    func testInsecureAuthorizationLinkIsRejectedInsteadOfOpened() async throws {
        let signer=try await fixture();defer { signer.stop() };signer.challenge=true;signer.authorizationURL="http://signer.example/approve";let (service,record)=try await connected(signer)
        do { _=try await service.sign(kind:30078,tags:[],content:"test",createdAt:1700000000,user:record.user,onAuthorization:{ _ in XCTFail("An insecure authorization URL was offered") });XCTFail("Insecure authorization was accepted") } catch { }
    }
    func testWalletNIP44UsesActualUserRatherThanSignerPeerAndRetainsNoMainPrivateKey() async throws {
        let signer=try await fixture();defer { signer.stop() };let identity=try identity();try await identity.connect(signer.token);defer { try? identity.disconnect() }
        let payload="[[\"privkey\",\"test-wallet-key\"],[\"mint\",\"https://mint.example\"]]"
        let cipher=try await identity.encryptWallet(payload,expectedAuthor:signer.user.publicKey.hex)
        XCTAssertEqual(try NostrSessionCrypto().decrypt(payload:cipher,privateKeyA:signer.user.privateKey,publicKeyB:signer.user.publicKey),payload)
        let clear=try await identity.decryptWallet(cipher,expectedAuthor:signer.user.publicKey.hex);XCTAssertEqual(clear,payload);XCTAssertNil(identity.keypair)
        do { _=try await identity.encryptWallet(payload,expectedAuthor:signer.peer.publicKey.hex);XCTFail("Signer-peer wallet encryption was accepted") } catch { }
        signer.denySigning=true;do { _=try await identity.encryptWallet(payload,expectedAuthor:signer.user.publicKey.hex);XCTFail("Denied wallet encryption succeeded") } catch { }
    }
    func testAccountReplacementCancelsPendingWalletEncryption() async throws {
        let signer=try await fixture();defer { signer.stop() };let identity=try identity();try await identity.connect(signer.token);signer.delaySigning=true
        let pending=Task { try await identity.encryptWallet("private recovery data",expectedAuthor:signer.user.publicKey.hex) }
        for _ in 0..<100 where !signer.methods().contains("nip44_encrypt") { try await Task.sleep(for:.milliseconds(10)) }
        XCTAssertTrue(signer.methods().contains("nip44_encrypt"));try identity.create();signer.release()
        do { _=try await pending.value;XCTFail("Encryption for a replaced account escaped cancellation") } catch { }
        try identity.disconnect()
    }

}
