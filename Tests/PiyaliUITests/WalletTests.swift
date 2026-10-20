import XCTest

@MainActor final class WalletPlayTests:XCTestCase {
    private func reveal(_ element:XCUIElement,in app:XCUIApplication) {
        for _ in 0..<8 where !element.exists || !element.isHittable { app.swipeUp(velocity:.slow) };XCTAssertTrue(element.waitForExistence(timeout:10));XCTAssertTrue(element.isHittable)
    }
    private func open(_ app:XCUIApplication) { app.tabBars.buttons["Account"].tap();let link=app.buttons["walletLink"];reveal(link,in:app);link.tap();XCTAssertTrue(app.navigationBars["Wallet"].waitForExistence(timeout:10)) }
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
        app.terminate();app.launch();open(app);XCTAssertTrue(app.buttons["walletDeposit"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["walletCreate"].exists);XCTAssertFalse(app.staticTexts["walletInvoice"].exists)
        let published=relay.frames().filter { $0.first as? String == "EVENT" }.compactMap { $0[1] as? [String:Any] }
        XCTAssertEqual(published.filter { $0["kind"] as? Int == 17375 }.count,1);XCTAssertEqual(published.filter { $0["kind"] as? Int == 10019 }.count,1)
        XCTAssertFalse(published.contains { ($0["content"] as? String ?? "").contains("privkey") })
    }
}
