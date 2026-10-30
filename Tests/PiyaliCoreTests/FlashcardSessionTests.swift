import XCTest
@testable import PiyaliCore

final class FlashcardSessionTests:XCTestCase {
    @MainActor func testNativePolicyExecutesOriginalFlashcardPromptsGradesColorsAndScheduling()throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),engine=try CompanionQuestPolicy(source:root.appendingPathComponent("Piyali/Resources/companion-quest-policy.js")),rows=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/flashcard-source-policy.json.gz"))
        XCTAssertEqual(rows.count,117)
        for row in rows {XCTAssertEqual(try engine.run(row["operation"].string,row["input"]),row["expected"],row["operation"].string)}
    }
    func testReviewUsesExplicitSourceRewardIndependentlyOfTheChosenScheduleAndRemainsRebasable(){
        var state=LearnerState();state.review(cardID:"public",rating:.hard,xp:6)
        XCTAssertEqual(state.totalXP,6);XCTAssertEqual(state.cardReviews?["es:public"]?.lastReviewOutcome,.hard);XCTAssertEqual(state.pendingChanges?.last?.amount,6)
        let sent=state;var acknowledged=sent;acknowledged.pendingChanges=[]
        state.review(cardID:"second",rating:.again,xp:5)
        let rebased=LearnerState.rebased(current:state,sent:sent,acknowledged:acknowledged)
        XCTAssertEqual(rebased.totalXP,11);XCTAssertEqual(rebased.pendingChanges?.count,1);XCTAssertEqual(rebased.pendingChanges?.first?.amount,5)
    }
    func testFrozenSourceScheduleRetainsOpenClockWhileXPUsesSaveClock()throws {
        let calendar=Calendar.current,day=calendar.startOfDay(for:Date()),opened=day.addingTimeInterval(86390),saved=day.addingTimeInterval(86410)
        let patch=FlashcardReview().applying(.hard,now:opened)
        var state=LearnerState();state.review(cardID:"midnight",rating:.hard,xp:6,patch:patch,now:saved)
        let change=try XCTUnwrap(state.pendingChanges?.last)
        XCTAssertEqual(change.date,saved);XCTAssertEqual(change.dayKey,CalendarDay.key(saved));XCTAssertEqual(change.activityDayKey,CalendarDay.key(opened))
        XCTAssertEqual(state.cardReviews?["es:midnight"],patch);XCTAssertEqual(state.plateProgress["flashcardDailyActivity"]["es"][CalendarDay.key(opened)].number,1)
        let result=WebProgressContract.rootPatch(fields:[:],month:[:],change:change,now:saved),progress=result.root["progress"] as? [String:Any],activity=progress?["flashcardDailyActivity"] as? [String:[String:Int]]
        XCTAssertEqual(activity?["es"]?[CalendarDay.key(opened)],1);XCTAssertEqual(WebProgressContract.integer((result.month["days"] as? [String:Any])?[CalendarDay.key(saved)]),6)
        let roundTrip=try JSONDecoder().decode(PracticeChange.self,from:JSONEncoder().encode(change));XCTAssertEqual(roundTrip.reviewPatch,patch)
        let sent=LearnerState();var acknowledged=sent
        acknowledged.review(cardID:"midnight",rating:.easy,now:saved);acknowledged.pendingChanges=[]
        let rebased=LearnerState.rebased(current:state,sent:sent,acknowledged:acknowledged)
        XCTAssertEqual(rebased.cardReviews?["es:midnight"],patch,"An unsent source choice must survive an acknowledged record with a later clock.")
    }
    func testSourceProgressDatesUseISOStringsInsteadOfNativeReferenceDateSeconds(){
        var value=FlashcardReview();value.nextReviewAt=Date(timeIntervalSince1970:1000)
        XCTAssertTrue(value.sourceFields["nextReviewAt"].string.hasPrefix("1970-01-01T00:16:40"));XCTAssertEqual(value.sourceFields["completedAt"],.null)
    }
}
