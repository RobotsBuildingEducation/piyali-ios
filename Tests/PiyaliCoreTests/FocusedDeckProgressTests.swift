import XCTest
@testable import PiyaliCore

final class FocusedDeckProgressTests:XCTestCase {
    private var root:URL {URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()}
    @MainActor func testOriginalAsyncFactoryPromptsParsingFallbacksAndSameLanguageCards()throws {
        let rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/focused-flashcards.json"))),policy=try CompanionQuestPolicy(source:root.appendingPathComponent("Piyali/Resources/companion-quest-policy.js"))
        XCTAssertEqual(rows.count,13)
        for row in rows {
            let prompt=try policy.run("goalDeckPrompt",row["input"]).string
            XCTAssertEqual(prompt,row["prompt"].string,row["name"].string);XCTAssertFalse(prompt.contains("scoreAtGeneration"))
            XCTAssertEqual(try policy.run("goalDeckCards",row["input"]),row["cards"],row["name"].string)
            for (index,success) in [false,true].enumerated(){XCTAssertEqual(try policy.run("focusedRecallEvent",.object(["focus":row["input"]["focus"],"card":row["cards"].array[0],"success":.bool(success)])),row["recall"].array[index])}
            XCTAssertEqual(try policy.run("focusedRecallCompletion",.object(["focus":row["input"]["focus"],"cards":row["cards"]])),row["completion"])
        }
        let subtitle=try policy.run("focusedDeckSubtitle",.object(["answered":.number(1),"cards":.array([.null,.null,.null]),"language":.string("en")])).string
        XCTAssertTrue(subtitle.hasPrefix("1/3 · "));XCTAssertGreaterThan(subtitle.count,15)
    }
    private func cards()->JSONValue {.array(["a","b","c"].map{.object(["id":.string($0),"concept":.object(["en":.string("A greeting"),"es":.string("Hola")]),"cefrLevel":.string("A1")])})}
    func testGoalOutcomesWaitForAcknowledgmentAcrossRestoreAndNewWorkDuringSync()throws {
        let now=Date(),bp:JSONValue = .object(["goalId":.string("goal-deck"),"dayKey":.string(CalendarDay.key(now)),"lang":.string("es"),"mode":.string("flashcards"),"modes":.array(["flashcards","tutor"].map(JSONValue.string))])
        var state=LearnerState();state.target="es";state.support="en";state.applyGoal(GoalChange(action:.edit,target:"es",payload:.object(["id":bp["goalId"],"text":.string("Speak with family")])));state.applyGoal(GoalChange(action:.blueprint,target:"es",payload:bp));state.applyGoal(GoalChange(action:.artifact,target:"es",payload:bp.setting("cards",cards())));state.pendingGoalChanges=[]
        func answer(_ id:String,_ date:Date)->GoalChange {.init(action:.outcome,target:"es",date:date,payload:bp.setting("cardID",.string(id)).setting("success",.bool(true)).setting("item",.string("Hola")))}
        state.applyGoal(answer("a",now));XCTAssertTrue(state.goalArtifacts?.values.first?["outcomes"]["a"]["success"].boolean == true)
        XCTAssertFalse(state.displayedGoalArtifact(bp,mode:"flashcards")["outcomes"]["a"]["success"].boolean)
        state=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state));XCTAssertFalse(state.displayedGoalArtifact(bp,mode:"flashcards")["outcomes"]["a"]["success"].boolean)
        let sent=state;state.applyGoal(answer("b",now.addingTimeInterval(1)));var ack=sent;ack.pendingGoalChanges=[]
        state=LearnerState.rebased(current:state,sent:sent,acknowledged:ack)
        XCTAssertTrue(state.displayedGoalArtifact(bp,mode:"flashcards")["outcomes"]["a"]["success"].boolean);XCTAssertFalse(state.displayedGoalArtifact(bp,mode:"flashcards")["outcomes"]["b"]["success"].boolean)
        let second=state;ack=state;ack.pendingGoalChanges=[];state=LearnerState.rebased(current:state,sent:second,acknowledged:ack)
        XCTAssertTrue(state.displayedGoalArtifact(bp,mode:"flashcards")["outcomes"]["b"]["success"].boolean);XCTAssertEqual(state.totalXP,4)
    }
    @MainActor func testRepairProjectionPreservesEarlierConfirmedCardsDuringLaterPendingSave()throws {
        let now=Date(),day=CalendarDay.key(now),item:JSONValue = .object(["memoryId":.string("m"),"mode":.string("flashcards"),"concept":.string("A greeting"),"expectedAnswer":.string("Hola")]),plan:JSONValue = .object(["targetLang":.string("es"),"dayKey":.string(day),"items":.array([item]),"memoryIds":.array([.string("m")])])
        var state=LearnerState();state.target="es";state.support="en";state.storeCompanionBlueprint(.object(["status":.string("ready"),"repair":plan]),target:"es",day:day)
        let policy=try CompanionQuestPolicy(source:root.appendingPathComponent("Piyali/Resources/companion-quest-policy.js")),raw=try policy.run("next",.object(["plan":plan,"completedCount":.number(0)])),step=try JSONDecoder().decode(RepairStep.self,from:Data(raw.json.utf8))
        state.storeRepairArtifact(.object(["ownerKey":.string(CompanionQuestDay.artifactKey(step,mode:"flashcards")),"cards":cards(),"outcomes":.object([:])]),step:step,mode:"flashcards");state.pendingCompanionQuestDays=[:];state.pendingChanges=[]
        XCTAssertTrue(state.recordRepairOutcome(step,mode:"flashcards",cardID:"a",success:true,item:"Hola",support:"prompted",now:now))
        XCTAssertFalse(state.displayedRepairArtifact(step,mode:"flashcards")["outcomes"]["a"]["success"].boolean)
        let sent=state;XCTAssertTrue(state.recordRepairOutcome(step,mode:"flashcards",cardID:"b",success:true,item:"Hola",support:"prompted",now:now.addingTimeInterval(1)))
        var ack=sent;ack.pendingCompanionQuestDays=[:];ack.pendingChanges=[]
        state=LearnerState.rebased(current:state,sent:sent,acknowledged:ack)
        XCTAssertTrue(state.displayedRepairArtifact(step,mode:"flashcards")["outcomes"]["a"]["success"].boolean);XCTAssertFalse(state.displayedRepairArtifact(step,mode:"flashcards")["outcomes"]["b"]["success"].boolean)
        state=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state));XCTAssertTrue(state.displayedRepairArtifact(step,mode:"flashcards")["outcomes"]["a"]["success"].boolean)
        let second=state;ack=state;ack.pendingCompanionQuestDays=[:];ack.pendingChanges=[];state=LearnerState.rebased(current:state,sent:second,acknowledged:ack)
        XCTAssertTrue(state.displayedRepairArtifact(step,mode:"flashcards")["outcomes"]["b"]["success"].boolean);XCTAssertEqual(state.totalXP,4)
    }
}
