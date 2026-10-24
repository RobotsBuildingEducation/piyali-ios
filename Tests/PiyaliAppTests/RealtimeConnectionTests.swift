import XCTest
import FirebaseCore
import FirebaseAuth
import FirebaseAppCheck
@testable import Piyali

@MainActor final class RealtimeConnectionTests:XCTestCase {
    func testDefaultRealtimeModelReturnsDataEventsAndNativeWebRTCAudio() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_LIVE_API_TESTS"] == "1" else { throw XCTSkip("Explicit live API opt-in required.") }
        XCTAssertEqual(ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"],"1")
        _=try XCTUnwrap(UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? ""))
        executionTimeAllowance=120
        if FirebaseApp.app() == nil { AppCheck.setAppCheckProviderFactory(PiyaliAppCheckFactory());FirebaseApp.configure() }
        XCTAssertEqual(FirebaseApp.app()?.options.projectID,"piyali-ios")
        let identity=IdentityService();try identity.create();try await FirebaseIdentityService.shared.ensure(identity)
        print("LIVE REALTIME CHECK: disposable Piyali account authenticated")
        // No physical microphone input is captured. This checks the actual
        // authenticated SDP exchange, data channel, and incoming RTP audio.
        let transport=RealtimeRTCTransport(capturesMicrophone:false)
        print("LIVE REALTIME CHECK: native WebRTC factory created")
        do {
            let opened=expectation(description:"oai-events channel opened"),spoken=expectation(description:"assistant audio played")
            var sessionModel="",output="",failure:String?,didStartAudio=false,peakAmplitude=0.0
            var audioMeter:Task<Void,Never>?;defer {audioMeter?.cancel()}
            transport.onOpen={ opened.fulfill() }
            transport.onFailure={ failure=$0 }
            transport.onEvent={ event in
                switch event["type"].string {
                case "session.created": sessionModel=event["session"]["model"].string
                case "response.output_audio_transcript.done","response.audio_transcript.done": output=event["transcript"].string
                case "output_audio_buffer.started": didStartAudio=true
                case "output_audio_buffer.stopped": spoken.fulfill()
                case "error": failure="Provider rejected event: "+event["error"]["code"].string
                default: break
                }
            }
            try await transport.connect(session:RealtimeVoicePolicy.session(instructions:"You are a Spanish practice partner. Say exactly 'Hola, buenos días.' when asked to greet.",manualResponse:true))
            print("LIVE REALTIME CHECK: remote SDP applied")
            await fulfillment(of:[opened],timeout:20)
            audioMeter=Task {
                while !Task.isCancelled {
                    peakAmplitude=max(peakAmplitude,await transport.audioAmplitude(speaking:true))
                    do {try await Task.sleep(for:.milliseconds(50))} catch {return}
                }
            }
            let input:JSONValue = .object(["type":.string("conversation.item.create"),"item":.object(["type":.string("message"),"role":.string("user"),"content":.array([.object(["type":.string("input_text"),"text":.string("Greet me in Spanish.")])])])])
            let response:JSONValue = .object(["type":.string("response.create"),"response":.object(["output_modalities":.array([.string("audio")])])])
            XCTAssertTrue(transport.send(input));XCTAssertTrue(transport.send(response))
            await fulfillment(of:[spoken],timeout:35)
            audioMeter?.cancel();await audioMeter?.value
            XCTAssertGreaterThan(peakAmplitude,0,"Real incoming RTP audio must supply amplitude for the visual envelope.")
            XCTAssertNil(failure);XCTAssertTrue(sessionModel.hasPrefix("gpt-realtime-2.1-mini"),sessionModel)
            XCTAssertFalse(output.isEmpty);XCTAssertTrue(didStartAudio);let bytes=await transport.receivedAudioBytes();XCTAssertGreaterThan(bytes,0)
            print("LIVE OPENAI WEBRTC: authenticated native SDP, source mini model, oai-events transcripts, playback stop, incoming audio packets and positive receiver amplitude verified; microphone capture disabled")
        } catch { transport.close();try? await Auth.auth().currentUser?.delete();try? Auth.auth().signOut();try? identity.disconnect();throw error }
        transport.close();try await Auth.auth().currentUser?.delete();try Auth.auth().signOut();try identity.disconnect()
    }
    func testDeniedPermissionNeverStartsAConnection() async {
        let service=LiveTutorService(permission:{false})
        await service.start(learner:LearnerState())
        XCTAssertFalse(service.connecting);XCTAssertFalse(service.connected);XCTAssertEqual(service.error,"Enable the microphone in Settings to use live audio.")
    }
    func testStopInvalidatesPermissionThatCompletesLater() async {
        var permission:CheckedContinuation<Bool,Never>?
        let requested=expectation(description:"permission requested")
        let service=LiveTutorService(permission:{ await withCheckedContinuation { permission=$0;requested.fulfill() } })
        let start=Task { await service.start(learner:LearnerState()) }
        await fulfillment(of:[requested],timeout:2)
        await service.stop();permission?.resume(returning:true);await start.value
        XCTAssertFalse(service.connecting);XCTAssertFalse(service.connected);XCTAssertNil(service.error)
    }
}

