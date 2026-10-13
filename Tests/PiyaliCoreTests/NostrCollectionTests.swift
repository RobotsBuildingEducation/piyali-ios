import XCTest
@testable import PiyaliCore

final class NostrCollectionTests: XCTestCase {
    func testCollectionMergeAndCompletionMatchReference() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/nostr-collections.json")
        let fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url))
        let content=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Piyali/Resources/achievement-protocol.json.gz")
        let catalog=try ContentLibrary.decode([JSONValue].self,url:content)
        for test in fixture["merging"].array { XCTAssertEqual(NostrAchievementCollection.merging(test["maps"].array),test["expected"],test.json) }
        for test in fixture["completion"].array { XCTAssertEqual(NostrAchievementCollection.completed(test["map"],catalog:catalog),test["expected"],test.json) }
        for test in fixture["events"].array {
            let expected=try JSONDecoder().decode(JSONValue.self,from:Data(test["expected"]["content"].string.utf8))
            XCTAssertEqual(NostrAchievementCollection.body(test["records"],createdAt:1700000000),expected)
        }
    }
    func testCloudAcknowledgmentCannotEraseRestoredSignedRecordsOrLocalSharingChoice() {
        var current=LearnerState();current.shareNostrAchievements=true
        current.nostrAchievementRecords = .object(["legacy-slot":.object(["unlockedAt":.number(10)])])
        let merged=LearnerState.rebased(current:current,sent:current,acknowledged:LearnerState())
        XCTAssertEqual(merged.achievementRecords?["legacy-slot"]?["unlockedAt"].number,10)
        XCTAssertEqual(merged.shareNostrAchievements,true)
    }
}
