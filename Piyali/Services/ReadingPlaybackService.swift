import Foundation
import Combine

@MainActor final class ReadingPlaybackService:ObservableObject {
    @Published private(set) var activeSentence:Int?
    @Published private(set) var readingAll=false
    let narration:RealtimeNarrationService
    private let policy:ReadingStoryNarrationPolicy?
    private var observation:AnyCancellable?,epoch=UUID()
    var loading:Bool{narration.loading}
    init(narration:RealtimeNarrationService?=nil){self.narration=narration ?? ReadingStoryAudioFixture.reading();policy=try? ReadingStoryNarrationPolicy();observation=self.narration.objectWillChange.sink{[weak self] _ in self?.objectWillChange.send()}}
    func play(_ text:String,language:String,sentence:Int?=nil){
        stop();guard !text.isEmpty else{return};activeSentence=sentence;readingAll=sentence == nil;let token=epoch
        do{guard let policy else{throw PracticeRecipeFailure.unavailable};let plan=try policy.request("reading",.object(["text":.string(text),"language":.string(language)]))
            narration.play(plan["request"]["text"].string,language:language,engine:nil,sessionOverride:plan["session"],cacheRequest:plan["request"],onFailed:{[weak self] in guard self?.epoch == token else{return};self?.stop()},onFinished:{[weak self] in guard self?.epoch == token else{return};self?.stop()})
        }catch{stop()}
    }
    func stop(){epoch=UUID();narration.stopAll();readingAll=false;activeSentence=nil}
}
