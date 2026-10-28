import XCTest
@MainActor final class DelightBodyJourneyTests:XCTestCase {
    private func element(_ id:String,_ app:XCUIApplication)->XCUIElement{app.descendants(matching:.any).matching(identifier:id).firstMatch}
    private func reveal(_ e:XCUIElement,_ app:XCUIApplication){for _ in 0..<14 where !e.isHittable{if e.exists,e.frame.midY<app.frame.midY{app.swipeDown(velocity:.slow)}else{app.swipeUp(velocity:.slow)}};if !e.isHittable{shot("Missing exercise interaction",app)};XCTAssertTrue(e.isHittable)}
    private func tap(_ id:String,_ app:XCUIApplication){let e=element(id,app);XCTAssertTrue(e.waitForExistence(timeout:10));reveal(e,app);e.tap()}
    private func shot(_ name:String,_ app:XCUIApplication){let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    private func launch(_ variant:String)->XCUIApplication {
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_HEADLINE_FIXTURE":"failure","PIYALI_PRACTICE_JUDGE_FIXTURE":"offered-reference","PIYALI_PRACTICE_FIXTURE":"delight:"+variant];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en","-piyali.theme","light"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Exercise Learner");tap("entryKeyboardDone",app);tap("createAccount",app);chooseEnglishSpanishOnboarding(app);tap("startLearning",app);tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);chooseA1Placement(app);open(app);return app
    }
    private func open(_ app:XCUIApplication){tap("productMenu",app);tap("productModeMenu",app);tap("productMode-path",app);if !app.buttons["lessonNode-lesson-pre-a1-1-1"].exists{tap("lessonPreviousLevel",app)};tap("lessonNode-lesson-pre-a1-1-1",app);tap("startLessonFromPreview",app);XCTAssertTrue(element("typedQuestionPrompt",app).waitForExistence(timeout:10))}
    private func word(_ text:String,placed:Bool,_ app:XCUIApplication)->XCUIElement{app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@ AND label == %@",placed ? "neighborhoodPlaced-":"neighborhoodWord-",text)).firstMatch}
    private func assign(_ text:String,group:Int,_ app:XCUIApplication){let w=word(text,placed:false,app);XCTAssertTrue(w.waitForExistence(timeout:5));reveal(w,app);w.tap();tap("neighborhoodGroup-\(group)",app);XCTAssertTrue(word(text,placed:true,app).waitForExistence(timeout:5))}
    func testNeighborhoodTapReturnNativeDragRetryAndFreshReentry() {
        continueAfterFailure=false;let app=launch("word_neighborhoods");let food=["manzana","plátano","pera"],clothes=["camisa","zapatos","pantalones"]
        XCTAssertFalse(app.buttons["checkTypedAnswer"].isEnabled);assign(food[0],group:0,app)
        let placed=word(food[0],placed:true,app);reveal(placed,app);placed.tap();XCTAssertTrue(word(food[0],placed:false,app).waitForExistence(timeout:5))
        let source=word(food[0],placed:false,app),bucket=element("neighborhoodGroup-0",app);reveal(source,app);source.press(forDuration:1,thenDragTo:bucket);XCTAssertTrue(word(food[0],placed:true,app).waitForExistence(timeout:5));shot("Native sorting word dropped into bucket",app)
        let bank=element("neighborhoodBank",app),back=word(food[0],placed:true,app);back.press(forDuration:1,thenDragTo:bank);XCTAssertTrue(word(food[0],placed:false,app).waitForExistence(timeout:5))
        for item in food+clothes{assign(item,group:0,app)};tap("checkTypedAnswer",app);XCTAssertTrue(app.staticTexts["practiceVerdict"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["practiceVerdict"].label.contains("Try again"))
        for item in clothes{let e=word(item,placed:true,app);reveal(e,app);e.tap();assign(item,group:1,app)};shot("Native sorting corrected buckets",app);tap("checkTypedAnswer",app);XCTAssertTrue(app.buttons["nextTypedQuestion"].waitForExistence(timeout:5));XCTAssertFalse(word(food[0],placed:true,app).isEnabled);XCTAssertTrue(app.staticTexts["activeLessonXP"].exists)
        app.terminate();app.launch();open(app);XCTAssertTrue(word(food[0],placed:false,app).exists);XCTAssertFalse(app.staticTexts["practiceVerdict"].exists);XCTAssertFalse(app.buttons["checkTypedAnswer"].isEnabled);shot("Native sorting fresh entry after relaunch",app)
    }
    func testForgeLivePreviewTapRemoveNativeDragAndWrongAnswerRepair() {
        continueAfterFailure=false;let app=launch("morphology_forge");tap("forgePiece-0",app);XCTAssertTrue(app.staticTexts["forgeSentence"].label.contains("jug"));tap("forgeChosen-0",app);XCTAssertTrue(app.buttons["forgePiece-0"].exists)
        let piece=app.buttons["forgePiece-0"],tray=element("forgeTray",app);piece.press(forDuration:1,thenDragTo:tray);XCTAssertTrue(app.buttons["forgeChosen-0"].waitForExistence(timeout:5));shot("Native forge piece dropped into tray",app)
        app.buttons["forgeChosen-0"].press(forDuration:1,thenDragTo:element("forgeBank",app));XCTAssertTrue(app.buttons["forgePiece-0"].waitForExistence(timeout:5))
        for index in 0..<4{tap("forgePiece-\(index)",app)};tap("checkTypedAnswer",app);XCTAssertTrue(app.staticTexts["practiceVerdict"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["practiceVerdict"].label.contains("Try again"));for _ in 0..<4{tap("forgeChosen-0",app)};tap("forgePiece-0",app);tap("forgePiece-1",app);XCTAssertTrue(app.staticTexts["forgeSentence"].label.contains("jugábamos"));shot("Native forged word in sentence",app);tap("checkTypedAnswer",app);XCTAssertTrue(app.buttons["nextTypedQuestion"].waitForExistence(timeout:5));XCTAssertFalse(app.buttons["forgeChosen-0"].isEnabled)
    }
    func testDetectiveRejectsAndLocksTokensThenShowsRepairPreviewBeforeGrading() {
        continueAfterFailure=false;let app=launch("sentence_detective");tap("detectiveToken-0",app);XCTAssertEqual(app.buttons["detectiveToken-0"].value as? String,"Rejected");XCTAssertFalse(app.buttons["detectiveToken-0"].isEnabled);XCTAssertFalse(app.buttons["checkTypedAnswer"].isEnabled);tap("detectiveToken-5",app)
        for index in 0..<6{XCTAssertFalse(app.buttons["detectiveToken-\(index)"].isEnabled)};XCTAssertFalse(app.buttons["checkTypedAnswer"].isEnabled);tap("detectiveRepair-1",app);XCTAssertTrue(app.staticTexts["detectivePreview"].label.contains("cuchara"));tap("checkTypedAnswer",app);XCTAssertTrue(app.staticTexts["practiceVerdict"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["practiceVerdict"].label.contains("Try again"));tap("detectiveRepair-0",app);XCTAssertTrue(app.staticTexts["detectivePreview"].label.contains("llave"));shot("Native detective repaired sentence",app);tap("checkTypedAnswer",app);XCTAssertTrue(app.buttons["nextTypedQuestion"].waitForExistence(timeout:5));XCTAssertFalse(app.buttons["detectiveRepair-0"].isEnabled)
    }
    func testDialogueAndListeningKeepSourceChoiceAndAudioControlsThroughRetry() {
        continueAfterFailure=false
        for variant in ["dialogue_fork","listen_difference"] {
            let app=launch(variant);XCTAssertTrue(app.buttons["typedPracticeListen"].exists);XCTAssertFalse(app.buttons["checkTypedAnswer"].isEnabled)
            let correct=variant == "dialogue_fork" ? 1:0,wrong=1-correct;tap("typedChoice-\(wrong)",app);tap("checkTypedAnswer",app);XCTAssertTrue(app.staticTexts["practiceVerdict"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["practiceVerdict"].label.contains("Try again"));tap("typedChoice-\(correct)",app);tap("checkTypedAnswer",app);XCTAssertTrue(app.buttons["nextTypedQuestion"].waitForExistence(timeout:5));XCTAssertFalse(app.buttons["typedChoice-\(wrong)"].isEnabled);XCTAssertEqual(app.buttons["typedPracticeListen"].isEnabled,variant == "listen_difference");shot("Native \(variant) correct choices",app);app.terminate()
        }
    }
}
