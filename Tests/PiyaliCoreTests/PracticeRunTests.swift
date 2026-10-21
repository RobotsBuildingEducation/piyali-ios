import XCTest
@testable import PiyaliCore

final class PracticeRunTests:XCTestCase {
    private let options:JSONValue = .object(["cefrLevel":.string("A1"),"direction":.string("target-to-support")])
    private var lesson:Lesson { .init(id:"lesson-practice",title:.string("Greetings"),description:.string(""),xpReward:50,modes:["grammar","vocabulary"],agenda:.object([:]),content:.object([:]),cefrLevel:"A1") }
    func testWrongAnswerCanRetryAndCorrectAnswerAwardsOnceWithActualAssistanceAndScope() throws {
        var state=LearnerState();state.target="es";state.support="en";_=state.beginLessonWork(lesson)
        let q=try PracticeQuestion(module:.grammar,kind:"mc",payload:.object(["question":.string("___, Ana."),"choices":.array([.string("Hola"),.string("Adiós")]),"answer":.string("Hola")]),options:options,target:"es",support:"en")
        var run=PracticeRun(question:q,lessonID:lesson.id,lessonLevel:"A1");run.response = .object(["indices":.array([.number(1)])]);state.savePractice(run)
        XCTAssertTrue(state.answerPractice(key:run.key,questionID:q.id,correct:false,reward:5));XCTAssertEqual(state.xp,0)
        run=try XCTUnwrap(state.practiceRuns?[run.key]);run.response = .object(["indices":.array([.number(0)])]);run.assisted=true;state.savePractice(run)
        XCTAssertTrue(state.answerPractice(key:run.key,questionID:q.id,correct:true,reward:5));XCTAssertFalse(state.answerPractice(key:run.key,questionID:q.id,correct:true,reward:5))
        XCTAssertEqual(state.xp,5);XCTAssertEqual(state.lessonWork?["es:"+lesson.id]?.earnedXP,5)
        let assessments=try XCTUnwrap(state.pendingChanges?.filter { $0.source == .assessment })
        XCTAssertEqual(assessments.map(\.independent),[true,false],"Ordinary choices are independent; a delivered assistant hint marks support.")
        XCTAssertEqual(state.pendingChanges?.last?.skillTreeLessonID,lesson.id);XCTAssertEqual(state.pendingChanges?.last?.skillTreeLessonLevel,"A1")
    }
    func testQuestionAndDuplicateWordPositionsResumeAndStaleAccountsCannotAward() throws {
        let q=try PracticeQuestion(module:.vocabulary,kind:"translate",payload:.object(["sentence":.string("Yo no digo que no"),"correctWords":.array(["I","do","not","say","no"].map(JSONValue.string)),"distractors":.array([.string("I")])]),options:options,target:"es",support:"en")
        let run=PracticeRun(question:q,lessonID:lesson.id,lessonLevel:"A1",response:.object(["indices":.array([.number(0),.number(5)])]),bank:["I","do","not","say","no","I"])
        var state=LearnerState();state.savePractice(run)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state)),saved=try XCTUnwrap(restored.practiceRuns?[run.key])
        XCTAssertEqual(saved.question.id,q.id);XCTAssertEqual(saved.bank,run.bank);XCTAssertEqual(saved.answerText,"I I")
        state.target="fr";XCTAssertFalse(state.answerPractice(key:run.key,questionID:q.id,correct:true,reward:6));XCTAssertEqual(state.totalXP,0)
        state.target="es";XCTAssertFalse(state.answerPractice(key:run.key,questionID:UUID(),correct:true,reward:6))
        XCTAssertEqual(q.answerLanguage,"en")
        let fill=try PracticeQuestion(module:.grammar,kind:"fill",payload:.object(["question":.string("___, Ana")]),options:options,target:"es",support:"en")
        XCTAssertEqual(fill.answerLanguage,"es","Question selection's random translation direction cannot switch fill or speech recognition into the support language.")
    }
    func testCollectingAndFlippingDoNotAwardAndCorrectFlashcardCollectsOnce() throws {
        let q=try PracticeQuestion(module:.vocabulary,kind:"flashcard",payload:.object(["concept":.string("Hello"),"answer":.string("Hola")]),options:options,target:"es",support:"en")
        var run=PracticeRun(question:q,lessonID:nil,lessonLevel:nil);run.showAnswer=true
        var state=LearnerState();state.savePractice(run);state.collectPracticeCard(run);state.collectPracticeCard(run)
        XCTAssertEqual(state.totalXP,0);XCTAssertEqual(state.practiceDecks?["es:vocabulary"]?.count,1)
        run.response = .object(["text":.string("Hola")]);state.savePractice(run)
        XCTAssertTrue(state.answerPractice(key:run.key,questionID:q.id,correct:true,reward:7));XCTAssertEqual(state.totalXP,7);XCTAssertEqual(state.practiceDecks?["es:vocabulary"]?.count,1)
        let saved=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state))
        XCTAssertEqual(saved.practiceRuns?[run.key]?.showAnswer,true);XCTAssertEqual(saved.practiceDecks?["es:vocabulary"]?.first?.answer,"Hola")
    }
}
