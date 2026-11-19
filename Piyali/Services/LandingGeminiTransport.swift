import Foundation
import AVFoundation
import FirebaseAILogic

/// Native Gemini bridge for the public lesson; emits the source controller's
/// playback-complete protocol instead of treating server completion as playback.
@MainActor final class LandingGeminiTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    private let lease=UUID(),engine=AVAudioEngine(),player=AVAudioPlayerNode()
    private let output=AVAudioFormat(commonFormat:.pcmFormatFloat32,sampleRate:24000,channels:1,interleaved:false)!
    private var session:LiveSession?,receiver:Task<Void,Never>?,sender:Task<Void,Never>?,request:Task<Void,Never>?
    private struct Frame:Sendable {let bytes:Data;let amplitude:Double}
    private var continuation:AsyncStream<Frame>.Continuation?
    private var gate=LandingGeminiGate(),closed=false,tapped=false,ownsAudio=false,inputAmplitude=0.0,amplitudes:[(UUID,Double)]=[]
    func connect(session config:JSONValue) async throws {
        guard FirebaseService.shared.configured else {throw AppError.message("Live practice is unavailable.")}
        let app=try await LandingDemoIdentity.connect(owner:lease)
        guard !closed else {LandingDemoIdentity.disconnect(owner:lease);throw CancellationError()}
        let connection=try await LandingDemoService.model(target:config["targetLang"].string,support:config["supportLang"].string,app:app).connect()
        guard !closed else {await connection.close();throw CancellationError()};session=connection
        do {try setupAudio(connection)} catch {onFailure?("microphoneUnavailable");close();throw error}
        receiver=Task { [weak self] in
            do {
                for try await response in connection.responses {
                    guard let self,!self.closed,!Task.isCancelled else {return}
                    if case .content(let content)=response.payload {
                        var packet=LandingGeminiPacket();packet.input=content.inputAudioTranscription?.text ?? "";packet.transcript=content.outputAudioTranscription?.text ?? "";packet.hasModel=content.modelTurn != nil;packet.complete=content.isTurnComplete;packet.interrupted=content.wasInterrupted
                        for part in content.modelTurn?.parts ?? [] {if let audio=part as? InlineDataPart,audio.mimeType.hasPrefix("audio/pcm") {packet.audio.append(audio.data)} else if let text=part as? TextPart {packet.fallback += text.text}}
                        self.apply(self.gate.receive(packet))
                    }
                }
                if let self,!self.closed {self.onFailure?("unavailable")}
            } catch {if let self,!self.closed,!Task.isCancelled {self.onFailure?("unavailable")}}
        }
        onOpen?()
    }
    func send(_ event:JSONValue)->Bool {
        guard !closed,let session,event["type"].string == "response.create" else {return false}
        let instructions=event["response"]["instructions"].string;guard !instructions.isEmpty else {return false}
        gate.requested(UUID().uuidString)
        request=Task { [weak self] in guard let self,!self.closed,!Task.isCancelled else {return};await session.sendContent(instructions,turnComplete:true) }
        return true
    }
    func setMicrophoneEnabled(_ enabled:Bool) {gate.enableInput(enabled && !closed);if !enabled {inputAmplitude=0}}
    func setRemoteAudioEnabled(_ enabled:Bool) {player.volume=enabled ? 1 : 0}
    func audioAmplitude(speaking:Bool) async ->Double {guard !closed else {return 0};return speaking ? (player.isPlaying ? amplitudes.first?.1 ?? 0 : 0) : (gate.inputEnabled ? inputAmplitude : 0)}
    private func apply(_ actions:[LandingGeminiGate.Action]) {
        for action in actions {
            guard !closed else {return}
            switch action {
            case .event(let event):onEvent?(event)
            case .play(let bytes,let ticket):play(bytes,ticket:ticket)
            case .stopAudio:amplitudes=[];player.stop();player.play()
            case .failure:onFailure?("unavailable")
            }
        }
    }
    private func setupAudio(_ connection:LiveSession) throws {
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord,mode:.voiceChat,options:[.defaultToSpeaker,.allowBluetoothHFP]);try AVAudioSession.sharedInstance().setActive(true);ownsAudio=true
        engine.attach(player);engine.connect(player,to:engine.mainMixerNode,format:output)
        let input=engine.inputNode;try input.setVoiceProcessingEnabled(true);let source=input.outputFormat(forBus:0)
        guard source.sampleRate>0,let pcm=AVAudioFormat(commonFormat:.pcmFormatInt16,sampleRate:16000,channels:1,interleaved:false),let converter=AVAudioConverter(from:source,to:pcm) else {throw AppError.message("Microphone unavailable")}
        let stream=AsyncStream<Frame>(bufferingPolicy:.bufferingNewest(20)){continuation=$0},sink=continuation
        input.installTap(onBus:0,bufferSize:2048,format:source) {buffer,_ in
            guard let converted=AVAudioPCMBuffer(pcmFormat:pcm,frameCapacity:AVAudioFrameCount(Double(buffer.frameLength)*16000/source.sampleRate)+1) else {return}
            var consumed=false,error:NSError?
            converter.convert(to:converted,error:&error){_,state in if consumed {state.pointee = .noDataNow;return nil};consumed=true;state.pointee = .haveData;return buffer}
            if error == nil,let samples=converted.int16ChannelData?[0],converted.frameLength>0 {
                var sum=0.0,squares=0.0;let count=Int(converted.frameLength)
                for i in 0..<count {let v=Double(samples[i])/32768;sum += v;squares += v*v}
                sink?.yield(Frame(bytes:Data(bytes:samples,count:count*2),amplitude:sqrt(max(0,squares/Double(count)-pow(sum/Double(count),2)))))
            }
        }
        tapped=true
        sender=Task { [weak self] in for await frame in stream {guard let self,!self.closed,!Task.isCancelled else {return};if self.gate.inputEnabled {self.inputAmplitude=frame.amplitude;await connection.sendAudioRealtime(frame.bytes)}} }
        engine.prepare();try engine.start();player.play()
    }
    private func play(_ bytes:Data,ticket:UUID) {
        let count=bytes.count/2
        guard count>0,let buffer=AVAudioPCMBuffer(pcmFormat:output,frameCapacity:AVAudioFrameCount(count)),let samples=buffer.floatChannelData?[0] else {apply(gate.played(ticket));return}
        buffer.frameLength=AVAudioFrameCount(count);var sum=0.0,squares=0.0
        bytes.withUnsafeBytes {raw in for i in 0..<count {let value=Double(Int16(littleEndian:raw.loadUnaligned(fromByteOffset:i*2,as:Int16.self)))/32768;samples[i]=Float(value);sum += value;squares += value*value}}
        amplitudes.append((ticket,sqrt(max(0,squares/Double(count)-pow(sum/Double(count),2)))))
        player.scheduleBuffer(buffer,completionCallbackType:.dataPlayedBack) { [weak self] _ in Task { @MainActor in guard let self,!self.closed else {return};self.amplitudes.removeAll{$0.0 == ticket};self.apply(self.gate.played(ticket))} }
    }
    func close() {
        guard !closed else {return};closed=true;receiver?.cancel();receiver=nil;sender?.cancel();sender=nil;request?.cancel();request=nil;continuation?.finish();continuation=nil
        engine.stop();player.stop();if tapped {engine.inputNode.removeTap(onBus:0);tapped=false};amplitudes=[];inputAmplitude=0
        let old=session;session=nil;gate=LandingGeminiGate();LandingDemoIdentity.disconnect(owner:lease)
        if ownsAudio {try? AVAudioSession.sharedInstance().setActive(false,options:.notifyOthersOnDeactivation);ownsAudio=false}
        // All shared cleanup happens before this suspension. An older close may
        // finish after a new lesson has already acquired the demo identity/audio.
        Task {await old?.close()}
    }
}
