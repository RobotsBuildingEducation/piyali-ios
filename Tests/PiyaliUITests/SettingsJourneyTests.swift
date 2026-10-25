import XCTest

@MainActor final class SettingsJourneyTests:XCTestCase {
    private func tap(_ id:String,_ app:XCUIApplication){let button=app.buttons[id];XCTAssertTrue(button.waitForExistence(timeout:15),id);reveal(button,app);button.tap()}
    private func reveal(_ element:XCUIElement,_ app:XCUIApplication){
        let top=element.identifier.hasPrefix("settingsTab-") || element.identifier == "productPanelClose"
        for _ in 0..<9 where !element.isHittable{let from=app.coordinate(withNormalizedOffset:CGVector(dx:0.95,dy:top ? 0.4:0.79)),to=app.coordinate(withNormalizedOffset:CGVector(dx:0.95,dy:top ? 0.79:0.4));from.press(forDuration:0.1,thenDragTo:to,withVelocity:.slow,thenHoldForDuration:0.1)}
        XCTAssertTrue(element.isHittable,element.identifier)
    }
    private func photo(_ title:String,_ app:XCUIApplication){let shot=XCTAttachment(screenshot:app.screenshot());shot.name=title;shot.lifetime = .keepAlways;add(shot)}
    private func open(_ app:XCUIApplication){tap("productMenu",app);tap("productPanel-settings",app);XCTAssertTrue(app.buttons["settingsTab-settings"].waitForExistence(timeout:10))}
    private func launch()->XCUIApplication {
        continueAfterFailure=false;let app=XCUIApplication();app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":UUID().uuidString,"PIYALI_SETTINGS_FIXTURE":"1"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US","-piyali.interfaceLanguage","en"];app.launch()
        let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Settings Learner");tap("entryKeyboardDone",app);tap("createAccount",app);tap("startLearning",app);open(app);return app
    }
    func testPersonaVoiceSoundPostsThemeAndNamePersistThroughRelaunch(){
        let app=launch();XCTAssertTrue(app.buttons["practiceLanguagePicker"].exists);photo("Native Settings drawer initial product",app)
        let persona=app.textViews["settingsPersona"];reveal(persona,app);persona.tap();persona.typeText(" A patient astronomer");tap("settingsKeyboardDone",app);let text=persona.value as? String;XCTAssertTrue(text?.contains("astronomer") == true)
        tap("settingsVoice",app);let cedar=app.buttons["Cedar"].firstMatch;XCTAssertTrue(cedar.waitForExistence(timeout:5));cedar.tap();XCTAssertTrue(app.buttons["settingsVoice"].label.contains("Cedar"))
        let sound=app.switches["settingsSound"];reveal(sound,app);XCTAssertEqual(sound.value as? String,"1");sound.tap();let posts=app.switches["settingsPosts"];reveal(posts,app);XCTAssertEqual(posts.value as? String,"0")
        tap("settingsPostsInfo",app);XCTAssertTrue(app.descendants(matching:.any).matching(identifier:"settingsPostsInfoDialog").firstMatch.waitForExistence(timeout:5));photo("Native Settings decentralized identity explanation",app);XCTAssertFalse(app.buttons["settingsTab-account"].exists && app.buttons["settingsTab-account"].isEnabled);tap("settingsPostsInfoClose",app)
        tap("settingsTheme-dark",app);photo("Native Settings theme controls",app);tap("settingsTab-account",app);tap("settingsNameAccordion",app)
        let name=app.textFields["settingsDisplayName"];name.tap();name.typeText(" Updated");let updatedName=name.value as? String;tap("settingsKeyboardDone",app);tap("settingsNameSave",app);tap("productPanelClose",app);app.terminate();app.launch();open(app)
        reveal(persona,app);XCTAssertEqual(persona.value as? String,text);XCTAssertTrue(app.buttons["settingsVoice"].label.contains("Cedar"));reveal(sound,app);XCTAssertEqual(sound.value as? String,"0");reveal(posts,app);XCTAssertEqual(posts.value as? String,"0");tap("settingsTheme-dark",app);XCTAssertTrue(app.buttons["settingsTheme-dark"].isSelected)
        tap("settingsTab-account",app);tap("settingsNameAccordion",app);XCTAssertEqual(name.value as? String,updatedName);photo("Native Settings account name restored",app)
    }
    func testInvalidSwitchKeepsAccountAndSignOutRequiresConfirmation(){
        let app=launch();tap("settingsTab-account",app);tap("settingsSwitchAccordion",app);let key=app.secureTextFields["settingsSwitchKey"];key.tap();key.typeText("npub1notaprivatekey");tap("settingsKeyboardDone",app);tap("settingsSwitchAccount",app)
        XCTAssertTrue(app.buttons["settingsSwitchAccount"].exists);XCTAssertFalse(app.textFields["entryName"].exists)
        // Dismiss the product error before checking the account drawer.
        if app.alerts.firstMatch.waitForExistence(timeout:2){app.alerts.firstMatch.buttons.firstMatch.tap()}
        app.swipeUp(velocity:.slow);tap("settingsSignOut",app);XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout:5));app.alerts.firstMatch.buttons["Cancel"].tap();XCTAssertTrue(app.buttons["settingsSignOut"].exists)
        tap("settingsSignOut",app);app.alerts.firstMatch.buttons.matching(NSPredicate(format:"label != 'Cancel'")).firstMatch.tap();XCTAssertTrue(app.textFields["entryName"].waitForExistence(timeout:10))
    }
}
