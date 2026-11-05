import XCTest
import SwiftUI
@testable import Piyali

@MainActor private final class FocusedPhonicsStore:LearnerProgressService {
    var online=false,saves=0,failCompletion=false,holdAttempt=false
    var waiters:[CheckedContinuation<Void,Never>]=[]
    func release(){holdAttempt=false;let pending=waiters;waiters=[];pending.forEach{$0.resume()}}
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState? {
        saves += 1;if holdAttempt,(state.pendingChanges ?? []).contains(where:{$0.source == .phonicsAttempt}){await withCheckedContinuation{waiters.append($0)}};guard online && !(failCompletion && !(state.pendingRepairEvidence ?? []).isEmpty) else{throw URLError(.notConnectedToInternet)}
        var saved=state;saved.pendingChanges=[];saved.pendingGoalChanges=[];saved.pendingMemoryChanges=[];saved.pendingCompanionQuestDays=[:];saved.pendingRepairEvidence=[];return saved
    }
}
@MainActor final class FocusedPhonicsFlowTests:XCTestCase {
    private func setup()async throws->(AppModel,FocusedPhonicsStore,JSONValue,[JSONValue]) {
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated offline identity required")}
        let store=FocusedPhonicsStore(),app=AppModel(progressService:store);try app.identity.create();app.signedIn=true;app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.onboardingComplete=true;await app.reloadContent();app.learner.editGoal("Pronounce casa")
        let bp:JSONValue = .object(["goalId":app.learner.goalBucket["activeGoal"]["id"],"lang":.string("es"),"dayKey":.string(CalendarDay.key(Date())),"mode":.string("phonics"),"modes":.array(["phonics","lesson"].map(JSONValue.string)),"modeTargets":.object(["phonics":.number(2),"lesson":.number(20)]),"cefrLevel":.string("Pre-A1"),"objective":.string("Pronounce two family words"),"targetLanguage":.array([.string("casa")])])
        app.learner.applyGoal(.init(action:.blueprint,target:"es",payload:bp));let cards=try app.focusedPhonicsDeck(goal:bp)["cards"].array;XCTAssertEqual(cards.count,2)
        app.learner.applyGoal(.init(action:.artifact,target:"es",payload:bp.setting("cards",.array(cards))));app.learner.pendingGoalChanges=[];return(app,store,bp,cards)
    }
    private func provider(_ raw:String)->PhonicsProvider{.init(judge:{_ in raw},quote:{_,_ in .null})}
    private func settle(_ session:PhonicsSessionController)async throws{for _ in 0..<250 where session.busy{try await Task.sleep(for:.milliseconds(20))};XCTAssertFalse(session.busy)}
    func testCachedDeckLoadsOfflineUsesCanonicalNewSupportAndDropsRemovedAuthoredCards()async throws {
        let(app,store,bp,cards)=try await setup();defer{try? app.identity.disconnect()}
        let key=GoalPractice.artifactKey(target:"es",day:bp["dayKey"].string,mode:"phonics",goalID:bp["goalId"].string),saved=try XCTUnwrap(app.learner.goalArtifacts?[key]),poison=cards[0].setting("tip",.string("INJECTED")).setting("practiceWord",.string("INJECTED")),unknown=cards[1].setting("id",.string("unknown")).setting("authoredId",.string("removed-authored-card"))
        app.learner.goalArtifacts?[key]=saved.setting("cards",.array([poison,cards[1],unknown]));app.learner.support="ar"
        let course=PhonicsCourseController(goal:bp);await course.load(app)
        XCTAssertTrue(course.initialized);XCTAssertNil(course.error);XCTAssertEqual(course.deck.count,2);XCTAssertEqual(store.saves,0);XCTAssertEqual(course.deck[0]["id"],cards[0]["id"]);XCTAssertEqual(course.deck[0]["practiceWord"].string,"casa");XCTAssertEqual(course.deck[0]["supportLanguage"].string,"ar");XCTAssertNotEqual(course.deck[0]["tip"].string,"INJECTED");XCTAssertEqual(app.learner.totalXP,0)
    }
    func testRemovedCachedCardsDoNotGenerateAnotherDeckOrInferGoalCompletion()async throws {
        let(app,store,bp,cards)=try await setup();defer{try? app.identity.disconnect()};let key=GoalPractice.artifactKey(target:"es",day:bp["dayKey"].string,mode:"phonics",goalID:bp["goalId"].string),artifact=try XCTUnwrap(app.learner.goalArtifacts?[key]);app.learner.goalArtifacts?[key]=artifact.setting("cards",.array(cards.map{$0.setting("authoredId",.string("removed-card"))}))
        let course=PhonicsCourseController(goal:bp);await course.load(app);XCTAssertTrue(course.initialized);XCTAssertNil(course.error);XCTAssertTrue(course.hasLetters);XCTAssertTrue(course.deck.isEmpty);XCTAssertTrue(course.collected.isEmpty);XCTAssertEqual(store.saves,0);XCTAssertEqual(app.readyGoal?["modeProgress"]["phonics"].number,0);XCTAssertEqual(app.learner.totalXP,0)
    }
    func testFailedSaveReopensCachedDeckWithoutNetworkGateThenRetryAndSecondCardCommitTheOriginalEvidence()async throws {
        let(app,store,bp,cards)=try await setup();defer{try? app.identity.disconnect()}
        let first=try PhonicsSessionController(app:app,card:cards[0],goal:bp,provider:provider("YES | 2"));defer{first.cancel()};first.practice(app);first.submit("casa",app:app);try await settle(first)
        XCTAssertTrue(first.needsSaveRetry);XCTAssertEqual(app.learner.totalXP,2);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1)
        app.learner=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(app.learner));let saves=store.saves,reopened=PhonicsCourseController(goal:bp);await reopened.load(app)
        XCTAssertTrue(reopened.initialized);XCTAssertNil(reopened.error);XCTAssertEqual(reopened.deck.count,2);XCTAssertTrue(reopened.collected.isEmpty);XCTAssertEqual(store.saves,saves);XCTAssertEqual(app.readyGoal?["modeProgress"]["phonics"].number,0)
        store.online=true;first.retrySave(app);try await settle(first);XCTAssertFalse(first.needsSaveRetry);XCTAssertEqual(app.learner.totalXP,2);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1)
        reopened.collect(cards[0],app:app);XCTAssertEqual(reopened.counts[cards[0]["id"].string].number,1)
        let restored=PhonicsCourseController(goal:bp);await restored.load(app);XCTAssertEqual(restored.deck.count,1);XCTAssertEqual(restored.collected.count,1)
        let last=try PhonicsSessionController(app:app,card:cards[1],goal:bp,provider:provider("YES | 2"));defer{last.cancel()};last.practice(app);last.submit(cards[1]["practiceWord"].string,app:app);try await settle(last)
        XCTAssertNil(last.error);XCTAssertEqual(app.learner.totalXP,4);XCTAssertTrue(app.learner.phonicsDocuments.isEmpty);XCTAssertEqual(app.learner.plateProgress["phonicsDailyActivity"],.null);XCTAssertEqual(app.readyGoal?["modeProgress"]["phonics"].number,2);XCTAssertEqual(GoalPractice.nextMode(try XCTUnwrap(app.readyGoal)),"lesson")
        let expected="original: casa pronounced successfully after a model; transfer: \(cards[1]["practiceWord"].string) pronounced successfully after a model"
        XCTAssertEqual(app.learner.goalBucket["goalProgress"]["demonstrated"].array.first{$0["domain"].string == "pronunciation"}?["example"].string,expected)
    }
    func testRepairContrastMissKeepsSourceCardContextAndDoesNotBlockOriginalTransferCompletion()async throws {
        let(app,store,_,_)=try await setup();defer{try? app.identity.disconnect()};store.online=true;app.learner.goal="";app.learner.goalIntelligence=[:]
        let day=CalendarDay.key(Date()),base=try XCTUnwrap(app.phonics.first),item:JSONValue = .object(["memoryId":.string("pronunciation"),"concept":.string("Say casa"),"cefrLevel":.string("Pre-A1"),"errorType":.string("phonics"),"mode":.string("phonics"),"expectedAnswer":.string("casa"),"sourceContext":.object(["card":.object(["id":.string(base.id),"practiceWord":.string("casa")])])]),plan:JSONValue = .object(["dayKey":.string(day),"targetLang":.string("es"),"target":.number(2),"items":.array([item,.object(["memoryId":.string("agreement"),"concept":.string("Soy estudiante"),"mode":.string("lesson"),"cefrLevel":.string("Pre-A1")])])])
        app.learner.storeCompanionBlueprint(.object(["status":.string("ready"),"repair":plan]),target:"es",day:day)
        let next=try XCTUnwrap(app.companionQuestPolicy).run("next",.object(["plan":plan,"completedCount":.number(0)])),step=try JSONDecoder().decode(RepairStep.self,from:Data(next.json.utf8)),artifact=try app.focusedPhonicsDeck(repair:step),cards=artifact["cards"].array
        app.learner.storeRepairArtifact(artifact,step:step,mode:"phonics");app.learner.pendingCompanionQuestDays=[:];XCTAssertEqual(cards.count,3)
        for index in [1,0,2] {
            if index == 2{store.failCompletion=true}
            let session=try PhonicsSessionController(app:app,card:cards[index],repair:step,provider:provider(index == 1 ? "NO":"YES | 2"));session.practice(app);session.submit(index == 1 ? "WRONG_FIXTURE":cards[index]["practiceWord"].string,app:app);try await settle(session)
            if index == 2{XCTAssertTrue(session.needsSaveRetry);XCTAssertEqual(app.currentRepairStep?.index,0);XCTAssertEqual(app.learner.confirmedPlateProgress["repairDailyActivity"]["es"][day].number,0);XCTAssertEqual(app.learner.plateProgress["repairDailyActivity"]["es"][day].number,1);store.failCompletion=false;session.retrySave(app);try await settle(session)}
            XCTAssertNil(session.error)
            if index == 1 {let captured=try XCTUnwrap(app.learner.activeMemories.first);XCTAssertEqual(Set(captured.fields["sourceContext"]?["card"].object.keys ?? Dictionary<String,JSONValue>().keys),Set(["id","letter","tts","phoneme","practiceWord","practiceWordMeaning"]))}
            session.cancel()
        }
        XCTAssertEqual(app.learner.totalXP,4);XCTAssertTrue(app.learner.phonicsDocuments.isEmpty);XCTAssertEqual(app.learner.plateProgress["phonicsDailyActivity"],.null);XCTAssertEqual(app.currentRepairStep?.index,1)
        XCTAssertEqual(app.learner.goalBucket["repairSummary"]["recentlyRepaired"].array.first?["example"].string,"original: \(cards[0]["practiceWord"].string) pronounced successfully after a model; transfer: \(cards[2]["practiceWord"].string) pronounced successfully after a model")
    }
    func testPendingPronunciationRejectsSignoutSameKeyTargetSupportGoalDayAndCancellation()async throws {
        for boundary in ["signout","sameKey","target","support","goal","day","cancel"] {
            let(app,_,bp,cards)=try await setup();defer{try? app.identity.disconnect()};var held:CheckedContinuation<String,Error>?
            let session=try PhonicsSessionController(app:app,card:cards[0],goal:bp,provider:.init(judge:{_ in try await withCheckedThrowingContinuation{held=$0}},quote:{_,_ in .null}));defer{session.cancel()};session.practice(app);session.submit("casa",app:app)
            for _ in 0..<100 where held == nil{try await Task.sleep(for:.milliseconds(10))};XCTAssertNotNil(held)
            switch boundary{case "signout":app.signedIn=false;case "sameKey":let key=app.identity.exportKey();try app.identity.disconnect();try app.identity.importKey(key);case "target":app.learner.target="fr";case "support":app.learner.support="ar";case "goal":app.learner.editGoal("Order a meal");case "day":let b=app.learner.goalBucket;app.learner.goalIntelligence?["es"]=b.setting("dailyGoal",b["dailyGoal"].setting("blueprint",bp.setting("dayKey",.string(CalendarDay.shift(CalendarDay.key(Date()),by:-1)))));default:session.cancel()}
            held?.resume(returning:"YES | 2");try await settle(session);XCTAssertNil(session.grade,boundary);XCTAssertEqual(app.learner.totalXP,0,boundary);XCTAssertNil(app.learner.gradedByLanguage,boundary);XCTAssertTrue(app.learner.phonicsDocuments.isEmpty,boundary)
        }
    }
}


