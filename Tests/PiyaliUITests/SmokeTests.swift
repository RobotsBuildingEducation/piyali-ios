import XCTest
final class SmokeTests: XCTestCase {
    func testCreateAccountAndOfflinePractice() {
        let app = XCUIApplication(); app.launch()
        if app.buttons["createAccount"].waitForExistence(timeout: 5) { app.buttons["createAccount"].tap() }
        if app.buttons["startLearning"].waitForExistence(timeout: 10) { app.buttons["startLearning"].tap() }
        XCTAssertTrue(app.tabBars.buttons["Practice"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Practice"].tap()
        let flashcards = app.buttons.matching(NSPredicate(format:"label BEGINSWITH 'Flashcards ('")).firstMatch
        XCTAssertTrue(flashcards.waitForExistence(timeout: 10)); flashcards.tap()
        XCTAssertTrue(app.buttons["nextFlashcard"].waitForExistence(timeout: 5)); app.buttons["nextFlashcard"].tap()
        app.navigationBars.buttons.element(boundBy:0).tap()
        app.tabBars.buttons["Notes"].tap()
        XCTAssertTrue(app.textFields["Title"].waitForExistence(timeout:5))
        let noteTitle = "Practice " + UUID().uuidString.prefix(8)
        app.textFields["Title"].tap(); app.textFields["Title"].typeText(String(noteTitle))
        let body = app.textFields["What do you want to remember?"]
        body.tap(); body.typeText("Hola means hello")
        app.buttons["Save note"].tap()
        XCTAssertTrue(app.buttons[String(noteTitle)].waitForExistence(timeout:5))
        app.terminate(); app.launch()
        XCTAssertTrue(app.tabBars.buttons["Notes"].waitForExistence(timeout:10)); app.tabBars.buttons["Notes"].tap()
        XCTAssertTrue(app.buttons[String(noteTitle)].waitForExistence(timeout:5))
        app.tabBars.buttons["Tutor"].tap()
        XCTAssertTrue(app.staticTexts["Unlock Piyali"].waitForExistence(timeout:5))
    }
}
