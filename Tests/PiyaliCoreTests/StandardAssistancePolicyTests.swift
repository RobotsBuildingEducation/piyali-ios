import XCTest
@testable import PiyaliCore
final class StandardAssistancePolicyTests:XCTestCase {
    private var root:URL{URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()}
    private func policy()throws->StandardAssistancePolicy{try .init(source:String(contentsOf:root.appendingPathComponent("Piyali/Resources/standard-assistance.js"),encoding:.utf8))}
    func testOriginalInlineHelpAndSubmittedSnapshotRequests()throws{
        struct Case:Decodable{let operation:String,input:JSONValue,output:JSONValue}
        let cases=try JSONDecoder().decode([Case].self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/standard-assistance.json"))),policy=try policy();XCTAssertEqual(cases.count,240)
        for c in cases{let result=try policy.runPolicy(c.operation,c.input);XCTAssertEqual(result,c.output);XCTAssertFalse(result["prompt"].string.contains("undefined"));if c.operation == "assistant",c.input["kind"].string != "match"{XCTAssertFalse(result["clipboard"].string.isEmpty);XCTAssertFalse(result["notice"].string.isEmpty)}}
    }
    func testCurrentTranslationPreferenceControlsTheOriginalBundle()throws {
        let q=try PracticeQuestion(module:.grammar,kind:"fill",payload:.object(["question":.string("La ___"),"answer":.string("niña"),"hint":.string("hint"),"translation":.string("translation")]),options:.object([:]),target:"es",support:"en"),run=PracticeRun(question:q,lessonID:nil,lessonLevel:"A1"),p=try policy()
        XCTAssertEqual(try p.build("assistant",run:run,showTranslations:false)["clipboard"].string,"La ___\nHint: hint")
        XCTAssertEqual(try p.build("assistant",run:run,showTranslations:true)["clipboard"].string,"La ___\nHint: hint\nTranslation: translation")
    }
    func testWrongMultipleSelectionsRetainSourceCommasAfterEditingAndRelaunch()throws{
        let q=try PracticeQuestion(module:.grammar,kind:"ma",payload:.object(["question":.string("Choose two relatives"),"choices":.array(["madre","padre","pan"].map(JSONValue.string)),"answers":.array(["madre","padre"].map(JSONValue.string))]),options:.object([:]),target:"es",support:"en")
        var state=LearnerState();state.target="es";state.support="en";let run=PracticeRun(question:q,lessonID:nil,lessonLevel:"A1",response:.object(["indices":.array([.number(0),.number(2)])]));state.savePractice(run);XCTAssertTrue(state.answerPractice(key:run.key,questionID:q.id,correct:false,reward:6));var saved=try XCTUnwrap(state.practiceRuns?[run.key]);saved.response=saved.response.setting("indices",.array([.number(1)]))
        let restored=try JSONDecoder().decode(PracticeRun.self,from:JSONEncoder().encode(saved)),request=try policy().build("explanation",run:restored)
        XCTAssertTrue(request["prompt"].string.contains("Student's answers: madre, pan"));XCTAssertTrue(request["prompt"].string.contains("Correct answers: madre, padre"));XCTAssertEqual(state.totalXP,0)
        saved.lastMissedResponse=nil;saved.lastMissedAnswer="Older saved wrong attempt";let legacy=try JSONDecoder().decode(PracticeRun.self,from:JSONEncoder().encode(saved));XCTAssertNil(legacy.lastMissedResponse);XCTAssertTrue(try policy().build("explanation",run:legacy)["prompt"].string.contains("Older saved wrong attempt"))
    }
}
