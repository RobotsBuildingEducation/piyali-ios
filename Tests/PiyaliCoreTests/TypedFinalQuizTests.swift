import XCTest
@testable import PiyaliCore

final class TypedFinalQuizTests:XCTestCase {
    private var lesson:Lesson { .init(id:"lesson-a1-1-quiz",title:.string("Family Quiz"),description:.string(""),xpReward:80,modes:["grammar","vocabulary"],agenda:.object([:]),content:.object([:]),isFinalQuiz:true,quizConfig:.object(["questionsRequired":.number(10),"passingScore":.number(8)]),cefrLevel:"A1") }
    private func prepare(_ state:inout LearnerState,quiz:FinalQuizRun) throws ->PracticeRun {
        let q=try PracticeQuestion(module:.grammar,kind:"mc",payload:.object(["question":.string("Choose a greeting"),"choices":.array([.string("hola"),.string("adiós")]),"answer":.string("hola")]),options:.object(["isFinalQuiz":.bool(true),"cefrLevel":.string("A1")]),target:state.target,support:state.support)
        var run=PracticeRun(question:q,lessonID:lesson.id,lessonLevel:"A1",response:.object(["indices":.array([.number(0)])]));run.quizRunID=quiz.id
        XCTAssertTrue(state.prepareTypedQuizQuestion(q,lessonID:lesson.id,runID:quiz.id));state.savePractice(run);return run
    }
    func testOneAttemptPerTypedItemEarlyFailureRetryAndStaleRunFences() throws {
        var state=LearnerState();let quiz=FinalQuizRun(lesson:lesson,learner:state);state.saveQuiz(quiz)
        let first=try prepare(&state,quiz:quiz)
        XCTAssertTrue(state.answerPractice(key:first.key,questionID:first.question.id,correct:false,reward:7))
        XCTAssertFalse(state.answerPractice(key:first.key,questionID:first.question.id,correct:true,reward:7),"A wrong quiz answer cannot be retried as practice")
        XCTAssertEqual(state.quizRuns?[state.quizKey(lesson.id)]?.answers,[false])
        for _ in 0..<2 { let next=try prepare(&state,quiz:quiz);XCTAssertTrue(state.answerPractice(key:next.key,questionID:next.question.id,correct:false,reward:7)) }
        XCTAssertTrue(state.quizRuns![state.quizKey(lesson.id)]!.outcome.completed);XCTAssertFalse(state.quizPassed(lesson));XCTAssertEqual(state.xp,0);XCTAssertFalse(state.complete(lesson))
        let retry=FinalQuizRun(lesson:lesson,learner:state);state.saveQuiz(retry)
        XCTAssertFalse(state.answerTypedQuizQuestion(lessonID:lesson.id,runID:quiz.id,questionID:first.question.id,correct:true))
        let next=try prepare(&state,quiz:retry);state.support="ja";XCTAssertFalse(state.answerPractice(key:next.key,questionID:next.question.id,correct:true,reward:6));XCTAssertEqual(state.xp,0)
    }
    func testTypedQuizPassResumesWithoutQuestionXPAndPreservesOneLessonReward() throws {
        var state=LearnerState();let quiz=FinalQuizRun(lesson:lesson,learner:state);state.saveQuiz(quiz)
        for count in 1...8 {
            let run=try prepare(&state,quiz:quiz);XCTAssertTrue(state.answerPractice(key:run.key,questionID:run.question.id,correct:true,reward:7));XCTAssertEqual(state.xp,0)
            XCTAssertEqual(state.quizRuns?[state.quizKey(lesson.id)]?.answers.count,count)
            state=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state))
        }
        XCTAssertTrue(state.quizPassed(lesson));XCTAssertTrue(state.quizRuns![state.quizKey(lesson.id)]!.outcome.passed)
        XCTAssertEqual(state.pendingChanges?.filter { $0.source == .assessment }.count,8)
        XCTAssertTrue(state.complete(lesson));XCTAssertEqual(state.xp,80);XCTAssertFalse(state.complete(lesson))
        let key=state.quizKey(lesson.id);state.quizRuns?.removeValue(forKey:key);XCTAssertTrue(state.quizPassed(lesson));XCTAssertEqual(state.xp,80)
    }
    @MainActor func testSourceQuizPlanPersistsSixteenUniqueFormatsWithoutFlashcards() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let recipes=try PracticeRecipes(source:root.appendingPathComponent("Piyali/Resources/practice-recipes.js")),context:JSONValue = .object(["lesson":PracticeCurriculum.lessonData(lesson),"targetLang":.string("es"),"user":.object([:])])
        var run=FinalQuizRun(lesson:lesson,learner:LearnerState());run.typedOptions=try (0..<32).map { try recipes.select(module:.grammar,context:context,randomSeed:UInt32($0+1)).setting("isFinalQuiz",.bool(true)) }
        let restored=try JSONDecoder().decode(FinalQuizRun.self,from:JSONEncoder().encode(run)),options=try XCTUnwrap(restored.typedOptions)
        for start in [0,16] { XCTAssertEqual(Set(options[start..<(start+16)].map { $0["exerciseType"].string }).count,16) }
        XCTAssertFalse(options.contains { $0["exerciseType"].string == "flashcard" });XCTAssertTrue(options.allSatisfy { $0["cefrLevel"].string == "A1" })
    }
}
