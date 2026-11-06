import XCTest

@MainActor final class CalendarJourneyTests:XCTestCase {
    private func element(_ id:String,_ app:XCUIApplication)->XCUIElement{app.descendants(matching:.any).matching(identifier:id).firstMatch}
    private func reveal(_ item:XCUIElement,_ app:XCUIApplication){for _ in 0..<8 where !item.isHittable{app.swipeUp(velocity:.slow)};XCTAssertTrue(item.isHittable)}
    private func tap(_ id:String,_ app:XCUIApplication){let item=element(id,app);XCTAssertTrue(item.waitForExistence(timeout:15),id);reveal(item,app);item.tap()}
    private func photo(_ name:String,_ app:XCUIApplication){let shot=XCTAttachment(screenshot:app.screenshot());shot.name=name;shot.lifetime = .keepAlways;add(shot)}
    func testOnboardingActivityAndRelaunchWithBuddhistAndIslamicSystemCalendars(){
        continueAfterFailure=false;var requests:[[String:String]]=[]
        for (expected,locale,language) in [("buddhist","th_TH@calendar=buddhist","en"),("islamic-umalqura","ar_SA@calendar=islamic-umalqura","ar")]{
            let scope=UUID().uuidString,app=XCUIApplication();requests.append(["scope":scope,"expectedCalendar":expected]);app.launchEnvironment=["PIYALI_OFFLINE_TESTS":"1","PIYALI_TEST_IDENTITY_SCOPE":scope,"PIYALI_ENTRY_INITIAL_LANGUAGE":language,"PIYALI_ENTRY_INITIAL_THEME":language=="ar" ? "dark":"light","PIYALI_XP_ACTIVITY_FIXTURE":"history","PIYALI_HEADLINE_FIXTURE":"failure","PIYALI_CALENDAR_PROBE":"1"];app.launchArguments=["-AppleLanguages","(en)","-AppleLocale",locale];app.launch();handleInitialPaperPencil(app)
            let name=app.textFields["entryName"];XCTAssertTrue(name.waitForExistence(timeout:15));name.tap();name.typeText("Calendar Learner");tap("entryKeyboardDone",app);tap("createAccount",app);handleInitialPaperPencil(app);tap("startLearning",app);tap("companionContinue",app);acknowledgePaperPencil(app);tap("gettingStartedGotIt",app);tap("placementNew",app);tap("focusActivityOpen",app)
            let year=Calendar(identifier:.gregorian).component(.year,from:Date()),first=element("activityDay-\(year)-01-01",app),partial=element("activityDay-\(year)-01-02",app),goal=element("activityDay-\(year)-01-03",app)
            XCTAssertTrue(first.waitForExistence(timeout:8));XCTAssertTrue(first.label.contains("250 XP"));XCTAssertTrue(partial.label.contains("15 XP"));XCTAssertEqual(first.value as?String,goal.value as?String);XCTAssertNotEqual(first.value as?String,partial.value as?String);XCTAssertEqual(element("dailyXPStatus",app).value as?String,"0%");photo("Native canonical Activity under "+expected,app)
            tap("activityCompanion",app);app.terminate();app.launch();handleInitialPaperPencil(app);XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15));tap("focusActivityOpen",app);XCTAssertTrue(first.label.contains("250 XP"));XCTAssertEqual(element("dailyXPStatus",app).value as?String,"0%");photo("Native calendar Activity after relaunch "+expected,app);app.terminate()
            app.launchArguments=["-AppleLanguages","(en)","-AppleLocale","en_US@calendar=gregorian"];requests.append(["scope":scope,"expectedCalendar":"gregorian"]);app.launch();handleInitialPaperPencil(app);XCTAssertTrue(app.staticTexts["todayFocusTitle"].waitForExistence(timeout:15));tap("focusActivityOpen",app);XCTAssertTrue(first.label.contains("250 XP"));XCTAssertEqual(element("dailyXPStatus",app).value as?String,"0%");photo("Native Activity retained after calendar switch from "+expected,app);app.terminate()

        }
        let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:requests,options:.sortedKeys),uniformTypeIdentifier:"public.json");a.name="Calendar probe scopes";a.lifetime = .keepAlways;add(a)
    }
}
