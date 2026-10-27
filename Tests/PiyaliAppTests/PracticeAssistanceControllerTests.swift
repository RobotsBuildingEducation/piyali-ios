import XCTest
@testable import Piyali
@MainActor private final class AssistanceNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class PracticeAssistanceControllerTests:XCTestCase {
    private func app()throws->AppModel {let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated offline identity required")};let app=AppModel(progressService:AssistanceNoCloud());try app.identity.create();app.signedIn=true;app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.onboardingComplete=true;app.learner.target="es";app.learner.support="en";return app}
    private func run(_ app:AppModel,variant:String="natural_or_weird",quiz:Bool=false)throws->PracticeRun {let recipes=try PracticeRecipes(),payload=try recipes.inspect("fallback",parameters:.object(["variant":.string(variant),"targetLang":.string("es"),"supportLang":.string("en"),"moduleType":.string("grammar")])),question=try PracticeQuestion(module:.grammar,kind:"delight:"+variant,payload:payload,options:.object(["cefrLevel":.string("A1"),"isFinalQuiz":.bool(quiz)]),target:"es",support:"en");let run=PracticeRun(question:question,lessonID:nil,lessonLevel:"A1",response:try recipes.inspect("initialResponse",parameters:.object(["question":payload])));app.learner.savePractice(run);return run}
    private func wait(_ condition:()->Bool)async throws{for _ in 0..<500 where !condition(){try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(condition())}
    func testDirectHelpStreamsCanCloseAndReopenCachedWithoutGradingOrAwardingXP()async throws {
        let app=try app(),run=try run(app);defer{try? app.identity.disconnect()};var requests=0,release:CheckedContinuation<String,Never>?
        let helper=PracticeAssistanceController(writer:{prompt,update in requests+=1;XCTAssertTrue(prompt.contains("Start with the exact answer"));update("Use the offered answer.");return await withCheckedContinuation{release=$0}})
        helper.ask(app,run:run);try await wait{release != nil};XCTAssertTrue(helper.assistantOpen);XCTAssertTrue(helper.assistantBusy);XCTAssertEqual(helper.assistantText,"Use the offered answer.");XCTAssertTrue(app.learner.practiceRuns?[run.key]?.assisted == true);XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.practiceRuns?[run.key]?.correct)
        helper.closeAssistant();release?.resume(returning:"The exact answer and explanation.");release=nil;try await wait{!helper.assistantBusy};XCTAssertFalse(helper.assistantOpen);helper.ask(app,run:run);XCTAssertTrue(helper.assistantOpen);XCTAssertEqual(requests,1);XCTAssertEqual(helper.assistantText,"The exact answer and explanation.");XCTAssertEqual(app.learner.totalXP,0);helper.cancel()
    }
    func testUncooperativeExplanationCannotReplaceAnotherResponseOrClearItsRequest()async throws {
        let app=try app();var run=try run(app,variant:"dialogue_fork");defer{try? app.identity.disconnect()};let answer=Int(run.question.payload["answerIndex"].number),wrong=run.question.strings("options").indices.filter{$0 != answer};XCTAssertGreaterThanOrEqual(wrong.count,2);run.response = .object(["selectedIndex":.number(Double(wrong[0]))]);run.correct=false;app.learner.savePractice(run)
        var calls=0,old:CheckedContinuation<String,Never>?,new:CheckedContinuation<String,Never>?
        let helper=PracticeAssistanceController(writer:{_,_ in calls+=1;return await withCheckedContinuation{if calls == 1{old=$0}else{new=$0}}})
        helper.explain(app,run:run);try await wait{old != nil};helper.responseChanged();run.response = .object(["selectedIndex":.number(Double(wrong[1]))]);app.learner.savePractice(run);helper.explain(app,run:run);try await wait{new != nil};old?.resume(returning:"Old explanation");old=nil;try await Task.sleep(for:.milliseconds(30));XCTAssertTrue(helper.explanationBusy);XCTAssertTrue(helper.explanationText.isEmpty);new?.resume(returning:"Current explanation");new=nil;try await wait{!helper.explanationBusy};XCTAssertEqual(helper.explanationText,"Current explanation");XCTAssertFalse(app.learner.practiceRuns?[run.key]?.assisted ?? true);XCTAssertEqual(app.learner.totalXP,0);helper.cancel()
    }
    func testScopeCancellationRejectsLateChunksAndQuizzesHaveNoAssistance()async throws {
        let app=try app(),run=try run(app);defer{try? app.identity.disconnect()};var release:CheckedContinuation<String,Never>?,update:(@MainActor(String)->Void)?;var calls=0
        let helper=PracticeAssistanceController(writer:{_,chunk in calls+=1;update=chunk;return await withCheckedContinuation{release=$0}});helper.ask(app,run:run);try await wait{release != nil};app.learner.support="ar";helper.clear();update?("Late answer");release?.resume(returning:"Late final");release=nil;try await Task.sleep(for:.milliseconds(30));XCTAssertTrue(helper.assistantText.isEmpty);XCTAssertFalse(helper.assistantOpen);XCTAssertFalse(helper.assistantBusy);XCTAssertFalse(app.learner.practiceRuns?[run.key]?.assisted ?? true)
        app.learner.support="en";var quiz=try self.run(app,quiz:true);quiz.correct=false;app.learner.savePractice(quiz);helper.ask(app,run:quiz);helper.explain(app,run:quiz);try await Task.sleep(for:.milliseconds(30));XCTAssertEqual(calls,1);XCTAssertTrue(helper.explanationText.isEmpty);XCTAssertEqual(app.learner.totalXP,0)
    }
    func testFailedFreshPreparationCannotRegradeThePreviouslySavedQuestion()async throws {
        let app=try app();var previous=try run(app);defer{try? app.identity.disconnect()};previous.response = .object(["choice":.bool(false)]);app.learner.savePractice(previous)
        let url=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".js");try "var PiyaliPracticeRecipes={inspect(){throw Error('Unavailable source policy')}}".write(to:url,atomically:true,encoding:.utf8);defer{try? FileManager.default.removeItem(at:url)}
        let service=PracticeService(recipes:try PracticeRecipes(source:url));await service.prepare(app,module:.grammar,lesson:nil,fresh:true)
        XCTAssertTrue(service.preparationFailed);XCTAssertFalse(service.preparing);XCTAssertFalse(service.busy);XCTAssertNotNil(service.error);XCTAssertEqual(app.learner.practiceRuns?[previous.key]?.question.id,previous.question.id)
        await service.check(app,run:previous);XCTAssertNil(app.learner.practiceRuns?[previous.key]?.correct);XCTAssertEqual(app.learner.totalXP,0);service.cancel();XCTAssertFalse(service.preparationFailed);XCTAssertNil(service.error)
    }
    func testMorphologyHelpFailureKeepsOriginalConcreteSolution()async throws {
        let app=try app(),run=try run(app,variant:"morphology_forge");defer{try? app.identity.disconnect()};let helper=PracticeAssistanceController(writer:{_,_ in throw URLError(.notConnectedToInternet)});helper.ask(app,run:run);try await wait{!helper.assistantBusy};XCTAssertTrue(helper.assistantText.contains(run.question.payload["answerWord"].string));XCTAssertFalse(helper.assistantText.contains(EntryCopy.ui("en","vocab_assistant_error")));XCTAssertEqual(app.learner.totalXP,0);helper.cancel()
    }
}
