import XCTest
import NostrSDK

/// Existing web invitations enter the same drawer as signed public teams.
@MainActor final class PrivateTeamsPlayTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication){let e=app.buttons[id];XCTAssertTrue(e.waitForExistence(timeout:15),id);e.tap()}
    private func rest(_ path:String,_ fields:[String:Any]?=nil)async throws{
        var request=URLRequest(url:URL(string:"http://127.0.0.1:8180/v1/projects/demo-piyali-ios/databases/(default)/documents/"+path)!)
        request.httpMethod=fields == nil ? "DELETE":"PATCH"
        if let fields{request.setValue("application/json",forHTTPHeaderField:"Content-Type");request.httpBody=try JSONSerialization.data(withJSONObject:["fields":fields.mapValues(Self.field)])}
        let(_,response)=try await URLSession.shared.data(for:request);XCTAssertTrue([200,404].contains((response as? HTTPURLResponse)?.statusCode ?? 0))
    }
    private static func field(_ value:Any)->[String:Any]{if let x=value as? String{return["stringValue":x]};if let x=value as? [String:Any]{return["mapValue":["fields":x.mapValues(field)]]};if let x=value as? [[String:Any]]{return["arrayValue":["values":x.map{field($0)}]]};return["nullValue":NSNull()]}
    func testIncomingLegacyInvitationsAcceptDeclineAndLeaveInMainDrawer()async throws{
        guard ProcessInfo.processInfo.environment["PIYALI_FIRESTORE_EMULATOR_TESTS"] == "1" else{throw XCTSkip("Isolated Firestore emulator opt-in required")};continueAfterFailure=false
        let relay=LocalNostrRelay();defer{relay.stop()};try await relay.start{frame,connection in if frame.first as? String == "REQ",let sub=frame[1] as? String{relay.send(["EOSE",sub],to:connection)}}
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_PRIVATE_TEAMS_TEST_EMULATOR":"1","PIYALI_TEAM_TEST_RELAY":relay.url,"PIYALI_HEADLINE_FIXTURE":"failure"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Team Learner");tap("entryKeyboardDone",app);tap("createAccount",app);tap("startLearning",app);tap("companionContinue",app);tap("gettingStartedGotIt",app);tap("placementNew",app);tap("productMenu",app);tap("productPanel-teams",app)
        let copy=app.buttons["teamsCopyID"];XCTAssertTrue(copy.waitForExistence(timeout:10));let member=try XCTUnwrap(copy.value as? String);XCTAssertTrue(member.hasPrefix("npub1"));let creator=Keypair()!.publicKey.npub,scope=UUID().uuidString.lowercased(),stamp="2026-10-25T00:00:00.000Z"
        for (id,title) in [("a-"+scope,"Morning Spanish"),("b-"+scope,"Evening English")]{let entry:[String:Any]=["npub":member,"status":"pending","addedAt":stamp,"name":""];try await rest("users/\(creator)/teams/\(id)",["teamName":title,"createdBy":creator,"creatorName":"Luis","createdAt":stamp,"members":[entry]]);try await rest("users/\(member)/teamInvites/team_\(id)",["teamId":id,"teamName":title,"creatorNpub":creator,"invitedBy":creator,"invitedByName":"Luis","status":"pending","createdAt":stamp,"member":entry])}
        // Snapshot listeners must deliver both invitations without closing the drawer.
        XCTAssertTrue(app.staticTexts["Morning Spanish"].waitForExistence(timeout:15));XCTAssertTrue(app.staticTexts["Evening English"].waitForExistence(timeout:15));app.buttons["Accept"].firstMatch.tap();XCTAssertTrue(app.staticTexts["My teams (1)"].waitForExistence(timeout:15));app.buttons["Decline"].firstMatch.tap();XCTAssertTrue(app.staticTexts["My teams (1)"].waitForExistence(timeout:10));XCTAssertFalse(app.buttons["Accept"].exists)
        let leave=app.descendants(matching:.any)["teamRemove"];for _ in 0..<5 where !leave.isHittable{app.swipeUp(velocity:.slow)};guard leave.isHittable else{XCTFail("Leave control is inaccessible");return};leave.tap();XCTAssertTrue(app.sheets.buttons["Leave team"].waitForExistence(timeout:5));app.sheets.buttons["Leave team"].tap();XCTAssertTrue(app.staticTexts["My teams (0)"].waitForExistence(timeout:15));app.terminate();app.launch();tap("productMenu",app);tap("productPanel-teams",app);XCTAssertTrue(app.staticTexts["My teams (0)"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["Accept"].exists);XCTAssertFalse(relay.frames().contains{$0.first as? String == "EVENT"})
        for id in ["a-"+scope,"b-"+scope]{try await rest("users/\(creator)/teams/\(id)");try await rest("users/\(member)/teamInvites/team_\(id)")}
    }
}
