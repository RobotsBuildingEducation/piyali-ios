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
    private func speechApp(failure:Bool=false)->XCUIApplication {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_READING_FIXTURE"]="1";app.launchEnvironment["PIYALI_READING_SPEECH_FIXTURE"]="1";app.launchEnvironment["PIYALI_PRACTICE_FIXTURE"]="delight:natural_or_weird"
        if failure { app.launchEnvironment["PIYALI_READING_SPEECH_FAILURE"]="1" }
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Speech Reader");if app.buttons["entryKeyboardDone"].exists { app.buttons["entryKeyboardDone"].tap() };app.buttons["createAccount"].tap()
        XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:20));app.buttons["startLearning"].tap();open(app);return app
    }
    private func spokenFragment(_ app:XCUIApplication) {
        tap("readingMicrophone",app);tap("readingMicrophone",app)
        XCTAssertTrue(app.staticTexts["readingSpeechTranscript"].waitForExistence(timeout:5));XCTAssertTrue(app.buttons["readingSpeechStartOver"].exists)
    }
    func testSpeechTranscriptResumeStartOverSixCardsAndSingleRewardHandoff() {
        let app=speechApp();spokenFragment(app)
        let transcript=app.staticTexts["readingSpeechTranscript"].label
        app.terminate();app.launch();open(app);XCTAssertEqual(app.staticTexts["readingSpeechTranscript"].label,transcript)
        tap("readingSpeechStartOver",app);XCTAssertFalse(app.staticTexts["readingSpeechTranscript"].exists);spokenFragment(app)
        tap("readingMicrophone",app);let completed=app.staticTexts["readingCompleted"];XCTAssertTrue(completed.waitForExistence(timeout:10));let reward=completed.value as? String
        XCTAssertEqual(app.staticTexts["readingSpeechTotal"].label,"29/60");XCTAssertTrue(app.staticTexts["readingSpeechSummary"].label.contains("remaining sentences"))
        let top=XCTAttachment(screenshot:app.screenshot());top.name="Native reading speech summary and total";top.lifetime = .keepAlways;add(top)
        for key in ["accuracy","completeness","pronunciation","fluency","confidence","comprehension"] { XCTAssertTrue(app.descendants(matching:.any)["readingSpeechScore-"+key].exists) }
        let last=app.staticTexts["Try the rest of the paragraph to show more understanding."],scroll=app.scrollViews["activityFeedbackScroll"]
        for _ in 0..<8 { if last.isHittable { break };scroll.swipeUp(velocity:.slow) };XCTAssertTrue(last.isHittable)
        let bottom=XCTAttachment(screenshot:app.screenshot());bottom.name="Native reading six speech criteria";bottom.lifetime = .keepAlways;add(bottom)
        app.terminate();var arguments=app.launchArguments;if let index=arguments.firstIndex(of:"-piyali.theme") { arguments[index+1]="dark" };app.launchArguments=arguments;app.launch();open(app);XCTAssertEqual(app.staticTexts["readingSpeechTotal"].label,"29/60");XCTAssertEqual(completed.value as? String,reward);XCTAssertFalse(app.buttons["readingMicrophone"].exists)
        let dark=XCTAttachment(screenshot:app.screenshot());dark.name="Native reading speech feedback dark";dark.lifetime = .keepAlways;add(dark)
        tap("readingContinue",app);XCTAssertEqual(app.buttons["introStep-stories"].value as? String,"Current")
    }
    func testSpeechReviewOutageStillCompletesPracticeWithoutScoreCards() {
        let app=speechApp(failure:true);spokenFragment(app);tap("readingMicrophone",app)
        XCTAssertTrue(app.staticTexts["readingCompleted"].waitForExistence(timeout:10));XCTAssertEqual(app.staticTexts["readingSpeechSummary"].label,"Could not generate feedback. Keep practicing!");XCTAssertFalse(app.staticTexts["readingSpeechTotal"].exists)
        app.terminate();app.launch();open(app);XCTAssertTrue(app.staticTexts["readingCompleted"].exists);XCTAssertFalse(app.buttons["readingMicrophone"].exists);tap("readingContinue",app)
        XCTAssertEqual(app.buttons["introStep-stories"].value as? String,"Current")
    }
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
