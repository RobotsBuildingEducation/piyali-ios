import XCTest
@testable import PiyaliCore

final class RPGPreparationTests:XCTestCase {
    private var root:URL{URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()}
    func testAllOriginalPreparationPromptValidationCacheAndSpeechCases()throws{
        let policy=try RPGPreparationPolicy(url:root.appendingPathComponent("Piyali/Resources/rpg-preparation-policy.js")),cases=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/rpg-preparation.json.gz"))
        XCTAssertEqual(cases.count,360)
        for (index,item) in cases.enumerated(){XCTAssertEqual(try policy.run(item["operation"].string,item["input"]),item["expected"],"Original preparation case \(index) \(item["operation"].string)")}
    }
    func testTypedPreparationKeepsWorldAndOriginalTaskWeightsWithFencedContent()throws{
        let policy=try RPGPreparationPolicy(url:root.appendingPathComponent("Piyali/Resources/rpg-preparation-policy.js")),fixture=try ContentLibrary.decode(JSONValue.self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/rpg.json")),row=fixture["stories"].array[0],base=try JSONDecoder().decode(RPGScenario.self,from:JSONEncoder().encode(row["base"])),request=try policy.request(scenario:base,lesson:.object(["id":.string("unit")]),target:"es",support:"en"),prepared=try XCTUnwrap(policy.prepare(response:"```json\n"+row["raw"].canonicalJSON+"\n```",request:request))
        XCTAssertEqual(prepared.scenario.worldKey,base.worldKey);XCTAssertEqual(prepared.scenario.npcs.map(\.name),base.npcs.map(\.name));XCTAssertEqual(prepared.scenario.quest.steps.map(\.weight),[1,1,1,1,1,1,2]);XCTAssertEqual(prepared.scenario.quest.steps.filter{$0.nodes[0].responseMode == "speech"}.count,2)
        let library=try ContentLibrary.decode(RPGLibrary.self,url:root.appendingPathComponent("Piyali/Resources/rpg-es.json.gz"));var run=RPGRun(target:"es",support:"en",lessonID:"unit",xpReward:30,scenario:prepared.scenario,world:try XCTUnwrap(library.worlds[base.worldKey]));run.choose(0);XCTAssertEqual(run.feedbackScene,"smiles");let restored=try JSONDecoder().decode(RPGRun.self,from:JSONEncoder().encode(run));XCTAssertEqual(restored.feedbackScene,"smiles");run.advance();XCTAssertNil(run.feedbackScene)
        XCTAssertNotNil(try policy.cached(prepared.cacheValue,request:request));XCTAssertNil(try policy.prepare(response:"bad JSON",request:request))
    }
}
