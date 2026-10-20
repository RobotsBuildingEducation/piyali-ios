import XCTest
@testable import PiyaliCore

final class WalletImportTests:XCTestCase {
    func testCurrentBrowserWalletAndBackupPayloadsKeepEveryReceivingKeyAndMint() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/wallet-import.json"),fixtures=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url))
        XCTAssertEqual(fixtures["configurations"].array.count,6)
        for fixture in fixtures["configurations"].array { let imported=try ImportedWalletConfiguration(fixture["payload"]);XCTAssertEqual(imported.privateKeys,fixture["keys"].array.map(\.string));XCTAssertEqual(imported.mints,fixture["mints"].array.map(\.string)) }
    }
    func testLegacyMintTagAndQuoteIDsMatchBrowserPayloadShape() throws {
        let token:JSONValue = .object(["proofs":.array([]),"del":.array([])])
        XCTAssertEqual(try WalletImport.token(token,mintTag:WalletContract.defaultMint)["mint"],.string(WalletContract.defaultMint))
        let quote=try WalletImport.quote(.object(["quoteId":.string("old-quote"),"mint":.string(WalletContract.defaultMint),"amount":.number(10),"unit":.string("sat")]),eventID:"event")
        XCTAssertEqual(quote["quote"]["quote"],.string("old-quote"));XCTAssertEqual(quote["amount"],.number(10));XCTAssertEqual(quote["legacyEventID"],.string("event"))
        XCTAssertThrowsError(try WalletImport.quote(.object(["quoteId":.string("../bad"),"mint":.string(WalletContract.defaultMint),"amount":.number(10)]),eventID:"event"))
    }
    func testMalformedKeyBackupIsRejectedWithoutGeneratingAReplacement() {
        XCTAssertThrowsError(try ImportedWalletConfiguration(.array([.array([.string("privkey"),.string("not-a-key")]),.array([.string("mint"),.string(WalletContract.defaultMint)])])))
        XCTAssertThrowsError(try ImportedWalletConfiguration(.array([.array([.string("mint"),.string(WalletContract.defaultMint)])])))
    }
}
