import XCTest
@testable import PiyaliCore

final class DailyPlateTests: XCTestCase {
    func fixture() throws -> JSONValue {
        let url = URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/daily-plate.json")
        return try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url))
    }
    func testReferenceElectionSnapshotsAndNeglectWeights() throws {
        let data = try fixture()
        for test in data["elections"].array {
            let i = test["input"]
            let actual = DailyPlate.elect(available:i["available"].array.map(\.string),count:i["count"] == .null ? nil : i.object["count"].map { Int($0.number) },avoid:i["avoid"].array.map(\.string),seed:i["seed"].string,weights:i["weights"].object.mapValues(\.number),score:i["score"] == .null ? nil : Int(i["score"].number))
            XCTAssertEqual(actual,test["expected"].array.map(\.string),i.json)
        }
        for test in data["snapshots"].array {
            let user = test["user"], progress = user["progress"], day = test["day"].string
            let first = DailyPlate.firstSession(progress:progress,day:day,priorLearning:true)
            let actual = DailyPlate.courses(progress:progress,bucket:.object([:]),user:user["local_npub"].string,target:test["lang"].string,day:day,kinds:test["kinds"].array.map(\.string),first:first)
            XCTAssertEqual(actual.map(\.kind),test["expected"]["courses"].array.map { $0["kind"].string })
            XCTAssertEqual(actual.map(\.count),test["expected"]["courses"].array.map { Int($0["count"].number) })
            XCTAssertEqual(actual.map(\.target),test["expected"]["courses"].array.map { Int($0["target"].number) })
        }
        let w = data["weights"]
        XCTAssertEqual(DailyPlate.weights(progress:w["progress"],target:w["lang"].string,day:w["day"].string,kinds:w["kinds"].array.map(\.string)),w["expected"].object.mapValues(\.number))
    }
    func testIntroAndLanguagePlansPersistWithoutReroll() throws {
        let day = Date(timeIntervalSince1970:1791892800)
        var state = LearnerState(); state.preparePlate(user:"learner",available:DailyPlate.introductory,now:day)
        XCTAssertEqual(state.questPlans?["es"]?.kinds,DailyPlate.introductory)
        state.award(10,now:day); state.preparePlate(user:"learner",available:["phonics"],now:day)
        XCTAssertEqual(state.questPlans?["es"]?.kinds,DailyPlate.introductory)
        let next = day.addingTimeInterval(86400)
        state.preparePlate(user:"learner",available:["review","learn","phonics","conversation"],now:next)
        let selected = state.questPlans?["es"]
        state.preparePlate(user:"learner",available:["speak"],now:next)
        XCTAssertEqual(state.questPlans?["es"],selected)
        state.target = "fr"; state.preparePlate(user:"learner",available:["speak","review","conversation"],now:next)
        XCTAssertEqual(state.questPlans?["es"],selected)
        let restored = try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state))
        XCTAssertEqual(restored.questPlans,state.questPlans)
    }
    func testReturningFlagOnlyAccountDoesNotRestartIntroAndUnfinishedTasksCarryOver() {
        let now = Date(), yesterday = CalendarDay.shift(CalendarDay.key(now),by:-1)
        var state = LearnerState(); state.xpByLanguage = ["es":10]
        state.questProgress = .object(["dailyQuestFirstSeen":.bool(true),"dailyQuestFirstDayKey":.string("2026-01-01")])
        state.questPlans = ["es":DailyQuestPlan(day:yesterday,kinds:["speak","learn","review"])]
        state.editGoal("Order a meal")
        state.preparePlate(user:"learner",available:["review","conversation","phonics"],now:now)
        XCTAssertEqual(state.questPlans?["es"]?.carry,["speak","learn"])
        XCTAssertEqual(Array(state.plateCourses(user:"learner").map(\.kind).prefix(3)),["goal","speak","learn"])
        XCTAssertEqual(state.plateProgress["dailyQuestFirstDayKey"].string,"2026-01-01")
        var legacy = LearnerState(); legacy.xpByLanguage = ["es":10]
        legacy.questProgress = .object(["dailyQuestFirstSeen":.bool(true)])
        legacy.preparePlate(user:"legacy",available:["phonics"],now:now)
        XCTAssertTrue(legacy.plateProgress["dailyQuestFirstDayKey"].string.isEmpty)
        XCTAssertFalse(legacy.introductoryQuest(day:CalendarDay.key(now)))
    }
    func testCompletionRequiresAllCoursesAndClaimsBonusOnce() {
        let now = Date(), day = CalendarDay.key(now)
        var state = LearnerState(); state.preparePlate(user:"learner",available:DailyPlate.introductory,now:now)
        XCTAssertFalse(state.claimPlate(user:"learner",now:now))
        state.award(20,source:.lesson,contentID:"one",now:now)
        state.award(60,source:.speak,contentID:"tutor-one",now:now)
        for index in 0..<5 { state.review(cardID:"card-\(index)",rating:.good,now:now) }
        let xp = state.xp
        XCTAssertTrue(state.claimPlate(user:"learner",now:now)); XCTAssertEqual(state.xp,xp + 25)
        XCTAssertFalse(state.claimPlate(user:"learner",now:now)); XCTAssertEqual(state.xp,xp + 25)
        XCTAssertFalse(state.plateProgress["plateBonusDailyActivity"]["es"][day].string.isEmpty)
        state.target = "fr"; XCTAssertFalse(state.claimPlate(user:"learner",now:now))
    }
    func testBonusMarkersFollowWebTruthinessAcrossSupportedSavedForms() {
        for marker in [JSONValue.bool(true),.string("2026-10-13T12:00:00Z"),.number(1),.object([:])] {
            let progress: JSONValue = .object(["plateBonusDailyActivity":.object(["es":.object(["2026-10-13":marker])])])
            XCTAssertTrue(DailyPlate.bonusAwarded(progress:progress,target:"es",day:"2026-10-13"))
            XCTAssertFalse(DailyPlate.bonusAwarded(progress:progress,target:"fr",day:"2026-10-13"))
        }
        XCTAssertFalse(DailyPlate.bonusAwarded(progress:.object([:]),target:"es",day:"2026-10-13"))
    }
    func testConcurrentSyncPreservesNewActivitiesWithoutDoubleCounting() {
        let now = Date(), day = CalendarDay.key(now)
        var sent = LearnerState(); sent.preparePlate(user:"learner",available:DailyPlate.introductory,now:now)
        var current = sent; current.review(cardID:"card",rating:.good,now:now)
        var cloud = sent; cloud.pendingChanges = []
        cloud.questProgress = DailyPlate.recorded(PracticeChange(dayKey:day,target:"es",level:"Pre-A1",amount:0,source:.conversation),progress:cloud.plateProgress)
        let result = LearnerState.rebased(current:current,sent:sent,acknowledged:cloud)
        XCTAssertEqual(result.plateProgress["flashcardDailyActivity"]["es"][day].number,1)
        XCTAssertEqual(result.plateProgress["conversationDailyActivity"]["es"][day].number,1)
    }
}
