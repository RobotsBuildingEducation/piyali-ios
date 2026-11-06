import XCTest

@MainActor final class GoalMemoryJourneyTests:XCTestCase {
    private func element(_ id:String,_ app:XCUIApplication)->XCUIElement{app.descendants(matching:.any).matching(identifier:id).firstMatch}
    private func tap(_ id:String,_ app:XCUIApplication){let e=element(id,app);XCTAssertTrue(e.waitForExistence(timeout:15),id);XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:e)],timeout:15),.completed,id);for _ in 0..<8 where !e.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(e.isHittable,id);e.tap()}
    private func shot(_ name:String,_ app:XCUIApplication){let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    private func memory(_ app:XCUIApplication){tap("productMenu",app);tap("productPanel-memory",app);XCTAssertTrue(app.buttons["memoryTab-repairs"].waitForExistence(timeout:10))}
    private func switchMode(_ mode:String,_ app:XCUIApplication){tap("productMenu",app);tap("productModeMenu",app);tap("productMode-"+mode,app)}
    private func wrong(_ app:XCUIApplication){let input=app.textFields["typedPracticeAnswer"];XCTAssertTrue(input.waitForExistence(timeout:15));input.tap();input.typeText("WRONG_FIXTURE");tap("practiceKeyboardDone",app);tap("checkTypedAnswer",app);XCTAssertTrue(app.staticTexts["practiceVerdict"].waitForExistence(timeout:10));XCTAssertTrue(app.staticTexts["practiceVerdict"].label.contains("Try again"))}
    func testFocusedMissBecomesGoalEvidenceCachedGoalReopensAndOrdinaryMissStillRepairsAfterRelaunch() {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_GOAL_PRACTICE_FIXTURE":"lesson","PIYALI_MEMORY_CAPTURE_ONLY":"1","PIYALI_HEADLINE_FIXTURE":"failure","PIYALI_PRACTICE_FIXTURE":"standard:fill","PIYALI_PRACTICE_JUDGE_FIXTURE":"offered-reference"]
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch();handleInitialPaperPencil(app)
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Goal Memory Learner");tap("entryKeyboardDone",app);tap("createAccount",app);handleInitialPaperPencil(app);chooseEnglishSpanishOnboarding(app);tap("startLearning",app);tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);chooseA1Placement(app)
        tap("startDailyPractice",app);let opened=app.buttons["goalFocusSummary"].waitForExistence(timeout:15);if !opened{shot("Native Goal route failure",app)};XCTAssertTrue(opened,app.debugDescription);wrong(app);shot("Native focused Goal wrong answer",app)
        memory(app)
        let repairs=app.descendants(matching:.any).matching(NSPredicate(format:"identifier BEGINSWITH 'memoryRepair-'"));XCTAssertEqual(repairs.count,0)
        tap("memoryTab-goals",app);XCTAssertTrue(app.staticTexts["La niña come ___."].waitForExistence(timeout:10));XCTAssertTrue(app.staticTexts["WRONG_FIXTURE"].exists);shot("Native Goal slip saved as open capability without a repair",app);tap("productPanelClose",app)
        let field=app.textFields["typedPracticeAnswer"];field.tap();field.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:13)+"pan");tap("practiceKeyboardDone",app);tap("checkTypedAnswer",app);XCTAssertTrue(app.buttons["nextTypedQuestion"].waitForExistence(timeout:10));XCTAssertTrue(app.staticTexts["practiceVerdict"].label.contains("+5 XP"))
        switchMode("focus",app);tap("startDailyPractice",app);XCTAssertTrue(app.buttons["goalFocusSummary"].waitForExistence(timeout:15));XCTAssertTrue(app.textFields["typedPracticeAnswer"].waitForExistence(timeout:10));shot("Native cached Goal reopens with pending evidence",app)
        switchMode("path",app);if !app.buttons["lessonNode-lesson-pre-a1-1-1"].exists{tap("lessonPreviousLevel",app)};tap("lessonNode-lesson-pre-a1-1-1",app);tap("startLessonFromPreview",app);wrong(app)
        memory(app);XCTAssertEqual(repairs.count,1);shot("Native ordinary practice miss stays in Repairs",app);tap("memoryTab-goals",app);XCTAssertTrue(app.staticTexts["WRONG_FIXTURE"].exists);tap("productPanelClose",app)
        app.terminate();app.launch();handleInitialPaperPencil(app);XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["goalFocusSummary"].exists)
        memory(app);XCTAssertEqual(repairs.count,1);tap("memoryTab-goals",app);XCTAssertTrue(app.staticTexts["La niña come ___."].waitForExistence(timeout:10));XCTAssertTrue(app.staticTexts["WRONG_FIXTURE"].exists);shot("Native Goal evidence and ordinary repair restore without active focus",app)
    }
}
