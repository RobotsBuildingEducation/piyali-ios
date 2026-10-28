import XCTest
@testable import PiyaliCore

final class FirstRunFlowTests:XCTestCase {
    func testFirstRunSequenceMatchesTheExecutedSourceCallbacks() throws {
        let rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/first-run-policy.json")))
        XCTAssertEqual(rows.count,288)
        for row in rows {
            var flow=FirstRunFlow();let prompted=row["prompted"].string
            if !prompted.isEmpty {flow.request(scope:prompted,shown:true,paperShown:true,hasPlacement:false);flow.close()}
            let state=WebProgressContract.imported(row["fields"].foundation)
            XCTAssertEqual(state.paperPencilModalShown == true,row["paperShown"] == .bool(true))
            XCTAssertEqual(state.hasFirstRunPlacement,row["hasPlacement"].boolean)
            flow.request(scope:"fixture:es",shown:row["shown"] == .bool(true),paperShown:row["paperShown"] == .bool(true),hasPlacement:state.hasFirstRunPlacement)
            XCTAssertEqual(flow.step?.rawValue,row["initial"] == .null ? nil : row["initial"].string)
            if flow.step == .paperPencil {XCTAssertTrue(flow.acknowledgePaper(scope:"fixture:es",shown:row["shown"] == .bool(true),hasPlacement:state.hasFirstRunPlacement))}
            XCTAssertEqual(flow.step?.rawValue,row["afterPaper"] == .null ? nil : row["afterPaper"].string)
            if flow.step == .gettingStarted {XCTAssertTrue(flow.acknowledge(scope:"fixture:es",hasPlacement:state.hasFirstRunPlacement))}
            XCTAssertEqual(flow.step?.rawValue,row["afterAck"] == .null ? nil : row["afterAck"].string)
            XCTAssertEqual(flow.promptedPlacement,row["promptAfter"] == .null ? nil : row["promptAfter"].string)
        }
    }
    func testChangingAccountOrLanguageClosesTheOldGuidanceWithoutAcknowledgingIt() {
        var flow=FirstRunFlow();flow.request(scope:"a:es",shown:false,paperShown:true,hasPlacement:false)
        flow.reconcile(scope:"b:es");XCTAssertNil(flow.step);XCTAssertFalse(flow.acknowledge(scope:"b:es",hasPlacement:false))
        flow.request(scope:"b:es",shown:true,paperShown:true,hasPlacement:false);XCTAssertEqual(flow.step,.placement);flow.close()
        flow.request(scope:"b:es",shown:true,paperShown:true,hasPlacement:false);XCTAssertNil(flow.step)
        flow.request(scope:"b:fr",shown:true,paperShown:true,hasPlacement:false);XCTAssertEqual(flow.step,.placement)
    }
    func testSeenFlagIsMonotonicAcrossImportsAndConcurrentAcknowledgment() throws {
        var local=LearnerState();local.gettingStartedModalShown=true
        let stale=WebProgressContract.imported(["gettingStartedModalShown":false],native:local);XCTAssertTrue(stale.gettingStartedModalShown == true)
        XCTAssertTrue(WebProgressContract.imported(["gettingStartedModalShown":true]).gettingStartedModalShown == true)
        XCTAssertTrue(LearnerState.rebased(current:local,sent:LearnerState(),acknowledged:LearnerState()).gettingStartedModalShown == true)
        let json=try JSONEncoder().encode(local);XCTAssertTrue(try JSONDecoder().decode(LearnerState.self,from:json).gettingStartedModalShown == true)
        local.paperPencilModalShown=true
        XCTAssertTrue(WebProgressContract.imported(["paperPencilModalShown":false],native:local).paperPencilModalShown == true)
        XCTAssertTrue(WebProgressContract.imported(["paperPencilModalShown":true]).paperPencilModalShown == true)
        XCTAssertTrue(LearnerState.rebased(current:local,sent:LearnerState(),acknowledged:LearnerState()).paperPencilModalShown == true)
        XCTAssertTrue(try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(local)).paperPencilModalShown == true)
    }
    func testPaperAcknowledgmentUsesLatestSetupStateAndRejectsAnOldScope(){
        var flow=FirstRunFlow();flow.request(scope:"first:es",shown:false,paperShown:false,hasPlacement:false);XCTAssertEqual(flow.step,.paperPencil);flow.reconcile(scope:"second:es");XCTAssertFalse(flow.acknowledgePaper(scope:"first:es",shown:false,hasPlacement:false));XCTAssertNil(flow.step)
        flow.request(scope:"second:es",shown:false,paperShown:false,hasPlacement:false);XCTAssertTrue(flow.acknowledgePaper(scope:"second:es",shown:true,hasPlacement:false));XCTAssertEqual(flow.step,.placement)
    }
    func testLanguagePlacementMapReplacesTheLegacyGlobalPromptGuard() {
        var state=WebProgressContract.imported(["proficiencyPlacement":"B1","progress":["targetLang":"es"]]);XCTAssertTrue(state.hasFirstRunPlacement)
        state.target="fr";state.place(.init(level:"A1",score:18,source:"self_report",selectedIDs:[],updatedAt:Date()));state.target="es";XCTAssertFalse(state.hasFirstRunPlacement)
        let legacy=WebProgressContract.imported(["proficiencyPlacement":"B1"]),newer=WebProgressContract.imported(["proficiencyPlacements":["fr":"A1"]])
        XCTAssertNil(LearnerState.rebased(current:legacy,sent:legacy,acknowledged:newer).legacyFirstRunPlacement)
    }

}
