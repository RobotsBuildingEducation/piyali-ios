import XCTest

@MainActor final class GuidedPracticeJourneyTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication){let button=app.buttons[id];XCTAssertTrue(button.waitForExistence(timeout:20),id);XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:button)],timeout:20),.completed,id);for _ in 0..<4 where !button.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(button.isHittable,id);button.tap()}
    private func photo(_ name:String,_ app:XCUIApplication){let shot=XCTAttachment(screenshot:app.screenshot());shot.name=name;shot.lifetime = .keepAlways;add(shot)}
    private func launch(_ scenario:String,walletRelay:String?=nil)->XCUIApplication {
        continueAfterFailure=false;let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_TUTOR_FIXTURE":"1","PIYALI_FLASHCARD_FIXTURE":"1","PIYALI_CONVERSATION_FIXTURE":scenario == "conversation" ? "1":"0"];if let walletRelay{app.launchEnvironment["PIYALI_WALLET_TEST_RELAY"]=walletRelay}
        if scenario == "fresh" {
            app.launchEnvironment["PIYALI_TUTOR_LATE_SPEECH_FIXTURE"]="1"
        } else {
            app.launchEnvironment["PIYALI_PLATE_JOURNEY_FIXTURE"]=scenario
        }
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch();handleInitialPaperPencil(app)
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Quest Learner");if app.buttons["entryKeyboardDone"].exists{app.buttons["entryKeyboardDone"].tap()};tap("createAccount",app);handleInitialPaperPencil(app);tap("startLearning",app)
        if !["returning-learn","rollover-learn"].contains(scenario) {
            tap("companionContinue",app)
            acknowledgePaperPencil(app)
            tap("gettingStartedGotIt",app)
            if scenario == "fresh" {
                XCTAssertTrue(app.buttons["placementNew"].waitForExistence(timeout:10))
                photo("Native new learner placement",app)
            }
            tap("placementNew",app)
        }
        return app
    }
    func testFreshSignupPlacementAndFirstGuidedTutorTurnSurviveRelaunch(){
        let app=launch("fresh")
        let start=app.buttons["startDailyPractice"]
        XCTAssertTrue(start.waitForExistence(timeout:15))
        XCTAssertEqual(start.label,"Start tasks")
        XCTAssertTrue(app.staticTexts["XP 0"].exists)
        photo("Native new learner Focus after placement",app)
        tap("startDailyPractice",app)
        let title=app.staticTexts["tutorLessonTitle"]
        XCTAssertTrue(title.waitForExistence(timeout:15))
        XCTAssertTrue(title.label.contains("Tutorial"))
        XCTAssertFalse(app.staticTexts["tutorLatestReply"].exists)
        photo("Native first guided Tutor before connecting",app)
        tap("tutorStart",app)
        let progress=app.staticTexts["tutorProgressBadge"]
        XCTAssertTrue(progress.waitForExistence(timeout:15))
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"label != %@","0%"),object:progress)],timeout:25),.completed)
        let savedProgress=progress.label
        photo("Native first guided Tutor progress",app)
        app.terminate();app.launch()
        XCTAssertTrue(start.waitForExistence(timeout:15))
        XCTAssertEqual(start.label,"Continue practice")
        XCTAssertFalse(app.buttons["companionContinue"].exists)
        tap("startDailyPractice",app)
        XCTAssertTrue(title.waitForExistence(timeout:15))
        XCTAssertEqual(progress.label,savedProgress)
        XCTAssertTrue(app.buttons["tutorStart"].isEnabled)
        XCTAssertFalse(app.staticTexts["tutorLatestReply"].exists)
        photo("Native first guided Tutor restored with microphone closed",app)
    }
    private func completeTutor(_ app:XCUIApplication){
        tap("startDailyPractice",app);photo("Native daily practice route",app);XCTAssertTrue(app.staticTexts["tutorLessonTitle"].waitForExistence(timeout:15));tap("tutorStart",app)
        XCTAssertTrue(app.buttons["tutorCompletionContinue"].waitForExistence(timeout:40));photo("Native guided Tutor result",app);tap("tutorCompletionContinue",app)
        XCTAssertTrue(app.buttons["tutorReviewContinue"].waitForExistence(timeout:10));XCTAssertFalse(app.buttons["dailyGoalRewardContinue"].exists);photo("Native guided Tutor review before daily goal",app);tap("tutorReviewContinue",app)
        XCTAssertTrue(app.buttons["dailyGoalRewardContinue"].waitForExistence(timeout:10));photo("Native guided daily goal reward",app);tap("dailyGoalRewardContinue",app)
        XCTAssertTrue(app.buttons["scholarshipLater"].waitForExistence(timeout:10));photo("Native scholarship after Tutor celebrations",app);tap("scholarshipLater",app);XCTAssertTrue(app.buttons["guidedContinue"].waitForExistence(timeout:10));photo("Native guided Tutor quest complete",app)
    }
    func testDailyPracticeCompletesTutorLessonAndFinalReviewThenNotesAndRelaunch()async throws{
        let relay=LocalNostrRelay();try await relay.start{frame,connection in if frame.first as? String == "REQ",let sub=frame[1] as? String{relay.send(["EOSE",sub],to:connection)}};defer{relay.stop()};let app=launch("full",walletRelay:relay.url);completeTutor(app);tap("guidedContinue",app)
        tap("lessonNode-lesson-pre-a1-1-1",app);tap("startLessonFromPreview",app);XCTAssertTrue(app.staticTexts["lessonCompletionBonus"].waitForExistence(timeout:15));XCTAssertEqual(app.staticTexts["lessonCompletionBonus"].label,"+80");tap("continueLessonCompletion",app)
        XCTAssertTrue(app.buttons["guidedContinue"].waitForExistence(timeout:10));photo("Native guided lesson quest complete",app);tap("guidedContinue",app)
        tap("flashcardTile-pre-a1-people-1",app);let answer=app.textFields["flashcardAnswer"];XCTAssertTrue(answer.waitForExistence(timeout:10));answer.tap();answer.typeText("mamá\n");tap("flashcardRate-hard",app)
        XCTAssertTrue(app.buttons["plateViewNotes"].waitForExistence(timeout:10));photo("Native all daily quests complete",app);XCTAssertTrue(app.staticTexts["+25"].exists);tap("plateViewNotes",app);tap("productPanelClose",app);XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:10));XCTAssertFalse(app.buttons["guidedContinue"].exists)
        app.terminate();app.launch();handleInitialPaperPencil(app);XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["guidedContinue"].exists);XCTAssertFalse(app.buttons["dailyGoalRewardContinue"].exists);photo("Native completed daily quest after relaunch",app)
    }
    func testConversationCourseCompletionStopsLiveCallBeforeContinuingToReview(){
        let app=launch("conversation");tap("startDailyPractice",app);XCTAssertTrue(app.staticTexts["conversationGoal"].waitForExistence(timeout:15));tap("conversationStart",app)
        XCTAssertTrue(app.buttons["guidedContinue"].waitForExistence(timeout:25));XCTAssertFalse(app.buttons["conversationSummaryDone"].exists);XCTAssertFalse(app.buttons["conversationEnd"].exists);photo("Native guided conversation stopped at course completion",app)
        tap("guidedContinue",app);XCTAssertTrue(app.buttons["flashcardTile-pre-a1-people-1"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["conversationSummaryDone"].exists)
    }
    func testReturningFocusCentersTheLatestLessonAfterRelaunch(){
        let app=launch("returning-learn")
        XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15))
        app.terminate();app.launch();handleInitialPaperPencil(app)
        tap("startDailyPractice",app)
        let lesson=app.buttons["lessonNode-lesson-pre-a1-3-1"],path=app.scrollViews.firstMatch
        let centered=NSPredicate { _,_ in
            lesson.isHittable && abs(lesson.frame.midY-path.frame.midY) < 50
        }
        func expectCentered(){
            XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:centered,object:nil)],timeout:15),.completed)
            XCTAssertEqual(lesson.value as? String,"in_progress")
            XCTAssertFalse(app.buttons["startLessonFromPreview"].exists)
        }
        expectCentered()
        photo("Native Focus Learn resumes centered on the latest lesson",app)
        lesson.tap();XCTAssertTrue(app.buttons["startLessonFromPreview"].waitForExistence(timeout:10));tap("closeLessonPreview",app)
        for _ in 0..<3 { app.swipeDown(velocity:.fast) }
        XCTAssertFalse(centered.evaluate(with:nil))
        tap("productMenu",app);tap("productModeMenu",app);tap("productMode-path",app)
        expectCentered()
        photo("Native selecting the current Course recenters the next lesson",app)
    }
    func testNextDayFocusKeepsEarnedXPAndDropsYesterdaysGuidedReview() {
        let app=launch("rollover-learn")
        let dailyXP=app.descendants(matching:.any).matching(identifier:"dailyXPStatus").firstMatch
        func expectToday() {
            XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15))
            let reset=XCTNSPredicateExpectation(predicate:NSPredicate(format:"value == %@","0%"),object:dailyXP)
            XCTAssertEqual(XCTWaiter.wait(for:[reset],timeout:10),.completed)
            XCTAssertTrue(app.staticTexts["XP 25"].exists)
            XCTAssertTrue(app.buttons["startDailyPractice"].label.contains("Start"))
            XCTAssertFalse(app.buttons["guidedContinue"].exists)
        }
        expectToday()
        photo("Native next-day Focus keeps yesterday's earned XP",app)
        app.terminate();app.launch()
        expectToday()
        tap("startDailyPractice",app)
        XCTAssertTrue(app.buttons["lessonNode-lesson-pre-a1-3-1"].waitForExistence(timeout:15))
        XCTAssertFalse(app.buttons["flashcardTile-pre-a1-people-1"].exists)
    }
    func testTutorDailyGoalReviewAndCourseCelebrationSurviveRootTrialLimit()async throws{
        let relay=LocalNostrRelay();try await relay.start{frame,connection in if frame.first as? String == "REQ",let sub=frame[1] as? String{relay.send(["EOSE",sub],to:connection)}};defer{relay.stop()};let app=launch("tutor-trial",walletRelay:relay.url);completeTutor(app);tap("guidedContinue",app)
        XCTAssertTrue(app.buttons["subscriptionConnect"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["tutorStart"].isHittable);photo("Native subscription after earned quest sequence",app)
        app.terminate();app.launch();handleInitialPaperPencil(app);XCTAssertTrue(app.buttons["subscriptionConnect"].waitForExistence(timeout:15));XCTAssertFalse(app.buttons["guidedContinue"].exists);tap("subscriptionNativeTools",app);XCTAssertTrue(app.buttons["Refresh subscription"].waitForExistence(timeout:10));XCTAssertTrue(app.links["subscriptionWebLink"].exists || app.buttons["subscriptionWebLink"].exists);photo("Native subscription iPhone purchases and web link",app)
    }
}
