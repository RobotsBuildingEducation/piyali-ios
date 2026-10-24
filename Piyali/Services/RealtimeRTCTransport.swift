import Foundation
import AVFoundation
import FirebaseAuth
import WebRTC

@MainActor protocol RealtimeVoiceTransport:AnyObject {
    var onOpen:(()->Void)? { get set }
    var onEvent:((JSONValue)->Void)? { get set }
    var onFailure:((String)->Void)? { get set }
    func connect(session:JSONValue) async throws
    @discardableResult func send(_ event:JSONValue)->Bool
    func setMicrophoneEnabled(_ enabled:Bool)
    func setRemoteAudioEnabled(_ enabled:Bool)
    func playbackDrainMilliseconds() async ->Double
    func audioAmplitude(speaking:Bool) async ->Double
    func close()
}
extension RealtimeVoiceTransport { func playbackDrainMilliseconds() async ->Double {1000};func audioAmplitude(speaking:Bool) async ->Double { 0 } }

/// Native WebRTC media and oai-events data channel. Only an SDP offer is sent
/// through Cloudflare; the standard provider key never enters the app.
@MainActor final class RealtimeRTCTransport:NSObject,RealtimeVoiceTransport {
    enum Purpose:String {case conversation,narration}
    var onOpen:(()->Void)?
    var onEvent:((JSONValue)->Void)?
    var onFailure:((String)->Void)?
    private let factory=RTCPeerConnectionFactory()
    private let configuration:AppConfiguration
    private var peer:RTCPeerConnection?,channel:RTCDataChannel?,microphone:RTCAudioTrack?,sender:RTCRtpSender?
    private var ownsAudio=false,closed=false
    private let capturesMicrophone:Bool,activatesPlayback:Bool
    private let purpose:Purpose
    init(configuration:AppConfiguration=AppConfiguration(),capturesMicrophone:Bool=true,activatesPlayback:Bool=true,purpose:Purpose = .conversation) { self.configuration=configuration;self.capturesMicrophone=capturesMicrophone;self.activatesPlayback=activatesPlayback;self.purpose=purpose;super.init() }
    func connect(session:JSONValue) async throws {
        closed=false
        if capturesMicrophone || activatesPlayback {
            let audio=RTCAudioSession.sharedInstance();audio.lockForConfiguration();defer { audio.unlockForConfiguration() }
            let config=RTCAudioSessionConfiguration.webRTC();config.category=AVAudioSession.Category.playAndRecord.rawValue;config.mode=AVAudioSession.Mode.voiceChat.rawValue;config.categoryOptions=[.defaultToSpeaker,.allowBluetoothHFP]
            // WebRTC's voice-processing audio unit uses its standard audio
            // session even for a receive-only track; no input sender is added.
            try audio.setConfiguration(config,active:true);ownsAudio=true
        }
        let config=RTCConfiguration();config.sdpSemantics = .unifiedPlan
        let constraints=RTCMediaConstraints(mandatoryConstraints:nil,optionalConstraints:nil)
        guard let peer=factory.peerConnection(with:config,constraints:constraints,delegate:self) else { throw AppError.message("A voice connection could not be created.") }
        self.peer=peer
        if capturesMicrophone {
            let source=factory.audioSource(with:RTCMediaConstraints(mandatoryConstraints:nil,optionalConstraints:["echoCancellation":"true","noiseSuppression":"true","autoGainControl":"true"]))
            let microphone=factory.audioTrack(with:source,trackId:"piyali-microphone");microphone.isEnabled=false;self.microphone=microphone
            sender=peer.add(microphone,streamIds:["piyali-voice"])
        } else {
            let receive=RTCRtpTransceiverInit();receive.direction = .recvOnly
            peer.addTransceiver(of:.audio,init:receive)
        }
        guard let channel=peer.dataChannel(forLabel:"oai-events",configuration:RTCDataChannelConfiguration()) else { throw AppError.message("The voice event channel could not be created.") }
        self.channel=channel;channel.delegate=self
        let offer:RTCSessionDescription=try await withCheckedThrowingContinuation { continuation in
            peer.offer(for:constraints) { description,error in
                if let error { continuation.resume(throwing:error) }
                else if let description { continuation.resume(returning:description) }
                else { continuation.resume(throwing:AppError.message("A voice offer could not be created.")) }
            }
        }
        try check(peer)
        try await withCheckedThrowingContinuation { (continuation:CheckedContinuation<Void,Error>) in peer.setLocalDescription(offer) { error in if let error { continuation.resume(throwing:error) } else { continuation.resume() } } }
        try check(peer)
        let answer=try await exchange(offer.sdp,session:session)
        try check(peer)
        try await withCheckedThrowingContinuation { (continuation:CheckedContinuation<Void,Error>) in peer.setRemoteDescription(RTCSessionDescription(type:.answer,sdp:answer)) { error in if let error { continuation.resume(throwing:error) } else { continuation.resume() } } }
        try check(peer)
    }
    private func check(_ peer:RTCPeerConnection) throws { if closed || self.peer !== peer || Task.isCancelled { throw CancellationError() } }
    private func exchange(_ sdp:String,session:JSONValue) async throws ->String {
        guard FirebaseService.shared.configured else { throw AppError.message("Configure Piyali's Firebase app before starting live conversation.") }
        guard let user=Auth.auth().currentUser else { throw AppError.message("Sync your account before starting live conversation.") }
        var request=URLRequest(url:configuration.worker.appendingPathComponent("realtime"));request.httpMethod="POST";request.timeoutInterval=35
        request.setValue("application/json",forHTTPHeaderField:"Content-Type")
        for (key,value) in try await FirebaseService.shared.appCheckHeaders() { request.setValue(value,forHTTPHeaderField:key) }
        request.setValue("Bearer "+(try await user.getIDToken()),forHTTPHeaderField:"Authorization")
        // The source narration session sends its model alongside the SDP. The
        // native worker requires the fixed model inside its normalized session.
        let normalized=session["model"].string.isEmpty ? session.setting("model",.string(configuration.string("RealtimeModel",default:"gpt-realtime-2.1-mini"))):session
        request.httpBody=try JSONEncoder().encode(JSONValue.object(["sdp":.string(sdp),"session":normalized,"purpose":.string(purpose.rawValue)]))
        let (data,response)=try await URLSession.shared.data(for:request)
        guard let http=response as? HTTPURLResponse else { throw AppError.message("Live conversation could not connect. Try again.") }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 429 { throw AppError.message("Live conversation is busy. Try again shortly.") }
            if [401,403].contains(http.statusCode) { throw AppError.message("Your online session expired. Sync your account, then try again.") }
            throw AppError.message("Live conversation could not connect. Try again.")
        }
        guard data.count <= 65536,let answer=String(data:data,encoding:.utf8),answer.hasPrefix("v=0"),answer.contains("m=audio ") else { throw AppError.message("Live conversation returned an invalid connection.") }
        return answer
    }
    @discardableResult func send(_ event:JSONValue)->Bool {
        guard !closed,channel?.readyState == .open,let data=try? JSONEncoder().encode(event) else { return false }
        return channel?.sendData(RTCDataBuffer(data:data,isBinary:false)) == true
    }
    func setMicrophoneEnabled(_ enabled:Bool) {
        let enabled=enabled && capturesMicrophone && !closed
        microphone?.isEnabled=enabled;sender?.track=enabled ? microphone : nil
    }
    func setRemoteAudioEnabled(_ enabled:Bool) { for receiver in peer?.receivers ?? [] { receiver.track?.isEnabled=enabled } }
    func audioAmplitude(speaking:Bool) async ->Double {
        guard let peer,!closed else { return 0 }
        let rms:Double=await withCheckedContinuation { continuation in peer.statistics { report in
            let levels=report.statistics.values.filter { stat in
                stat.type == (speaking ? "inbound-rtp" : "media-source") && ((stat.values["kind"] as? String) == "audio" || (stat.values["mediaType"] as? String) == "audio")
            }.compactMap { ($0.values["audioLevel"] as? NSNumber)?.doubleValue }.filter { $0.isFinite }
            continuation.resume(returning:levels.max() ?? 0)
        } }
        guard !closed,self.peer === peer else {return 0};return min(1,max(0,rms))
    }
    func playbackDrainMilliseconds() async ->Double {
        guard let peer,!closed else{return 1000}
        return await withCheckedContinuation {continuation in
            var resumed=false
            let timeout=Task{try? await Task.sleep(for:.milliseconds(500));if !Task.isCancelled,!resumed{resumed=true;continuation.resume(returning:1000)}}
            peer.statistics{report in Task{@MainActor in
                guard !resumed else{return};resumed=true;timeout.cancel();var tail=1000.0
                for stat in report.statistics.values where stat.type == "inbound-rtp" {
                    let count=(stat.values["jitterBufferEmittedCount"] as? NSNumber)?.doubleValue ?? 0
                    if count>0 {let delay=max((stat.values["jitterBufferDelay"] as? NSNumber)?.doubleValue ?? 0,(stat.values["jitterBufferTargetDelay"] as? NSNumber)?.doubleValue ?? 0)/count;tail=max(tail,delay*1000+500)}
                }
                continuation.resume(returning:tail)
            }}
        }
    }
    func receivedAudioBytes() async ->Int {
        guard let peer else { return 0 }
        return await withCheckedContinuation { continuation in peer.statistics { report in
            let bytes=report.statistics.values.filter { $0.type == "inbound-rtp" && (($0.values["kind"] as? String) == "audio" || ($0.values["mediaType"] as? String) == "audio") }.reduce(0) { $0+(($1.values["bytesReceived"] as? NSNumber)?.intValue ?? 0) }
            continuation.resume(returning:bytes)
        } }
    }
    func close() {
        closed=true;setMicrophoneEnabled(false);channel?.delegate=nil;channel?.close();channel=nil
        peer?.delegate=nil;peer?.close();peer=nil;sender=nil;microphone=nil
        if ownsAudio { let audio=RTCAudioSession.sharedInstance();audio.lockForConfiguration();try? audio.setActive(false);audio.unlockForConfiguration();ownsAudio=false }
    }
}

