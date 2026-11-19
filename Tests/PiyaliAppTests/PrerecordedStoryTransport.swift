import Foundation
@testable import Piyali

/// QA-only: uses native RTC and a fixed public PCM clip. No microphone track is created or enabled.
@MainActor final class PrerecordedStoryTransport:RealtimeVoiceTransport{
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    private let rtc=RealtimeRTCTransport(capturesMicrophone:false),pcm:Data
    private var work:Task<Void,Never>?
    private(set) var eventTypes:[String]=[],errorCodes:[String]=[],sentAudioBytes=0,microphoneRequests:[Bool]=[]
    init(wav:Data)throws{
        guard wav.count>44,String(data:wav.prefix(4),encoding:.ascii)=="RIFF",String(data:wav[8..<12],encoding:.ascii)=="WAVE"else{throw StoryFailure.invalid}
        var offset=12,found:Data?
        while offset+8<=wav.count{let size=Int(wav[offset+4..<offset+8].enumerated().reduce(UInt32(0)){$0|UInt32($1.element) << UInt32($1.offset*8)}),end=offset+8+size;guard end<=wav.count else{throw StoryFailure.invalid};if String(data:wav[offset..<offset+4],encoding:.ascii)=="data"{found=Data(wav[offset+8..<end]);break};offset=end+size%2}
        guard let found,!found.isEmpty else{throw StoryFailure.invalid};pcm=found
    }
    func connect(session:JSONValue)async throws{
        rtc.onOpen={[weak self] in self?.onOpen?()};rtc.onEvent={[weak self] event in guard let self else{return};self.eventTypes.append(event["type"].string);if event["type"].string == "error"{self.errorCodes.append(event["error"]["code"].string)};self.onEvent?(event)};rtc.onFailure={[weak self] message in self?.onFailure?(message)};try await rtc.connect(session:session)
    }
    func send(_ event:JSONValue)->Bool{rtc.send(event)}
    func setRemoteAudioEnabled(_ enabled:Bool){rtc.setRemoteAudioEnabled(false)}
    func setMicrophoneEnabled(_ enabled:Bool){microphoneRequests.append(enabled);guard enabled else{return}
        work=Task{var bytes=pcm;bytes.append(Data(repeating:0,count:24000*2*3));var offset=0
            while offset<bytes.count,!Task.isCancelled{let end=min(bytes.count,offset+4800),audio=bytes[offset..<end];guard rtc.send(.object(["type":.string("input_audio_buffer.append"),"audio":.string(audio.base64EncodedString())]))else{onFailure?("fixture-send");return};sentAudioBytes+=audio.count;offset=end;try? await Task.sleep(for:.milliseconds(100))}
        }
    }
    func audioAmplitude(speaking:Bool)async->Double{0}
    func close(){work?.cancel();work=nil;rtc.close()}
}
