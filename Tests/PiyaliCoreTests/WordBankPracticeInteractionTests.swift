import XCTest
@testable import PiyaliCore
final class WordBankPracticeInteractionTests:XCTestCase {
    func testOriginalTranslationAndRepeatMovementHandlers()throws{
        struct Sample:Decodable{let component:String,input:JSONValue,expected:JSONValue}
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/word-bank-interactions.json"),samples=try JSONDecoder().decode([Sample].self,from:Data(contentsOf:url));XCTAssertEqual(samples.count,84)
        for sample in samples{let p=sample.input,state=WordBankPracticeInteraction.State(bank:p["state"]["bank"].array.map{Int($0.number)},selected:p["state"]["selected"].array.map{Int($0.number)}),result:WordBankPracticeInteraction.State
            if p["action"].string == "drag"{let d=p["drag"];result=WordBankPracticeInteraction.drag(state,fromSelected:d["source"]["droppableId"].string == "selected-words",index:Int(d["source"]["index"].number),toSelected:d["destination"] == .null ? nil:d["destination"]["droppableId"].string == "selected-words",position:Int(d["destination"]["index"].number),locked:p["locked"].boolean)}else{result=WordBankPracticeInteraction.tap(state,index:Int(p["position"].number),selected:p["action"].string == "return",locked:p["locked"].boolean)}
            XCTAssertEqual(result.json,sample.expected,"\(sample.component): \(p.canonicalJSON)")
        }
    }
    func testOriginalFallbackDistractorsAndGeneratedBankReadiness()throws{
        struct Sample:Decodable{let component:String,language:String,words:[String],expected:[String]}
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/word-bank-fallbacks.json"),samples=try JSONDecoder().decode([Sample].self,from:Data(contentsOf:url));XCTAssertEqual(samples.count,48)
        for s in samples{XCTAssertEqual(WordBankPracticeInteraction.fallbackDistractors(words:s.words,answerLanguage:s.language),s.expected,"\(s.component) \(s.language) \(s.words)")}
        for kind in ["translate","repeat"]{let q=try PracticeQuestion.parse(#"{"type":"translate","sentence":"And I eat","correctWords":["y","como"],"distractors":[]}"#,module:.grammar,kind:kind,options:.object(["direction":.string("support-to-target")]),target:"es",support:"en");XCTAssertEqual(q.strings("distractors"),["o","pero","muy","también"]);let run=PracticeRun(question:q,lessonID:nil,lessonLevel:nil,bank:q.strings("correctWords")+q.strings("distractors"));XCTAssertTrue(q.ready(.object(["indices":.array([.number(5)])])));XCTAssertEqual(run.bank.count,6)}
    }
    func testDuplicatePositionsPersistAndLegacyResponsesRecover()throws{
        let q=try PracticeQuestion(module:.vocabulary,kind:"repeat",payload:.object(["sentence":.string("Yo no digo que no"),"correctWords":.array(["no","no"].map(JSONValue.string)),"distractors":.array([.string("sí")])]),options:.object(["direction":.string("support-to-target"),"isListening":.bool(true)]),target:"es",support:"en")
        var run=PracticeRun(question:q,lessonID:nil,lessonLevel:nil,bank:["no","sí","no"]);var state=WordBankPracticeInteraction.state(run);state=WordBankPracticeInteraction.tap(state,index:2,selected:false);state=WordBankPracticeInteraction.tap(state,index:0,selected:false);state=WordBankPracticeInteraction.tap(state,index:0,selected:true);run.response=WordBankPracticeInteraction.response(run.response,state:state)
        let resumed=try JSONDecoder().decode(PracticeRun.self,from:JSONEncoder().encode(run));XCTAssertEqual(WordBankPracticeInteraction.state(resumed),.init(bank:[1,2],selected:[0]));XCTAssertEqual(run.answerText,"no");XCTAssertEqual(q.audioText,"no no")
        run.response = .object(["indices":.array([.number(2),.number(0)])]);XCTAssertEqual(WordBankPracticeInteraction.state(run),.init(bank:[1],selected:[2,0]))
        run.response=run.response.setting("wordBankOrder",.array([.number(2)]));XCTAssertEqual(WordBankPracticeInteraction.state(run),.init(bank:[1],selected:[2,0]))
        run.response = .object(["indices":.array([.number(0.5)])]);XCTAssertEqual(WordBankPracticeInteraction.state(run),.init(bank:[0,1,2],selected:[]))
    }
}
