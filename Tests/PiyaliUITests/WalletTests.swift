import XCTest
import NostrSDK
import CryptoKit

private struct WalletUIFixtureCrypto:ContentSigning,NIP44v2Encrypting {}

@MainActor final class WalletPlayTests:XCTestCase {
    private func reveal(_ element:XCUIElement,in app:XCUIApplication) {
        let scrollContent=element.identifier.hasPrefix("wallet")
        for _ in 0..<12 {
            let frame=element.exists ? element.frame:.zero,above=scrollContent && frame.midY>0 && frame.midY<app.frame.height*0.37,below=scrollContent && frame.midY>app.frame.height*0.91
            if element.exists && element.isHittable && !above && !below{break}
            let from=app.coordinate(withNormalizedOffset:CGVector(dx:0.96,dy:above ? 0.44:0.78)),to=app.coordinate(withNormalizedOffset:CGVector(dx:0.96,dy:above ? 0.78:0.44));from.press(forDuration:0.1,thenDragTo:to,withVelocity:.slow,thenHoldForDuration:0.1)
        };XCTAssertTrue(element.waitForExistence(timeout:10));XCTAssertTrue(element.isHittable)
    }
    private func tap(_ id:String,_ app:XCUIApplication){let button=app.buttons[id];XCTAssertTrue(button.waitForExistence(timeout:15),id);reveal(button,in:app);button.tap()}
    private func photo(_ title:String,_ app:XCUIApplication){let shot=XCTAttachment(screenshot:app.screenshot());shot.name=title;shot.lifetime = .keepAlways;add(shot)}
    private func open(_ app:XCUIApplication) {tap("productMenu",app);tap("productPanel-settings",app);tap("settingsTab-account",app);tap("walletLink",app);XCTAssertTrue(app.descendants(matching:.any).matching(identifier:"walletPanel").firstMatch.waitForExistence(timeout:10))}
    private func configure(_ app:XCUIApplication,_ relay:LocalNostrRelay){app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_SETTINGS_FIXTURE":"1","PIYALI_WALLET_TEST_RELAY":relay.url];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()}
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
        let app=XCUIApplication();configure(app,relay)
        tap("entrySignIn",app);let input=app.secureTextFields["entrySecret"];XCTAssertTrue(input.waitForExistence(timeout:10));input.tap();input.typeText(keys.privateKey.nsec);tap("entryKeyboardDone",app);tap("entrySubmitSignIn",app)
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
        let app=XCUIApplication();configure(app,relay)
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Wallet Learner");tap("entryKeyboardDone",app);tap("createAccount",app);XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:15));app.buttons["startLearning"].tap();open(app)
        let create=app.buttons["walletCreate"];reveal(create,in:app);photo("Native wallet source create accordion",app);create.tap();XCTAssertTrue(app.buttons["walletDeposit"].waitForExistence(timeout:15));reveal(app.buttons["walletDeposit"],in:app);XCTAssertFalse(app.buttons["walletDeposit"].isEnabled)
        tap("walletRecipient-Girls On Campus",app);XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"selected == true"),object:app.buttons["walletRecipient-Girls On Campus"])],timeout:3),.completed);XCTAssertTrue(app.buttons["walletDeposit"].isEnabled);XCTAssertEqual(app.staticTexts["walletBalance"].label,"Balance: ₿0");photo("Native wallet recipient and unfunded card",app)
        tap("walletTools",app);guard app.navigationBars["Wallet"].waitForExistence(timeout:10) else{photo("Wallet tools failed to open",app);XCTFail("Payment tools must open from Account");return};photo("Native wallet payment tools",app);let automatic=app.staticTexts["walletAutomaticOff"];for _ in 0..<8 where !automatic.exists || !automatic.isHittable{app.collectionViews.firstMatch.swipeUp(velocity:.slow)};guard automatic.exists else{let tree=XCTAttachment(string:app.debugDescription);tree.name="Wallet tools accessibility tree";add(tree);XCTFail("Automatic tips status missing");return};XCTAssertTrue(automatic.label.contains("off"));let close=app.buttons["walletToolsClose"];XCTAssertTrue(close.waitForExistence(timeout:5));close.tap()
        app.terminate();app.launch();open(app);XCTAssertTrue(app.buttons["walletDeposit"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["walletCreate"].exists);XCTAssertFalse(app.staticTexts["walletInvoice"].exists);XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"selected == true"),object:app.buttons["walletRecipient-Girls On Campus"])],timeout:3),.completed);reveal(app.buttons["walletDeposit"],in:app);XCTAssertTrue(app.buttons["walletDeposit"].isEnabled);photo("Native wallet recipient restored after relaunch",app)
        let published=relay.frames().filter { $0.first as? String == "EVENT" }.compactMap { $0[1] as? [String:Any] }
        XCTAssertEqual(published.filter { $0["kind"] as? Int == 17375 }.count,1);XCTAssertEqual(published.filter { $0["kind"] as? Int == 10019 }.count,1)
        XCTAssertFalse(published.contains { ($0["content"] as? String ?? "").contains("privkey") })
    }
}
