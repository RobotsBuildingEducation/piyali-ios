import XCTest
@testable import Piyali

@MainActor final class SessionTimerControllerTests:XCTestCase {
    func testAccountLocalRestorationAndDurableOnceOnlyCompletionOutbox()throws {
        let suite="SessionTimerTests."+UUID().uuidString,defaults=try XCTUnwrap(UserDefaults(suiteName:suite));defer{defaults.removePersistentDomain(forName:suite)}
        var old=SessionTimer(account:"a");old.start("1",now:Date().addingTimeInterval(-120));let id=try XCTUnwrap(old.id?.uuidString)
        defaults.set(try JSONEncoder().encode(old),forKey:"piyali.sessionTimer.a")
        let controller=SessionTimerController(defaults:defaults);controller.load(account:"a");XCTAssertEqual(controller.session.status,.finished);XCTAssertEqual(controller.pending,[id]);controller.refresh();XCTAssertEqual(controller.pending,[id])
        controller.load(account:"b");XCTAssertEqual(controller.session.status,.idle);XCTAssertTrue(controller.pending.isEmpty)
        controller.start("20");controller.toggle();XCTAssertEqual(controller.session.status,.paused)
        let b=controller.session;controller.load(account:"a");XCTAssertEqual(controller.pending,[id]);controller.acknowledge(id,account:"b");XCTAssertEqual(controller.pending,[id])
        controller.acknowledge(id,account:"a");controller.load(account:"b");XCTAssertEqual(controller.session,b)
        controller.load(account:"a");XCTAssertTrue(controller.pending.isEmpty);controller.clear();XCTAssertEqual(controller.session.status,.idle)
        let restored=SessionTimerController(defaults:defaults);restored.load(account:"a");XCTAssertFalse(restored.session.hasTimer);XCTAssertTrue(restored.pending.isEmpty)
    }
    func testClosingTimerDraftDoesNotRestartAnActiveTimer()throws {
        let suite="SessionTimerTests."+UUID().uuidString,defaults=try XCTUnwrap(UserDefaults(suiteName:suite));defer{defaults.removePersistentDomain(forName:suite)}
        let controller=SessionTimerController(defaults:defaults);controller.load(account:"a");controller.start("10");let id=controller.session.id,end=controller.session.endsAt
        controller.saveDraft("30");XCTAssertEqual(controller.session.id,id);XCTAssertEqual(controller.session.endsAt,end);XCTAssertEqual(controller.session.duration,600)
        let restored=SessionTimerController(defaults:defaults);restored.load(account:"a");XCTAssertEqual(restored.session.draft,"30");XCTAssertEqual(restored.session.id,id)
        controller.clear()
    }
}
