import Foundation
import Combine

/// Story capture uses the source caller options and strict completed-transcript metadata.
@MainActor final class StorySpeechController:ObservableObject {
    let recorder:SpeechPracticeService
    private var options:StorySpeechPolicy?,speechPolicy:FlashcardPolicy?,owner:String?,changes:AnyCancellable?
    init(recorder:SpeechPracticeService?=nil){self.recorder=recorder ?? StorySpeechFixture.recorder();changes=self.recorder.objectWillChange.sink{[weak self] _ in self?.objectWillChange.send()}}
    private func scope(_ app:AppModel,_ run:StoryRun,target:String,role:Int?)->String{[app.identity.npub,app.learner.target,app.learner.support,app.learner.level,run.id.uuidString,String(run.index),String(role ?? -1),target].joined(separator:"|")}
    func cancel(){owner=nil;recorder.cancel();recorder.clearError()}
    func stop(){recorder.stop()}
    func start(_ app:AppModel,run:StoryRun,target:String,role:Int?,allowed:@escaping()->Bool,result:@escaping(JSONValue)->Void){
        guard allowed(),!recorder.connecting,!recorder.recording,!recorder.evaluating,let current=app.learner.story,current.id == run.id,current.index == run.index,!current.completed,!current.atEnd else{return}
        if run.mode == .speaking{guard role == nil,current.currentSentence?.target == target else{return}}
        else{guard let role,let segment=current.currentSegment,segment.turns.indices.contains(role),segment.turns[role].target == target,StoryAppearance.isUser(segment.turns[role].speaker,learnerName:app.learner.name)else{return}}
        cancel();let captured=scope(app,current,target:target,role:role);owner=captured
        do{if options == nil{options=try StorySpeechPolicy()};if speechPolicy == nil{speechPolicy=try FlashcardPolicy()};let config=try options!.options(mode:run.mode,target:target,language:run.target,user:app.learner.settingsSnapshot,awaiting:role != nil)
            #if DEBUG
            StorySpeechFixture.prepare(target)
            #endif
            recorder.start(target:config["targetLang"].string,policy:speechPolicy!,transcriptionHint:config["transcriptionHint"].string,timeoutMs:Int(config["timeoutMs"].number)){[weak self] text in
                guard let self,self.owner == captured else{return};self.owner=nil
                guard allowed(),let current=app.learner.story,current.id == run.id,current.index == run.index,!current.completed,self.scope(app,current,target:target,role:role) == captured else{return}
                do{let metadata=try self.options!.result(text);guard !metadata["recognizedText"].string.isEmpty else{self.recorder.reportError("no-speech");return};result(metadata)}catch{self.recorder.reportError("transcription-failed")}
            }
        }catch{recorder.reportError("connection-failed")}
    }
}

@MainActor private enum StorySpeechFixture {
    static func recorder()->SpeechPracticeService{
        #if DEBUG
        if enabled{return SpeechPracticeService(transportFactory:{StorySpeechFixtureTransport()},permission:{ProcessInfo.processInfo.environment["PIYALI_STORY_SPEECH_DENIED"] != "1"})}
        #endif
        return SpeechPracticeService()
    }
    #if DEBUG
    static var target="",attempt=0
    private static var enabled:Bool{let e=ProcessInfo.processInfo.environment;return e["PIYALI_OFFLINE_TESTS"] == "1" && e["PIYALI_LIVE_API_TESTS"] != "1" && e["PIYALI_STORY_SPEECH_RESULTS"] != nil && UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil}
    static func prepare(_ target:String){guard enabled else{return};self.target=target}
    static func transcript()->String{let entries=ProcessInfo.processInfo.environment["PIYALI_STORY_SPEECH_RESULTS"]?.split(separator:",").map(String.init) ?? ["pass"],sequence=entries.isEmpty ? ["pass"]:entries;let value=sequence[min(attempt,sequence.count-1)];return value == "miss" ? "wrong phrase":target}
    #endif
}
#if DEBUG
@MainActor private final class StorySpeechFixtureTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    private var work:Task<Void,Never>?
    func connect(session:JSONValue)async throws{
        let delay=Int(ProcessInfo.processInfo.environment["PIYALI_STORY_SPEECH_OPEN_DELAY_MS"] ?? "0") ?? 0
        if delay>0{try await Task.sleep(for:.milliseconds(delay))};try Task.checkCancellation();onOpen?()
    }
    func send(_ event:JSONValue)->Bool{true}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    private var pending:String?
    func setMicrophoneEnabled(_ enabled:Bool){
        if enabled{pending=StorySpeechFixture.transcript();if ProcessInfo.processInfo.environment["PIYALI_STORY_SPEECH_AUTOFINISH"] != "1"{return}}
        guard let text=pending else{return};pending=nil
        work=Task{try? await Task.sleep(for:.milliseconds(20));guard !Task.isCancelled else{return};StorySpeechFixture.attempt+=1;onEvent?(.object(["type":.string("input_audio_transcription.completed"),"transcript":.string(text)]))}
    }
    func audioAmplitude(speaking:Bool)async->Double{0.08}
    func close(){work?.cancel();work=nil}
}
#endif
