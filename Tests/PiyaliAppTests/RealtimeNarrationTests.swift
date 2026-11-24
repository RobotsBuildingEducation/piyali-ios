import XCTest
@testable import Piyali

@MainActor private final class NarrationTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    var session:JSONValue = .null,sent:[JSONValue]=[],microphone:[Bool]=[],closed=false
    func connect(session:JSONValue)async throws{self.session=session;onOpen?()}
    func send(_ event:JSONValue)->Bool{sent.append(event);return true}
    func setMicrophoneEnabled(_ enabled:Bool){microphone.append(enabled)}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func playbackDrainMilliseconds()async->Double{30}
    func close(){closed=true}
}
@MainActor final class RealtimeNarrationTests:XCTestCase {
    func testOriginalNarrationStartsReceiveOnlyAndWaitsForGenerationAndPlayout()async throws {
        let transport=NarrationTransport(),service=RealtimeNarrationService(factory:{transport}),engine=try CompanionQuestPolicy();defer{service.stopAll()};var finished=0
        service.play("casa",language:"es",engine:engine){finished += 1}
        for _ in 0..<40 where transport.sent.isEmpty{await Task.yield()}
        XCTAssertEqual(transport.microphone,[false]);XCTAssertTrue(transport.session["instructions"].string.contains("es-MX"));XCTAssertEqual(transport.sent.first?["item"]["content"].array.first?["text"].string,"[NARRATE THIS TEXT EXACTLY]: casa");XCTAssertEqual(transport.sent.last?["type"].string,"response.create")
        transport.onEvent?(.object(["type":.string("output_audio_buffer.started")]));XCTAssertTrue(service.playing)
        transport.onEvent?(.object(["type":.string("response.done"),"response":.object(["status":.string("completed")])]));try await Task.sleep(for:.milliseconds(60));XCTAssertEqual(finished,0);XCTAssertTrue(service.playing);XCTAssertFalse(transport.closed)
        transport.onEvent?(.object(["type":.string("output_audio_buffer.stopped")]));try await Task.sleep(for:.milliseconds(80));XCTAssertEqual(finished,1);XCTAssertFalse(service.playing);XCTAssertTrue(transport.closed)
    }
    func testNewNarrationCancelsOldOwnerAndRejectsLateFailureAndIncompleteResponses()async throws {
        let first=NarrationTransport(),second=NarrationTransport(),a=RealtimeNarrationService(factory:{first}),b=RealtimeNarrationService(factory:{second}),engine=try CompanionQuestPolicy();defer{a.stopAll();b.stopAll()}
        a.play("casa",language:"es",engine:engine);for _ in 0..<40 where first.sent.isEmpty{await Task.yield()};let late=first.onFailure
        b.play("Bonjour",language:"fr",engine:engine);for _ in 0..<40 where second.sent.isEmpty{await Task.yield()};XCTAssertTrue(first.closed);late?("old failure");XCTAssertNil(b.error);XCTAssertTrue(b.loading)
        second.onEvent?(.object(["type":.string("response.done"),"response":.object(["status":.string("incomplete")])]));XCTAssertNotNil(b.error);XCTAssertTrue(second.closed);XCTAssertFalse(b.loading)
    }
}
