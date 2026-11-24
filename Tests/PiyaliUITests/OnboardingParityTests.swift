import XCTest

@MainActor final class OnboardingParityTests:XCTestCase {
    private func launch(language:String="en",theme:String="light")->XCUIApplication {
        continueAfterFailure=false;let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_ENTRY_INITIAL_LANGUAGE"]=language;app.launchEnvironment["PIYALI_ENTRY_INITIAL_THEME"]=theme;app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US"];app.launch();handleInitialPaperPencil(app)
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Welcome Learner");app.buttons["entryKeyboardDone"].tap();app.buttons["createAccount"].tap();handleInitialPaperPencil(app);XCTAssertTrue(app.staticTexts["onboardingTitle"].waitForExistence(timeout:20));return app
    }
    private func shot(_ name:String,_ app:XCUIApplication) {let capture=XCTAttachment(screenshot:app.screenshot());capture.name=name;capture.lifetime = .keepAlways;add(capture)}
    private func choose(_ app:XCUIApplication,support:Bool,code:String) {let menu=app.buttons[support ? "onboardingSupport" : "onboardingPractice"];for _ in 0..<3 where !menu.isHittable {app.swipeDown()};menu.tap();let option=app.buttons["onboardingOption-"+(support ? "support-" : "practice-")+code];XCTAssertTrue(option.waitForExistence(timeout:5));option.tap()}
    func testSourceCardsMenusPerLanguageGoalsSupportChangeAndFinish() {
        let app=launch();shot("Native source onboarding English light",app)
        XCTAssertEqual(app.buttons["startLearning"].label,"Start session");XCTAssertEqual(app.buttons["onboardingSupport"].frame.width,app.frame.width-80,accuracy:1);XCTAssertEqual(app.buttons["onboardingSupport"].frame.height,42,accuracy:1)
        let hint=app.staticTexts["onboardingGoalHint"],start=app.buttons["startLearning"];XCTAssertEqual(start.frame.height,48,accuracy:1);let buttonY=start.frame.minY
        for _ in 0..<4 where hint.frame.maxY>start.frame.minY-16 {app.coordinate(withNormalizedOffset:CGVector(dx:0.97,dy:0.7)).press(forDuration:0.1,thenDragTo:app.coordinate(withNormalizedOffset:CGVector(dx:0.97,dy:0.35)),withVelocity:.slow,thenHoldForDuration:0.1)}
        XCTAssertLessThan(hint.frame.maxY,start.frame.minY-16);XCTAssertEqual(start.frame.minY,buttonY,accuracy:1)
        let editor=app.textViews["onboardingGoal"];editor.tap();editor.typeText("Talk with family");app.buttons["onboardingKeyboardDone"].tap()
        choose(app,support:false,code:"fr");XCTAssertEqual(editor.value as? String,"");editor.tap();editor.typeText("Order in a cafe");app.buttons["onboardingKeyboardDone"].tap()
        choose(app,support:true,code:"fr");XCTAssertEqual(editor.value as? String,"Order in a cafe");XCTAssertTrue(app.buttons["onboardingPractice"].label.contains("Francais"))
        choose(app,support:false,code:"es");XCTAssertEqual(editor.value as? String,"Talk with family")
        choose(app,support:false,code:"ja");XCTAssertTrue(app.buttons["onboardingPractice"].label.contains("beta"));XCTAssertEqual(editor.value as? String,"")
        choose(app,support:false,code:"fr");XCTAssertEqual(editor.value as? String,"Order in a cafe");shot("Native source onboarding French retained goal",app)
        app.buttons["startLearning"].tap();XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15));app.terminate();app.launch();handleInitialPaperPencil(app);XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15));XCTAssertFalse(app.staticTexts["onboardingTitle"].exists)
    }
    func testArabicDarkDrawerScrollAndOptionalBlankGoal() {
        let app=launch(language:"ar",theme:"dark");XCTAssertTrue(app.buttons["onboardingSupport"].isHittable);XCTAssertTrue(app.buttons["onboardingPractice"].isHittable);shot("Native source onboarding Arabic dark",app)
        let editor=app.textViews["onboardingGoal"];for _ in 0..<3 where !editor.isHittable {app.swipeUp()};XCTAssertTrue(editor.isHittable);XCTAssertEqual(editor.value as? String,"");app.buttons["startLearning"].tap();XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15))
    }
}
