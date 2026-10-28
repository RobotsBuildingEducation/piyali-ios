import XCTest

@MainActor func acknowledgePaperPencil(_ app:XCUIApplication,file:StaticString=#filePath,line:UInt=#line){
    let button=app.buttons["paperPencilUnderstood"]
    XCTAssertTrue(button.waitForExistence(timeout:10),"New accounts see the authored paper-and-pencil suggestion first.",file:file,line:line)
    for _ in 0..<8 where !button.isHittable{app.scrollViews["paperPencilScroll"].swipeUp(velocity:.slow)}
    XCTAssertTrue(button.isHittable,file:file,line:line);button.tap()
    XCTAssertTrue(app.staticTexts["gettingStartedTitle"].waitForExistence(timeout:8),file:file,line:line)
}
