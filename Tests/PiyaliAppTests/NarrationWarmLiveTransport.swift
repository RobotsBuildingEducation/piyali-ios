import Foundation
@testable import Piyali

@MainActor final class NarrationWarmLiveTransport:RealtimeVoiceTransport{
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    let rtc:RealtimeRTCTransport
    private(set) var sends:[String]=[],voices:[String]=[],microphone:[Bool]=[],responses=0
    init(deferred:Bool){rtc=RealtimeRTCTransport(capturesMicrophone:false,activatesPlayback:!deferred,purpose:.narration,recordsNarration:true);rtc.setOutputGain(0)}
    var narrationReceiverReady:Bool{rtc.narrationReceiverReady}
    func connect(session:JSONValue)async throws{rtc.onOpen={[weak self] in self?.onOpen?()};rtc.onFailure={[weak self] value in self?.onFailure?(value)};rtc.onEvent={[weak self] event in guard let self else{return};if event["type"].string == "session.updated"{voices.append(event["session"]["audio"]["output"]["voice"].string)};if event["type"].string == "response.created"{responses+=1};onEvent?(event)};try await rtc.connect(session:session)}
    func send(_ event:JSONValue)->Bool{sends.append(event["type"].string);return rtc.send(event)}
    func setMicrophoneEnabled(_ enabled:Bool){microphone.append(enabled);rtc.setMicrophoneEnabled(enabled)}
    func setRemoteAudioEnabled(_ enabled:Bool){rtc.setRemoteAudioEnabled(enabled)}
    func activateNarrationOutput()throws{try rtc.activateNarrationOutput()}
    func completedNarrationRecording()->NarrationRecording?{rtc.completedNarrationRecording()}
    func playbackDrainMilliseconds()async->Double{await rtc.playbackDrainMilliseconds()}
    func audioAmplitude(speaking:Bool)async->Double{await rtc.audioAmplitude(speaking:speaking)}
    func close(){rtc.close()}
}
