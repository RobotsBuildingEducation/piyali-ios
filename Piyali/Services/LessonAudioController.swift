import Foundation
import Combine

/// Lesson playback owns one question at a time; provider callbacks never outlive that owner.
@MainActor final class LessonAudioController:ObservableObject {
    let narration:RealtimeNarrationService
    private var observation:AnyCancellable?
    private(set) var owner:String?
    private(set) var wordIndex:Int?
    var loading:Bool{narration.loading}
    var playing:Bool{narration.playing}
    init(narration:RealtimeNarrationService?=nil){
        self.narration=narration ?? LessonAudioFixture.narration()
        observation=self.narration.objectWillChange.sink{[weak self] _ in self?.objectWillChange.send()}
    }
    func bind(_ owner:String){guard self.owner != owner else{return};stop();self.owner=owner}
    func play(_ text:String,language:String,owner:String,wordIndex:Int?=nil,spokenCard:Bool=false,ignoreWhileLoading:Bool=false,engine:CompanionQuestPolicy?){
        guard self.owner == owner,!(ignoreWhileLoading && loading) else{return}
        // Original question playback replaces blanks; spoken targets and card answers are verbatim.
        let text=Self.prepare(text,verbatim:spokenCard || wordIndex != nil)
        guard !text.isEmpty else{return}
        if let wordIndex,self.wordIndex == wordIndex,loading{stop();return}
        stop();self.wordIndex=wordIndex
        narration.play(text,language:language,engine:engine,voice:"ash")
    }
    static func prepare(_ text:String,verbatim:Bool)->String{
        // ECMAScript trim, including BOM and excluding NEXT LINE, as in both source modules.
        let whitespace=CharacterSet(charactersIn:"\u{0009}\u{000A}\u{000B}\u{000C}\u{000D} \u{00A0}\u{1680}\u{2000}\u{2001}\u{2002}\u{2003}\u{2004}\u{2005}\u{2006}\u{2007}\u{2008}\u{2009}\u{200A}\u{2028}\u{2029}\u{202F}\u{205F}\u{3000}\u{FEFF}")
        let trimmed=text.trimmingCharacters(in:whitespace)
        return verbatim ? trimmed:trimmed.replacingOccurrences(of:"___",with:" … ")
    }
    func stop(){narration.stopAll();wordIndex=nil;objectWillChange.send()}
    func clear(){stop();owner=nil}
}

@MainActor private enum LessonAudioFixture {
    static func narration()->RealtimeNarrationService{
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        if env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_LIVE_API_TESTS"] != "1",env["PIYALI_LESSON_AUDIO_FIXTURE"] == "loading",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil{return RealtimeNarrationService(factory:{LessonLoadingTransport()})}
        if env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_LIVE_API_TESTS"] != "1",env["PIYALI_LESSON_AUDIO_FIXTURE"] == "cache",let scope=env["PIYALI_TEST_IDENTITY_SCOPE"],UUID(uuidString:scope) != nil {
            let root=FileManager.default.urls(for:.cachesDirectory,in:.userDomainMask)[0].appendingPathComponent("piyali-lesson-cache-fixture-"+scope,isDirectory:true)
            return RealtimeNarrationService(factory:{LessonCacheTransport()},cache:NarrationAudioCache(directory:root),replayFactory:{NarrationReplayPlayer(volume:0)})
        }
        #endif
        return RealtimeNarrationService()
    }
}
#if DEBUG
@MainActor private final class LessonLoadingTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    func connect(session:JSONValue)async throws{onOpen?()}
    func send(_ event:JSONValue)->Bool{true}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func setMicrophoneEnabled(_ enabled:Bool){}
    func close(){}
}
#endif

#if DEBUG
@MainActor private final class LessonCacheTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    private var work:Task<Void,Never>?
    func connect(session:JSONValue)async throws{onOpen?()}
    func send(_ event:JSONValue)->Bool{if event["type"].string == "response.create"{work=Task{try? await Task.sleep(for:.seconds(4));guard !Task.isCancelled else{return};onEvent?(.object(["type":.string("output_audio_buffer.started")]));try? await Task.sleep(for:.seconds(4));guard !Task.isCancelled else{return};onEvent?(.object(["type":.string("response.done"),"response":.object(["status":.string("completed")])]));onEvent?(.object(["type":.string("output_audio_buffer.stopped")]))}};return true}
    func setMicrophoneEnabled(_ enabled:Bool){}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func playbackDrainMilliseconds()async->Double{0}
    func completedNarrationRecording()->NarrationRecording?{var data=Data();for i in 0..<96000{let sample:Int16=i>=4800 && i<91200 ? Int16(sin(Double(i)*440*2*Double.pi/24000)*6000):0;var value=sample.littleEndian;withUnsafeBytes(of:&value){data.append(contentsOf:$0)}};return .init(pcm16:data,sampleRate:24000,channels:1)}
    func close(){work?.cancel();work=nil}
}
#endif
