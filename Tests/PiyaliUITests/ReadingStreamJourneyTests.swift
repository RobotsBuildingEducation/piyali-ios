import XCTest

@MainActor final class ReadingStreamJourneyTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication) {
        let button=app.buttons[id];XCTAssertTrue(button.waitForExistence(timeout:15))
        for _ in 0..<8 where !button.isHittable {app.swipeUp(velocity:.slow)}
        XCTAssertTrue(button.isHittable);button.tap()
    }
    private func openReading(_ app:XCUIApplication) {
        tap("productMenu",app);tap("productModeMenu",app);tap("productMode-path",app);tap("introLink",app);tap("startLessonFromPreview",app)
        for _ in 0..<2 {if app.buttons["introStep-reading"].value as? String == "Current" {break};tap("skipLessonActivity",app)}
    }
    private func start(_ fixtures:[String:String])->XCUIApplication {
        continueAfterFailure=false
        let app=XCUIApplication()
        app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_READING_FIXTURE":"1","PIYALI_READING_AUDIO_FIXTURE":"1","PIYALI_PRACTICE_FIXTURE":"delight:natural_or_weird"]
        app.launchEnvironment.merge(fixtures) {_,fixture in fixture}
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en"]
        app.launch()
        let name=app.textFields["entryName"]
        XCTAssertTrue(name.waitForExistence(timeout:15))
        name.tap()
        name.typeText("Reading Learner")
        tap("entryKeyboardDone",app);tap("createAccount",app);tap("startLearning",app)
        openReading(app)
        return app
    }
    private func photo(_ title:String,_ app:XCUIApplication) {
        let shot=XCTAttachment(screenshot:app.screenshot())
        shot.name=title
        shot.lifetime = .keepAlways
        add(shot)
    }
    private func atLine(_ passage:XCUIElement,fraction:CGFloat=0.25,y:CGFloat=16)->XCUICoordinate {
        passage.coordinate(withNormalizedOffset:CGVector(dx:fraction,dy:0)).withOffset(CGVector(dx:0,dy:y))
    }

    func testWrappedSentencesStayTappableWithAndWithoutTranslations() {
        let app=start([:])
        let passage=app.descendants(matching:.any)["readingPassage"]
        XCTAssertTrue(passage.waitForExistence(timeout:12))
        XCTAssertGreaterThan(passage.frame.height,200)
        photo("Native Reading inline sentence colors",app)

        let second="Es una libreta pequeña y no tiene líneas."
        atLine(passage,fraction:0.97).tap()
        XCTAssertEqual(passage.value as? String,second)
        atLine(passage,y:51).tap()
        XCTAssertEqual(passage.value as? String,second)
        XCTAssertFalse(app.buttons["readingStop"].isEnabled)
        photo("Native Reading wrapped sentence playing",app)
        atLine(passage,y:36).tap()
        XCTAssertEqual(passage.value as? String,second,"Touching the space between lines leaves the active sentence alone.")

        tap("readingTranslate",app)
        let firstTranslation=app.staticTexts["readingTranslation-0"]
        XCTAssertTrue(firstTranslation.waitForExistence(timeout:12))
        XCTAssertEqual(firstTranslation.label,"My green notebook is near the window.")
        let first=app.buttons["readingSentence-0"]
        for _ in 0..<8 where !first.isHittable {app.swipeDown(velocity:.slow)}
        XCTAssertTrue(first.isHittable)
        first.tap()
        XCTAssertTrue(first.isSelected)
        photo("Native Reading translated sentence playing",app)
    }

    func testDraftPlaybackStopsOnNewContentAndExplicitRetryRestoresReview() {
        let app=start(["PIYALI_READING_INTERRUPTED_DRAFT_FIXTURE":"1"])
        let draft=app.descendants(matching:.any)["readingDraftPassage"]
        let first="Mi libreta verde está cerca de la ventana."
        let next="En la página izquierda dibujo una planta."
        XCTAssertTrue(draft.waitForExistence(timeout:10))
        XCTAssertEqual(draft.label,first)
        XCTAssertFalse(app.buttons["readingListen"].isEnabled)
        XCTAssertFalse(app.buttons["readingCheck"].exists)

        let sentence=atLine(draft)
        sentence.tap()
        XCTAssertEqual(draft.value as? String,first)
        XCTAssertFalse(app.buttons["readingStop"].isEnabled)
        photo("Native Reading draft while playing the first sentence",app)

        let updated=XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@",next),object:draft)
        XCTAssertEqual(XCTWaiter.wait(for:[updated],timeout:12),.completed)
        XCTAssertNotEqual(draft.value as? String,first)
        XCTAssertFalse(app.buttons["readingListen"].isEnabled)
        photo("Native Reading draft after the next sentence arrived",app)

        sentence.tap()
        XCTAssertEqual(draft.value as? String,first)
        let replaced=XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:draft)
        replaced.isInverted=true
        XCTAssertEqual(XCTWaiter.wait(for:[replaced],timeout:7),.completed)
        XCTAssertEqual(draft.value as? String,first)
        photo("Native Reading draft held during fallback",app)

        let retry=app.buttons["readingRetry"]
        XCTAssertTrue(retry.waitForExistence(timeout:14))
        XCTAssertFalse(draft.exists)
        XCTAssertFalse(app.buttons["readingCheck"].exists)
        let xp=app.descendants(matching:.any).matching(identifier:"dailyXPStatus").firstMatch
        XCTAssertEqual(xp.value as? String,"0%")
        photo("Native Reading after the fallback failure",app)

        tap("readingRetry",app)
        let saved=app.descendants(matching:.any)["readingPassage"]
        XCTAssertTrue(saved.waitForExistence(timeout:12))
        XCTAssertNotEqual(saved.value as? String,first)
        XCTAssertFalse(retry.exists)
        tap("readingOption-0",app)
        tap("readingCheck",app)
        let completed=app.staticTexts["readingCompleted"]
        XCTAssertTrue(completed.waitForExistence(timeout:10))
        let reward=xp.value as? String
        XCTAssertTrue(["5%","6%","7%","8%"].contains(reward ?? ""))
        app.terminate()
        app.launch()
        openReading(app)
        XCTAssertTrue(completed.waitForExistence(timeout:10))
        XCTAssertEqual(xp.value as? String,reward)
    }
    func testDraftSentencePlaybackAndValidatedReview() {
        let app=start(["PIYALI_READING_STREAM_FIXTURE":"1","PIYALI_READING_LOADING_FIXTURE":"1","PIYALI_READING_TRANSLATION_STREAM_FIXTURE":"1"])
        let loading=app.descendants(matching:.any)["readingPassageLoading"]
        XCTAssertTrue(loading.waitForExistence(timeout:8))
        XCTAssertTrue(loading.label.contains("Creating lecture"))
        XCTAssertEqual(loading.frame.width,app.frame.width-42,accuracy:1)
        XCTAssertGreaterThan(loading.frame.height,340)
        XCTAssertFalse(app.buttons["readingListen"].exists)
        XCTAssertFalse(app.buttons["readingWaiting"].isEnabled)
        photo("Reading passage skeleton",app)
        XCTAssertTrue(app.staticTexts["readingDraftTitle"].waitForExistence(timeout:15))
        XCTAssertFalse(loading.exists)
        XCUIDevice.shared.press(.home);app.activate();XCTAssertTrue(app.staticTexts["readingDraftTitle"].waitForExistence(timeout:15))
        XCTAssertFalse(app.buttons["readingListen"].isEnabled);XCTAssertFalse(app.buttons["readingCheck"].exists);XCTAssertFalse(app.staticTexts["readingCompleted"].exists)
        let draft=app.descendants(matching:.any)["readingDraftPassage"];XCTAssertTrue(draft.waitForExistence(timeout:15));photo("Reading incremental draft",app);atLine(draft).tap()
        XCTAssertEqual(draft.value as? String,"Mi libreta verde está cerca de la ventana.");XCTAssertFalse(app.buttons["readingStop"].isEnabled)
        XCTAssertTrue(app.descendants(matching:.any)["readingPassage"].waitForExistence(timeout:20))
        XCTAssertFalse(app.staticTexts["readingDraftTitle"].exists);XCTAssertTrue(app.buttons["readingCheck"].exists);XCTAssertFalse(app.staticTexts["readingCompleted"].exists)
        tap("readingListen",app)
        XCTAssertTrue(app.buttons["readingStop"].isEnabled)
        tap("readingStop",app)
        XCTAssertFalse(app.buttons["readingStop"].isEnabled)
        tap("readingTranslate",app);let line=app.staticTexts["readingTranslation-0"];XCTAssertTrue(line.waitForExistence(timeout:10));XCTAssertEqual(line.label,"My green notebook is near the window.");XCTAssertFalse(app.buttons["readingTranslate"].isEnabled)
        let later=app.staticTexts["readingTranslation-1"];XCTAssertTrue(later.waitForExistence(timeout:10))
        photo("Validated Reading after incremental draft",app)
    }
}