@MainActor private final class VoiceTransportFixture:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    var session:JSONValue = .null,events:[JSONValue]=[],microphone=false,closed=false,sendsSucceed=true
    func connect(session:JSONValue) async throws { self.session=session;onOpen?() }
    func send(_ event:JSONValue)->Bool { events.append(event);return sendsSucceed }
    func setMicrophoneEnabled(_ enabled:Bool) { microphone=enabled }
    var amplitude=0.06
    var amplitudeRequest:CheckedContinuation<Double,Never>?
    var holdsAmplitude=false
    var amplitudeStarted:XCTestExpectation?
    func audioAmplitude(speaking:Bool) async ->Double { if holdsAmplitude {return await withCheckedContinuation {amplitudeRequest=$0;amplitudeStarted?.fulfill()}};return amplitude }
    var remoteAudio=true
    func setRemoteAudioEnabled(_ enabled:Bool) { remoteAudio=enabled }
    func close() { closed=true;microphone=false }
    func receive(_ raw:String) throws { onEvent?(try JSONDecoder().decode(JSONValue.self,from:Data(raw.utf8))) }
    var vad:JSONValue { events.last { $0["session"]["audio"]["input"].object.keys.contains("turn_detection") }?["session"]["audio"]["input"]["turn_detection"] ?? .null }
}

