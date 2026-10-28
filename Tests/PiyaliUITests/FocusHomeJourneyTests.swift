import XCTest

@MainActor final class FocusHomeJourneyTests:XCTestCase {
    private func launch(_ language:String="en",theme:String="light")->XCUIApplication {
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_ENTRY_INITIAL_LANGUAGE"]=language;app.launchEnvironment["PIYALI_ENTRY_INITIAL_THEME"]=theme;app.launchEnvironment["PIYALI_IMMERSION_FIXTURE"]="1";app.launch();return app
    }
    private func enter(_ app:XCUIApplication) {
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Focus Learner");if app.buttons["entryKeyboardDone"].exists {app.buttons["entryKeyboardDone"].tap()};app.buttons["createAccount"].tap();XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:15));app.buttons["startLearning"].tap();XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15))
    }
    private func shot(_ app:XCUIApplication,_ name:String){let attachment=XCTAttachment(screenshot:app.screenshot());attachment.name=name;attachment.lifetime = .keepAlways;add(attachment)}
    private func reveal(_ app:XCUIApplication,_ element:XCUIElement){for _ in 0..<8 where !element.exists || !element.isHittable {app.swipeUp(velocity:.slow)};XCTAssertTrue(element.isHittable)}
    private func dismissWelcome(_ app:XCUIApplication){let next=app.buttons["companionContinue"];reveal(app,next);next.tap();acknowledgePaperPencil(app);XCTAssertTrue(app.buttons["gettingStartedGotIt"].waitForExistence(timeout:5));app.buttons["gettingStartedGotIt"].tap();XCTAssertTrue(app.buttons["placementNew"].waitForExistence(timeout:5));app.buttons["placementNew"].tap()}
    func testWelcomeGeometryCustomizeCancelSaveAndImmersionRewardSurviveRelaunch() {
        continueAfterFailure=false;let app=launch();enter(app)
        XCTAssertFalse(app.buttons["startDailyPractice"].isEnabled);XCTAssertFalse(app.buttons["focusCustomizeCompanion"].isEnabled);XCTAssertLessThanOrEqual(app.buttons["companionContinue"].frame.maxY,app.buttons["focusCustomizeCompanion"].frame.minY+1,"The balloon must float above the pet, rather than cover its meters.")
        let row=app.descendants(matching:.any).matching(identifier:"focusCourse-speak").firstMatch,next=app.descendants(matching:.any).matching(identifier:"focusCourse-learn").firstMatch
        XCTAssertEqual(row.frame.height,64,accuracy:1);XCTAssertEqual(next.frame.minY-row.frame.maxY,10,accuracy:1)
        shot(app,"Focus welcome light")
        dismissWelcome(app)
        let edit=app.buttons["focusCustomizeCompanion"];reveal(app,edit);edit.tap();XCTAssertTrue(app.textFields["companionNameDraft"].waitForExistence(timeout:5));XCTAssertTrue(app.buttons["companionOption-ghost"].isEnabled);XCTAssertFalse(app.buttons["companionOption-alien"].isEnabled);XCTAssertFalse(app.buttons["companionOption-axolotl"].isEnabled)
        let initialName=app.textFields["companionNameDraft"].value as? String
        shot(app,"Focus companion picker light")
        app.textFields["companionNameDraft"].tap();app.textFields["companionNameDraft"].typeText("Discard me");let cancel=app.buttons["companionCancel"];reveal(app,cancel);cancel.tap()
        edit.tap();let name=app.textFields["companionNameDraft"];XCTAssertTrue(name.waitForExistence(timeout:5));XCTAssertEqual(name.value as? String,initialName);name.tap();name.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:(initialName ?? "").count));name.typeText("  Cielo  \n");XCTAssertTrue(edit.waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["Cielo"].exists)
        shot(app,"Focus companion saved light")
        let task=app.buttons["immersionTask-0"];reveal(app,task);XCTAssertTrue(task.waitForExistence(timeout:10));shot(app,"Focus score and immersion light")
        for index in 0..<3 {let row=app.buttons["immersionTask-\(index)"];reveal(app,row);row.tap()}
        let reward=app.descendants(matching:.any).matching(identifier:"immersionReward").firstMatch;reveal(app,reward);XCTAssertTrue(reward.exists);XCTAssertFalse(app.buttons["immersionTask-2"].isEnabled);shot(app,"Focus immersion reward light")
        app.terminate();app.launch();XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["companionContinue"].exists);reveal(app,app.buttons["focusCustomizeCompanion"]);XCTAssertTrue(app.staticTexts["Cielo"].exists);reveal(app,reward);XCTAssertTrue(reward.exists);XCTAssertFalse(app.buttons["immersionTask-0"].isEnabled)
    }
    func testArabicDarkCompanionAndScoreUseSourceCopyAndRemainInteractive() {
        continueAfterFailure=false;let app=launch("ar",theme:"dark");enter(app);XCTAssertLessThanOrEqual(app.buttons["companionContinue"].frame.maxY,app.buttons["focusCustomizeCompanion"].frame.minY+1);XCTAssertLessThanOrEqual(app.buttons["companionContinue"].frame.maxX,app.frame.maxX-12);XCTAssertGreaterThanOrEqual(app.buttons["companionContinue"].frame.minX,12);shot(app,"Focus welcome Arabic dark");dismissWelcome(app)
        let edit=app.buttons["focusCustomizeCompanion"];reveal(app,edit);edit.tap();XCTAssertTrue(app.buttons["companionOption-ghost"].waitForExistence(timeout:5));XCTAssertTrue(app.buttons["companionOption-ghost"].label.contains("شبح"));shot(app,"Focus companion picker Arabic dark");app.buttons["companionCancel"].tap()
        let title=app.staticTexts["focusImmersionTitle"];reveal(app,title);XCTAssertEqual(title.label,"انغماس اليوم");shot(app,"Focus score Arabic dark")
        for index in 0..<3 {let row=app.buttons["immersionTask-\(index)"];reveal(app,row);row.tap()}
        let reward=app.descendants(matching:.any).matching(identifier:"immersionReward").firstMatch;reveal(app,reward);XCTAssertTrue(reward.label.contains("كسبت +15 XP!"));shot(app,"Focus reward Arabic dark")
    }
}
