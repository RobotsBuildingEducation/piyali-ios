import XCTest
import UIKit
import LocalAuthentication
@testable import Piyali

@MainActor final class KeyBackupTests:XCTestCase {
    private func identity() throws->IdentityService {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Requires isolated test identity.")}
        let identity=IdentityService();try identity.create();return identity
    }
    func testDeniedAndCancelledAuthorizationNeverCopySecret() async throws {
        let identity=try identity();defer{try? identity.disconnect()};var writes=0
        let denied=KeyBackupController(authorize:{_ in false},write:{_,_ in writes+=1});await denied.copy(identity:identity,reason:"Test backup");XCTAssertEqual(denied.state,.idle)
        let cancelled=KeyBackupController(authorize:{_ in throw LAError(.userCancel)},write:{_,_ in writes+=1});await cancelled.copy(identity:identity,reason:"Test backup");XCTAssertEqual(cancelled.state,.idle);XCTAssertEqual(writes,0)
        let failed=KeyBackupController(authorize:{_ in throw LAError(.passcodeNotSet)},write:{_,_ in writes+=1});await failed.copy(identity:identity,reason:"Test backup");XCTAssertEqual(failed.state,.failed);XCTAssertEqual(writes,0)
    }
    func testAuthorizedCopyUsesCurrentKeyAndTwoMinuteExpiry() async throws {
        let identity=try identity();defer{try? identity.disconnect()};var writes=0,correct=false,remaining=0.0
        let controller=KeyBackupController(authorize:{_ in true},write:{key,expiry in writes+=1;correct=key == identity.exportKey();remaining=expiry.timeIntervalSinceNow})
        await controller.copy(identity:identity,reason:"Test backup");XCTAssertEqual(writes,1);XCTAssertTrue(correct);XCTAssertGreaterThan(remaining,119);XCTAssertLessThanOrEqual(remaining,120)
    }
    func testDefaultClipboardWriterCopiesOnlyTheDisposableSimulatorKey() async throws {
        let identity=try identity();defer{if UIPasteboard.general.string == identity.exportKey(){UIPasteboard.general.items=[]};try? identity.disconnect()}
        let controller=KeyBackupController(authorize:{_ in true});await controller.copy(identity:identity,reason:"Test backup")
        XCTAssertTrue(UIPasteboard.general.string == identity.exportKey())
    }
    func testAccountReplacementAndDismissalRejectHeldAuthorization() async throws {
        let identity=try identity();defer{try? identity.disconnect()};var gate:CheckedContinuation<Bool,Never>?,writes=0
        let controller=KeyBackupController(authorize:{_ in await withCheckedContinuation{gate=$0}},write:{_,_ in writes+=1})
        let first=Task{await controller.copy(identity:identity,reason:"Test backup")};while gate == nil {await Task.yield()};try identity.create();gate?.resume(returning:true);gate=nil;await first.value;XCTAssertEqual(writes,0)
        let second=Task{await controller.copy(identity:identity,reason:"Test backup")};while gate == nil {await Task.yield()};controller.cancel();gate?.resume(returning:true);await second.value;XCTAssertEqual(writes,0);XCTAssertEqual(controller.state,.idle)
    }
}
