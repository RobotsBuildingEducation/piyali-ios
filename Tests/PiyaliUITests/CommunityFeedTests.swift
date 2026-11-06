import XCTest
@MainActor final class CommunityFeedPlayTests:XCTestCase {
    func testFeedOnlyPublishesAfterPreviewAndExplicitConfirmation() async throws {
        continueAfterFailure=false
        let relay=LocalNostrRelay();defer { relay.stop() };var events:[[String:Any]]=[]
        try await relay.start { frame,connection in
            if frame.first as? String == "REQ",let sub=frame[1] as? String { for event in events { relay.send(["EVENT",sub,event],to:connection) };relay.send(["EOSE",sub],to:connection) }
            else if frame.first as? String == "EVENT",let event=frame[1] as? [String:Any],let id=event["id"] as? String { events.append(event);relay.send(["OK",id,true,""],to:connection) }
        }
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_TEAM_TEST_RELAY"]=relay.url;app.launch();handleInitialPaperPencil(app)
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:10));app.buttons["createAccount"].tap();handleInitialPaperPencil(app);XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:10));app.buttons["startLearning"].tap();app.tabBars.buttons["Account"].tap()
        let teams=app.buttons["Learning teams"];for _ in 0..<6 where !teams.isHittable { app.swipeUp(velocity:.slow) };teams.tap()
        let feed=app.buttons["communityFeedLink"];XCTAssertTrue(feed.waitForExistence(timeout:10));feed.tap()
        XCTAssertTrue(app.navigationBars["Community feed"].waitForExistence(timeout:10));XCTAssertTrue(app.staticTexts["No learning posts yet. Pull to refresh."].waitForExistence(timeout:10))
        XCTAssertFalse(relay.frames().contains { $0.first as? String == "EVENT" })
        app.buttons["communityShare"].tap();XCTAssertTrue(app.buttons["communityConfirm"].waitForExistence(timeout:5));app.buttons["Cancel"].tap()
        XCTAssertFalse(relay.frames().contains { $0.first as? String == "EVENT" })
        app.buttons["communityShare"].tap();app.buttons["communityConfirm"].tap()
        XCTAssertTrue(app.staticTexts["communityPublished"].waitForExistence(timeout:15));XCTAssertTrue(app.staticTexts["Total XP: 0"].waitForExistence(timeout:10))
        app.buttons["Refresh"].tap()
        let published=relay.frames().filter { $0.first as? String == "EVENT" }.compactMap { $0[1] as? [String:Any] }
        XCTAssertEqual(published.count,1);XCTAssertEqual(published.first?["kind"] as? Int,1);XCTAssertEqual((published.first?["sig"] as? String)?.count,128)
    }
}
