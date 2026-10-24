import XCTest
@testable import PiyaliCore

final class FirstRunFlowTests:XCTestCase {
    func testFirstRunSequenceMatchesTheExecutedSourceCallbacks() throws {
        let rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/first-run-policy.json")))
        XCTAssertEqual(rows.count,72)
        for row in rows {
            var flow=FirstRunFlow();let prompted=row["prompted"].string
            if !prompted.isEmpty {flow.request(scope:prompted,shown:true,hasPlacement:false);flow.close()}
            let state=WebProgressContract.imported(row["fields"].foundation)
            XCTAssertEqual(state.hasFirstRunPlacement,row["hasPlacement"].boolean)
            flow.request(scope:"fixture:es",shown:row["shown"] == .bool(true),hasPlacement:state.hasFirstRunPlacement)
            XCTAssertEqual(flow.step?.rawValue,row["initial"] == .null ? nil : row["initial"].string)
            if flow.step == .gettingStarted {XCTAssertTrue(flow.acknowledge(scope:"fixture:es",hasPlacement:state.hasFirstRunPlacement))}
            XCTAssertEqual(flow.step?.rawValue,row["afterAck"] == .null ? nil : row["afterAck"].string)
            XCTAssertEqual(flow.promptedPlacement,row["promptAfter"] == .null ? nil : row["promptAfter"].string)
        }
    }
    func testChangingAccountOrLanguageClosesTheOldGuidanceWithoutAcknowledgingIt() {
        var flow=FirstRunFlow();flow.request(scope:"a:es",shown:false,hasPlacement:false)
        flow.reconcile(scope:"b:es");XCTAssertNil(flow.step);XCTAssertFalse(flow.acknowledge(scope:"b:es",hasPlacement:false))
        flow.request(scope:"b:es",shown:true,hasPlacement:false);XCTAssertEqual(flow.step,.placement);flow.close()
        flow.request(scope:"b:es",shown:true,hasPlacement:false);XCTAssertNil(flow.step)
        flow.request(scope:"b:fr",shown:true,hasPlacement:false);XCTAssertEqual(flow.step,.placement)
    }
    func testSeenFlagIsMonotonicAcrossImportsAndConcurrentAcknowledgment() throws {
        var local=LearnerState();local.gettingStartedModalShown=true
        let stale=WebProgressContract.imported(["gettingStartedModalShown":false],native:local);XCTAssertTrue(stale.gettingStartedModalShown == true)
        XCTAssertTrue(WebProgressContract.imported(["gettingStartedModalShown":true]).gettingStartedModalShown == true)
        XCTAssertTrue(LearnerState.rebased(current:local,sent:LearnerState(),acknowledged:LearnerState()).gettingStartedModalShown == true)
        let json=try JSONEncoder().encode(local);XCTAssertTrue(try JSONDecoder().decode(LearnerState.self,from:json).gettingStartedModalShown == true)
    }
    func testLanguagePlacementMapReplacesTheLegacyGlobalPromptGuard() {
        var state=WebProgressContract.imported(["proficiencyPlacement":"B1","progress":["targetLang":"es"]]);XCTAssertTrue(state.hasFirstRunPlacement)
        state.target="fr";state.place(.init(level:"A1",score:18,source:"self_report",selectedIDs:[],updatedAt:Date()));state.target="es";XCTAssertFalse(state.hasFirstRunPlacement)
        let legacy=WebProgressContract.imported(["proficiencyPlacement":"B1"]),newer=WebProgressContract.imported(["proficiencyPlacements":["fr":"A1"]])
        XCTAssertNil(LearnerState.rebased(current:legacy,sent:legacy,acknowledged:newer).legacyFirstRunPlacement)
    }

}
