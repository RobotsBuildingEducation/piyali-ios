import XCTest

@MainActor final class TutorReplayJourneyTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication){let e=app.buttons[id];XCTAssertTrue(e.waitForExistence(timeout:15));XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"hittable == true"),object:e)],timeout:10),.completed);e.tap()}
    private func wait(_ element:XCUIElement,enabled:Bool){XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == %@",NSNumber(value:enabled)),object:element)],timeout:12),.completed)}
    private func shot(_ name:String,_ app:XCUIApplication){let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    func testNormalTutorReplaysSavedClipsRestoresControlsAndKeepsHistoryPrivate()throws{
        continueAfterFailure=false;let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_TUTOR_FIXTURE":"1","PIYALI_TUTOR_REPLY_FIXTURE":"1","PIYALI_TUTOR_REPLAY_FIXTURE":"1"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Replay Learner");tap("entryKeyboardDone",app);tap("createAccount",app);tap("startLearning",app)
        func tutor(){tap("productMenu",app);tap("productModeMenu",app);tap("productMode-tutor",app);XCTAssertTrue(app.buttons["tutorStart"].waitForExistence(timeout:15))}
        tutor();tap("tutorStart",app)
        let reply=app.descendants(matching:.any)["tutorLatestReply"];XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","al mercado"),object:reply)],timeout:20),.completed)
        let replay=app.buttons["tutorReplay"];XCTAssertTrue(replay.waitForExistence(timeout:5));replay.tap();wait(replay,enabled:false);XCTAssertTrue(app.buttons["tutorMute"].isEnabled);XCTAssertTrue(app.buttons["tutorPause"].isEnabled);shot("Native Tutor recorded reply replay active",app);wait(replay,enabled:true);XCTAssertFalse(app.descendants(matching:.any)["tutorError"].exists)
        replay.tap();wait(replay,enabled:false);tap("tutorPause",app);wait(replay,enabled:true);XCTAssertEqual(app.staticTexts["tutorVoiceStatus"].label.uppercased(),"PAUSED");shot("Native Tutor replay interrupted by pause",app);tap("tutorPause",app);XCTAssertTrue(app.staticTexts["tutorLiveStatus"].waitForExistence(timeout:10));tap("tutorEnd",app);app.swipeDown();tap("tutorHistory",app)
        let buttons=app.buttons.matching(identifier:"tutorReplay");XCTAssertGreaterThanOrEqual(buttons.count,2);let first=try XCTUnwrap(buttons.allElementsBoundByIndex.first(where:{$0.isHittable}));first.tap();wait(first,enabled:false);XCTAssertTrue(buttons.allElementsBoundByIndex.contains(where:{$0.isEnabled}));shot("Native Tutor history replay keeps other reply available",app);wait(first,enabled:true);tap("tutorHistoryClose",app)
        app.terminate();app.launch();tutor();XCTAssertFalse(app.buttons["tutorHistory"].isEnabled);XCTAssertFalse(app.buttons["tutorReplay"].exists);shot("Native Tutor recording cache does not expose private replies on relaunch",app)
    }
}
