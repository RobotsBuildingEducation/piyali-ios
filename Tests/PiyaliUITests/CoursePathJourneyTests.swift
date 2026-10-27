import XCTest
@MainActor final class CoursePathJourneyTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication){let e=app.buttons[id];XCTAssertTrue(e.waitForExistence(timeout:15));for _ in 0..<18 where !e.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(e.isHittable);e.tap()}
    private func path(_ app:XCUIApplication){tap("productMenu",app);tap("productModeMenu",app);tap("productMode-path",app)}
    private func launch()->XCUIApplication {let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_HEADLINE_FIXTURE":"failure"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch();let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Course Learner");tap("entryKeyboardDone",app);tap("createAccount",app);tap("startLearning",app);tap("companionContinue",app);tap("gettingStartedGotIt",app);return app}
    func testBeginnerPlacementKeepsNextLevelAndFirstRegularLessonLockedAcrossRelaunch(){
        continueAfterFailure=false;let app=launch();tap("placementNew",app);path(app)
        let first=app.buttons["lessonNode-lesson-pre-a1-1-1"],next=app.buttons["lessonNextLevel"],intro=app.buttons["introLink"]
        XCTAssertTrue(intro.waitForExistence(timeout:10));XCTAssertTrue(intro.isEnabled);XCTAssertTrue(next.exists);XCTAssertFalse(next.isEnabled);XCTAssertFalse(app.buttons["lessonPreviousLevel"].exists)
        for _ in 0..<4 where !first.exists{app.swipeUp(velocity:.slow)};XCTAssertTrue(first.exists);XCTAssertFalse(first.isEnabled);XCTAssertEqual(first.value as? String,"locked")
        let a=XCTAttachment(screenshot:app.screenshot());a.name="Native beginner sequential course";a.lifetime = .keepAlways;add(a)
        app.terminate();app.launch();path(app);XCTAssertTrue(intro.waitForExistence(timeout:10));XCTAssertTrue(intro.isEnabled);XCTAssertFalse(app.buttons["lessonNextLevel"].isEnabled)
        tap("introLink",app);XCTAssertTrue(app.buttons["startLessonFromPreview"].waitForExistence(timeout:5));tap("closeLessonPreview",app);XCTAssertTrue(intro.waitForExistence(timeout:5));XCTAssertFalse(app.staticTexts["lessonCompletionBonus"].exists)
        tap("introLink",app);tap("startLessonFromPreview",app);XCTAssertTrue(app.buttons["introStep-vocabulary"].waitForExistence(timeout:10));let back=app.navigationBars.buttons.element(boundBy:0);XCTAssertTrue(back.waitForExistence(timeout:5));back.tap();XCTAssertTrue(intro.waitForExistence(timeout:5))
    }
    func testSelfReportedA1CanReviewBeginnerCourseWithoutCompletionCredit(){
        continueAfterFailure=false;let app=launch();chooseA1Placement(app);path(app);tap("lessonPreviousLevel",app)
        XCTAssertTrue(app.buttons["lessonNextLevel"].waitForExistence(timeout:10));XCTAssertTrue(app.buttons["lessonNextLevel"].isEnabled)
        let first=app.buttons["lessonNode-lesson-pre-a1-1-1"];for _ in 0..<4 where !first.exists{app.swipeUp(velocity:.slow)};XCTAssertTrue(first.exists);XCTAssertTrue(first.isEnabled);XCTAssertEqual(first.value as? String,"available")
        tap("lessonNode-lesson-pre-a1-1-1",app);XCTAssertTrue(app.buttons["startLessonFromPreview"].waitForExistence(timeout:5));tap("startLessonFromPreview",app);let back=app.navigationBars.buttons.element(boundBy:0);XCTAssertTrue(back.waitForExistence(timeout:10));back.tap();XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:5));app.terminate();app.launch();path(app);XCTAssertTrue(app.buttons["introLink"].waitForExistence(timeout:10));XCTAssertEqual(app.buttons["introLink"].value as? String,"available");XCTAssertFalse(app.staticTexts["lessonCompletionBonus"].exists)
    }
}
// Legitimate source self-report, used by activity-specific tests that need course access.
@MainActor func chooseA1Placement(_ app:XCUIApplication){
    func tap(_ id:String){let b=app.buttons[id];XCTAssertTrue(b.waitForExistence(timeout:10));for _ in 0..<5 where !b.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(b.isHittable);b.tap()}
    tap("placementFindLevel");tap("placementOption-common_words");tap("placementNext");tap("placementNext");tap("placementStart")
}
@MainActor func openPlacedBeginnerCourse(_ app:XCUIApplication){
    let previous=app.buttons["lessonPreviousLevel"];if previous.waitForExistence(timeout:3),previous.isHittable{previous.tap()}
}