extension FocusedPhonicsFlowTests {
    func testRenderedGoalPhonicsRetainsFinalEarnedAttemptAcrossTrialGateUntilAcknowledged()async throws {
        let(app,store,bp,cards)=try await setup();defer{store.release();try? app.identity.disconnect()}
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_PHONICS_FIXTURE"] == "1" else{throw XCTSkip("Synthetic pronunciation provider required")}
        app.learner.applyGoal(.init(action:.outcome,target:"es",payload:bp.setting("mode",.string("phonics")).setting("cardID",cards[0]["id"]).setting("success",.bool(true)).setting("item",cards[0]["practiceWord"]).setting("externalReward",.bool(true))));app.learner.pendingGoalChanges=[];app.learner.subscriptionXPAdjustment=299
        let course=PhonicsCourseController(goal:bp),scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow},window=UIWindow(windowScene:scene);var surfaces:[ProductMode]=[]
        let host=UIHostingController(rootView:PhonicsTrialHost{FocusedGoalCourseView(onSurface:{surfaces.append($0)},phonicsControllerFactory:{_ in course})}.environmentObject(app));window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();defer{window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
        for _ in 0..<120 where course.currentSession == nil || app.activityFooter == nil{try await Task.sleep(for:.milliseconds(25))};let session=try XCTUnwrap(course.currentSession);XCTAssertEqual(session.card["id"],cards[1]["id"]);XCTAssertEqual(surfaces,[.phonics]);XCTAssertTrue(app.subscription.hasAccess)
        store.online=true;store.holdAttempt=true;session.practice(app);session.submit(cards[1]["practiceWord"].string,app:app)
        for _ in 0..<120 where store.waiters.isEmpty{try await Task.sleep(for:.milliseconds(25))};XCTAssertFalse(store.waiters.isEmpty)
        try await Task.sleep(for:.milliseconds(250));XCTAssertEqual(app.learner.totalXP,2);XCTAssertFalse(app.subscription.hasAccess);XCTAssertTrue(app.preservingEarnedPractice);XCTAssertNotNil(app.activityFooter);XCTAssertTrue(session.saving);XCTAssertEqual(surfaces,[.phonics]);XCTAssertEqual(app.readyGoal?["modeProgress"]["phonics"].number,0)
        capture("Native Goal pronunciation saving across 300 XP",window)
        store.online=false;store.release();try await settle(session);try await Task.sleep(for:.milliseconds(200));XCTAssertTrue(session.needsSaveRetry);XCTAssertTrue(app.preservingEarnedPractice);XCTAssertEqual(app.activityFooter?.owner,session.id);XCTAssertEqual(surfaces,[.phonics]);session.back();XCTAssertTrue(session.needsSaveRetry)
        capture("Native Goal pronunciation failed save and retry across 300 XP",window)
        store.online=true;session.retrySave(app);try await settle(session)
        for _ in 0..<120 where surfaces.last != .path{try await Task.sleep(for:.milliseconds(25))};XCTAssertEqual(surfaces,[.phonics,.path]);XCTAssertEqual(app.readyGoal?["modeProgress"]["phonics"].number,2);XCTAssertEqual(app.learner.totalXP,2);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1);XCTAssertFalse(app.preservingEarnedPractice);capture("Native subscription after acknowledged Goal pronunciation",window)
    }
}


