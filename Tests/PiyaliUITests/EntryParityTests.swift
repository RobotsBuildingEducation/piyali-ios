import XCTest

@MainActor final class EntryParityTests:XCTestCase {
    private func launch() -> XCUIApplication {
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch();return app
    }
    func testLandingHasNamedSignupAndDedicatedKeyLoginWithBackAndErrors() {
        continueAfterFailure=false;let app=launch()
        XCTAssertTrue(app.staticTexts["entryHeroTitle"].waitForExistence(timeout:15));XCTAssertEqual(app.staticTexts["entryHeroTitle"].label,"Your Personal Language Tutor")
        let snapshot=XCTAttachment(screenshot:app.screenshot());snapshot.name="Native landing hero";snapshot.lifetime = .keepAlways;add(snapshot)
        print("ENTRY FRAME: headingY=\(app.staticTexts["entryHeroTitle"].frame.minY), headingHeight=\(app.staticTexts["entryHeroTitle"].frame.height), inputY=\(app.textFields["entryName"].frame.minY), inputHeight=\(app.textFields["entryName"].frame.height)")
        let create=app.buttons["createAccount"];XCTAssertFalse(create.isEnabled)
        let name=app.textFields["entryName"];name.tap();name.typeText("nsec1not-a-display-name");XCTAssertFalse(create.isEnabled)
        if app.buttons["entryKeyboardDone"].exists { app.buttons["entryKeyboardDone"].tap() };app.buttons["entrySignIn"].tap();XCTAssertTrue(app.staticTexts["Welcome Back"].waitForExistence(timeout:5))
        let signInShot=XCTAttachment(screenshot:app.screenshot());signInShot.name="Native secret-key screen";signInShot.lifetime = .keepAlways;add(signInShot)
        let secret=app.secureTextFields["entrySecret"];secret.tap();secret.typeText("bad-key");if app.buttons["entryKeyboardDone"].exists { app.buttons["entryKeyboardDone"].tap() };app.buttons["entrySubmitSignIn"].tap()
        XCTAssertTrue(app.staticTexts["entryError"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["entryError"].label.contains("Invalid secret key"))
        app.buttons["entryBack"].tap();XCTAssertTrue(app.textFields["entryName"].waitForExistence(timeout:5))
    }
    func testLanguageAtlasSelectionChangesTheOriginalPostcard() {
        continueAfterFailure=false;let app=launch()
        let japanese=app.buttons["landingLanguage-ja"]
        for _ in 0..<10 where !japanese.exists || !japanese.isHittable { app.swipeUp(velocity:.slow) }
        XCTAssertTrue(japanese.waitForExistence(timeout:10));japanese.tap()
        let greeting=app.staticTexts["landingGreeting"]
        for _ in 0..<8 where !greeting.isHittable { app.swipeDown(velocity:.slow) }
        XCTAssertTrue(greeting.isHittable);XCTAssertEqual(greeting.label,"ありがとう")
    }
    func testCreationCarriesNameIntoActualThreeFieldOnboardingWithoutPlacementControls() {
        continueAfterFailure=false;let app=launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Parity Learner");if app.buttons["entryKeyboardDone"].exists { app.buttons["entryKeyboardDone"].tap() }
        app.buttons["createAccount"].tap();XCTAssertTrue(app.staticTexts["onboardingTitle"].waitForExistence(timeout:20))
        XCTAssertTrue(app.buttons["onboardingSupport"].exists);XCTAssertTrue(app.buttons["onboardingPractice"].exists);XCTAssertTrue(app.textViews["onboardingGoal"].exists)
        XCTAssertFalse(app.pickers["onboardingLevelPicker"].exists);XCTAssertFalse(app.steppers.firstMatch.exists)
        let done=app.buttons["startLearning"];XCTAssertEqual(done.label,"Start session")
        let attachment=XCTAttachment(screenshot:app.screenshot());attachment.name="Native onboarding compared to reference";attachment.lifetime = .keepAlways;add(attachment)
    }
    func testCapabilityTabsCompanionToolkitFAQsAndFooterSignup() {
        continueAfterFailure=false;let app=launch()
        func reveal(_ element:XCUIElement,limit:Int=25) {
            for _ in 0..<limit where !element.exists || !element.isHittable {
                let top=app.buttons["entryTheme"].frame.maxY+20,above=element.exists && element.frame.midY < top
                let from=app.coordinate(withNormalizedOffset:CGVector(dx:0.97,dy:above ? 0.3 : 0.8)),to=app.coordinate(withNormalizedOffset:CGVector(dx:0.97,dy:above ? 0.75 : 0.35))
                from.press(forDuration:0.1,thenDragTo:to,withVelocity:.slow,thenHoldForDuration:0.3)
            }
            XCTAssertTrue(element.isHittable)
        }
        let remember=app.buttons["landingTab-remember"];reveal(remember);remember.tap()
        XCTAssertTrue(app.staticTexts["Your first try"].exists)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Native Remember capability";shot.lifetime = .keepAlways;add(shot)
        app.buttons["landingTab-grow"].tap();let vocabulary=app.staticTexts["Vocabulary cards"];reveal(vocabulary);XCTAssertTrue(vocabulary.exists)
        let next=app.buttons["Next companion"];reveal(next);next.tap();XCTAssertEqual(app.staticTexts["landingCompanionName"].label,"Alien")
        let toolkit=app.buttons["landingToolkit"];reveal(toolkit);toolkit.tap();XCTAssertTrue(app.staticTexts["Game Review RPG"].exists);toolkit.tap()
        let cost=app.buttons["landingFAQ-2"];reveal(cost);cost.tap();XCTAssertTrue(app.staticTexts["landingFAQAnswer-2"].exists)
        let footer=app.textFields["entryFooterName"];reveal(footer)
        XCTAssertFalse(app.buttons["entryFooterCreate"].isEnabled)
        let privacy=app.buttons["landingPrivacy"];reveal(privacy);privacy.tap();XCTAssertTrue(app.navigationBars["Privacy policy"].waitForExistence(timeout:5))
    }
    func testOnboardingEntersTodayFocusAndModeMenuOpensLibrariesWithoutAutoStartingLessons() {
        continueAfterFailure=false;let app=launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Flow Learner");if app.buttons["entryKeyboardDone"].exists { app.buttons["entryKeyboardDone"].tap() }
        app.buttons["createAccount"].tap();let finish=app.buttons["startLearning"];XCTAssertTrue(finish.waitForExistence(timeout:20));finish.tap()
        XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15));XCTAssertEqual(app.tabBars.count,0)
        let snapshot=XCTAttachment(screenshot:app.screenshot());snapshot.name="Native Today Focus after onboarding";snapshot.lifetime = .keepAlways;add(snapshot)
        app.buttons["productMenu"].tap();XCTAssertTrue(app.buttons["productPanel-settings"].waitForExistence(timeout:5));XCTAssertTrue(app.buttons["productPanel-teams"].exists);XCTAssertTrue(app.buttons["productPanel-assistant"].exists);XCTAssertTrue(app.buttons["productPanel-memory"].exists)
        app.buttons["productModeMenu"].tap();XCTAssertTrue(app.buttons["productMode-path"].exists);XCTAssertTrue(app.buttons["productMode-cards"].exists);XCTAssertTrue(app.buttons["productMode-phonics"].exists);XCTAssertTrue(app.buttons["productMode-conversation"].exists)
        let menuShot=XCTAttachment(screenshot:app.screenshot());menuShot.name="Native activity mode menu";menuShot.lifetime = .keepAlways;add(menuShot)
        app.buttons["productMode-path"].tap();XCTAssertTrue(app.navigationBars["Lessons"].waitForExistence(timeout:10));XCTAssertTrue(app.buttons["introLink"].exists)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'lessonNode-' AND enabled == true")).count,0,"Tutorial completion gates the first normal node")
        app.buttons["productMenu"].tap();app.buttons["productModeMenu"].tap();app.buttons["productMode-focus"].tap();XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:5))
        let continueButton=app.buttons["companionContinue"]
        for _ in 0..<6 where !continueButton.isHittable { app.swipeUp(velocity:.slow) }
        continueButton.tap();XCTAssertTrue(app.buttons["gettingStartedGotIt"].waitForExistence(timeout:5));app.buttons["gettingStartedGotIt"].tap();XCTAssertTrue(app.buttons["placementNew"].waitForExistence(timeout:5));XCTAssertTrue(app.buttons["placementFindLevel"].exists);app.buttons["placementNew"].tap()
        let start=app.buttons["startDailyPractice"];for _ in 0..<6 where !start.isHittable { app.swipeDown(velocity:.slow) }
        XCTAssertTrue(NSPredicate(format:"enabled == true").evaluate(with:start) || XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:start)],timeout:10) == .completed);start.tap();XCTAssertTrue(app.navigationBars["Tutor"].waitForExistence(timeout:10));XCTAssertFalse(app.buttons["Start voice session"].exists,"Starting a daily task chooses the mode, not a lesson or microphone session")
    }
}
