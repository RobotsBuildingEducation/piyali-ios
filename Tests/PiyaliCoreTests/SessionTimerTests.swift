import XCTest
@testable import PiyaliCore

final class SessionTimerTests:XCTestCase {
    func testExecutedWebGoalAndTimerNumericBoundaries()throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/session-tools-source.json")
        let cases=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url));XCTAssertEqual(cases.count,23)
        for c in cases{XCTAssertEqual(SessionToolPolicy.goal(c["input"].string),Int(c["goal"].number),c["input"].string);XCTAssertEqual(SessionToolPolicy.minutes(c["input"].string),Int(c["minutes"].number),c["input"].string)}
    }
    func testDeadlinePauseResumeAndBackgroundExpiration()throws {
        let now=Date(timeIntervalSince1970:1000);var timer=SessionTimer(account:"a");XCTAssertEqual(timer.draft,"20")
        timer.start("1",now:now);XCTAssertEqual(timer.remaining(at:now.addingTimeInterval(10.2)),50)
        timer.toggle(now:now.addingTimeInterval(10.2));XCTAssertEqual(timer.status,.paused);XCTAssertEqual(timer.remaining(at:now.addingTimeInterval(500)),50)
        timer=try JSONDecoder().decode(SessionTimer.self,from:JSONEncoder().encode(timer));XCTAssertEqual(timer.status,.paused)
        timer.toggle(now:now.addingTimeInterval(500));XCTAssertEqual(timer.status,.running);XCTAssertFalse(timer.refresh(now:now.addingTimeInterval(549)))
        XCTAssertTrue(timer.refresh(now:now.addingTimeInterval(551)));XCTAssertEqual(timer.status,.finished);XCTAssertFalse(timer.refresh(now:now.addingTimeInterval(600)));XCTAssertTrue(timer.hasTimer)
        timer.clear();XCTAssertFalse(timer.hasTimer);XCTAssertNil(timer.id);XCTAssertEqual(timer.draft,"1")
    }
    func testClockDragUsesShortestDeltaAndFiveMinuteStepsAcrossMultipleTurns() {
        XCTAssertEqual(SessionToolPolicy.angle(x:0,y:-1),0);XCTAssertEqual(SessionToolPolicy.angle(x:1,y:0),90)
        XCTAssertEqual(SessionToolPolicy.drag(minutes:120,from:359,to:2),121)
        XCTAssertEqual(SessionToolPolicy.drag(minutes:120,from:2,to:359),119)
        XCTAssertEqual(SessionToolPolicy.drag(minutes:239,from:0,to:90),240)
        XCTAssertEqual(SessionToolPolicy.drag(minutes:1,from:90,to:0),0)
        XCTAssertEqual(SessionToolPolicy.snapped(12.5),15);XCTAssertEqual(SessionToolPolicy.snapped(12.49),10)
    }
    func testGoalImportRetainsSmallWebTargetsAndEditingDoesNotEraseEarnedProgress() {
        XCTAssertEqual(LearnerState().dailyGoal,100)
        XCTAssertEqual(LearnerState().companionName,"")
        for goal in [1,5,100,1000]{XCTAssertEqual(WebProgressContract.imported(["dailyGoalXp":goal]).dailyGoal,goal)}
        XCTAssertEqual(WebProgressContract.imported(["progress":["dailyGoalXp":5]]).dailyGoal,5)
        XCTAssertEqual(WebProgressContract.imported(["dailyGoalXp":NSNull(),"stats":["dailyGoalXp":150]]).dailyGoal,150)
        XCTAssertEqual(WebProgressContract.imported(["dailyGoalXp":" 5 "]).dailyGoal,5)
        XCTAssertEqual(WebProgressContract.imported(["dailyGoalXp":0,"progress":["dailyGoalXp":150]]).dailyGoal,100)
        var state=LearnerState();state.dailyXP=125;state.streak=3;state.dailyKey=CalendarDay.key(Date());let health=state.companionHealth
        state.dailyGoal=SessionToolPolicy.goal("200")
        XCTAssertEqual(state.dailyXP,125);XCTAssertEqual(state.streak,3);XCTAssertEqual(state.companionHealth,health)
    }
}
