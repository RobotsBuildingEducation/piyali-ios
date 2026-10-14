import XCTest

@MainActor final class StoryPlayTests:XCTestCase {
    private func reveal(_ element:XCUIElement,in app:XCUIApplication) {
        for _ in 0..<6 where !element.exists || !element.isHittable { app.swipeUp(velocity:.slow) }
        XCTAssertTrue(element.waitForExistence(timeout:10));XCTAssertTrue(element.isHittable)
    }
    private func start(_ mode:String) -> XCUIApplication {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_STORY_FIXTURE"]=mode;app.launch()
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:10));app.buttons["createAccount"].tap()
        XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:15));app.buttons["startLearning"].tap();open(app);return app
    }
    private func open(_ app:XCUIApplication) { app.tabBars.buttons["Practice"].tap();let link=app.buttons["storiesLink"];reveal(link,in:app);link.tap();XCTAssertTrue(app.staticTexts["storyProgress"].waitForExistence(timeout:15)) }
    private func tap(_ id:String,_ app:XCUIApplication) { let button=app.buttons[id];reveal(button,in:app);button.tap() }
    func testListeningSelectionAndWordOrderResumeAndAwardSixOnce() {
        let app=start("radio");tap("storyRead",app);tap("storyOption-0",app);tap("storyCheck",app)
        XCTAssertEqual(app.staticTexts["storyFeedback"].label,"Try this");tap("storyNext",app)
        tap("storyRead",app);for option in [2,0,1] { tap("storyOption-"+String(option),app) };tap("storyCheck",app)
        XCTAssertEqual(app.staticTexts["storyFeedback"].label,"Correct")
        app.terminate();app.launch();open(app);tap("storyNext",app);tap("storyFinish",app)
        XCTAssertTrue(app.staticTexts["storyCompleted"].waitForExistence(timeout:10));XCTAssertTrue(app.staticTexts["storyCompleted"].label.contains("6 XP"))
        app.terminate();app.launch();open(app);XCTAssertTrue(app.staticTexts["storyCompleted"].exists);XCTAssertFalse(app.buttons["storyFinish"].exists)
        app.tabBars.buttons["Account"].tap();let total=app.staticTexts.matching(NSPredicate(format:"label BEGINSWITH %@","6 total XP")).firstMatch;reveal(total,in:app)
    }
    func testSentenceMissRetryAndRelaunchRetainOneTwoXPReward() {
        let app=start("speaking");let target=app.staticTexts["storyTarget"].label
        let field=app.textFields["storyTypedAnswer"];reveal(field,in:app);field.tap();field.typeText("wrong phrase");tap("storyCheckTyped",app)
        let retry=app.buttons["Try line again"];reveal(retry,in:app);retry.tap();reveal(field,in:app);field.tap();field.typeText(target);tap("storyCheckTyped",app)
        XCTAssertTrue(app.staticTexts["storySpeechFeedback"].label.contains("+2 XP"))
        app.terminate();app.launch();open(app);XCTAssertTrue(app.staticTexts["storySpeechFeedback"].label.contains("+2 XP"));XCTAssertFalse(app.buttons["storyCheckTyped"].exists)
        tap("storyNext",app);tap("storySkip",app);tap("storyFinish",app)
        XCTAssertTrue(app.staticTexts["storyCompleted"].waitForExistence(timeout:10));XCTAssertTrue(app.staticTexts["storyCompleted"].label.contains("2 XP"))
        app.tabBars.buttons["Account"].tap();let total=app.staticTexts.matching(NSPredicate(format:"label BEGINSWITH %@","2 total XP")).firstMatch;reveal(total,in:app)
    }
}
