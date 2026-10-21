import XCTest
@testable import Piyali
@MainActor final class FinalQuizTests:XCTestCase {
    func testOrdinarySkillFlagsCannotBypassTheQuizAndRewardRemainsOnceOnly() throws {
        let lessons=try ContentLibrary.load([String:[LearningUnit]].self,name:"curriculum-es"),lesson=try XCTUnwrap(lessons["Pre-A1"]?.flatMap(\.lessons).first { $0.isFinalQuiz == true })
        let app=AppModel();app.learner=LearnerState();app.learner.practicedModes=[app.learner.modeKey(lesson.id,"Grammar"),app.learner.modeKey(lesson.id,"Vocabulary")]
        XCTAssertFalse(app.canComplete(lesson));app.complete(lesson);XCTAssertEqual(app.learner.totalXP,0)
        var run=FinalQuizRun(lesson:lesson,learner:app.learner);run.answers=Array(repeating:true,count:8);app.learner.saveQuiz(run)
        XCTAssertTrue(app.canComplete(lesson));app.complete(lesson);let xp=app.learner.totalXP;XCTAssertEqual(xp,lesson.xpReward);app.complete(lesson);XCTAssertEqual(app.learner.totalXP,xp)
    }
}
