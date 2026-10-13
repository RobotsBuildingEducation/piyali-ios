import XCTest
@testable import PiyaliCore

final class ImmersionTests: XCTestCase {
    private func fixture() throws -> JSONValue {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/immersion.json")
        return try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url))
    }
    private var date: Date { WebProgressContract.date("2026-09-24T12:00:00.000Z")! }
    private func learner() -> LearnerState {
        var state=LearnerState();state.target="de";state.support="en";state.dailyKey=CalendarDay.key(date)
        state.place(Placement(level:"A2",score:32,source:"test",selectedIDs:[],updatedAt:date))
        return state
    }
    private func tasks(_ count: Int = 3, suffix: String = "") -> JSONValue { .array((0..<count).map { .object(["title":.string("Task \($0)\(suffix)"),"description":.string("Practice privately at home \($0)\(suffix).")]) }) }
    private func propose(_ state: inout LearnerState, at: Date? = nil) {
        let now=at ?? date
        state.applyImmersion(.init(date:now,target:state.target,action:.batch,payload:state.immersionScope(now:now).setting("tasks",tasks())))
    }
    func testStatesQualityAndHistoryMatchActualWebFunctions() throws {
        let data=try fixture()
        for sample in data["states"].array {
            let c=sample["context"]
            XCTAssertEqual(DailyImmersion.state(sample["batch"],day:c["dayKey"].string,target:c["targetLang"].string,support:c["appLanguage"].string,goal:c["goal"],placementAt:c["placementAt"].string),sample["expected"])
        }
        for sample in data["normalize"].array {
            let actual=DailyImmersion.normalize(sample["raw"],count:Int(sample["count"].number),recent:sample["recent"].array)
            XCTAssertEqual(actual.map(JSONValue.array) ?? .null,sample["expected"])
        }
        for sample in data["history"].array { XCTAssertEqual(.array(DailyImmersion.history(sample["old"].array,adding:sample["adding"].array)),sample["expected"]) }
    }
    func testChecklistGives15XPOnceAndKeepsRewardAfterUndoOrGoalEdit() {
        var state=learner();propose(&state)
        state.toggleImmersion(index:0,now:date);state.toggleImmersion(index:1,now:date)
        XCTAssertEqual(state.totalXP,0)
        state.toggleImmersion(index:2,now:date)
        XCTAssertEqual(state.totalXP,15);XCTAssertTrue(state.immersionBatch?["rewarded"].boolean == true)
        state.toggleImmersion(index:2,now:date.addingTimeInterval(1));state.toggleImmersion(index:2,now:date.addingTimeInterval(2));XCTAssertEqual(state.totalXP,15)
        state.editGoal("Read a recipe",now:date.addingTimeInterval(3))
        let payload=state.immersionScope(now:date).setting("tasks",tasks(1,suffix:" new goal"))
        state.applyImmersion(.init(date:date.addingTimeInterval(4),target:state.target,action:.batch,payload:payload))
        XCTAssertEqual(state.immersionBatch?["tasks"].array.count,4);XCTAssertTrue(DailyImmersion.completed(state.immersionBatch!,index:0));XCTAssertFalse(DailyImmersion.completed(state.immersionBatch!,index:3))
        state.toggleImmersion(index:3,now:date.addingTimeInterval(5));XCTAssertEqual(state.totalXP,15)
    }
    func testNextLessonAndConciseContextMatchReference() throws {
        let fixture=try fixture(),lessons=["one","two","three","four"].map { Lesson(id:$0,title:.string($0),description:.null,xpReward:20,modes:[],agenda:.null,content:.null) }
        for sample in fixture["candidates"].array {
            let skill=DailyImmersion.candidate(lessons:lessons,progress:.null,completedCount:Int(sample["skillCount"].number),level:sample["skillLevel"].string,mode:"Lessons",priority:sample["priority"].string.isEmpty ? nil : sample["priority"].string)
            let tutor=DailyImmersion.candidate(lessons:lessons,progress:sample["progress"],completedCount:Int(sample["tutorCount"].number),level:sample["tutorLevel"].string,mode:"Tutor")
            let winner=try XCTUnwrap(DailyImmersion.leading(skill,tutor))
            XCTAssertEqual(winner.lesson.id,sample["expected"]["id"].string);XCTAssertEqual(winner.index,Int(sample["expected"]["index"].number));XCTAssertEqual(winner.mode,sample["expected"]["mode"].string)
        }
        let input=fixture["context"]["lesson"]
        var lesson=Lesson(id:input["id"].string,title:input["title"],description:input["description"],xpReward:20,modes:[],agenda:.null,content:input["content"]);lesson.objectives=input["objectives"]
        let candidate=DailyImmersion.candidate(lessons:[lesson],progress:.null,completedCount:0,level:"B1",mode:"Tutor")
        XCTAssertEqual(DailyImmersion.context(candidate,support:"es"),fixture["context"]["expected"])
    }
    func testGoalRemovalKeepsFirstThreeTasksAndTheirProgress() {
        var state=learner();state.editGoal("Read a recipe",now:date)
        state.applyImmersion(.init(date:date,target:state.target,action:.batch,payload:state.immersionScope(now:date).setting("tasks",tasks(4))))
        state.toggleImmersion(index:0,now:date)
        state.editGoal("",now:date.addingTimeInterval(1))
        XCTAssertEqual(state.immersionState(now:date)["status"].string,"goal_removed")
        state.applyImmersion(.init(date:date.addingTimeInterval(2),target:state.target,action:.batch,payload:state.immersionScope(now:date)))
        XCTAssertEqual(state.immersionBatch?["tasks"].array.count,3);XCTAssertTrue(DailyImmersion.completed(state.immersionBatch!,index:0));XCTAssertEqual(state.totalXP,0)
    }
    func testFirstBatchWinsAndOldTaskOrTimestampCannotOverwriteCurrentCompletion() {
        var state=learner();propose(&state)
        let batch=state.immersionBatch!
        state.applyImmersion(.init(date:date.addingTimeInterval(1),target:state.target,action:.batch,payload:state.immersionScope(now:date).setting("tasks",tasks(3,suffix:" other device"))))
        XCTAssertEqual(state.immersionBatch,batch)
        state.toggleImmersion(index:0,now:date.addingTimeInterval(5))
        let stale=state.immersionScope(now:date).setting("generatedAt",batch["generatedAt"]).setting("index",.number(0)).setting("task",batch["tasks"].array[0]).setting("value",.bool(false))
        state.applyImmersion(.init(date:date,target:state.target,action:.completion,payload:stale))
        XCTAssertTrue(DailyImmersion.completed(state.immersionBatch!,index:0))
        state.applyImmersion(.init(date:date.addingTimeInterval(10),target:state.target,action:.completion,payload:stale.setting("task",.object(["title":.string("wrong task")]))))
        XCTAssertTrue(DailyImmersion.completed(state.immersionBatch!,index:0))
    }
    func testAcknowledgmentKeepsNewCompletionAndItsRewardWithoutRepeatingIt() {
        var sent=learner();propose(&sent);sent.pendingImmersionChanges=[]
        sent.toggleImmersion(index:0,now:date);sent.toggleImmersion(index:1,now:date)
        var acknowledged=sent;acknowledged.pendingImmersionChanges=[]
        var current=sent;current.toggleImmersion(index:2,now:date.addingTimeInterval(1))
        let rebased=LearnerState.rebased(current:current,sent:sent,acknowledged:acknowledged)
        XCTAssertEqual(rebased.totalXP,15);XCTAssertTrue(DailyImmersion.completed(rebased.immersionBatch!,index:2));XCTAssertEqual(rebased.pendingImmersionChanges?.count,1)
        var cloud=rebased;cloud.pendingImmersionChanges=[]
        let final=LearnerState.rebased(current:rebased,sent:rebased,acknowledged:cloud)
        XCTAssertEqual(final.totalXP,15);XCTAssertTrue(final.pendingImmersionChanges?.isEmpty == true)
    }
    func testWebRewardReceiptPreventsRepeatAndArraysBecomeAchievementProof() {
        var state=learner();propose(&state)
        state.immersionRewardReceipts = .object([DailyImmersion.receipt(target:state.target,day:state.dailyKey):.string("already awarded on web")])
        for index in 0..<3 { state.toggleImmersion(index:index,now:date) }
        XCTAssertEqual(state.totalXP,0);XCTAssertTrue(state.immersionBatch?["rewarded"].boolean == true)
        let proof=AchievementProgress.completionProof(profile:.object(["realWorldTasks":state.immersionBatch!]),summary:.object([:]),quest:.object([:]),language:state.target,day:state.dailyKey).events
        XCTAssertEqual(proof.filter { $0["metric"].string == "immersion_tasks" }.count,3)
        XCTAssertEqual(proof.filter { $0["metric"].string == "immersion_checklists" }.count,1)
    }
    func testNewDayAndLanguageKeepSeparateHistoryAndRequireNewTasks() {
        var state=learner();propose(&state)
        let tomorrow=date.addingTimeInterval(86400)
        XCTAssertEqual(state.immersionState(now:tomorrow)["status"].string,"new")
        state.applyImmersion(.init(date:tomorrow,target:state.target,action:.batch,payload:state.immersionScope(now:tomorrow).setting("tasks",tasks(3,suffix:" next day"))))
        XCTAssertEqual(state.immersionHistory?["de"]?.array.count,3)
        state.target="fr";state.place(Placement(level:"A1",score:18,source:"test",selectedIDs:[],updatedAt:tomorrow))
        state.applyImmersion(.init(date:tomorrow,target:state.target,action:.batch,payload:state.immersionScope(now:tomorrow).setting("tasks",tasks(3,suffix:" French"))))
        XCTAssertEqual(state.immersionBatch?["targetLang"].string,"fr");XCTAssertEqual(state.immersionHistory?["de"]?.array.count,6)
    }
}
