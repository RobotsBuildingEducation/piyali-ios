import XCTest

@MainActor final class ConversationPlayTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication) { let button=app.buttons[id];XCTAssertTrue(button.waitForExistence(timeout:15));XCTAssertTrue(button.isHittable);button.tap() }
    private func open(_ app:XCUIApplication) { tap("productMenu",app);tap("productModeMenu",app);tap("productMode-conversation",app);XCTAssertTrue(app.staticTexts["conversationGoal"].waitForExistence(timeout:15)) }
    private func start(theme:String="light")->XCUIApplication {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_CONVERSATION_FIXTURE"]="1";app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme",theme];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Conversation Learner");if app.buttons["entryKeyboardDone"].exists { app.buttons["entryKeyboardDone"].tap() };tap("createAccount",app);tap("startLearning",app);open(app);return app
    }
    private func photo(_ name:String,_ app:XCUIApplication) { let capture=XCTAttachment(screenshot:app.screenshot());capture.name=name;capture.lifetime = .keepAlways;add(capture) }
    func testVoiceFirstScreenHelpMutePauseResumeSummaryLogAndRelaunch() {
        let app=start()
        XCTAssertFalse(app.textFields["conversationReply"].exists);XCTAssertFalse(app.buttons["conversationSend"].exists);XCTAssertFalse(app.staticTexts["conversationLatestReply"].exists);XCTAssertFalse(app.buttons["conversationHistory"].isEnabled)
        photo("Native conversation initial light",app)
        tap("conversationStarter",app);XCTAssertTrue(app.staticTexts["conversationStarterPhrase"].waitForExistence(timeout:5));tap("conversationStarter",app);XCTAssertFalse(app.staticTexts["conversationStarterPhrase"].exists)
        tap("conversationStart",app);XCTAssertTrue(app.staticTexts["conversationFeedback"].waitForExistence(timeout:10))
        tap("conversationMute",app);tap("conversationPause",app);XCTAssertEqual(app.staticTexts["conversationVoiceStatus"].label,"Paused")
        photo("Native conversation paused controls",app)
        tap("conversationPause",app);XCTAssertTrue(app.buttons["conversationMute"].waitForExistence(timeout:5));XCTAssertEqual(app.staticTexts["conversationVoiceStatus"].label,"Muted")
        tap("conversationMute",app)
        let reply=app.staticTexts["conversationLatestReply"];let replied=NSPredicate(format:"label CONTAINS %@","¡Hola, Ana!");expectation(for:replied,evaluatedWith:reply);waitForExpectations(timeout:12)
        photo("Native conversation live reply",app)
        tap("conversationEnd",app);XCTAssertTrue(app.staticTexts["conversationSummaryXP"].waitForExistence(timeout:10));XCTAssertTrue(app.staticTexts["conversationSummaryXP"].label.contains("+5"));XCTAssertTrue(app.staticTexts["conversationSummaryGoals"].label.contains("1"));XCTAssertTrue(app.staticTexts["conversationSummaryTurns"].label.contains("2"))
        photo("Native conversation complete summary",app);tap("conversationSummaryDone",app)
        tap("conversationHistory",app);XCTAssertTrue(app.staticTexts["wrong topic"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["Hola, me llamo Ana."].exists);photo("Native conversation private history",app)
        tap("conversationSave",app);app.buttons["Done"].tap()
        app.terminate();app.launch();open(app);XCTAssertTrue(app.buttons["conversationStart"].exists);XCTAssertEqual(app.staticTexts["conversationLatestReply"].label,"¡Hola, Ana! ¿Qué te gusta hacer?")
        tap("productMenu",app);tap("productPanel-settings",app);let xp=app.staticTexts.matching(NSPredicate(format:"label BEGINSWITH %@","5 total XP")).firstMatch;for _ in 0..<6 where !xp.isHittable { app.swipeUp(velocity:.slow) };XCTAssertTrue(xp.waitForExistence(timeout:5))
    }
    func testSourceSettingsPersistAcrossDismissalAndDarkRelaunchWithoutStartingAudio() {
        let app=start();tap("conversationSettings",app)
        XCTAssertTrue(app.staticTexts["Proficiency Level"].exists);XCTAssertTrue(app.staticTexts["Pronunciation Practice"].exists);XCTAssertTrue(app.staticTexts["Custom Topics"].exists)
        tap("conversationLevel",app);let elementary=app.buttons.matching(NSPredicate(format:"label BEGINSWITH %@","A2 ·")).firstMatch;XCTAssertTrue(elementary.waitForExistence(timeout:5));elementary.tap()
        let toggle=app.switches["conversationPronunciation"];XCTAssertTrue(toggle.exists);toggle.tap()
        let topics=app.textViews["conversationTopics"].exists ? app.textViews["conversationTopics"] : app.textFields["conversationTopics"];topics.tap();topics.typeText("Travel at the cafe");app.buttons["Close"].tap()
        XCTAssertTrue(app.staticTexts["conversationGoal"].waitForExistence(timeout:10));XCTAssertFalse(app.staticTexts["conversationVoiceStatus"].exists)
        app.terminate();var args=app.launchArguments;if let index=args.firstIndex(of:"-piyali.theme") { args[index+1]="dark" };app.launchArguments=args;app.launch();open(app);photo("Native conversation initial dark",app);tap("conversationSettings",app)
        XCTAssertTrue(app.buttons["conversationLevel"].label.contains("A2"));XCTAssertEqual(app.switches["conversationPronunciation"].value as? String,"1");let saved=app.textViews["conversationTopics"].exists ? app.textViews["conversationTopics"] : app.textFields["conversationTopics"];XCTAssertEqual(saved.value as? String,"Travel at the cafe");photo("Native conversation source settings dark",app)
    }
}

