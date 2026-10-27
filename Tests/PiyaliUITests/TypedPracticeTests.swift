import XCTest

@MainActor final class TypedPracticeTests:XCTestCase {
    private func launch(kind:String,enterPractice:Bool=true,theme:String="light")->XCUIApplication {
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_PRACTICE_FIXTURE"]=kind;if kind.hasPrefix("oral:"){app.launchEnvironment["PIYALI_PRACTICE_JUDGE_FIXTURE"]="offered-reference"}
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme",theme];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Practice Learner");if app.buttons["entryKeyboardDone"].exists { app.buttons["entryKeyboardDone"].tap() }
        app.buttons["createAccount"].tap();XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:20));chooseEnglishSpanishOnboarding(app);app.buttons["startLearning"].tap();if enterPractice { openPractice(app) };return app
    }
    private func openPractice(_ app:XCUIApplication) {
        XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));app.buttons["productMenu"].tap();app.buttons["productModeMenu"].tap();app.buttons["productMode-path"].tap()
        XCTAssertTrue(app.buttons["introLink"].waitForExistence(timeout:15));app.buttons["introLink"].tap();XCTAssertTrue(app.buttons["startLessonFromPreview"].waitForExistence(timeout:5));app.buttons["startLessonFromPreview"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format:"identifier IN %@",["checkTypedAnswer","nextTypedQuestion"])).firstMatch.waitForExistence(timeout:10))
    }
    private func reveal(_ element:XCUIElement,_ app:XCUIApplication) { for _ in 0..<14 where !element.isHittable { app.swipeUp(velocity:.slow) };if !element.isHittable{let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Missing practice interaction";shot.lifetime = .keepAlways;add(shot)};XCTAssertTrue(element.isHittable) }
    func testOriginalLessonPreviewCanExpandObjectivesAndCloseBeforeStarting() {
        continueAfterFailure=false;let app=launch(kind:"delight:natural_or_weird",enterPractice:false,theme:"dark")
        XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));app.buttons["productMenu"].tap();app.buttons["productModeMenu"].tap();app.buttons["productMode-path"].tap()
        XCTAssertTrue(app.buttons["introLink"].waitForExistence(timeout:15));app.buttons["introLink"].tap();XCTAssertTrue(app.buttons["startLessonFromPreview"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["Complete the 6 learning activities"].exists)
        let objectives=app.buttons["lessonPreviewObjectives"];XCTAssertTrue(objectives.label.contains("7"));objectives.tap()
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Native original lesson preview dark";shot.lifetime = .keepAlways;add(shot)
        let greeting=app.staticTexts["hello · hola"];if !greeting.waitForExistence(timeout:5) { print("PREVIEW HIERARCHY: "+app.debugDescription) };XCTAssertTrue(greeting.exists)
        app.buttons["closeLessonPreview"].tap();XCTAssertTrue(app.buttons["introLink"].waitForExistence(timeout:5));XCTAssertFalse(app.buttons["introStep-vocabulary"].exists)
        app.buttons["introLink"].tap();app.buttons["startLessonFromPreview"].tap();XCTAssertTrue(app.buttons["introStep-vocabulary"].waitForExistence(timeout:5));XCTAssertEqual(app.buttons["introStep-vocabulary"].value as? String,"Current")
    }
    func testCurriculumLessonRequiresItsOwnEightyXPThenShowsOneBonusAndUnlocksTheNextNode() {
        continueAfterFailure=false;let app=launch(kind:"delight:natural_or_weird",enterPractice:false);var dialogs:[String]=[]
        func followups(){continueLessonFollowups(app,onDialog:{dialogs.append($0)})}
        func openPath() { XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));app.buttons["productMenu"].tap();app.buttons["productModeMenu"].tap();app.buttons["productMode-path"].tap() }
        openPath();XCTAssertTrue(app.buttons["introLink"].waitForExistence(timeout:15));app.buttons["introLink"].tap();app.buttons["startLessonFromPreview"].tap()
        for _ in 0..<6 { let next=app.buttons.matching(NSPredicate(format:"identifier IN %@",["skipLessonActivity","skipIntroActivity","realtimeSkip","rpgBack"])).firstMatch;XCTAssertTrue(next.waitForExistence(timeout:10));reveal(next,app);next.tap() }
        XCTAssertTrue(app.staticTexts["lessonCompletionBonus"].waitForExistence(timeout:10));XCTAssertEqual(app.staticTexts["lessonCompletionBonus"].label,"+50");app.buttons["continueLessonCompletion"].tap();followups()
        let first=app.buttons["lessonNode-lesson-pre-a1-1-1"],second=app.buttons["lessonNode-lesson-pre-a1-1-2"]
        XCTAssertTrue(first.waitForExistence(timeout:5));XCTAssertTrue(first.isEnabled);XCTAssertFalse(second.isEnabled)
        reveal(first,app);first.tap();XCTAssertTrue(app.staticTexts["+80 XP"].waitForExistence(timeout:5));app.buttons["startLessonFromPreview"].tap()
        XCTAssertFalse(app.staticTexts["activeLessonXP"].exists,"Lesson progress belongs to feedback after grading")
        for turn in 1...14 {
            let correct=app.buttons["typedChoice-0"];XCTAssertTrue(correct.waitForExistence(timeout:5));reveal(correct,app);correct.tap()
            let check=app.buttons["checkTypedAnswer"];reveal(check,app);check.tap();followups()
            if turn < 14 {
                let next=app.buttons["nextTypedQuestion"];XCTAssertTrue(next.waitForExistence(timeout:5));XCTAssertEqual(app.staticTexts["activeLessonXP"].label,"\(Int(floor(Double(turn*6)/80*100+0.5)))%")
                if turn == 2 { XCTAssertFalse(app.staticTexts["lessonCompletionBonus"].exists,"One correct answer in each module cannot complete an 80-XP lesson") }
                reveal(next,app);next.tap()
            }
        }
        let bonus=app.staticTexts["lessonCompletionBonus"];XCTAssertTrue(bonus.waitForExistence(timeout:10));XCTAssertEqual(bonus.label,"+80");XCTAssertTrue(app.staticTexts["Lesson Complete!"].exists)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Native completed 80 XP curriculum lesson";shot.lifetime = .keepAlways;add(shot)
        app.buttons["continueLessonCompletion"].tap();followups();XCTAssertTrue(first.waitForExistence(timeout:5));XCTAssertEqual(first.value as? String,"completed");XCTAssertTrue(second.isEnabled)
        XCTAssertEqual(dialogs.filter{$0 == "dailyGoalRewardContinue"}.count,1);XCTAssertEqual(dialogs.filter{$0 == "companionUnlockKeep"}.count,1)
        app.terminate();app.launch();openPath();XCTAssertTrue(first.waitForExistence(timeout:10));XCTAssertEqual(first.value as? String,"completed");XCTAssertTrue(second.isEnabled);XCTAssertFalse(app.staticTexts["lessonCompletionBonus"].exists)
    }
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
    func testLessonFlashcardRevealDoesNotAwardAndCorrectAnswerLocksOnce() {
        continueAfterFailure=false;let app=launch(kind:"oral:flashcard")
        app.buttons["flipLessonFlashcard"].tap();XCTAssertTrue(app.buttons["listenLessonFlashcard"].exists);XCTAssertFalse(app.buttons["collectLessonFlashcard"].exists);XCTAssertFalse(app.staticTexts["practiceVerdict"].exists)
        let field=app.textFields["typedPracticeAnswer"];field.tap();field.typeText("Hola");if app.buttons["practiceKeyboardDone"].exists{app.buttons["practiceKeyboardDone"].tap()};app.buttons["checkTypedAnswer"].tap();XCTAssertTrue(app.buttons["nextTypedQuestion"].waitForExistence(timeout:10));XCTAssertTrue(app.staticTexts["practiceVerdict"].label.contains("+6 XP"));XCTAssertFalse(app.buttons["openLessonFlashcardDeck"].exists);XCTAssertTrue(app.buttons["nextTypedQuestion"].exists)
    }
}
