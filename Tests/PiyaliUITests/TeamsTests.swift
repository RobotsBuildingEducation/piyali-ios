import XCTest
import UIKit
import Network
import CryptoKit
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


private struct TeamsFeedFixtureCrypto:ContentSigning {}
private final class ControlledTeamFeedRelay:@unchecked Sendable {
    enum Mode{case failure,posts,ordinary,banned,missingProfile,metadataFailure,mixed}
    private let lock=NSLock()
    private var mode:Mode = .failure
    private(set) var post:[String:Any]=[:],profile:[String:Any]=[:],ordinary:[String:Any]=[:],banned:[String:Any]=[:]
    init()throws {
        let keys=Keypair()!
        func event(kind:Int,tags:[[String]],content:String)throws->[String:Any]{
            let now=Int64(Date().timeIntervalSince1970),data=try JSONSerialization.data(withJSONObject:[0,keys.publicKey.hex,now,kind,tags,content],options:[.withoutEscapingSlashes]),id=SHA256.hash(data:data).map{String(format:"%02x",$0)}.joined()
            return ["id":id,"pubkey":keys.publicKey.hex,"created_at":now,"kind":kind,"tags":tags,"content":content,"sig":try TeamsFeedFixtureCrypto().signatureForContent(id,privateKey:keys.privateKey.hex)]
        }
        post=try event(kind:1,tags:[["t","LearnWithNostr"],["purpose","nosaboProgress"],["total_xp","1250"],["daily_goal_percent","67"]],content:"I just reached 1250 XP! https://piyali.app #LearnWithNostr")
        profile=try event(kind:0,tags:[],content:"{\"name\":\"Community learner\"}")
        ordinary=try event(kind:1,tags:[["t","LearnWithNostr"]],content:"A community greeting")
        banned=try event(kind:0,tags:[],content:"{\"name\":\"TEST\"}")
    }
    func set(_ next:Mode){lock.withLock{mode=next}}
    func handle(_ frame:[Any],_ connection:NWConnection,relay:LocalNostrRelay){
        guard frame.first as? String == "REQ",let id=frame[1] as? String,let filter=frame.last as? [String:Any] else{return}
        if (filter["kinds"] as? [Int]) == [1]{
            let current=lock.withLock{mode}
            switch current{case .failure:relay.send(["CLOSED",id,"Community relay unavailable"],to:connection);default:
                if case .ordinary=current{relay.send(["EVENT",id,ordinary],to:connection)}else{relay.send(["EVENT",id,post],to:connection);if case .mixed=current{relay.send(["EVENT",id,ordinary],to:connection)}}
                relay.send(["EOSE",id],to:connection)
            }
        }else{
            if (filter["kinds"] as? [Int]) == [0]{let current=lock.withLock{mode};switch current{case .metadataFailure:relay.send(["CLOSED",id,"Metadata unavailable"],to:connection);return;case .missingProfile:break;case .banned:relay.send(["EVENT",id,banned],to:connection);default:relay.send(["EVENT",id,profile],to:connection)}}
            relay.send(["EOSE",id],to:connection)
        }
    }

}
extension TeamsTests {
    func testFeedAdapterFailureSignedRecoveryAndCacheThroughActualEnglishProductAndRelaunch()async throws{try await feedRecoveryJourney(arabic:false)}
    func testFeedAdapterFailureSignedRecoveryAndCacheThroughActualArabicProductAndRelaunch()async throws{try await feedRecoveryJourney(arabic:true)}
    private func feedRecoveryJourney(arabic:Bool)async throws {
        continueAfterFailure=false
        let relay=LocalNostrRelay(),feed=try ControlledTeamFeedRelay();defer{relay.stop()};try await relay.start{feed.handle($0,$1,relay:relay)}
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_TEAM_TEST_RELAY":relay.url,"PIYALI_PRIVATE_TEAMS_TEST_EMULATOR":"1","PIYALI_HEADLINE_FIXTURE":"failure"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme",arabic ? "dark":"light"];app.launch()
        let entry=app.textFields["entryName"];XCTAssertTrue(entry.waitForExistence(timeout:15));entry.tap();entry.typeText("Feed Learner");tap("entryKeyboardDone",app);tap("createAccount",app);chooseEnglishSpanishOnboarding(app);tap("startLearning",app);tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);tap("placementNew",app)
        if arabic{tap("productMenu",app);tap("productPanel-settings",app);tap("supportLanguagePicker",app);tap("settingsLanguage-support-ar",app);tap("productPanelClose",app)}
        open(app);tap("teamsFeedTab",app)
        let error=app.staticTexts["teamsFeedError"],loading=app.otherElements["teamsFeedLoading"],content=app.staticTexts["teamsFeedContent"],empty=app.staticTexts["teamsFeedEmpty"]
        XCTAssertTrue(empty.waitForExistence(timeout:15));XCTAssertEqual(empty.label,"No posts yet. Start the conversation!");XCTAssertFalse(error.exists);XCTAssertFalse(app.buttons["teamsFeedRefresh"].exists);XCTAssertFalse(content.exists);shot("Native Teams feed adapter failure is empty \(arabic ? "ar":"en")",app)
        app.terminate();feed.set(.posts);app.launch();open(app);tap("teamsFeedTab",app)
        XCTAssertTrue(app.staticTexts["Total XP: 1250"].waitForExistence(timeout:15));XCTAssertTrue(app.buttons["Community learner"].waitForExistence(timeout:5),"SwiftUI Link is exposed as a native button in this OS");XCTAssertTrue(content.label.contains("https://piyali.app"));XCTAssertFalse(error.exists);XCTAssertFalse(loading.exists);shot("Native Teams feed signed recovery \(arabic ? "ar":"en")",app)
        tap("teamsClose",app);XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:app.buttons["teamsClose"])],timeout:5),.completed,"The actual drawer close control must dismiss before reopening");let reads=relay.frames().filter{($0.last as? [String:Any])?["kinds"] as? [Int] == [1]}.count;feed.set(.failure);open(app);tap("teamsFeedTab",app);XCTAssertTrue(app.staticTexts["Total XP: 1250"].waitForExistence(timeout:5));XCTAssertFalse(loading.exists,"A successful cached feed stays visible without a spinner");XCTAssertEqual(relay.frames().filter{($0.last as? [String:Any])?["kinds"] as? [Int] == [1]}.count,reads,"The fresh cache must avoid another relay read");shot("Native Teams feed cached reopen \(arabic ? "ar":"en")",app)
        app.terminate();app.launch();open(app);tap("teamsFeedTab",app);XCTAssertTrue(empty.waitForExistence(timeout:15));XCTAssertEqual(empty.label,"No posts yet. Start the conversation!");XCTAssertFalse(error.exists);XCTAssertFalse(app.buttons["teamsFeedRefresh"].exists);XCTAssertFalse(content.exists);shot("Native Teams feed relaunch failure is empty \(arabic ? "ar":"en")",app)
        XCTAssertFalse(relay.frames().contains{$0.first as? String == "EVENT"},"Opening, retrying and reading community posts never publishes")
    }
}


