import XCTest

@MainActor final class IntroTutorialPlayTests:XCTestCase {
    private struct PlayFixture:Decodable { struct Step:Decodable { let mode:String;let correct:Int;let example:String };let steps:[Step] }
    private func reveal(_ element:XCUIElement,in app:XCUIApplication) {
        for _ in 0..<6 where !element.exists || !element.isHittable { app.swipeUp(velocity:.slow) }
        for _ in 0..<6 where !element.exists || !element.isHittable { app.swipeDown(velocity:.slow) }
        XCTAssertTrue(element.waitForExistence(timeout:5));XCTAssertTrue(element.isHittable)
    }
    private func next(_ app:XCUIApplication) { let button=app.buttons["introNext"];reveal(button,in:app);button.tap() }
    private func open(_ app:XCUIApplication) {
        let link=app.buttons["introLink"];XCTAssertTrue(link.waitForExistence(timeout:15))
        for _ in 0..<4 where !link.isHittable { app.swipeUp(velocity:.slow) };link.tap()
        XCTAssertTrue(app.staticTexts["introProgress"].waitForExistence(timeout:5))
    }
    func testGuideProgressAndOneRewardSurviveRelaunchWithoutPracticeCredit() {
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launch()
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:10));app.buttons["createAccount"].tap()
        XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:10));app.buttons["startLearning"].tap();open(app)
        for _ in 0..<2 { next(app) }
        reveal(app.staticTexts["introProgress"],in:app);XCTAssertTrue(app.staticTexts["introProgress"].label.contains("2 / 6"));app.terminate();app.launch();open(app)
        reveal(app.staticTexts["introProgress"],in:app);XCTAssertTrue(app.staticTexts["introProgress"].label.contains("2 / 6"))
        for _ in 0..<4 { next(app) }
        reveal(app.buttons["introFinish"],in:app);XCTAssertTrue(app.buttons["introFinish"].waitForExistence(timeout:5));XCTAssertTrue(app.buttons["introFinish"].label.contains("+50 XP"));app.buttons["introFinish"].tap()
        XCTAssertFalse(app.buttons["introFinish"].isEnabled);app.terminate();app.launch();open(app)
        reveal(app.buttons["introFinish"],in:app);XCTAssertTrue(app.buttons["introFinish"].waitForExistence(timeout:5));XCTAssertFalse(app.buttons["introFinish"].isEnabled)
        app.tabBars.buttons["Account"].tap();let total=app.staticTexts["50 total XP · 1 lessons completed"]
        for _ in 0..<5 where !total.isHittable { app.swipeUp(velocity:.slow) };XCTAssertTrue(total.waitForExistence(timeout:5))
    }
    func testAuthoredIntroAdventureReturnsToGuideWithoutClaimingUnitXP() throws {
        let fixture=try JSONDecoder().decode(PlayFixture.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"intro-play",withExtension:"json"))))
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launch()
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:10));app.buttons["createAccount"].tap()
        XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:10));app.buttons["startLearning"].tap();open(app)
        for _ in 0..<5 { next(app) }
        let adventure=app.buttons["Play introductory adventure"];reveal(adventure,in:app);adventure.tap()
        XCTAssertTrue(app.staticTexts["rpgStatus"].waitForExistence(timeout:15))
        func tap(_ id:String) { let button=app.buttons[id];reveal(button,in:app);button.tap() }
        for step in fixture.steps {
            tap("rpgTalk")
            if step.mode == "choice" { tap("rpgChoice-\(step.correct)") }
            else { let field=app.descendants(matching:.any)["rpgReply"];reveal(field,in:app);field.tap();field.typeText(step.example);if app.buttons["Done"].exists { app.buttons["Done"].tap() };tap("rpgSend") }
            tap("rpgContinue")
        }
        XCTAssertFalse(app.buttons["rpgComplete"].exists);tap("Continue introduction")
        reveal(app.buttons["introFinish"],in:app);XCTAssertTrue(app.buttons["introFinish"].label.contains("+50 XP"))
        app.buttons["introFinish"].tap();XCTAssertFalse(app.buttons["introFinish"].isEnabled)
        app.tabBars.buttons["Account"].tap();reveal(app.staticTexts["50 total XP · 1 lessons completed"],in:app)
    }
}
