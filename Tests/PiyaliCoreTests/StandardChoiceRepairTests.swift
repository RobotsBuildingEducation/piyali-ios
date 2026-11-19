import XCTest
@testable import PiyaliCore
final class StandardChoiceRepairTests:XCTestCase {
    func testOriginalGeneratedChoiceRepairWithControlledReplacementPositions()throws {
        struct Case:Decodable{let kind:String,input:JSONValue,expected:JSONValue}
        struct Fixture:Decodable{let repairs:[Case]}
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/standard-interactions.json"),fixture=try JSONDecoder().decode(Fixture.self,from:Data(contentsOf:url));XCTAssertEqual(fixture.repairs.count,64)
        for c in fixture.repairs{let payload=c.input.setting("random",.null),index=Int(floor(c.input["random"].number*Double(c.input["choices"].array.count))),result=StandardChoiceRepair.repair(kind:c.kind,payload:payload,replacementIndex:index)
            for (key,value) in c.expected.object{XCTAssertEqual(result[key],value,c.input.canonicalJSON)}
        }
    }
    func testNonLatinAndSymbolReferencesRemainDistinctAndParsingRepairsMissingAnswers()throws {
        for words in [["猫","犬"],["кошка","собака"],["قطة","كلب"],["🍎","🍌"],["か","が"],["и","й"],["ε","έ"],["मैं","में"]]{let payload:JSONValue = .object(["choices":.array(words.map(JSONValue.string)),"answer":.string(words[1])]),result=StandardChoiceRepair.repair(kind:"mc",payload:payload,replacementIndex:0);XCTAssertEqual(result["answer"].string,words[1]);XCTAssertNotEqual(StandardChoiceRepair.normalized(words[0]),StandardChoiceRepair.normalized(words[1]))}
        let accents:JSONValue = .object(["choices":.array([.string("sí"),.string("si")]),"answer":.string("si")]);XCTAssertEqual(StandardChoiceRepair.repair(kind:"mc",payload:accents)["answer"].string,"si")
        for module in [PracticeRecipeModule.grammar,.vocabulary]{let type=module == .grammar ? "mc":"vocab_mc",raw="{\"type\":\"\(type)\",\"phase\":\"q\",\"question\":\"Yo ___ pan.\"}\n{\"type\":\"\(type)\",\"phase\":\"meta\",\"choices\":[\"comes\",\"comen\"],\"answer\":\"como\"}",q=try PracticeQuestion.parse(raw,module:module,kind:"mc",options:.object([:]),target:"es",support:"en");XCTAssertTrue(q.strings("choices").contains("como"));XCTAssertEqual(q.payload["answer"].string,"como")}
    }
    func testFillWithoutAnExplicitAnswerRetainsTheOriginalHintForRepairMemory()throws {
        for module in [PracticeRecipeModule.grammar,.vocabulary]{let q=try PracticeQuestion(module:module,kind:"fill",payload:.object(["question":.string("Yo ___ pan."),"hint":.string("Use the first-person form of comer.")]),options:.object([:]),target:"es",support:"en"),run=PracticeRun(question:q,lessonID:nil,lessonLevel:nil);XCTAssertEqual(run.expected,q.payload["hint"].string)}
    }

    func testInvalidVocabularyChoicesExampleIsCorrectedWithoutChangingValidPrompts()throws {
        for type in ["vocab_mc","vocab_ma"]{
            let original="{\"type\":\"\(type)\",\"phase\":\"choices\":[\"madre\",\"perro\"]}",fixed=StandardChoiceRepair.prompt(original),value=try JSONDecoder().decode(JSONValue.self,from:Data(fixed.utf8));XCTAssertEqual(value["phase"].string,"choices");XCTAssertEqual(value["choices"],.array([.string("madre"),.string("perro")]));XCTAssertEqual(StandardChoiceRepair.prompt(fixed),fixed)
        }
        XCTAssertEqual(StandardChoiceRepair.prompt("Teacher asks which family word fits."),"Teacher asks which family word fits.")
    }

}
