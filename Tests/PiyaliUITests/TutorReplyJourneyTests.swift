import XCTest
@MainActor final class TutorReplyJourneyTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication){let e=app.buttons[id];XCTAssertTrue(e.waitForExistence(timeout:15));XCTAssertTrue(e.isHittable);e.tap()}
    private var captureLanguage="en"
    private func shot(_ label:String,_ app:XCUIApplication){let a=XCTAttachment(screenshot:app.screenshot());a.name=label+" "+captureLanguage;a.lifetime = .keepAlways;add(a)}
    func testNormalTutorLongReplyPhraseCardsControlsHistoryAndPrivateRelaunch(){run(language:"en",theme:"light")}
    func testArabicTutorLongReplyPhraseCardsControlsHistoryAndPrivateRelaunch(){run(language:"ar",theme:"dark")}
    private func run(language:String,theme:String){captureLanguage=language
        continueAfterFailure=false;let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_TUTOR_FIXTURE":"1","PIYALI_TUTOR_REPLY_FIXTURE":"1"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage",language,"-piyali.theme",theme];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Reply Learner");tap("entryKeyboardDone",app);tap("createAccount",app);tap("startLearning",app)
        func tutor(){tap("productMenu",app);tap("productModeMenu",app);tap("productMode-tutor",app);XCTAssertTrue(app.buttons["tutorStart"].waitForExistence(timeout:15))}
        tutor();tap("tutorStart",app);let reply=app.descendants(matching:.any)["tutorLatestReply"];let result=XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","al mercado"),object:reply)],timeout:20);if result != .completed{shot("Native Tutor reply lookup failure",app);let a=XCTAttachment(string:app.debugDescription);a.name="Native Tutor reply lookup hierarchy";a.lifetime = .keepAlways;add(a)};XCTAssertEqual(result,.completed)
        let card=app.descendants(matching:.any)["tutorPhrase-3"];XCTAssertTrue(card.waitForExistence(timeout:10));for _ in 0..<4{if card.isHittable{break};app.swipeUp()};XCTAssertTrue(card.isHittable);XCTAssertTrue(app.buttons["tutorMute"].isHittable);XCTAssertTrue(app.buttons["tutorPause"].isHittable);XCTAssertTrue(app.staticTexts["tutorLiveStatus"].waitForExistence(timeout:5));shot("Native Tutor long reply with translated phrase cards",app);reply.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:20,dy:10)).tap();XCTAssertTrue(reply.isSelected);shot("Native Tutor repeated phrases selected",app)
        tap("tutorMute",app);XCTAssertFalse(app.staticTexts["tutorLiveStatus"].exists);tap("tutorPause",app);XCTAssertEqual(app.staticTexts["tutorVoiceStatus"].label.uppercased(),"PAUSED");shot("Native Tutor long reply paused controls",app);tap("tutorPause",app);tap("tutorEnd",app);XCTAssertFalse(app.staticTexts["tutorLiveStatus"].exists)
        app.swipeDown();tap("tutorHistory",app);XCTAssertTrue(app.descendants(matching:.any).matching(NSPredicate(format:"label CONTAINS %@","al mercado")).firstMatch.waitForExistence(timeout:8));shot("Native Tutor long reply retained in private history",app);tap("tutorHistoryClose",app)
        app.terminate();app.launch();tutor();XCTAssertFalse(app.staticTexts["tutorLatestReply"].exists);XCTAssertFalse(app.descendants(matching:.any)["tutorPhrase-0"].exists);XCTAssertFalse(app.buttons["tutorHistory"].isEnabled);shot("Native Tutor long reply stays private after relaunch",app)
    }
}
