import XCTest
import UIKit
import Network
import NostrSDK

@MainActor final class TeamsTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication){let e=app.buttons[id];XCTAssertTrue(e.waitForExistence(timeout:15),id);XCTAssertTrue(e.isHittable,id);if !e.isEnabled{XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:e)],timeout:15),.completed,"Action finishes saving before "+id)};e.tap()}
    private func enter(_ value:String,_ id:String,_ app:XCUIApplication){let e=app.textFields[id];XCTAssertTrue(e.waitForExistence(timeout:10));e.tap();e.typeText(value+"\n")}
    private func replaceValue(_ id:String,with value:String,rtl:Bool,_ app:XCUIApplication){
        let field=app.textFields[id];XCTAssertTrue(field.waitForExistence(timeout:10));field.tap()
        let previous=field.value as? String ?? "",width=(previous as NSString).size(withAttributes:[.font:UIFont.systemFont(ofSize:16)]).width
        // These existing values are single Latin words. Select the actual text,
        // independently of caret affinity or an edit-menu activation point.
        field.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:rtl ? field.frame.width-16-width/2:16+width/2,dy:field.frame.height/2)).doubleTap()
        field.typeText(value);XCTAssertEqual(field.value as? String,value,"Replace the complete selected value before submitting");field.typeText("\n")
    }
    private func open(_ app:XCUIApplication){tap("productMenu",app);tap("productPanel-teams",app);XCTAssertTrue(app.buttons["teamsClose"].waitForExistence(timeout:10))}
    private func shot(_ name:String,_ app:XCUIApplication){let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    private func reveal(_ id:String,_ app:XCUIApplication)->XCUIElement{let e=app.descendants(matching:.any)[id];for _ in 0..<6 where !e.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(e.isHittable,id);if !e.isEnabled{XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:e)],timeout:15),.completed,"Action finishes saving before "+id)};return e}
    func testCreateEditRosterAndDeleteUseSignedLocalRelayAndSurviveRelaunch()async throws {try await signedRosterJourney(arabic:false)}
    func testArabicSettingsThenCreateRenameAddAndPrivateRelaunchUsesMirroredNativeTeamsControls()async throws {try await signedRosterJourney(arabic:true)}
    private func signedRosterJourney(arabic:Bool)async throws {
        continueAfterFailure=false
        let relay=LocalNostrRelay();defer{relay.stop()};var events:[[String:Any]]=[]
        try await relay.start{frame,connection in
            if frame.first as? String == "REQ",let sub=frame[1] as? String{for event in events{relay.send(["EVENT",sub,event],to:connection)};relay.send(["EOSE",sub],to:connection)}else if frame.first as? String == "EVENT",let event=frame[1] as? [String:Any],let id=event["id"] as? String{events.append(event);relay.send(["OK",id,true,""],to:connection)}
        }
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_TEAM_TEST_RELAY":relay.url,"PIYALI_PRIVATE_TEAMS_TEST_EMULATOR":"1","PIYALI_HEADLINE_FIXTURE":"failure"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme",arabic ? "dark":"light"];app.launch();handleInitialPaperPencil(app)
        let entryName=app.textFields["entryName"];XCTAssertTrue(entryName.waitForExistence(timeout:15));entryName.tap();entryName.typeText("Team Learner");tap("entryKeyboardDone",app);tap("createAccount",app);handleInitialPaperPencil(app);chooseEnglishSpanishOnboarding(app);tap("startLearning",app);tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);tap("placementNew",app)
        if arabic{tap("productMenu",app);tap("productPanel-settings",app);tap("supportLanguagePicker",app);tap("settingsLanguage-support-ar",app);tap("productPanelClose",app)}
        open(app);XCTAssertTrue(app.staticTexts["My teams (0)"].waitForExistence(timeout:10));shot(arabic ? "Native Arabic Teams empty product":"Native Teams empty product",app);if arabic{XCTAssertGreaterThan(app.buttons["teamCreateOpen"].frame.midX,app.buttons["teamsCopyID"].frame.midX);XCTAssertGreaterThan(app.buttons["teamsClose"].frame.midX,app.frame.midX)};tap("teamsCopyID",app);let copyClose=app.buttons["teamsNoticeClose"];XCTAssertTrue(copyClose.exists);if arabic{XCTAssertGreaterThan(copyClose.frame.midX,app.frame.midX)};copyClose.tap();tap("teamCreateOpen",app)
        enter("Weekend","teamName",app);enter("bad","teamMembers",app);XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"identifier == %@ AND label CONTAINS %@","teamsNoticeDescription","Invalid npub format")).firstMatch.waitForExistence(timeout:5));XCTAssertFalse(app.staticTexts["teamFormError"].exists);replaceValue("teamMembers",with:"npub10xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqpkge6d",rtl:arabic,app);XCTAssertTrue(app.staticTexts["Members to Invite (1)"].waitForExistence(timeout:5));shot("Native Teams queued product",app);tap("teamCreate",app)
        XCTAssertTrue(app.buttons["learningTeamRow"].waitForExistence(timeout:20));XCTAssertEqual(app.buttons["learningTeamRow"].label,"Weekend");XCTAssertTrue(app.staticTexts["Team Learner"].exists);shot("Native Teams single product",app);tap("teamEdit",app);replaceValue("teamEditName",with:"Evening",rtl:arabic,app);tap("teamRename",app);XCTAssertTrue(app.buttons["learningTeamRow"].waitForExistence(timeout:15));XCTAssertEqual(app.buttons["learningTeamRow"].label,"Evening")
        tap("teamAddOpen",app);enter("npub1ccz8l9zpa47k6vz9gphftsrumpw80rjt3nhnefat4symjhrsnmjs38mnyd","teamMembers",app);tap("teamAdd",app);XCTAssertTrue(app.buttons["learningTeamRow"].waitForExistence(timeout:15));XCTAssertEqual(app.buttons["learningTeamRow"].label,"Evening")
        app.terminate();app.launch();handleInitialPaperPencil(app);open(app);if arabic{XCTAssertGreaterThan(app.buttons["teamCreateOpen"].frame.midX,app.buttons["teamsCopyID"].frame.midX)};XCTAssertTrue(app.buttons["learningTeamRow"].waitForExistence(timeout:20));XCTAssertEqual(app.buttons["learningTeamRow"].label,"Evening");shot("Native Teams restored product",app)
        reveal("teamRemove",app).tap();let remove=app.sheets.buttons["Delete team"];XCTAssertTrue(remove.waitForExistence(timeout:5));remove.tap();XCTAssertTrue(app.staticTexts["My teams (0)"].waitForExistence(timeout:20));app.terminate();app.launch();handleInitialPaperPencil(app);open(app);if arabic{XCTAssertGreaterThan(app.buttons["teamCreateOpen"].frame.midX,app.buttons["teamsCopyID"].frame.midX)};XCTAssertTrue(app.staticTexts["My teams (0)"].waitForExistence(timeout:20));tap("teamsFeedTab",app);XCTAssertTrue(app.staticTexts["No posts yet. Start the conversation!"].waitForExistence(timeout:10));shot("Native Teams feed product",app)
        let published=relay.frames().filter{$0.first as? String == "EVENT"}.compactMap{$0[1] as? [String:Any]},rosters=published.filter{($0["tags"] as? [[String]])?.contains(where:{$0.first == "d" && $0.last?.hasPrefix("learning-team:")==true}) == true}
        XCTAssertEqual(rosters.count,4);XCTAssertTrue(rosters.allSatisfy{($0["kind"] as? Int)==30078 && ($0["sig"] as? String)?.count==128});XCTAssertTrue(published.contains{($0["tags"] as? [[String]])?.contains(["d","learning-progress"])==true})
    }
}


