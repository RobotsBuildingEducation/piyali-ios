import XCTest

@MainActor final class StoryPlayTests:XCTestCase {
    private func reveal(_ element:XCUIElement,_ app:XCUIApplication) {
        for _ in 0..<12 {
            let tile=element.exists && (element.identifier.hasPrefix("storyOption-") || element.identifier.hasPrefix("storySelected-"))
            let submit=app.buttons["storyCheck"]
            let covered=tile && submit.exists && element.frame.maxY > submit.frame.minY-12
            if element.exists,element.isHittable,!covered { break }
            if element.exists,element.frame.minY < app.frame.minY+90 { app.swipeDown(velocity:.slow) } else { app.swipeUp(velocity:.slow) }
        }
        XCTAssertTrue(element.waitForExistence(timeout:10));XCTAssertTrue(element.isHittable)
    }
    private func tap(_ id:String,_ app:XCUIApplication) { let button=app.buttons[id];reveal(button,app);button.tap() }
    private func start(_ mode:String,role:Bool=false,failure:Bool=false,theme:String="light")->XCUIApplication {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_STORY_FIXTURE"]=mode;app.launchEnvironment["PIYALI_PRACTICE_FIXTURE"]="delight:natural_or_weird";app.launchEnvironment["PIYALI_READING_FIXTURE"]="1";app.launchEnvironment["PIYALI_STORY_SPEECH_RESULTS"]="miss,pass,pass,pass"
        if role { app.launchEnvironment["PIYALI_STORY_LEARNER_CAST"]="1" };if failure { app.launchEnvironment["PIYALI_STORY_AUDIO_FAIL_FIRST"]="1" }
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme",theme];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Story Learner");if app.buttons["entryKeyboardDone"].exists { app.buttons["entryKeyboardDone"].tap() };app.buttons["createAccount"].tap()
        XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:20));app.buttons["startLearning"].tap();open(app);return app
    }
    private func open(_ app:XCUIApplication,expectStory:Bool=true) {
        XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));app.buttons["productMenu"].tap();app.buttons["productModeMenu"].tap();app.buttons["productMode-path"].tap()
        XCTAssertTrue(app.buttons["introLink"].waitForExistence(timeout:15));app.buttons["introLink"].tap();app.buttons["startLessonFromPreview"].tap()
        for _ in 0..<3 { if app.buttons["introStep-stories"].value as? String == "Current" || app.buttons["introStep-realtime"].value as? String == "Current" { break };tap("skipLessonActivity",app) }
        if expectStory { XCTAssertTrue(app.staticTexts["storyProgress"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["storyRead"].exists);XCTAssertFalse(app.textFields["storyTypedAnswer"].exists) }
    }
    private func photo(_ name:String,_ app:XCUIApplication) { let shot=XCTAttachment(screenshot:app.screenshot());shot.name=name;shot.lifetime = .keepAlways;add(shot) }
    private func option(_ word:String,_ app:XCUIApplication) { let button=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'storyOption-' AND label == %@",word)).firstMatch;reveal(button,app);button.tap();if !button.isSelected { XCTFail("A visible word or answer tap must select it: "+app.debugDescription) } }
    private func record(_ app:XCUIApplication) { tap("storyRecord",app);tap("storyRecord",app);XCTAssertTrue(app.staticTexts["storySpeechFeedback"].waitForExistence(timeout:5)) }
    private func xp(_ amount:Int,_ app:XCUIApplication) {
        tap("productMenu",app);tap("productPanel-settings",app)
        let total=app.staticTexts.matching(NSPredicate(format:"label BEGINSWITH %@","\(amount) total XP")).firstMatch;reveal(total,app);XCTAssertTrue(total.label.hasPrefix("\(amount) total XP"));tap("productPanelClose",app)
    }
    func testRadioFailureRetryOneAttemptResumeAutoPlaybackAndOneSixXPCompletion() {
        let app=start("radio",failure:true)
        XCTAssertTrue(app.buttons["storyPlay"].isHittable,"The primary action is fixed in the viewport");XCTAssertFalse(app.staticTexts["storyQuestion"].exists);photo("Native source radio ready with fixed action footer",app)
        tap("storyPlay",app);XCTAssertTrue(app.staticTexts["storyAudioError"].waitForExistence(timeout:5));XCTAssertFalse(app.staticTexts["storyQuestion"].exists)
        tap("storyPlay",app);XCTAssertTrue(app.staticTexts["storyQuestion"].waitForExistence(timeout:5));option("His friend",app);tap("storyCheck",app)
        XCTAssertTrue(app.staticTexts["storyFeedback"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["storyFeedback"].label.contains("Not quite"));XCTAssertFalse(app.buttons["storyCheck"].exists)
        tap("productMenu",app);tap("productMenuClose",app);XCTAssertTrue(app.buttons["storyNext"].isHittable);photo("Native radio answer feedback and shared menu slot",app)
        app.terminate();app.launchEnvironment.removeValue(forKey:"PIYALI_STORY_AUDIO_FAIL_FIRST");app.launch();open(app);XCTAssertTrue(app.staticTexts["storyFeedback"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["storyFeedback"].label.contains("Not quite"));tap("storyNext",app)
        XCTAssertTrue(app.staticTexts["Build what you hear."].waitForExistence(timeout:5));for word in ["Sí","es","hoy"] { option(word,app) };tap("storyCheck",app);XCTAssertTrue(app.staticTexts["storyFeedback"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["storyFeedback"].label.contains("right"));photo("Native radio ordered words and source progress feedback",app);tap("storyNext",app)
        XCTAssertTrue(app.staticTexts["Select two words you hear."].waitForExistence(timeout:5));option("pastel",app);XCTAssertFalse(app.buttons["storyCheck"].isEnabled);option("tengo",app);tap("storyCheck",app);tap("storyNext",app)
        XCTAssertTrue(app.staticTexts["realtimeGoal"].waitForExistence(timeout:10));xp(6,app);XCTAssertFalse(app.buttons["storyNext"].exists)
        app.terminate();app.launch();open(app,expectStory:false);XCTAssertTrue(app.staticTexts["realtimeGoal"].waitForExistence(timeout:10));xp(6,app)
    }
    func testSpeakingUsesRecordRetryAndResumesEachTwoXPLineBeforeHandoff() {
        let app=start("speaking");XCTAssertTrue(app.staticTexts["storyTarget"].exists);XCTAssertTrue(app.buttons["storyRecord"].isHittable);photo("Native source speaking story before recording",app)
        record(app);XCTAssertTrue(app.staticTexts["storySpeechFeedback"].label.contains("Try again"));XCTAssertFalse(app.buttons["storyNext"].exists)
        record(app);XCTAssertTrue(app.staticTexts["storySpeechXP"].waitForExistence(timeout:5));XCTAssertEqual(app.staticTexts["storySpeechXP"].label,"+2 XP");XCTAssertFalse(app.buttons["storyRecord"].exists)
        app.terminate();app.launchEnvironment["PIYALI_STORY_SPEECH_RESULTS"]="pass";app.launch();open(app);XCTAssertTrue(app.staticTexts["storySpeechXP"].waitForExistence(timeout:5));XCTAssertEqual(app.staticTexts["storySpeechXP"].label,"+2 XP");xp(2,app);tap("storyNext",app)
        record(app);XCTAssertEqual(app.staticTexts["storySpeechXP"].label,"+2 XP");photo("Native speaking result with one saved line reward",app);tap("storyNext",app)
        XCTAssertTrue(app.staticTexts["realtimeGoal"].waitForExistence(timeout:10));xp(4,app)
        app.terminate();app.launch();open(app,expectStory:false);XCTAssertTrue(app.staticTexts["realtimeGoal"].waitForExistence(timeout:10));xp(4,app)
    }
    func testConversationKeepsEarlierPairsAndRequiresUserSpeechWithoutTurnXP() {
        let app=start("conversation",role:true,theme:"dark")
        tap("storyTranslate-0-0",app);XCTAssertTrue(app.staticTexts["I have red flowers."].exists);XCTAssertFalse(app.staticTexts["storyQuestion"].exists)
        tap("storyPlay",app);XCTAssertTrue(app.staticTexts["storyRoleTarget"].waitForExistence(timeout:5));XCTAssertFalse(app.staticTexts["storyQuestion"].exists);photo("Native source conversation waits for the learner",app)
        record(app);XCTAssertFalse(app.staticTexts["storyQuestion"].exists);tap("storySpeechRetry",app);record(app);XCTAssertTrue(app.buttons["storyNext"].waitForExistence(timeout:5));tap("storyNext",app)
        XCTAssertTrue(app.staticTexts["storyQuestion"].waitForExistence(timeout:5));xp(0,app);option("His mother",app);tap("storyCheck",app);tap("storyNext",app)
        XCTAssertTrue(app.staticTexts["storyRoleTarget"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["storyDialogue-0-0"].exists,"Earlier dialogue remains available for review");XCTAssertFalse(app.staticTexts["Build what you hear."].exists)
        app.terminate();app.launch();open(app);tap("storyPlay",app);XCTAssertTrue(app.staticTexts["storyRoleTarget"].waitForExistence(timeout:5));XCTAssertFalse(app.staticTexts["storyQuestion"].exists);xp(0,app)
        tap("skipLessonActivity",app);XCTAssertTrue(app.staticTexts["realtimeGoal"].waitForExistence(timeout:10));xp(0,app)
    }
}
