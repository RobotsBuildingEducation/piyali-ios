import XCTest

@MainActor final class GuidedPracticeJourneyTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication){let button=app.buttons[id];XCTAssertTrue(button.waitForExistence(timeout:20),id);XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:button)],timeout:20),.completed,id);for _ in 0..<4 where !button.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(button.isHittable,id);button.tap()}
    private func photo(_ name:String,_ app:XCUIApplication){let shot=XCTAttachment(screenshot:app.screenshot());shot.name=name;shot.lifetime = .keepAlways;add(shot)}
    private func launch(_ scenario:String)->XCUIApplication {
        continueAfterFailure=false;let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_TUTOR_FIXTURE":"1","PIYALI_FLASHCARD_FIXTURE":"1","PIYALI_PLATE_JOURNEY_FIXTURE":scenario,"PIYALI_CONVERSATION_FIXTURE":scenario == "conversation" ? "1":"0"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Quest Learner");if app.buttons["entryKeyboardDone"].exists{app.buttons["entryKeyboardDone"].tap()};tap("createAccount",app);tap("startLearning",app);return app
    }
    private func completeTutor(_ app:XCUIApplication){
        tap("startDailyPractice",app);photo("Native daily practice route",app);XCTAssertTrue(app.staticTexts["tutorLessonTitle"].waitForExistence(timeout:15));tap("tutorStart",app)
        XCTAssertTrue(app.buttons["tutorCompletionContinue"].waitForExistence(timeout:40));photo("Native guided Tutor result",app);tap("tutorCompletionContinue",app)
        XCTAssertTrue(app.buttons["dailyGoalRewardContinue"].waitForExistence(timeout:10));photo("Native guided daily goal reward",app);XCTAssertFalse(app.buttons["tutorReviewContinue"].isHittable);tap("dailyGoalRewardContinue",app)
        tap("tutorReviewContinue",app);XCTAssertTrue(app.buttons["guidedContinue"].waitForExistence(timeout:10));photo("Native guided Tutor quest complete",app)
    }
    func testDailyPracticeCompletesTutorLessonAndFinalReviewThenNotesAndRelaunch(){
        let app=launch("full");completeTutor(app);tap("guidedContinue",app)
        tap("lessonNode-lesson-pre-a1-1-1",app);tap("startLessonFromPreview",app);XCTAssertTrue(app.staticTexts["lessonCompletionBonus"].waitForExistence(timeout:15));XCTAssertEqual(app.staticTexts["lessonCompletionBonus"].label,"+80");tap("continueLessonCompletion",app)
        XCTAssertTrue(app.buttons["guidedContinue"].waitForExistence(timeout:10));photo("Native guided lesson quest complete",app);tap("guidedContinue",app)
        tap("flashcardTile-pre-a1-people-1",app);let answer=app.textFields["flashcardAnswer"];XCTAssertTrue(answer.waitForExistence(timeout:10));answer.tap();answer.typeText("mamá\n");tap("flashcardRate-hard",app)
        XCTAssertTrue(app.buttons["plateViewNotes"].waitForExistence(timeout:10));photo("Native all daily quests complete",app);XCTAssertTrue(app.staticTexts["+25"].exists);tap("plateViewNotes",app);tap("productPanelClose",app);XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:10));XCTAssertFalse(app.buttons["guidedContinue"].exists)
        app.terminate();app.launch();XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["guidedContinue"].exists);XCTAssertFalse(app.buttons["dailyGoalRewardContinue"].exists);photo("Native completed daily quest after relaunch",app)
    }
    func testConversationCourseCompletionStopsLiveCallBeforeContinuingToReview(){
        let app=launch("conversation");tap("startDailyPractice",app);XCTAssertTrue(app.staticTexts["conversationGoal"].waitForExistence(timeout:15));tap("conversationStart",app)
        XCTAssertTrue(app.buttons["guidedContinue"].waitForExistence(timeout:25));XCTAssertFalse(app.buttons["conversationSummaryDone"].exists);XCTAssertFalse(app.buttons["conversationEnd"].exists);photo("Native guided conversation stopped at course completion",app)
        tap("guidedContinue",app);XCTAssertTrue(app.buttons["flashcardTile-pre-a1-people-1"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["conversationSummaryDone"].exists)
    }
    func testTutorDailyGoalReviewAndCourseCelebrationSurviveRootTrialLimit(){
        let app=launch("tutor-trial");completeTutor(app);tap("guidedContinue",app)
        XCTAssertTrue(app.buttons["Refresh subscription"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["tutorStart"].isHittable);photo("Native subscription after earned quest sequence",app)
        app.terminate();app.launch();XCTAssertTrue(app.buttons["Refresh subscription"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["guidedContinue"].exists)
    }
}
