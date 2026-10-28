import XCTest
@MainActor final class RPGTranslationPlayTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication){let b=app.buttons[id];XCTAssertTrue(b.waitForExistence(timeout:15));for _ in 0..<15 where !b.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(b.isHittable);b.tap()}
    private func open(_ app:XCUIApplication,_ fixture:RPGPlayFixture){tap("productMenu",app);tap("productModeMenu",app);tap("productMode-path",app);openPlacedBeginnerCourse(app);tap("lessonNode-"+fixture.lessonID,app);tap("startLessonFromPreview",app);XCTAssertTrue(app.otherElements["rpgWorld"].waitForExistence(timeout:20))}
    private func shot(_ title:String,_ app:XCUIApplication){let a=XCTAttachment(screenshot:app.screenshot());a.name=title;a.lifetime = .keepAlways;add(a)}
    func testTranslationStreamsUndoAndCloseRejectLateLinesWithoutChangingTheSavedTask()throws{
        continueAfterFailure=false
        let fixture=try JSONDecoder().decode(RPGPlayFixture.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"rpg-prepared-play",withExtension:"json")))),app=XCUIApplication()
        app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_HEADLINE_FIXTURE":"failure","PIYALI_RPG_PREPARED_FIXTURE":"prepared","PIYALI_RPG_TRANSLATION_FIXTURE":"stream"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Translation Learner");tap("entryKeyboardDone",app);tap("createAccount",app);tap("startLearning",app);tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);chooseA1Placement(app);open(app,fixture);try rpgApproach(fixture.steps[0],fixture,app)
        let prompt=app.staticTexts["rpgPrompt"];XCTAssertTrue(prompt.waitForExistence(timeout:5));XCTAssertEqual(prompt.label,"¡Hola! ¿Cómo te llamas?");tap("rpgTranslation",app)
        let first=app.staticTexts["rpgLineTranslation-0"];XCTAssertTrue(first.waitForExistence(timeout:5));XCTAssertEqual(first.label,"Hello!");XCTAssertFalse(app.staticTexts["rpgLineTranslation-1"].exists);shot("Native RPG translation partial",app)
        XCTAssertTrue(app.staticTexts["rpgLineTranslation-1"].waitForExistence(timeout:10));XCTAssertEqual(app.staticTexts["rpgLineTranslation-1"].label,"What is your name?");XCTAssertTrue(app.buttons["rpgChoice-2"].label.contains("Thank you"));shot("Native RPG translation complete",app)
        tap("rpgTranslation",app);XCTAssertTrue(prompt.waitForExistence(timeout:5));XCTAssertFalse(first.exists);XCTAssertTrue(app.staticTexts["rpgSceneCaption"].exists)
        tap("rpgTranslation",app);XCTAssertTrue(first.waitForExistence(timeout:5));tap("rpgCloseDialogue",app);try rpgApproach(fixture.steps[0],fixture,app)
        XCTAssertTrue(prompt.waitForExistence(timeout:5));XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:first)],timeout:6),.completed);XCTAssertTrue(app.descendants(matching:.any)["rpgStatus"].label.contains("0/7"));shot("Native RPG translation close recovery",app)
        tap("rpgBack",app);app.terminate();app.launch();open(app,fixture);try rpgApproach(fixture.steps[0],fixture,app);XCTAssertTrue(prompt.waitForExistence(timeout:5));XCTAssertFalse(first.exists);XCTAssertTrue(app.descendants(matching:.any)["rpgStatus"].label.contains("0/7"));XCTAssertFalse(app.staticTexts["lessonCompletionBonus"].exists);shot("Native RPG translation restored original",app);tap("rpgBack",app)
    }
}
