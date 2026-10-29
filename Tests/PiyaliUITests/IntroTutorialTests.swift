import XCTest

@MainActor final class IntroTutorialPlayTests:XCTestCase {
    private typealias PlayFixture=RPGPlayFixture
    private func reveal(_ element:XCUIElement,in app:XCUIApplication) { for _ in 0..<8 where !element.isHittable { app.swipeUp(velocity:.slow) };XCTAssertTrue(element.isHittable) }
    private func launch(walletRelay:String?=nil)->XCUIApplication {
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_PRACTICE_FIXTURE"]="delight:natural_or_weird"
        if let walletRelay{app.launchEnvironment["PIYALI_WALLET_TEST_RELAY"]=walletRelay}
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Intro Learner");if app.buttons["entryKeyboardDone"].exists { app.buttons["entryKeyboardDone"].tap() };app.buttons["createAccount"].tap();XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:20));app.buttons["startLearning"].tap();return app
    }
    private func path(_ app:XCUIApplication) { XCTAssertTrue(app.buttons["productMenu"].waitForExistence(timeout:15));app.buttons["productMenu"].tap();app.buttons["productModeMenu"].tap();app.buttons["productMode-path"].tap() }
    private func open(_ app:XCUIApplication) { path(app);XCTAssertTrue(app.buttons["introLink"].waitForExistence(timeout:15));app.buttons["introLink"].tap();XCTAssertTrue(app.buttons["startLessonFromPreview"].waitForExistence(timeout:5));app.buttons["startLessonFromPreview"].tap() }
    private func skip(_ app:XCUIApplication) { let button=app.buttons.matching(NSPredicate(format:"identifier IN %@",["skipLessonActivity","skipIntroActivity","realtimeSkip","rpgBack"])).firstMatch;XCTAssertTrue(button.waitForExistence(timeout:10));reveal(button,in:app);button.tap() }
    func testInlineSequenceResumesAndFinishesWithOneBonusAfterAllSixActivities() async throws {
        continueAfterFailure=false;let relay=LocalNostrRelay();var walletEvents:[[String:Any]]=[];try await relay.start{frame,connection in if frame.first as? String == "REQ",let sub=frame[1] as? String{for event in walletEvents{relay.send(["EVENT",sub,event],to:connection)};relay.send(["EOSE",sub],to:connection)}else if frame.first as? String == "EVENT",let event=frame[1] as? [String:Any],let id=event["id"] as? String{walletEvents.append(event);relay.send(["OK",id,true,""],to:connection)}};defer{relay.stop()};let app=launch(walletRelay:relay.url);open(app)
        XCTAssertTrue(app.buttons["introStep-vocabulary"].waitForExistence(timeout:5));XCTAssertEqual(app.buttons["introStep-vocabulary"].value as? String,"Current");XCTAssertFalse(app.buttons["Try Vocabulary"].exists)
        skip(app);XCTAssertEqual(app.buttons["introStep-grammar"].value as? String,"Current");skip(app);XCTAssertEqual(app.buttons["introStep-reading"].value as? String,"Current")
        app.terminate();app.launch();open(app);XCTAssertTrue(app.buttons["introStep-reading"].waitForExistence(timeout:5));XCTAssertEqual(app.buttons["introStep-reading"].value as? String,"Current");XCTAssertEqual(app.buttons["introStep-vocabulary"].value as? String,"Completed")
        skip(app);skip(app)
        XCTAssertTrue(app.staticTexts["realtimeGoal"].waitForExistence(timeout:5));XCTAssertEqual(app.staticTexts["realtimeGoal"].label,"Say hello");XCTAssertTrue(app.buttons["realtimeStart"].isEnabled);XCTAssertFalse(app.buttons["End session"].exists,"Entering realtime does not open the microphone")
        let voice=XCTAttachment(screenshot:app.screenshot());voice.name="Native introductory realtime goal waits for the learner";voice.lifetime = .keepAlways;add(voice)
        skip(app);XCTAssertTrue(app.buttons["rpgBack"].waitForExistence(timeout:10));skip(app)
        let bonus=app.staticTexts["lessonCompletionBonus"];XCTAssertTrue(bonus.waitForExistence(timeout:10));XCTAssertEqual(bonus.label,"+50");app.buttons["continueLessonCompletion"].tap();guard app.buttons["scholarshipLater"].waitForExistence(timeout:10) else{let failure=XCTAttachment(screenshot:app.screenshot());failure.name="Missing scholarship after intro";failure.lifetime = .keepAlways;add(failure);XCTFail("Scholarship must follow introductory completion");return};let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Native scholarship after introduction";shot.lifetime = .keepAlways;add(shot);app.buttons["scholarshipRecipient-Girls On Campus"].tap();XCTAssertTrue(app.buttons["scholarshipRecipient-Girls On Campus"].isSelected);let create=app.buttons["walletCreate"];XCTAssertTrue(create.waitForExistence(timeout:10));create.tap();XCTAssertTrue(app.buttons["walletDeposit"].waitForExistence(timeout:15));XCTAssertTrue(app.buttons["walletDeposit"].isEnabled);XCTAssertTrue(app.buttons["scholarshipRecipientAccordion"].label.contains("Girls On Campus"));let created=XCTAttachment(screenshot:app.screenshot());created.name="Native wallet created inside scholarship prompt";created.lifetime = .keepAlways;add(created);app.buttons["scholarshipLater"].tap()
        XCTAssertTrue(app.buttons["lessonNode-lesson-pre-a1-1-1"].waitForExistence(timeout:5));XCTAssertTrue(app.buttons["lessonNode-lesson-pre-a1-1-1"].isEnabled)
        app.terminate();app.launch();path(app);XCTAssertTrue(app.buttons["lessonNode-lesson-pre-a1-1-1"].waitForExistence(timeout:10));XCTAssertTrue(app.buttons["lessonNode-lesson-pre-a1-1-1"].isEnabled);XCTAssertFalse(bonus.exists)
        app.buttons["introLink"].tap();app.buttons["startLessonFromPreview"].tap();XCTAssertTrue(app.buttons["introStep-vocabulary"].waitForExistence(timeout:5));XCTAssertEqual(app.buttons["introStep-vocabulary"].value as? String,"Current")
        for _ in 0..<6 { skip(app) };XCTAssertTrue(app.buttons["lessonNode-lesson-pre-a1-1-1"].waitForExistence(timeout:5));XCTAssertFalse(bonus.exists,"Review retains the completed introduction receipt");XCTAssertFalse(app.buttons["scholarshipLater"].exists,"Seen scholarship prompt must not replay");XCTAssertEqual(walletEvents.filter{$0["kind"] as? Int == 17375}.count,1);XCTAssertEqual(walletEvents.filter{$0["kind"] as? Int == 10019}.count,1);XCTAssertFalse(walletEvents.contains{$0["kind"] as? Int == 9321})
    }
    func testAuthoredIntroAdventureFinishesTheInlineSequenceWithoutClaimingUnitXP() throws {
        continueAfterFailure=false;let fixture=try JSONDecoder().decode(PlayFixture.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"intro-play",withExtension:"json"))))
        let app=launch();open(app);for _ in 0..<5 { skip(app) };XCTAssertTrue(app.staticTexts["rpgStatus"].waitForExistence(timeout:15))
        func tap(_ id:String) { let button=app.buttons[id];reveal(button,in:app);button.tap() }
        for step in fixture.steps {
            try rpgApproach(step,fixture,app)
            if step.mode == "choice" { tap("rpgChoice-\(step.correct)") }
            else { app.buttons["rpgMicrophone"].press(forDuration:1);app.buttons["Response"].tap();let field=app.descendants(matching:.any)["rpgReply"];reveal(field,in:app);field.tap();field.typeText(step.example+"\n");XCTAssertTrue(app.buttons["rpgContinue"].waitForExistence(timeout:10)) }
            tap("rpgContinue")
        }
        XCTAssertTrue(app.staticTexts["lessonCompletionBonus"].waitForExistence(timeout:10));XCTAssertFalse(app.buttons["rpgComplete"].exists,"The original Intro advances automatically after its last game task");XCTAssertEqual(app.staticTexts["lessonCompletionBonus"].label,"+50")
    }
}
