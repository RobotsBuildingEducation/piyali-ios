import XCTest
@testable import Piyali

@MainActor private final class SpeechPracticeTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    var session=JSONValue.null,events:[JSONValue]=[],microphone=false,closed=false
    func connect(session:JSONValue)async throws {self.session=session}
    func send(_ event:JSONValue)->Bool {events.append(event);return true}
    func setMicrophoneEnabled(_ enabled:Bool){microphone=enabled}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func close(){closed=true;microphone=false}
}
@MainActor final class SpeechPracticeServiceTests:XCTestCase {
    func testChannelReadinessControlsCaptureAndFinalTranscriptReportsOnlyOnce()async throws {
        let transport=SpeechPracticeTransport(),service=SpeechPracticeService(transportFactory:{transport},permission:{true}),policy=try FlashcardPolicy();var results:[String]=[]
        service.start(target:"es",policy:policy){results.append($0)}
        for _ in 0..<30 where transport.session == .null {await Task.yield()};XCTAssertFalse(transport.microphone);XCTAssertTrue(service.connecting)
        transport.onOpen?();XCTAssertTrue(transport.microphone);XCTAssertTrue(service.recording);XCTAssertEqual(transport.session["output_modalities"].array,[.string("text")]);XCTAssertFalse(transport.session["audio"]["input"]["turn_detection"]["create_response"].boolean)
        transport.onEvent?(.object(["type":.string("response.done")]));XCTAssertTrue(results.isEmpty)
        transport.onEvent?(.object(["type":.string("conversation.item.input_audio_transcription.completed"),"transcript":.string("mamá")]));service.stop();XCTAssertEqual(results,["mamá"]);XCTAssertTrue(transport.closed);XCTAssertFalse(service.recording)
        transport.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"transcript":.string("late")]));XCTAssertEqual(results,["mamá"])
    }
    func testCancellationDuringSetupAndOldCallbacksCannotAffectANewLanguageSession()async throws {
        let old=SpeechPracticeTransport(),new=SpeechPracticeTransport();var current=old
        let service=SpeechPracticeService(transportFactory:{current},permission:{true}),policy=try FlashcardPolicy();var results:[String]=[]
        service.start(target:"es",policy:policy){results.append($0)};for _ in 0..<30 where old.session == .null {await Task.yield()};service.stop();XCTAssertTrue(old.closed);XCTAssertTrue(results.isEmpty)
        current=new;service.start(target:"ar",policy:policy){results.append($0)};for _ in 0..<30 where new.session == .null {await Task.yield()}
        old.onOpen?();old.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"transcript":.string("old language")]));XCTAssertTrue(service.connecting);XCTAssertFalse(new.microphone)
        new.onOpen?();XCTAssertEqual(new.session["audio"]["input"]["transcription"]["language"].string,"ar");service.stop();XCTAssertTrue(service.evaluating);XCTAssertFalse(new.microphone)
        new.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"transcript":.string("مرحبا")]));try await Task.sleep(for:.milliseconds(150));XCTAssertEqual(results,["مرحبا"]);XCTAssertFalse(service.evaluating)
    }
}
