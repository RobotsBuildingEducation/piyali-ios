import Foundation
import AVFoundation

/// The source useSpeechPractice transcription session: capture starts on data-channel readiness.
@MainActor final class SpeechPracticeService:ObservableObject {
    @Published private(set) var connecting=false
    @Published private(set) var recording=false
    @Published private(set) var evaluating=false
    @Published private(set) var transcript=""
    @Published private(set) var audioLevel=0.0
    @Published private(set) var error:String?
    private var transport:RealtimeVoiceTransport?
    private let makeTransport:()->RealtimeVoiceTransport
    private let permission:()async->Bool
    private var epoch=UUID(),speechStarted:Date?,heardSpeech=false,waitingForEnd=false,userStopped=false
    private var setup:Task<Void,Never>?,finishTimer:Task<Void,Never>?,limit:Task<Void,Never>?,deadline:Task<Void,Never>?
    private var meter:Task<Void,Never>?
    private var completion:((String)->Void)?
    private var silenceMs=2000
    init(transportFactory:(()->RealtimeVoiceTransport)?=nil,permission:(()async->Bool)?=nil){makeTransport=transportFactory ?? {RealtimeRTCTransport()};self.permission=permission ?? {await AVAudioApplication.requestRecordPermission()}}
    func clearError(){error=nil}
    func reportError(_ code:String){cancel();error=code}
    func start(target:String,policy:FlashcardPolicy,transcriptionHint:String="",timeoutMs:Int=2000,onResult:@escaping (String)->Void){
        guard !connecting,!recording,!evaluating else{return};cancel();let token=epoch;silenceMs=max(500,timeoutMs);connecting=true;transcript="";error=nil;completion=onResult
        setup=Task {do {
            guard await permission() else{throw AppError.message("mic-denied")};try Task.checkCancellation();guard epoch == token else{return}
            let session=try policy.run("flashSpeech",.object(["targetLang":.string(target),"transcriptionHint":.string(transcriptionHint),"timeoutMs":.number(Double(silenceMs))])),client=makeTransport();transport=client
            client.onOpen={ [weak self,weak client] in guard let self,self.epoch == token else{return};self.deadline?.cancel();client?.setRemoteAudioEnabled(false)
                guard client?.send(.object(["type":.string("session.update"),"event_id":.string("speech-practice-session-update"),"session":session])) == true else{self.fail("connection-failed");return}
                client?.setMicrophoneEnabled(true);self.connecting=false;self.recording=true;self.meter=Task{while !Task.isCancelled,self.epoch == token,self.recording{self.audioLevel=await client?.audioAmplitude(speaking:false) ?? 0;try? await Task.sleep(for:.milliseconds(50))}};self.limit=Task{try? await Task.sleep(for:.milliseconds(max(30000,self.silenceMs)));if !Task.isCancelled,self.epoch == token{self.finish()}}
            }
            client.onEvent={ [weak self] value in guard let self,self.epoch == token else{return};self.receive(value)}
            client.onFailure={ [weak self] _ in guard let self,self.epoch == token else{return};self.fail("connection-failed")}
            deadline=Task{try? await Task.sleep(for:.seconds(10));if !Task.isCancelled,self.epoch == token,self.connecting{self.fail("connection-failed")}}
            try await client.connect(session:session);try Task.checkCancellation()
        }catch is CancellationError{}catch{if epoch == token{fail(error.localizedDescription)}}}
    }
    func receive(_ event:JSONValue,now:Date=Date()){
        let type=event["type"].string
        if ["conversation.item.input_audio_transcription.completed","input_audio_transcription.completed"].contains(type),!event["transcript"].string.isEmpty {
            transcript=event["transcript"].string.trimmingCharacters(in:.whitespacesAndNewlines);heardSpeech=true;schedule(userStopped ? 80:waitingForEnd ? 180:silenceMs)
        }else if type == "input_audio_buffer.speech_started" {heardSpeech=true;waitingForEnd=false;speechStarted=now;finishTimer?.cancel()}
        else if type == "input_audio_buffer.speech_stopped" {
            let duration=speechStarted.map{now.timeIntervalSince($0)*1000} ?? 500;speechStarted=nil
            if duration<500,transcript.isEmpty{heardSpeech=false;waitingForEnd=false;return}
            if heardSpeech {waitingForEnd=true;schedule(transcript.isEmpty ? 2500:1500)}
        }else if type == "response.done",!transcript.isEmpty{waitingForEnd=true;schedule(500)}
        else if type == "error" {
            if event["error"]["code"].string == "input_audio_buffer_commit_empty" {return}
            if event["error"]["event_id"].string == "speech-practice-session-update",!heardSpeech,transcript.isEmpty{return}
            if transcript.isEmpty {fail("realtime-error")}else{finish()}
        }else if type.hasSuffix("transcription.failed"){fail("transcription-failed")}
    }
    func stop(){if connecting {cancel();return};guard recording || evaluating else{return};if !transcript.isEmpty{finish();return};userStopped=true;recording=false;evaluating=true;transport?.setMicrophoneEnabled(false);schedule(2500)}
    func cancel(){epoch=UUID();meter?.cancel();meter=nil;audioLevel=0;setup?.cancel();finishTimer?.cancel();limit?.cancel();deadline?.cancel();transport?.close();transport=nil;completion=nil;connecting=false;recording=false;evaluating=false;speechStarted=nil;heardSpeech=false;waitingForEnd=false;userStopped=false}
    private func schedule(_ milliseconds:Int){finishTimer?.cancel();let token=epoch;finishTimer=Task{try? await Task.sleep(for:.milliseconds(milliseconds));if !Task.isCancelled,epoch == token{finish()}}}
    private func finish(){let text=transcript,callback=completion;if text.isEmpty{fail("no-speech");return};cancel();callback?(text)}
    private func fail(_ code:String){cancel();error=code}
}
