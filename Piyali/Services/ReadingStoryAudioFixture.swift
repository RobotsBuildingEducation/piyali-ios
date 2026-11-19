import Foundation

@MainActor enum ReadingStoryAudioFixture {
    private static func enabled(_ key:String)->Bool{
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        return env["PIYALI_OFFLINE_TESTS"] == "1" && env["PIYALI_LIVE_API_TESTS"] != "1" && env[key] == "1" && UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil
        #else
        return false
        #endif
    }
    static func reading()->RealtimeNarrationService{
        #if DEBUG
        if enabled("PIYALI_READING_AUDIO_FIXTURE"){return RealtimeNarrationService(factory:{ReadingStoryFixtureTransport(loadingOnly:true)})}
        #endif
        return RealtimeNarrationService()
    }
    static func conversationStarter()->RealtimeNarrationService{
        #if DEBUG
        if enabled("PIYALI_CONVERSATION_FIXTURE"){
            return RealtimeNarrationService(factory:{ReadingStoryFixtureTransport(expectedVoice:"shimmer",playbackMilliseconds:2200)})
        }
        #endif
        return RealtimeNarrationService()
    }
    static func story()->StoryAudioTransport?{
        #if DEBUG
        if enabled("PIYALI_STORY_NARRATION_FIXTURE"){
            var attempt=0;let firstFails=ProcessInfo.processInfo.environment["PIYALI_STORY_AUDIO_FAIL_FIRST"] == "1"
            return NativeStoryAudio(narration:RealtimeNarrationService(factory:{attempt+=1;return ReadingStoryFixtureTransport(fails:firstFails && attempt == 1)}))
        }
        #endif
        return nil
    }
}
#if DEBUG
@MainActor private final class ReadingStoryFixtureTransport:RealtimeVoiceTransport{
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    private let loadingOnly:Bool,fails:Bool
    private let expectedVoice:String?
    private let playbackMilliseconds:Int
    private var voiceConfigured=false
    private var work:Task<Void,Never>?
    init(loadingOnly:Bool=false,fails:Bool=false,expectedVoice:String?=nil,playbackMilliseconds:Int=650){
        self.loadingOnly=loadingOnly;self.fails=fails;self.expectedVoice=expectedVoice;self.playbackMilliseconds=playbackMilliseconds
    }
    func connect(session:JSONValue)async throws{
        if let expectedVoice,session["audio"]["output"]["voice"].string != expectedVoice {
            throw AppError.message("Unexpected narration voice.")
        }
        onOpen?()
    }
    func send(_ event:JSONValue)->Bool{
        if let expectedVoice {
            if event["type"].string == "session.update" {
                voiceConfigured=event["session"]["audio"]["output"]["voice"].string == expectedVoice
            }
            if event["type"].string == "response.create",!voiceConfigured { return false }
        }
        guard event["type"].string == "response.create",!loadingOnly else{return true}
        work=Task{try? await Task.sleep(for:.milliseconds(150));guard !Task.isCancelled else{return};if fails{onFailure?("fixture");return};onEvent?(.object(["type":.string("output_audio_buffer.started")]));try? await Task.sleep(for:.milliseconds(playbackMilliseconds));guard !Task.isCancelled else{return};onEvent?(.object(["type":.string("response.done"),"response":.object(["status":.string("completed")])]));onEvent?(.object(["type":.string("output_audio_buffer.stopped")]))};return true
    }
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func setMicrophoneEnabled(_ enabled:Bool){}
    func playbackDrainMilliseconds()async->Double{10}
    func close(){work?.cancel();work=nil}
}
#endif
