import XCTest
@testable import PiyaliCore

final class CompanionHealthTests: XCTestCase {
    func testReferenceResetAndDecayAcrossTimezonesAndDST() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/companion-health.json")
        let fixtures=try XCTUnwrap(JSONSerialization.jsonObject(with:Data(contentsOf:url)) as? [[String:Any]])
        XCTAssertEqual(fixtures.count,150)
        for fixture in fixtures {
            let fields=fixture["data"] as! [String:Any], now=WebProgressContract.date(fixture["now"])!
            var calendar=Calendar(identifier:.gregorian);calendar.timeZone=TimeZone(identifier:fixture["timezone"] as! String)!
            XCTAssertEqual(CompanionHealth.missed(fields,now:now,calendar:calendar),fixture["missed"] as? Int,fixture["name"] as! String)
            let actual=CompanionHealth.resetFields(fields,now:now,resetWindow:fixture["resetWindow"] as! Bool,calendar:calendar)
            XCTAssertEqual(JSONValue.foundation(actual),JSONValue.foundation(fixture["expected"]!),fixture["name"] as! String)
        }
    }
    func testRecoveryRequiresGoalAndOnlyOncePerWindow() {
        let now=Date(),today=CalendarDay.key(now)
        let fields:[String:Any]=["dailyGoalXp":50,"dailyXp":40,"dailyResetAt":WebProgressContract.iso(now.addingTimeInterval(3600)),"dailyGoalPetHealth":90,"dailyGoalPetTrackedDay":today,"dailyGoalPetStartedFull":false,"dailyGoalPetLastAccountedDay":CalendarDay.shift(today,by:-1)]
        let first=fields.merging(CompanionHealth.awardFields(fields,amount:10,now:now)){_,new in new}
        XCTAssertEqual(CompanionHealth.health(first),100);XCTAssertEqual(first["dailyGoalPetReachedDates"] as? [String],[today]);XCTAssertEqual(first["dailyGoalPetStartedFull"] as? Bool,false)
        let next=first.merging(CompanionHealth.awardFields(first,amount:50,now:now)){_,new in new}
        XCTAssertEqual(CompanionHealth.health(next),100);XCTAssertEqual(next["dailyGoalPetReachedDates"] as? [String],[today])
        let tomorrow=CompanionHealth.resetFields(next,now:now.addingTimeInterval(86400),resetWindow:false)
        XCTAssertEqual(tomorrow["dailyGoalPetHealthyDates"] as? [String],[])
        XCTAssertEqual(tomorrow["dailyGoalPetStartedFull"] as? Bool,true)
    }
    func testHealthOnlyReconciliationPreservesXPAndIsIdempotent() {
        let now=Date(),today=CalendarDay.key(now)
        let fields:[String:Any]=["dailyGoalXp":50,"dailyXp":30,"dailyResetAt":WebProgressContract.iso(now.addingTimeInterval(3600)),"dailyGoalPetHealth":100,"dailyGoalPetLastAccountedDay":CalendarDay.shift(today,by:-4)]
        let patch=CompanionHealth.reconcileFields(fields,now:now)
        XCTAssertEqual(patch["dailyGoalPetHealth"] as? Int,70);XCTAssertNil(patch["dailyXp"]);XCTAssertNil(patch["dailyResetAt"])
        let updated=fields.merging(patch){_,new in new}
        XCTAssertTrue(CompanionHealth.reconcileFields(updated,now:now).isEmpty)
    }
    func testOfflineRecoveryPersistsAndRebasesNewWorkWithoutDoubleCredit() throws {
        let now=Date(),today=CalendarDay.key(now)
        var sent=LearnerState();sent.dailyGoal=50
        sent.companionProgress=JSONValue.foundation(["dailyXp":0,"dailyResetAt":WebProgressContract.iso(now.addingTimeInterval(3600)),"dailyGoalPetHealth":50,"dailyGoalPetLastAccountedDay":CalendarDay.shift(today,by:-1)])
        sent.award(40,now:now)
        var current=sent;current.award(10,now:now);XCTAssertEqual(current.companionHealth,65)
        var cloud=sent;cloud.pendingChanges=[]
        let merged=LearnerState.rebased(current:current,sent:sent,acknowledged:cloud)
        XCTAssertEqual(merged.companionHealth,65);XCTAssertEqual(merged.pendingChanges?.count,1)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(merged))
        XCTAssertEqual(restored.companionHealth,65)
    }
    func testImportUsesCanonicalHealthAndNeverRetroactivelyAwardsHealthyDays() {
        let now=Date(),today=CalendarDay.key(now)
        var native=LearnerState();native.companionProgress=JSONValue.foundation(["dailyGoalPetHealth":100])
        let fields:[String:Any]=["dailyGoalXp":50,"dailyGoalPetHealth":80,"dailyGoalPetLastAccountedDay":CalendarDay.shift(today,by:-1)]
        let state=WebProgressContract.imported(fields,native:native,now:now)
        XCTAssertEqual(state.companionHealth,80);XCTAssertEqual(state.companionStatus,"Healthy")
        XCTAssertTrue(state.companionProgress?["dailyGoalPetHealthyDates"].array.isEmpty ?? true)
        XCTAssertEqual(CompanionHealth.health(["dailyGoalPetHealth":Double.nan]),100)
    }
}
