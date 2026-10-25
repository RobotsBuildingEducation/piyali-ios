import XCTest
@testable import PiyaliCore

final class TutorSourceProgressTests:XCTestCase {
    private var lesson:Lesson {Lesson(id:"lesson-tutorial-1",title:.string("Tutorial"),description:.string("Introductions"),xpReward:50,modes:["realtime"],agenda:.object([:]),content:.object([:]),cefrLevel:"Pre-A1")}
    func testOwnXPIsCappedWhileSuccessfulRepeatsRetainTurnRewardsAndOneCompletion(){
        var learner=LearnerState();learner.storeTutorState(lesson:lesson,data:.object(["kind":.string("start")]))
        XCTAssertFalse(learner.completeSourceTutor(lesson:lesson,required:50,ready:true))
        for _ in 0..<8 {learner.sourceTutorTurn(lesson:lesson,required:50,agenda:.object(["hello":.bool(true)]),xp:7)}
        XCTAssertEqual(learner.totalXP,56);XCTAssertEqual(learner.tutorProgress(lesson.id).earnedXP,50);XCTAssertEqual(learner.tutorProgress(lesson.id).items,["hello"])
        XCTAssertFalse(learner.completeSourceTutor(lesson:lesson,required:50,ready:false));XCTAssertTrue(learner.completeSourceTutor(lesson:lesson,required:50,ready:true));XCTAssertFalse(learner.completeSourceTutor(lesson:lesson,required:50,ready:true))
        XCTAssertEqual(learner.totalXP,106);XCTAssertEqual(learner.plateProgress["speakDailyActivity"]["es"][CalendarDay.key(Date())].number,1);XCTAssertEqual(learner.plateProgress["lessonDailyActivity"],.null)
        XCTAssertEqual(learner.tutorProgress(lesson.id).sourceState?["status"].string,"completed")
    }
    func testQuizCursorCanResetWithoutLosingXPAndCompletionDeletesOnlyOwnedDraftFields(){
        var learner=LearnerState();learner.sourceTutorTurn(lesson:lesson,required:6,agenda:.object(["a":.bool(true)]),xp:7)
        let messages:JSONValue = .array([.object(["id":.string("public"),"role":.string("assistant"),"text":.string("Hola"),"ts":.number(1000)])])
        learner.storeTutorState(lesson:lesson,data:.object(["kind":.string("draft"),"draft":.object(["version":.number(1),"messages":messages])]))
        learner.storeTutorState(lesson:lesson,data:.object(["kind":.string("agenda"),"agenda":.object([:]),"replaceAgenda":.bool(true),"quiz":.object(["correctItems":.object([:]),"attemptNumber":.number(2)])]))
        var progress=learner.tutorProgress(lesson.id);XCTAssertTrue(progress.items.isEmpty);XCTAssertEqual(progress.earnedXP,6);XCTAssertEqual(progress.sourceState?["conversationDraft"]["messages"],messages);XCTAssertEqual(progress.sourceState?["tutorAgendaProgress"]["quiz"]["attemptNumber"],.number(2))
        XCTAssertTrue(learner.completeSourceTutor(lesson:lesson,required:6,ready:true));progress=learner.tutorProgress(lesson.id)
        XCTAssertEqual(progress.sourceState?["conversationDraft"],.null);XCTAssertEqual(progress.sourceState?["tutorAgendaProgress"],.null)
        learner.storeTutorState(lesson:lesson,data:.object(["kind":.string("draft"),"draft":.object(["messages":messages])]))
        XCTAssertEqual(learner.tutorProgress(lesson.id).sourceState?["conversationDraft"],.null,"A late draft cannot reopen a completed source lesson")
    }
    func testNewTutorTurnAndDraftRebaseOverAnInflightAcknowledgment(){
        var learner=LearnerState();learner.sourceTutorTurn(lesson:lesson,required:50,agenda:.object(["a":.bool(true)]),xp:3);let sent=learner;var cloud=sent;cloud.pendingChanges=[]
        learner.sourceTutorTurn(lesson:lesson,required:50,agenda:.object(["b":.bool(true)]),xp:7)
        learner.storeTutorState(lesson:lesson,data:.object(["kind":.string("draft"),"draft":.object(["version":.number(1),"messages":.array([])])]))
        let merged=LearnerState.rebased(current:learner,sent:sent,acknowledged:cloud)
        XCTAssertEqual(merged.totalXP,10);XCTAssertEqual(merged.tutorProgress(lesson.id).earnedXP,10);XCTAssertEqual(merged.tutorProgress(lesson.id).items,["a","b"]);XCTAssertEqual(merged.tutorProgress(lesson.id).sourceState?["conversationDraft"]["version"],.number(1));XCTAssertEqual(merged.pendingChanges?.count,2)
    }
}
