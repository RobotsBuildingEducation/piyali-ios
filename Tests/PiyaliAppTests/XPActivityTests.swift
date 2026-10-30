import XCTest
@testable import Piyali

@MainActor final class XPActivityTests:XCTestCase {
    private func date(_ value:String)->Date{ISO8601DateFormatter().date(from:value)!}
    func testAllOriginalWeekKeysPaddingLabelsTooltipsAndStyles()throws{
        let url=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"xp-activity",withExtension:"json.gz")),cases=try ContentLibrary.decode([JSONValue].self,url:url);XCTAssertEqual(cases.count,80)
        var calendar=Calendar(identifier:.gregorian);calendar.timeZone=try XCTUnwrap(TimeZone(identifier:"America/Mexico_City"))
        for row in cases{let input=row["input"],now=date(input["now"].string+"-06:00"),history:JSONValue = .object(["days":input["days"],"goalDays":input["goalDays"]]),plan=XPActivityPlan(history:history,language:input["language"].string,dark:!input["light"].boolean,now:now,calendar:calendar)
            let actual:JSONValue = .array(plan.weeks.map{week in .object(["key":.string(week.id),"monthLabel":.string(week.month),"days":.array(week.days.map{day in day.blank ? .object(["key":.string(day.id),"isBlank":.bool(true)]):.object(["key":.string(day.id),"isBlank":.bool(false),"title":.string(day.title),"style":day.style])})])});XCTAssertEqual(actual,row["weeks"],input.json)
        }
    }
    func testSavedGoalsRemainIndependentOfTodaysTargetAndLiveTodayUsesMaximum()throws{
        let now=date("2026-10-15T12:00:00-06:00"),history:JSONValue = .object(["days":.object(["2026-01-01":.number(300),"2026-01-02":.number(250),"2026-10-15":.number(200)]),"goalDays":.array([.string("2026-01-01"),.string("2026-01-03")])]);var c=Calendar(identifier:.gregorian);c.timeZone=TimeZone(identifier:"America/Mexico_City")!
        let effective=XPActivityPlan.effective(history,dailyXP:100,goal:100,now:now,calendar:c),days=XPActivityPlan(history:effective,language:"en",dark:false,now:now,calendar:c).weeks.flatMap(\.days)
        XCTAssertEqual(days.first{$0.id=="2026-01-01"}?.level,"goal");XCTAssertEqual(days.first{$0.id=="2026-01-02"}?.level,"some");XCTAssertEqual(days.first{$0.id=="2026-01-03"}?.level,"goal");XCTAssertEqual(effective["days"]["2026-10-15"].number,200);XCTAssertTrue(effective["goalDays"].array.contains(.string("2026-10-15")))
        XCTAssertFalse(XPActivityPlan.effective(.object([:]),dailyXP:0,goal:0,now:now,calendar:c)["goalDays"].array.contains(.string("2026-10-15")))
    }
    func testLegacyImportAndOfflineAwardsSurviveRolloverAndOldProfileDecoding()throws{
        let now=date("2026-10-15T12:00:00-06:00");var c=Calendar(identifier:.gregorian);c.timeZone=TimeZone(identifier:"America/Mexico_City")!;var state=WebProgressContract.imported(["dailyXpHistory":["2026-01-01":50],"completedGoalDates":["2026-01-01"]],now:now);state.dailyGoal=5;state.award(5,now:now,calendar:c);XCTAssertEqual(state.activityLegacy["days"]["2026-01-01"].number,50);XCTAssertTrue(state.activityLegacy["goalDays"].array.contains(.string("2026-01-01")));state.rollDay(now:now.addingTimeInterval(86400),calendar:c);XCTAssertEqual(state.dailyXP,0);XCTAssertEqual(state.activityLegacy["days"]["2026-10-15"].number,5);XCTAssertTrue(state.activityLegacy["goalDays"].array.contains(.string("2026-10-15")));let saved=try JSONEncoder().encode(state),restored=try JSONDecoder().decode(LearnerState.self,from:saved);XCTAssertEqual(restored.xpActivity,state.xpActivity);var old=try JSONSerialization.jsonObject(with:saved)as! [String:Any];old.removeValue(forKey:"xpActivity");XCTAssertNil(try JSONDecoder().decode(LearnerState.self,from:JSONSerialization.data(withJSONObject:old)).xpActivity)
    }
    func testScopedMonthlyMergeCacheFailureAndLateAccountResponse()async throws{
        let suite="piyali.activity.tests."+UUID().uuidString,defaults=try XCTUnwrap(UserDefaults(suiteName:suite));defer{defaults.removePersistentDomain(forName:suite)};let controller=XPActivityController(defaults:defaults),legacy:JSONValue = .object(["days":.object(["2026-01-01":.number(20),"2026-01-02":.number(5)]),"goalDays":.array([.string("2026-01-02")])]),remote:JSONValue = .object(["days":.object(["2026-01-01":.number(30)]),"goalDays":.array([.string("2026-01-01")])])
        await controller.load(account:"first",year:2026,legacy:legacy){_,_ in remote};XCTAssertEqual(controller.history["days"]["2026-01-01"].number,30);XCTAssertEqual(controller.history["days"]["2026-01-02"].number,5);XCTAssertEqual(controller.history["goalDays"].array.count,2)
        let restored=XPActivityController(defaults:defaults);await restored.load(account:"first",year:2026,legacy:legacy){_,_ in throw URLError(.notConnectedToInternet)};XCTAssertEqual(restored.history,controller.history)
        var resolve:CheckedContinuation<JSONValue,Never>?;let old=Task{await controller.load(account:"first",year:2026,legacy:legacy){_,_ in await withCheckedContinuation{resolve=$0}}};for _ in 0..<100 where resolve == nil{try await Task.sleep(for:.milliseconds(2))};XCTAssertNotNil(resolve);await controller.load(account:"other",year:2026,legacy:.object([:])){_,_ in .object([:])};resolve?.resume(returning:remote);await old.value;XCTAssertTrue(controller.history["days"].object.isEmpty)
    }
}
