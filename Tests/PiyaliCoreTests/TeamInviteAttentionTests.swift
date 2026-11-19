import XCTest
@testable import PiyaliCore

final class TeamInviteAttentionTests:XCTestCase {
    func testActualAppInvitationEffectsMatchNativeAttentionAcrossViewedDuplicateAndReplacementIDs()throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let fixture=try ContentLibrary.decode(JSONValue.self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/team-invite-attention.json"))
        XCTAssertEqual(fixture["attentionCases"].array.count,56)
        for row in fixture["attentionCases"].array {
            var state=TeamInviteAttention()
            for(index,action)in row["actions"].array.enumerated(){if action["kind"].string == "viewed"{state.viewed()}else{state.receive(action["invites"].array)};XCTAssertEqual(state.count,Int(row["expected"].array[index]["count"].number));XCTAssertEqual(state.hasUnseen,row["expected"].array[index]["unseen"].boolean)}
        }
    }
}
