import XCTest
@testable import PiyaliCore

final class SyncContractTests: XCTestCase {
    private let now = Date(timeIntervalSince1970:1_792_080_000)
    func testPreferenceEditsDuringSyncSurviveAcknowledgment() {
        var sent = LearnerState(); sent.preferencesModifiedAt = now
        var current = sent; current.target = "fr"; current.name = "New name"
        current.preferencesModifiedAt = now.addingTimeInterval(1)
        var cloud = sent; cloud.name = "Old cloud name"; cloud.target = "de"
        let merged = LearnerState.rebased(current:current,sent:sent,acknowledged:cloud)
        XCTAssertEqual(merged.name,"New name"); XCTAssertEqual(merged.target,"fr")
        XCTAssertEqual(merged.preferencesModifiedAt,current.preferencesModifiedAt)
    }
    func testRevealReviewDoesNotAwardXPOrPrematureMastery() {
        var state = LearnerState(); state.review(cardID:"a1-greet-1",rating:.again,now:now)
        XCTAssertEqual(state.xp,0); XCTAssertFalse(state.flashcardMastery.contains("es:a1-greet-1"))
        XCTAssertEqual(state.cardReviews?["es:a1-greet-1"]?.nextReviewAt,now.addingTimeInterval(60))
        XCTAssertEqual(state.pendingChanges?.count,1); XCTAssertEqual(state.pendingChanges?.first?.amount,0)
    }
    func testInvalidWebNumericDataUsesDefaultsWithoutTrapping() {
        XCTAssertEqual(WebProgressContract.number(Double.nan,default:2.5),2.5)
        XCTAssertEqual(WebProgressContract.integer(Double.infinity,default:5),5)
        XCTAssertGreaterThan(WebProgressContract.integer(1e100),0)
    }
    func testSchedulesMatchReferenceFixtures() throws {
        let path = URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/review-schedules.json")
        let fixtures = try XCTUnwrap(JSONSerialization.jsonObject(with:Data(contentsOf:path)) as? [[String:Any]])
        XCTAssertEqual(fixtures.count,116)
        for fixture in fixtures {
            let progress = fixture["progress"] as! [String:Any], rating = ReviewRating(rawValue:fixture["rating"] as! String)!
            let result = WebProgressContract.reviewFields(WebProgressContract.review(progress).applying(rating,now:WebProgressContract.date(fixture["now"])!))
            let expected = fixture["expected"] as! [String:Any]
            for (key,value) in expected {
                let actual = try JSONDecoder().decode(JSONValue.self,from:JSONSerialization.data(withJSONObject:[result[key]!]))
                let wanted = try JSONDecoder().decode(JSONValue.self,from:JSONSerialization.data(withJSONObject:[value]))
                XCTAssertEqual(actual,wanted,"\(fixture["name"]!) \(key)")
            }
        }
    }
    func testOfflineAwardsKeepTheirCalendarDay() {
        let today = CalendarDay.key(now), yesterday = CalendarDay.shift(today,by:-1)
        let fields: [String:Any] = ["xp":100,"dailyXp":5,"dailyResetAt":WebProgressContract.iso(now.addingTimeInterval(3600)),"dailyXpRecent":[today:5],"progress":["languageXp":["es":100],"totalXp":100],"subscriptionSentinel":"keep"]
        let change = PracticeChange(date:now.addingTimeInterval(-86400),dayKey:yesterday,target:"es",level:"A1",amount:10,source:.practice)
        let result = WebProgressContract.rootPatch(fields:fields,month:[:],change:change,now:now)
        XCTAssertNil(result.root["dailyXp"])
        XCTAssertEqual((result.month["days"] as? [String:Int])?[yesterday],10)
        XCTAssertEqual((result.root["dailyXpRecent"] as? [String:Int])?[today],5)
        XCTAssertNil(result.root["subscriptionSentinel"])
        XCTAssertEqual(result.root["xp"] as? Int,110)
    }
    func testRebaseKeepsNewPracticeAndAcknowledgesOnlySentEvents() {
        var sent = LearnerState(); sent.award(10,now:now)
        var current = sent; current.award(5,now:now)
        var cloud = sent; cloud.pendingChanges = []; cloud.xpByLanguage["es"] = 110
        let merged = LearnerState.rebased(current:current,sent:sent,acknowledged:cloud)
        XCTAssertEqual(merged.xp,115); XCTAssertEqual(merged.pendingChanges?.count,1)
        XCTAssertEqual(merged.pendingChanges?.first?.amount,5)
    }
    func testLegacyDayKeyNormalizesWithoutResettingTodaysXP() {
        let date = WebProgressContract.date("2026-02-03T12:00:00.000Z")!
        var calendar = Calendar(identifier:.gregorian); calendar.timeZone = TimeZone(secondsFromGMT:0)!
        var state = LearnerState(); state.dailyKey = "2026-2-3"; state.dailyXP = 17
        state.rollDay(now:date,calendar:calendar)
        XCTAssertEqual(state.dailyKey,"2026-02-03"); XCTAssertEqual(state.dailyXP,17)
    }
    func testWebAccountImportUsesLanguageXPAndRetainsUnknownWebState() {
        let today = CalendarDay.key(now)
        let fields: [String:Any] = ["displayName":"Web learner","language":"es","dailyGoalXp":30,"onboarding":["completed":true],"progress":["targetLang":"fr","supportLang":"es","cefrLevel":"B1","languageXp":["fr":70,"es":90],"totalXp":160],"dailyXpRecent":[today:12],"learningIntelligence":["fr":["elo":["rating":1000.0,"scaleVersion":4]]]]
        let state = WebProgressContract.imported(fields,now:now)
        XCTAssertEqual(state.target,"fr"); XCTAssertEqual(state.xp,70); XCTAssertEqual(state.totalXP,160)
        XCTAssertTrue(state.onboardingComplete); XCTAssertEqual(state.rating,1000); XCTAssertEqual(state.dailyXP,12)
    }
}
