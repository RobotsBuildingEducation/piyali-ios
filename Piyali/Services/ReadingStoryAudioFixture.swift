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
    private var work:Task<Void,Never>?
    init(loadingOnly:Bool=false,fails:Bool=false){self.loadingOnly=loadingOnly;self.fails=fails}
    func connect(session:JSONValue)async throws{onOpen?()}
    func send(_ event:JSONValue)->Bool{
        guard event["type"].string == "response.create",!loadingOnly else{return true}
        work=Task{try? await Task.sleep(for:.milliseconds(150));guard !Task.isCancelled else{return};if fails{onFailure?("fixture");return};onEvent?(.object(["type":.string("output_audio_buffer.started")]));try? await Task.sleep(for:.milliseconds(650));guard !Task.isCancelled else{return};onEvent?(.object(["type":.string("response.done"),"response":.object(["status":.string("completed")])]));onEvent?(.object(["type":.string("output_audio_buffer.stopped")]))};return true
    }
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func setMicrophoneEnabled(_ enabled:Bool){}
    func playbackDrainMilliseconds()async->Double{10}
    func close(){work?.cancel();work=nil}
}
#endif