extension TeamsTests {
    func testRawFeedBlankCacheFilteredMetadataAndMixedRecoveryInEnglishProduct()async throws{try await rawFeedJourney(arabic:false)}
    func testRawFeedBlankCacheFilteredMetadataAndMixedRecoveryInArabicProduct()async throws{try await rawFeedJourney(arabic:true)}
    private func rawFeedJourney(arabic:Bool)async throws {
        continueAfterFailure=false
        let relay=LocalNostrRelay(),feed=try ControlledTeamFeedRelay();feed.set(.ordinary);defer{relay.stop()};try await relay.start{feed.handle($0,$1,relay:relay)}
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_TEAM_TEST_RELAY":relay.url,"PIYALI_PRIVATE_TEAMS_TEST_EMULATOR":"1","PIYALI_HEADLINE_FIXTURE":"failure"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme",arabic ? "dark":"light"];app.launch()
        let entry=app.textFields["entryName"];XCTAssertTrue(entry.waitForExistence(timeout:15));entry.tap();entry.typeText("Content Learner");tap("entryKeyboardDone",app);tap("createAccount",app);chooseEnglishSpanishOnboarding(app);tap("startLearning",app);tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);tap("placementNew",app)
        if arabic{tap("productMenu",app);tap("productPanel-settings",app);tap("supportLanguagePicker",app);tap("settingsLanguage-support-ar",app);tap("productPanelClose",app)}
        func showFeed(){open(app);tap("teamsFeedTab",app);XCTAssertTrue(app.buttons["teamsFeedTab"].isSelected)}
        func empty(){XCTAssertTrue(app.staticTexts["teamsFeedEmpty"].waitForExistence(timeout:15));XCTAssertFalse(app.staticTexts["teamsFeedError"].exists);XCTAssertFalse(app.staticTexts["teamsFeedContent"].exists)}
        showFeed();XCTAssertFalse(app.otherElements["teamsFeedLoading"].exists);XCTAssertFalse(app.staticTexts["teamsFeedEmpty"].exists,"An ordinary retained note produces the original blank feed, not an empty message");XCTAssertFalse(app.staticTexts["teamsFeedError"].exists);XCTAssertFalse(app.staticTexts["teamsFeedContent"].exists);shot("Native Teams content ordinary blank \(arabic ? "ar":"en")",app)
        XCTAssertTrue(relay.frames().contains{($0.last as? [String:Any])?["kinds"] as? [Int] == [0]},"The signed ordinary note completes its metadata read")
        tap("teamsClose",app);XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:app.buttons["teamsClose"])],timeout:5),.completed)
        let reads=relay.frames().filter{($0.last as? [String:Any])?["kinds"] as? [Int] == [1]}.count;feed.set(.failure);showFeed();XCTAssertFalse(app.staticTexts["teamsFeedEmpty"].exists);XCTAssertFalse(app.staticTexts["teamsFeedContent"].exists);XCTAssertEqual(relay.frames().filter{($0.last as? [String:Any])?["kinds"] as? [Int] == [1]}.count,reads);shot("Native Teams content raw cache reopen \(arabic ? "ar":"en")",app)
        app.terminate();feed.set(.banned);app.launch();showFeed();empty();shot("Native Teams content filtered author empty \(arabic ? "ar":"en")",app)
        app.terminate();feed.set(.metadataFailure);app.launch();showFeed();empty();shot("Native Teams content metadata failure empty \(arabic ? "ar":"en")",app)
        app.terminate();feed.set(.missingProfile);app.launch();showFeed();XCTAssertTrue(app.buttons["New Private User"].waitForExistence(timeout:15));XCTAssertTrue(app.staticTexts["Total XP: 1250"].exists);XCTAssertFalse(app.staticTexts["teamsFeedEmpty"].exists);shot("Native Teams content missing profile fallback \(arabic ? "ar":"en")",app)
        app.terminate();feed.set(.mixed);app.launch();showFeed();XCTAssertTrue(app.buttons["Community learner"].waitForExistence(timeout:15));XCTAssertEqual(app.staticTexts.matching(identifier:"teamsFeedContent").count,1);XCTAssertTrue(app.staticTexts["teamsFeedContent"].label.contains("1250 XP"));XCTAssertFalse(app.staticTexts["A community greeting"].exists);XCTAssertFalse(app.staticTexts["teamsFeedEmpty"].exists);shot("Native Teams content mixed signed recovery \(arabic ? "ar":"en")",app)
        XCTAssertFalse(relay.frames().contains{$0.first as? String == "EVENT"},"Content reads, relaunch and cache recovery never publish")
    }
}

