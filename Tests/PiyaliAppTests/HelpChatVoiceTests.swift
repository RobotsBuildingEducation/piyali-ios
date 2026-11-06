import XCTest
@testable import Piyali

@MainActor private final class HelpVoiceTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    var session:JSONValue = .null,sent:[JSONValue]=[],microphone=false,closed=false
    func connect(session:JSONValue)async throws{self.session=session;onOpen?()}
    func send(_ value:JSONValue)->Bool{sent.append(value);return true}
    func setMicrophoneEnabled(_ enabled:Bool){microphone=enabled}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func close(){closed=true}
    func event(_ text:String)throws{onEvent?(try JSONDecoder().decode(JSONValue.self,from:Data(text.utf8)))}
}
@MainActor final class HelpChatVoiceTests:XCTestCase {
    func testSourceIdleThinkingAndSpeakingDeadlinesCancelOldTimers()async throws {
        var waits:[Int]=[],continuations:[CheckedContinuation<Void,Never>]=[],timeouts=0
        let deadline=HelpChatVoiceDeadline(wait:{ms in waits.append(ms);await withCheckedContinuation{continuations.append($0)}})
        deadline.begin{timeouts += 1};for _ in 0..<50 where waits.count<1{await Task.yield()};XCTAssertEqual(deadline.milliseconds,15000)
        deadline.receive(.object(["type":.string("input_audio_buffer.speech_started")]));XCTAssertNil(deadline.milliseconds)
        deadline.receive(.object(["type":.string("input_audio_buffer.committed")]));for _ in 0..<50 where waits.count<2{await Task.yield()};XCTAssertEqual(deadline.milliseconds,25000)
        deadline.receive(.object(["type":.string("response.created")]));for _ in 0..<50 where waits.count<3{await Task.yield()};XCTAssertEqual(deadline.milliseconds,45000)
        deadline.receive(.object(["type":.string("response.done")]));XCTAssertEqual(deadline.milliseconds,45000)
        deadline.receive(.object(["type":.string("output_audio_buffer.stopped")]));for _ in 0..<50 where waits.count<4{await Task.yield()};XCTAssertEqual(deadline.milliseconds,15000)
        XCTAssertEqual(waits,[15000,25000,45000,15000]);for c in continuations.dropLast(){c.resume()};await Task.yield();XCTAssertEqual(timeouts,0);continuations.last?.resume();for _ in 0..<20 where timeouts == 0{await Task.yield()};XCTAssertEqual(timeouts,1);XCTAssertNil(deadline.milliseconds)
    }
    func testOriginalHelpSessionListensFirstOrdersDelayedTranscriptsAndStopsOnIdle()async throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent("help-voice-"+UUID().uuidString),chat=HelpChatController(directory:directory),transport=HelpVoiceTransport(),live=LiveTutorService(permission:{true},transportFactory:{transport});defer{try? FileManager.default.removeItem(at:directory)}
        chat.configure(account:"voice-test",progress:.object(["targetLang":.string("es"),"supportLang":.string("ar")]),appLanguage:"ar");let session=try chat.run("session")
        await live.start(learner:LearnerState(),instructions:session["instructions"].string,openingPrompt:nil,inactivityTimeout:0.05,onInputTurn:chat.voiceInput,onAssistantTurn:chat.voiceReply,sessionConfiguration:session)
        XCTAssertEqual(transport.session,session);XCTAssertTrue(transport.microphone);XCTAssertFalse(transport.sent.contains{$0["type"].string == "response.create"});XCTAssertEqual(session["audio"]["input"]["turn_detection"]["silence_duration_ms"],.number(2000));XCTAssertTrue(session["instructions"].string.contains("Egyptian Arabic"))
        try transport.event(#"{"type":"input_audio_buffer.committed","item_id":"u1"}"#);try transport.event(#"{"type":"response.created","response":{"id":"r1"}}"#);try transport.event(#"{"type":"response.done","response":{"id":"r1","status":"completed","output":[{"content":[{"transcript":"Use hermana."}]}]}}"#)
        XCTAssertEqual(chat.messages.map(\.role),["assistant"]);try transport.event(#"{"type":"conversation.item.input_audio_transcription.completed","item_id":"u1","transcript":"What is sister?"}"#);XCTAssertEqual(chat.messages.map(\.role),["user","assistant"])
        try transport.event(#"{"type":"output_audio_buffer.stopped"}"#);try await Task.sleep(for:.milliseconds(1200));XCTAssertTrue(live.autoStopped);XCTAssertTrue(transport.closed);XCTAssertFalse(live.connected);XCTAssertTrue(chat.saved.isEmpty);await live.stop()
    }
}
