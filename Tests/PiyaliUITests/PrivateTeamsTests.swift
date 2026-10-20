import XCTest
import NostrSDK

@MainActor final class PrivateTeamsPlayTests:XCTestCase {
    private func reveal(_ element:XCUIElement,in app:XCUIApplication) {
        for _ in 0..<7 where !element.exists || !element.isHittable { app.swipeUp(velocity:.slow) }
        for _ in 0..<7 where !element.isHittable { app.swipeDown(velocity:.slow) }
        XCTAssertTrue(element.waitForExistence(timeout:10));XCTAssertTrue(element.isHittable)
    }
    private func input(_ value:String,id:String,app:XCUIApplication,replace:Int=0) {
        let field=app.descendants(matching:.any)[id];reveal(field,in:app);field.tap();field.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:replace)+value)
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }
    }
    private func start(_ relay:LocalNostrRelay) async throws -> XCUIApplication {
        guard ProcessInfo.processInfo.environment["PIYALI_FIRESTORE_EMULATOR_TESTS"] == "1" else { throw XCTSkip("Use scripts/test-private-teams.sh --ui with its demo Firestore emulator.") }
        continueAfterFailure=false
        try await relay.start { frame,connection in if frame.first as? String == "REQ",let id=frame[1] as? String { relay.send(["EOSE",id],to:connection) } }
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_PRIVATE_TEAMS_TEST_EMULATOR"]="1";app.launchEnvironment["PIYALI_TEAM_TEST_RELAY"]=relay.url;app.launch()
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:10));app.buttons["createAccount"].tap();XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:15));app.buttons["startLearning"].tap();return app
    }
    private func open(_ app:XCUIApplication) {
        app.tabBars.buttons["Account"].tap();let teams=app.buttons["Learning teams"];reveal(teams,in:app);teams.tap()
        let link=app.buttons["privateTeamsLink"];reveal(link,in:app);link.tap();XCTAssertTrue(app.navigationBars["Private teams"].waitForExistence(timeout:10))
    }
    func testCreateRenameInviteShareRelaunchAndDeletePrivateTeam() async throws {
        let relay=LocalNostrRelay();defer { relay.stop() };let app=try await start(relay)
        open(app);input("Weekend",id:"privateTeamName",app:app);input(Keypair()!.publicKey.npub,id:"privateTeamMembers",app:app)
        let create=app.buttons["privateTeamCreate"];reveal(create,in:app);create.tap()
        let row=app.buttons.matching(identifier:"privateTeamRow").firstMatch;reveal(row,in:app);XCTAssertTrue(row.label.contains("1 invited"));row.tap()
        input("Evening",id:"privateTeamEditName",app:app,replace:7);let rename=app.buttons["privateTeamRename"];reveal(rename,in:app);rename.tap();XCTAssertTrue(app.navigationBars["Evening"].waitForExistence(timeout:15))
        input(Keypair()!.publicKey.npub,id:"privateTeamAddInput",app:app);let add=app.buttons["privateTeamAdd"];reveal(add,in:app);add.tap()
        let share=app.buttons["privateTeamShare"];reveal(share,in:app);share.tap()
        app.terminate();app.launch();open(app);reveal(row,in:app);XCTAssertTrue(row.label.contains("Evening"));XCTAssertTrue(row.label.contains("2 invited"));row.tap()
        let remove=app.buttons["Delete private team"];reveal(remove,in:app);remove.tap();XCTAssertTrue(app.sheets.buttons["Delete private team"].waitForExistence(timeout:5));app.sheets.buttons["Delete private team"].tap()
        XCTAssertTrue(app.staticTexts["No private teams yet."].waitForExistence(timeout:15));app.terminate();app.launch();open(app);XCTAssertTrue(app.staticTexts["No private teams yet."].waitForExistence(timeout:15))
        XCTAssertFalse(relay.frames().contains { $0.first as? String == "EVENT" })
    }
    func testAccountSwitchShowsOnlyItsInvitationThenAcceptsAndLeaves() async throws {
        let relay=LocalNostrRelay();defer { relay.stop() };let app=try await start(relay),receiver=Keypair()!
        open(app);input("Invitation",id:"privateTeamName",app:app);input(receiver.publicKey.npub,id:"privateTeamMembers",app:app)
        let create=app.buttons["privateTeamCreate"];reveal(create,in:app);create.tap();XCTAssertTrue(app.buttons.matching(identifier:"privateTeamRow").firstMatch.waitForExistence(timeout:15))
        app.navigationBars.buttons.element(boundBy:0).tap();app.navigationBars.buttons.element(boundBy:0).tap()
        input(receiver.privateKey.nsec,id:"Import another nsec",app:app);let change=app.buttons["Switch account"];reveal(change,in:app);change.tap();XCTAssertTrue(app.sheets.buttons["Switch account"].waitForExistence(timeout:5));app.sheets.buttons["Switch account"].tap()
        XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:15));app.buttons["startLearning"].tap();open(app)
        XCTAssertFalse(app.buttons.matching(identifier:"privateTeamRow").firstMatch.exists)
        let accept=app.buttons["privateTeamAccept"];reveal(accept,in:app);accept.tap();let row=app.buttons.matching(identifier:"privateTeamRow").firstMatch;reveal(row,in:app);row.tap()
        let leave=app.buttons["Leave private team"];reveal(leave,in:app);leave.tap();XCTAssertTrue(app.sheets.buttons["Leave private team"].waitForExistence(timeout:5));app.sheets.buttons["Leave private team"].tap();XCTAssertTrue(app.staticTexts["No private teams yet."].waitForExistence(timeout:15))
        XCTAssertFalse(relay.frames().contains { $0.first as? String == "EVENT" })
    }
}
