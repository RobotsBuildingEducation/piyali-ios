import XCTest
@testable import PiyaliCore
final class OralQuestionRulesTests:XCTestCase {
    func testOriginalVocabularyNormalizationAndOptionalSpeakingPrompt()throws{
        struct Case:Decodable{let input:JSONValue,expected:JSONValue}
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/oral-normalization.json"),cases=try JSONDecoder().decode([Case].self,from:Data(contentsOf:url));XCTAssertEqual(cases.count,20)
        for c in cases{let result=OralQuestionRules.normalize(c.input,module:.vocabulary);for key in ["target","display","variant"]{XCTAssertEqual(result[key],c.expected[key])}}
        for module in [PracticeRecipeModule.vocabulary,.grammar]{let type=module == .grammar ? "grammar_speak":"vocab_speak",q=try PracticeQuestion.parse("{\"type\":\"\(type)\",\"target\":\" Hola. \",\"variant\":\"TRANSLATE\"}",module:module,kind:"speak",options:.object([:]),target:"es",support:"en");XCTAssertEqual(q.audioText,"Hola.");XCTAssertEqual(q.questionText,"Hola.");XCTAssertThrowsError(try PracticeQuestion.parse("{\"type\":\"\(type)\",\"target\":\"   \"}",module:module,kind:"speak",options:.object([:]),target:"es",support:"en"))}
    }
}
