import XCTest

@MainActor final class ReadingPlayTests:XCTestCase {
    private func reveal(_ element:XCUIElement,in app:XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout:10))
        for _ in 0..<10 { if element.isHittable { break };if element.frame.minY < app.frame.minY+90 { app.swipeDown(velocity:.slow) } else { app.swipeUp(velocity:.slow) } }
        XCTAssertTrue(element.isHittable)
    }
    private func open(_ app:XCUIApplication) {
        XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));app.buttons["productMenu"].tap();app.buttons["productModeMenu"].tap();app.buttons["productMode-path"].tap()
        XCTAssertTrue(app.buttons["introLink"].waitForExistence(timeout:15));app.buttons["introLink"].tap();app.buttons["startLessonFromPreview"].tap()
        for _ in 0..<2 { if app.buttons["introStep-reading"].value as? String == "Current" { break };tap("skipLessonActivity",app) }
        XCTAssertTrue(app.descendants(matching:.any)["readingPassage"].waitForExistence(timeout:15));XCTAssertFalse(app.pickers["readingMethod"].exists)
    }
    private func tap(_ id:String,_ app:XCUIApplication) { let button=app.buttons[id];reveal(button,in:app);button.tap() }
    func testWrongAnswerRetryResumeAndOneReward() {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_READING_FIXTURE"]="1";app.launchEnvironment["PIYALI_PRACTICE_FIXTURE"]="delight:natural_or_weird"
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Reading Learner");if app.buttons["entryKeyboardDone"].exists { app.buttons["entryKeyboardDone"].tap() };app.buttons["createAccount"].tap()
        XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:20));app.buttons["startLearning"].tap();open(app)
        let initial=XCTAttachment(screenshot:app.screenshot());initial.name="Native reading passage and sentence audio";initial.lifetime = .keepAlways;add(initial)
        tap("readingTranslate",app);let line=app.staticTexts["readingTranslation-0"];reveal(line,in:app);XCTAssertEqual(line.label,"My green notebook is near the window.")
        tap("readingOption-1",app);tap("readingCheck",app);let feedback=app.staticTexts["readingFeedback"];reveal(feedback,in:app);XCTAssertEqual(feedback.label,"Not quite.");tap("readingExplain",app);let explanation=app.staticTexts["readingExplanation"];reveal(explanation,in:app);XCTAssertTrue(explanation.label.contains("remember the plan"))
        app.terminate();app.launch();open(app);tap("readingTranslate",app);reveal(line,in:app);XCTAssertEqual(line.label,"My green notebook is near the window.")
        tap("readingOption-0",app);tap("readingCheck",app);let completed=app.staticTexts["readingCompleted"];reveal(completed,in:app);let saved=completed.label;XCTAssertTrue(saved.contains("XP awarded:"))
        let result=XCTAttachment(screenshot:app.screenshot());result.name="Native reading correct answer and handoff";result.lifetime = .keepAlways;add(result)
        app.terminate();app.launch();open(app);reveal(completed,in:app);XCTAssertEqual(completed.label,saved);XCTAssertFalse(app.buttons["readingCheck"].exists)
        tap("readingContinue",app);XCTAssertEqual(app.buttons["introStep-stories"].value as? String,"Current")
    }
}
