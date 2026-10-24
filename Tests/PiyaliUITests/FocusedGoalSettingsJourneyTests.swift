import XCTest

@MainActor final class FocusedGoalSettingsJourneyTests:XCTestCase {
    func testTranslatedGoalEditorKeepsLanguageDraftsAndPersistsThroughPanelCloseAndRelaunch() {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_ENTRY_INITIAL_LANGUAGE"]="en";app.launchEnvironment["PIYALI_HEADLINE_FIXTURE"]="failure";app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Goal Learner");app.buttons["entryKeyboardDone"].tap();app.buttons["createAccount"].tap();XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:15));app.buttons["startLearning"].tap();XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15))
        func settings(){app.buttons["productMenu"].tap();XCTAssertTrue(app.buttons["productPanel-settings"].waitForExistence(timeout:5));app.buttons["productPanel-settings"].tap();XCTAssertTrue(app.textViews["learningGoalField"].waitForExistence(timeout:10))}
        func language(_ name:String){app.buttons["practiceLanguagePicker"].tap();let option=app.buttons[name];XCTAssertTrue(option.waitForExistence(timeout:5));option.tap()}
        settings();let goal=app.textViews["learningGoalField"];goal.tap();goal.typeText("Talk with family");app.buttons["saveLearningPreferences"].tap();XCTAssertEqual(goal.value as? String,"Talk with family")
        language("French");XCTAssertEqual(goal.value as? String,"");goal.tap();goal.typeText("Order in a cafe");app.buttons["saveLearningPreferences"].tap()
        language("Spanish");XCTAssertEqual(goal.value as? String,"Talk with family");language("French");XCTAssertEqual(goal.value as? String,"Order in a cafe")
        let attachment=XCTAttachment(screenshot:app.screenshot());attachment.name="Translated native goal editor and language boundary";attachment.lifetime = .keepAlways;add(attachment)
        goal.tap();goal.typeText(" politely");let edited=(goal.value as? String)?.trimmingCharacters(in:.whitespacesAndNewlines);XCTAssertTrue(edited?.contains("politely") == true);app.buttons["productPanelClose"].tap();app.terminate();app.launch();XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));settings();XCTAssertEqual(goal.value as? String,edited)
        language("Spanish");XCTAssertEqual(goal.value as? String,"Talk with family")
    }
}
