import Foundation

@MainActor protocol StoryAudioTransport:AnyObject {
    func play(_ turn:StoryTurn,language:String,started:@escaping()->Void,finished:@escaping()->Void,failed:@escaping()->Void)
    func stop()
    func configure(user:JSONValue)
}
extension StoryAudioTransport { func configure(user:JSONValue){} }
@MainActor final class NativeStoryAudio:StoryAudioTransport {
    let narration:RealtimeNarrationService
    private let policy:ReadingStoryNarrationPolicy?
    private var user:JSONValue = .null
    init(narration:RealtimeNarrationService?=nil){self.narration=narration ?? RealtimeNarrationService();policy=try? ReadingStoryNarrationPolicy()}
    func configure(user:JSONValue){self.user=user}
    func play(_ turn:StoryTurn,language:String,started:@escaping()->Void,finished:@escaping()->Void,failed:@escaping()->Void){
        stop()
        do{guard let policy else{throw PracticeRecipeFailure.unavailable}
            let plan=try policy.request("story",.object(["language":.string(language),"turn":.object(["speaker":.string(turn.speaker),"target":.string(turn.target)]),"user":user]))
            narration.play(plan["request"]["text"].string,language:language,engine:nil,sessionOverride:plan["session"],cacheRequest:plan["request"],onStarted:started,onFailed:failed,onFinished:finished)
        }catch{failed()}
    }
    func stop(){narration.stopAll()}
}
#if DEBUG
/// Same playback controls and callbacks, with an isolated, bounded local player.
@MainActor private final class FixtureStoryAudio:StoryAudioTransport {
    private var task:Task<Void,Never>?
    private var count=0
    func play(_ turn:StoryTurn,language:String,started:@escaping()->Void,finished:@escaping()->Void,failed:@escaping()->Void) {
        stop();count += 1
        if ProcessInfo.processInfo.environment["PIYALI_STORY_AUDIO_FAIL_FIRST"] == "1",count == 1 { failed();return }
        started();task=Task { try? await Task.sleep(for:.milliseconds(150));guard !Task.isCancelled else { return };finished() }
    }
    func stop() { task?.cancel();task=nil }
}
#endif
@MainActor final class StoryPlaybackService:ObservableObject {
    enum Phase:String { case idle,loading,playing,awaitingSpeech,failed }
    @Published private(set) var phase:Phase = .idle
    @Published private(set) var currentTurn:StoryTurn?
    @Published private(set) var previewTurn:StoryTurn?
    @Published private(set) var previewPlaying=false
    @Published private(set) var previewError=false
    @Published private(set) var hasPlayed=false
    private(set) var roleIndex:Int?
    private let player:StoryAudioTransport
    private let previewPlayer:StoryAudioTransport
    private var generation=UUID(),previewGeneration=UUID()
    private var deadline:Task<Void,Never>?,previewDeadline:Task<Void,Never>?
    private var turns:[StoryTurn]=[],cursor=0,language="",learnerName="",replaying=false
    private var completion:(()->Void)?
    init(player:StoryAudioTransport?=nil,previewPlayer:StoryAudioTransport?=nil) {
        func make()->StoryAudioTransport {
            #if DEBUG
            if let fixture=ReadingStoryAudioFixture.story(){return fixture}
            if StoryService.fixtureMode != nil { return FixtureStoryAudio() }
            #endif
            return NativeStoryAudio()
        }
        self.player=player ?? make();self.previewPlayer=previewPlayer ?? make()
    }
    var active:Bool { phase == .loading || phase == .playing }
    func start(_ values:[StoryTurn],language:String,learnerName:String,replay:Bool=false,user:JSONValue = .null,completed:@escaping()->Void) {
        cancel();player.configure(user:user);previewPlayer.configure(user:user);hasPlayed=true;self.turns=values;self.language=language;self.learnerName=learnerName;replaying=replay;completion=completed;cursor=0;next()
    }
    func continueSpeech() { guard phase == .awaitingSpeech else { return };roleIndex=nil;cursor += 1;next() }
    func cancel(reset:Bool=false) {
        generation=UUID();deadline?.cancel();deadline=nil;completion=nil;player.stop();turns=[];roleIndex=nil;currentTurn=nil;phase = .idle
        stopPreview();previewError=false;if reset { hasPlayed=false }
    }
    func stopPreview() { previewGeneration=UUID();previewDeadline?.cancel();previewDeadline=nil;previewPlayer.stop();previewPlaying=false;previewTurn=nil }
    func preview(_ turn:StoryTurn,language:String,user:JSONValue = .null) {
        // A preview cannot finish the main queue or satisfy a pending user line.
        if active { generation=UUID();deadline?.cancel();deadline=nil;completion=nil;player.stop();phase = .idle;currentTurn=nil }
        stopPreview();previewPlayer.configure(user:user);previewError=false;let token=previewGeneration;previewTurn=turn;previewPlaying=true
        previewDeadline=Task { [weak self] in try? await Task.sleep(for:.seconds(90));guard !Task.isCancelled,self?.previewGeneration == token else { return };self?.stopPreview();self?.previewError=true }
        previewPlayer.play(turn,language:language,started:{},finished:{ [weak self] in guard self?.previewGeneration == token else { return };self?.stopPreview() },failed:{ [weak self] in guard self?.previewGeneration == token else { return };self?.stopPreview();self?.previewError=true })
    }
    private func next() {
        deadline?.cancel();deadline=nil
        while cursor < turns.count,replaying,StoryAppearance.isUser(turns[cursor].speaker,learnerName:learnerName) { cursor += 1 }
        guard cursor < turns.count else { phase = .idle;currentTurn=nil;roleIndex=nil;let done=completion;completion=nil;done?();return }
        let turn=turns[cursor];currentTurn=turn
        if !replaying,StoryAppearance.isUser(turn.speaker,learnerName:learnerName) { roleIndex=cursor;phase = .awaitingSpeech;return }
        phase = .loading;let token=generation,index=cursor;armDeadline(seconds:30,token:token,index:index)
        player.play(turn,language:language,started:{ [weak self] in
            guard let self,self.generation == token,self.cursor == index,self.phase == .loading else { return };self.phase = .playing;self.armDeadline(seconds:90,token:token,index:index)
        },finished:{ [weak self] in
            guard let self,self.generation == token,self.cursor == index,self.active else { return };self.cursor += 1;self.next()
        },failed:{ [weak self] in guard let self,self.generation == token,self.cursor == index else { return };self.fail() })
    }
    private func armDeadline(seconds:Double,token:UUID,index:Int) {
        deadline?.cancel();deadline=Task { [weak self] in try? await Task.sleep(for:.seconds(seconds));guard !Task.isCancelled,let self,self.generation == token,self.cursor == index,self.active else { return };self.fail() }
    }
    private func fail() { generation=UUID();deadline?.cancel();deadline=nil;completion=nil;player.stop();currentTurn=nil;roleIndex=nil;phase = .failed }
}
