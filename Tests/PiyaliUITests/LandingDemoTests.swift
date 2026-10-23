import XCTest

@MainActor final class LandingDemoPlayTests:XCTestCase {
    private func launch(_ mode:String)->XCUIApplication {
        continueAfterFailure=false;let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_LANDING_DEMO_FIXTURE"]=mode;app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let start=app.buttons["landingDemoStart"];for _ in 0..<15 where !start.isHittable {app.swipeUp(velocity:.slow)};XCTAssertTrue(start.waitForExistence(timeout:10))
        // The production default also depends on timezone/browser language.
        // Select the same Spanish lesson as the scripted provider explicitly.
        let picker=app.buttons["landingDemoLanguage"];for _ in 0..<8 where !picker.isHittable {app.swipeDown(velocity:.slow)};picker.tap();app.buttons["Spanish"].tap()
        for _ in 0..<8 where !start.isHittable {app.swipeUp(velocity:.slow)}
        if picker.frame.minY>220 {let from=app.coordinate(withNormalizedOffset:CGVector(dx:0.97,dy:0.75));from.press(forDuration:0.1,thenDragTo:from.withOffset(CGVector(dx:0,dy:-min(300,picker.frame.minY-160))),withVelocity:.slow,thenHoldForDuration:0.4)};return app
    }
    private func shot(_ name:String,_ app:XCUIApplication) {let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    func testWholePublicLessonFinalFeedbackRetryAndLanguageResetRemainSignedOut() {
        let app=launch("complete");shot("Native public demo idle",app)
        let orb=app.buttons["landingDemoOrb"];XCTAssertTrue(orb.waitForExistence(timeout:5));orb.tap();XCTAssertEqual(orb.value as? String,"Loving reaction");shot("Native public demo orb boop",app)
        app.buttons["landingDemoStart"].tap();XCTAssertFalse(app.buttons["landingDemoLanguage"].isEnabled)
        let ended=NSPredicate(format:"label == %@","Nice practice! Ready for more?");let status=app.staticTexts["landingDemoStatus"];expectation(for:ended,evaluatedWith:status);waitForExpectations(timeout:35)
        XCTAssertTrue(app.textViews["landingDemoTutor"].label.contains("Goodbye!"));XCTAssertEqual(app.textViews["landingDemoLearner"].label,"gracias");shot("Native public demo finished unsaved lesson",app)
        XCTAssertTrue(app.buttons["landingDemoLanguage"].isEnabled);XCTAssertEqual(app.buttons["landingDemoStart"].label,"Try another short lesson")
        let finalText=app.textViews["landingDemoTutor"].label
        let grow=app.buttons["landingTab-grow"];for _ in 0..<8 where !grow.isHittable {app.swipeDown(velocity:.slow)};grow.tap();XCTAssertTrue(app.staticTexts["Vocabulary cards"].waitForExistence(timeout:5));app.buttons["landingTab-speak"].tap()
        XCTAssertEqual(app.textViews["landingDemoTutor"].label,finalText);XCTAssertTrue(app.buttons["landingDemoLanguage"].label.contains("Spanish"));XCTAssertEqual(app.buttons["landingDemoStart"].label,"Try another short lesson")
        app.buttons["landingDemoStart"].tap();app.buttons["landingDemoStart"].tap()
        XCTAssertEqual(app.buttons["landingDemoStart"].label,"Try it!")
        app.buttons["landingDemoLanguage"].tap();let japanese=app.buttons["Japanese (beta)"];XCTAssertTrue(japanese.waitForExistence(timeout:5));japanese.tap();XCTAssertTrue(app.textViews["landingDemoTutor"].label.contains("こんにちは"));XCTAssertFalse(status.exists)
        let name=app.textFields["entryName"];for _ in 0..<15 where !name.isHittable {app.coordinate(withNormalizedOffset:CGVector(dx:0.97,dy:0.2)).press(forDuration:0.05,thenDragTo:app.coordinate(withNormalizedOffset:CGVector(dx:0.97,dy:0.85)))};XCTAssertTrue(name.isHittable);XCTAssertTrue(app.buttons["entrySignIn"].exists)
    }
    func testPermissionRetryAndCapabilityChangeCloseTheLessonAndRestoreItsSample() {
        let app=launch("permission-retry");app.buttons["landingDemoStart"].tap()
        let status=app.staticTexts["landingDemoStatus"];XCTAssertTrue(status.waitForExistence(timeout:5));XCTAssertEqual(status.label,"Allow microphone access to try the lesson.");shot("Native public demo permission recovery",app)
        app.buttons["landingDemoStart"].tap();XCTAssertFalse(app.buttons["landingDemoLanguage"].isEnabled)
        let remember=app.buttons["landingTab-remember"];for _ in 0..<8 where !remember.isHittable {app.swipeDown(velocity:.slow)};remember.tap();XCTAssertTrue(app.staticTexts["Your first try"].waitForExistence(timeout:5))
        app.buttons["landingTab-speak"].tap();XCTAssertTrue(app.buttons["landingDemoLanguage"].isEnabled);XCTAssertEqual(app.buttons["landingDemoStart"].label,"Try it!");XCTAssertTrue(app.textViews["landingDemoTutor"].label.contains("hola"))
    }
    func testPendingStartupCanBeCanceledAndBackgroundedWithoutALateSession() {
        let app=launch("held-start");app.buttons["landingDemoStart"].tap();XCTAssertEqual(app.buttons["landingDemoStart"].label,"Cancel");app.buttons["landingDemoStart"].tap();XCTAssertEqual(app.buttons["landingDemoStart"].label,"Try it!")
        app.buttons["landingDemoStart"].tap();XCUIDevice.shared.press(.home);app.activate();XCTAssertTrue(app.buttons["landingDemoStart"].waitForExistence(timeout:10));XCTAssertEqual(app.buttons["landingDemoStart"].label,"Try it!");XCTAssertTrue(app.buttons["landingDemoLanguage"].isEnabled)
    }
}