private struct PhonicsTrialHost<Content:View>:View {
    @EnvironmentObject var app:AppModel
    @ViewBuilder var content:()->Content
    var body:some View {ProductAccessGate(service:app.subscription){content().overlay(alignment:.bottom){if let footer=app.activityFooter{footer.content.padding(12).background{SourceActivityDockBackground(correct:footer.correct)}.padding(.horizontal,8).padding(.bottom,12)}}}}
}
extension FocusedPhonicsFlowTests {
    private func capture(_ name:String,_ window:UIWindow){let shot=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});shot.name=name;shot.lifetime = .keepAlways;add(shot)}
    func testRenderedRepairPhonicsKeepsCompletionRetryAcrossTrialGateThenDeniesTheNextLesson()async throws {
        let(app,store,_,_)=try await setup();defer{store.release();try? app.identity.disconnect()};guard ProcessInfo.processInfo.environment["PIYALI_PHONICS_FIXTURE"] == "1" else{throw XCTSkip("Synthetic pronunciation provider required")}
        app.learner.goal="";app.learner.goalIntelligence=[:]
        let day=CalendarDay.key(Date()),item:JSONValue = .object(["memoryId":.string("pronunciation"),"concept":.string("casa"),"expectedAnswer":.string("casa"),"mode":.string("phonics"),"errorType":.string("phonics"),"cefrLevel":.string("Pre-A1")]),plan:JSONValue = .object(["dayKey":.string(day),"targetLang":.string("es"),"target":.number(2),"items":.array([item,.object(["memoryId":.string("agreement"),"concept":.string("Soy estudiante"),"mode":.string("lesson"),"cefrLevel":.string("Pre-A1")])])])
        app.learner.storeCompanionBlueprint(.object(["status":.string("ready"),"repair":plan]),target:"es",day:day);let step=try XCTUnwrap(app.currentRepairStep),artifact=try app.focusedPhonicsDeck(repair:step),cards=artifact["cards"].array
        let outcomes=JSONValue.object(Dictionary(uniqueKeysWithValues:cards.prefix(2).map{($0["id"].string,JSONValue.object(["success":.bool(true),"item":$0["practiceWord"]]))}));app.learner.storeRepairArtifact(artifact.setting("outcomes",outcomes),step:step,mode:"phonics");app.learner.pendingCompanionQuestDays=[:];app.learner.subscriptionXPAdjustment=299
        let course=PhonicsCourseController(repair:step),scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow},window=UIWindow(windowScene:scene);var surfaces:[ProductMode]=[]
        let host=UIHostingController(rootView:PhonicsTrialHost{RepairPracticeView(onSurface:{surfaces.append($0)},phonicsControllerFactory:{_ in course})}.environmentObject(app));window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();defer{window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
        for _ in 0..<120 where course.currentSession == nil || app.activityFooter == nil{try await Task.sleep(for:.milliseconds(25))};let session=try XCTUnwrap(course.currentSession);XCTAssertEqual(session.card["id"],cards[2]["id"])
        store.online=true;store.failCompletion=true;session.practice(app);session.submit(cards[2]["practiceWord"].string,app:app);try await settle(session);try await Task.sleep(for:.milliseconds(250))
        XCTAssertTrue(session.needsSaveRetry);XCTAssertFalse(app.subscription.hasAccess);XCTAssertTrue(app.preservingEarnedPractice);XCTAssertEqual(app.activityFooter?.owner,session.id);XCTAssertEqual(surfaces,[.phonics]);XCTAssertEqual(app.currentRepairStep?.id,step.id);capture("Native repair pronunciation completion retry across 300 XP",window)
        store.failCompletion=false;session.retrySave(app);try await settle(session);for _ in 0..<120 where surfaces.last != .path{try await Task.sleep(for:.milliseconds(25))}
        XCTAssertEqual(surfaces,[.phonics,.path]);XCTAssertEqual(app.currentRepairStep?.index,1);XCTAssertFalse(app.preservingEarnedPractice);XCTAssertEqual(app.learner.totalXP,2);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1);capture("Native subscription after acknowledged repair pronunciation",window)
    }
    func testRenderedOrdinaryPronunciationCanCollectEarnedWorkAtTrialEndButCannotStartAnotherAttempt()async throws {
        let(app,_,_,_)=try await setup();defer{try? app.identity.disconnect()};guard ProcessInfo.processInfo.environment["PIYALI_PHONICS_FIXTURE"] == "1" else{throw XCTSkip("Synthetic pronunciation provider required")};app.learner.subscriptionXPAdjustment=299
        let course=PhonicsCourseController(),scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow},window=UIWindow(windowScene:scene)
        let host=UIHostingController(rootView:PhonicsTrialHost{PhonicsView(controller:course)}.environmentObject(app));window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();defer{window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
        for _ in 0..<120 where course.currentSession == nil || app.activityFooter == nil{try await Task.sleep(for:.milliseconds(25))};let session=try XCTUnwrap(course.currentSession);session.practice(app);session.submit(session.card["practiceWord"].string,app:app);try await settle(session);try await Task.sleep(for:.milliseconds(250))
        XCTAssertFalse(app.subscription.hasAccess);XCTAssertTrue(app.preservingEarnedPractice);XCTAssertEqual(app.activityFooter?.owner,session.id);XCTAssertTrue(session.grade?.correct == true);capture("Native ordinary pronunciation earned Collect across 300 XP",window)
        session.practice(app);session.record(app);session.submit("another answer",app:app);XCTAssertNotNil(session.grade);XCTAssertFalse(session.recorder.recording);XCTAssertEqual(app.learner.totalXP,2);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1)
        course.collect(session.card,app:app);session.finishReview();XCTAssertFalse(app.preservingEarnedPractice);XCTAssertEqual(app.learner.plateProgress["phonicsDailyActivity"]["es"][CalendarDay.key(Date())].number,1);session.cancel()
    }
    func testExpiredAccessDeniesNewGradingQuoteRecordingPlaybackLevelAndSupplementalDeck()async throws {
        let(app,store,_,_)=try await setup();defer{try? app.identity.disconnect()};let course=PhonicsCourseController();await course.load(app);let card=try XCTUnwrap(course.deck.first);for c in course.deck{course.collect(c,app:app)};XCTAssertTrue(course.complete)
        app.learner.subscriptionXPAdjustment=300;XCTAssertFalse(app.subscription.hasAccess);var judges=0,quotes=0
        let session=try PhonicsSessionController(app:app,card:card,provider:.init(judge:{_ in judges += 1;return "YES | 2"},quote:{_,_ in quotes += 1;return .null}));defer{session.cancel()};session.practice(app);session.submit("casa",app:app);session.record(app);session.speak("word",app:app);let level=course.activeLevel;course.select("A1",app:app);await course.newRound(app);try await Task.sleep(for:.milliseconds(200))
        XCTAssertEqual(judges,0);XCTAssertEqual(quotes,0);XCTAssertFalse(session.practicing);XCTAssertNil(session.grade);XCTAssertFalse(session.recorder.recording);XCTAssertFalse(session.playback.loading);XCTAssertEqual(course.activeLevel,level);XCTAssertEqual(store.saves,0);XCTAssertFalse((app.learner.pendingChanges ?? []).contains{$0.source == .phonicsDeck});XCTAssertEqual(app.learner.totalXP,0);XCTAssertFalse(app.preservingEarnedPractice)
    }
}
