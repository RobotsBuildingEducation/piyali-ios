import XCTest
@testable import PiyaliCore

final class LearningTeamsTests: XCTestCase {
    func testProgressRowsAndSignedTemplatesMatchActualWebSource() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/teams.json")
        let fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url))
        for sample in fixture["rows"].array { XCTAssertEqual(LearningTeams.progressRow(member:"npub1fixture",data:sample["data"],creator:true),sample["expected"]) }
        for sample in fixture["events"].array {
            let args=sample["args"]
            var actual=LearningTeams.teamTemplate(id:args["id"].string,name:args["name"].string,members:args["memberHexes"].array.map(\.string),createdAt:Int64(args["createdAt"].number),deleted:args["deleted"].boolean)
            actual=actual.setting("content",try JSONDecoder().decode(JSONValue.self,from:Data(actual["content"].string.utf8)))
            XCTAssertEqual(actual,sample["expected"])
        }
        for sample in fixture["departures"].array {
            let left:Int64?;if case .number(let value)=sample["left"] { left=Int64(value) } else { left=nil }
            XCTAssertEqual(LearningTeams.memberLeft(teamCreatedAt:Int64(sample["created"].number),leaveCreatedAt:left),sample["expected"].boolean)
        }
    }
    func testPublishedSnapshotIncludesLanguageCompanionAndDistinctScore() {
        var state=LearnerState();state.name=" Ada ";state.xpByLanguage["es"]=450;state.dailyGoal=30;state.dailyXP=20;state.companionName="Coco";state.companionType="robot";state.tutorLevels=["es":"B2"];state.ratingByLanguage=["es":PerformanceScore.rating(score:25)]
        let snapshot=LearningTeams.snapshot(state,now:Date(timeIntervalSince1970:1700000000)),row=LearningTeams.progressRow(member:"fixture",data:snapshot,creator:false)
        XCTAssertEqual(snapshot["updatedAt"].number,1700000000);XCTAssertEqual(row["name"].string,"Ada");XCTAssertEqual(row["level"].string,"B2");XCTAssertEqual(row["score"].number,25);XCTAssertEqual(row["progressPercent"].number,67)
        XCTAssertEqual(row["companion"]["type"].string,"robot");XCTAssertEqual(row["companion"]["level"].number,5)
        state.target="fr";XCTAssertEqual(LearningTeams.snapshot(state)["companion"]["level"].number,1);XCTAssertEqual(LearningTeams.snapshot(state)["companion"]["type"].string,"ghost")
        XCTAssertNil(snapshot.object["notes"]);XCTAssertNil(snapshot.object["conversationDrafts"])
    }
    func testLeaveReferencesTheSpecificCreatorAndTeam() {
        let creator=String(repeating:"a",count:64),event=LearningTeams.leaveTemplate(creator:creator,id:"same-id",createdAt:100)
        XCTAssertEqual(event["content"].string,"");XCTAssertEqual(event["tags"].array.last?.array.map(\.string),["a","30078:\(creator):learning-team:same-id"])
        XCTAssertNotEqual(LearningTeams.leaveIdentifier(creator:creator,id:"same-id"),LearningTeams.leaveIdentifier(creator:String(repeating:"b",count:64),id:"same-id"))
    }
}
