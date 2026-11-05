import XCTest

@MainActor final class FocusedPhonicsJourneyTests:XCTestCase {
    private func element(_ id:String,_ app:XCUIApplication)->XCUIElement{app.descendants(matching:.any).matching(identifier:id).firstMatch}
    private func tap(_ id:String,_ app:XCUIApplication){let e=element(id,app);XCTAssertTrue(e.waitForExistence(timeout:15),id);XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:e)],timeout:15),.completed,id);for _ in 0..<6 where !e.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(e.isHittable,id);e.tap()}
    private func shot(_ name:String,_ app:XCUIApplication){let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    private func start(_ scenario:String,trial:Bool=false,fresh:Bool=false)->XCUIApplication {
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_FOCUSED_PHONICS_FIXTURE":scenario,"PIYALI_FOCUSED_PHONICS_COMPLETION_OFFLINE":scenario == "repair" ? "1":"0","PIYALI_PHONICS_FIXTURE":"1","PIYALI_MEMORY_CAPTURE_ONLY":"1","PIYALI_HEADLINE_FIXTURE":"failure","PIYALI_PRACTICE_FIXTURE":"standard:fill","PIYALI_PRACTICE_JUDGE_FIXTURE":"offered-reference"]
        if fresh{app.launchEnvironment["PIYALI_FOCUSED_PHONICS_FRESH"]="1";app.launchEnvironment["PIYALI_FOCUSED_PHONICS_PREPARATION_OFFLINE"]="1";app.launchEnvironment["PIYALI_FOCUSED_PHONICS_COMPLETION_OFFLINE"]="0"}
        if trial{app.launchEnvironment["PIYALI_FOCUSED_PHONICS_TRIAL"]="1";app.launchEnvironment["PIYALI_FOCUSED_PHONICS_COMPLETION_OFFLINE"]="0";app.launchEnvironment["PIYALI_FOCUSED_PHONICS_FAIL_COMPLETION_ONCE"]="1"}
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch();handleInitialPaperPencil(app)
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Focused Phonics Learner");tap("entryKeyboardDone",app);tap("createAccount",app);handleInitialPaperPencil(app);chooseEnglishSpanishOnboarding(app);tap("startLearning",app);tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);chooseA1Placement(app);tap("startDailyPractice",app);XCTAssertTrue(app.buttons["phonicsPrimary"].waitForExistence(timeout:15));return app
    }
    private func correct(_ app:XCUIApplication,firstCapture:Bool){tap("phonicsPrimary",app);XCTAssertTrue(element("phonicsWord",app).waitForExistence(timeout:10));tap("phonicsPrimary",app)
        if firstCapture{XCTAssertTrue(element("phonicsIncorrect",app).waitForExistence(timeout:15));shot("Native focused pronunciation miss",app);tap("phonicsPrimary",app);tap("phonicsPrimary",app)}
    }
    func testGoalPronunciationMissRetryReentryWithoutCollectThenNextLessonAndRelaunch(){
        continueAfterFailure=false;let app=start("goal");XCTAssertEqual(element("focusedPhonicsProgress",app).label,"0 / 2");shot("Native focused Goal phonics front",app)
        correct(app,firstCapture:true);XCTAssertTrue(element("phonicsCorrect",app).waitForExistence(timeout:15));shot("Native first Goal phonics outcome saved before Collect",app)
        app.terminate();app.launch();XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));tap("startDailyPractice",app);XCTAssertTrue(element("focusedPhonicsProgress",app).waitForExistence(timeout:15));XCTAssertEqual(element("focusedPhonicsProgress",app).label,"1 / 2");shot("Native focused Goal phonics restores saved outcome without Collect",app)
        correct(app,firstCapture:true);XCTAssertTrue(app.textFields["typedPracticeAnswer"].waitForExistence(timeout:15));XCTAssertTrue(app.buttons["goalFocusSummary"].exists);shot("Native Goal phonics completes into next lesson",app)
        app.terminate();app.launch();XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));tap("startDailyPractice",app);XCTAssertTrue(app.textFields["typedPracticeAnswer"].waitForExistence(timeout:15));shot("Native next Goal lesson restores after pronunciation",app)
    }
    func testRepairPronunciationOriginalContrastTransferThenNextRepairLessonAndRelaunch(){
        continueAfterFailure=false;let app=start("repair");XCTAssertEqual(element("focusedPhonicsProgress",app).label,"0 / 3");shot("Native repair phonics original front",app)
        correct(app,firstCapture:true);XCTAssertTrue(element("phonicsCorrect",app).waitForExistence(timeout:15));tap("phonicsPrimary",app);XCTAssertEqual(element("focusedPhonicsProgress",app).label,"1 / 3")
        correct(app,firstCapture:false);XCTAssertTrue(element("phonicsCorrect",app).waitForExistence(timeout:15));shot("Native repair contrast does not finish transfer",app);tap("phonicsPrimary",app);XCTAssertEqual(element("focusedPhonicsProgress",app).label,"2 / 3")
        correct(app,firstCapture:false);XCTAssertTrue(element("phonicsFooterError",app).waitForExistence(timeout:15));XCTAssertFalse(app.textFields["typedPracticeAnswer"].exists);shot("Native repair completion failure retains pronunciation and retry",app);tap("phonicsPrimary",app);XCTAssertTrue(element("phonicsFooterError",app).waitForExistence(timeout:15));XCTAssertFalse(app.textFields["typedPracticeAnswer"].exists)
        app.terminate();app.launchEnvironment["PIYALI_FOCUSED_PHONICS_COMPLETION_OFFLINE"]="0";app.launch();XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));tap("startDailyPractice",app);XCTAssertTrue(app.textFields["typedPracticeAnswer"].waitForExistence(timeout:15));shot("Native next repair lesson restores after pronunciation",app)
    }
}


