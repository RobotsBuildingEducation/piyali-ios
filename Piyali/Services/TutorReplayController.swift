import Foundation

/// Mirrors playSavedClip: stop the previous reply, use its saved original
/// recording, otherwise narrate the source-selected visible text/voice/language.
@MainActor final class TutorReplayController:ObservableObject {
    @Published private(set) var activeID:String?
    @Published private(set) var error:String?
    private(set) var playbackSource:String?
    private let narration:RealtimeNarrationService
    private var task:Task<Void,Never>?,epoch=UUID(),duck:((Bool)->Void)?
    private var policy:TutorReplayPolicy?
    typealias Lookup=(String,TutorAudioClips.Scope)async->Data?
    private let lookup:Lookup?
    init(narration:RealtimeNarrationService?=nil,lookup:Lookup?=nil){self.narration=narration ?? RealtimeNarrationService();self.lookup=lookup}
    func play(_ id:String,messages:[JSONValue],target:String,voice:String,scope:TutorAudioClips.Scope,clips:TutorAudioClips,engine:CompanionQuestPolicy?,live:Bool,duck:@escaping(Bool)->Void){
        let same=activeID == id;stop();guard !same,!id.isEmpty else{return}
        activeID=id;error=nil;playbackSource=nil;self.duck=duck;let token=epoch
        narration.reserve{[weak self] in self?.finish(token)}
        task=Task{[weak self] in guard let self else{return}
            let wav:Data?
            if let lookup{wav=await lookup(id,scope)}else{wav=await clips.load(id,scope:scope)}
            guard epoch == token,!Task.isCancelled else{return}
            narration.onStopped=nil
            let done:()->Void={ [weak self] in self?.finish(token) }
            if let wav{
                duck(true);playbackSource="recorded"
                narration.playRecording(wav,preservingAudioSession:live,onFinished:done,onFailed:{[weak self] in self?.fail(token)})
            }else{
                do{
                    if policy == nil{policy=try TutorReplayPolicy()}
                    guard let plan=try policy?.plan(.object(["id":.string(id),"messages":.array(messages),"target":.string(target),"voice":.string(voice)])),plan != .null else{finish(token);return}
                    duck(true);playbackSource="synthesized"
                    narration.play(plan["text"].string,language:plan["language"].string,engine:engine,voice:plan["voice"].string,onFailed:{[weak self] in self?.fail(token)},onFinished:done)
                }catch{fail(token)}
            }
            if epoch == token,activeID != nil{narration.onStopped=done}
        }
    }
    private func finish(_ token:UUID){guard epoch == token else{return};stop()}
    private func fail(_ token:UUID){guard epoch == token else{return};stop();error="Narration could not play. Try again."}
    func stop(){epoch=UUID();task?.cancel();task=nil;narration.onStopped=nil;narration.stopAll();activeID=nil;let callback=duck;duck=nil;callback?(false)}
}
