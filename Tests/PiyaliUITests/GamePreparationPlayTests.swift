import XCTest
@MainActor final class GamePreparationPlayTests:XCTestCase{
    private func tap(_ id:String,_ app:XCUIApplication){let b=app.buttons[id];XCTAssertTrue(b.waitForExistence(timeout:15));for _ in 0..<15 where !b.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(b.isHittable);b.tap()}
    private func preview(_ app:XCUIApplication){tap("productMenu",app);tap("productModeMenu",app);tap("productMode-path",app);openPlacedBeginnerCourse(app);tap("lessonNode-unit-pre-a1-people-game",app)}
    private func shot(_ name:String,_ app:XCUIApplication){let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    func testCoursePreparationCanMoveCancelRetryAndHandoffWithoutStartingCancelledWork()throws{
        continueAfterFailure=false;let app=XCUIApplication()
        app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_HEADLINE_FIXTURE":"failure","PIYALI_RPG_PREPARED_FIXTURE":"prepared","PIYALI_RPG_PREPARED_DELAY_MS":"10000","PIYALI_GAME_LOADER_SEED":"7"]
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Map Learner");tap("entryKeyboardDone",app);tap("createAccount",app);tap("startLearning",app);tap("companionContinue",app);tap("gettingStartedGotIt",app);chooseA1Placement(app);preview(app);tap("startLessonFromPreview",app)
        let map=app.otherElements["gamePreparationWorld"];XCTAssertTrue(map.waitForExistence(timeout:8));let before=map.value as? String;map.swipeLeft(velocity:.slow);XCTAssertNotEqual(map.value as? String,before);shot("Native preparation playable map",app);tap("cancelGamePreparation",app)
        XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:8));XCTAssertFalse(app.otherElements["rpgWorld"].exists);XCTAssertFalse(app.staticTexts["lessonCompletionBonus"].exists);shot("Native preparation cancelled to course",app)
        app.terminate();app.launchEnvironment["PIYALI_RPG_PREPARED_DELAY_MS"]="0";app.launch();preview(app);tap("startLessonFromPreview",app);XCTAssertTrue(map.waitForExistence(timeout:8));shot("Native preparation retry",app)
        XCTAssertTrue(app.otherElements["rpgWorld"].waitForExistence(timeout:20));XCTAssertTrue(app.descendants(matching:.any)["rpgStatus"].label.contains("0/7"));XCTAssertFalse(app.staticTexts["lessonCompletionBonus"].exists);shot("Native preparation original game handoff",app);tap("rpgBack",app)
        app.terminate();app.launch();preview(app);tap("startLessonFromPreview",app);XCTAssertTrue(map.waitForExistence(timeout:8));XCTAssertTrue(app.otherElements["rpgWorld"].waitForExistence(timeout:20));XCTAssertTrue(app.descendants(matching:.any)["rpgStatus"].label.contains("0/7"));shot("Native preparation resumed saved chapter",app);tap("rpgBack",app)
    }
}
