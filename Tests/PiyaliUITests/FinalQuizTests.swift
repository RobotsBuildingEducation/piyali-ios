import XCTest
@MainActor final class FinalQuizPlayTests:XCTestCase {
    private func reveal(_ element:XCUIElement,in app:XCUIApplication) {
        for _ in 0..<10 where !element.exists || !element.isHittable { app.swipeUp(velocity:.slow) }
        XCTAssertTrue(element.waitForExistence(timeout:10));XCTAssertTrue(element.isHittable)
    }
    private func tap(_ id:String,_ app:XCUIApplication) { let button=app.buttons[id];reveal(button,in:app);button.tap() }
    private func open(_ app:XCUIApplication) {
        app.tabBars.buttons["Learn"].tap();tap("People & Family",app);tap("People & Family Quiz",app);tap("finalQuizLink",app)
        XCTAssertTrue(app.navigationBars["Final quiz"].waitForExistence(timeout:10))
    }
    private func answer(_ correct:Bool,_ app:XCUIApplication) { tap(correct ? "quizOption-0" : "quizOption-1",app);tap("quizCheck",app) }
    func testEarlyFailureRetryResumeEarlyPassAndOnceOnlyReward() {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_QUIZ_FIXTURE"]="1";app.launch()
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:10));app.buttons["createAccount"].tap();XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:15));app.buttons["startLearning"].tap();open(app)
        for index in 0..<3 { answer(false,app);if index<2 { tap("quizNext",app) } }
        let result=app.staticTexts["quizResult"];reveal(result,in:app);XCTAssertTrue(result.label.contains("try a new round"));XCTAssertFalse(app.buttons["quizComplete"].exists)
        tap("quizRetry",app)
        for _ in 0..<3 { answer(true,app);tap("quizNext",app) }
        app.terminate();app.launch();open(app)
        let progress=app.staticTexts["quizProgress"];reveal(progress,in:app);XCTAssertTrue(progress.label.contains("3 correct"));XCTAssertTrue(progress.label.contains("3/10"))
        for index in 3..<8 { answer(true,app);if index<7 { tap("quizNext",app) } }
        reveal(result,in:app);XCTAssertTrue(result.label.contains("passing score"));reveal(progress,in:app);XCTAssertTrue(progress.label.contains("8/10"))
        tap("quizComplete",app);XCTAssertFalse(app.buttons["quizComplete"].isEnabled)
        app.terminate();app.launch();open(app);let complete=app.buttons["quizComplete"];reveal(complete,in:app);XCTAssertFalse(complete.isEnabled);XCTAssertTrue(complete.label.contains("already completed"));XCTAssertFalse(app.buttons["quizCheck"].exists)
    }
}
