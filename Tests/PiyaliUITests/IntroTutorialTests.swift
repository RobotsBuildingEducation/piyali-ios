import XCTest

@MainActor final class IntroTutorialPlayTests:XCTestCase {
    private struct PlayFixture:Decodable { struct Step:Decodable { let mode:String;let correct:Int;let example:String };let steps:[Step] }
    private func reveal(_ element:XCUIElement,in app:XCUIApplication) { for _ in 0..<8 where !element.isHittable { app.swipeUp(velocity:.slow) };XCTAssertTrue(element.isHittable) }
    private func launch()->XCUIApplication {
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_PRACTICE_FIXTURE"]="delight:natural_or_weird"
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Intro Learner");if app.buttons["entryKeyboardDone"].exists { app.buttons["entryKeyboardDone"].tap() };app.buttons["createAccount"].tap();XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:20));app.buttons["startLearning"].tap();return app
    }
    private func path(_ app:XCUIApplication) { XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));app.buttons["productMenu"].tap();app.buttons["productModeMenu"].tap();app.buttons["productMode-path"].tap() }
    private func open(_ app:XCUIApplication) { path(app);XCTAssertTrue(app.buttons["introLink"].waitForExistence(timeout:15));app.buttons["introLink"].tap();XCTAssertTrue(app.buttons["startLessonFromPreview"].waitForExistence(timeout:5));app.buttons["startLessonFromPreview"].tap() }
    private func skip(_ app:XCUIApplication) { let button=app.buttons.matching(NSPredicate(format:"identifier IN %@",["skipLessonActivity","skipIntroActivity","realtimeSkip"])).firstMatch;XCTAssertTrue(button.waitForExistence(timeout:10));reveal(button,in:app);button.tap() }
    func testInlineSequenceResumesAndFinishesWithOneBonusAfterAllSixActivities() {
        continueAfterFailure=false;let app=launch();open(app)
        XCTAssertTrue(app.buttons["introStep-vocabulary"].waitForExistence(timeout:5));XCTAssertEqual(app.buttons["introStep-vocabulary"].value as? String,"Current");XCTAssertFalse(app.buttons["Try Vocabulary"].exists)
        skip(app);XCTAssertEqual(app.buttons["introStep-grammar"].value as? String,"Current");skip(app);XCTAssertEqual(app.buttons["introStep-reading"].value as? String,"Current")
        app.terminate();app.launch();open(app);XCTAssertTrue(app.buttons["introStep-reading"].waitForExistence(timeout:5));XCTAssertEqual(app.buttons["introStep-reading"].value as? String,"Current");XCTAssertEqual(app.buttons["introStep-vocabulary"].value as? String,"Completed")
        skip(app);skip(app)
        XCTAssertTrue(app.staticTexts["realtimeGoal"].waitForExistence(timeout:5));XCTAssertEqual(app.staticTexts["realtimeGoal"].label,"Say hello");XCTAssertTrue(app.buttons["realtimeStart"].isEnabled);XCTAssertFalse(app.buttons["End session"].exists,"Entering realtime does not open the microphone")
        let voice=XCTAttachment(screenshot:app.screenshot());voice.name="Native introductory realtime goal waits for the learner";voice.lifetime = .keepAlways;add(voice)
        skip(app);XCTAssertTrue(app.buttons["skipIntroActivity"].waitForExistence(timeout:10));skip(app)
        let bonus=app.staticTexts["lessonCompletionBonus"];XCTAssertTrue(bonus.waitForExistence(timeout:10));XCTAssertEqual(bonus.label,"+50");app.buttons["continueLessonCompletion"].tap()
        XCTAssertTrue(app.buttons["lessonNode-lesson-pre-a1-1-1"].waitForExistence(timeout:5));XCTAssertTrue(app.buttons["lessonNode-lesson-pre-a1-1-1"].isEnabled)
        app.terminate();app.launch();path(app);XCTAssertTrue(app.buttons["lessonNode-lesson-pre-a1-1-1"].waitForExistence(timeout:10));XCTAssertTrue(app.buttons["lessonNode-lesson-pre-a1-1-1"].isEnabled);XCTAssertFalse(bonus.exists)
    }
    func testAuthoredIntroAdventureFinishesTheInlineSequenceWithoutClaimingUnitXP() throws {
        continueAfterFailure=false;let fixture=try JSONDecoder().decode(PlayFixture.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"intro-play",withExtension:"json"))))
        let app=launch();open(app);for _ in 0..<5 { skip(app) };XCTAssertTrue(app.staticTexts["rpgStatus"].waitForExistence(timeout:15))
        func tap(_ id:String) { let button=app.buttons[id];reveal(button,in:app);button.tap() }
        for step in fixture.steps {
            tap("rpgTalk")
            if step.mode == "choice" { tap("rpgChoice-\(step.correct)") }
            else { let field=app.descendants(matching:.any)["rpgReply"];reveal(field,in:app);field.tap();field.typeText(step.example);if app.buttons["Done"].exists { app.buttons["Done"].tap() };tap("rpgSend") }
            tap("rpgContinue")
        }
        XCTAssertFalse(app.buttons["rpgComplete"].exists);tap("Continue introduction");XCTAssertTrue(app.staticTexts["lessonCompletionBonus"].waitForExistence(timeout:10));XCTAssertEqual(app.staticTexts["lessonCompletionBonus"].label,"+50")
    }
}
