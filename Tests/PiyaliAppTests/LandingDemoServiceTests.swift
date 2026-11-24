import XCTest
import SwiftUI
@testable import Piyali

@MainActor private final class DemoTransportFixture:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    var sent:[JSONValue]=[],mic:[Bool]=[],closed=false,hold=false,started:XCTestExpectation?,pending:CheckedContinuation<Void,Error>?
    func connect(session:JSONValue) async throws {started?.fulfill();if hold {try await withCheckedThrowingContinuation{pending=$0}};onOpen?()}
    func send(_ event:JSONValue)->Bool {sent.append(event);return !closed}
    func setMicrophoneEnabled(_ enabled:Bool) {mic.append(enabled)}
    func setRemoteAudioEnabled(_ enabled:Bool) {}
    func close() {closed=true}
    func emit(_ type:String,_ fields:[String:JSONValue]=[:]) {onEvent?(.object(fields.merging(["type":.string(type)]){_,b in b}))}
    func done(_ id:String) {emit("response.done",["response_id":.string(id)])}
    func input(_ text:String) {emit("conversation.item.input_audio_transcription.completed",["transcript":.string(text)])}
}
@MainActor final class LandingDemoServiceTests:XCTestCase {
    func testPermissionDialogInactivityPreservesStartupButBackgroundCancelsTheConnection() async throws {
        var grant:CheckedContinuation<Bool,Never>?,factories=0;let requested=expectation(description:"Permission pending"),transport=DemoTransportFixture()
        let service=LandingDemoService(permission:{await withCheckedContinuation{grant=$0;requested.fulfill()}},transportFactory:{factories += 1;return transport})
        let start=Task{await service.start(target:"es",support:"en")};await fulfillment(of:[requested],timeout:2)
        service.sceneChanged(.inactive);XCTAssertEqual(service.status,"connecting");XCTAssertEqual(factories,0)
        grant?.resume(returning:true);await start.value;XCTAssertEqual(service.status,"thinking");XCTAssertEqual(transport.sent.count,1)
        transport.done("intro");XCTAssertEqual(service.status,"listening");service.sceneChanged(.background)
        XCTAssertEqual(service.status,"ended");XCTAssertTrue(transport.closed);transport.emit("response.audio_transcript.delta",["delta":.string("stale")]);XCTAssertEqual(service.tutorText,"")
    }
    func testCancelClosesALateConnectionWithoutChangingTheFreshRetry() async throws {
        let old=DemoTransportFixture(),fresh=DemoTransportFixture();old.hold=true;old.started=expectation(description:"Old connection pending");var count=0
        let service=LandingDemoService(permission:{true},transportFactory:{count += 1;return count == 1 ? old : fresh})
        let pending=Task{await service.start(target:"es",support:"en")};await fulfillment(of:[old.started!],timeout:2)
        await service.stop();XCTAssertEqual(service.status,"idle");await service.start(target:"ja",support:"es");fresh.emit("response.audio_transcript.delta",["delta":.string("Fresh Japanese lesson")])
        old.pending?.resume();old.pending=nil;await pending.value;old.emit("response.audio_transcript.delta",["delta":.string("Old Spanish lesson")])
        XCTAssertTrue(old.closed);XCTAssertFalse(fresh.closed);XCTAssertEqual(service.tutorText,"Fresh Japanese lesson");XCTAssertEqual(service.status,"speaking");XCTAssertEqual(fresh.sent.count,1);await service.stop()
    }
    func testConnectionTimeoutAndPermissionDenialAreRetryableWithoutAConnectedSessionCountdown() async throws {
        let late=DemoTransportFixture();late.hold=true;late.started=expectation(description:"Timed connection pending")
        let service=LandingDemoService(permission:{true},transportFactory:{late},connectTimeout:.milliseconds(30)),pending=Task{await service.start(target:"es",support:"en")}
        await fulfillment(of:[late.started!],timeout:2);let failed=expectation(for:NSPredicate{_,_ in service.status == "error"},evaluatedWith:nil);await fulfillment(of:[failed],timeout:2)
        XCTAssertEqual(service.errorCode,"unavailable");XCTAssertTrue(late.closed);late.pending?.resume();late.pending=nil;await pending.value;XCTAssertEqual(service.status,"error")
        var allowed=false;let retry=DemoTransportFixture(),permissions=LandingDemoService(permission:{allowed},transportFactory:{retry},connectTimeout:.milliseconds(30))
        await permissions.start(target:"es",support:"en");XCTAssertEqual(permissions.errorCode,"microphoneDenied");allowed=true;await permissions.start(target:"es",support:"en")
        XCTAssertEqual(permissions.errorCode,"");try await Task.sleep(for:.milliseconds(100));XCTAssertTrue(permissions.active);XCTAssertFalse(retry.closed);await permissions.stop()
    }
    func testCompleteLessonGatesMicrophoneAndWaitsForFinalFeedbackThenIgnoresLateEvents() async {
        let transport=DemoTransportFixture(),service=LandingDemoService(permission:{true},transportFactory:{transport})
        await service.start(target:"es",support:"en");XCTAssertEqual(transport.sent.count,1)
        transport.emit("response.created");transport.input("too soon");XCTAssertEqual(transport.sent.count,1)
        transport.done("one");transport.done("one");XCTAssertEqual(transport.mic,[true]);transport.input(" ");XCTAssertEqual(transport.sent.count,1)
        transport.input("ola");XCTAssertEqual(transport.mic.last,false);transport.done("two");transport.done("two");XCTAssertEqual(transport.sent.count,3);XCTAssertTrue(transport.sent.last!["response"]["instructions"].string.contains("Introduce word 2"))
        transport.done("three");transport.input("gracias");transport.done("four");transport.input("hola");transport.done("five")
        XCTAssertEqual(service.status,"listening");XCTAssertFalse(transport.closed);transport.input("gracias");XCTAssertEqual(transport.sent.count,6);XCTAssertEqual(service.status,"thinking");XCTAssertFalse(transport.closed)
        transport.emit("response.created");transport.emit("response.audio_transcript.delta",["delta":.string("Final feedback")]);transport.done("six")
        XCTAssertEqual(service.status,"ended");XCTAssertEqual(service.tutorText,"Final feedback");XCTAssertTrue(transport.closed);transport.input("more");transport.done("six");XCTAssertEqual(transport.sent.count,6)
        await service.stop(reset:true);XCTAssertEqual(service.status,"idle");XCTAssertEqual(service.tutorText,"")
    }
}

extension LandingDemoServiceTests {
    func testMissingModelResponseIsRetryableWithoutCuttingOffTutorPlayback() async throws {
        let missing=DemoTransportFixture(),service=LandingDemoService(permission:{true},transportFactory:{missing},replyStartTimeout:.milliseconds(30))
        await service.start(target:"es",support:"en");let failed=expectation(for:NSPredicate{_,_ in service.status == "error"},evaluatedWith:nil);await fulfillment(of:[failed],timeout:2)
        XCTAssertEqual(service.errorCode,"unavailable");XCTAssertTrue(missing.closed)
        let speaking=DemoTransportFixture(),long=LandingDemoService(permission:{true},transportFactory:{speaking},replyStartTimeout:.milliseconds(30))
        await long.start(target:"es",support:"en");speaking.emit("response.created");try await Task.sleep(for:.milliseconds(100));XCTAssertEqual(long.status,"speaking");XCTAssertFalse(speaking.closed);await long.stop()
    }
}
