import XCTest
@testable import PiyaliCore

final class GoalLessonProgressTests:XCTestCase {
    private var root:URL {URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()}
    @MainActor func testOriginalGoalPoliciesAndNativeLessonCounterAgree()throws {
        let policy=try CompanionQuestPolicy(source:root.appendingPathComponent("Piyali/Resources/companion-quest-policy.js")),rows=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/goal-source-policy.json.gz"))
        XCTAssertEqual(rows.count,116)
        for row in rows {
            let input=row["input"],operation=row["operation"].string
            XCTAssertEqual(try policy.run(operation,input),row["expected"],operation)
            if operation == "goalReady" {
                let lesson=input["lesson"],bp=lesson["goalBlueprint"]
                XCTAssertEqual(GoalLessonProgress.ready(input["bucket"],goalID:bp["goalId"].string,day:bp["dayKey"].string,lessonID:lesson["id"].string,target:Int(lesson["xpReward"].number)),row["expected"].boolean)
            }
            if operation == "goalPreparation" {
                var change=PracticeChange(dayKey:input["dayKey"].string,target:input["targetLang"].string,level:"A1",amount:Int(input["amount"].number),source:.practice)
                change.attachCurriculumLesson(id:input["lessonId"].string,level:"A1")
                let next=GoalLessonProgress.applying(change,to:input["bucket"])
                if row["expected"] == .null {XCTAssertEqual(next,input["bucket"])}else{XCTAssertEqual(next["dailyGoal"]["preparationXp"],row["expected"])}
            }
        }
    }
    private func state(_ day:String)->LearnerState {
        var state=LearnerState();state.editGoal("Greet a family member")
        let goal=state.goalBucket["activeGoal"]
        let bp:JSONValue = .object(["goalId":goal["id"],"dayKey":.string(day),"lang":.string("es"),"mode":.string("lesson"),"modes":.array([.string("lesson"),.string("tutor")]),"objective":.string("Greet a family member"),"cefrLevel":.string("Pre-A1")])
        state.applyGoal(GoalChange(action:.blueprint,target:"es",payload:bp));state.pendingGoalChanges=[];return state
    }
    func testUnrelatedXPAndLateGoalWorkDoNotFillThisLessonAndThresholdDoesNotAwardABonus() {
        let day=CalendarDay.key(Date());var state=state(day),goal=state.goalBucket["activeGoal"]
        let lesson=Lesson(id:"goal-\(goal["id"].string)-\(day)",title:.string("Greeting"),description:.string("Practice"),xpReward:20,modes:["vocabulary","grammar","reading","stories","realtime"],agenda:.object([:]),content:.object([:]),isGoal:true)
        state.award(50);state.award(50,lesson:Lesson(id:"other",title:.string("Other"),description:.string(""),xpReward:20,modes:[],agenda:.object([:]),content:.object([:])))
        XCTAssertEqual(GoalLessonProgress.earned(state.goalBucket),0)
        state.award(12,lesson:lesson);state.award(9,lesson:lesson)
        XCTAssertEqual(GoalLessonProgress.earned(state.goalBucket),21);XCTAssertEqual(state.totalXP,121);XCTAssertFalse(state.complete(lesson));XCTAssertNil(state.lessonWork?[state.completionKey(lesson.id)])
        state.editGoal("A different destination");goal=state.goalBucket["activeGoal"];state.award(10,lesson:lesson)
        XCTAssertEqual(GoalLessonProgress.earned(state.goalBucket),0);XCTAssertNotEqual(lesson.id,"goal-\(goal["id"].string)-\(day)")
    }
    func testCompletionWaitsForCanonicalLessonXPAndPendingModesDoNotClaimThePlateBonus() {
        let day=CalendarDay.key(Date());var state=state(day),bucket=state.goalBucket
        let goalID=bucket["activeGoal"]["id"],payload:JSONValue = .object(["goalId":goalID,"dayKey":.string(day),"mode":.string("lesson"),"success":.bool(true),"support":.string("prompted"),"observation":.string("Completed correct exercises"),"requireLessonCompletion":.bool(true),"priorModeProgress":.number(0)])
        let attempt=GoalChange(action:.attempt,target:"es",payload:payload)
        XCTAssertEqual(GoalPractice.applying(attempt,to:bucket).bucket,bucket)
        bucket=bucket.setting("dailyGoal",bucket["dailyGoal"].setting("preparationXp",.number(20)));state.goalIntelligence?["es"]=bucket
        state.applyGoal(attempt)
        XCTAssertEqual(state.goalBucket["dailyGoal"]["modeProgress"]["lesson"].number,20);XCTAssertEqual(state.confirmedGoalBucket["dailyGoal"]["modeProgress"]["lesson"].number,0)
        state.pendingGoalChanges=[]
        XCTAssertEqual(state.confirmedGoalBucket["dailyGoal"]["modeProgress"]["lesson"].number,20);XCTAssertEqual(state.totalXP,0)
    }
    func testLegacyBundleUpgradeKeepsPracticeAndCannotOverwriteANewerOrCompletedPlan() {
        let day=CalendarDay.key(Date()),original=state(day).goalBucket
        let old=original["dailyGoal"].setting("preparationXp",.number(12)).setting("modeProgress",.object(["lesson":.number(0.5)])).setting("modeEventIds",.array([.string("saved-event")]))
        let bucket=original.setting("dailyGoal",old),bp=old["blueprint"].setting("modeTargets",.object(["lesson":.number(20),"tutor":.number(25)]))
        let change=GoalChange(action:.bundleUpgrade,target:"es",payload:bp),next=GoalPractice.applying(change,to:bucket).bucket
        XCTAssertEqual(next["dailyGoal"]["preparationXp"].number,12);XCTAssertEqual(next["dailyGoal"]["modeProgress"]["lesson"].number,0.5);XCTAssertEqual(next["dailyGoal"]["modeProgress"]["tutor"].number,0);XCTAssertEqual(next["dailyGoal"]["modeEventIds"],old["modeEventIds"])
        let late=GoalChange(action:.bundleUpgrade,target:"es",payload:bp.setting("objective",.string("Late replacement")))
        XCTAssertEqual(GoalPractice.applying(late,to:next).bucket,next)
        let finished=bucket.setting("dailyGoal",old.setting("completed",.bool(true)))
        XCTAssertEqual(GoalPractice.applying(change,to:finished).bucket,finished)
        let stale=GoalChange(action:.bundleUpgrade,target:"es",payload:bp.setting("goalId",.string("old-goal")))
        XCTAssertEqual(GoalPractice.applying(stale,to:bucket).bucket,bucket)
    }
    func testSourceRootPatchAndInFlightRebaseKeepGoalPreparationWithoutCurriculumWrites() {
        let day=CalendarDay.key(Date());var sent=state(day);let bp=sent.goalBucket["dailyGoal"]["blueprint"],id="goal-\(bp["goalId"].string)-\(day)"
        let lesson=Lesson(id:id,title:.string("Goal"),description:.string(""),xpReward:20,modes:["grammar"],agenda:.object([:]),content:.object([:]),isGoal:true)
        sent.award(12,lesson:lesson);let fields:[String:Any]=["local_npub":"public","learningIntelligence":["es":state(day).goalBucket.foundation]]
        // Use the same active goal, not a newly generated ID.
        var original=sent.goalBucket;original=original.setting("dailyGoal",original["dailyGoal"].setting("preparationXp",.number(0)))
        var profile=fields;profile["learningIntelligence"]=["es":original.foundation]
        let change=sent.pendingChanges!.last!,patch=WebProgressContract.rootPatch(fields:profile,month:[:],change:change)
        XCTAssertEqual(((patch.root["learningIntelligence"] as? [String:[String:Any]])?["es"]?["dailyGoal"] as? [String:Any])?["preparationXp"] as? Double,12)
        var current=sent;current.award(9,lesson:lesson)
        var acknowledged=sent;acknowledged.pendingChanges=[]
        let merged=LearnerState.rebased(current:current,sent:sent,acknowledged:acknowledged)
        XCTAssertEqual(GoalLessonProgress.earned(merged.goalBucket),21);XCTAssertEqual(merged.pendingChanges?.count,1);XCTAssertNil(merged.lessonWork?[merged.completionKey(id)])
    }
}
