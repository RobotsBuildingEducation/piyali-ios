import XCTest

@MainActor final class TypedPracticeTests:XCTestCase {
    private func launch(kind:String)->XCUIApplication {
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_PRACTICE_FIXTURE"]=kind
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Practice Learner");if app.buttons["entryKeyboardDone"].exists { app.buttons["entryKeyboardDone"].tap() }
        app.buttons["createAccount"].tap();XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:20));app.buttons["startLearning"].tap();openPractice(app);return app
    }
    private func openPractice(_ app:XCUIApplication) {
        XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));app.buttons["productMenu"].tap();app.buttons["productModeMenu"].tap();app.buttons["productMode-path"].tap()
        XCTAssertTrue(app.buttons["introLink"].waitForExistence(timeout:15));app.buttons["introLink"].tap();app.buttons["Try Vocabulary"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format:"identifier IN %@",["checkTypedAnswer","nextTypedQuestion"])).firstMatch.waitForExistence(timeout:10))
    }
    private func reveal(_ element:XCUIElement,_ app:XCUIApplication) { for _ in 0..<7 where !element.isHittable { app.swipeUp(velocity:.slow) };XCTAssertTrue(element.isHittable) }
    func testBinaryQuestionRetriesInPlaceAndCorrectRewardSurvivesRelaunch() {
        continueAfterFailure=false;let app=launch(kind:"delight:natural_or_weird")
        app.buttons["typedChoice-1"].tap();let check=app.buttons["checkTypedAnswer"];reveal(check,app);check.tap()
        XCTAssertTrue(app.staticTexts["practiceVerdict"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["practiceVerdict"].label.contains("Try again"));XCTAssertFalse(app.buttons["nextTypedQuestion"].exists)
        app.buttons["typedChoice-0"].tap();check.tap();XCTAssertTrue(app.buttons["nextTypedQuestion"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["practiceVerdict"].label.contains("+6 XP"));XCTAssertFalse(app.buttons["typedChoice-1"].isEnabled)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Native typed binary question after retry";shot.lifetime = .keepAlways;add(shot)
        app.terminate();app.launch();openPractice(app);XCTAssertTrue(app.buttons["nextTypedQuestion"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["practiceVerdict"].label.contains("+6 XP"))
    }
    func testWordBankKeepsDuplicatePositionsAndResumesBeforeAnswering() {
        continueAfterFailure=false;let app=launch(kind:"translate")
        func word(_ text:String)->XCUIElement { app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'typedWord-' AND label == %@ AND enabled == true",text)).firstMatch }
        word("I").tap();word("I").tap();XCTAssertTrue(app.buttons["typedSelected-1"].exists);app.buttons["typedSelected-1"].tap()
        for text in ["do","not","say","no"] { word(text).tap() }
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Native translation bank before checking";shot.lifetime = .keepAlways;add(shot)
        app.terminate();app.launch();openPractice(app);XCTAssertTrue(app.buttons["typedSelected-4"].exists)
        let check=app.buttons["checkTypedAnswer"];reveal(check,app);check.tap();XCTAssertTrue(app.buttons["nextTypedQuestion"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["practiceVerdict"].label.contains("+6 XP"))
    }
    func testLessonFlashcardFlipsCollectsAndReviewsItsAnswerWithoutPracticeCredit() {
        continueAfterFailure=false;let app=launch(kind:"flashcard")
        let card=app.buttons["flipLessonFlashcard"];XCTAssertTrue(card.label.contains("Hello"));card.tap();XCTAssertTrue(card.label.contains("Hola"));XCTAssertTrue(app.buttons["listenLessonFlashcard"].exists)
        app.buttons["collectLessonFlashcard"].tap();XCTAssertFalse(app.buttons["collectLessonFlashcard"].isEnabled);app.buttons["openLessonFlashcardDeck"].tap()
        XCTAssertTrue(app.navigationBars["Deck Review"].waitForExistence(timeout:5));let review=app.buttons["reviewLessonFlashcard"];XCTAssertTrue(review.label.contains("Hello"));review.tap();XCTAssertTrue(review.label.contains("Hola"))
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Native collected lesson flashcard deck";shot.lifetime = .keepAlways;add(shot)
        app.buttons["Close"].tap();XCTAssertFalse(app.staticTexts["practiceVerdict"].exists);XCTAssertFalse(app.buttons["nextTypedQuestion"].exists)
    }
}
