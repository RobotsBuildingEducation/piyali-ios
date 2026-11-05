import Foundation

@MainActor enum ConversationVoiceFixture {
    static func service()->LiveTutorService {
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        if env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_CONVERSATION_FIXTURE"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil {
            let script=ConversationVoiceScript()
            return LiveTutorService(capturesMicrophone:false,permission:{true},transportFactory:{ConversationScriptTransport(script:script)})
        }
        #endif
        return LiveTutorService()
    }
}
#if DEBUG
/// Scripted protocol events drive the production voice controller and UI. No
/// fixture controls are inserted into the learner screen or persistence layer.
@MainActor private final class ConversationVoiceScript {
    var position=0
    let turns=[("wrong topic","Intenta saludar y decir tu nombre."),("Hola, me llamo Ana.","¡Hola, Ana! ¿Qué te gusta hacer?")]
}
@MainActor private final class ConversationScriptTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    private let script:ConversationVoiceScript
    private var emission:Task<Void,Never>?,closed=false,microphone=false
    private var resumeEmission:Task<Void,Never>?
    private var replyEmission:Task<Void,Never>?
    private let prefix=UUID().uuidString
    init(script:ConversationVoiceScript) { self.script=script }
    func connect(session:JSONValue) async throws { closed=false;onOpen?() }
    func send(_ event:JSONValue)->Bool {
        guard !closed else{return false}
        if ProcessInfo.processInfo.environment["PIYALI_CONVERSATION_PARTIAL_FIXTURE"] == "1",event["type"].string == "response.create",event["response"]["metadata"]["kind"].string == "pause_resume" {
            script.position=script.turns.count
            resumeEmission=Task { [weak self] in
                try? await Task.sleep(for:.milliseconds(500));guard !Task.isCancelled,let self,!self.closed else{return}
                let id=self.prefix+"-resumed";self.emit(["type":.string("response.created"),"response":.object(["id":.string(id)])]);self.emit(["type":.string("output_audio_buffer.started")])
                self.emit(["type":.string("response.output_audio_transcript.done"),"response_id":.string(id),"transcript":.string("Vamos a practicar juntos.")])
                self.emit(["type":.string("response.done"),"response":.object(["id":.string(id),"status":.string("completed"),"output":.array([.object(["content":.array([.object(["transcript":.string("Vamos a practicar juntos.")])])])])])]);self.emit(["type":.string("output_audio_buffer.stopped")])
            }
        }
        return true
    }
    func setRemoteAudioEnabled(_ enabled:Bool) {}
    func setMicrophoneEnabled(_ enabled:Bool) {
        microphone=enabled;emission?.cancel();emission=nil
        guard enabled,!closed,script.position < script.turns.count else { return }
        let delay=script.position == 0 ? 2 : 5
        emission=Task { [weak self] in
            do { try await Task.sleep(for:.seconds(delay)) } catch { return }
            guard let self,!self.closed,self.microphone else { return }
            let index=self.script.position,turn=self.script.turns[index];self.script.position += 1
            let input=self.prefix+"-input-\(index)",response=self.prefix+"-response-\(index)"
            self.emit(["type":.string("input_audio_buffer.speech_started")])
            self.emit(["type":.string("input_audio_buffer.speech_stopped")])
            self.emit(["type":.string("input_audio_buffer.committed"),"item_id":.string(input)])
            self.emit(["type":.string("response.created"),"response":.object(["id":.string(response)])])
            self.emit(["type":.string("conversation.item.input_audio_transcription.completed"),"item_id":.string(input),"transcript":.string(turn.0)])
            self.emit(["type":.string("output_audio_buffer.started")])
            if ProcessInfo.processInfo.environment["PIYALI_CONVERSATION_LIVE_TRANSLATION_FIXTURE"] == "1",index == 0 {
                self.script.position=self.script.turns.count;self.emit(["type":.string("response.output_audio_transcript.delta"),"response_id":.string(response),"delta":.string("Vamos a practicar")])
                self.replyEmission=Task { [weak self] in
                    try? await Task.sleep(for:.seconds(8));guard !Task.isCancelled,let self,!self.closed else{return}
                    self.emit(["type":.string("response.output_audio_transcript.delta"),"response_id":.string(response),"delta":.string(" juntos.")])
                    self.emit(["type":.string("response.done"),"response":.object(["id":.string(response),"status":.string("completed"),"output":.array([.object(["content":.array([.object(["transcript":.string("Vamos a practicar juntos.")])])])])])]);self.emit(["type":.string("output_audio_buffer.stopped")])
                };return
            }
            if ProcessInfo.processInfo.environment["PIYALI_CONVERSATION_PARTIAL_FIXTURE"] == "1",index == 0 {self.emit(["type":.string("response.output_audio_transcript.delta"),"response_id":.string(response),"delta":.string("Vamos a practicar")]);return}
            self.emit(["type":.string("response.output_audio_transcript.done"),"response_id":.string(response),"transcript":.string(turn.1)])
            self.emit(["type":.string("response.done"),"response":.object(["id":.string(response),"status":.string("completed"),"output":.array([.object(["content":.array([.object(["transcript":.string(turn.1)])])])])])])
            self.emit(["type":.string("output_audio_buffer.stopped")])
        }
    }
    private func emit(_ event:[String:JSONValue]) { guard !closed else { return };onEvent?(.object(event)) }
    func close() { closed=true;microphone=false;emission?.cancel();emission=nil;resumeEmission?.cancel();resumeEmission=nil;replyEmission?.cancel();replyEmission=nil }
}
#endif
