import XCTest

@MainActor final class RPGPlayTests:XCTestCase {
    private typealias Fixture=RPGPlayFixture
    private func reveal(_ element:XCUIElement,_ app:XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout:15))
        for _ in 0..<15 where !element.isHittable{app.swipeUp(velocity:.slow)}
        XCTAssertTrue(element.isHittable)
    }
    private func tap(_ id:String,_ app:XCUIApplication){let button=app.buttons[id];reveal(button,app);button.tap()}
    private func shot(_ name:String,_ app:XCUIApplication){let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    private func path(_ app:XCUIApplication){tap("productMenu",app);tap("productModeMenu",app);tap("productMode-path",app);openPlacedBeginnerCourse(app)}
    private func open(_ app:XCUIApplication,_ fixture:Fixture,fromHome:Bool=true){if fromHome{path(app)};tap("lessonNode-"+fixture.lessonID,app);tap("startLessonFromPreview",app);XCTAssertTrue(app.otherElements["rpgWorld"].waitForExistence(timeout:20));XCTAssertFalse(app.buttons["productMenu"].isHittable,"Games occupy the full product viewport")}
    func testActualCourseReviewMovementRetriesSpeakingRecapAndRewardSurviveRelaunch()throws {
        continueAfterFailure=false
        let fixture=try JSONDecoder().decode(Fixture.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"rpg-play",withExtension:"json"))));XCTAssertEqual(fixture.steps.count,3)
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_HEADLINE_FIXTURE":"failure"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Adventure Learner");tap("entryKeyboardDone",app);tap("createAccount",app);tap("startLearning",app)
        tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);chooseA1Placement(app)
        open(app,fixture);shot("Native source-art course game",app);tap("rpgHelp",app);XCTAssertTrue(app.staticTexts["helpEmptyPrompt"].waitForExistence(timeout:5));shot("Native RPG Help drawer",app);tap("helpClose",app);try rpgExamineCounterFromDistance(fixture,app)
        tap("rpgQuest",app);shot("Native course quest log",app);app.buttons["Close dialogue"].tap()
        try rpgApproach(fixture.steps[0],fixture,app);shot("Native RPG choice",app)
        let wrong=(fixture.steps[0].correct+1)%3;for _ in 0..<3{tap("rpgChoice-\(wrong)",app)};tap("rpgContinue",app)
        tap("rpgBack",app);XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:5));app.terminate();app.launch();open(app,fixture)
        XCTAssertTrue(app.descendants(matching:.any)["rpgStatus"].label.contains("1/3"));shot("Native RPG pending task restored",app)
        for step in fixture.steps.dropFirst(){try rpgApproach(step,fixture,app);if step.mode == "choice"{tap("rpgChoice-\(step.correct)",app)}else{let mic=app.buttons["rpgMicrophone"];XCTAssertTrue(mic.waitForExistence(timeout:5));mic.press(forDuration:1);tap("Response",app);let field=app.descendants(matching:.any)["rpgReply"];reveal(field,app);field.tap();field.typeText(step.example+"\n");XCTAssertTrue(app.buttons["rpgContinue"].waitForExistence(timeout:10))};shot("Native RPG resolved \(step.mode)",app);tap("rpgContinue",app)}
        XCTAssertTrue(app.buttons["rpgComplete"].waitForExistence(timeout:10));shot("Native RPG completion",app);tap("rpgComplete",app)
        let bonus=app.staticTexts["lessonCompletionBonus"];XCTAssertTrue(bonus.waitForExistence(timeout:10));XCTAssertEqual(bonus.label,"+15");shot("Native actual game lesson reward",app);tap("continueLessonCompletion",app)
        app.terminate();app.launch();open(app,fixture);XCTAssertTrue(app.descendants(matching:.any)["rpgStatus"].label.contains("0/3"));tap("rpgBack",app);XCTAssertFalse(bonus.exists,"Reopening a completed game starts practice without another reward")
    }
}
