import XCTest

@MainActor final class HelpChatJourneyTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication){let e=app.buttons[id];XCTAssertTrue(e.waitForExistence(timeout:15),id);XCTAssertTrue(e.isHittable,id);e.tap()}
    private func open(_ app:XCUIApplication){tap("productMenu",app);tap("productPanel-assistant",app);XCTAssertTrue(app.buttons["helpClose"].waitForExistence(timeout:5))}
    private func shot(_ title:String,_ app:XCUIApplication){let a=XCTAttachment(screenshot:app.screenshot());a.name=title;a.lifetime = .keepAlways;add(a)}
    private func question(_ value:String,_ app:XCUIApplication){let field=app.descendants(matching:.any)["assistantInput"];XCTAssertTrue(field.waitForExistence(timeout:5));field.tap();field.typeText(value);tap("helpSend",app)}
    func testRootHelpStreamingSaveNewLoadMorphemesErrorAndRelaunch(){
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_HELP_FIXTURE":"1","PIYALI_HEADLINE_FIXTURE":"failure"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch();handleInitialPaperPencil(app)
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Help Learner");tap("entryKeyboardDone",app);tap("createAccount",app);handleInitialPaperPencil(app);tap("startLearning",app);tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);tap("placementNew",app)
        open(app);XCTAssertGreaterThanOrEqual(app.buttons["helpMenu"].frame.width,31);XCTAssertGreaterThanOrEqual(app.buttons["helpVoice"].frame.height,31);XCTAssertFalse(app.buttons["helpSave"].isEnabled);shot("Native Help empty product",app)
        question("How do I say sister?",app);XCTAssertTrue(app.staticTexts.containing(NSPredicate(format:"label CONTAINS %@","Mi hermana vive aquí.")).firstMatch.waitForExistence(timeout:10));shot("Native Help streamed product",app);tap("helpSave",app);tap("helpMenu",app)
        let saved=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'helpLoad-'")).firstMatch;XCTAssertTrue(saved.waitForExistence(timeout:5));shot("Native Help saved menu product",app);tap("helpNewChat",app);XCTAssertTrue(app.staticTexts["helpEmptyPrompt"].exists)
        tap("helpClose",app);open(app);XCTAssertTrue(app.staticTexts["helpEmptyPrompt"].exists);tap("helpMenu",app);saved.tap();XCTAssertTrue(app.staticTexts.containing(NSPredicate(format:"label CONTAINS %@","Mi hermana vive aquí.")).firstMatch.waitForExistence(timeout:5))
        tap("helpMenu",app);let mode=app.switches["helpMorphemeMode"];XCTAssertTrue(mode.waitForExistence(timeout:5));mode.tap();XCTAssertEqual(mode.value as? String,"1");tap("helpNewChat",app);question("sister",app);XCTAssertTrue(app.staticTexts.containing(NSPredicate(format:"label CONTAINS %@","feminine")).firstMatch.waitForExistence(timeout:10));shot("Native Help morphemes product",app)
        tap("helpClose",app);app.terminate();app.launch();handleInitialPaperPencil(app);open(app);tap("helpMenu",app);XCTAssertEqual(mode.value as? String,"1");XCTAssertTrue(saved.waitForExistence(timeout:5));saved.tap();XCTAssertTrue(app.staticTexts.containing(NSPredicate(format:"label CONTAINS %@","Mi hermana vive aquí.")).firstMatch.waitForExistence(timeout:5))
        tap("helpMenu",app);mode.tap();tap("helpNewChat",app);question("FAIL_HELP",app);XCTAssertTrue(app.staticTexts.containing(NSPredicate(format:"label CONTAINS %@","Sorry, I couldn’t complete")).firstMatch.waitForExistence(timeout:10));shot("Native Help error product",app)
        tap("helpMenu",app);tap("helpNewChat",app);question("STOP_HELP",app);tap("helpSend",app);XCTAssertTrue(app.buttons["helpVoice"].isEnabled);tap("helpMenu",app);let deletion=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'helpDelete-'")).firstMatch;XCTAssertTrue(deletion.exists);deletion.tap();XCTAssertFalse(saved.exists);tap("helpNewChat",app);tap("helpClose",app)
        XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:5));XCTAssertFalse(app.staticTexts["lessonCompletionBonus"].exists)
    }
}
