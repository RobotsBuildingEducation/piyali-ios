import XCTest

@MainActor final class MemoryJourneyTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication){let button=app.buttons[id];XCTAssertTrue(button.waitForExistence(timeout:15),id);XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:button)],timeout:10),.completed,id);for _ in 0..<6 where !button.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(button.isHittable,id);button.tap()}
    private func photo(_ name:String,_ app:XCUIApplication){let shot=XCTAttachment(screenshot:app.screenshot());shot.name=name;shot.lifetime = .keepAlways;add(shot)}
    private func launch(automaticJourney:Bool=false,practiceKind:String?=nil)->XCUIApplication {
        continueAfterFailure=false;let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_MEMORY_FIXTURE":"1"];if let practiceKind{app.launchEnvironment["PIYALI_PRACTICE_FIXTURE"]=practiceKind};if automaticJourney{app.launchEnvironment["PIYALI_JOURNEY_PROMPT_FIXTURE"]="1"};app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Memory Learner");if app.buttons["entryKeyboardDone"].exists{app.buttons["entryKeyboardDone"].tap()};tap("createAccount",app);tap("startLearning",app);if !automaticJourney{open(app)};return app
    }
    private func open(_ app:XCUIApplication){tap("productMenu",app);tap("productPanel-memory",app);XCTAssertTrue(app.buttons["memoryTab-repairs"].waitForExistence(timeout:10))}
    func testAutomaticMilestoneWaitsForQuietAcknowledgesAndOpensJourneyWithoutRepeating(){
        let app=launch(automaticJourney:true)
        XCTAssertTrue(app.buttons["journeyCapture"].waitForExistence(timeout:15));photo("Native automatically prompted Journey milestone",app)
        tap("View Journey",app);XCTAssertTrue(app.buttons["memoryTab-journey"].waitForExistence(timeout:10));XCTAssertEqual(app.buttons["memoryTab-journey"].isSelected,true);tap("productPanelClose",app)
        open(app);XCTAssertTrue(app.buttons["memoryTab-repairs"].isSelected);tap("productPanelClose",app)
        let duplicate=XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == true"),object:app.buttons["journeyCapture"])
        XCTAssertEqual(XCTWaiter.wait(for:[duplicate],timeout:3),.timedOut)
        app.terminate();app.launch();XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15))
        let restored=XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == true"),object:app.buttons["journeyCapture"])
        XCTAssertEqual(XCTWaiter.wait(for:[restored],timeout:3),.timedOut)
        open(app);tap("memoryTab-journey",app);XCTAssertTrue(app.buttons["journeyRecord-5"].waitForExistence(timeout:10))
    }
    func testStudyNoteCreatedFromAnAnsweredExerciseRestoresInItsLanguageAndLevel(){
        let app=launch(practiceKind:"delight:natural_or_weird");tap("productPanelClose",app)
        tap("productMenu",app);tap("productModeMenu",app);tap("productMode-path",app);tap("introLink",app);tap("startLessonFromPreview",app)
        tap("typedChoice-0",app);tap("checkTypedAnswer",app);tap("createTypedStudyNote",app)
        let note=app.buttons["createTypedStudyNote"];XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == false"),object:note)],timeout:10),.completed)
        open(app);tap("memoryTab-notes",app);XCTAssertTrue(app.buttons["memoryLevel-A1"].label.contains("2 notes"));tap("memoryLevel-A1",app)
        let created=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'memoryNote-' AND label CONTAINS 'Hola, mamá.'")).firstMatch
        XCTAssertTrue(created.waitForExistence(timeout:10));created.tap();XCTAssertTrue(app.staticTexts["Use hola to greet a family member."].waitForExistence(timeout:10));photo("Native study note created from exercise",app)
        tap("productPanelClose",app);app.terminate();app.launch();open(app);tap("memoryTab-notes",app);tap("memoryLevel-A1",app);created.tap();XCTAssertTrue(app.staticTexts["Use hola to greet a family member."].exists)
    }
    func testRepairsGoalsStudyNoteAccordionDeleteClearAndRelaunch(){
        let app=launch();XCTAssertTrue(app.staticTexts["memoryDigest"].waitForExistence(timeout:10));photo("Native Memory repairs product",app);tap("memoryTab-goals",app);XCTAssertTrue(app.staticTexts["Talk with family"].exists);XCTAssertTrue(app.staticTexts["Greet a relative"].exists);photo("Native Memory goals product",app)
        tap("memoryTab-notes",app);XCTAssertTrue(app.buttons["memoryLevel-A1"].isEnabled);XCTAssertFalse(app.buttons["memoryLevel-A2"].isEnabled);tap("memoryLevel-A1",app);tap("memoryNote-00000000-0000-0000-0000-000000000001",app);XCTAssertTrue(app.staticTexts["Use this greeting during a family call."].exists);photo("Native Memory expanded saved note product",app);tap("memoryNoteDelete",app);XCTAssertFalse(app.buttons["memoryLevel-A1"].isEnabled);tap("memoryClearAll",app);XCTAssertTrue(app.staticTexts["No notes"].exists)
        tap("productPanelClose",app);app.terminate();app.launch();open(app);tap("memoryTab-notes",app);XCTAssertTrue(app.staticTexts["No notes"].exists);XCTAssertFalse(app.buttons["memoryClearAll"].exists);photo("Native Memory notes cleared after relaunch",app)
    }
    func testJourneyRecordPreviewEncryptedSaveListenCompareDeleteAndRelaunch(){
        let app=launch();tap("memoryTab-journey",app);XCTAssertTrue(app.buttons["journeyListen-1"].waitForExistence(timeout:10));tap("journeyRecord-5",app);XCTAssertTrue(app.buttons["journeyCapture"].waitForExistence(timeout:10));photo("Native Journey recording dialog product",app);tap("journeyCapture",app);tap("journeyCapture",app);XCTAssertTrue(app.buttons["journeySave"].waitForExistence(timeout:10));photo("Native Journey private preview product",app);tap("journeySave",app);XCTAssertTrue(app.staticTexts["Recording saved"].waitForExistence(timeout:15));tap("journeyRecordingClose",app)
        tap("journeyListen-5",app);XCTAssertTrue(app.staticTexts["Hear your starting point alongside this moment."].waitForExistence(timeout:10));photo("Native Journey baseline comparison product",app);tap("journeyDelete",app);XCTAssertTrue(app.staticTexts["Delete this recording?"].exists);tap("Keep it",app);tap("journeyDelete",app);tap("journeyDeleteConfirm",app);XCTAssertTrue(app.buttons["journeyRecord-5"].waitForExistence(timeout:10));tap("productPanelClose",app);app.terminate();app.launch();open(app);tap("memoryTab-journey",app);XCTAssertTrue(app.buttons["journeyRecord-5"].waitForExistence(timeout:10));XCTAssertTrue(app.buttons["journeyListen-1"].exists)
    }
}
