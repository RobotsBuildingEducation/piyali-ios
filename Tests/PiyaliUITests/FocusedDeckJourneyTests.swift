import XCTest

@MainActor final class FocusedDeckJourneyTests:XCTestCase {
    private func element(_ id:String,_ app:XCUIApplication)->XCUIElement{app.descendants(matching:.any).matching(identifier:id).firstMatch}
    private func tap(_ id:String,_ app:XCUIApplication){let e=element(id,app);XCTAssertTrue(e.waitForExistence(timeout:15),id);XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:e)],timeout:15),.completed,id);for _ in 0..<8 where !e.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(e.isHittable,id);e.tap()}
    private func shot(_ name:String,_ app:XCUIApplication){let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    private func start(_ scenario:String)->XCUIApplication {
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_FOCUSED_DECK_FIXTURE":scenario,"PIYALI_FLASHCARD_FIXTURE":"1","PIYALI_FLASHCARD_NOTE_FIXTURE":"1","PIYALI_FLASHCARD_NOTE_DELAY_MS":"12000","PIYALI_MEMORY_CAPTURE_ONLY":"1","PIYALI_HEADLINE_FIXTURE":"failure","PIYALI_PRACTICE_FIXTURE":"standard:fill","PIYALI_PRACTICE_JUDGE_FIXTURE":"offered-reference"]
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch();handleInitialPaperPencil(app)
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Focused Deck Learner");tap("entryKeyboardDone",app);tap("createAccount",app);handleInitialPaperPencil(app);chooseEnglishSpanishOnboarding(app);tap("startLearning",app);tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);chooseA1Placement(app);tap("startDailyPractice",app);return app
    }
    private func answer(_ text:String,index:Int,prefix:String,app:XCUIApplication,note:Bool=false){
        let card=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@ AND identifier ENDSWITH %@","flashcardTile-"+prefix,"-c\(index)")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout:15),app.debugDescription)
        for _ in 0..<6 where !card.isHittable{app.swipeUp(velocity:.slow)}
        // The focused deck is a horizontal rail; completed cards remain visible.
        if !card.isHittable{app.scrollViews.element(boundBy:1).swipeLeft()}
        XCTAssertTrue(card.isHittable,app.debugDescription);card.tap()
        let field=app.textFields["flashcardAnswer"];XCTAssertTrue(field.waitForExistence(timeout:10));field.tap();field.typeText(text+"\n")
        XCTAssertTrue(element("flashcardReward",app).waitForExistence(timeout:10));XCTAssertTrue(app.buttons["flashcardRate-good"].waitForExistence(timeout:10))
        if note{tap("flashcardCreateNote",app);XCTAssertFalse(app.buttons["flashcardCreateNote"].isEnabled);shot("Native focused Goal note pending before final recall save",app)}
        tap("flashcardRate-good",app)
    }
    private func progress(_ count:String,_ app:XCUIApplication){let e=element("focusedFlashcardProgress",app);XCTAssertTrue(e.waitForExistence(timeout:10));XCTAssertTrue(e.label.hasPrefix(count),e.label)}
    func testGoalRecallCompletesThenLessonOpensWhileStudyNoteSurvivesAndRestores(){
        continueAfterFailure=false;let app=start("goal");progress("0/3",app);XCTAssertFalse(app.buttons["goalFocusSummary"].exists);shot("Native Goal recall deck before practice",app)
        answer("papá",index:0,prefix:"goal-",app:app);progress("1/3",app)
        answer("hermana",index:1,prefix:"goal-",app:app);progress("2/3",app);shot("Native Goal recall deck two confirmed answers",app)
        answer("mamá",index:2,prefix:"goal-",app:app,note:true)
        XCTAssertTrue(app.textFields["typedPracticeAnswer"].waitForExistence(timeout:15));XCTAssertTrue(app.buttons["goalFocusSummary"].exists);shot("Native completed Goal recall hands off to Goal lesson",app)
        tap("productMenu",app);tap("productPanel-memory",app);tap("memoryTab-notes",app);tap("memoryLevel-A1",app)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'memoryNote-' AND label CONTAINS 'Mi mamá vive cerca.'")).firstMatch.waitForExistence(timeout:25));shot("Native focused recall note completes after lesson handoff",app);tap("productPanelClose",app)
        app.terminate();app.launch();XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));tap("startDailyPractice",app);XCTAssertTrue(app.textFields["typedPracticeAnswer"].waitForExistence(timeout:15));XCTAssertTrue(app.buttons["goalFocusSummary"].exists)
        tap("productMenu",app);tap("productPanel-memory",app);tap("memoryTab-notes",app);tap("memoryLevel-A1",app);XCTAssertTrue(app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'memoryNote-' AND label CONTAINS 'Mi mamá vive cerca.'")).firstMatch.waitForExistence(timeout:10));shot("Native completed Goal deck and study note restore",app)
    }
    func testRepairRecallCompletesThenNextRepairLessonOpens(){
        continueAfterFailure=false;let app=start("repair");progress("0/2",app);shot("Native repair recall deck before practice",app)
        answer("Hola",index:0,prefix:"repair-",app:app);progress("1/2",app);shot("Native repair recall deck one confirmed answer",app)
        answer("Gracias",index:1,prefix:"repair-",app:app)
        XCTAssertTrue(app.textFields["typedPracticeAnswer"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'flashcardTile-repair-'")).firstMatch.exists);shot("Native completed repair deck hands off to next repair lesson",app)
        app.terminate();app.launch();XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));tap("startDailyPractice",app);XCTAssertTrue(app.textFields["typedPracticeAnswer"].waitForExistence(timeout:15));shot("Native next repair lesson restores after relaunch",app)
    }
}
