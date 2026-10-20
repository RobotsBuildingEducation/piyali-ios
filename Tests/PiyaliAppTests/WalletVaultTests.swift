import XCTest
import NostrSDK
@testable import Piyali

@MainActor final class WalletVaultTests:XCTestCase {
    func testWalletRecoverySecretsAreAccountScopedAndRetainedAcrossIdentityDisconnect() throws {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { throw XCTSkip("Isolated test identity required for Keychain storage.") }
        let vault=WalletVault(),first=try XCTUnwrap(Keypair()),second=try XCTUnwrap(Keypair()),wallet=try XCTUnwrap(Keypair())
        defer { try? vault.removeTestState(owner:first.publicKey.hex);try? vault.removeTestState(owner:second.publicKey.hex) }
        let state=WalletPrivateState(owner:first.publicKey.hex,walletPrivateKey:wallet.privateKey.hex,mints:[WalletContract.defaultMint],relays:["wss://relay.example"])
        try vault.save(state);XCTAssertEqual(try vault.load(owner:first.publicKey.hex)?.walletPrivateKey,wallet.privateKey.hex);XCTAssertNil(try vault.load(owner:second.publicKey.hex))
        let identity=IdentityService();try identity.importKey(first.privateKey.nsec);try identity.disconnect()
        XCTAssertEqual(try vault.load(owner:first.publicKey.hex)?.walletPrivateKey,wallet.privateKey.hex)
        XCTAssertThrowsError(try vault.load(owner:"../not-an-account"))
        let learner=String(decoding:try JSONEncoder().encode(LearnerState()),as:UTF8.self);XCTAssertFalse(learner.contains(wallet.privateKey.hex));XCTAssertFalse(learner.contains("walletPrivateKey"))
    }
    func testPendingBatchSurvivesKeychainRoundTripBeforeAnyNetworkRequest() throws {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { throw XCTSkip("Isolated test identity required for Keychain storage.") }
        let owner=try XCTUnwrap(Keypair()),wallet=try XCTUnwrap(Keypair()),vault=WalletVault();defer { try? vault.removeTestState(owner:owner.publicKey.hex) }
        let batch=CashuMintBatch(outputs:[],secrets:["pending private test secret"],blindingFactors:["saved private blinding factor"])
        var state=WalletPrivateState(owner:owner.publicKey.hex,walletPrivateKey:wallet.privateKey.hex,mints:[WalletContract.defaultMint],relays:[])
        state.pending=WalletPendingOperation(purpose:.deposit,mint:WalletContract.defaultMint,amount:10,batch:batch,quote:.object(["quote":.string("private-test-quote")]))
        try vault.save(state);let restored=try XCTUnwrap(vault.load(owner:owner.publicKey.hex));XCTAssertEqual(restored.pending?.id,state.pending?.id);XCTAssertEqual(restored.pending?.batch.secrets,batch.secrets);XCTAssertEqual(restored.pending?.phase,.prepared)
        state.pending?.phase = .submitted;try vault.save(state);XCTAssertEqual(try vault.load(owner:owner.publicKey.hex)?.pending?.phase,.submitted)
    }
    func testLocalWalletEncryptionIsBoundToCurrentAccount() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { throw XCTSkip("Isolated test identity required for Keychain storage.") }
        let identity=IdentityService();try identity.create();defer { try? identity.disconnect() };let author=identity.hex
        let cipher=try await identity.encryptWallet("private wallet record",expectedAuthor:author)
        XCTAssertFalse(cipher.contains("private wallet record"));let clear=try await identity.decryptWallet(cipher,expectedAuthor:author);XCTAssertEqual(clear,"private wallet record")
        try identity.create();do { _=try await identity.decryptWallet(cipher,expectedAuthor:author);XCTFail("An obsolete account decrypted wallet data") } catch { }
    }

}
