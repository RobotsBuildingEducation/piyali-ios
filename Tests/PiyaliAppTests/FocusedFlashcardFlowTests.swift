import XCTest
@testable import Piyali

@MainActor private final class FocusedFlowStore:LearnerProgressService {
    var online=false
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState? {
        guard online else{throw URLError(.notConnectedToInternet)}
        var result=state;result.pendingChanges=[];result.pendingGoalChanges=[];result.pendingCompanionQuestDays=[:];result.pendingRepairEvidence=[];return result
    }
}
@MainActor final class FocusedFlashcardFlowTests:XCTestCase {
    private func model()throws->(AppModel,FocusedFlowStore,JSONValue) {
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated identity required")}
        let store=FocusedFlowStore(),app=AppModel(progressService:store);try app.identity.create();app.signedIn=true;app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.onboardingComplete=true;app.learner.target="es";app.learner.support="en";app.learner.editGoal("Speak with family")
        let bp:JSONValue = .object(["goalId":app.learner.goalBucket["activeGoal"]["id"],"goalText":.string("Speak with family"),"lang":.string("es"),"dayKey":.string(CalendarDay.key(Date())),"mode":.string("flashcards"),"modes":.array(["flashcards","lesson"].map(JSONValue.string)),"modeTargets":.object(["flashcards":.number(3),"lesson":.number(20)]),"cefrLevel":.string("Pre-A1"),"objective":.string("Greet a relative"),"scenario":.string("Visit family"),"supports":.array([.string("Use a model")]),"successCriteria":.array([.string("Say hello")]),"targetLanguage":.array(["Hola","Gracias","Adiós"].map(JSONValue.string))])
        app.learner.applyGoal(GoalChange(action:.blueprint,target:"es",payload:bp));app.learner.pendingGoalChanges=[];return(app,store,bp)
    }
    private func provider(_ raw:String)->FlashcardProvider{.init(judge:{_ in raw},stream:{_,_ in "Hola"},quote:{_,_ in .null})}
    private func settle(_ session:FlashcardSessionController)async {for _ in 0..<100 where session.grading || session.saving{try? await Task.sleep(for:.milliseconds(20))}}
    private func install(_ app:AppModel,_ bp:JSONValue)throws->[JSONValue] {
        let cards=try XCTUnwrap(app.companionQuestPolicy).run("goalDeckCards",.object(["focus":.object(["blueprint":bp,"targetLang":.string("es"),"supportLang":.string("en")]),"providerFailed":.bool(true)])).array
        app.learner.applyGoal(GoalChange(action:.artifact,target:"es",payload:bp.setting("mode",.string("flashcards")).setting("cards",.array(cards))));app.learner.pendingGoalChanges=[];return cards
    }
    func testGoalGenerationUsesOriginalPromptAndFloorThenRestoresCachedArtifactWithoutAnotherRequest()async throws {
        let(app,store,bp)=try model();defer{try? app.identity.disconnect()};store.online=true;var prompts:[String]=[]
        let sparse=bp.setting("targetLanguage",.array([])).setting("scoreAtGeneration",.number(99))
        try await app.prepareGoalDeck(sparse,mode:"flashcards",respond:{prompt in prompts.append(prompt);throw URLError(.notConnectedToInternet)})
        let cards=app.goalArtifact(bp,mode:"flashcards")["cards"].array;XCTAssertEqual(cards.count,3);XCTAssertEqual(cards[0]["concept"]["es"].string,"Speak with family");XCTAssertEqual(cards[1]["concept"]["en"].string,"Greet a relative (2)");XCTAssertFalse(prompts[0].contains("scoreAtGeneration"));XCTAssertTrue(prompts[0].contains("Live internal Elo"))
        try await app.prepareGoalDeck(sparse,mode:"flashcards",respond:{_ in XCTFail("Cached deck must be reused");return "[]"});XCTAssertEqual(prompts.count,1)
        app.learner=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(app.learner));XCTAssertEqual(app.goalArtifact(bp,mode:"flashcards")["cards"].array,cards)
    }
    func testFailedGoalSaveCloseReopenAndRetryStayActionableWithoutDuplicateXPOrPrematureMode()async throws {
        let(app,store,bp)=try model();defer{try? app.identity.disconnect()};let cards=try install(app,bp)
        var session=try FlashcardSessionController(app:app,card:cards[0],status:"active",goal:bp,provider:provider("YES | 6"));app.flashcardSession=session;session.answer="Hola";session.submit(app);await settle(session);session.commit(.good,app:app);await settle(session)
        XCTAssertNotNil(session.error);XCTAssertEqual(app.learner.totalXP,2);XCTAssertFalse(app.learner.displayedGoalArtifact(bp,mode:"flashcards")["outcomes"][cards[0]["id"].string]["success"].boolean)
        session.close(app,abandoned:false);app.learner=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(app.learner))
        session=try FlashcardSessionController(app:app,card:cards[0],status:"active",goal:bp,provider:provider("YES | 6"));app.flashcardSession=session;session.answer="Hola";session.submit(app);await settle(session);session.commit(.good,app:app);await settle(session)
        XCTAssertNotNil(session.error);XCTAssertEqual(app.flashcardSession?.id,session.id);XCTAssertEqual(app.learner.totalXP,2)
        store.online=true;session.commit(.good,app:app);await settle(session);XCTAssertNil(app.flashcardSession);XCTAssertTrue(app.learner.displayedGoalArtifact(bp,mode:"flashcards")["outcomes"][cards[0]["id"].string]["success"].boolean)
        XCTAssertEqual(app.learner.goalBucket["dailyGoal"]["modeProgress"]["flashcards"].number,0);XCTAssertEqual(app.learner.totalXP,2);XCTAssertNil(app.learner.cardReviews)
        for card in cards.dropFirst(){let next=try FlashcardSessionController(app:app,card:card,status:"active",goal:bp,provider:provider("YES | 6"));app.flashcardSession=next;next.answer=card["concept"]["es"].string;next.submit(app);await settle(next);next.commit(.good,app:app);await settle(next)}
        XCTAssertEqual(app.learner.totalXP,6);XCTAssertEqual(app.readyGoal?["modeProgress"]["flashcards"].number,3);XCTAssertEqual(GoalPractice.nextMode(try XCTUnwrap(app.readyGoal)),"lesson");XCTAssertNil(app.learner.cardReviews)
        let completion=try XCTUnwrap(app.learner.goalBucket["goalProgress"]["demonstrated"].array.first{$0["target"] == bp["objective"]});XCTAssertEqual(completion["example"].string,"Completed three goal-specific recall cards: Hola; Gracias; Adiós")
    }
    func testRepeatedUnsuccessfulRecallUsesOriginalSemanticEvidenceID()throws {
        let(app,_,bp)=try model();defer{try? app.identity.disconnect()};let cards=try install(app,bp)
        for _ in 0..<2 {app.recordGoalPreparation(bp,mode:"flashcards",card:cards[0],success:false,answer:"wrong",assess:false)}
        let summary=app.learner.goalBucket["goalProgress"];XCTAssertEqual(summary["eventIds"].array.count,1);XCTAssertEqual(summary["openCapabilities"].array.first?["recurrence"].number,1);XCTAssertEqual(summary["openCapabilities"].array.first?["example"].string,"Unsuccessful recall; not independent production")
    }
    func testLateGradeRejectsSignoutAndReturningWithTheSameKey()async throws {
        for boundary in ["signout","sameKey"]{let(app,_,bp)=try model();defer{try? app.identity.disconnect()};let cards=try install(app,bp);var held:CheckedContinuation<String,Error>?
            let session=try FlashcardSessionController(app:app,card:cards[0],status:"active",goal:bp,provider:.init(judge:{_ in try await withCheckedThrowingContinuation{held=$0}},stream:{_,_ in ""},quote:{_,_ in .null}));app.flashcardSession=session;session.answer="Hola";session.submit(app)
            for _ in 0..<100 where held == nil{try await Task.sleep(for:.milliseconds(10))};XCTAssertNotNil(held)
            if boundary == "signout"{app.signedIn=false}else{let key=app.identity.exportKey();try app.identity.disconnect();try app.identity.importKey(key)}
            held?.resume(returning:"YES | 6");await settle(session);XCTAssertNil(session.grade);XCTAssertNil(app.learner.gradedByLanguage);XCTAssertEqual(app.learner.totalXP,0);XCTAssertFalse(session.matches(app))
        }
    }
}
