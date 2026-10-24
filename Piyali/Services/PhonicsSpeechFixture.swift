import Foundation

@MainActor enum PhonicsSpeechFixture {
    static func recorder()->SpeechPracticeService {
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        if env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_LIVE_API_TESTS"] != "1",env["PIYALI_PHONICS_FIXTURE"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil {return SpeechPracticeService(transportFactory:{PhonicsFixtureTransport()},permission:{true})}
        #endif
        return SpeechPracticeService()
    }
}
#if DEBUG
@MainActor private final class PhonicsFixtureTransport:RealtimeVoiceTransport {
    static var captures=0
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    private var session:JSONValue = .null,work:Task<Void,Never>?
    func connect(session:JSONValue)async throws {self.session=session;onOpen?()}
    func send(_ event:JSONValue)->Bool {true}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func setMicrophoneEnabled(_ enabled:Bool){guard enabled else{return};Self.captures += 1;let first=Self.captures == 1
        work=Task{try? await Task.sleep(for:.milliseconds(180));guard !Task.isCancelled else{return};let prompt=session["audio"]["input"]["transcription"]["prompt"].string
            let text=first ? "WRONG_FIXTURE":prompt.components(separatedBy:"\"").dropLast().last ?? "casa"
            onEvent?(.object(["type":.string("conversation.item.input_audio_transcription.completed"),"transcript":.string(text)]));onEvent?(.object(["type":.string("response.done")]))
        }
    }
    func close(){work?.cancel()}
}
#endif
