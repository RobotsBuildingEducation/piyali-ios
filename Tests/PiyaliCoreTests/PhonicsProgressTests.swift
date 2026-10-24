import XCTest
@testable import PiyaliCore

final class PhonicsProgressTests:XCTestCase {
    @MainActor func testOriginalPronunciationPoliciesAndGeneratedDeckRestore()throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),engine=try CompanionQuestPolicy(source:root.appendingPathComponent("Piyali/Resources/companion-quest-policy.js")),rows=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/phonics-source-policy.json.gz"))
        XCTAssertGreaterThan(rows.count,90)
        for row in rows{XCTAssertEqual(try engine.run(row["operation"].string,row["input"]),row["expected"],row["operation"].string)}
    }
    func testAttemptRewardsAndCompletionActivityHaveSeparateSourceBoundaries()throws {
        let card:JSONValue = .object(["id":.string("public-a"),"practiceWord":.string("casa"),"practiceWordMeaning":.object(["en":.string("house")]),"cefrLevel":.string("Pre-A1")]);var state=LearnerState()
        state.attemptPhonics(card:card,grade:.init(correct:false,xp:0));state.attemptPhonics(card:card,grade:.init(correct:true,xp:2))
        XCTAssertEqual(state.totalXP,2);XCTAssertEqual(state.phonicsRecords?["es:public-a"]?["attempts"].number,2);XCTAssertEqual(state.phonicsRecords?["es:public-a"]?["correctCount"].number,1);XCTAssertEqual(state.plateProgress["phonicsDailyActivity"]["es"][CalendarDay.key(Date())].number,0)
        XCTAssertNotNil(state.collectPhonics(cardID:"public-a"));XCTAssertNil(state.collectPhonics(cardID:"public-a"));XCTAssertEqual(state.totalXP,2);XCTAssertEqual(state.plateProgress["phonicsDailyActivity"]["es"][CalendarDay.key(Date())].number,1)
        state.attemptPhonics(card:card,grade:.init(correct:true,xp:1));XCTAssertEqual(state.totalXP,3);XCTAssertEqual(state.phonicsRecords?["es:public-a"]?["correctCount"].number,2)
        let data=try JSONEncoder().encode(state);XCTAssertEqual(try JSONDecoder().decode(LearnerState.self,from:data).phonicsDocuments.count,1)
    }
    func testSharedTimestampFieldsRetainTheEntireGeneratedDefinition(){
        let value=PhonicsProgress.document(["letterId":"gen_1792830600000000_0","generated":true,"createdAt":Date(timeIntervalSince1970:1000),"foreign":["at":Date(timeIntervalSince1970:2000)]])
        XCTAssertEqual(value["letterId"].string,"gen_1792830600000000_0");XCTAssertEqual(value["generated"],.bool(true));XCTAssertTrue(value["createdAt"].string.hasPrefix("1970-01-01T00:16:40"));XCTAssertTrue(value["foreign"]["at"].string.hasPrefix("1970-01-01T00:33:20"))
    }
    func testPhonicsAttemptsPerformedDuringSyncReplayOverCanonicalCounts(){
        let card:JSONValue = .object(["id":.string("public-a"),"practiceWord":.string("casa")]);var current=LearnerState();current.attemptPhonics(card:card,grade:.init(correct:false,xp:0));let sent=current;var acknowledged=sent;acknowledged.pendingChanges=[]
        current.attemptPhonics(card:card,grade:.init(correct:true,xp:2));let merged=LearnerState.rebased(current:current,sent:sent,acknowledged:acknowledged)
        XCTAssertEqual(merged.phonicsRecords?["es:public-a"]?["attempts"].number,2);XCTAssertEqual(merged.phonicsRecords?["es:public-a"]?["correctCount"].number,1);XCTAssertEqual(merged.totalXP,2);XCTAssertEqual(merged.pendingChanges?.count,1)
    }
    func testNewPronunciationOutcomesRetainLatestAttemptWhileLegacyRecallIsMonotonic(){
        let field="practice_phonics_repair0_authored-v1",card:JSONValue = .object(["id":.string("a")]),old:JSONValue = .object(["success":.bool(true),"iosAttemptID":.string("one"),"iosUpdatedAt":.string("2026-10-24T01:00:00Z")]),new:JSONValue = .object(["success":.bool(false),"iosAttemptID":.string("two"),"iosUpdatedAt":.string("2026-10-24T02:00:00Z")]),artifact:JSONValue = .object(["ownerKey":.string("same"),"cards":.array([card]),"outcomes":.object(["a":old])]),document=JSONValue.object([field:artifact]),patch=JSONValue.object([field:artifact.setting("outcomes",.object(["a":new]))])
        let merged=CompanionQuestDay.merging(patch,into:document);XCTAssertEqual(merged[field]["outcomes"]["a"]["success"],.bool(false));XCTAssertEqual(CompanionQuestDay.merging(document,into:merged)[field]["outcomes"]["a"],new)
    }
    func testFocusedPronunciationDoesNotWriteOrdinaryCollectionOrActivity(){var state=LearnerState();state.attemptPhonics(card:.object(["id":.string("focused-a"),"practiceWord":.string("casa")]),grade:.init(correct:true,xp:2),focused:true);XCTAssertEqual(state.totalXP,2);XCTAssertTrue(state.phonicsDocuments.isEmpty);XCTAssertEqual(state.plateProgress["phonicsDailyActivity"],.null)}
}
