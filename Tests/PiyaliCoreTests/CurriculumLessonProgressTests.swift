import XCTest
@testable import PiyaliCore

final class CurriculumLessonProgressTests:XCTestCase {
    private var lesson:Lesson { .init(id:"lesson-a1-1",title:.string("Greetings"),description:.string("Use greetings"),xpReward:50,modes:["grammar","vocabulary"],agenda:.object([:]),content:.object([:]),cefrLevel:"A1") }
    func testLessonOwnedCounterResumesAndDoesNotUseSharedXPOrLegacyBaselines() throws {
        var state=LearnerState();state.target="es"
        XCTAssertTrue(state.beginLessonWork(lesson));XCTAssertFalse(state.beginLessonWork(lesson))
        state.award(100,source:.tutorTurn)
        XCTAssertEqual(state.lessonWork?["es:lesson-a1-1"]?.earnedXP,0)
        for amount in [6,5,6,6] { var change=PracticeChange(date:Date(),dayKey:CalendarDay.key(Date()),target:"es",level:"A1",amount:amount,source:.practice);change.skillTreeLessonID=lesson.id;state.enqueue(change) }
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state))
        XCTAssertEqual(restored.lessonWork?["es:lesson-a1-1"]?.earnedXP,23);XCTAssertFalse(restored.lessonWork!["es:lesson-a1-1"]!.ready(goal:50))
        let legacy=CurriculumLessonProgress.fromWeb(["status":"in_progress","lessonStartXp":100,"xpEarned":50])
        XCTAssertEqual(legacy.earnedXP,0);XCTAssertFalse(legacy.ready(goal:50))
    }
    func testDifferentLessonLanguageAndUnstartedAwardsDoNotFillTheCounter() {
        var state=LearnerState();_=state.beginLessonWork(lesson)
        for (target,id) in [("fr",lesson.id),("es","other-lesson")] { var change=PracticeChange(date:Date(),dayKey:CalendarDay.key(Date()),target:target,level:"A1",amount:50,source:.practice);change.skillTreeLessonID=id;state.enqueue(change) }
        XCTAssertEqual(state.lessonWork?["es:lesson-a1-1"]?.earnedXP,0);XCTAssertNil(state.lessonWork?["fr:lesson-a1-1"]);XCTAssertNil(state.lessonWork?["es:other-lesson"])
    }
    func testOwnXPThresholdAndCompletionBonusAreSeparateAndCompletedReviewDoesNotRestartIt() {
        var state=LearnerState();_=state.beginLessonWork(lesson)
        var change=PracticeChange(date:Date(),dayKey:CalendarDay.key(Date()),target:"es",level:"A1",amount:55,source:.practice);change.skillTreeLessonID=lesson.id
        state.enqueue(change);XCTAssertTrue(state.lessonWork!["es:lesson-a1-1"]!.ready(goal:50));XCTAssertEqual(state.lessonWork!["es:lesson-a1-1"]!.fraction(goal:50),1)
        XCTAssertTrue(state.complete(lesson));XCTAssertEqual(state.lessonWork?["es:lesson-a1-1"]?.status,.completed);XCTAssertEqual(state.lessonWork?["es:lesson-a1-1"]?.earnedXP,50)
        XCTAssertFalse(state.beginLessonWork(lesson));state.enqueue(change);XCTAssertEqual(state.lessonWork?["es:lesson-a1-1"]?.earnedXP,50)
    }
    func testWebCountersAndInFlightLocalWorkRebaseWithoutUsingLegacyXP() {
        let fields:[String:Any] = ["progress":["targetLang":"es","languageLessons":["es":[lesson.id:["status":"in_progress","earnedXp":17,"xpEarned":100,"lessonStartXp":800]]]]]
        var sent=WebProgressContract.imported(fields);sent.level="A1"
        XCTAssertEqual(sent.lessonWork?["es:"+lesson.id]?.earnedXP,17)
        var current=sent;current.award(6,lesson:lesson)
        var remote=sent;remote.lessonWork?["es:"+lesson.id]?.earnedXP=22
        let rebased=LearnerState.rebased(current:current,sent:sent,acknowledged:remote)
        XCTAssertEqual(rebased.lessonWork?["es:"+lesson.id]?.earnedXP,28)
        XCTAssertEqual(rebased.pendingChanges?.last?.skillTreeLessonLevel,"A1")
        var unrelated=LearnerState();unrelated.importLessonWork(["status":"locked","earnedXp":10],id:lesson.id,target:"es")
        XCTAssertNil(unrelated.lessonWork)
    }
}