extension ConversationPlayTests {
    private func changeSupport(_ language:String,_ app:XCUIApplication) {
        tap("productMenu",app);tap("productPanel-settings",app)
        let picker=app.buttons["supportLanguagePicker"]
        for _ in 0..<6 where !picker.isHittable { app.swipeDown(velocity:.slow) }
        XCTAssertTrue(picker.waitForExistence(timeout:5));picker.tap();XCTAssertTrue(app.buttons[language].waitForExistence(timeout:5));app.buttons[language].tap();tap("productPanelClose",app)
    }
    func testSupportLanguageRefreshesGoalStarterAndTranslationWithoutReplayingRewards() {
        let app=start();tap("conversationStart",app)
        let reply=app.staticTexts["conversationLatestReply"];expectation(for:NSPredicate(format:"label CONTAINS %@","¡Hola, Ana!"),evaluatedWith:reply);waitForExpectations(timeout:15)
        tap("conversationEnd",app);XCTAssertTrue(app.staticTexts["conversationSummaryXP"].waitForExistence(timeout:10));XCTAssertTrue(app.staticTexts["conversationSummaryXP"].label.contains("+5"));tap("conversationSummaryDone",app)
        tap("conversationTranslate",app);XCTAssertTrue(app.staticTexts["conversationTranslation"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["conversationTranslation"].label.contains("Hello, Ana!"))
        changeSupport("French",app)
        XCTAssertTrue(app.staticTexts["conversationGoal"].waitForExistence(timeout:10));XCTAssertEqual(app.staticTexts["conversationGoal"].label,"Dites une chose que vous aimez");XCTAssertFalse(app.staticTexts["conversationTranslation"].exists);XCTAssertTrue(app.buttons["conversationTranslate"].exists)
        tap("conversationStarter",app);XCTAssertTrue(app.staticTexts["conversationStarterSupport"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["conversationStarterSupport"].label.contains("J’aime"));tap("conversationStarter",app)
        tap("conversationTranslate",app);XCTAssertTrue(app.staticTexts["conversationTranslation"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["conversationTranslation"].label.contains("Bonjour Ana"));photo("Native conversation French support",app)
        changeSupport("Spanish",app);XCTAssertEqual(app.staticTexts["conversationGoal"].label,"Di algo que te guste");XCTAssertFalse(app.staticTexts["conversationStarterPhrase"].exists);XCTAssertFalse(app.staticTexts["conversationTranslation"].exists)
        tap("conversationTranslate",app);XCTAssertEqual(app.staticTexts["conversationTranslation"].label,app.staticTexts["conversationLatestReply"].label)
        app.terminate();app.launch();open(app);XCTAssertEqual(app.staticTexts["conversationGoal"].label,"Di algo que te guste");XCTAssertEqual(app.staticTexts["conversationTranslation"].label,"¡Hola, Ana! ¿Qué te gusta hacer?");photo("Native conversation Spanish support restored",app)
        tap("productMenu",app);tap("productPanel-settings",app);let xp=app.staticTexts.matching(NSPredicate(format:"label BEGINSWITH %@","5 total XP")).firstMatch;for _ in 0..<6 where !xp.isHittable { app.swipeUp(velocity:.slow) };XCTAssertTrue(xp.waitForExistence(timeout:5))
    }
}
