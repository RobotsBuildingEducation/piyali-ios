import XCTest

@MainActor final class TutorParityTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication){let button=app.buttons[id];XCTAssertTrue(button.waitForExistence(timeout:15));XCTAssertTrue(button.isHittable);button.tap()}
    private func photo(_ name:String,_ app:XCUIApplication){let shot=XCTAttachment(screenshot:app.screenshot());shot.name=name;shot.lifetime = .keepAlways;add(shot)}
    private func open(_ app:XCUIApplication){tap("productMenu",app);tap("productModeMenu",app);tap("productMode-tutor",app);XCTAssertTrue(app.staticTexts["tutorLessonTitle"].waitForExistence(timeout:15))}
    private func start(asr:Bool=false,late:Bool=false,memory:Bool=false)->XCUIApplication {
        continueAfterFailure=false;let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_TUTOR_FIXTURE":"1"];if memory{app.launchEnvironment["PIYALI_MEMORY_FIXTURE"]="0";app.launchEnvironment["PIYALI_TUTOR_MEMORY_FIXTURE"]="1";app.launchEnvironment["PIYALI_MEMORY_CAPTURE_ONLY"]="0"};if asr{app.launchEnvironment["PIYALI_TUTOR_ASR_RECOVERY_FIXTURE"]="1"};if late{app.launchEnvironment["PIYALI_TUTOR_LATE_SPEECH_FIXTURE"]="1"};app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch();handleInitialPaperPencil(app)
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText(late ? "Late Speech Learner":asr ? "ASR Recovery Learner":"Tutor Learner");if app.buttons["entryKeyboardDone"].exists{app.buttons["entryKeyboardDone"].tap()};tap("createAccount",app);handleInitialPaperPencil(app);tap("startLearning",app);open(app);return app
    }
    func testSourceVoiceEntryPathLockedPreviewWelcomeMutePauseResumeAndPrivateRelaunch(){
        let app=start();XCTAssertFalse(app.textFields["Message your tutor"].exists);XCTAssertFalse(app.buttons["tutorHistory"].isEnabled);XCTAssertTrue(app.staticTexts["tutorLessonTitle"].label.contains("Tutorial"));photo("Native Tutor product entry",app)
        tap("tutorLessons",app);photo("Native Tutor product path",app);tap("tutorNode-lesson-tutorial-1",app);tap("tutorPreviewObjectives",app);XCTAssertEqual(app.buttons["tutorPreviewObjectives"].value as? String,"Expanded");photo("Native Tutor product introductory preview",app);XCTAssertTrue(app.buttons["tutorPreviewStart"].label.contains("Start game"));XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label BEGINSWITH %@","learn to say hello")).firstMatch.exists);tap("tutorPreviewClose",app)
        let locked=app.buttons["tutorNode-lesson-pre-a1-1-1"];if !locked.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(locked.waitForExistence(timeout:5));locked.tap();XCTAssertTrue(app.otherElements["tutorPreviewLocked"].exists || app.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","This lesson is locked")).firstMatch.exists);XCTAssertFalse(app.buttons["tutorPreviewStart"].isEnabled);tap("tutorPreviewClose",app);tap("tutorPathClose",app)
        tap("tutorStart",app);let reply=app.staticTexts["tutorLatestReply"];XCTAssertTrue(reply.waitForExistence(timeout:10));XCTAssertTrue(reply.label.contains("Welcome"));tap("tutorMute",app);tap("tutorPause",app);XCTAssertEqual(app.staticTexts["tutorVoiceStatus"].label.uppercased(),"PAUSED");photo("Native Tutor paused",app);tap("tutorPause",app);XCTAssertEqual(app.buttons["tutorMute"].label,"Unmute microphone");tap("tutorEnd",app)
        tap("tutorHistory",app);XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","Welcome!")).firstMatch.exists);app.buttons["Close"].tap();app.terminate();app.launch();handleInitialPaperPencil(app);open(app);XCTAssertFalse(app.staticTexts["tutorLatestReply"].exists);XCTAssertFalse(app.buttons["tutorHistory"].isEnabled);photo("Native Tutor fresh private reconnect",app)
    }
}


