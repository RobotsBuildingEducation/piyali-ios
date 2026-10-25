import XCTest
final class SmokeTests: XCTestCase {
    private func openImmersion(_ app: XCUIApplication) {
        let link=app.buttons["immersionLink"]
        XCTAssertTrue(link.waitForExistence(timeout:10))
        for _ in 0..<3 where !link.isHittable { app.swipeUp(velocity:.slow) }
        for _ in 0..<3 where !link.isHittable { app.swipeDown(velocity:.slow) }
        XCTAssertTrue(link.isHittable);link.tap()
        XCTAssertTrue(app.navigationBars["Immersion & Score"].waitForExistence(timeout:5))
    }
    func testImmersionChecklistKeepsProgressAndGrantsOneRewardAfterRelaunch() {
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_IMMERSION_FIXTURE"]="1";app.launch()
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:5));app.buttons["createAccount"].tap()
        XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:10));app.buttons["startLearning"].tap()
        openImmersion(app)
        XCTAssertTrue(app.buttons["immersion-task-0"].waitForExistence(timeout:10));XCTAssertTrue(app.buttons["immersion-task-0"].isEnabled);app.buttons["immersion-task-0"].tap();XCTAssertEqual(app.buttons["immersion-task-0"].value as? String,"Completed");app.buttons["immersion-task-1"].tap()
        XCTAssertFalse(app.staticTexts["immersionReward"].exists)
        app.terminate();app.launch();openImmersion(app)
        XCTAssertTrue(app.buttons["immersion-task-0"].waitForExistence(timeout:10));XCTAssertEqual(app.buttons["immersion-task-0"].value as? String,"Completed")
        app.buttons["immersion-task-2"].tap();app.swipeUp();XCTAssertTrue(app.buttons["immersion-task-3"].waitForExistence(timeout:5));app.buttons["immersion-task-3"].tap()
        XCTAssertTrue(app.staticTexts["immersionReward"].waitForExistence(timeout:5));app.buttons["immersion-task-3"].tap();app.buttons["immersion-task-3"].tap()
        app.navigationBars.buttons.element(boundBy:0).tap();app.tabBars.buttons["Account"].tap();app.swipeUp()
        XCTAssertTrue(app.staticTexts["15 total XP · 0 lessons completed"].waitForExistence(timeout:5))
    }
    func testDailyPlateIntroAndReviewCountPersistWithoutRevealXP() {
        let app = XCUIApplication(); app.launchEnvironment["PIYALI_OFFLINE_TESTS"] = "1"; app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"] = UUID().uuidString; app.launch()
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:5)); app.buttons["createAccount"].tap()
        XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:10)); app.buttons["startLearning"].tap()
        XCTAssertTrue(app.buttons["Daily practice plate"].waitForExistence(timeout:10)); app.buttons["Daily practice plate"].tap()
        XCTAssertTrue(app.buttons["quest-speak"].waitForExistence(timeout:5)); XCTAssertTrue(app.buttons["quest-learn"].exists)
        XCTAssertTrue(app.buttons["quest-review"].label.contains("0 / 5")); app.buttons["quest-review"].tap()
        XCTAssertTrue(app.buttons["Reveal answer"].waitForExistence(timeout:5)); app.buttons["Reveal answer"].tap()
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["Daily practice plate"].waitForExistence(timeout:10)); app.buttons["Daily practice plate"].tap()
        XCTAssertTrue(app.buttons["quest-review"].waitForExistence(timeout:5)); XCTAssertTrue(app.buttons["quest-review"].label.contains("1 / 5"))
        XCTAssertFalse(app.staticTexts["questCompleted"].exists)
        app.navigationBars.buttons.element(boundBy:0).tap(); app.tabBars.buttons["Account"].tap(); app.swipeUp()
        XCTAssertTrue(app.staticTexts["0 total XP · 0 lessons completed"].waitForExistence(timeout:5))
    }
    func testLanguageSwitchKeepsGoalsSeparateAfterRelaunch() {
        let app = XCUIApplication(); app.launchEnvironment["PIYALI_OFFLINE_TESTS"] = "1"; app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"] = UUID().uuidString; app.launch()
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:5)); app.buttons["createAccount"].tap()
        XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:10)); app.buttons["startLearning"].tap()
        XCTAssertTrue(app.tabBars.buttons["Account"].waitForExistence(timeout:10)); app.tabBars.buttons["Account"].tap()
        let goal = app.descendants(matching:.any)["learningGoalField"]
        XCTAssertTrue(goal.waitForExistence(timeout:5)); goal.tap(); goal.typeText(" restaurant mission")
        let save = app.buttons["saveLearningPreferences"]
        XCTAssertTrue(save.waitForExistence(timeout:5)); save.tap()
        let language = app.buttons["practiceLanguagePicker"]
        XCTAssertTrue(language.waitForExistence(timeout:5)); language.tap()
        XCTAssertTrue(app.buttons["French"].waitForExistence(timeout:5)); app.buttons["French"].tap()
        XCTAssertFalse((goal.value as? String ?? "").contains("restaurant mission"))
        app.terminate(); app.launch()
        XCTAssertTrue(app.tabBars.buttons["Account"].waitForExistence(timeout:10)); app.tabBars.buttons["Account"].tap()
        XCTAssertTrue(app.buttons["practiceLanguagePicker"].waitForExistence(timeout:5))
        XCTAssertTrue(app.buttons["practiceLanguagePicker"].label.contains("French"))
        XCTAssertFalse((app.descendants(matching:.any)["learningGoalField"].value as? String ?? "").contains("restaurant mission"))
        app.buttons["practiceLanguagePicker"].tap()
        XCTAssertTrue(app.buttons["Spanish"].waitForExistence(timeout:5)); app.buttons["Spanish"].tap()
        XCTAssertTrue((app.descendants(matching:.any)["learningGoalField"].value as? String ?? "").contains("restaurant mission"))
    }
    func testStartingLevelPersistsWithoutXPOrCompletionCredit() {
        let app = XCUIApplication(); app.launchEnvironment["PIYALI_OFFLINE_TESTS"] = "1"; app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"] = UUID().uuidString; app.launch()
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:5)); app.buttons["createAccount"].tap()
        XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:10)); app.buttons["startLearning"].tap()
        app.swipeUp();let placement = app.buttons["Choose your starting level"]
        XCTAssertTrue(placement.waitForExistence(timeout:10)); placement.tap()
        let option = app.switches["I mostly speak this language at home"]
        XCTAssertTrue(option.waitForExistence(timeout:5)); option.switches.firstMatch.tap()
        XCTAssertEqual(option.value as? String,"1")
        for _ in 0..<4 where !app.buttons["Start at A1"].isHittable { app.swipeUp() }
        XCTAssertTrue(app.buttons["Start at A1"].waitForExistence(timeout:5)); app.buttons["Start at A1"].tap()
        app.terminate(); app.launch()
        app.swipeUp(); XCTAssertTrue(app.buttons["Choose your starting level"].waitForExistence(timeout:10)); app.buttons["Choose your starting level"].tap()
        XCTAssertTrue(app.staticTexts["Current starting level: A1"].waitForExistence(timeout:5))
        app.navigationBars.buttons.element(boundBy:0).tap(); app.tabBars.buttons["Account"].tap()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["0 total XP · 0 lessons completed"].waitForExistence(timeout:5))
    }
    func testOnboardingStartingLevelUnlocksChosenCourseAfterRelaunch() {
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launch()
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:5));app.buttons["createAccount"].tap()
        let picker=app.buttons["onboardingLevelPicker"]
        XCTAssertTrue(picker.waitForExistence(timeout:10));picker.tap()
        XCTAssertTrue(app.buttons["B1"].waitForExistence(timeout:5));app.buttons["B1"].tap();app.buttons["startLearning"].tap()
        app.swipeUp(); XCTAssertTrue(app.buttons["Choose your starting level"].waitForExistence(timeout:10));app.buttons["Choose your starting level"].tap()
        XCTAssertTrue(app.staticTexts["Current starting level: B1"].waitForExistence(timeout:5))
        app.terminate();app.launch()
        app.swipeUp(); XCTAssertTrue(app.buttons["Choose your starting level"].waitForExistence(timeout:10));app.buttons["Choose your starting level"].tap()
        XCTAssertTrue(app.staticTexts["Current starting level: B1"].waitForExistence(timeout:5))
        app.navigationBars.buttons.element(boundBy:0).tap();app.tabBars.buttons["Account"].tap();app.swipeUp()
        XCTAssertTrue(app.staticTexts["0 total XP · 0 lessons completed"].waitForExistence(timeout:5))
    }
    // The obsolete tab-bar/handwritten-notebook smoke flow is covered by
    // FlashcardParityTests, TypedPracticeTests and MemoryJourneyTests using product controls.
}
