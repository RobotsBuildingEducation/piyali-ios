import XCTest

@MainActor final class GameHandoffJourneyTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication){let b=app.buttons[id];XCTAssertTrue(b.waitForExistence(timeout:15),id);for _ in 0..<10 where !b.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(b.isHittable,id);b.tap()}
    private func shot(_ name:String,_ app:XCUIApplication){let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    private func launch(_ support:String="en",prepared:String="prepared",failLibraryLoad:Bool=false,legacyTutorial:Bool=false,legacyDialogue:Bool=false,legacyRecovery:Bool=false)->XCUIApplication{
        let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_TUTOR_FIXTURE":"1","PIYALI_PRACTICE_FIXTURE":"delight:natural_or_weird","PIYALI_HEADLINE_FIXTURE":"failure","PIYALI_RPG_PREPARED_FIXTURE":prepared,"PIYALI_RPG_PREPARED_DELAY_MS":"10000","PIYALI_GAME_LOADER_SEED":"7","PIYALI_ENTRY_INITIAL_LANGUAGE":support,"PIYALI_ENTRY_INITIAL_THEME":support=="ar" ? "dark":"light"]
        if failLibraryLoad { app.launchEnvironment["PIYALI_RPG_FAIL_FIRST_LIBRARY_LOAD"]="1" }
        if legacyTutorial { app.launchEnvironment["PIYALI_LEGACY_TUTORIAL_FIXTURE"]="1" }
        if legacyRecovery { app.launchEnvironment["PIYALI_LEGACY_TUTORIAL_RECOVERY"]="1" }
        if legacyDialogue {
            app.launchEnvironment["PIYALI_LEGACY_TUTORIAL_DIALOGUE"]="1"
            app.launchEnvironment["PIYALI_RPG_TRANSLATION_FIXTURE"]="stream"
        }
        app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US"];app.launch();handleInitialPaperPencil(app);let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Handoff Learner");tap("entryKeyboardDone",app);tap("createAccount",app);handleInitialPaperPencil(app);tap("startLearning",app);tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);tap("placementNew",app);return app
    }
    private func mode(_ mode:String,_ app:XCUIApplication){tap("productMenu",app);tap("productModeMenu",app);tap("productMode-"+mode,app)}
    func testTutorialWarmsDuringEarlierStepsShowsPlayableLoaderAndCanSkip()throws{
        continueAfterFailure=false;let app=launch();mode("path",app);tap("introLink",app);tap("startLessonFromPreview",app);XCTAssertTrue(app.buttons["introStep-vocabulary"].waitForExistence(timeout:10));XCTAssertFalse(app.otherElements["rpgWorld"].exists);XCTAssertFalse(app.otherElements["gamePreparationWorld"].exists)
        for id in ["skipLessonActivity","skipLessonActivity","skipLessonActivity","skipLessonActivity","realtimeSkip"]{tap(id,app)}
        let map=app.otherElements["gamePreparationWorld"];XCTAssertTrue(map.waitForExistence(timeout:8));XCTAssertTrue(app.buttons["introStep-game"].exists);XCTAssertTrue(app.buttons["skipIntroActivity"].isEnabled);XCTAssertFalse(app.buttons["cancelGamePreparation"].exists);shot("Native introduction inline playable loader",app);tap("skipIntroActivity",app)
        let bonus=app.staticTexts["lessonCompletionBonus"];XCTAssertTrue(bonus.waitForExistence(timeout:10));XCTAssertEqual(bonus.label,"+50");XCTAssertFalse(app.otherElements["rpgWorld"].exists);shot("Native introduction loader skip completes once",app)
    }
    func testTutorialHardFailureOpensTheLegacyWorldAndResumesBeforeSkip(){
        continueAfterFailure=false
        let app=launch(prepared:"cache-only",failLibraryLoad:true,legacyTutorial:true)
        mode("path",app)
        tap("introLink",app)
        tap("startLessonFromPreview",app)
        for id in ["skipLessonActivity","skipLessonActivity","skipLessonActivity","skipLessonActivity","realtimeSkip"]{tap(id,app)}
        let world=app.otherElements["explorationWorld"]
        XCTAssertTrue(world.waitForExistence(timeout:20))
        XCTAssertEqual(world.value as? String,"tutorialPlaza|3,3")
        XCTAssertTrue(app.buttons["introStep-game"].exists)
        XCTAssertFalse(app.buttons["explorationGenerate"].exists)
        XCTAssertFalse(app.staticTexts["lessonCompletionBonus"].exists)
        world.coordinate(withNormalizedOffset:CGVector(dx:0.66,dy:0.51)).tap()
        let position=world.value as? String
        XCTAssertNotEqual(position,"tutorialPlaza|3,3")
        shot("Native course introduction legacy Greeting Plaza",app)
        awaitLegacyFullScreen(app)
        XCTAssertEqual(world.value as? String,position)
        shot("Native legacy fullscreen preserves the player position",app)
        app.terminate()
        app.launch()
        handleInitialPaperPencil(app)
        mode("path",app)
        tap("introLink",app)
        tap("startLessonFromPreview",app)
        XCTAssertTrue(world.waitForExistence(timeout:15))
        XCTAssertEqual(world.value as? String,position)
        tap("skipIntroActivity",app)
        let bonus=app.staticTexts["lessonCompletionBonus"]
        XCTAssertTrue(bonus.waitForExistence(timeout:10))
        XCTAssertEqual(bonus.label,"+50")
        XCTAssertFalse(world.exists)
        shot("Native legacy game Skip reaches the introduction bonus",app)
    }
    func testLegacyTutorialRejectsUnplayableMapAndRetriesThroughProviderOutage() {
        continueAfterFailure=false
        let app=launch(prepared:"cache-only",failLibraryLoad:true,legacyTutorial:true,legacyRecovery:true)
        mode("path",app)
        tap("introLink",app)
        tap("startLessonFromPreview",app)
        for id in ["skipLessonActivity","skipLessonActivity","skipLessonActivity","skipLessonActivity","realtimeSkip"]{tap(id,app)}

        let retry=app.buttons["retryIntroLegacyGame"],error=app.staticTexts["introLegacyGameError"]
        let world=app.otherElements["explorationWorld"],bonus=app.staticTexts["lessonCompletionBonus"]
        XCTAssertTrue(retry.waitForExistence(timeout:20))
        XCTAssertEqual(retry.label,"Try again")
        XCTAssertEqual(error.label,"The game could not start. Please try again.")
        XCTAssertTrue(app.otherElements["gamePreparationWorld"].exists)
        XCTAssertEqual(app.buttons["introStep-game"].value as? String,"Current")
        XCTAssertEqual(app.buttons["introStep-vocabulary"].value as? String,"Completed")
        XCTAssertTrue(app.buttons["skipIntroActivity"].isHittable)
        XCTAssertTrue(retry.isHittable)
        XCTAssertFalse(world.exists)
        XCTAssertFalse(bonus.exists)
        shot("Native legacy game rejected map and Retry",app)

        retry.tap()
        XCTAssertTrue(world.waitForExistence(timeout:15))
        XCTAssertEqual(world.value as? String,"tutorialPlaza|3,3")
        XCTAssertFalse(error.exists)
        XCTAssertFalse(retry.exists)
        XCTAssertFalse(bonus.exists)
        awaitLegacyFullScreen(app)
        XCTAssertEqual(world.value as? String,"tutorialPlaza|3,3")
        shot("Native Greeting Plaza after both providers fail",app)
        tap("skipIntroActivity",app)
        XCTAssertTrue(bonus.waitForExistence(timeout:10))
        XCTAssertEqual(bonus.label,"+50")
    }
    func testLegacyTutorialChoicesAndChapterDialogueLeadToEarnedCompletion()throws {
        continueAfterFailure=false
        let app=launch(prepared:"cache-only",failLibraryLoad:true,legacyTutorial:true,legacyDialogue:true)
        mode("path",app)
        tap("introLink",app)
        tap("startLessonFromPreview",app)
        for id in ["skipLessonActivity","skipLessonActivity","skipLessonActivity","skipLessonActivity","realtimeSkip"]{tap(id,app)}
        XCTAssertTrue(app.otherElements["explorationWorld"].waitForExistence(timeout:15))
        awaitLegacyFullScreen(app)

        var tiles=(0..<14).flatMap { y in (0..<18).map { x in x == 0 || x == 17 || y == 0 || y == 13 ? 2 : 0 } }
        tiles[3*18+5]=3
        tiles[4*18+2]=4
        tiles[2*18+4]=6
        let world=app.otherElements["explorationWorld"]
        shot("Native generated Greeting Plaza artwork",app)
        world.coordinate(withNormalizedOffset:.zero)
            .withOffset(CGVector(dx:world.frame.width/2+world.frame.height/10,dy:world.frame.height*0.512)).tap()
        XCTAssertEqual(world.value as? String,"tutorialPlaza|4,3")
        world.coordinate(withNormalizedOffset:.zero)
            .withOffset(CGVector(dx:world.frame.width/2+world.frame.height/10,dy:world.frame.height*0.512)).tap()
        XCTAssertEqual(world.value as? String,"tutorialPlaza|4,3","The generated tree uses the source solid tile")
        let choice=RPGPlayFixture.Step(npc:1,mode:"choice",correct:0,example:""),speech=RPGPlayFixture.Step(npc:0,mode:"speech",correct:0,example:"Me llamo Sol.")
        let fixture=RPGPlayFixture(lessonID:"lesson-tutorial-1",world:.init(width:18,height:14,tiles:tiles,solidTiles:[2,3,4,6],objects:[]),
                                   npcs:[.init(x:4,y:4),.init(x:8,y:6)],steps:[choice,speech])
        try rpgApproach(choice,fixture,app,worldID:"explorationWorld",closeID:"explorationCloseDialogue")
        let originalChoice=app.buttons["explorationChoice-0"]
        XCTAssertTrue(app.staticTexts["explorationChoicesThinking"].waitForExistence(timeout:3))
        XCTAssertFalse(originalChoice.exists)
        shot("Native legacy choices pending",app)
        XCTAssertTrue(originalChoice.waitForExistence(timeout:6))
        XCTAssertNotEqual(originalChoice.label,"A. Hola, quiero presentarme.")
        shot("Native legacy choices use the existing quest after malformed output",app)

        let close=app.buttons["explorationCloseDialogue"]
        tap("explorationCloseDialogue",app)
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:close)],timeout:4),.completed)
        try rpgApproach(choice,fixture,app,worldID:"explorationWorld",closeID:"explorationCloseDialogue")
        let newOption=XCTNSPredicateExpectation(predicate:NSPredicate(format:"label == %@","A. Hola, quiero presentarme."),object:originalChoice)
        XCTAssertEqual(XCTWaiter.wait(for:[newOption],timeout:6),.completed)
        XCTAssertEqual(app.buttons["explorationChoice-2"].label,"C. Buenas tardes.")
        shot("Native legacy generated choices",app)
        tap("explorationTranslation",app)
        let firstLine=app.staticTexts["explorationLineTranslation-0"]
        XCTAssertTrue(firstLine.waitForExistence(timeout:3))
        XCTAssertEqual(firstLine.label,"I'm happy to see you here.")
        XCTAssertFalse(originalChoice.label.contains("introduce myself"))
        let translatedOption=XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Hello, I want to introduce myself."),object:originalChoice)
        XCTAssertEqual(XCTWaiter.wait(for:[translatedOption],timeout:10),.completed)
        XCTAssertTrue(app.buttons["explorationChoice-2"].label.contains("Good afternoon."))
        shot("Native translated generated choices",app)
        tap("explorationTranslation",app)
        XCTAssertEqual(originalChoice.label,"A. Hola, quiero presentarme.")
        XCTAssertFalse(firstLine.exists)
        tap("explorationChoice-0",app)
        XCTAssertTrue(app.staticTexts["explorationSceneLine"].waitForExistence(timeout:5))
        XCTAssertEqual(app.staticTexts["explorationSceneLine"].label,"Sonríe.")
        XCTAssertTrue(app.staticTexts["explorationNode"].label.contains("Claro, adelante."))
        tap("explorationContinue",app)

        try rpgApproach(speech,fixture,app,worldID:"explorationWorld",closeID:"explorationCloseDialogue")
        let bridge=app.staticTexts["explorationPlayerBridge"]
        XCTAssertTrue(bridge.waitForExistence(timeout:5))
        XCTAssertEqual(bridge.label,"Vengo a practicar mi presentación.")
        XCTAssertEqual(app.staticTexts["explorationNode"].label,"¡Bienvenida! Dime cómo te llamas.")
        XCTAssertFalse(app.staticTexts["lessonCompletionBonus"].exists)
        shot("Native legacy chapter bridge and greeting",app)
        let mic=app.buttons["explorationMicrophone"]
        XCTAssertTrue(mic.waitForExistence(timeout:5))
        XCTAssertTrue(mic.isHittable)
        mic.press(forDuration:1)
        tap("Response",app)
        let answer=app.descendants(matching:.any)["explorationAnswer"]
        XCTAssertTrue(answer.waitForExistence(timeout:5))
        answer.tap()
        answer.typeText(speech.example)
        tap("explorationSpeechSubmit",app)
        let continueButton=app.buttons["explorationContinue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout:8))
        XCTAssertTrue(app.staticTexts["explorationNode"].label.contains("Mucho gusto, Sol. Me alegra conocerte."))
        shot("Native legacy in-character reply",app)
        tap("explorationContinue",app)
        let bonus=app.staticTexts["lessonCompletionBonus"]
        XCTAssertTrue(bonus.waitForExistence(timeout:10))
        XCTAssertEqual(bonus.label,"+50")
        XCTAssertFalse(app.otherElements["explorationWorld"].exists)
        shot("Native legacy quest earns the introduction bonus",app)
    }
    private func awaitLegacyFullScreen(_ app:XCUIApplication) {
        let stepper=app.buttons["introStep-game"]
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:stepper)],timeout:12),.completed)
        let world=app.otherElements["explorationWorld"]
        XCTAssertTrue(world.waitForExistence(timeout:5))
        XCTAssertGreaterThan(world.frame.height,app.frame.height*0.85,"The world should occupy the fullscreen viewport")
    }
    func testTutorStopsVoiceCanCancelThenRetryHandoffAndResume()throws{
        continueAfterFailure=false;let app=launch("ar");mode("tutor",app);tap("tutorStart",app);XCTAssertTrue(app.buttons["tutorMute"].waitForExistence(timeout:10));tap("tutorLessons",app);tap("tutorNode-lesson-tutorial-1",app);tap("tutorPreviewStart",app)
        let map=app.otherElements["gamePreparationWorld"];XCTAssertTrue(map.waitForExistence(timeout:8));let before=map.value as?String;map.swipeLeft(velocity:.slow);XCTAssertNotEqual(map.value as?String,before);shot("Native Tutor preview playable preparation Arabic",app);tap("cancelGamePreparation",app);XCTAssertTrue(app.buttons["tutorPathClose"].waitForExistence(timeout:8));XCTAssertFalse(app.otherElements["rpgWorld"].exists);tap("tutorPathClose",app);XCTAssertTrue(app.buttons["tutorStart"].waitForExistence(timeout:8));XCTAssertFalse(app.buttons["tutorMute"].exists)
        tap("tutorLessons",app);tap("tutorNode-lesson-tutorial-1",app);tap("tutorPreviewStart",app);XCTAssertTrue(map.waitForExistence(timeout:8));XCTAssertTrue(app.otherElements["rpgWorld"].waitForExistence(timeout:30));XCTAssertFalse(app.buttons["tutorMute"].exists);XCTAssertFalse(app.buttons["tutorCompletionContinue"].exists);shot("Native Tutor game handoff",app);tap("rpgBack",app);XCTAssertTrue(app.buttons["tutorPathClose"].waitForExistence(timeout:8));tap("tutorNode-lesson-tutorial-1",app);tap("tutorPreviewStart",app);XCTAssertTrue(app.otherElements["rpgWorld"].waitForExistence(timeout:20));shot("Native Tutor saved game resumes after preparation",app);tap("rpgBack",app)
    }
    func testTutorLibraryFailureKeepsThePreviewAndCanStartTheSameGameAgain(){
        continueAfterFailure=false
        let app=launch("ar",prepared:"cache-only",failLibraryLoad:true)
        mode("tutor",app);tap("tutorStart",app)
        XCTAssertTrue(app.buttons["tutorMute"].waitForExistence(timeout:10))
        tap("tutorLessons",app);tap("tutorNode-lesson-tutorial-1",app);tap("tutorPreviewStart",app)
        let error=app.staticTexts["tutorPreviewGameError"]
        XCTAssertTrue(error.waitForExistence(timeout:15))
        XCTAssertEqual(error.label,"ما قدرنا نبدأ اللعبة. جرّب مرة ثانية.")
        XCTAssertTrue(app.buttons["tutorPreviewStart"].isEnabled)
        XCTAssertFalse(app.otherElements["rpgWorld"].exists)
        XCTAssertFalse(app.buttons["tutorCompletionContinue"].exists)
        shot("Native Tutor hard preparation failure returns to the original preview",app)
        tap("tutorPreviewStart",app)
        XCTAssertTrue(app.otherElements["rpgWorld"].waitForExistence(timeout:30))
        XCTAssertFalse(error.exists)
        XCTAssertFalse(app.buttons["tutorMute"].exists)
        XCTAssertFalse(app.buttons["tutorCompletionContinue"].exists)
        let status=app.descendants(matching:.any)["rpgStatus"]
        XCTAssertTrue(status.label.contains("0/7"))
        shot("Native Tutor game starts from the unchanged preview after retry",app)
        tap("rpgBack",app)
        XCTAssertTrue(app.buttons["tutorPathClose"].waitForExistence(timeout:10))
    }
    func testTutorAuthoredGameCompletesThroughItsOwnBonusWithoutLessonCredit()throws{
        continueAfterFailure=false;let fixture=try JSONDecoder().decode(RPGPlayFixture.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"intro-play",withExtension:"json")))),app=launch(prepared:"cache-only");tap("openDailyGoal",app);let goal=app.textFields["dailyGoalDraft"];XCTAssertTrue(goal.waitForExistence(timeout:5));goal.tap();let old=goal.value as?String ?? "";goal.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:old.count)+"50");tap("dailyGoalSave",app);mode("tutor",app);tap("tutorLessons",app);tap("tutorNode-lesson-tutorial-1",app);tap("tutorPreviewStart",app);XCTAssertTrue(app.otherElements["gamePreparationWorld"].waitForExistence(timeout:8));XCTAssertTrue(app.otherElements["rpgWorld"].waitForExistence(timeout:20));XCTAssertFalse(app.buttons["tutorMute"].exists)
        for step in fixture.steps{try rpgApproach(step,fixture,app);if step.mode=="choice"{tap("rpgChoice-\(step.correct)",app)}else{app.buttons["rpgMicrophone"].press(forDuration:1);app.buttons["Response"].tap();let field=app.descendants(matching:.any)["rpgReply"];XCTAssertTrue(field.waitForExistence(timeout:5));field.tap();field.typeText(step.example+"\n");XCTAssertTrue(app.buttons["rpgContinue"].waitForExistence(timeout:10))};tap("rpgContinue",app)}
        XCTAssertTrue(app.buttons["tutorGameComplete"].waitForExistence(timeout:10));shot("Native Tutor game completed recap",app);tap("tutorGameComplete",app);XCTAssertTrue(app.buttons["tutorCompletionContinue"].waitForExistence(timeout:15));XCTAssertEqual(app.staticTexts["tutorCompletionXP"].label,"50");XCTAssertFalse(app.staticTexts["lessonCompletionBonus"].exists);shot("Native Tutor game own completion bonus",app)
        XCTAssertFalse(app.buttons["dailyGoalRewardContinue"].exists);tap("tutorCompletionContinue",app);XCTAssertTrue(app.buttons["tutorReviewContinue"].waitForExistence(timeout:10));XCTAssertFalse(app.buttons["dailyGoalRewardContinue"].exists);shot("Native Tutor game review above returned path",app);tap("tutorReviewContinue",app);XCTAssertTrue(app.buttons["dailyGoalRewardContinue"].waitForExistence(timeout:10));shot("Native Tutor game daily goal after review",app);tap("dailyGoalRewardContinue",app);XCTAssertFalse(app.buttons["scholarshipLater"].exists);XCTAssertFalse(app.buttons["guidedContinue"].exists);XCTAssertTrue(app.buttons["tutorPathClose"].isHittable);shot("Native Tutor returned path holds quiet-window rewards",app);tap("tutorPathClose",app);XCTAssertTrue(app.buttons["scholarshipLater"].waitForExistence(timeout:10));shot("Native Tutor scholarship after closing returned path",app);tap("scholarshipLater",app);XCTAssertTrue(app.buttons["guidedContinue"].waitForExistence(timeout:10));shot("Native Tutor task acknowledgment after path closes",app);tap("guidedContinue",app);XCTAssertTrue(app.buttons["tutorLessons"].waitForExistence(timeout:10));tap("tutorLessons",app);XCTAssertTrue(app.buttons["tutorPathClose"].waitForExistence(timeout:10));XCTAssertEqual(app.buttons["tutorNode-lesson-tutorial-1"].value as?String,"completed");shot("Native Tutor returned path after completion sequence",app);tap("tutorNode-lesson-tutorial-1",app);tap("tutorPreviewStart",app);XCTAssertTrue(app.otherElements["rpgWorld"].waitForExistence(timeout:20));let status=app.descendants(matching:.any)["rpgStatus"];XCTAssertTrue(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","0/7"),object:status)],timeout:10) == .completed);XCTAssertFalse(app.buttons["tutorCompletionContinue"].exists);tap("rpgBack",app);tap("tutorPathClose",app);app.terminate();app.launch();handleInitialPaperPencil(app);mode("tutor",app);XCTAssertTrue(app.buttons["tutorLessons"].waitForExistence(timeout:15));tap("tutorLessons",app);XCTAssertEqual(app.buttons["tutorNode-lesson-tutorial-1"].value as?String,"completed");XCTAssertFalse(app.buttons["tutorCompletionContinue"].exists);shot("Native completed Tutor path survives relaunch",app)
    }

}
