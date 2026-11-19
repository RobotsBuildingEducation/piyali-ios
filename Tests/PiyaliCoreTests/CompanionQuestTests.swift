import XCTest
@testable import PiyaliCore

final class CompanionQuestTests:XCTestCase {
    private var root:URL {URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()}
    @MainActor func testOriginalCompanionPolicyFixturesInJavaScriptCore()throws {
        let cases=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/companion-quest-policy.json.gz")),policy=try CompanionQuestPolicy(source:root.appendingPathComponent("Piyali/Resources/companion-quest-policy.js"))
        XCTAssertEqual(cases.count,198)
        for row in cases {XCTAssertEqual(try policy.run(row["operation"].string,row["input"]),row["expected"],row["operation"].string)}
    }
    func testRepairPlanSurvivesReinforcementAndKeepsStableThreeStepCounter()throws {
        let day=CalendarDay.key(Date()),previous=CalendarDay.shift(day,by:-1)
        var state=LearnerState();state.questProgress = .object(["dailyQuestFirstSeen":.bool(true),"dailyQuestFirstDayKey":.string(previous)])
        state.questPlans=["es":DailyQuestPlan(day:day,kinds:["learn","review"])];state.xpByLanguage=["es":50]
        let notes=(0..<3).map{i in MemoryNote(fields:["id":.string("n\(i)"),"concept":.string("Concept \(i)"),"createdDayKey":.string(previous),"status":.string("captured")])}
        state.companionMemory=["es":notes]
        let bp:JSONValue = .object(["status":.string("ready"),"repair":.object(["items":.array(notes.map{.object(["memoryId":.string($0.id),"concept":.string($0.text("concept"))])}),"memoryIds":.array(notes.map{.string($0.id)})]),"rationale":.object(["summary":.string("A small repair")])])
        state.storeCompanionBlueprint(bp,target:"es",day:day)
        XCTAssertEqual(state.plateCourses(user:"fixture").first?.target,3)
        for note in notes {state.reinforceMemory(id:note.id)}
        XCTAssertTrue(state.activeMemories.isEmpty)
        XCTAssertEqual(state.plateCourses(user:"fixture").first?.kind,"repair");XCTAssertEqual(state.plateCourses(user:"fixture").first?.target,3)
        XCTAssertEqual(state.totalXP,50);XCTAssertNil(state.pendingChanges)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state));XCTAssertEqual(restored.repairPlan(day:day),state.repairPlan(day:day));XCTAssertEqual(restored.pendingCompanionQuestDays,state.pendingCompanionQuestDays)
    }
    func testAtomicReservationAndLateGenerationDoNotReplaceReadyOrNewLease() {
        let now=Date(),day="2026-10-23",empty:JSONValue = .object(["iosPlate":.object(["kinds":.array([.string("learn")])]),"foreignField":.string("retained")])
        let first=CompanionQuestDay.reserve(empty,id:"one",target:"es",day:day,now:now)!
        let reserved=empty.setting("blueprint",first)
        XCTAssertNil(CompanionQuestDay.reserve(reserved,id:"two",target:"es",day:day,now:now.addingTimeInterval(599)))
        XCTAssertNotNil(CompanionQuestDay.reserve(reserved,id:"two",target:"es",day:day,now:now.addingTimeInterval(601)))
        let ready:JSONValue = .object(["status":.string("ready"),"iosGenerationID":.string("one"),"message":.object(["long":.string("Original")]),"repair":.object(["items":.array([.object(["concept":.string("Hola")])])]),"rationale":.object(["summary":.string("Why")])])
        let committed=CompanionQuestDay.merging(.object(["blueprint":ready]),into:reserved)
        XCTAssertEqual(committed["blueprint"],ready);XCTAssertEqual(committed["repair"],ready["repair"]);XCTAssertEqual(committed["explanation"],ready["rationale"]);XCTAssertEqual(committed["iosPlate"],empty["iosPlate"])
        XCTAssertEqual(CompanionQuestDay.merging(.object(["blueprint":ready.setting("message",.string("Late"))]),into:committed),committed)
        let newer=reserved.setting("blueprint",first.setting("iosGenerationID",.string("two")))
        XCTAssertEqual(CompanionQuestDay.merging(.object(["blueprint":ready]),into:newer),newer)
    }
    func testCorruptAndFractionalRepairCountsUseTheDisplayedCounterWithoutTrapping() {
        let day=CalendarDay.key(Date()),items=(0..<3).map{JSONValue.object(["memoryId":.string("m\($0)"),"concept":.string("c\($0)")])}
        let plan:JSONValue = .object(["targetLang":.string("es"),"dayKey":.string(day),"items":.array(items)])
        var state=LearnerState();state.importQuestDay(.object(["repair":plan]),target:"es",day:day)
        let step=RepairStep(index:2,mode:"lesson",item:items[2],plan:plan,stepCount:3)
        state.questProgress = .object(["repairDailyActivity":.object(["es":.object([day:.number(1.8)])])]);XCTAssertTrue(state.repairStepIsCurrent(step))
        state.questProgress = .object(["repairDailyActivity":.object(["es":.object([day:.number(1e200)])])]);XCTAssertFalse(state.repairStepIsCurrent(step))
    }
    func testSyncPreservesInFlightLanguageAndExplanationOutbox() {
        let day="2026-10-23";var sent=LearnerState();sent.storeQuestExplanation(.string("First"),target:"es",day:day)
        var current=sent;current.storeQuestExplanation(.string("Autre"),target:"fr",day:day)
        var acknowledged=LearnerState();acknowledged.importQuestDay(.object(["explanation":.string("First"),"otherClient":.bool(true)]),target:"es",day:day)
        let merged=LearnerState.rebased(current:current,sent:sent,acknowledged:acknowledged)
        XCTAssertNil(merged.pendingCompanionQuestDays?["es_"+day]);XCTAssertNotNil(merged.pendingCompanionQuestDays?["fr_"+day]);XCTAssertEqual(merged.questDay(target:"fr",day:day)["explanation"],.string("Autre"));XCTAssertEqual(merged.questDay(target:"es",day:day)["otherClient"],.bool(true))
        XCTAssertEqual(merged.companionQuestUser["dailyQuestExplanations"]["fr"][day],.string("Autre"));XCTAssertEqual(merged.companionQuestUser["questDaysLoaded"]["es_"+day],.bool(true))
    }
}
