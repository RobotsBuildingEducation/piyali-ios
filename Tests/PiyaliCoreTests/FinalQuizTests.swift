import XCTest
@testable import PiyaliCore

final class FinalQuizTests:XCTestCase {
    private var root:URL { URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent() }
    private func lesson() throws -> Lesson {
        let data=try ContentLibrary.decode([String:[LearningUnit]].self,url:root.appendingPathComponent("Piyali/Resources/curriculum-es.json.gz"))
        return try XCTUnwrap(data["Pre-A1"]?.flatMap(\.lessons).first { $0.isFinalQuiz == true })
    }
    private func exercise() -> Exercise { Exercise(passage:"",question:"Choose a greeting",choices:["hola","adiós"],answer:"hola",explanation:"Hola means hello.") }
    func testOutcomesMatchEverySourceReachablePrefix() throws {
        let cases=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/quiz-outcomes.json")))
        XCTAssertEqual(cases.count,9216)
        for item in cases {
            let outcome=QuizRules(item["config"]).outcome(item["history"].array.map(\.boolean)),expected=item["expected"]
            XCTAssertEqual(outcome.answered,Int(expected["answered"].number));XCTAssertEqual(outcome.correct,Int(expected["correct"].number));XCTAssertEqual(outcome.wrong,Int(expected["wrong"].number));XCTAssertEqual(outcome.completed,expected["completed"].boolean);XCTAssertEqual(outcome.passed,expected["passed"].boolean)
        }
    }
    func testAllCurriculaRetainFinalQuizMetadataAndAuthoredLevel() throws {
        var total=0,quizzes=0
        for language in LearningLanguages.practice+["nah","yua"] {
            let levels=try ContentLibrary.decode([String:[LearningUnit]].self,url:root.appendingPathComponent("Piyali/Resources/curriculum-"+language+".json.gz"))
            for (level,units) in levels { for item in units.flatMap(\.lessons) {
                total += 1;XCTAssertEqual(item.cefrLevel,level)
                if item.isFinalQuiz == true { quizzes += 1;XCTAssertEqual(Set(item.modes),["grammar","vocabulary"]);let rules=QuizRules(item.quizConfig ?? .null);XCTAssertTrue([10,12].contains(rules.questionsRequired));XCTAssertEqual(rules.passingScore,rules.questionsRequired-2) }
            } }
        }
        XCTAssertEqual(total,8736);XCTAssertEqual(quizzes,1246)
    }
    func testNoQuestionXPOnceOnlyAssessmentAndPassedLessonReward() throws {
        let lesson=try lesson();var state=LearnerState(),run=FinalQuizRun(lesson:lesson,learner:LearnerState())
        state.practicedModes=[state.modeKey(lesson.id,"Grammar"),state.modeKey(lesson.id,"Vocabulary")]
        XCTAssertFalse(state.complete(lesson));XCTAssertFalse(state.quizPassed(lesson))
        for index in 0..<8 {
            XCTAssertTrue(run.prepare(exercise(),mode:index%2==0 ? .grammar : .vocabulary));state.saveQuiz(run)
            let id=try XCTUnwrap(run.question?.id),grade=Grade(correct:true,feedback:"Correct",correctedAnswer:"hola")
            XCTAssertTrue(state.answerQuiz(lesson:lesson,runID:run.id,questionID:id,answer:"hola",grade:grade));XCTAssertFalse(state.answerQuiz(lesson:lesson,runID:run.id,questionID:id,answer:"hola",grade:grade))
            XCTAssertEqual(state.totalXP,0);run=try XCTUnwrap(state.quizRuns?[state.quizKey(lesson.id)])
            state=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state))
        }
        XCTAssertTrue(run.outcome.passed);XCTAssertEqual(run.outcome.answered,8);XCTAssertTrue(state.quizPassed(lesson));XCTAssertEqual(state.pendingChanges?.count,8);XCTAssertEqual(Set(state.pendingChanges!.map(\.id)).count,8)
        XCTAssertTrue(state.complete(lesson));XCTAssertEqual(state.totalXP,lesson.xpReward);XCTAssertFalse(state.complete(lesson));XCTAssertEqual(state.totalXP,lesson.xpReward)
        state.quizRuns=[:];XCTAssertTrue(state.quizPassed(lesson));state.support="fr";XCTAssertTrue(state.quizPassed(lesson))
    }
    func testIncompleteQuestionsCannotReplaceTheCurrentDraft() throws {
        let lesson=try lesson();var run=FinalQuizRun(lesson:lesson,learner:LearnerState())
        XCTAssertFalse(run.prepare(Exercise(passage:"",question:"",choices:[],answer:"hola",explanation:""),mode:.grammar))
        XCTAssertFalse(run.prepare(Exercise(passage:"",question:"Choose",choices:["adiós","gracias"],answer:"hola",explanation:""),mode:.vocabulary))
        XCTAssertTrue(run.prepare(exercise(),mode:.grammar));let first=run.question?.id
        XCTAssertFalse(run.prepare(exercise(),mode:.vocabulary));XCTAssertEqual(run.question?.id,first)
    }
    func testEarlyFailureCannotCompleteAndRetryFencesOldAnswers() throws {
        let lesson=try lesson();var state=LearnerState(),run=FinalQuizRun(lesson:lesson,learner:LearnerState())
        for _ in 0..<3 { XCTAssertTrue(run.prepare(exercise(),mode:.grammar));state.saveQuiz(run);let id=try XCTUnwrap(run.question?.id);XCTAssertTrue(state.answerQuiz(lesson:lesson,runID:run.id,questionID:id,answer:"adiós",grade:Grade(correct:false,feedback:"Incorrect",correctedAnswer:"hola")));run=try XCTUnwrap(state.quizRuns?[state.quizKey(lesson.id)]) }
        XCTAssertTrue(run.outcome.completed);XCTAssertFalse(run.outcome.passed);XCTAssertFalse(state.complete(lesson));XCTAssertFalse(run.prepare(exercise(),mode:.vocabulary));XCTAssertEqual(state.totalXP,0)
        let oldRun=run;run=FinalQuizRun(lesson:lesson,learner:state);XCTAssertTrue(run.prepare(exercise(),mode:.vocabulary));state.saveQuiz(run)
        XCTAssertFalse(state.answerQuiz(lesson:lesson,runID:oldRun.id,questionID:oldRun.question!.id,answer:"hola",grade:Grade(correct:true,feedback:"Late",correctedAnswer:"hola")))
        state.support="fr";XCTAssertFalse(state.answerQuiz(lesson:lesson,runID:run.id,questionID:run.question!.id,answer:"hola",grade:Grade(correct:true,feedback:"Late",correctedAnswer:"hola")))
        XCTAssertEqual(state.quizRuns?[state.quizKey(lesson.id)]?.answers.count,0)
    }
}
