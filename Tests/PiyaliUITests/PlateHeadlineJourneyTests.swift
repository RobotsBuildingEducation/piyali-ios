import XCTest

@MainActor final class PlateHeadlineJourneyTests:XCTestCase {
    private func launch(fixture:String="slow",language:String="en",theme:String="light")->XCUIApplication {
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_ENTRY_INITIAL_LANGUAGE"]=language;app.launchEnvironment["PIYALI_ENTRY_INITIAL_THEME"]=theme;app.launchEnvironment["PIYALI_HEADLINE_FIXTURE"]=fixture;app.launch();handleInitialPaperPencil(app);return app
    }
    private func enter(_ app:XCUIApplication) {
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Headline Learner");if app.buttons["entryKeyboardDone"].exists{app.buttons["entryKeyboardDone"].tap()};app.buttons["createAccount"].tap();handleInitialPaperPencil(app);XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:15));app.buttons["startLearning"].tap();XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15))
    }
    private func expect(_ text:String,_ app:XCUIApplication,timeout:TimeInterval=15) {
        let element=app.staticTexts["focusHeadline"],expectation=XCTNSPredicateExpectation(predicate:NSPredicate(format:"label == %@",text),object:element);XCTAssertEqual(XCTWaiter.wait(for:[expectation],timeout:timeout),.completed)
    }
    private func shot(_ app:XCUIApplication,_ name:String){let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    func testPartialStreamFinalSentenceAndCacheSurviveRelaunchWithGenerationUnavailable() {
        continueAfterFailure=false;let app=launch();enter(app);expect("Ask about",app,timeout:6);shot(app,"Headline partial stream")
        expect("Ask about today's plans with confidence.",app);shot(app,"Headline final sentence")
        app.terminate();app.launchEnvironment["PIYALI_HEADLINE_FIXTURE"]="failure";app.launch();handleInitialPaperPencil(app);XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15));expect("Ask about today's plans with confidence.",app,timeout:5)
        XCTAssertFalse(app.otherElements["focusHeadlineLoading"].exists);shot(app,"Headline restored without generation")
    }
    func testSupportSwitchDuringStreamCannotShowTheOldLanguageAndPersistsNewHeadline() {
        continueAfterFailure=false;let app=launch();enter(app);expect("Ask about",app,timeout:6)
        app.buttons["productMenu"].tap();app.buttons["productPanel-settings"].tap();let picker=app.buttons["supportLanguagePicker"];XCTAssertTrue(picker.waitForExistence(timeout:5));picker.tap();app.buttons["French"].tap();app.buttons["productPanelClose"].tap()
        expect("Demande ton chemin avec confiance.",app,timeout:20);shot(app,"Headline switched to French")
        app.terminate();app.launchEnvironment["PIYALI_HEADLINE_FIXTURE"]="failure";app.launch();handleInitialPaperPencil(app);XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15));expect("Demande ton chemin avec confiance.",app,timeout:5)
    }
    func testUnavailableGenerationShowsOriginalSubtitleAndDoesNotBlockTheWelcome() {
        continueAfterFailure=false;let app=launch(fixture:"failure");enter(app);expect("Complete your tasks to earn an XP bonus",app,timeout:5);XCTAssertTrue(app.buttons["companionContinue"].exists);XCTAssertFalse(app.buttons["startDailyPractice"].isEnabled);shot(app,"Headline fallback subtitle")
    }
    func testArabicDarkHeadlineKeepsItsDirectionAndRestoresWithoutGeneration() {
        continueAfterFailure=false;let app=launch(fixture:"stream",language:"ar",theme:"dark");enter(app);expect("تحدث بثقة عن خططك لهذا اليوم.",app,timeout:8);shot(app,"Headline Arabic dark")
        app.terminate();app.launchEnvironment["PIYALI_HEADLINE_FIXTURE"]="failure";app.launch();handleInitialPaperPencil(app);XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15));expect("تحدث بثقة عن خططك لهذا اليوم.",app,timeout:5)
        XCTAssertLessThanOrEqual(app.staticTexts["focusHeadline"].frame.maxX,app.frame.maxX-12);XCTAssertGreaterThanOrEqual(app.staticTexts["focusHeadline"].frame.minX,12)
    }
}
