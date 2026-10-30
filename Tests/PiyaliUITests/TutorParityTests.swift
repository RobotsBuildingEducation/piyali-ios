import XCTest

@MainActor final class TutorParityTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication){let button=app.buttons[id];XCTAssertTrue(button.waitForExistence(timeout:15));XCTAssertTrue(button.isHittable);button.tap()}
    private func photo(_ name:String,_ app:XCUIApplication){let shot=XCTAttachment(screenshot:app.screenshot());shot.name=name;shot.lifetime = .keepAlways;add(shot)}
    private func open(_ app:XCUIApplication){tap("productMenu",app);tap("productModeMenu",app);tap("productMode-tutor",app);XCTAssertTrue(app.staticTexts["tutorLessonTitle"].waitForExistence(timeout:15))}
    private func start()->XCUIApplication {
        continueAfterFailure=false;let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_TUTOR_FIXTURE":"1"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch();handleInitialPaperPencil(app)
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Tutor Learner");if app.buttons["entryKeyboardDone"].exists{app.buttons["entryKeyboardDone"].tap()};tap("createAccount",app);handleInitialPaperPencil(app);tap("startLearning",app);open(app);return app
    }
    func testSourceVoiceEntryPathLockedPreviewWelcomeMutePauseResumeAndPrivateRelaunch(){
        let app=start();XCTAssertFalse(app.textFields["Message your tutor"].exists);XCTAssertFalse(app.buttons["tutorHistory"].isEnabled);XCTAssertTrue(app.staticTexts["tutorLessonTitle"].label.contains("Tutorial"));photo("Native Tutor product entry",app)
        tap("tutorLessons",app);photo("Native Tutor product path",app);tap("tutorNode-lesson-tutorial-1",app);tap("tutorPreviewObjectives",app);XCTAssertEqual(app.buttons["tutorPreviewObjectives"].value as? String,"Expanded");photo("Native Tutor product introductory preview",app);XCTAssertTrue(app.buttons["tutorPreviewStart"].label.contains("Start game"));XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label BEGINSWITH %@","learn to say hello")).firstMatch.exists);tap("tutorPreviewClose",app)
        let locked=app.buttons["tutorNode-lesson-pre-a1-1-1"];if !locked.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(locked.waitForExistence(timeout:5));locked.tap();XCTAssertTrue(app.otherElements["tutorPreviewLocked"].exists || app.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","This lesson is locked")).firstMatch.exists);XCTAssertFalse(app.buttons["tutorPreviewStart"].isEnabled);tap("tutorPreviewClose",app);tap("tutorPathClose",app)
        tap("tutorStart",app);let reply=app.staticTexts["tutorLatestReply"];XCTAssertTrue(reply.waitForExistence(timeout:10));XCTAssertTrue(reply.label.contains("Welcome"));tap("tutorMute",app);tap("tutorPause",app);XCTAssertEqual(app.staticTexts["tutorVoiceStatus"].label.uppercased(),"PAUSED");photo("Native Tutor paused",app);tap("tutorPause",app);XCTAssertEqual(app.buttons["tutorMute"].label,"Unmute microphone");tap("tutorEnd",app)
        tap("tutorHistory",app);XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","Welcome!")).firstMatch.exists);app.buttons["Close"].tap();app.terminate();app.launch();handleInitialPaperPencil(app);open(app);XCTAssertFalse(app.staticTexts["tutorLatestReply"].exists);XCTAssertFalse(app.buttons["tutorHistory"].isEnabled);photo("Native Tutor fresh private reconnect",app)
    }
}
