import XCTest

@MainActor final class FinalQuizPlayTests:XCTestCase {
    private let node="lessonNode-lesson-a1-5-quiz"
    private func reveal(_ element:XCUIElement,in app:XCUIApplication) { for _ in 0..<12 where !element.isHittable { app.swipeUp(velocity:.slow) };XCTAssertTrue(element.waitForExistence(timeout:5));XCTAssertTrue(element.isHittable) }
    private func tap(_ id:String,_ app:XCUIApplication) { let element=app.buttons[id];reveal(element,in:app);element.tap() }
    private func path(_ app:XCUIApplication) { tap("productMenu",app);tap("productModeMenu",app);tap("productMode-path",app) }
    private func open(_ app:XCUIApplication) { path(app);tap(node,app);tap("startLessonFromPreview",app);XCTAssertTrue(app.staticTexts["quizProgress"].waitForExistence(timeout:10)) }
    private func answer(_ correct:Bool,_ app:XCUIApplication) { tap(correct ? "typedChoice-0" : "typedChoice-1",app);tap("checkTypedAnswer",app) }
    func testTypedQuizEarlyFailureRetryResumePassAndReviewDoNotAwardQuestionXPOrAnotherBonus() {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_PRACTICE_FIXTURE"]="delight:natural_or_weird"
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Quiz Learner");if app.buttons["entryKeyboardDone"].exists { app.buttons["entryKeyboardDone"].tap() };tap("createAccount",app);tap("startLearning",app)
        tap("companionContinue",app);tap("gettingStartedGotIt",app)
        tap("placementFindLevel",app);let common=app.buttons["placementOption-common_words"];XCTAssertTrue(common.waitForExistence(timeout:5));common.tap();XCTAssertEqual(common.value as? String,"Selected");tap("placementNext",app);tap("placementNext",app);tap("placementStart",app)
        open(app)
        for count in 1...3 {
            answer(false,app)
            if count < 3 { XCTAssertEqual(app.staticTexts["quizProgress"].label,"\(count)/10");XCTAssertFalse(app.buttons["checkTypedAnswer"].exists);XCTAssertFalse(app.buttons["typedChoice-0"].isEnabled);XCTAssertFalse(app.buttons["skipLessonActivity"].exists);tap("nextTypedQuestion",app) }
        }
        XCTAssertTrue(app.staticTexts["quizResult"].waitForExistence(timeout:5));XCTAssertEqual(app.staticTexts["quizResult"].label,"Quiz Not Passed");XCTAssertFalse(app.buttons["quizComplete"].exists)
        let failed=XCTAttachment(screenshot:app.screenshot());failed.name="Native typed quiz early failure";failed.lifetime = .keepAlways;add(failed)
        tap("quizRetry",app)
        for count in 1...3 { answer(true,app);XCTAssertEqual(app.staticTexts["quizProgress"].label,"\(count)/10");XCTAssertFalse(app.staticTexts["practiceVerdict"].label.contains("XP"));if count < 3 { tap("nextTypedQuestion",app) } }
        app.terminate();app.launch();open(app);XCTAssertEqual(app.staticTexts["quizProgress"].label,"3/10");tap("nextTypedQuestion",app)
        for count in 4...8 { answer(true,app);if count < 8 { tap("nextTypedQuestion",app) } }
        XCTAssertTrue(app.staticTexts["quizResult"].waitForExistence(timeout:5));XCTAssertEqual(app.staticTexts["quizResult"].label,"Quiz Passed!")
        let passed=XCTAttachment(screenshot:app.screenshot());passed.name="Native typed quiz early pass";passed.lifetime = .keepAlways;add(passed)
        tap("quizExit",app);XCTAssertTrue(app.staticTexts["lessonCompletionBonus"].waitForExistence(timeout:10));XCTAssertEqual(app.staticTexts["lessonCompletionBonus"].label,"+60");tap("continueLessonCompletion",app)
        tap(node,app);tap("startLessonFromPreview",app);XCTAssertTrue(app.staticTexts["quizProgress"].waitForExistence(timeout:10));XCTAssertEqual(app.staticTexts["quizProgress"].label,"0/10")
        for count in 1...8 { answer(true,app);if count < 8 { tap("nextTypedQuestion",app) } }
        tap("quizExit",app);XCTAssertTrue(app.buttons[node].waitForExistence(timeout:10));XCTAssertFalse(app.staticTexts["lessonCompletionBonus"].exists)
    }
}
