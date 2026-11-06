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
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_PRIVATE_TEAMS_TEST_EMULATOR":"1","PIYALI_TEAM_TEST_RELAY":relay.url,"PIYALI_HEADLINE_FIXTURE":"failure"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch();handleInitialPaperPencil(app)
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Team Learner");tap("entryKeyboardDone",app);tap("createAccount",app);handleInitialPaperPencil(app);chooseEnglishSpanishOnboarding(app);tap("startLearning",app);tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);tap("placementNew",app);tap("productMenu",app);tap("productPanel-teams",app)
        let copy=app.buttons["teamsCopyID"];XCTAssertTrue(copy.waitForExistence(timeout:10));let member=try XCTUnwrap(copy.value as? String);XCTAssertTrue(member.hasPrefix("npub1"));let creator=Keypair()!.publicKey.npub,scope=UUID().uuidString.lowercased(),stamp="2026-10-25T00:00:00.000Z"
        for (id,title) in [("a-"+scope,"Morning Spanish"),("b-"+scope,"Evening English")]{let entry:[String:Any]=["npub":member,"status":"pending","addedAt":stamp,"name":""];try await rest("users/\(creator)/teams/\(id)",["teamName":title,"createdBy":creator,"creatorName":"Luis","createdAt":stamp,"members":[entry]]);try await rest("users/\(member)/teamInvites/team_\(id)",["teamId":id,"teamName":title,"creatorNpub":creator,"invitedBy":creator,"invitedByName":"Luis","status":"pending","createdAt":stamp,"member":entry])}
        // Snapshot listeners must deliver both invitations without closing the drawer.
        XCTAssertTrue(app.staticTexts["Morning Spanish"].waitForExistence(timeout:15));XCTAssertTrue(app.staticTexts["Evening English"].waitForExistence(timeout:15));app.buttons["Accept"].firstMatch.tap();XCTAssertTrue(app.staticTexts["My teams (1)"].waitForExistence(timeout:15));app.buttons["Decline"].firstMatch.tap();XCTAssertTrue(app.staticTexts["My teams (1)"].waitForExistence(timeout:10));XCTAssertFalse(app.buttons["Accept"].exists)
        let leave=app.descendants(matching:.any)["teamRemove"];for _ in 0..<5 where !leave.isHittable{app.swipeUp(velocity:.slow)};guard leave.isHittable else{XCTFail("Leave control is inaccessible");return};leave.tap();XCTAssertTrue(app.sheets.buttons["Leave team"].waitForExistence(timeout:5));app.sheets.buttons["Leave team"].tap();XCTAssertTrue(app.staticTexts["My teams (0)"].waitForExistence(timeout:15));app.terminate();app.launch();handleInitialPaperPencil(app);tap("productMenu",app);tap("productPanel-teams",app);XCTAssertTrue(app.staticTexts["My teams (0)"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["Accept"].exists);XCTAssertFalse(relay.frames().contains{$0.first as? String == "EVENT"})
        for id in ["a-"+scope,"b-"+scope]{try await rest("users/\(creator)/teams/\(id)");try await rest("users/\(member)/teamInvites/team_\(id)")}
    }
}