@MainActor final class RealtimeVoiceControllerTests:XCTestCase {
    func testConversationUsesSourcePolicyAndLocksMicUntilPlaybackStopsWhileMutePersists() async throws {
        let transport=VoiceTransportFixture(),service=LiveTutorService(permission:{true},transportFactory:{transport})
        var draft=ConversationDraft();draft.personality="A dramatic pirate"
        await service.start(learner:LearnerState(),conversationDraft:draft)
        XCTAssertTrue(service.connected);XCTAssertTrue(transport.microphone)
        XCTAssertEqual(transport.session["model"].string,"gpt-realtime-2.1-mini")
        XCTAssertTrue(transport.session["instructions"].string.contains("A dramatic pirate"))
        XCTAssertFalse(transport.session["audio"]["input"]["turn_detection"]["create_response"].boolean)
        try transport.receive(#"{"type":"input_audio_buffer.committed","item_id":"u1"}"#)
        XCTAssertFalse(transport.microphone);XCTAssertEqual(transport.vad,.null)
        try transport.receive(#"{"type":"input_audio_buffer.committed","item_id":"u1"}"#)
        XCTAssertEqual(transport.events.filter { $0["type"].string == "response.create" }.count,1)
        XCTAssertTrue(transport.events.first { $0["type"].string == "response.create" }?["response"]["instructions"].string.contains("FINAL STYLE REQUIREMENT") == true)
        try transport.receive(#"{"type":"response.created","response":{"id":"r1"}}"#)
        try transport.receive(#"{"type":"response.done","response":{"id":"r1","status":"completed"}}"#)
        XCTAssertFalse(transport.microphone)
        service.setMuted(true);try transport.receive(#"{"type":"output_audio_buffer.stopped"}"#)
        XCTAssertFalse(transport.microphone);XCTAssertEqual(transport.vad,.null)
        service.setMuted(false);XCTAssertTrue(transport.microphone);XCTAssertEqual(transport.vad["type"].string,"server_vad")
        await service.stop();XCTAssertTrue(transport.closed);XCTAssertFalse(transport.microphone)
    }
    func testLateTranscriptCompletesOneTurnAndOldConnectionCallbacksCannotAwardAfterStop() async throws {
        let transport=VoiceTransportFixture(),service=LiveTutorService(permission:{true},transportFactory:{transport})
        var draft=ConversationDraft();draft.append(.init(role:"assistant",text:"¿Qué quieres beber?"))
        var received:[String]=[]
        await service.start(learner:LearnerState(),conversationDraft:draft,onConversationTurn:{text,answered,reply in received += [text,answered,reply]})
        let oldEvent=transport.onEvent
        for raw in [#"{"type":"input_audio_buffer.speech_started"}"#,#"{"type":"input_audio_buffer.committed","item_id":"u1"}"#,#"{"type":"response.created","response":{"id":"r1"}}"#,#"{"type":"response.done","response":{"id":"r1","status":"completed","output":[{"content":[{"transcript":"Aquí tienes tu café."}]}]}}"#] { try transport.receive(raw) }
        XCTAssertTrue(received.isEmpty)
        let transcript=#"{"type":"conversation.item.input_audio_transcription.completed","item_id":"u1","transcript":"Un café, por favor."}"#
        try transport.receive(transcript);try transport.receive(transcript)
        XCTAssertEqual(received,["Un café, por favor.","¿Qué quieres beber?","Aquí tienes tu café."]);XCTAssertEqual(service.learnerTurnNumber,1)
        XCTAssertEqual(service.transcript,"You: Un café, por favor.\nPiyali: Aquí tienes tu café.")
        await service.stop();oldEvent?(try JSONDecoder().decode(JSONValue.self,from:Data(transcript.utf8)))
        XCTAssertEqual(service.learnerTurnNumber,1);XCTAssertEqual(received.count,3)
    }
    func testInstructionUpdateDoesNotReenableSpeechDuringAssistantAudioAndSendFailureCloses() async throws {
        let transport=VoiceTransportFixture(),service=LiveTutorService(permission:{true},transportFactory:{transport})
        var draft=ConversationDraft();await service.start(learner:LearnerState(),conversationDraft:draft)
        try transport.receive(#"{"type":"response.created","response":{"id":"r1"}}"#)
        let before=transport.events.count;draft.interests="travel"
        await service.updateConversation(draft,learner:LearnerState())
        XCTAssertFalse(transport.microphone);XCTAssertEqual(transport.events.count,before+1)
        XCTAssertFalse(try XCTUnwrap(transport.events.last)["session"].object.keys.contains("audio"))
        transport.sendsSucceed=false;service.setMuted(true)
        XCTAssertFalse(service.connected);XCTAssertTrue(transport.closed);XCTAssertNotNil(service.error)
    }
}

extension RealtimeVoiceControllerTests {
    func testInputCanBeGradedBeforeAssistantFinishesAndResumeMuteNeverOpensMicrophone() async throws {
        let transport=VoiceTransportFixture(),service=LiveTutorService(permission:{true},transportFactory:{transport})
        var inputs:[RealtimeVoiceState.InputTurn]=[],replies:[String]=[]
        await service.start(learner:LearnerState(),conversationDraft:ConversationDraft(),initiallyMuted:true,onInputTurn:{inputs.append($0)},onAssistantTurn:{_,text in replies.append(text)})
        XCTAssertTrue(service.connected);XCTAssertTrue(service.muted);XCTAssertFalse(transport.microphone);XCTAssertEqual(transport.vad,.null)
        service.setMuted(false)
        for raw in [#"{"type":"input_audio_buffer.committed","item_id":"u1"}"#,#"{"type":"response.created","response":{"id":"r1"}}"#,#"{"type":"conversation.item.input_audio_transcription.completed","item_id":"u1","transcript":"Me llamo Ana."}"#] { try transport.receive(raw) }
        XCTAssertEqual(inputs.count,1);XCTAssertEqual(inputs.first?.responseID,"r1");XCTAssertTrue(replies.isEmpty);XCTAssertEqual(service.learnerTurnNumber,0)
        try transport.receive(#"{"type":"conversation.item.input_audio_transcription.completed","item_id":"u1","transcript":"Me llamo Ana."}"#);XCTAssertEqual(inputs.count,1)
        try transport.receive(#"{"type":"response.done","response":{"id":"r1","status":"completed","output":[{"content":[{"transcript":"¡Hola, Ana!"}]}]}}"#)
        XCTAssertEqual(replies,["¡Hola, Ana!"]);XCTAssertEqual(service.learnerTurnNumber,1)
        await service.stop()
    }
    func testInstructionUpdatesKeepOnlyTheFrozenResumeHistory() async throws {
        let transport=VoiceTransportFixture(),service=LiveTutorService(permission:{true},transportFactory:{transport})
        var draft=ConversationDraft();draft.append(.init(role:"assistant",text:"This was saved before pause."))
        await service.start(learner:LearnerState(),conversationDraft:draft)
        draft.append(.init(role:"user",text:"This belongs to the current connection."));draft.interests="travel"
        await service.updateConversation(draft,learner:LearnerState())
        let prompt=try XCTUnwrap(transport.events.last)["session"]["instructions"].string
        XCTAssertTrue(prompt.contains("This was saved before pause."));XCTAssertFalse(prompt.contains("This belongs to the current connection."))
        await service.stop()
    }
}

extension RealtimeVoiceControllerTests {
    func testStarterPlaybackDucksBothAudioDirectionsWithoutChangingUserMuteOrAssistantLock() async throws {
        let transport=VoiceTransportFixture(),service=LiveTutorService(permission:{true},transportFactory:{transport})
        await service.start(learner:LearnerState(),conversationDraft:ConversationDraft())
        service.setPlaybackDucked(true);XCTAssertFalse(transport.microphone);XCTAssertFalse(transport.remoteAudio);XCTAssertEqual(transport.vad,.null);XCTAssertFalse(service.muted)
        try transport.receive(#"{"type":"response.created","response":{"id":"r1"}}"#)
        service.setPlaybackDucked(false);XCTAssertTrue(transport.remoteAudio);XCTAssertFalse(transport.microphone)
        service.setMuted(true);try transport.receive(#"{"type":"output_audio_buffer.stopped"}"#);XCTAssertFalse(transport.microphone)
        service.setPlaybackDucked(true);service.setPlaybackDucked(false);XCTAssertTrue(service.muted);XCTAssertFalse(transport.microphone)
        service.setMuted(false);XCTAssertTrue(transport.microphone);await service.stop()
    }
}

extension RealtimeVoiceControllerTests {
    func testChangingContextClearsTransientVoiceTextAndFencesThePreviousConnection() async throws {
        let transport=VoiceTransportFixture(),service=LiveTutorService(permission:{true},transportFactory:{transport})
        await service.start(learner:LearnerState(),conversationDraft:ConversationDraft())
        try transport.receive(#"{"type":"response.created","response":{"id":"r1"}}"#)
        try transport.receive(#"{"type":"response.output_audio_transcript.delta","response_id":"r1","delta":"Old language reply"}"#)
        XCTAssertEqual(service.assistantTurnText,"Old language reply");let oldEvent=transport.onEvent
        await service.stop(clearTranscript:true);XCTAssertTrue(service.assistantTurnText.isEmpty);XCTAssertTrue(service.transcript.isEmpty)
        oldEvent?(.object(["type":.string("response.output_audio_transcript.delta"),"response_id":.string("r1"),"delta":.string(" late words")]))
        XCTAssertTrue(service.assistantTurnText.isEmpty);XCTAssertFalse(service.connected)
    }
}

extension RealtimeVoiceControllerTests {
    func testVisualAudioEnvelopeMutesDucksAndRejectsSamplesFromThePreviousConnection() async throws {
        let transport=VoiceTransportFixture(),service=LiveTutorService(permission:{true},transportFactory:{transport})
        await service.start(learner:LearnerState(),conversationDraft:ConversationDraft())
        let audible=expectation(for:NSPredicate {_,_ in service.audioLevel > 0},evaluatedWith:nil)
        await fulfillment(of:[audible],timeout:3)
        service.setMuted(true);XCTAssertEqual(service.audioLevel,0)
        try transport.receive(#"{"type":"output_audio_buffer.started"}"#)
        let reply=expectation(for:NSPredicate {_,_ in service.audioLevel > 0},evaluatedWith:nil)
        await fulfillment(of:[reply],timeout:3)
        service.setPlaybackDucked(true);XCTAssertEqual(service.audioLevel,0);service.setPlaybackDucked(false)
        transport.holdsAmplitude=true;transport.amplitudeStarted=expectation(description:"Old audio sample pending")
        await fulfillment(of:[transport.amplitudeStarted!],timeout:3);await service.stop(clearTranscript:true)
        transport.amplitudeRequest?.resume(returning:1);transport.amplitudeRequest=nil
        await Task.yield();XCTAssertEqual(service.audioLevel,0);XCTAssertFalse(service.connected)
    }
}
