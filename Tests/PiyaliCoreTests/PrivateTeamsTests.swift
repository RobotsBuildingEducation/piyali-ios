import XCTest
@testable import PiyaliCore

final class PrivateTeamsTests:XCTestCase {
    func testInvitationMutationsMatchTheExecutedWebHelpersAndPreserveOtherMembers() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/private-teams.json")
        let cases=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url))
        XCTAssertEqual(cases.count,4)
        for sample in cases {
            let changed=try PrivateTeams.responding(sample["team"],member:sample["member"].string,accept:sample["accept"].boolean)
            XCTAssertEqual(changed["members"].array.sorted { $0["npub"].string < $1["npub"].string },sample["expected"]["members"].array.sorted { $0["npub"].string < $1["npub"].string })
            XCTAssertEqual(changed["legacyMarker"],sample["team"]["legacyMarker"])
            XCTAssertEqual(changed["_memberChange"]["before"]["legacy"],.string("keep"))
            if sample["accept"].boolean { XCTAssertEqual(changed["_memberChange"]["after"]["status"],.string("accepted")) }
        }
    }
    func testNewInvitationsRequireDistinctValidMembersAndRetainTheExistingRoster() throws {
        let owner="npub1"+String(repeating:"q",count:58),member="npub1"+String(repeating:"p",count:58)
        let team:JSONValue = .object(["teamName":.string("Weekend"),"members":.array([])])
        let result=try PrivateTeams.adding([member],to:team,creator:owner,now:Date(timeIntervalSince1970:1700000000))
        XCTAssertEqual(result.team["members"].array.count,1);XCTAssertEqual(result.invites[member]?["status"],.string("pending"))
        XCTAssertThrowsError(try PrivateTeams.adding([member],to:result.team,creator:owner,now:Date()))
        XCTAssertThrowsError(try PrivateTeams.adding([member,member],to:team,creator:owner,now:Date()))
        XCTAssertThrowsError(try PrivateTeams.adding([owner],to:team,creator:owner,now:Date()))
        XCTAssertThrowsError(try PrivateTeams.responding(team,member:member,accept:true))
        XCTAssertThrowsError(try PrivateTeam(id:"../bad",creator:owner,data:team))
        XCTAssertThrowsError(try PrivateTeam(id:"one",creator:owner,data:team.setting("nostr",.object(["id":.string("one")]))))
    }
    func testSharedProgressContainsNoPrivateLearnerFields() {
        var state=LearnerState();state.name="Ada";state.notes=[Note(title:"Private secret",body:"A private conversation")];state.journeyRecordings=["es:one":"private-audio.m4a"]
        let shared=LearningTeams.snapshot(state)
        for key in ["notes","history","iosStateJSON","conversationDrafts","privateKey","wallet","memories","recordings"] { XCTAssertEqual(shared[key],.null) }
        XCTAssertEqual(shared["name"],.string("Ada"));XCTAssertEqual(shared["schemaVersion"],.number(2))
        XCTAssertFalse(shared.json.contains("Private secret"));XCTAssertFalse(shared.json.contains("private-audio"))
    }
}