private final class HeldTeamRenameRelay:@unchecked Sendable {
    private let lock=NSLock()
    private var events:[[String:Any]]=[]
    private var hold=false,pending:(String,NWConnection)?
    func arm(){lock.withLock{hold=true}}
    var waiting:Bool{lock.withLock{pending != nil}}
    func handle(_ frame:[Any],_ connection:NWConnection,relay:LocalNostrRelay){
        if frame.first as? String == "REQ",let sub=frame[1] as? String{for event in lock.withLock({events}){relay.send(["EVENT",sub,event],to:connection)};relay.send(["EOSE",sub],to:connection)}
        else if frame.first as? String == "EVENT",let event=frame[1] as? [String:Any],let id=event["id"] as? String{
            let held=lock.withLock{()->Bool in if hold,(event["tags"] as? [[String]])?.contains(where:{$0.first == "d" && $0.last?.hasPrefix("learning-team:")==true}) == true{hold=false;pending=(id,connection);return true};events.append(event);return false};if !held{relay.send(["OK",id,true,""],to:connection)}
        }
    }
    func reject(_ relay:LocalNostrRelay){let held=lock.withLock{()->(String,NWConnection)? in let v=pending;pending=nil;return v};if let(id,connection)=held{relay.send(["OK",id,false,"Public fixture rejected rename"],to:connection)}}
}
extension TeamsTests {
    private func fixtureWrite(_ path:String,_ fields:[String:Any]?=nil)async throws {
        func field(_ value:Any)->[String:Any]{if let v=value as? String{return["stringValue":v]};if let v=value as? [String:Any]{return["mapValue":["fields":v.mapValues(field)]]};if let v=value as? [[String:Any]]{return["arrayValue":["values":v.map{field($0)}]]};return["nullValue":NSNull()]}
        var request=URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:8180/v1/projects/demo-piyali-ios/databases/(default)/documents/"+path)));request.httpMethod=fields == nil ? "DELETE":"PATCH"
        if let fields{request.setValue("application/json",forHTTPHeaderField:"Content-Type");request.httpBody=try JSONSerialization.data(withJSONObject:["fields":fields.mapValues(field)])};let(_,response)=try await URLSession.shared.data(for:request);XCTAssertTrue([200,404].contains((response as? HTTPURLResponse)?.statusCode ?? 0))
    }
    func testIncomingInvitationSurvivesHeldRejectedRenameAndRelaunchWithoutAcceptingTheFailedRoster()async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_FIRESTORE_EMULATOR_TESTS"] == "1" else{throw XCTSkip("Isolated local Firebase required")};continueAfterFailure=false
        let relay=LocalNostrRelay(),state=HeldTeamRenameRelay();defer{relay.stop()};try await relay.start{state.handle($0,$1,relay:relay)}
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_TEAM_TEST_RELAY":relay.url,"PIYALI_PRIVATE_TEAMS_TEST_EMULATOR":"1","PIYALI_HEADLINE_FIXTURE":"failure"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch();let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Live Team Learner");tap("entryKeyboardDone",app);tap("createAccount",app);chooseEnglishSpanishOnboarding(app);tap("startLearning",app);tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);chooseA1Placement(app);open(app)
        let member=try XCTUnwrap(app.buttons["teamsCopyID"].value as? String);tap("teamCreateOpen",app);enter("Weekend","teamName",app);enter("npub10xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqpkge6d","teamMembers",app);tap("teamCreate",app);XCTAssertTrue(app.buttons["learningTeamRow"].waitForExistence(timeout:20));tap("teamEdit",app);let input=app.textFields["teamEditName"];XCTAssertTrue(input.waitForExistence(timeout:10));input.tap();input.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:7)+"Evening\n");state.arm();tap("teamRename",app)
        for _ in 0..<100 where !state.waiting{try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(state.waiting)
        let creator=Keypair()!.publicKey.npub,id="incoming-"+UUID().uuidString.lowercased(),stamp="2026-11-06T00:00:00.000Z",entry:[String:Any]=["npub":member,"status":"pending","addedAt":stamp,"name":""]
        try await fixtureWrite("users/\(creator)/teams/\(id)",["teamName":"Incoming while busy","createdBy":creator,"creatorName":"Public inviter","createdAt":stamp,"members":[entry]])
        try await fixtureWrite("users/\(member)/teamInvites/team_\(id)",["teamId":id,"teamName":"Incoming while busy","creatorNpub":creator,"invitedBy":creator,"invitedByName":"Public inviter","status":"pending","createdAt":stamp,"member":entry]);shot("Native Teams invitation delivered during held rename",app)
        state.reject(relay);XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"identifier == %@ AND label CONTAINS %@","teamsNoticeDescription","No relay acknowledged this update.")).firstMatch.waitForExistence(timeout:15));XCTAssertFalse(app.staticTexts["teamFormError"].exists);shot("Native Teams rejected rename retains its error",app);tap("teamEditorClose",app);XCTAssertTrue(app.staticTexts["Incoming while busy"].waitForExistence(timeout:10));XCTAssertTrue(app.buttons["learningTeamRow"].label.contains("Weekend"));XCTAssertFalse(app.buttons["learningTeamRow"].label.contains("Evening"));shot("Native Teams pending invitation remains after failed mutation",app)
        app.terminate();app.launch();open(app);XCTAssertTrue(app.staticTexts["Incoming while busy"].waitForExistence(timeout:15));XCTAssertTrue(app.buttons["learningTeamRow"].label.contains("Weekend"));shot("Native Teams old signed name and incoming invitation restore",app)
        XCTAssertTrue(app.buttons["Decline"].firstMatch.waitForExistence(timeout:10),"Restored invitation can be declined")
        app.buttons["Decline"].firstMatch.tap()
        let declined=app.staticTexts.matching(NSPredicate(format:"identifier == %@ AND label == %@","teamsNoticeTitle","Invite declined")).firstMatch
        XCTAssertTrue(declined.waitForExistence(timeout:10),"Decline displays the original success notice")
        let remove=reveal("teamRemove",app),notice=app.otherElements["teamsNotice"].firstMatch
        let deleteFrame=remove.frame,noticeFrame=notice.exists ? notice.frame:.zero
        let readiness:[String:Any] = ["enabled":remove.isEnabled,"deleteFrame":String(describing:deleteFrame),"noticeFrame":String(describing:noticeFrame),"overlaps":deleteFrame.intersects(noticeFrame)]
        let readyTrace=XCTAttachment(data:try JSONSerialization.data(withJSONObject:readiness,options:[.sortedKeys]),uniformTypeIdentifier:"public.json");readyTrace.name="Native Teams bottom action and notice bounds";readyTrace.lifetime = .keepAlways;add(readyTrace)
        shot("Native Teams decline notice above bottom action",app)
        // Ordinary source toasts have no close button and cover underlying content.
        // XCTest's isHittable does not account for our separate non-key notice window.
        await fulfillment(of:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:declined)],timeout:7)
        XCTAssertFalse(declined.exists,"The five-second notice expires before tapping its covered action")
        remove.tap()
        let deletion=app.sheets.buttons["Delete team"]
        XCTAssertTrue(deletion.waitForExistence(timeout:10),"Native confirmation appears after the notice clears")
        XCTAssertTrue(deletion.isHittable)
        shot("Native Teams deletion confirmation after decline notice",app)
        deletion.tap()
        XCTAssertTrue(app.staticTexts["My teams (0)"].waitForExistence(timeout:15),"Confirmed deletion removes the old signed team")
        try await fixtureWrite("users/\(creator)/teams/\(id)");try await fixtureWrite("users/\(member)/teamInvites/team_\(id)")
        let published=relay.frames().filter{$0.first as? String == "EVENT"}.compactMap{$0[1] as? [String:Any]};XCTAssertTrue(published.allSatisfy{($0["kind"] as? Int)==30078});XCTAssertFalse(published.contains{($0["kind"] as? Int)==1})
    }
}
