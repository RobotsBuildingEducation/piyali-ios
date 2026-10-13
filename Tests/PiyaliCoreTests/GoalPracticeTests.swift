import XCTest
@testable import PiyaliCore

final class GoalPracticeTests: XCTestCase {
    let now = Date(timeIntervalSince1970:1791892800)
    func edited() -> JSONValue {
        GoalPractice.applying(GoalChange(action:.edit,target:"es",date:now,payload:.object(["id":.string("goal-one"),"text":.string("Order a meal"),"status":.string("active")])),to:.object([:])).bucket
    }
    func task(_ bucket: JSONValue, day: String = "2026-10-13", raw: JSONValue = .object([:])) -> JSONValue {
        GoalPractice.blueprint(raw:raw,goal:bucket["activeGoal"],target:"es",day:day,level:"B1",rating:PerformanceScore.rating(score:18),progress:bucket["goalProgress"])
    }
    func installed() -> JSONValue {
        let bucket = edited()
        return GoalPractice.applying(GoalChange(action:.blueprint,target:"es",date:now,payload:task(bucket)),to:bucket).bucket
    }
    func attempt(_ bucket: JSONValue, mode: String, success: Bool = true, action: GoalAction = .attempt, observation: String = "Ordered a meal using a hint") -> GoalChange {
        let blueprint = bucket["dailyGoal"]["blueprint"]
        return GoalChange(action:action,target:"es",date:now,payload:blueprint.setting("mode",.string(mode)).setting("success",.bool(success)).setting("support",.string("prompted")).setting("observation",.string(observation)).setting("domain",.string("production")))
    }
    func testBundleSelectionAndEvidenceMatchWebFixtures() throws {
        let url = URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/goal-practice.json")
        let fixture = try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url))
        for item in fixture["modes"].array {
            XCTAssertEqual(GoalPractice.selectModes(goalID:item["goalId"].string,day:item["dayKey"].string,preferred:item["preferredMode"].string,cards:item["allowFocusedCards"].boolean),item["expected"].array.map(\.string))
        }
        let evidence = fixture["evidence"]
        XCTAssertEqual(GoalPractice.mergeEvidence(.object([:]),event:evidence["event"],now:evidence["now"].string),evidence["expected"])
        let completion = fixture["modeCompletion"], blueprint = completion["bucket"]["dailyGoal"]["blueprint"]
        var change = GoalChange(action:.attempt,target:"es",date:try XCTUnwrap(WebProgressContract.date(completion["now"].string)),payload:completion["event"].setting("goalId",blueprint["goalId"]).setting("dayKey",blueprint["dayKey"]).setting("mode",blueprint["mode"]))
        change.id = try XCTUnwrap(UUID(uuidString:completion["event"]["id"].string))
        let result = GoalPractice.applying(change,to:completion["bucket"])
        XCTAssertEqual(result.bucket["dailyGoal"]["modeProgress"],completion["expected"]["dailyGoal"]["modeProgress"])
        XCTAssertEqual(result.bucket["dailyGoal"]["completed"],completion["expected"]["dailyGoal"]["completed"])
        XCTAssertEqual(result.bucket["goalProgress"],completion["expected"]["goalProgress"])
        XCTAssertEqual(completion["xpBefore"].number + Double(result.reward),completion["xpAfter"].number)
    }
    func testGoalEditsPauseResumeAndReplacementRetainOrResetEvidence() {
        var bucket = installed()
        let blueprint = bucket["dailyGoal"]["blueprint"]
        let paused = GoalChange(action:.edit,target:"es",date:now.addingTimeInterval(1),payload:.object(["id":.string("ignored"),"text":.string("Order a meal"),"status":.string("paused")]))
        bucket = GoalPractice.applying(paused,to:bucket).bucket
        XCTAssertNil(GoalPractice.active(bucket)); XCTAssertEqual(bucket["activeGoal"]["id"].string,"goal-one")
        XCTAssertEqual(bucket["dailyGoal"]["blueprint"],blueprint)
        let replacement = GoalChange(action:.edit,target:"es",date:now.addingTimeInterval(2),payload:.object(["id":.string("new-goal"),"text":.string("Speak to family"),"status":.string("active")]))
        bucket = GoalPractice.applying(replacement,to:bucket).bucket
        XCTAssertEqual(bucket["activeGoal"]["id"].string,"new-goal"); XCTAssertEqual(bucket["dailyGoal"],.null)
        XCTAssertTrue(bucket["goalProgress"]["demonstrated"].array.isEmpty)
        XCTAssertEqual(GoalPractice.applying(paused,to:bucket).bucket,bucket)
    }
    func testFirstSavedBlueprintWinsAndOldDayCannotReplaceNewDay() {
        var bucket = installed(), competing = task(edited()).setting("objective",.string("Competing objective"))
        let original = bucket["dailyGoal"]["blueprint"]
        bucket = GoalPractice.applying(GoalChange(action:.blueprint,target:"es",date:now,payload:competing),to:bucket).bucket
        XCTAssertEqual(bucket["dailyGoal"]["blueprint"],original)
        competing = task(bucket,day:"2026-10-14")
        bucket = GoalPractice.applying(GoalChange(action:.blueprint,target:"es",date:now,payload:competing),to:bucket).bucket
        XCTAssertEqual(bucket["dailyGoal"]["blueprint"]["dayKey"].string,"2026-10-14")
        bucket = GoalPractice.applying(GoalChange(action:.blueprint,target:"es",date:now,payload:original),to:bucket).bucket
        XCTAssertEqual(bucket["dailyGoal"]["blueprint"],competing)
    }
    func testTaskRequiresEvidenceAndCompletionDoesNotAwardExtraXP() {
        var bucket = installed()
        for mode in bucket["dailyGoal"]["blueprint"]["modes"].array.map(\.string) {
            let failure = GoalPractice.applying(attempt(bucket,mode:mode,success:false),to:bucket)
            XCTAssertEqual(failure.reward,0); XCTAssertEqual(failure.bucket["dailyGoal"]["modeProgress"][mode].number,0)
            let empty = GoalPractice.applying(attempt(bucket,mode:mode,observation:""),to:bucket)
            XCTAssertEqual(empty.bucket,bucket)
            let change = attempt(bucket,mode:mode)
            let result = GoalPractice.applying(change,to:bucket)
            XCTAssertEqual(result.reward,0); bucket = result.bucket
            XCTAssertEqual(GoalPractice.applying(change,to:bucket).reward,0)
            XCTAssertEqual(GoalPractice.applying(attempt(bucket,mode:mode),to:bucket).reward,0)
        }
        XCTAssertTrue(bucket["dailyGoal"]["completed"].boolean); XCTAssertNil(GoalPractice.nextMode(bucket["dailyGoal"]))
        XCTAssertNil(GoalPractice.today(bucket,day:"2026-10-14"))
    }
    func testRecallEvidenceDoesNotCompletePracticalGoalAndSummaryIsBounded() {
        var bucket = installed()
        let mode = bucket["dailyGoal"]["blueprint"]["modes"].array.first!.string
        for i in 0..<50 { bucket = GoalPractice.applying(attempt(bucket,mode:mode,action:.evidence,observation:String(repeating:"word ",count:600) + "\(i)"),to:bucket).bucket }
        XCTAssertFalse(bucket["dailyGoal"]["completed"].boolean)
        XCTAssertEqual(bucket["dailyGoal"]["modeProgress"][mode].number,0)
        XCTAssertLessThanOrEqual(bucket["goalProgress"]["wordCount"].number,200)
        XCTAssertLessThanOrEqual(bucket["goalProgress"]["eventIds"].array.count,24)
        XCTAssertLessThanOrEqual(bucket["goalProgress"]["demonstrated"].array.count,4)
    }
    func testRecallEvidenceKeepsEachWordConceptSeparate() {
        var bucket = installed()
        let mode = bucket["dailyGoal"]["blueprint"]["modes"].array.first!.string
        for word in ["soup","rice"] {
            let original = attempt(bucket,mode:mode,action:.evidence)
            let change = GoalChange(action:.evidence,target:"es",date:now,payload:original.payload.setting("target",.string(word)).setting("domain",.string("recall")))
            bucket = GoalPractice.applying(change,to:bucket).bucket
        }
        XCTAssertEqual(Set(bucket["goalProgress"]["demonstrated"].array.map { $0["target"].string }),["soup","rice"])
        XCTAssertTrue(bucket["goalProgress"]["demonstrated"].array.allSatisfy { $0["demonstratedStage"].string == "recognition" })
        XCTAssertFalse(bucket["dailyGoal"]["completed"].boolean)
    }
    func testPreparationArtifactsKeepFirstDeckAndNeverRepeatCardRewards() {
        let blueprint = task(edited())
        let card: JSONValue = .object(["id":.string("card-one"),"concept":.object(["es":.string("sopa")])])
        let deck = GoalChange(action:.artifact,target:"es",date:now,payload:blueprint.setting("mode",.string("flashcards")).setting("cards",.array([card])))
        var artifact = GoalPractice.applyingArtifact(deck,to:.object([:])).artifact
        let competing = GoalChange(action:.artifact,target:"es",date:now,payload:deck.payload.setting("cards",.array([.object(["id":.string("other")])])))
        XCTAssertEqual(GoalPractice.applyingArtifact(competing,to:artifact).artifact,artifact)
        let payload = blueprint.setting("mode",.string("flashcards")).setting("cardID",.string("card-one")).setting("success",.bool(true))
        let result = GoalPractice.applyingArtifact(GoalChange(action:.outcome,target:"es",date:now,payload:payload),to:artifact)
        XCTAssertEqual(result.reward,2); artifact = result.artifact
        artifact = GoalPractice.applyingArtifact(GoalChange(action:.outcome,target:"es",date:now.addingTimeInterval(1),payload:payload.setting("success",.bool(false))),to:artifact).artifact
        XCTAssertEqual(GoalPractice.applyingArtifact(GoalChange(action:.outcome,target:"es",date:now.addingTimeInterval(2),payload:payload),to:artifact).reward,0)
    }
    func testSyncRetainsNewGoalEvidenceWithoutReplayingAcknowledgedRewards() {
        var sent = LearnerState(); sent.goalIntelligence = ["es":installed()]
        let blueprint = installed()["dailyGoal"]["blueprint"]
        let key = GoalPractice.artifactKey(target:"es",day:blueprint["dayKey"].string,mode:"flashcards",goalID:blueprint["goalId"].string)
        let card: JSONValue = .object(["id":.string("one")])
        sent.goalArtifacts = [key:GoalPractice.applyingArtifact(GoalChange(action:.artifact,target:"es",date:now,payload:blueprint.setting("mode",.string("flashcards")).setting("cards",.array([card]))),to:.object([:])).artifact]
        var current = sent
        let change = GoalChange(action:.outcome,target:"es",date:now,payload:blueprint.setting("mode",.string("flashcards")).setting("cardID",.string("one")).setting("success",.bool(true)))
        current.applyGoal(change)
        XCTAssertEqual(current.xp,2)
        let rebased = LearnerState.rebased(current:current,sent:sent,acknowledged:sent)
        XCTAssertEqual(rebased.xp,current.xp); XCTAssertEqual(rebased.pendingGoalChanges?.count,1)
        var cloud = current; cloud.pendingGoalChanges = []; cloud.acknowledgedEventIDs = [change.id]
        let acknowledged = LearnerState.rebased(current:current,sent:sent,acknowledged:cloud)
        XCTAssertEqual(acknowledged.xp,current.xp); XCTAssertTrue(acknowledged.pendingGoalChanges?.isEmpty == true)
    }
}