extension RealtimeRTCTransport:RTCPeerConnectionDelegate,RTCDataChannelDelegate {
    nonisolated func dataChannelDidChangeState(_ dataChannel:RTCDataChannel) {
        Task { @MainActor [weak self] in guard let self,!self.closed,self.channel === dataChannel else { return };if dataChannel.readyState == .open { self.onOpen?() } else if dataChannel.readyState == .closed { self.onFailure?("Live conversation disconnected. Try connecting again.") } }
    }
    nonisolated func dataChannel(_ dataChannel:RTCDataChannel,didReceiveMessageWith buffer:RTCDataBuffer) {
        guard buffer.data.count <= 131072,let event=try? JSONDecoder().decode(JSONValue.self,from:buffer.data) else { return }
        Task { @MainActor [weak self] in guard let self,!self.closed,self.channel === dataChannel else { return };self.onEvent?(event) }
    }
    nonisolated func peerConnection(_ peerConnection:RTCPeerConnection,didChange newState:RTCPeerConnectionState) {
        if newState == .failed || newState == .closed { Task { @MainActor [weak self] in guard let self,!self.closed,self.peer === peerConnection else { return };self.onFailure?("Live conversation disconnected. Try connecting again.") } }
    }
    nonisolated func peerConnection(_ peerConnection:RTCPeerConnection,didChange stateChanged:RTCSignalingState) {}
    nonisolated func peerConnection(_ peerConnection:RTCPeerConnection,didAdd stream:RTCMediaStream) {}
    nonisolated func peerConnection(_ peerConnection:RTCPeerConnection,didRemove stream:RTCMediaStream) {}
    nonisolated func peerConnectionShouldNegotiate(_ peerConnection:RTCPeerConnection) {}
    nonisolated func peerConnection(_ peerConnection:RTCPeerConnection,didChange newState:RTCIceConnectionState) {}
    nonisolated func peerConnection(_ peerConnection:RTCPeerConnection,didChange newState:RTCIceGatheringState) {}
    nonisolated func peerConnection(_ peerConnection:RTCPeerConnection,didGenerate candidate:RTCIceCandidate) {}
    nonisolated func peerConnection(_ peerConnection:RTCPeerConnection,didRemove candidates:[RTCIceCandidate]) {}
    nonisolated func peerConnection(_ peerConnection:RTCPeerConnection,didOpen dataChannel:RTCDataChannel) {}
}