extension FocusedPhonicsJourneyTests {
    func testGoalPronunciationTrialEndRecoversCompletionIntoSubscription(){trialJourney("goal")}
    func testRepairPronunciationTrialEndRecoversCompletionIntoSubscription(){trialJourney("repair")}
    private func trialJourney(_ scenario:String){
        continueAfterFailure=false;let app=start(scenario,trial:true)
        correct(app,firstCapture:true);XCTAssertTrue(element("phonicsCorrect",app).waitForExistence(timeout:15));tap("phonicsPrimary",app)
        if scenario == "repair"{correct(app,firstCapture:false);XCTAssertTrue(element("phonicsCorrect",app).waitForExistence(timeout:15));tap("phonicsPrimary",app)}
        correct(app,firstCapture:false)
        // The first completion save fails. Background autosave can acknowledge it
        // before a UI tap; explicit held-offline Retry is covered by rendered tests.
        XCTAssertTrue(app.buttons["subscriptionNativeTools"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["phonicsPrimary"].exists);XCTAssertFalse(app.textFields["typedPracticeAnswer"].exists);shot("Native \(scenario) subscription after earned pronunciation recovered",app)
        app.terminate();app.launch();XCTAssertTrue(app.buttons["subscriptionNativeTools"].waitForExistence(timeout:15));shot("Native \(scenario) trial-end subscription persists after relaunch",app)
    }
}


extension FocusedPhonicsJourneyTests {
    func testFreshGoalPhonicsOfflinePreparationReentryThenOnlinePronunciationAndNextLesson(){freshOfflineJourney("goal")}
    func testFreshRepairPhonicsOfflinePreparationReentryThenOnlinePronunciationAndNextLesson(){freshOfflineJourney("repair")}
    private func freshOfflineJourney(_ scenario:String){
        continueAfterFailure=false;let app=start(scenario,fresh:true),initial=scenario == "goal" ? "0 / 2":"0 / 3"
        XCTAssertEqual(element("focusedPhonicsProgress",app).label,initial);XCTAssertFalse(element("phonicsCourseError",app).exists);shot("Native fresh \(scenario) authored phonics prepared while offline",app)
        tap("phonicsPrimary",app);XCTAssertTrue(element("phonicsWord",app).waitForExistence(timeout:10));shot("Native fresh \(scenario) offline pronunciation model",app)
        app.terminate();app.launch();XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));tap("startDailyPractice",app);XCTAssertTrue(element("focusedPhonicsProgress",app).waitForExistence(timeout:15));XCTAssertEqual(element("focusedPhonicsProgress",app).label,initial);XCTAssertFalse(element("phonicsCourseError",app).exists);shot("Native fresh \(scenario) offline authored deck survives relaunch",app)
        app.terminate();app.launchEnvironment["PIYALI_FOCUSED_PHONICS_PREPARATION_OFFLINE"]="0";app.launch();XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));tap("startDailyPractice",app)
        correct(app,firstCapture:true);XCTAssertTrue(element("phonicsCorrect",app).waitForExistence(timeout:15));tap("phonicsPrimary",app)
        if scenario == "repair"{correct(app,firstCapture:false);XCTAssertTrue(element("phonicsCorrect",app).waitForExistence(timeout:15));tap("phonicsPrimary",app)}
        correct(app,firstCapture:false);XCTAssertTrue(app.textFields["typedPracticeAnswer"].waitForExistence(timeout:15));shot("Native fresh \(scenario) phonics reconnects and completes into next lesson",app)
    }
}
