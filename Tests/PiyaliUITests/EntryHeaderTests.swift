import XCTest

@MainActor final class EntryHeaderTests:XCTestCase {
    private func launch(language:String="en",theme:String="light")->XCUIApplication {
        continueAfterFailure=false;let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_ENTRY_INITIAL_LANGUAGE"]=language;app.launchEnvironment["PIYALI_ENTRY_INITIAL_THEME"]=theme;app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US"];app.launch();XCTAssertTrue(app.staticTexts["entryHeroTitle"].waitForExistence(timeout:15));return app
    }
    private func revealHeader(_ app:XCUIApplication) {for _ in 0..<6 where !app.buttons["entryHeaderSignIn"].isHittable {app.coordinate(withNormalizedOffset:CGVector(dx:0.97,dy:0.85)).press(forDuration:0.1,thenDragTo:app.coordinate(withNormalizedOffset:CGVector(dx:0.97,dy:0.25)),withVelocity:.slow,thenHoldForDuration:0.3)};XCTAssertTrue(app.buttons["entryHeaderSignIn"].isHittable);XCTAssertTrue(app.buttons["entryHeaderCreate"].isHittable);XCTAssertLessThan(app.buttons["entryHeaderSignIn"].frame.maxY,150)}
    private func shot(_ name:String,_ app:XCUIApplication) {let capture=XCTAttachment(screenshot:app.screenshot());capture.name=name;capture.lifetime = .keepAlways;add(capture)}
    func testFixedHeaderOrbKeyLoginRemoteSignerBackAndNamePreservation() {
        let app=launch();XCTAssertFalse(app.buttons["entryHeaderCreate"].exists);let orb=app.buttons["entryHeaderOrb"];orb.tap();XCTAssertEqual(orb.value as? String,"Loving reaction")
        let name=app.textFields["entryName"];name.tap();name.typeText("Header Learner");if app.buttons["entryKeyboardDone"].exists {app.buttons["entryKeyboardDone"].tap()}
        revealHeader(app);shot("Native fixed entry header with actions",app);app.buttons["entryHeaderSignIn"].tap();XCTAssertTrue(app.secureTextFields["entrySecret"].waitForExistence(timeout:5));XCTAssertFalse(app.buttons["entryHeaderCreate"].exists)
        app.buttons["entryRemoteSigner"].tap();XCTAssertTrue(app.secureTextFields["bunkerURL"].waitForExistence(timeout:5));XCTAssertTrue(app.navigationBars["Remote signer"].exists);app.navigationBars.buttons.element(boundBy:0).tap()
        XCTAssertTrue(app.secureTextFields["entrySecret"].waitForExistence(timeout:5));app.buttons["entryBack"].tap();XCTAssertTrue(name.waitForExistence(timeout:5));XCTAssertEqual(name.value as? String,"Header Learner");XCTAssertFalse(app.buttons["entryHeaderCreate"].exists)
    }
    func testHeaderStartRegistersWithoutANameAndCarriesSelectedLanguageThroughOnboarding() {
        let app=launch();XCTAssertFalse(app.buttons["createAccount"].isEnabled);app.buttons["entryLanguage"].tap();app.buttons["entrySupportOption-es"].tap();revealHeader(app);app.buttons["entryHeaderCreate"].tap()
        XCTAssertTrue(app.staticTexts["onboardingTitle"].waitForExistence(timeout:20));XCTAssertTrue(app.buttons["onboardingSupport"].label.contains("Español"));XCTAssertTrue(app.buttons["onboardingPractice"].label.contains("Inglés"));app.buttons["startLearning"].tap();XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15));app.terminate();app.launch();XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15));XCTAssertFalse(app.staticTexts["entryHeroTitle"].exists)
    }
    func testDarkFrenchAndArabicEntryKeepWrappingThemeAndSignInReachable() {
        let app=launch(language:"fr",theme:"dark");let title=app.staticTexts["entryHeroTitle"],name=app.textFields["entryName"];XCTAssertEqual(title.label,"Ton Tuteur Linguistique Personnel");XCTAssertGreaterThan(name.frame.minY,title.frame.maxY);shot("Native French dark landing hero",app)
        app.buttons["entryLanguage"].tap();app.buttons["entrySupportOption-ar"].tap();XCTAssertEqual(title.label,"مدرّسك اللغوي الشخصي");XCTAssertTrue(app.buttons["entryTheme"].isHittable);XCTAssertGreaterThan(name.frame.minY,title.frame.maxY);shot("Native Arabic dark landing hero",app);revealHeader(app);shot("Native Arabic fixed entry header",app);app.buttons["entryHeaderSignIn"].tap();XCTAssertTrue(app.secureTextFields["entrySecret"].waitForExistence(timeout:5));XCTAssertTrue(app.buttons["entryTheme"].isHittable);shot("Native Arabic dark sign in",app);app.buttons["entryTheme"].tap();XCTAssertEqual(app.buttons["entryTheme"].label,"Switch to dark mode");app.buttons["entryBack"].tap();XCTAssertTrue(title.waitForExistence(timeout:5));app.terminate();app.launch();XCTAssertTrue(title.waitForExistence(timeout:10));XCTAssertEqual(title.label,"مدرّسك اللغوي الشخصي");XCTAssertEqual(app.buttons["entryTheme"].label,"Switch to dark mode")
    }
}
