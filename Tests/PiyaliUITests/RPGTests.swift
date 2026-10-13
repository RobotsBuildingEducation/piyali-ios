import XCTest

@MainActor final class RPGPlayTests:XCTestCase {
    private struct Fixture:Decodable {
        struct Step:Decodable { let mode:String;let correct:Int;let example:String }
        let lessonID:String;let steps:[Step]
    }
    private func reveal(_ element:XCUIElement,in app:XCUIApplication) {
        _=element.waitForExistence(timeout:3)
        for _ in 0..<7 where !element.isHittable { app.swipeUp(velocity:.slow) }
        for _ in 0..<7 where !element.isHittable { app.swipeDown(velocity:.slow) }
        XCTAssertTrue(element.waitForExistence(timeout:10));XCTAssertTrue(element.isHittable)
    }
    private func tap(_ id:String,in app:XCUIApplication) { let element=app.buttons[id];reveal(element,in:app);element.tap() }
    private func open(_ app:XCUIApplication,lesson:String) {
        app.tabBars.buttons["Practice"].tap();tap("adventureLink",in:app)
        tap("rpgReview-"+lesson,in:app)
        XCTAssertTrue(app.staticTexts["rpgStatus"].waitForExistence(timeout:15))
    }
    func testActualAuthoredReviewRetriesSpeakingAndRecapSurviveRelaunch() throws {
        let url=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"rpg-play",withExtension:"json"))
        let fixture=try JSONDecoder().decode(Fixture.self,from:Data(contentsOf:url));XCTAssertEqual(fixture.steps.count,7)
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launch()
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:10));app.buttons["createAccount"].tap()
        XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:10));app.buttons["startLearning"].tap();open(app,lesson:fixture.lessonID)
        // Three genuine wrong choices reveal and advance with zero points.
        XCTAssertEqual(fixture.steps[0].mode,"choice");tap("rpgTalk",in:app)
        let wrong=(fixture.steps[0].correct+1)%3
        for _ in 0..<3 { tap("rpgChoice-\(wrong)",in:app) }
        tap("rpgContinue",in:app)
        app.terminate();app.launch();open(app,lesson:fixture.lessonID)
        XCTAssertTrue(app.staticTexts["rpgStatus"].label.contains("Task 2 / 7 · 0 / 800"))
        for step in fixture.steps.dropFirst() {
            tap("rpgTalk",in:app)
            if step.mode == "choice" { tap("rpgChoice-\(step.correct)",in:app) }
            else {
                let field=app.descendants(matching:.any)["rpgReply"];reveal(field,in:app);field.tap();field.typeText(step.example)
                if app.buttons["Done"].exists { app.buttons["Done"].tap() };tap("rpgSend",in:app)
            }
            tap("rpgContinue",in:app)
        }
        let finish=app.buttons["rpgComplete"];reveal(finish,in:app);XCTAssertTrue(finish.label.contains("+22 XP"));finish.tap()
        XCTAssertTrue(app.buttons["rpgComplete"].label.contains("saved"));XCTAssertFalse(app.buttons["rpgComplete"].isEnabled)
        app.terminate();app.launch();open(app,lesson:fixture.lessonID)
        reveal(app.buttons["rpgComplete"],in:app);XCTAssertFalse(app.buttons["rpgComplete"].isEnabled)
        app.tabBars.buttons["Account"].tap();reveal(app.staticTexts["22 total XP · 1 lessons completed"],in:app)
    }
}
