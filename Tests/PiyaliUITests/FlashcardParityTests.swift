import XCTest

@MainActor final class FlashcardParityTests:XCTestCase {
    func testCardsWrongRetryRevealRatingAndSchedulerRestoreThroughTheRealProductMenu(){
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_ENTRY_INITIAL_LANGUAGE"]="en";app.launchEnvironment["PIYALI_ENTRY_INITIAL_THEME"]="light";app.launchEnvironment["PIYALI_FLASHCARD_FIXTURE"]="1";app.launchEnvironment["PIYALI_HEADLINE_FIXTURE"]="failure";app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Cards Learner");app.buttons["entryKeyboardDone"].tap();app.buttons["createAccount"].tap();XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:15))
        app.buttons["onboardingPractice"].tap();let spanish=app.buttons["onboardingOption-practice-es"];XCTAssertTrue(spanish.waitForExistence(timeout:5));spanish.tap();app.buttons["startLearning"].tap();XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15))
        func cards(){app.buttons["productMenu"].tap();app.buttons["productModeMenu"].tap();app.buttons["productMode-cards"].tap();XCTAssertTrue(app.buttons["flashcardTile-pre-a1-people-1"].waitForExistence(timeout:15))}
        cards();let first=app.buttons["flashcardTile-pre-a1-people-1"],second=app.buttons["flashcardTile-pre-a1-people-2"];XCTAssertTrue(first.isEnabled);XCTAssertFalse(second.isEnabled)
        first.tap();let answer=app.textFields["flashcardAnswer"];XCTAssertTrue(answer.waitForExistence(timeout:5));shot(app,"Native flashcard initial")
        answer.tap();answer.typeText("WRONG_FIXTURE\n");XCTAssertTrue(app.buttons["flashcardRetry"].waitForExistence(timeout:10));shot(app,"Native flashcard wrong");app.buttons["flashcardExplain"].tap();XCTAssertTrue(app.staticTexts["flashcardExplanation"].waitForExistence(timeout:5));app.buttons["flashcardRetry"].tap()
        app.buttons["flashcardReveal"].tap();XCTAssertTrue(app.buttons["flashcardFlipBack"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["flashcardPrompt"].waitForExistence(timeout:5));app.buttons["flashcardFlipBack"].tap()
        answer.tap();answer.typeText("mamá\n");XCTAssertTrue(app.staticTexts["flashcardReward"].waitForExistence(timeout:10));XCTAssertTrue(app.staticTexts["flashcardReward"].label.contains("6"));shot(app,"Native flashcard correct and rating choices")
        app.buttons["flashcardCreateNote"].tap();XCTAssertFalse(app.buttons["flashcardCreateNote"].isEnabled);app.buttons["flashcardRate-hard"].tap();XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:5));XCTAssertTrue(second.isEnabled)
        app.terminate();app.launch();XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));cards();XCTAssertTrue(second.isEnabled)
        second.tap();XCTAssertTrue(answer.waitForExistence(timeout:5));answer.tap();answer.typeText("papá\n");XCTAssertTrue(app.staticTexts["flashcardReward"].waitForExistence(timeout:10));app.buttons["flashcardCancel"].exists ? app.buttons["flashcardCancel"].tap():app.coordinate(withNormalizedOffset:CGVector(dx:0.005,dy:0.5)).tap()
        XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:5))
    }
    private func shot(_ app:XCUIApplication,_ name:String){let item=XCTAttachment(screenshot:app.screenshot());item.name=name;item.lifetime = .keepAlways;add(item)}
}
