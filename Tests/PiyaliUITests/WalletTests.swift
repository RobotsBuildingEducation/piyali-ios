import XCTest
import NostrSDK
import CryptoKit

private struct WalletUIFixtureCrypto:ContentSigning,NIP44v2Encrypting {}

@MainActor final class WalletPlayTests:XCTestCase {
    private func reveal(_ element:XCUIElement,in app:XCUIApplication) {
        for _ in 0..<8 where !element.exists || !element.isHittable { app.swipeUp(velocity:.slow) };XCTAssertTrue(element.waitForExistence(timeout:10));XCTAssertTrue(element.isHittable)
    }
    private func open(_ app:XCUIApplication) { app.tabBars.buttons["Account"].tap();let link=app.buttons["walletLink"];reveal(link,in:app);link.tap();XCTAssertTrue(app.navigationBars["Wallet"].waitForExistence(timeout:10)) }
    func testBrowserBackupRequiresExplicitRestoreAndSurvivesRelaunch() async throws {
        continueAfterFailure=false
        let keys=Keypair()!,receiving=Keypair()!,relay=LocalNostrRelay();defer { relay.stop() }
        let tags=[["privkey",receiving.privateKey.hex],["mint","https://mint.minibits.cash/Bitcoin"]],payload=String(data:try JSONSerialization.data(withJSONObject:tags),encoding:.utf8)!
        let content=try WalletUIFixtureCrypto().encrypt(plaintext:payload,privateKeyA:keys.privateKey,publicKeyB:keys.publicKey),createdAt=Int64(Date().timeIntervalSince1970)
        let raw=try JSONSerialization.data(withJSONObject:[0,keys.publicKey.hex,createdAt,375,[[String]](),content],options:[.withoutEscapingSlashes,.fragmentsAllowed]),id=SHA256.hash(data:raw).map { String(format:"%02x",$0) }.joined()
        var events:[[String:Any]]=[["id":id,"pubkey":keys.publicKey.hex,"created_at":createdAt,"kind":375,"tags":[[String]](),"content":content,"sig":try WalletUIFixtureCrypto().signatureForContent(id,privateKey:keys.privateKey.hex)]]
        try await relay.start { frame,connection in
            if frame.first as? String == "REQ",let sub=frame[1] as? String { for event in events { relay.send(["EVENT",sub,event],to:connection) };relay.send(["EOSE",sub],to:connection) }
            else if frame.first as? String == "EVENT",let event=frame[1] as? [String:Any],let id=event["id"] as? String { events.append(event);relay.send(["OK",id,true,""],to:connection) }
        }
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_WALLET_TEST_RELAY"]=relay.url;app.launch()
        let input=app.secureTextFields["nsec private key"];XCTAssertTrue(input.waitForExistence(timeout:10));input.tap();input.typeText(keys.privateKey.nsec);app.buttons["Sign in with key"].tap()
        XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:15));app.buttons["startLearning"].tap();open(app)
        let restore=app.buttons["walletRestoreBrowser"];reveal(restore,in:app);XCTAssertFalse(app.buttons["walletCreate"].exists);XCTAssertFalse(app.buttons["walletDeposit"].exists)
        XCTAssertEqual(relay.frames().filter { $0.first as? String == "EVENT" }.count,0)
        restore.tap();XCTAssertTrue(app.buttons["walletDeposit"].waitForExistence(timeout:15));XCTAssertFalse(restore.exists);XCTAssertFalse(app.buttons["walletPublishReceiving"].exists)
        app.terminate();app.launch();open(app);XCTAssertTrue(app.buttons["walletDeposit"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["walletRestoreBrowser"].exists)
        let published=relay.frames().filter { $0.first as? String == "EVENT" }.compactMap { $0[1] as? [String:Any] }
        XCTAssertEqual(published.count,2);let config=try XCTUnwrap(published.first { $0["kind"] as? Int == 17375 })
        let clear=try WalletUIFixtureCrypto().decrypt(payload:try XCTUnwrap(config["content"] as? String),privateKeyA:keys.privateKey,publicKeyB:keys.publicKey)
        let restored=try XCTUnwrap(JSONSerialization.jsonObject(with:Data(clear.utf8)) as? [[String]])
        XCTAssertEqual(restored.filter { $0.first == "privkey" }.map { $0[1] },[receiving.privateKey.hex])
    }
    func testCreateAndRelaunchRestoreEncryptedWalletWithoutRequestingAnInvoice() async throws {
        continueAfterFailure=false
        let relay=LocalNostrRelay();defer { relay.stop() };var events:[[String:Any]]=[]
        try await relay.start { frame,connection in
            if frame.first as? String == "REQ",let sub=frame[1] as? String { for event in events { relay.send(["EVENT",sub,event],to:connection) };relay.send(["EOSE",sub],to:connection) }
            else if frame.first as? String == "EVENT",let event=frame[1] as? [String:Any],let id=event["id"] as? String { events.append(event);relay.send(["OK",id,true,""],to:connection) }
        }
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_WALLET_TEST_RELAY"]=relay.url;app.launch()
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:10));app.buttons["createAccount"].tap();XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:15));app.buttons["startLearning"].tap();open(app)
        let create=app.buttons["walletCreate"];reveal(create,in:app);create.tap();XCTAssertTrue(app.buttons["walletDeposit"].waitForExistence(timeout:15));XCTAssertEqual(app.staticTexts["walletBalance"].label,"0 sats available")
        let amount=app.textFields["walletDepositAmount"];reveal(amount,in:app);amount.tap();amount.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:2)+"0");app.buttons["Done"].tap();XCTAssertFalse(app.buttons["walletDeposit"].isEnabled)
        amount.tap();amount.typeText(XCUIKeyboardKey.delete.rawValue+"10");app.buttons["Done"].tap();XCTAssertTrue(app.buttons["walletDeposit"].isEnabled)
        let receive=app.buttons["walletReceive"];reveal(receive,in:app);receive.tap()
        let recipient=app.textFields["walletRecipient"];reveal(recipient,in:app);recipient.tap();recipient.typeText("invalid recipient");app.buttons["Done"].tap()
        let preview=app.buttons["walletPreviewTip"];reveal(preview,in:app);preview.tap();let error=app.staticTexts["walletError"];reveal(error,in:app);XCTAssertTrue(error.label.contains("recipient"));XCTAssertFalse(app.buttons["walletSendTip"].exists);let automatic=app.staticTexts["walletAutomaticOff"];reveal(automatic,in:app);XCTAssertTrue(automatic.label.contains("off"))
        app.terminate();app.launch();open(app);XCTAssertTrue(app.buttons["walletDeposit"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["walletCreate"].exists);XCTAssertFalse(app.staticTexts["walletInvoice"].exists)
        let published=relay.frames().filter { $0.first as? String == "EVENT" }.compactMap { $0[1] as? [String:Any] }
        XCTAssertEqual(published.filter { $0["kind"] as? Int == 17375 }.count,1);XCTAssertEqual(published.filter { $0["kind"] as? Int == 10019 }.count,1)
        XCTAssertFalse(published.contains { ($0["content"] as? String ?? "").contains("privkey") })
    }
}
