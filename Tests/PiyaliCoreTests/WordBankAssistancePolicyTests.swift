import XCTest
@testable import PiyaliCore
final class WordBankAssistancePolicyTests:XCTestCase {
    func testOriginalWordBankHelpAndExplanationPrompts()throws {
        struct Case:Decodable{let operation:String,input:JSONValue,output:JSONValue}
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),policy=try WordBankAssistancePolicy(source:String(contentsOf:root.appendingPathComponent("Piyali/Resources/word-bank-assistance.js"),encoding:.utf8)),cases=try JSONDecoder().decode([Case].self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/word-bank-assistance.json")));XCTAssertEqual(cases.count,80)
        for c in cases{XCTAssertEqual(try policy.runPolicy(c.operation,c.input),c.output,"\(c.operation): \(c.input.canonicalJSON)");XCTAssertFalse(c.output["prompt"].string.contains("undefined"))}
        for c in cases where c.input["supportLang"].string == "en"{
            let p=c.input,q=try PracticeQuestion(module:p["module"].string == "grammar" ? .grammar:.vocabulary,kind:p["kind"].string,payload:.object(["sentence":p["sourceSentence"],"correctWords":p["correctWords"],"distractors":.array([]),"hint":p["hint"]]),options:.object(["direction":.string("target-to-support")]),target:p["targetLang"].string,support:p["supportLang"].string),run=PracticeRun(question:q,lessonID:nil,lessonLevel:nil,response:.object(["indices":.array([.number(Double(p["wordBank"].array.count))])]),bank:p["wordBank"].array.map(\.string)+[p["userAnswer"].string])
            let expected=try policy.runPolicy(c.operation,p.setting("wordBank",.array(run.bank.map(JSONValue.string))));XCTAssertEqual(try policy.build(c.operation,run:run),expected)
        }
    }
}
