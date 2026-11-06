import Foundation
@MainActor enum WritingSpeechFixture {
    static func recorder()->SpeechPracticeService {
        #if DEBUG
        if enabled{return SpeechPracticeService(transportFactory:{WritingFixtureTransport()},permission:{true})}
        #endif
        return SpeechPracticeService()
    }
    #if DEBUG
    static var reference="",captures=0
    private static var enabled:Bool{let e=ProcessInfo.processInfo.environment;return e["PIYALI_OFFLINE_TESTS"] == "1" && e["PIYALI_LIVE_API_TESTS"] != "1" && e["PIYALI_WRITING_SPEECH_FIXTURE"] == "wrong-then-reference" && UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil}
    static func prepare(_ run:PracticeRun){guard enabled else{return};reference=run.question.payload["answer"].string;if reference.isEmpty{reference=run.question.payload["sampleAnswers"].array.first?.string ?? ""}}
    #endif
}
#if DEBUG
@MainActor private final class WritingFixtureTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    private var work:Task<Void,Never>?
    func connect(session:JSONValue)async throws{onOpen?()}
    func send(_ event:JSONValue)->Bool{true}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func setMicrophoneEnabled(_ enabled:Bool){guard enabled else{return};WritingSpeechFixture.captures+=1;let text=WritingSpeechFixture.captures == 1 ? "WRONG_FIXTURE":WritingSpeechFixture.reference
        work=Task{try? await Task.sleep(for:.milliseconds(300));guard !Task.isCancelled else{return};onEvent?(.object(["type":.string("conversation.item.input_audio_transcription.completed"),"transcript":.string(text)]));onEvent?(.object(["type":.string("response.done")]))}}
    func close(){work?.cancel()}
}
#endif
