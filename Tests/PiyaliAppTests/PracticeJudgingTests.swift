import XCTest
@testable import Piyali

@MainActor final class PracticeJudgingTests:XCTestCase {
    private let options:JSONValue = .object(["cefrLevel":.string("A1"),"direction":.string("target-to-support")])
    func testVocabularyFillUsesItsActualSentenceContractAndAcceptsModelAlternatives() async throws {
        let engine=try PracticeRecipes(),service=PracticeService()
        let question=try PracticeQuestion(module:.vocabulary,kind:"fill",payload:.object(["question":.string("Yo ___ beber agua."),"hint":.string("express a need")]),options:options,target:"es",support:"en")
        let run=PracticeRun(question:question,lessonID:nil,lessonLevel:nil,response:.object(["text":.string("quiero")]))
        let verdict=try await service.verdict(run:run,recipes:engine,judge:{ prompt in
            XCTAssertTrue(prompt.contains("Yo ___ beber agua."));XCTAssertTrue(prompt.contains("Yo quiero beber agua."));XCTAssertFalse(prompt.contains("undefined"));return "YES"
        })
        XCTAssertTrue(verdict.correct);XCTAssertEqual(question.standardReward,5)
    }
    func testOrderedBankAlternativeUsesCorrectLanguagesAndPreservesSemanticJudge() async throws {
        let engine=try PracticeRecipes(),service=PracticeService()
        let question=try PracticeQuestion(module:.grammar,kind:"translate",payload:.object(["sentence":.string("No quiero agua."),"correctWords":.array(["I","do","not","want","water"].map(JSONValue.string)),"distractors":.array([.string("don't")])]),options:options,target:"es",support:"en")
        let run=PracticeRun(question:question,lessonID:nil,lessonLevel:nil,response:.object(["indices":.array([0,5,3,4].map { .number(Double($0)) })]),bank:["I","do","not","want","water","don't"])
        let result=try await service.verdict(run:run,recipes:engine,judge:{ prompt in XCTAssertTrue(prompt.contains("I don't want water"));XCTAssertTrue(prompt.contains("Source sentence (Spanish)"));XCTAssertTrue(prompt.contains("Expected translation (English)"));return "YES" })
        XCTAssertTrue(result.correct)
    }
    func testNaturalOrWeirdStaysDeterministicAndFlashcardUsesFourToSevenReward() async throws {
        let engine=try PracticeRecipes(),service=PracticeService()
        let q=try PracticeQuestion(module:.grammar,kind:"delight:natural_or_weird",payload:.object(["variant":.string("natural_or_weird"),"isNatural":.bool(false)]),options:options,target:"es",support:"en")
        for choice in [true,false] {
            let run=PracticeRun(question:q,lessonID:nil,lessonLevel:nil,response:.object(["choice":.bool(choice)]))
            let result=try await service.verdict(run:run,recipes:engine,judge:{ _ in XCTFail("Binary contract must not call a model");return "YES" });XCTAssertEqual(result.correct,!choice)
        }
        let card=try PracticeQuestion(module:.vocabulary,kind:"flashcard",payload:.object(["concept":.string("hello"),"answer":.string("hola")]),options:options,target:"es",support:"en")
        let run=PracticeRun(question:card,lessonID:nil,lessonLevel:nil,response:.object(["text":.string("hola")]))
        let result=try await service.verdict(run:run,recipes:engine,judge:{ prompt in XCTAssertTrue(prompt.contains("hello"));return "YES | 7" });XCTAssertTrue(result.correct);XCTAssertEqual(result.reward,7)
    }
}
