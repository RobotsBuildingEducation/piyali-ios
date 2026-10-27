import XCTest

@MainActor final class RPGPreparedPlayTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication){let b=app.buttons[id];XCTAssertTrue(b.waitForExistence(timeout:15));for _ in 0..<12 where !b.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(b.isHittable);b.tap()}
    private func open(_ app:XCUIApplication,_ fixture:RPGPlayFixture){tap("productMenu",app);tap("productModeMenu",app);tap("productMode-path",app);tap("lessonNode-"+fixture.lessonID,app);tap("startLessonFromPreview",app);XCTAssertTrue(app.otherElements["rpgWorld"].waitForExistence(timeout:20))}
    private func shot(_ name:String,_ app:XCUIApplication){let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    private func answer(_ text:String,_ app:XCUIApplication){let mic=app.buttons["rpgMicrophone"];XCTAssertTrue(mic.waitForExistence(timeout:5));mic.press(forDuration:1);app.buttons["Response"].tap();let field=app.textFields["rpgReply"];XCTAssertTrue(field.waitForExistence(timeout:5));field.tap();field.typeText(text+"\n")}
    func testPreparedChapterCancellationResumeRewardAndOfflineCachedReplay()throws{
        continueAfterFailure=false
        let fixture=try JSONDecoder().decode(RPGPlayFixture.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"rpg-prepared-play",withExtension:"json"))));XCTAssertEqual(fixture.steps.count,7)
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_HEADLINE_FIXTURE":"failure","PIYALI_RPG_PREPARED_FIXTURE":"prepared","PIYALI_RPG_SPEECH_DELAY_MS":"3000"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Prepared Learner");tap("entryKeyboardDone",app);tap("createAccount",app);tap("startLearning",app);tap("companionContinue",app);tap("gettingStartedGotIt",app);tap("placementNew",app);open(app,fixture)
        XCTAssertTrue(app.descendants(matching:.any)["rpgStatus"].label.contains("0/7"));shot("Native prepared chapter world",app)
        for step in fixture.steps.prefix(2){try rpgApproach(step,fixture,app);XCTAssertTrue(app.staticTexts["rpgSceneCaption"].exists);tap("rpgChoice-\(step.correct)",app);tap("rpgContinue",app)}
        let speech=fixture.steps[2];XCTAssertEqual(speech.mode,"speech");try rpgApproach(speech,fixture,app);answer(speech.example,app);tap("rpgCloseDialogue",app)
        XCTAssertTrue(app.descendants(matching:.any)["rpgStatus"].label.contains("2/7"));try rpgApproach(speech,fixture,app);XCTAssertTrue(app.buttons["rpgMicrophone"].exists);XCTAssertFalse(app.buttons["rpgContinue"].exists,"Closing a pending provider reply must not grade this turn")
        shot("Native prepared speech cancellation",app);answer(speech.example,app);XCTAssertTrue(app.buttons["rpgContinue"].waitForExistence(timeout:10));tap("rpgContinue",app);tap("rpgBack",app);app.terminate();app.launch();open(app,fixture)
        XCTAssertTrue(app.descendants(matching:.any)["rpgStatus"].label.contains("3/7"));shot("Native prepared chapter restored",app)
        for step in fixture.steps.dropFirst(3){try rpgApproach(step,fixture,app);if step.mode == "choice"{tap("rpgChoice-\(step.correct)",app)}else{answer(step.example,app)};XCTAssertTrue(app.buttons["rpgContinue"].waitForExistence(timeout:10));tap("rpgContinue",app)}
        XCTAssertTrue(app.buttons["rpgComplete"].waitForExistence(timeout:10));shot("Native prepared chapter recap",app);tap("rpgComplete",app);let bonus=app.staticTexts["lessonCompletionBonus"];XCTAssertTrue(bonus.waitForExistence(timeout:10));XCTAssertEqual(bonus.label,"+30");tap("continueLessonCompletion",app)
        app.terminate();app.launchEnvironment["PIYALI_RPG_PREPARED_FIXTURE"]="cache-only";app.launch();open(app,fixture);let status=app.descendants(matching:.any)["rpgStatus"];XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","0/7"),object:status)],timeout:15),.completed,"Prepared content must survive process relaunch when generation is unavailable");XCTAssertFalse(app.buttons["rpgComplete"].exists);shot("Native cached prepared replay",app);tap("rpgBack",app);XCTAssertFalse(bonus.exists)
    }
}
