import XCTest
@testable import PiyaliCore

final class WalletContractTests:XCTestCase {
    private let owner=String(repeating:"a",count:64),wallet=String(repeating:"b",count:64),mint=WalletContract.defaultMint
    private func proof(_ digit:String="1",amount:Int=1,secret:String="test secret") throws -> WalletProof {
        try WalletProof(.object(["id":.string("009a1f293253e41e"),"C":.string("02"+String(repeating:digit,count:64)),"amount":.number(Double(amount)),"secret":.string(secret)]))
    }
    private func record(_ digit:String,proofs:[WalletProof],destroyed:[String]=[]) throws -> WalletTokenRecord {
        try WalletTokenRecord(id:String(repeating:digit,count:64),payload:.object(["mint":.string(mint),"unit":.string("sat"),"proofs":.array(proofs.map(\.wire)),"del":.array(destroyed.map(JSONValue.string))]))
    }
    func testRecipientUsesSeparateWalletKeyAndExactAdvertisedMintURL() throws {
        let exact="https://MINT.minibits.cash:443/Bitcoin/",recipient=try NutzapRecipient(author:owner,tags:[["pubkey",wallet],["mint",exact,"sat"],["mint",mint],["relay","wss://relay.example"]])
        XCTAssertEqual(recipient.walletKey,"02"+wallet);XCTAssertEqual(recipient.mints,[exact]);XCTAssertEqual(try recipient.compatibleMint(holding:[mint]),exact)
        XCTAssertThrowsError(try recipient.compatibleMint(holding:["https://another.example"]))
    }
    func testMissingKeyMainIdentityKeyUnsupportedUnitsAndInsecureMintAreRejected() {
        for tags in [[["mint",mint]],[["pubkey",owner],["mint",mint]],[["pubkey",wallet],["mint",mint,"usd"]],[["pubkey",wallet],["mint","http://mint.example"]],[["pubkey",wallet],["pubkey",wallet],["mint",mint]]] { XCTAssertThrowsError(try NutzapRecipient(author:owner,tags:tags)) }
        for value in ["https://user:password@mint.example","https://mint.example/?token=secret","https://mint.example/#fragment","not-a-url"] { XCTAssertThrowsError(try WalletContract.mint(value)) }
    }
    func testRolloverArrivingBeforeOriginalNeverRestoresSpentBalance() throws {
        let first=try record("a",proofs:[proof("1",amount:4),proof("2",amount:2,secret:"other")]),second=try record("b",proofs:[proof("3",amount:1,secret:"change")],destroyed:[String(repeating:"a",count:64)])
        var ledger=WalletLedger();try ledger.ingest(second);try ledger.ingest(first);XCTAssertEqual(try ledger.balance(mint:mint),1)
        try ledger.ingest(first);try ledger.ingest(second);XCTAssertEqual(try ledger.balance(mint:mint),1)
        let restored=try JSONDecoder().decode(WalletLedger.self,from:JSONEncoder().encode(ledger));XCTAssertEqual(restored,ledger)
    }
    func testPublicDeletionBeforeTokenIsRememberedAndDuplicateProofsDoNotInflateBalance() throws {
        let original=try record("a",proofs:[proof()]),copy=try record("b",proofs:[proof()]);var ledger=WalletLedger();ledger.remove([original.id]);try ledger.ingest(original);XCTAssertEqual(try ledger.balance(mint:mint),0)
        try ledger.ingest(copy);try ledger.ingest(record("c",proofs:[proof()]));XCTAssertEqual(try ledger.balance(mint:mint),1)
    }
    func testConflictingProofOrReusedSecretFailsClosed() throws {
        var ledger=WalletLedger();try ledger.ingest(record("a",proofs:[proof()]))
        XCTAssertThrowsError(try ledger.ingest(record("a",proofs:[proof(amount:2)])))
        try ledger.ingest(record("b",proofs:[proof("2")]));XCTAssertThrowsError(try ledger.balance(mint:mint))
        var other=WalletLedger();try other.ingest(record("a",proofs:[proof()]));try other.ingest(record("b",proofs:[proof(amount:2)]));XCTAssertThrowsError(try other.balance(mint:mint))
    }
    func testInvalidAmountsAndMalformedProofsCannotEnterLedger() throws {
        let valid=try proof().wire
        for amount in [Double](arrayLiteral:0,-1,1.5,.infinity,2_199_023_255_552) { XCTAssertThrowsError(try WalletProof(valid.setting("amount",.number(amount)))) }
        XCTAssertThrowsError(try WalletProof(valid.setting("C",.string("bad point"))))
        XCTAssertThrowsError(try record("a",proofs:[proof(),proof()]))
    }
    func testNutzapLockRequiresExactAdvertisedKeyWithoutRefundOrMultisignatureConditions() throws {
        let secret:JSONValue = .array([.string("P2PK"),.object(["nonce":.string(String(repeating:"c",count:64)),"data":.string("02"+wallet)])])
        XCTAssertTrue(try proof(secret:secret.json).locked(to:"02"+wallet));XCTAssertFalse(try proof(secret:secret.json).locked(to:"02"+owner))
        var values=secret.array;values[1]=values[1].setting("tags",.array([.array([.string("refund"),.string("02"+owner)])]));XCTAssertFalse(try proof(secret:JSONValue.array(values).json).locked(to:"02"+wallet))
        values[1]=values[1].setting("tags",.object([:]));XCTAssertFalse(try proof(secret:JSONValue.array(values).json).locked(to:"02"+wallet))
    }
}