private final class StreamedRosterRelay:@unchecked Sendable {
    private let lock=NSLock()
    private var events:[[String:Any]]=[]
    private var held:[(String,NWConnection)]=[]
    private var hold=false,holdOnlyMembers=false
    private let member=Keypair(hex:String(repeating:"0",count:63)+"3")!
    private let stamp=Int64(Date().timeIntervalSince1970)
    var memberNpub:String{member.publicKey.npub}
    var waiting:Bool{lock.withLock{!held.isEmpty}}
    var published:[[String:Any]]{lock.withLock{events}}
    private func event(kind:Int,tags:[[String]],content:String,time:Int64)throws->[String:Any]{
        let data=try JSONSerialization.data(withJSONObject:[0,member.publicKey.hex,time,kind,tags,content],options:[.withoutEscapingSlashes]),id=SHA256.hash(data:data).map{String(format:"%02x",$0)}.joined()
        return ["id":id,"pubkey":member.publicKey.hex,"created_at":time,"kind":kind,"tags":tags,"content":content,"sig":try TeamsFeedFixtureCrypto().signatureForContent(id,privateKey:member.privateKey.hex)]
    }
    private func progress(_ xp:Int,time:Int64)throws->[String:Any]{
        let fields:[String:Any] = ["schemaVersion":2,"name":"Public teammate","targetLang":"es","xp":xp,"level":"B1","score":64,"scoreScale":"0-100","goal":30,"dailyGoalXp":30,"dailyXp":15,"progressPercent":50,"companion":["name":"Luna","type":"ghost","level":3,"health":74],"updatedAt":time]
        let data=try JSONSerialization.data(withJSONObject:fields,options:[.sortedKeys,.withoutEscapingSlashes]);return try event(kind:30078,tags:[["d","learning-progress"],["t","learning-progress"]],content:String(decoding:data,as:UTF8.self),time:time)
    }
    init()throws{events=[try event(kind:0,tags:[],content:"{\"name\":\"Public teammate\"}",time:stamp),try progress(1234,time:stamp)]}
    func arm(){lock.withLock{hold=true;holdOnlyMembers=false}}
    func armMembers(){lock.withLock{hold=true;holdOnlyMembers=true}}
    func releaseCurrent(_ relay:LocalNostrRelay){let result=lock.withLock{()->([(String,NWConnection)],[[String:Any]]) in hold=false;let pending=held;held=[];return(pending,events)};for(id,connection)in result.0{for event in result.1{relay.send(["EVENT",id,event],to:connection)};relay.send(["EOSE",id],to:connection)}}
    func handle(_ frame:[Any],_ connection:NWConnection,relay:LocalNostrRelay){
        if frame.first as? String == "REQ",let id=frame[1] as? String{
            let result=lock.withLock{()->[[String:Any]]? in if hold && (!holdOnlyMembers || (frame.dropFirst(2).compactMap{$0 as? [String:Any]}.contains{($0["#d"] as? [String])?.contains("learning-progress") == true})){held.append((id,connection));return nil};return events}
            if let result{for event in result{relay.send(["EVENT",id,event],to:connection)};relay.send(["EOSE",id],to:connection)}
        }else if frame.first as? String == "EVENT",let event=frame[1] as? [String:Any],let id=event["id"] as? String{lock.withLock{events.append(event)};relay.send(["OK",id,true,""],to:connection)}
    }
    func releaseUpdated(_ relay:LocalNostrRelay)throws{
        let updated=try progress(5678,time:stamp+1),state=lock.withLock{()->([(String,NWConnection)],[[String:Any]]) in hold=false;events.append(updated);let pending=held;held=[];return(pending,events)}
        for(id,connection)in state.0{for event in state.1{relay.send(["EVENT",id,event],to:connection)};relay.send(["EOSE",id],to:connection)}
    }
}
extension TeamsTests {
    func testArabicMirrorCardChangesBeforeAHeldSignedMemberReadThenRestoresFreshProgressAndDeletes()async throws {
        continueAfterFailure=false
        let relay=LocalNostrRelay(),state=try StreamedRosterRelay();defer{relay.stop()};try await relay.start{state.handle($0,$1,relay:relay)}
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_TEAM_TEST_RELAY":relay.url,"PIYALI_PRIVATE_TEAMS_TEST_EMULATOR":"1","PIYALI_HEADLINE_FIXTURE":"failure"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","dark"];app.launch()
        let entry=app.textFields["entryName"];XCTAssertTrue(entry.waitForExistence(timeout:15));entry.tap();entry.typeText("Stream Learner");tap("entryKeyboardDone",app);tap("createAccount",app);chooseEnglishSpanishOnboarding(app);tap("startLearning",app);tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);tap("placementNew",app)
        tap("productMenu",app);tap("productPanel-settings",app);tap("supportLanguagePicker",app);tap("settingsLanguage-support-ar",app);tap("productPanelClose",app)
        open(app);let owner=try XCTUnwrap(app.buttons["teamsCopyID"].value as? String);tap("teamCreateOpen",app);enter("Weekend","teamName",app);enter(state.memberNpub,"teamMembers",app);tap("teamCreate",app)
        let old=app.staticTexts["1234"];for _ in 0..<6 where !old.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(old.waitForExistence(timeout:15));XCTAssertTrue(old.isHittable);shot("Native streamed roster initial signed member",app)
        tap("teamsClose",app);app.terminate();state.armMembers();app.launch();open(app)
        XCTAssertTrue(app.staticTexts["Stream Learner"].waitForExistence(timeout:5),"Cold roster exposes the in-memory creator before signed peer progress finishes")
        XCTAssertFalse(app.staticTexts["1234"].exists);XCTAssertTrue(state.waiting);shot("Native cold roster creator before held member batch",app)
        state.releaseCurrent(relay);for _ in 0..<6 where !old.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(old.waitForExistence(timeout:15));shot("Native cold roster signed members settled",app)
        let card=app.buttons["learningTeamRow"];for _ in 0..<6 where !card.isHittable{app.swipeDown(velocity:.slow)};XCTAssertTrue(card.isHittable);XCTAssertEqual(card.label,"Weekend")
        let url=try XCTUnwrap(URL(string:"http://127.0.0.1:8180/v1/projects/demo-piyali-ios/databases/(default)/documents/users/\(owner)/teams")),(data,_)=try await URLSession.shared.data(from:url),json=try XCTUnwrap(JSONSerialization.jsonObject(with:data) as? [String:Any]),docs=try XCTUnwrap(json["documents"] as? [[String:Any]]),path=try XCTUnwrap(docs.first?["name"] as? String),id=try XCTUnwrap(path.split(separator:"/").last).description
        state.arm()
        var patch=URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:8180/v1/projects/demo-piyali-ios/databases/(default)/documents/users/\(owner)/teams/\(id)?updateMask.fieldPaths=teamName")));patch.httpMethod="PATCH";patch.setValue("application/json",forHTTPHeaderField:"Content-Type");patch.httpBody=try JSONSerialization.data(withJSONObject:["fields":["teamName":["stringValue":"Peer cache name"]]])
        let(_,response)=try await URLSession.shared.data(for:patch);XCTAssertEqual((response as? HTTPURLResponse)?.statusCode,200)
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"label == %@","Peer cache name"),object:card)],timeout:3),.completed,"The Firebase card update is visible before a relay round trip completes")
        for _ in 0..<100 where !state.waiting{try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(state.waiting);XCTAssertFalse(app.staticTexts["5678"].exists);shot("Native streamed roster mirror title before signed member reply",app)
        try state.releaseUpdated(relay);let fresh=app.staticTexts["5678"];for _ in 0..<6 where !fresh.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(fresh.waitForExistence(timeout:15));XCTAssertTrue(fresh.isHittable);XCTAssertFalse(old.exists);XCTAssertEqual(card.label,"Peer cache name");shot("Native streamed roster signed peer progress settled",app)
        reveal("teamRemove",app).tap();let deletion=app.sheets.buttons["Delete team"];XCTAssertTrue(deletion.waitForExistence(timeout:5));deletion.tap();XCTAssertTrue(app.staticTexts["My teams (0)"].waitForExistence(timeout:15));app.terminate();app.launch();open(app);XCTAssertTrue(app.staticTexts["My teams (0)"].waitForExistence(timeout:15));shot("Native streamed roster deletion private relaunch",app)
        let published=relay.frames().filter{$0.first as? String == "EVENT"}.compactMap{$0[1] as? [String:Any]},deleted=published.filter{($0["tags"] as? [[String]])?.contains(["deleted"]) == true}
        XCTAssertFalse(published.contains{$0["kind"] as? Int == 1});XCTAssertEqual(deleted.count,1)
        XCTAssertTrue((deleted.first?["tags"] as? [[String]])?.contains(["name","Weekend"]) == true,"Mirror display names never replace the signed roster used for actions")
    }
}
