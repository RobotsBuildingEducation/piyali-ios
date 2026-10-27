import XCTest
@MainActor final class QuestionAssistanceJourneyTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication){let e=app.buttons[id];XCTAssertTrue(e.waitForExistence(timeout:15));for _ in 0..<12 where !e.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(e.isHittable);e.tap()}
    private func shot(_ name:String,_ app:XCUIApplication){let s=XCTAttachment(screenshot:app.screenshot());s.name=name;s.lifetime = .keepAlways;add(s)}
    func testOriginalHelpCloseRetryExplanationAndLessonProgressUseTheFixedActionArea()throws {
        continueAfterFailure=false;let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_HEADLINE_FIXTURE":"failure","PIYALI_PRACTICE_FIXTURE":"delight:natural_or_weird","PIYALI_QUESTION_HELP_FIXTURE":"stream"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Question Learner");tap("entryKeyboardDone",app);tap("createAccount",app);chooseEnglishSpanishOnboarding(app);tap("startLearning",app);tap("companionContinue",app);tap("gettingStartedGotIt",app);chooseA1Placement(app);tap("productMenu",app);tap("productModeMenu",app);tap("productMode-path",app);tap("lessonPreviousLevel",app);tap("lessonNode-lesson-pre-a1-1-1",app);tap("startLessonFromPreview",app)
        XCTAssertTrue(app.buttons["typedChoice-0"].waitForExistence(timeout:10));XCTAssertFalse(app.buttons["lessonMode-grammar"].exists);XCTAssertFalse(app.staticTexts["activeLessonXP"].exists);XCTAssertFalse(app.buttons["checkTypedAnswer"].isEnabled);shot("Native natural-or-weird unanswered",app)
        tap("typedPracticeHelp",app);let help=app.staticTexts["typedAssistantText"];XCTAssertTrue(help.waitForExistence(timeout:10));XCTAssertTrue(help.label.contains("Sounds weird"));XCTAssertFalse(app.staticTexts["practiceVerdict"].exists);XCTAssertFalse(app.staticTexts["activeLessonXP"].exists);shot("Native question direct-help stream",app);tap("closeTypedAssistantAction",app)
        XCTAssertTrue(app.buttons["checkTypedAnswer"].waitForExistence(timeout:5));XCTAssertFalse(app.staticTexts["typedAssistantText"].exists);XCTAssertTrue(app.buttons["typedPracticeHelp"].waitForExistence(timeout:5));XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:app.buttons["typedPracticeHelp"])],timeout:8),.completed);tap("typedPracticeHelp",app);XCTAssertTrue(help.waitForExistence(timeout:5));XCTAssertTrue(help.label.contains("Yo soy Ana"));tap("closeTypedAssistantAction",app)
        tap("typedChoice-1",app);tap("checkTypedAnswer",app);let verdict=app.staticTexts["practiceVerdict"];XCTAssertTrue(verdict.waitForExistence(timeout:5));XCTAssertTrue(verdict.label.contains("Try again"));XCTAssertFalse(app.staticTexts["activeLessonXP"].exists);shot("Native question retry action area",app);tap("explainTypedAnswer",app);let explanation=app.staticTexts["typedExplanation"];XCTAssertTrue(explanation.waitForExistence(timeout:10));XCTAssertTrue(explanation.label.contains("soy"));shot("Native question wrong-answer explanation",app)
        tap("typedChoice-0",app);XCTAssertFalse(explanation.exists);tap("checkTypedAnswer",app);XCTAssertTrue(app.buttons["nextTypedQuestion"].waitForExistence(timeout:10));XCTAssertTrue(verdict.label.contains("+6 XP"));XCTAssertEqual(app.staticTexts["activeLessonXP"].label,"8%");XCTAssertTrue(app.buttons["createTypedStudyNote"].exists);XCTAssertFalse(app.staticTexts["lessonCompletionBonus"].exists);shot("Native question correct feedback and lesson progress",app)
        tap("nextTypedQuestion",app);XCTAssertTrue(app.buttons["typedChoice-0"].waitForExistence(timeout:10));XCTAssertFalse(app.staticTexts["activeLessonXP"].exists);XCTAssertFalse(app.staticTexts["typedAssistantText"].exists);XCTAssertFalse(app.staticTexts["practiceVerdict"].exists)
        let back=app.navigationBars.buttons.element(boundBy:0);XCTAssertTrue(back.waitForExistence(timeout:5));back.tap();tap("lessonNode-lesson-pre-a1-1-1",app);tap("startLessonFromPreview",app);XCTAssertTrue(app.buttons["typedChoice-0"].waitForExistence(timeout:10));XCTAssertFalse(app.staticTexts["practiceVerdict"].exists);XCTAssertFalse(app.staticTexts["activeLessonXP"].exists);XCTAssertFalse(app.buttons["checkTypedAnswer"].isEnabled);tap("typedChoice-0",app);tap("checkTypedAnswer",app);XCTAssertTrue(app.buttons["nextTypedQuestion"].waitForExistence(timeout:10));XCTAssertEqual(app.staticTexts["activeLessonXP"].label,"15%");shot("Native fresh lesson entry retains earned progress",app)
    }
}

@MainActor func chooseEnglishSpanishOnboarding(_ app:XCUIApplication){
    func tap(_ id:String){let b=app.buttons[id];XCTAssertTrue(b.waitForExistence(timeout:10));for _ in 0..<8 where !b.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(b.isHittable);b.tap()}
    tap("onboardingSupport");tap("onboardingOption-support-en");tap("onboardingPractice");tap("onboardingOption-practice-es")
}

/// Follow the product's queued reward/task dialogs before interacting with its path.
@MainActor func continueLessonFollowups(_ app:XCUIApplication,onDialog:((String)->Void)?=nil) {
    let dialogs=app.buttons.matching(NSPredicate(format:"identifier IN %@",["dailyGoalRewardContinue","scholarshipLater","guidedContinue","achievementContinue","companionUnlockKeep"]))
    for _ in 0..<8 {
        guard dialogs.firstMatch.waitForExistence(timeout:2) else{return}
        if let visible=dialogs.allElementsBoundByIndex.first(where:{$0.isHittable}) {onDialog?(visible.identifier);visible.tap()} else {return}
    }
}
