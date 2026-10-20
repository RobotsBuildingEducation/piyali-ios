import XCTest

@MainActor final class ReadingPlayTests:XCTestCase {
    private func reveal(_ element:XCUIElement,in app:XCUIApplication) {
        for _ in 0..<8 where !element.exists || !element.isHittable { app.swipeUp(velocity:.slow) }
        XCTAssertTrue(element.waitForExistence(timeout:10));XCTAssertTrue(element.isHittable)
    }
    private func open(_ app:XCUIApplication) { app.tabBars.buttons["Practice"].tap();let link=app.buttons["readingLink"];reveal(link,in:app);link.tap();XCTAssertTrue(app.staticTexts["readingPassage"].waitForExistence(timeout:15)) }
    private func tap(_ id:String,_ app:XCUIApplication) { let button=app.buttons[id];reveal(button,in:app);button.tap() }
    func testWrongAnswerRetryResumeAndOneReward() {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_READING_FIXTURE"]="1";app.launch()
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:10));app.buttons["createAccount"].tap()
        XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:15));app.buttons["startLearning"].tap();open(app)
        tap("readingOption-1",app);tap("readingCheck",app);let feedback=app.staticTexts["readingFeedback"];reveal(feedback,in:app);XCTAssertTrue(feedback.label.contains("try another"))
        app.terminate();app.launch();open(app)
        tap("readingOption-0",app);tap("readingCheck",app);let completed=app.staticTexts["readingCompleted"];reveal(completed,in:app);let saved=completed.label;XCTAssertTrue(saved.contains("XP saved"))
        app.terminate();app.launch();open(app);reveal(completed,in:app);XCTAssertEqual(completed.label,saved);XCTAssertFalse(app.buttons["readingCheck"].exists)
    }
}
