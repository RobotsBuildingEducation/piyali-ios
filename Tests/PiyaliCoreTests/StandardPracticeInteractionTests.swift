import XCTest
@testable import PiyaliCore
final class StandardPracticeInteractionTests:XCTestCase {
    func testOriginalSelectorsAndStandardMovementHandlers()throws {
        struct Sample:Decodable{let module:String,input:JSONValue,expected:JSONValue}
        struct Layout:Decodable{let module:String,question:String,choices:[String],answers:[String],hash:UInt32,blanks:Int,drag:Bool}
        struct Fixture:Decodable{let samples:[Sample],layouts:[Layout]}
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/standard-interactions.json"),fixtures=try JSONDecoder().decode(Fixture.self,from:Data(contentsOf:url))
        XCTAssertEqual(fixtures.samples.count,70);XCTAssertEqual(fixtures.layouts.count,126)
        for example in fixtures.layouts{XCTAssertEqual(StandardPracticeInteraction.hash(example.question+"||"+example.choices.joined(separator:"|")+"||"+example.answers.joined(separator:"|")),example.hash);XCTAssertEqual(StandardPracticeInteraction.blankCount(example.question),example.blanks);XCTAssertEqual(StandardPracticeInteraction.useDrag(question:example.question,choices:example.choices,answers:example.answers,module:example.module == "grammar" ? .grammar:.vocabulary),example.drag)}
        for example in fixtures.samples{
            let p=example.input,state=StandardPracticeInteraction.State(p["state"]),kind=p["kind"].string,choices=p["choices"].array.map(\.string),result:StandardPracticeInteraction.State
            if p["action"].string == "slotTap"{result=StandardPracticeInteraction.returnSlot(kind:kind,state:state,slot:Int(p["position"].number))}
            else if p["action"].string == "tap",kind == "match",p["source"].string.hasPrefix("slot-"){result=StandardPracticeInteraction.returnSlot(kind:kind,state:state,slot:Int(p["source"].string.dropFirst(5))!)}
            else if p["action"].string == "tap"{result=StandardPracticeInteraction.tap(kind:kind,state:state,index:Int(p["index"].number),choices:choices)}
            else{let d=p["drag"],ri=Int(d["draggableId"].string.replacingOccurrences(of:"r-",with:""));result=StandardPracticeInteraction.drag(kind:kind,state:state,choices:choices,source:d["source"]["droppableId"].string,sourceIndex:Int(d["source"]["index"].number),destination:d["destination"] == .null ? nil:d["destination"]["droppableId"].string,destinationIndex:Int(d["destination"]["index"].number),item:ri)}
            XCTAssertEqual(result.json,example.expected,"\(example.module): \(p.canonicalJSON)")
        }
    }
    func testSlotResponsePersistenceLegacyRecoveryAndCompleteMAReadiness()throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),data=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliAppTests/Fixtures/standard-bodies.json")))
        for module in [PracticeRecipeModule.vocabulary,.grammar]{
            for variant in ["mc-drag","ma-drag","match"]{
                let sample=data[module.rawValue][variant],q=try PracticeQuestion(module:module,kind:sample["kind"].string,payload:sample["question"],options:.object(["cefrLevel":.string("A1")]),target:"es",support:"en")
                if q.kind != "match"{XCTAssertTrue(StandardPracticeInteraction.usesSlots(q))}
                for name in ["idle","partial","filled","locked"]{
                    var run=PracticeRun(question:q,lessonID:nil,lessonLevel:nil,response:sample["responses"][name]);run.rightOrder=[2,0,1]
                    let state=StandardPracticeInteraction.state(run),response=StandardPracticeInteraction.response(run.response,state:state,kind:q.kind,choices:q.kind == "match" ? q.strings("right"):run.bank)
                    XCTAssertEqual(response["indices"],run.response["indices"]);XCTAssertEqual(response["pairs"],run.response["pairs"])
                    let roundTrip=try JSONDecoder().decode(PracticeRun.self,from:JSONEncoder().encode(run));XCTAssertEqual(StandardPracticeInteraction.state(roundTrip),state)
                    if q.kind == "ma"{XCTAssertEqual(q.ready(response),name == "filled" || name == "locked")}
                    run.response=run.response.setting("standardState",.null);let recovered=StandardPracticeInteraction.state(run);XCTAssertEqual((recovered.bank+recovered.slots.compactMap{$0}).sorted(),Array(0..<(q.kind == "match" ? q.strings("right").count:run.bank.count)))
                }
            }
            let sample=data[module.rawValue]["ma-buttons"],q=try PracticeQuestion(module:module,kind:"ma",payload:sample["question"],options:.object(["cefrLevel":.string("A1")]),target:"es",support:"en");XCTAssertFalse(StandardPracticeInteraction.usesSlots(q));XCTAssertTrue(q.ready(.object(["indices":.array([.number(0)])])))
        }
    }

}
