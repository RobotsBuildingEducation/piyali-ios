import XCTest

@MainActor func acknowledgePaperPencil(_ app:XCUIApplication,file:StaticString=#filePath,line:UInt=#line){
    let button=app.buttons["paperPencilUnderstood"]
    XCTAssertTrue(button.waitForExistence(timeout:10),"New accounts see the authored paper-and-pencil suggestion first.",file:file,line:line)
    for _ in 0..<8 where !button.isHittable{app.scrollViews["paperPencilScroll"].swipeUp(velocity:.slow)}
    XCTAssertTrue(button.isHittable,file:file,line:line);button.tap()
    XCTAssertTrue(app.staticTexts["gettingStartedTitle"].waitForExistence(timeout:8),file:file,line:line)
}

/// Follow the current App's initial modal through actual controls. Feature
/// journeys use this after launch/signup; dedicated entry tests inspect it first.
@MainActor func handleInitialPaperPencil(_ app:XCUIApplication,file:StaticString=#filePath,line:UInt=#line){
    let title=app.staticTexts["paperPencilTitle"]
    if !title.exists,app.textFields["entryName"].waitForExistence(timeout:1){return}
    guard title.waitForExistence(timeout:8)else{return}
    let button=app.buttons["paperPencilUnderstood"]
    for _ in 0..<8 where !button.isHittable{app.scrollViews["paperPencilScroll"].swipeUp(velocity:.slow)}
    XCTAssertTrue(button.isHittable,file:file,line:line);button.tap()
    // Onboarding close is session-only. The product branch acknowledges and
    // advances to the original install/key guidance and placement gate.
    if app.staticTexts["gettingStartedTitle"].waitForExistence(timeout:0.8){
        let done=app.buttons["gettingStartedGotIt"]
        for _ in 0..<8 where !done.isHittable{app.swipeUp(velocity:.slow)}
        XCTAssertTrue(done.isHittable,file:file,line:line);done.tap()
    }
    if app.buttons["placementClose"].waitForExistence(timeout:0.8){app.buttons["placementClose"].tap()}
}
