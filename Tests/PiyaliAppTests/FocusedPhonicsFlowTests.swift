import XCTest
@testable import Piyali

@MainActor private final class FocusedPhonicsStore:LearnerProgressService {
    var online=false,saves=0,failCompletion=false
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState? {
        saves += 1;guard online && !(failCompletion && !(state.pendingRepairEvidence ?? []).isEmpty) else{throw URLError(.notConnectedToInternet)}
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
