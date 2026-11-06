import XCTest
@MainActor final class WordBankBodyJourneyTests:XCTestCase {
    private func element(_ id:String,_ app:XCUIApplication)->XCUIElement{app.descendants(matching:.any).matching(identifier:id).firstMatch}
    private func reveal(_ e:XCUIElement,_ app:XCUIApplication){for _ in 0..<12 where !e.isHittable{if e.exists,e.frame.midY<app.frame.midY{app.swipeDown(velocity:.slow)}else{app.swipeUp(velocity:.slow)}};if !e.isHittable{shot("Missing word-bank interaction",app)};XCTAssertTrue(e.isHittable)}
    private func tap(_ id:String,_ app:XCUIApplication){let e=element(id,app);XCTAssertTrue(e.waitForExistence(timeout:10));reveal(e,app);e.tap()}
    private func shot(_ name:String,_ app:XCUIApplication){let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    private var selectedVariants:Set<String>{Set((ProcessInfo.processInfo.environment["PIYALI_WORD_BANK_JOURNEY_VARIANTS"] ?? "translate-target,translate-support,repeat-target,repeat-support,repeat-listening").split(separator:",").map(String.init))}
    private func launch(_ variant:String)->XCUIApplication {
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_HEADLINE_FIXTURE":"failure","PIYALI_QUESTION_HELP_FIXTURE":"stream","PIYALI_PRACTICE_JUDGE_FIXTURE":"offered-reference","PIYALI_PRACTICE_FIXTURE":"wordbank:"+variant];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch();handleInitialPaperPencil(app)
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Word Bank Learner");tap("entryKeyboardDone",app);tap("createAccount",app);handleInitialPaperPencil(app);chooseEnglishSpanishOnboarding(app);tap("startLearning",app);tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);chooseA1Placement(app);open(app);return app
    }
    private func open(_ app:XCUIApplication){tap("productMenu",app);tap("productModeMenu",app);tap("productMode-path",app);if !app.buttons["lessonNode-lesson-pre-a1-1-1"].exists{tap("lessonPreviousLevel",app)};tap("lessonNode-lesson-pre-a1-1-1",app);tap("startLessonFromPreview",app);XCTAssertTrue(element("typedQuestionPrompt",app).waitForExistence(timeout:10))}
    private func checkWrong(_ app:XCUIApplication){tap("checkTypedAnswer",app);XCTAssertTrue(app.staticTexts["practiceVerdict"].waitForExistence(timeout:10));XCTAssertTrue(app.staticTexts["practiceVerdict"].label.contains("Try again"))}
    private func correct(_ xp:Int,_ app:XCUIApplication){tap("checkTypedAnswer",app);XCTAssertTrue(app.buttons["nextTypedQuestion"].waitForExistence(timeout:10));XCTAssertTrue(app.staticTexts["practiceVerdict"].label.contains("+\(xp) XP"))}
    private func drag(_ source:String,to target:String,_ app:XCUIApplication){let a=element(source,app),b=element(target,app);XCTAssertTrue(a.waitForExistence(timeout:10));XCTAssertTrue(b.waitForExistence(timeout:10));reveal(a,app);a.press(forDuration:1,thenDragTo:b)}
    func testTranslationBothDirectionsDuplicatePositionsNativeReorderRetryAndLock() {
        continueAfterFailure=false
        for variant in ["translate-target","translate-support"] where selectedVariants.contains(variant) {
            let app=launch(variant)
            XCTAssertFalse(app.buttons["checkTypedAnswer"].isEnabled)
            tap("typedWord-0",app);tap("typedWord-5",app);XCTAssertTrue(app.buttons["typedSelected-1"].exists);XCTAssertFalse(app.buttons["typedWord-0"].exists);tap("typedSelected-0",app);XCTAssertTrue(app.buttons["typedWord-0"].waitForExistence(timeout:5))
            drag("typedSelected-0",to:"wordBankAvailable",app);XCTAssertTrue(app.buttons["typedWord-5"].waitForExistence(timeout:5));XCTAssertFalse(app.buttons["checkTypedAnswer"].isEnabled)
            tap("typedWord-6",app);checkWrong(app);tap("typedSelected-0",app);XCTAssertTrue(app.staticTexts["practiceVerdict"].exists)
            tap("typedPracticeHelp",app);XCTAssertTrue(app.buttons["closeTypedAssistantAction"].waitForExistence(timeout:10));tap("closeTypedAssistantAction",app)
            tap("typedWord-1",app);tap("typedWord-0",app);drag("typedSelected-1",to:"typedSelected-0",app)
            XCTAssertEqual(app.buttons["typedSelected-0"].label,variant == "translate-target" ? "I":"Yo")
            for index in [2,3,4]{tap("typedWord-\(index)",app)}
            shot("Native translation assembled \(variant)",app);correct(6,app);XCTAssertFalse(app.buttons["typedSelected-0"].isEnabled);shot("Native translation correct \(variant)",app)
            app.terminate()
        }
    }
    func testEveryRepeatModeHidesSentenceAndSupportsNativeDragRetryAndReturn() {
        continueAfterFailure=false
        for variant in ["repeat-target","repeat-support","repeat-listening"] where selectedVariants.contains(variant) {
            let app=launch(variant)
            XCTAssertFalse(app.staticTexts["Yo no digo que no"].exists);XCTAssertFalse(app.staticTexts["I do not say no"].exists);XCTAssertFalse(app.buttons["Show transcript"].exists)
            tap("typedPracticeListen",app);tap("typedWord-6",app);checkWrong(app);tap("typedSelected-0",app);XCTAssertTrue(app.buttons["typedWord-6"].waitForExistence(timeout:5))
            drag("typedWord-0",to:"wordBankAnswer",app);XCTAssertTrue(app.buttons["typedSelected-0"].waitForExistence(timeout:5));drag("typedSelected-0",to:"wordBankAvailable",app);XCTAssertTrue(app.buttons["typedWord-0"].waitForExistence(timeout:5))
            for index in 0..<5{tap("typedWord-\(index)",app)}
            shot("Native repetition assembled \(variant)",app);correct(6,app);XCTAssertFalse(app.buttons["typedSelected-0"].isEnabled);app.terminate()
        }
    }
}
