import XCTest

@MainActor final class ExplorationPlayTests:XCTestCase {
    private struct Fixture:Decodable {
        struct Area:Decodable { let id:String;let portals:[String] }
        struct Node:Decodable { let id:String;let mode:String;let line:String;let item:String }
        struct Step:Decodable { let mapID:String;let nodes:[Node] }
        struct Item:Decodable { let mapID:String;let name:String }
        struct Search:Decodable { let stepIndex:Int;let mapID:String;let index:Int }
        let level:String;let maps:[Area];let steps:[Step];let placements:[Item];let search:Search
    }
    private func fixture() throws -> Fixture { try JSONDecoder().decode(Fixture.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"exploration-play",withExtension:"json")))) }
    private func reveal(_ element:XCUIElement,in app:XCUIApplication) {
        _=element.waitForExistence(timeout:2)
        for attempt in 0..<22 {
            let top=app.navigationBars.firstMatch.frame.maxY+12,bottom=app.tabBars.firstMatch.frame.minY-20
            if element.exists {
                let center=element.frame.midY
                if element.isHittable,center > top,center < bottom { return }
                if center <= top { app.swipeDown(velocity:.slow) } else { app.swipeUp(velocity:.slow) }
            } else if attempt < 11 { app.swipeUp(velocity:.slow) } else { app.swipeDown(velocity:.slow) }
        }
        let screenshot=XCTAttachment(screenshot:app.screenshot());screenshot.name="Exploration missing control";screenshot.lifetime = .keepAlways;add(screenshot)
        XCTAssertTrue(element.waitForExistence(timeout:10));XCTAssertTrue(element.isHittable)
    }
    private func tap(_ id:String,in app:XCUIApplication) { let button=app.buttons[id];reveal(button,in:app);XCTAssertTrue(button.isEnabled);button.tap() }
    private func open(_ app:XCUIApplication) { app.tabBars.buttons["Practice"].tap();tap("adventureLink",in:app);tap("explorationLink",in:app);XCTAssertTrue(app.navigationBars["Exploration"].waitForExistence(timeout:10)) }
    private func start(_ fixture:Fixture,objectSearch:Bool = false) -> XCUIApplication {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launchEnvironment["PIYALI_EXPLORATION_TEST_FIXTURE"]="1";app.launch();handleInitialPaperPencil(app)
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:10));app.buttons["createAccount"].tap();handleInitialPaperPencil(app);let picker=app.buttons["onboardingLevelPicker"];XCTAssertTrue(picker.waitForExistence(timeout:15));picker.tap();XCTAssertTrue(app.buttons[fixture.level].waitForExistence(timeout:5));app.buttons[fixture.level].tap();app.buttons["startLearning"].tap();open(app)
        if objectSearch { let toggle=app.switches["explorationObjectSearch"];reveal(toggle,in:app);toggle.coordinate(withNormalizedOffset:CGVector(dx:0.92,dy:0.5)).tap();XCTAssertEqual(toggle.value as? String,"1") }
        tap("explorationLocal",in:app);XCTAssertTrue(app.staticTexts["explorationStatus"].waitForExistence(timeout:15));return app
    }
    private func travel(_ destination:String,current:inout String,fixture:Fixture,app:XCUIApplication) throws {
        for _ in 0..<8 where current != destination {
            let area=try XCTUnwrap(fixture.maps.first { $0.id == current }),index=try XCTUnwrap(area.portals.firstIndex(of:destination) ?? area.portals.firstIndex(of:"review-hub"))
            tap("explorationApproachPortal-\(index)",in:app);tap("explorationEnterPortal-\(index)",in:app);current=area.portals[index]
        };XCTAssertEqual(current,destination)
    }
    private func talk(_ step:Fixture.Step,current:inout String,fixture:Fixture,app:XCUIApplication) throws { try travel(step.mapID,current:&current,fixture:fixture,app:app);tap("explorationApproachNPC",in:app);tap("explorationTalk",in:app) }
    private func ordinary(_ node:Fixture.Node,app:XCUIApplication) {
        let line=app.staticTexts["explorationNode"];reveal(line,in:app)
        if node.mode == "choice" { tap("explorationChoice-0",in:app) }
        else if node.mode == "speech" { let field=app.descendants(matching:.any)["explorationAnswer"];reveal(field,in:app);field.tap();field.typeText("Estoy listo para ayudar.");if app.buttons["Done"].exists { app.buttons["Done"].tap() };tap("explorationSpeechSubmit",in:app) }
        else if node.mode == "none" { tap("explorationContinue",in:app) }
    }
    func testRoomTravelGatheringInventoryRelaunchAndWholeQuestCompletion() throws {
        let fixture=try fixture(),app=start(fixture);var current="review-hub",restarted=false
        for step in fixture.steps {
            try talk(step,current:&current,fixture:fixture,app:app)
            for node in step.nodes {
                if node.mode == "gather" {
                    let index=try XCTUnwrap(fixture.placements.firstIndex { $0.name == node.item }),item=fixture.placements[index]
                    try travel(item.mapID,current:&current,fixture:fixture,app:app);tap("explorationApproachItem-\(index)",in:app);tap("explorationPickUp-\(index)",in:app)
                    let held=app.staticTexts["explorationInventoryItem"];reveal(held,in:app);XCTAssertEqual(held.label,node.item)
                    app.terminate();app.launch();handleInitialPaperPencil(app);open(app);reveal(held,in:app);XCTAssertEqual(held.label,node.item);restarted=true
                    try talk(step,current:&current,fixture:fixture,app:app);tap("explorationHandIn-0",in:app)
                } else { ordinary(node,app:app) }
            }
        }
        XCTAssertTrue(restarted);XCTAssertTrue(app.staticTexts["explorationComplete"].waitForExistence(timeout:15))
        app.terminate();app.launch();handleInitialPaperPencil(app);open(app);XCTAssertTrue(app.staticTexts["explorationComplete"].waitForExistence(timeout:15))
        app.tabBars.buttons["Account"].tap();reveal(app.staticTexts["0 total XP · 0 lessons completed"],in:app)
    }
    func testSearchInsideAnObjectAndReturnTheRequestedItem() throws {
        let fixture=try fixture(),app=start(fixture,objectSearch:true);var current="review-hub"
        for (index,step) in fixture.steps.enumerated() {
            try talk(step,current:&current,fixture:fixture,app:app)
            for node in step.nodes {
                if index == fixture.search.stepIndex,node.mode == "gather" {
                    let active=app.staticTexts["explorationObjectSearchActive"];reveal(active,in:app)
                    try travel(fixture.search.mapID,current:&current,fixture:fixture,app:app);tap("explorationApproachObject-\(fixture.search.index)",in:app);tap("explorationSearchObject-\(fixture.search.index)",in:app)
                    try talk(step,current:&current,fixture:fixture,app:app);tap("explorationHandIn-0",in:app)
                    let status=app.staticTexts["explorationStatus"];reveal(status,in:app);XCTAssertTrue(status.label.contains("Chapter \(index+2) /"));return
                };ordinary(node,app:app)
            }
        };XCTFail("The source fixture did not reach object search")
    }
}
