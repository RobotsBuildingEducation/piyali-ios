import XCTest
@testable import Piyali
@MainActor final class WordBankReferenceGradeTests:XCTestCase {
    func testDistinctBankWordsUseTheSemanticJudgeInsteadOfAccentFolding()async throws {
        let service=PracticeService(),recipes=try PracticeRecipes()
        for pair in [["sí","si"],["か","が"],["и","й"],["ε","έ"],["मैं","में"],["🍎","🍌"],["قَلْب","قُلْب"]]{
            for kind in ["translate","repeat"] {
                let payload:JSONValue = .object(["sentence":.string("Use the requested word."),"correctWords":.array([.string(pair[1])]),"distractors":.array([.string(pair[0])])])
                let q=try PracticeQuestion(module:.grammar,kind:kind,payload:payload,options:.object(["cefrLevel":.string("A1")]),target:"es",support:"en");var calls=0
                let wrong=PracticeRun(question:q,lessonID:nil,lessonLevel:nil,response:.object(["indices":.array([.number(0)])]),bank:pair),rejected=try await service.verdict(run:wrong,recipes:recipes,judge:{_ in calls+=1;return "NO"});XCTAssertFalse(rejected.correct);XCTAssertEqual(calls,1)
                let correct=PracticeRun(question:q,lessonID:nil,lessonLevel:nil,response:.object(["indices":.array([.number(1)])]),bank:pair),accepted=try await service.verdict(run:correct,recipes:recipes,judge:{_ in XCTFail("The exact offered reference uses the original fast path");return "NO"});XCTAssertTrue(accepted.correct)
            }
        }
    }
}
