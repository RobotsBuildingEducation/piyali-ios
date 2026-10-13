import XCTest
final class SmokeTests: XCTestCase {
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
        let placement = app.buttons["Choose your starting level"]
        XCTAssertTrue(placement.waitForExistence(timeout:10)); placement.tap()
        let option = app.switches["I mostly speak this language at home"]
        XCTAssertTrue(option.waitForExistence(timeout:5)); option.switches.firstMatch.tap()
        XCTAssertEqual(option.value as? String,"1")
        for _ in 0..<4 where !app.buttons["Start at A1"].isHittable { app.swipeUp() }
        XCTAssertTrue(app.buttons["Start at A1"].waitForExistence(timeout:5)); app.buttons["Start at A1"].tap()
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["Choose your starting level"].waitForExistence(timeout:10)); app.buttons["Choose your starting level"].tap()
        XCTAssertTrue(app.staticTexts["Current starting level: A1"].waitForExistence(timeout:5))
        app.navigationBars.buttons.element(boundBy:0).tap(); app.tabBars.buttons["Account"].tap()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["0 total XP · 0 lessons completed"].waitForExistence(timeout:5))
    }
    func testCreateAccountAndOfflinePractice() {
        let app = XCUIApplication(); app.launchEnvironment["PIYALI_OFFLINE_TESTS"] = "1"; app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"] = UUID().uuidString; app.launch()
        if app.buttons["createAccount"].waitForExistence(timeout: 5) { app.buttons["createAccount"].tap() }
        if app.buttons["startLearning"].waitForExistence(timeout: 10) { app.buttons["startLearning"].tap() }
        XCTAssertTrue(app.tabBars.buttons["Practice"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Practice"].tap()
        let flashcards = app.buttons.matching(NSPredicate(format:"label BEGINSWITH 'Flashcards ('")).firstMatch
        XCTAssertTrue(flashcards.waitForExistence(timeout: 10)); flashcards.tap()
        XCTAssertTrue(app.buttons["Reveal answer"].waitForExistence(timeout: 5))
        let prompt = app.staticTexts["flashcardPrompt"].label
        app.buttons["Reveal answer"].tap()
        XCTAssertTrue(app.staticTexts["nextReview"].waitForExistence(timeout:5))
        let scheduled = app.staticTexts["nextReview"].label
        app.terminate(); app.launch()
        XCTAssertTrue(app.tabBars.buttons["Practice"].waitForExistence(timeout:10)); app.tabBars.buttons["Practice"].tap()
        let restoredCards = app.buttons.matching(NSPredicate(format:"label BEGINSWITH 'Flashcards ('")).firstMatch
        XCTAssertTrue(restoredCards.waitForExistence(timeout:10)); restoredCards.tap()
        // The reviewed card is first in the queue; its schedule survives a process restart.
        XCTAssertTrue(app.staticTexts["nextReview"].waitForExistence(timeout:5))
        XCTAssertEqual(app.staticTexts["flashcardPrompt"].label,prompt)
        XCTAssertEqual(app.staticTexts["nextReview"].label,scheduled)
        app.buttons["nextFlashcard"].tap()
        let translation = app.textFields["Your translation"]
        XCTAssertTrue(translation.waitForExistence(timeout:5)); translation.tap(); translation.typeText("wrong-answer-for-memory-test")
        app.buttons["Check answer"].tap()
        XCTAssertTrue(app.staticTexts["nextReview"].waitForExistence(timeout:5))
        app.navigationBars.buttons.element(boundBy:0).tap()
        app.tabBars.buttons["Notes"].tap()
        let memoryLink = app.buttons.matching(NSPredicate(format:"label BEGINSWITH 'Companion memory ('")).firstMatch
        XCTAssertTrue(memoryLink.waitForExistence(timeout:5)); memoryLink.tap()
        XCTAssertTrue(app.staticTexts["memoryAnswer"].firstMatch.waitForExistence(timeout:5))
        app.terminate(); app.launch()
        XCTAssertTrue(app.tabBars.buttons["Notes"].waitForExistence(timeout:10)); app.tabBars.buttons["Notes"].tap()
        let restoredMemory = app.buttons.matching(NSPredicate(format:"label BEGINSWITH 'Companion memory ('")).firstMatch
        XCTAssertTrue(restoredMemory.waitForExistence(timeout:5)); restoredMemory.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label CONTAINS 'wrong-answer-for-memory-test'")).firstMatch.waitForExistence(timeout:5))
        app.navigationBars.buttons.element(boundBy:0).tap()
        XCTAssertTrue(app.textFields["Title"].waitForExistence(timeout:5))
        let noteTitle = "Practice " + UUID().uuidString.prefix(8)
        app.textFields["Title"].tap(); app.textFields["Title"].typeText(String(noteTitle))
        let body = app.textFields["What do you want to remember?"]
        body.tap(); body.typeText("Hola means hello")
        app.buttons["Save note"].tap()
        XCTAssertTrue(app.buttons[String(noteTitle)].waitForExistence(timeout:5))
        app.terminate(); app.launch()
        XCTAssertTrue(app.tabBars.buttons["Notes"].waitForExistence(timeout:10)); app.tabBars.buttons["Notes"].tap()
        XCTAssertTrue(app.buttons[String(noteTitle)].waitForExistence(timeout:5))
        app.tabBars.buttons["Tutor"].tap()
        XCTAssertTrue(app.staticTexts["Unlock Piyali"].waitForExistence(timeout:5))
    }
}
