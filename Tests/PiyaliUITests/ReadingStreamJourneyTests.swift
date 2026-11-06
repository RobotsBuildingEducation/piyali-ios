import XCTest

@MainActor final class ReadingStreamJourneyTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication) {
        let button=app.buttons[id];XCTAssertTrue(button.waitForExistence(timeout:15))
        for _ in 0..<8 where !button.isHittable {app.swipeUp(velocity:.slow)}
        XCTAssertTrue(button.isHittable);button.tap()
    }
    func testDraftSentencePlaybackAndValidatedReview() {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_READING_FIXTURE":"1","PIYALI_READING_STREAM_FIXTURE":"1","PIYALI_READING_AUDIO_FIXTURE":"1","PIYALI_READING_TRANSLATION_STREAM_FIXTURE":"1","PIYALI_PRACTICE_FIXTURE":"delight:natural_or_weird"]
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en"]
        app.launch();let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Reading Learner");tap("entryKeyboardDone",app);tap("createAccount",app);tap("startLearning",app)
        tap("productMenu",app);tap("productModeMenu",app);tap("productMode-path",app);tap("introLink",app);tap("startLessonFromPreview",app)
        for _ in 0..<2 {if app.buttons["introStep-reading"].value as? String == "Current" {break};tap("skipLessonActivity",app)}
        XCTAssertTrue(app.staticTexts["readingDraftTitle"].waitForExistence(timeout:15))
        XCUIDevice.shared.press(.home);app.activate();XCTAssertTrue(app.staticTexts["readingDraftTitle"].waitForExistence(timeout:15))
        XCTAssertFalse(app.buttons["readingListen"].isEnabled);XCTAssertFalse(app.buttons["readingCheck"].exists);XCTAssertFalse(app.staticTexts["readingCompleted"].exists)
        let draft=app.descendants(matching:.any)["readingDraftPassage"];XCTAssertTrue(draft.waitForExistence(timeout:15));let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Reading incremental draft";shot.lifetime = .keepAlways;add(shot);draft.coordinate(withNormalizedOffset:CGVector(dx:0.25,dy:0.015)).tap()
        XCTAssertEqual(draft.value as? String,"Mi libreta verde está cerca de la ventana.");XCTAssertFalse(app.buttons["readingStop"].isEnabled)
        XCTAssertTrue(app.descendants(matching:.any)["readingPassage"].waitForExistence(timeout:20))
        XCTAssertFalse(app.staticTexts["readingDraftTitle"].exists);XCTAssertTrue(app.buttons["readingCheck"].exists);XCTAssertFalse(app.staticTexts["readingCompleted"].exists)
        tap("readingTranslate",app);let line=app.staticTexts["readingTranslation-0"];XCTAssertTrue(line.waitForExistence(timeout:10));XCTAssertEqual(line.label,"My green notebook is near the window.");XCTAssertFalse(app.buttons["readingTranslate"].isEnabled)
        let later=app.staticTexts["readingTranslation-1"];XCTAssertTrue(later.waitForExistence(timeout:10))
        let finalShot=XCTAttachment(screenshot:app.screenshot());finalShot.name="Validated Reading after incremental draft";finalShot.lifetime = .keepAlways;add(finalShot)
    }
}
