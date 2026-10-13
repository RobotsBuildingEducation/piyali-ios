import XCTest

@MainActor final class TeamsTests: XCTestCase {
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        _=element.waitForExistence(timeout:2)
        for _ in 0..<5 where !element.isHittable { app.swipeUp(velocity:.slow) }
        for _ in 0..<5 where !element.isHittable { app.swipeDown(velocity:.slow) }
        XCTAssertTrue(element.waitForExistence(timeout:10))
        XCTAssertTrue(element.isHittable)
    }
    private func enter(_ text: String, field: String, app: XCUIApplication) {
        let input=app.descendants(matching:.any)[field];reveal(input,in:app);input.tap();input.typeText(text)
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }
    }
    private func openTeams(_ app: XCUIApplication) {
        app.tabBars.buttons["Account"].tap();let link=app.buttons["Learning teams"];reveal(link,in:app);link.tap()
        XCTAssertTrue(app.navigationBars["Teams"].waitForExistence(timeout:10))
    }
    func testCreateEditRosterAndDeleteUseSignedLocalRelayAndSurviveRelaunch() async throws {
        let relay=LocalNostrRelay();defer { relay.stop() };var events:[[String:Any]]=[]
        try await relay.start { frame,connection in
            if frame.first as? String == "REQ",let sub=frame[1] as? String { for event in events { relay.send(["EVENT",sub,event],to:connection) };relay.send(["EOSE",sub],to:connection) }
            else if frame.first as? String == "EVENT",let event=frame[1] as? [String:Any],let id=event["id"] as? String { events.append(event);relay.send(["OK",id,true,""],to:connection) }
        }
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_TEAM_TEST_RELAY"]=relay.url;app.launch()
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:10));app.buttons["createAccount"].tap()
        XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:10));app.buttons["startLearning"].tap();openTeams(app)
        enter("Weekend",field:"teamName",app:app)
        enter("npub10xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqpkge6d",field:"teamMembers",app:app)
        let create=app.buttons["teamCreate"];reveal(create,in:app);XCTAssertTrue(create.isEnabled);create.tap()
        let row=app.buttons.matching(identifier:"learningTeamRow").firstMatch;reveal(row,in:app);XCTAssertTrue(row.label.contains("2 members"));row.tap()
        XCTAssertTrue(app.navigationBars["Weekend"].waitForExistence(timeout:10))
        let name=app.descendants(matching:.any)["teamEditName"];reveal(name,in:app);name.tap();name.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:7)+"Evening")
        app.buttons["Done"].tap();let rename=app.buttons["teamRename"];reveal(rename,in:app);rename.tap()
        XCTAssertTrue(app.navigationBars["Evening"].waitForExistence(timeout:10))
        enter("npub1ccz8l9zpa47k6vz9gphftsrumpw80rjt3nhnefat4symjhrsnmjs38mnyd",field:"teamAddInput",app:app)
        let add=app.buttons["teamAdd"];reveal(add,in:app);add.tap()
        app.navigationBars.buttons.element(boundBy:0).tap();reveal(row,in:app);XCTAssertTrue(row.label.contains("3 members"))
        app.terminate();app.launch();openTeams(app);reveal(row,in:app);XCTAssertTrue(row.label.contains("Evening"));XCTAssertTrue(row.label.contains("3 members"));row.tap()
        let remove=app.buttons["Delete team"];reveal(remove,in:app);remove.tap()
        XCTAssertTrue(app.sheets.buttons["Delete team"].waitForExistence(timeout:5));app.sheets.buttons["Delete team"].tap()
        XCTAssertTrue(app.staticTexts["No teams found. Refresh to check your relays."].waitForExistence(timeout:10))
        app.terminate();app.launch();openTeams(app)
        XCTAssertTrue(app.staticTexts["No teams found. Refresh to check your relays."].waitForExistence(timeout:10))
        let published=relay.frames().filter { $0.first as? String == "EVENT" }.compactMap { $0[1] as? [String:Any] }
        XCTAssertEqual(published.count,4)
        XCTAssertTrue(published.allSatisfy { ($0["kind"] as? Int) == 30078 && ($0["sig"] as? String)?.count == 128 && ($0["tags"] as? [[String]])?.first?.last?.hasPrefix("learning-team:") == true })
    }
}
