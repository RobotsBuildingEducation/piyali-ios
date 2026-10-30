import XCTest
import NostrSDK

@MainActor final class RemoteSignerPlayTests:XCTestCase {
    private func reveal(_ element:XCUIElement,in app:XCUIApplication) {
        for _ in 0..<6 where !element.exists || !element.isHittable { app.swipeUp(velocity:.slow) }
        for _ in 0..<6 where !element.exists || !element.isHittable { app.swipeDown(velocity:.slow) }
        XCTAssertTrue(element.waitForExistence(timeout:10));XCTAssertTrue(element.isHittable)
    }
    func testBunkerLoginRestoresUserAccountAndDisconnectRemovesSession() async throws {
        continueAfterFailure=false
        let signer=LocalRemoteSigner(peer:try XCTUnwrap(Keypair()),user:try XCTUnwrap(Keypair()));try await signer.start();defer { signer.stop() }
        let app=XCUIApplication();app.launchEnvironment["PIYALI_OFFLINE_TESTS"]="1";app.launchEnvironment["PIYALI_TEST_IDENTITY_SCOPE"]=UUID().uuidString;app.launch();handleInitialPaperPencil(app)
        let link=app.buttons["remoteSignerLink"];reveal(link,in:app);link.tap()
        let field=app.secureTextFields["bunkerURL"];reveal(field,in:app);field.tap();field.typeText(signer.token)
        let connect=app.buttons["bunkerConnect"];reveal(connect,in:app);connect.tap()
        XCTAssertTrue(app.buttons["startLearning"].waitForExistence(timeout:20));app.buttons["startLearning"].tap()
        app.tabBars.buttons["Account"].tap();let key=app.staticTexts[signer.user.publicKey.npub];reveal(key,in:app)
        XCTAssertFalse(app.buttons["Back up private key"].exists)
        app.terminate();app.launch();handleInitialPaperPencil(app);app.tabBars.buttons["Account"].tap();reveal(key,in:app)
        let disconnect=app.buttons["remoteSignerDisconnect"];reveal(disconnect,in:app);disconnect.tap()
        XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:10))
        app.terminate();app.launch();handleInitialPaperPencil(app);XCTAssertTrue(app.buttons["createAccount"].waitForExistence(timeout:10))
        XCTAssertEqual(signer.methods().filter { $0 == "connect" }.count,1)
    }
}
