import XCTest
@MainActor final class StandardBodyJourneyTests:XCTestCase {
    private func element(_ id:String,_ app:XCUIApplication)->XCUIElement{app.descendants(matching:.any).matching(identifier:id).firstMatch}
    private func reveal(_ e:XCUIElement,_ app:XCUIApplication){for _ in 0..<12 where !e.isHittable{if e.exists,e.frame.midY<app.frame.midY{app.swipeDown(velocity:.slow)}else{app.swipeUp(velocity:.slow)}};if !e.isHittable{shot("Missing standard interaction",app)};XCTAssertTrue(e.isHittable)}
    private func tap(_ id:String,_ app:XCUIApplication){let e=element(id,app);XCTAssertTrue(e.waitForExistence(timeout:10));reveal(e,app);e.tap()}
    private func shot(_ name:String,_ app:XCUIApplication){let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    private func launch(_ variant:String)->XCUIApplication {
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_HEADLINE_FIXTURE":"failure","PIYALI_PRACTICE_JUDGE_FIXTURE":"offered-reference","PIYALI_PRACTICE_FIXTURE":"standard:"+variant];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Standard Learner");tap("entryKeyboardDone",app);tap("createAccount",app);chooseEnglishSpanishOnboarding(app);tap("startLearning",app);tap("companionContinue",app);tap("gettingStartedGotIt",app);chooseA1Placement(app);open(app);return app
    }
    private func open(_ app:XCUIApplication){tap("productMenu",app);tap("productModeMenu",app);tap("productMode-path",app);if !app.buttons["lessonNode-lesson-pre-a1-1-1"].exists{tap("lessonPreviousLevel",app)};tap("lessonNode-lesson-pre-a1-1-1",app);tap("startLessonFromPreview",app);XCTAssertTrue(element("typedQuestionPrompt",app).waitForExistence(timeout:10))}
    private func checkWrong(_ app:XCUIApplication){tap("checkTypedAnswer",app);XCTAssertTrue(app.staticTexts["practiceVerdict"].waitForExistence(timeout:10));XCTAssertTrue(app.staticTexts["practiceVerdict"].label.contains("Try again"))}
    private func correct(_ xp:Int,_ app:XCUIApplication){tap("checkTypedAnswer",app);XCTAssertTrue(app.buttons["nextTypedQuestion"].waitForExistence(timeout:10));XCTAssertTrue(app.staticTexts["practiceVerdict"].label.contains("+\(xp) XP"))}
    private func drag(_ source:String,to target:String,_ app:XCUIApplication){let a=element(source,app),b=element(target,app);XCTAssertTrue(a.waitForExistence(timeout:10));XCTAssertTrue(b.waitForExistence(timeout:10));reveal(a,app);a.press(forDuration:1,thenDragTo:b)}
    func testMatchingTapNativeDragReturnSwapRetryAndFreshReentry() {
        continueAfterFailure=false;let app=launch("match");XCTAssertFalse(app.buttons["checkTypedAnswer"].isEnabled)
        drag("standardMatchBank-0",to:"standardSlot-0",app);XCTAssertTrue(app.buttons["standardMatchPlaced-0"].waitForExistence(timeout:5));drag("standardMatchPlaced-0",to:"standardBank",app);XCTAssertTrue(app.buttons["standardMatchBank-0"].waitForExistence(timeout:5))
        tap("standardMatchBank-1",app);tap("standardMatchBank-0",app);tap("standardMatchBank-2",app);checkWrong(app);shot("Native standard matching incorrect pairs",app)
        drag("standardMatchPlaced-1",to:"standardSlot-0",app);XCTAssertEqual(app.buttons["standardMatchPlaced-0"].label,"hello");XCTAssertEqual(app.buttons["standardMatchPlaced-1"].label,"goodbye");correct(6,app);XCTAssertFalse(app.buttons["standardMatchPlaced-0"].isEnabled);shot("Native standard matching swapped correct pairs",app)
        app.terminate();app.launch();open(app);XCTAssertTrue(app.buttons["standardMatchBank-0"].waitForExistence(timeout:10));XCTAssertFalse(app.buttons["standardMatchPlaced-0"].exists);XCTAssertFalse(app.staticTexts["practiceVerdict"].exists);XCTAssertFalse(app.buttons["checkTypedAnswer"].isEnabled)
    }
    func testSingleAndMultipleChoiceCardsSelectToggleRetryAndLock() {
        continueAfterFailure=false
        for variant in ["mc-buttons","ma-buttons"]{let app=launch(variant);XCTAssertFalse(app.buttons["checkTypedAnswer"].isEnabled);tap("typedChoice-1",app);checkWrong(app)
            if variant == "ma-buttons"{tap("typedChoice-1",app);XCTAssertFalse(app.buttons["checkTypedAnswer"].isEnabled);tap("typedChoice-0",app);XCTAssertTrue(app.buttons["checkTypedAnswer"].isEnabled);tap("typedChoice-1",app)}else{tap("typedChoice-0",app)}
            correct(variant == "mc-buttons" ? 5:6,app);XCTAssertFalse(app.buttons["typedChoice-0"].isEnabled);shot("Native standard \(variant) correct cards",app);app.terminate()
        }
    }
    func testInlineSingleChoiceTapReplaceNativeDragAndReturnBeforeRetry() {
        continueAfterFailure=false;let app=launch("mc-drag");tap("typedWord-1",app);XCTAssertTrue(app.buttons["typedSelected-0"].waitForExistence(timeout:5));tap("typedSelected-0",app);XCTAssertTrue(app.buttons["typedWord-1"].waitForExistence(timeout:5))
        drag("typedWord-0",to:"standardSlot-0",app);XCTAssertTrue(app.buttons["typedSelected-0"].waitForExistence(timeout:5));drag("typedSelected-0",to:"standardBank",app);XCTAssertTrue(app.buttons["typedWord-0"].waitForExistence(timeout:5));XCTAssertFalse(app.buttons["checkTypedAnswer"].isEnabled)
        tap("typedWord-1",app);checkWrong(app);tap("typedWord-0",app);XCTAssertEqual(app.buttons["typedSelected-0"].label,"como");correct(5,app);shot("Native inline single-choice answer",app)
    }
    func testMultipleInlineBlanksRequireEverySlotAndPreserveHolesThroughRetry() {
        continueAfterFailure=false;let app=launch("ma-drag");tap("typedWord-0",app);XCTAssertFalse(app.buttons["checkTypedAnswer"].isEnabled);tap("typedWord-1",app);XCTAssertTrue(app.buttons["checkTypedAnswer"].isEnabled);tap("typedSelected-0",app);XCTAssertFalse(app.buttons["checkTypedAnswer"].isEnabled);XCTAssertEqual(app.buttons["typedSelected-1"].label,"padre")
        drag("typedWord-2",to:"standardSlot-0",app);checkWrong(app);drag("typedWord-0",to:"standardSlot-0",app);XCTAssertEqual(app.buttons["typedSelected-0"].label,"madre");XCTAssertEqual(app.buttons["typedSelected-1"].label,"padre");correct(6,app);shot("Native multiple inline blank repair",app)
    }
    func testFillUsesOriginalInputHelpAudioAndTypedRetry() {
        continueAfterFailure=false;let app=launch("fill"),field=app.textFields["typedPracticeAnswer"];XCTAssertFalse(app.buttons["typedPracticeMicrophone"].exists);XCTAssertTrue(app.buttons["typedPracticeListen"].exists);XCTAssertTrue(app.buttons["typedPracticeHelp"].exists);field.tap();field.typeText("WRONG_FIXTURE");tap("practiceKeyboardDone",app);checkWrong(app);field.tap();field.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:13)+"pan");tap("practiceKeyboardDone",app);correct(5,app);XCTAssertFalse(field.isEnabled);shot("Native standard fill correct input",app)
    }
}
