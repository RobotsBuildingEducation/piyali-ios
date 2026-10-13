import XCTest
@testable import PiyaliCore
final class TutorCourseTests: XCTestCase {
    var lesson: Lesson { Lesson(id:"lesson-pre-a1-1-1",title:.string("Family"),description:.string("Talk about family"),xpReward:80,modes:["realtime"],agenda:.object(["items":.array([.object(["id":.string("one"),"goal":.string("Name a family member")]),.object(["id":.string("two"),"goal":.string("Describe the family")])])]),content:.object([:])) }
    func verdict(success: Bool = true, advanced: Bool = true, confidence: Double = 0.9, mistake: Bool = false) -> TutorTurnVerdict { TutorTurnVerdict(successful:success,objectiveAdvanced:advanced,mistake:mistake,confidence:confidence,correction:"",reason:"Evidence",support:"prompted") }
    func testVoiceTurnIdentitySurvivesTrimmingAndReconnectWithoutCountingModelOnlyTurns() {
        var capture = VoiceTurnCapture()
        XCTAssertNil(capture.finish())
        capture.append("Mi mamá "); capture.append("se llama Ana.")
        XCTAssertEqual(capture.finish(),"Mi mamá se llama Ana."); XCTAssertEqual(capture.sequence,1)
        XCTAssertNil(capture.finish()); XCTAssertEqual(capture.sequence,1)
        capture.append(String(repeating:"a",count:14000)); XCTAssertEqual(capture.pending.count,12000)
        XCTAssertEqual(capture.finish()?.count,12000); XCTAssertEqual(capture.sequence,2)
        capture.reset(); capture.append("Quisiera una sopa.")
        XCTAssertEqual(capture.finish(),"Quisiera una sopa."); XCTAssertEqual(capture.sequence,3)
    }
    func testTutorCourseLevelIsIndependentFromLessonBrowsing() {
        var state = LearnerState(); state.level = "A1"
        XCTAssertEqual(state.tutorLevel,"Pre-A1")
        state.place(Placement(level:"B1",score:53,source:"self_report",selectedIDs:[],updatedAt:Date()))
        XCTAssertEqual(state.tutorLevel,"B1")
        state.level = "A1"; XCTAssertEqual(state.tutorLevel,"B1")
        state.target = "fr"; XCTAssertEqual(state.tutorLevel,"Pre-A1")
    }
    func testNeutralOrUncertainTurnsDoNotEarnOrComplete() {
        var state = LearnerState(); let item = TutorCourse.agenda(lesson)[0]
        XCTAssertEqual(state.tutorTurn(lesson:lesson,item:item,verdict:verdict(success:false)),0)
        XCTAssertEqual(state.tutorTurn(lesson:lesson,item:item,verdict:verdict(confidence:0.2)),0)
        XCTAssertEqual(state.xp,0); XCTAssertEqual(state.tutorProgress(lesson.id).earnedXP,0)
        XCTAssertFalse(state.completeTutor(lesson)); XCTAssertFalse(state.canCompleteTutor(lesson))
    }
    func testAgendaAndPracticeThresholdBothRequiredWithSeparateCompletion() {
        var state = LearnerState(); let items = TutorCourse.agenda(lesson)
        for _ in 0..<20 { _ = state.tutorTurn(lesson:lesson,item:items[0],verdict:verdict(),amount:7) }
        XCTAssertFalse(state.canCompleteTutor(lesson))
        _ = state.tutorTurn(lesson:lesson,item:items[1],verdict:verdict(),amount:3)
        XCTAssertTrue(state.canCompleteTutor(lesson)); let xp = state.xp
        XCTAssertTrue(state.completeTutor(lesson)); XCTAssertEqual(state.xp,xp + TutorCourse.requiredXP(lesson.id))
        XCTAssertFalse(state.completeTutor(lesson)); XCTAssertFalse(state.completed.contains(state.completionKey(lesson.id)))
        XCTAssertEqual(state.plateProgress["speakDailyActivity"]["es"][state.dailyKey].number,1)
        state.target = "fr"; XCTAssertEqual(state.tutorProgress(lesson.id).earnedXP,0)
    }
    func testFreshTurnSurvivesCloudAcknowledgment() {
        let item = TutorCourse.agenda(lesson)[0]
        var sent = LearnerState(); _ = sent.tutorTurn(lesson:lesson,item:item,verdict:verdict(),amount:5)
        var current = sent; _ = current.tutorTurn(lesson:lesson,item:TutorCourse.agenda(lesson)[1],verdict:verdict(),amount:7)
        var cloud = sent; cloud.pendingChanges = []
        let result = LearnerState.rebased(current:current,sent:sent,acknowledged:cloud)
        XCTAssertEqual(result.tutorProgress(lesson.id).earnedXP,12); XCTAssertEqual(result.tutorProgress(lesson.id).items,["one","two"])
        XCTAssertEqual(result.xp,12)
    }
}
