import XCTest
@testable import PiyaliCore

final class GoalMemoryCaptureTests:XCTestCase {
    private func installed(_ bp:JSONValue,now:Date)->LearnerState {
        var state=LearnerState();state.target="es";state.support="en"
        state.applyGoal(GoalChange(action:.edit,target:"es",date:now,payload:.object(["id":bp["goalId"],"text":.string("Speak with family")])))
        state.applyGoal(GoalChange(action:.blueprint,target:"es",date:now,payload:bp));state.pendingGoalChanges=[];return state
    }
    func testOriginalFullCaptureRoutesGoalSlipsWithoutRepairsXPOrCompletionIncludingEmptyAnswers()throws {
        let file=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/goal-memory-capture.json")
        let rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:file));XCTAssertEqual(rows.count,12)
        for row in rows {
            let now=try XCTUnwrap(WebProgressContract.date(row["now"].string)),bp=row["focus"]["blueprint"] == .null ? rows[0]["focus"]["blueprint"]:row["focus"]["blueprint"],input=row["input"]
            var state=installed(bp,now:now)
            // The source SRS/realtime captures omit npub and does not enter its strict Goal branch.
            let focus:GoalMemoryFocus?=row["route"].string == "goal" ? .init(target:"es",blueprint:bp):nil
            state.captureMemory(mode:input["sourceMode"].string,concept:input["concept"].string,answer:input["userAnswer"].string,expected:input["expectedAnswer"].string,feedback:"",now:now,goalFocus:focus)
            XCTAssertEqual(state.totalXP,0);XCTAssertEqual(GoalLessonProgress.earned(state.goalBucket),0);XCTAssertFalse(state.goalBucket["dailyGoal"]["completed"].boolean)
            if row["route"].string == "goal" {
                XCTAssertTrue((state.companionMemory?["es"] ?? []).isEmpty);XCTAssertTrue((state.pendingMemoryChanges ?? []).isEmpty)
                let change=try XCTUnwrap(state.pendingGoalChanges?.first),source=row["event"]
                for key in ["goalId","target","observation","expectedAnswer","mode","domain","success","support"] {XCTAssertEqual(change.payload[key],source[key],row["name"].string+key)}
                var expected=row["summary"];if !expected["eventIds"].array.isEmpty{expected=expected.setting("eventIds",.array([.string(change.id.uuidString)]))}
                XCTAssertEqual(state.goalBucket["goalProgress"],expected,row["name"].string)
                let reapplied=GoalPractice.applying(change,to:state.goalBucket)
                XCTAssertEqual(reapplied.bucket,state.goalBucket);XCTAssertEqual(reapplied.reward,0)
            } else {XCTAssertEqual(state.companionMemory?["es"]?.count,1);XCTAssertTrue((state.pendingGoalChanges ?? []).isEmpty)}
        }
    }
    func testTypedGoalMissDoesNotFillLessonAndContextIsNeverRestoredOrInferredFromAnActiveGoal()throws {
        let now=Date(),day=CalendarDay.key(now),bp:JSONValue = .object(["goalId":.string("goal-memory"),"lang":.string("es"),"dayKey":.string(day),"mode":.string("lesson"),"modes":.array([.string("lesson"),.string("tutor")])])
        var state=installed(bp,now:now)
        let q=try PracticeQuestion(module:.grammar,kind:"mc",payload:.object(["question":.string("___, Ana"),"answer":.string("Hola"),"choices":.array(["Hola","Adiós"].map(JSONValue.string))]),options:.object(["cefrLevel":.string("A1")]),target:"es",support:"en")
        var run=PracticeRun(question:q,lessonID:"goal-goal-memory-"+day,lessonLevel:"A1",response:.object(["indices":.array([.number(1)])]));state.savePractice(run)
        var restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state))
        XCTAssertTrue(restored.answerPractice(key:run.key,questionID:q.id,correct:false,reward:5,now:now));XCTAssertEqual(restored.companionMemory?["es"]?.count,1,"A restored question has no mounted Goal focus.")
        let focus=GoalMemoryFocus(target:"es",blueprint:bp)
        XCTAssertTrue(state.answerPractice(key:run.key,questionID:q.id,correct:false,reward:5,now:now,goalFocus:focus));XCTAssertFalse(state.answerPractice(key:run.key,questionID:q.id,correct:false,reward:5,now:now,goalFocus:focus));XCTAssertEqual(state.pendingGoalChanges?.count,1)
        XCTAssertEqual(state.totalXP,0);XCTAssertEqual(GoalLessonProgress.earned(state.goalBucket),0)
        run=try XCTUnwrap(state.practiceRuns?[run.key]);run.response = .object(["indices":.array([.number(0)])]);state.savePractice(run)
        XCTAssertTrue(state.answerPractice(key:run.key,questionID:q.id,correct:true,reward:5,now:now,goalFocus:focus));XCTAssertEqual(state.totalXP,5);XCTAssertEqual(GoalLessonProgress.earned(state.goalBucket),5)
        XCTAssertEqual(state.pendingGoalChanges?.count,1);XCTAssertEqual(state.goalBucket["dailyGoal"]["modeProgress"]["lesson"].number,0)
        XCTAssertTrue((state.pendingMemoryChanges ?? []).isEmpty)
    }
    func testGoalFocusRejectsTargetDayPauseReplacementAndWrongMode()throws {
        let now=Date(),day=CalendarDay.key(now),bp:JSONValue = .object(["goalId":.string("goal-memory"),"lang":.string("es"),"dayKey":.string(day),"mode":.string("lesson"),"modes":.array([.string("lesson"),.string("tutor")])])
        let state=installed(bp,now:now),focus=GoalMemoryFocus(target:"es",blueprint:bp)
        XCTAssertTrue(focus.matches(state,now:now));XCTAssertFalse(focus.matches(state,now:now.addingTimeInterval(86400)))
        var changed=state;changed.target="fr";XCTAssertFalse(focus.matches(changed,now:now))
        changed=state;changed.editGoal("Speak with family",status:"paused",now:now);XCTAssertFalse(focus.matches(changed,now:now))
        changed=state;changed.editGoal("Order food",now:now);XCTAssertFalse(focus.matches(changed,now:now))
        XCTAssertFalse(GoalMemoryFocus(target:"es",blueprint:bp.setting("mode",.string("flashcards"))).matches(state,now:now))
    }
    func testReadingStoryAndConversationMissReducersPreserveOriginalCallerDifferences()throws {
        let now=Date(),bp:JSONValue = .object(["goalId":.string("goal-memory"),"lang":.string("es"),"dayKey":.string(CalendarDay.key(now)),"mode":.string("lesson"),"modes":.array(["lesson","tutor"].map(JSONValue.string))])
        var state=installed(bp,now:now);let focus=GoalMemoryFocus(target:"es",blueprint:bp),lessonID="goal-goal-memory-"+CalendarDay.key(now)
        let reading:JSONValue = .object(["title":.string("La libreta"),"target":.string("Mi libreta verde está sobre la mesa. Dibujo una flor roja y escribo su nombre. Mañana mi hermana quiere dibujar conmigo."),"takeaways":.array(["A notebook","A flower","A plan"].map(JSONValue.string)),"reviewQuestion":.object(["type":.string("text"),"question":.string("What color is the flower?"),"answer":.string("red")])])
        state.saveReading(try ReadingRun(payload:reading,target:"es",support:"en",level:"A1",lessonID:lessonID,selection:.null,worth:.null,roll:0.5))
        XCTAssertEqual(state.reviewReading(answer:"blue",correct:false,feedback:"Try again",now:now,goalFocus:focus),0)
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/stories.json"),raw=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:root))["cases"].array[0]["raw"],lines=raw["segments"].array.flatMap{$0["turns"].array}
        state.saveStory(try StoryRun(payload:.object(["title":raw["title"],"sentences":.array(lines+lines)]),mode:.speaking,target:"es",support:"en",level:"A1",lessonID:lessonID,worth:.null))
        XCTAssertEqual(state.practiceStoryLine(words:"wrong phrase",typed:true,now:now,goalFocus:focus),0)
        let conversation=RealtimeLessonRun(target:"es",support:"en",lessonID:lessonID,lessonLevel:"A1",questionLevel:"A1",goal:.object(["title_en":.string("Greet a relative"),"rubric_en":.string("Say hello")]))
        state.saveRealtimeLesson(conversation);XCTAssertEqual(state.answerRealtimeLesson(key:conversation.key,runID:conversation.id,turnID:UUID(),utterance:"No sé",reply:"Hola",verdict:.init(met:false,confidence:1),now:now),0)
        XCTAssertEqual(state.pendingGoalChanges?.filter{$0.action == .evidence}.count,2);XCTAssertEqual(Set((state.pendingGoalChanges ?? []).map{$0.payload["domain"].string}),Set(["reading","story"]))
        XCTAssertEqual(state.totalXP,0);XCTAssertEqual(GoalLessonProgress.earned(state.goalBucket),0);XCTAssertEqual(state.pendingMemoryChanges?.count,1);XCTAssertEqual(state.companionMemory?["es"]?.first?.text("sourceMode"),"conversation")
    }

}
