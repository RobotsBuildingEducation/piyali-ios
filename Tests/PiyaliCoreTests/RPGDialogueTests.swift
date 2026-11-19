import XCTest
@testable import PiyaliCore
final class RPGDialogueTests:XCTestCase {
    private var root:URL{URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()}
    func testAllOriginalDialoguePresentationTranslationAndChunkCases()throws{
        let p=try RPGDialoguePolicy(url:root.appendingPathComponent("Piyali/Resources/rpg-dialogue-policy.js")),f=try ContentLibrary.decode(JSONValue.self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/rpg-dialogue.json.gz"))
        XCTAssertEqual(f["cases"].array.count,303);XCTAssertEqual(f["traces"].array.count,7)
        for (index,row) in f["cases"].array.enumerated(){XCTAssertEqual(try p.run(row["operation"].string,row["input"]),row["expected"],"Original dialogue case \(index)")}
        for trace in f["traces"].array where trace["input"]["failAfter"] == .null{
            let plan=try p.plan(trace["input"]);XCTAssertEqual(plan.prompt,trace["expected"]["prompt"].string);var state=try p.initial(plan)
            for chunk in trace["input"]["chunks"].array{state=try p.append(chunk.string,state:state,plan:plan)};state=try p.append("",state:state,plan:plan,final:true)
            for field in ["lineTranslations","choiceTranslations","actionTranslations"]{XCTAssertEqual(state[field],trace["expected"]["final"][field])}
        }
    }
    func testCharacterWaveReservesTimeForUTF16AndCompletesWithoutOvershoot(){
        XCTAssertEqual(RPGCharacterReveal.opacity(unit:0,elapsed:0),0);XCTAssertEqual(RPGCharacterReveal.opacity(unit:0,elapsed:0.018),0)
        XCTAssertGreaterThan(RPGCharacterReveal.opacity(unit:0,elapsed:0.08),0);XCTAssertLessThan(RPGCharacterReveal.opacity(unit:0,elapsed:0.08),1)
        XCTAssertEqual(RPGCharacterReveal.opacity(unit:0,elapsed:0.138),1);XCTAssertEqual(RPGCharacterReveal.opacity(unit:1,elapsed:0.02),0)
        XCTAssertEqual(RPGCharacterReveal.opacity(unit:1000,elapsed:100),1)
    }
}
