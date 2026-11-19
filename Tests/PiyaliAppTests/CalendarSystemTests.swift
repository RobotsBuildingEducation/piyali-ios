import XCTest
@testable import Piyali

@MainActor final class CalendarSystemTests:XCTestCase {
    func testActualSystemCalendarStillImportsAwardsAndRendersCanonicalHistory()throws{
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"]=="1",let expected=env["PIYALI_EXPECTED_SYSTEM_CALENDAR"],UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Explicit isolated system-calendar run required")}
        XCTAssertEqual(String(describing:Calendar.current.identifier),expected)
        let now=try XCTUnwrap(WebProgressContract.date("2026-10-28T12:00:00Z")),today=CalendarDay.key(now);XCTAssertEqual(today,"2026-10-28");XCTAssertEqual(CalendarDay.year(now),2026)
        var state=WebProgressContract.imported(["xp":100,"progress":["targetLang":"es","languageXp":["es":100],"totalXp":100],"dailyXpRecent":[today:15],"dailyStartedAt":WebProgressContract.iso(now),"dailyXp":15],now:now);XCTAssertEqual(state.dailyXP,15);state.award(5,now:now);XCTAssertEqual(state.dailyXP,20);XCTAssertEqual(state.totalXP,105);XCTAssertEqual(state.pendingChanges?.last?.dayKey,today)
        let history=XPActivityPlan.effective(.object([:]),dailyXP:state.dailyXP,goal:20,now:now),plan=XPActivityPlan(history:history,language:"en",dark:false,now:now);XCTAssertTrue(history["goalDays"].array.contains(.string(today)));XCTAssertEqual(history["days"][today].number,20);XCTAssertTrue(plan.weeks.allSatisfy{$0.id.hasPrefix("plate-week-2026-")});XCTAssertEqual(plan.weeks.flatMap(\.days).first{$0.id==today}?.level,"goal")
        let a=XCTAttachment(string:JSONValue.foundation(["systemCalendar":String(describing:Calendar.current.identifier),"locale":Locale.current.identifier,"canonicalToday":today,"queryYear":CalendarDay.year(now),"dailyXP":state.dailyXP,"totalXP":state.totalXP]).json);a.name="Actual system calendar day contract";a.lifetime = .keepAlways;add(a)
    }
}
