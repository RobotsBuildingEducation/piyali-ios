import Foundation

@MainActor enum LandingDemoFixture {
    static func service()->LandingDemoService {
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        if env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,let mode=env["PIYALI_LANDING_DEMO_FIXTURE"],["complete","permission-retry","held-start"].contains(mode) {
            var attempts=0
            return LandingDemoService(permission:{attempts += 1;return mode != "permission-retry" || attempts > 1},transportFactory:{LandingScriptTransport(holds:mode == "held-start",replyDelay:mode == "permission-retry" ? .seconds(5) : .milliseconds(650))})
        }
        #endif
        return LandingDemoService()
    }
}
#if DEBUG
/// Scripted source-protocol events exercise the real lesson controller and UI.
/// This fixture never connects, captures audio, creates an identity or saves XP.
@MainActor private final class LandingScriptTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    private let holds:Bool
    private let replyDelay:Duration
    private var closed=false,reply:Task<Void,Never>?,input:Task<Void,Never>?,request=0,attempt=0,pending:CheckedContinuation<Void,Error>?
    init(holds:Bool,replyDelay:Duration){self.holds=holds;self.replyDelay=replyDelay}
    func connect(session:JSONValue) async throws {if holds {try await withCheckedThrowingContinuation{pending=$0}};if !closed {onOpen?()}}
    func send(_ event:JSONValue)->Bool {
        guard !closed else {return false};request += 1;let number=request
        let text=["Say hola to greet someone.","Good attempt. Listen: hola.","Now say gracias to thank someone.","An alien visits. Greet our new friend.","The café owner gives you a treat. Thank them.","Well done! Hola means hello; gracias means thanks. Goodbye!"][min(5,number-1)]
        let delay=replyDelay
        reply=Task{[weak self] in do {try await Task.sleep(for:delay)}catch{return};guard let self,!self.closed else{return};self.emit("response.created",["response":.object(["id":.string("reply\(number)")])]);self.emit("response.audio_transcript.delta",["delta":.string(text)]);do {try await Task.sleep(for:.milliseconds(700))}catch{return};self.emit("response.done",["response_id":.string("reply\(number)")]);self.emit("response.done",["response_id":.string("reply\(number)")])}
        return true
    }
    func setMicrophoneEnabled(_ enabled:Bool) {
        input?.cancel();input=nil;guard enabled,!closed,attempt < 4 else{return}
        let text=["ola","gracias","hola","gracias"][attempt];attempt += 1
        input=Task{[weak self] in do {try await Task.sleep(for:.milliseconds(900))}catch{return};self?.emit("conversation.item.input_audio_transcription.completed",["transcript":.string(text)])}
    }
    func setRemoteAudioEnabled(_ enabled:Bool) {}
    func audioAmplitude(speaking:Bool) async ->Double {closed ? 0 : 0.045}
    private func emit(_ type:String,_ fields:[String:JSONValue]=[:]) {guard !closed else{return};onEvent?(.object(fields.merging(["type":.string(type)]){_,b in b}))}
    func close() {guard !closed else{return};closed=true;input?.cancel();reply?.cancel();pending?.resume(throwing:CancellationError());pending=nil}
}
#endif