extension TutorParityTests {
    func testNormalProductUnexpectedSpeechRecoveryKeepsHistoryUngradedAndPrivateOnRelaunch() {
        let app=start(asr:true);tap("tutorStart",app)
        let reply=app.descendants(matching:.any)["tutorLatestReply"]
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Please try hola once more."),object:reply)],timeout:25),.completed)
        XCTAssertEqual(app.staticTexts["tutorLiveStatus"].label.lowercased(),"listening");XCTAssertFalse(app.descendants(matching:.any)["tutorError"].exists)
        XCTAssertTrue(app.staticTexts["0%"].exists);photo("Native Tutor ASR recovery in complete product shell",app)
        tap("tutorEnd",app);tap("tutorHistory",app)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","Please try hola once more.")).firstMatch.waitForExistence(timeout:8))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","नमस्ते")).firstMatch.exists);photo("Native Tutor ASR rejected speech absent from private history",app);tap("tutorHistoryClose",app)
        app.terminate();app.launch();handleInitialPaperPencil(app);open(app)
        XCTAssertTrue(app.buttons["tutorStart"].isEnabled);XCTAssertFalse(app.buttons["tutorHistory"].isEnabled);XCTAssertFalse(app.descendants(matching:.any)["tutorLatestReply"].exists);photo("Native Tutor ASR recovery remains private and disconnected on relaunch",app)
    }
}


extension TutorParityTests {
    func testNormalProductLateSpeechCreditsOnceKeepsChatPrivateAndRestoresProgressOnRelaunch() {
        let app=start(late:true);tap("tutorStart",app)
        let badge=app.staticTexts["tutorProgressBadge"]
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"label != %@","0%"),object:badge)],timeout:25),.completed)
        XCTAssertTrue((6...14).contains(Int(badge.label.replacingOccurrences(of:"%",with:"")) ?? -1));XCTAssertFalse(app.descendants(matching:.any)["tutorError"].exists)
        // Allow the second, distinct correct burst and its duplicate to arrive.
        let until=Date().addingTimeInterval(2);while Date()<until{RunLoop.current.run(until:Date().addingTimeInterval(0.1))}
        let percent=badge.label;photo("Native Tutor late speech credits the existing turn in product shell",app)
        tap("tutorEnd",app);tap("tutorHistory",app)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label == %@","I do not know")).firstMatch.waitForExistence(timeout:8))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format:"label == %@","hola")).firstMatch.exists);XCTAssertFalse(app.staticTexts.matching(NSPredicate(format:"label == %@","me llamo")).firstMatch.exists)
        photo("Native Tutor late speech is absent from private chat history",app);tap("tutorHistoryClose",app)
        app.terminate();app.launch();handleInitialPaperPencil(app);open(app)
        XCTAssertEqual(app.staticTexts["tutorProgressBadge"].label,percent);XCTAssertTrue(app.buttons["tutorStart"].isEnabled);XCTAssertFalse(app.buttons["tutorHistory"].isEnabled);XCTAssertFalse(app.descendants(matching:.any)["tutorLatestReply"].exists)
        photo("Native Tutor late progress persists and replies stay private after relaunch",app)
    }
}


extension TutorParityTests {
    func testNormalSignupTutorSemanticMemoryEnrichesWithoutXPAndSurvivesRelaunch() {
        let app=start(memory:true);tap("tutorStart",app)
        let menu=app.buttons["productMenu"]
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"value == %@","Note saved!"),object:menu)],timeout:25),.completed)
        XCTAssertEqual(app.staticTexts["tutorProgressBadge"].label,"0%");XCTAssertFalse(app.descendants(matching:.any)["tutorError"].exists);photo("Native Tutor low-confidence semantic Memory capture in product shell",app)
        tap("tutorEnd",app);tap("productMenu",app);tap("productPanel-memory",app)
        let card=app.descendants(matching:.any).matching(NSPredicate(format:"identifier BEGINSWITH 'memoryRepair-' AND label CONTAINS 'A greeting'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout:15));XCTAssertTrue(card.label.contains("The greeting was missing."));XCTAssertTrue(card.label.contains("Start with hola."));XCTAssertFalse(card.label.contains("Private fixture judge reason"));let id=card.identifier
        photo("Native captured Tutor Memory enriched after End",app);tap("productPanelClose",app)
        app.terminate();app.launch();handleInitialPaperPencil(app);XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));tap("productMenu",app);tap("productPanel-memory",app)
        let restored=app.descendants(matching:.any)[id];XCTAssertTrue(restored.waitForExistence(timeout:10));XCTAssertTrue(restored.label.contains("Start with hola."));XCTAssertEqual(app.descendants(matching:.any).matching(NSPredicate(format:"identifier BEGINSWITH 'memoryRepair-'")).count,1)
        photo("Native Tutor Memory retained exactly once after process relaunch",app)
    }
}