extension PrivateTeamsPlayTests {
    func testStartupInvitationBadgeViewedQuietNewIDOnFeedAndPrivateRelaunch()async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_FIRESTORE_EMULATOR_TESTS"] == "1" else{throw XCTSkip("Isolated emulator opt-in required")};continueAfterFailure=false
        let relay=LocalNostrRelay();defer{relay.stop()};try await relay.start{frame,connection in if frame.first as? String == "REQ",let sub=frame[1] as? String{relay.send(["EOSE",sub],to:connection)}}
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_PRIVATE_TEAMS_TEST_EMULATOR":"1","PIYALI_TEAM_TEST_RELAY":relay.url,"PIYALI_HEADLINE_FIXTURE":"failure"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Invite Attention Learner");tap("entryKeyboardDone",app);tap("createAccount",app);chooseEnglishSpanishOnboarding(app);tap("startLearning",app);tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);chooseA1Placement(app)
        tap("productMenu",app);tap("productPanel-teams",app);let copy=app.buttons["teamsCopyID"];XCTAssertTrue(copy.waitForExistence(timeout:10));let member=try XCTUnwrap(copy.value as? String);XCTAssertTrue(member.hasPrefix("npub1"));tap("teamsClose",app)
        let creator=Keypair()!.publicKey.npub,scope=UUID().uuidString.lowercased(),stamp="2026-11-06T00:00:00.000Z"
        func seed(_ suffix:String,_ title:String)async throws {
            let id=suffix+"-"+scope,entry:[String:Any]=["npub":member,"status":"pending","addedAt":stamp,"name":""]
            try await rest("users/\(creator)/teams/\(id)",["teamName":title,"createdBy":creator,"creatorName":"Public inviter","createdAt":stamp,"members":[entry]])
            try await rest("users/\(member)/teamInvites/team_\(id)",["teamId":id,"teamName":title,"creatorNpub":creator,"invitedBy":creator,"invitedByName":"Public inviter","status":"pending","createdAt":stamp,"member":entry])
        }
        func value(_ id:String,_ expected:String){XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"value == %@",expected),object:app.buttons[id])],timeout:15),.completed,id)}
        func shot(_ title:String){let a=XCTAttachment(screenshot:app.screenshot());a.name=title;a.lifetime = .keepAlways;add(a)}
        try await seed("a","Morning practice");value("productMenu","Pending invitations: 1");shot("Native Teams invitation arrives while drawer closed")
        tap("productMenu",app);value("productPanel-teams","Pending invitations: 1");shot("Native Teams menu item and trigger show unseen invitation");tap("productPanel-teams",app);XCTAssertTrue(app.staticTexts["Morning practice"].waitForExistence(timeout:15));shot("Native Teams opening Your teams views the pending invitation");tap("teamsClose",app);value("productMenu","")
        try await seed("a","Morning renamed");value("productMenu","");tap("productMenu",app);tap("productPanel-teams",app);try await seed("b","Evening practice");XCTAssertTrue(app.staticTexts["Evening practice"].waitForExistence(timeout:15));tap("teamsClose",app);value("productMenu","");tap("productMenu",app);tap("productPanel-teams",app);tap("teamsFeedTab",app)
        try await seed("c","Weekend practice");XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","(3)"),object:app.buttons["teamsTab"])],timeout:15),.completed);shot("Native Teams new invitation remains unseen on Global feed");tap("teamsClose",app);value("productMenu","Pending invitations: 3")
        tap("productMenu",app);tap("productPanel-teams",app);XCTAssertTrue(app.staticTexts["Morning renamed"].waitForExistence(timeout:15));tap("teamsClose",app);value("productMenu","");app.terminate();app.launch();XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));value("productMenu","Pending invitations: 3");shot("Native Teams pending invitations are unseen again on fresh app startup")
        tap("productMenu",app);tap("productPanel-teams",app);XCTAssertTrue(app.buttons["Decline"].firstMatch.waitForExistence(timeout:15));app.buttons["Decline"].firstMatch.tap();XCTAssertTrue(app.buttons["Decline"].firstMatch.waitForExistence(timeout:15));app.buttons["Decline"].firstMatch.tap();XCTAssertTrue(app.buttons["Decline"].firstMatch.waitForExistence(timeout:15));app.buttons["Decline"].firstMatch.tap();tap("teamsClose",app);value("productMenu","")
        XCTAssertFalse(relay.frames().contains{$0.first as? String == "EVENT"},"Startup reads and legacy invitations must not publish public notes or team progress")
        for suffix in ["a","b","c"]{let id=suffix+"-"+scope;try await rest("users/\(creator)/teams/\(id)");try await rest("users/\(member)/teamInvites/team_\(id)")}
    }
}
