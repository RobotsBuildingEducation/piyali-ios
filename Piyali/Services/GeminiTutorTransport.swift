import Foundation
import AVFoundation

/// Learner Tutor only. Conversations, reading and public demos retain their own
/// source providers and identities. The bridge owns turn ordering; this adapter
/// owns one Firebase socket and one native microphone/player lifetime.
@MainActor final class GeminiTutorTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    typealias Factory=(JSONValue)async throws->GeminiTutorSocket
    private let factory:Factory,capturesAudio:Bool,capturesMicrophone:Bool
    private let bridge=GeminiTutorBridge(responsePrefix:"gemini_"+UUID().uuidString+"_"),engine=AVAudioEngine(),player=AVAudioPlayerNode()
    private let format=AVAudioFormat(commonFormat:.pcmFormatFloat32,sampleRate:24000,channels:1,interleaved:false)!
    private var socket:GeminiTutorSocket?,receiveTask:Task<Void,Never>?,sendTask:Task<Void,Never>?,resetTask:Task<Void,Never>?,captureTask:Task<Void,Never>?
    private var deadlines:[String:Task<Void,Never>]=[:],continuation:AsyncStream<Data>.Continuation?
    private let audioLease=UUID()
    private var config:JSONValue = .null,epoch=UUID(),closed=false,tapped=false,ownsAudio=false,playing=false,remoteEnabled=true
    private var inputIndex=0,inputID="",inputLevel=0.0,levels:[(Int,Double)]=[],sendCount=0
    private(set) var receivedAudioBytes=0,playedAudioBuffers=0
    init(capturesAudio:Bool=true,capturesMicrophone:Bool=true,factory:Factory?=nil){self.capturesAudio=capturesAudio;self.capturesMicrophone=capturesMicrophone;self.factory=factory ?? {try await FirebaseGeminiTutorSocket.connect($0)}}
    func connect(session:JSONValue)async throws {
        guard !closed,socket == nil else{throw CancellationError()};config=session
        installBridge();let run=epoch
        let connection=try await factory(config)
        guard !closed,epoch == run,!Task.isCancelled else{connection.close();throw CancellationError()};socket=connection
        do{if capturesAudio{try setupAudio()}}catch{close();throw error}
        receive(connection,run:run);onOpen?()
    }
    private func installBridge(){
        bridge.onEvent={[weak self] in self?.event($0)}
        bridge.onText={[weak self] in self?.enqueue(GeminiTutorWire.text($0))}
        bridge.onInput={[weak self] in self?.enqueue(GeminiTutorWire.input($0))}
        bridge.onAudio={[weak self] in self?.play($0,ticket:$1)}
        bridge.onStopAudio={[weak self] in self?.stopAudio()}
        bridge.onReset={[weak self] in self?.reset()}
        bridge.onDeadline={[weak self] id,start in guard let self else{return};deadlines.removeValue(forKey:id)?.cancel();if start{deadlines[id]=Task{[weak self] in do{try await Task.sleep(for:.seconds(20))}catch{return};self?.bridge.responseTimedOut(id)}}}
        bridge.onToolResponses={[weak self] in self?.enqueue(.object(["toolResponse":.object(["functionResponses":.array($0)])]))}
    }
    private func receive(_ connection:GeminiTutorSocket,run:UUID){
        receiveTask=Task{[weak self] in
            do{while !Task.isCancelled{let message=try await connection.receive();guard let self,!closed,epoch == run else{return};if message["error"] != .null{fail();return};bridge.receive(GeminiTutorWire.packet(message))}}
            catch{if let self,!closed,epoch == run,!Task.isCancelled{fail()}}
        }
    }
    private func enqueue(_ packet:JSONValue){
        guard !closed,let socket else{return};guard sendCount<48 else{fail();return}
        let previous=sendTask,run=epoch;sendCount+=1
        sendTask=Task{[weak self] in
            await previous?.value
            guard let self,!closed,epoch == run,!Task.isCancelled else{return}
            defer{if epoch == run{sendCount-=1}}
            do{try await socket.send(packet)}catch{if !closed,epoch == run,!Task.isCancelled{fail()}}
        }
    }
    private func reset(){
        guard !closed else{return};socket?.close();socket=nil;receiveTask?.cancel();sendTask?.cancel();sendTask=nil;sendCount=0;epoch=UUID();let run=epoch
        resetTask=Task{[weak self] in guard let self else{return};do{
            let connection=try await factory(config)
            guard !closed,epoch == run,!Task.isCancelled else{connection.close();return}
            socket=connection;receive(connection,run:run);bridge.resetReady()
        }catch{if !closed,epoch == run,!Task.isCancelled{fail()}}}
    }
    private func event(_ raw:JSONValue){
        guard !closed else{return};let type=raw["type"].string;var event=raw
        if type == "input_audio_buffer.speech_stopped"{inputIndex+=1;inputID="gemini-input-\(epoch.uuidString)-\(inputIndex)"}
        if ["input_audio_buffer.speech_stopped","input_audio_buffer.committed","conversation.item.input_audio_transcription.completed"].contains(type){event=raw.setting("item_id",.string(inputID))}
        // Tool grading is disabled in the actual Tutor. Never allow an unsolicited
        // provider tool to grant progress; finish the tool request explicitly.
        if type == "tool.call"{let responses=raw["functionCalls"].array.map{call in call.setting("args",.null).setting("response",.object(["allowed":.bool(false),"reason":.string("Lesson progress is checked by the app.")]))};enqueue(.object(["toolResponse":.object(["functionResponses":.array(responses)])]));return}
        if type == "response.done"{event=event.setting("response",event["response"].setting("status",.string("completed")))}
        onEvent?(event)
        if ["response.done","response.canceled"].contains(type){playing=false;onEvent?(.object(["type":.string("output_audio_buffer.stopped")]))}
    }
    func send(_ event:JSONValue)->Bool {
        guard !closed else{return false}
        switch event["type"].string{
        case "response.create":bridge.request(event["response"]["instructions"].string,metadata:event["response"]["metadata"] == .null ? .object([:]):event["response"]["metadata"])
        case "response.cancel":bridge.cancel()
        case "input_audio_buffer.clear":bridge.clearInput()
        case "session.update":let update=event["session"];if update["responseInstructionsSuffix"] != .null{config=config.setting("responseInstructionsSuffix",update["responseInstructionsSuffix"])};if update["instructions"] != .null{config=config.setting("instructions",update["instructions"])};if update["inputLanguageCodes"] != .null{config=config.setting("inputLanguageCodes",update["inputLanguageCodes"])}
        default:return false
        };return true
    }
    func setMicrophoneEnabled(_ enabled:Bool){bridge.setInputEnabled(enabled && capturesMicrophone);if !enabled{inputLevel=0}}
    func setRemoteAudioEnabled(_ enabled:Bool){remoteEnabled=enabled;player.volume=enabled ? Float(bridge.outputGain):0}
    func setOutputGain(_ value:Double){bridge.setOutputGain(value);player.volume=remoteEnabled ? Float(bridge.outputGain):0}
    func playbackDrainMilliseconds()async->Double{0}
    func audioAmplitude(speaking:Bool)async->Double{guard !closed else{return 0};return speaking ? levels.first?.1 ?? 0:inputLevel}
    private func setupAudio()throws {
        try GeminiTutorAudioLease.acquire(audioLease);ownsAudio=true
        engine.attach(player);engine.connect(player,to:engine.mainMixerNode,format:format)
        if !capturesMicrophone{bridge.setInputEnabled(false);engine.prepare();try engine.start();player.play();return}
        let input=engine.inputNode;try input.setVoiceProcessingEnabled(true);let source=input.outputFormat(forBus:0)
        guard source.sampleRate>0,let pcm=AVAudioFormat(commonFormat:.pcmFormatInt16,sampleRate:16000,channels:1,interleaved:false),let converter=AVAudioConverter(from:source,to:pcm) else{throw AppError.message("The microphone is unavailable.")}
        let stream=AsyncStream<Data>(bufferingPolicy:.bufferingNewest(20)){continuation=$0},sink=continuation
        input.installTap(onBus:0,bufferSize:2048,format:source){buffer,_ in
            guard let converted=AVAudioPCMBuffer(pcmFormat:pcm,frameCapacity:AVAudioFrameCount(Double(buffer.frameLength)*16000/source.sampleRate)+1)else{return}
            var consumed=false,error:NSError?;converter.convert(to:converted,error:&error){_,status in if consumed{status.pointee = .noDataNow;return nil};consumed=true;status.pointee = .haveData;return buffer}
            if error == nil,let samples=converted.int16ChannelData?[0],converted.frameLength>0{sink?.yield(Data(bytes:samples,count:Int(converted.frameLength)*2))}
        };tapped=true
        captureTask=Task{[weak self] in for await bytes in stream{guard let self,!closed,!Task.isCancelled else{return};if bridge.inputEnabled{inputLevel=GeminiTutorBridge.rms(bytes);bridge.inputPCM(bytes,nowMilliseconds:Date().timeIntervalSince1970*1000)}}}
        engine.prepare();try engine.start();player.play()
    }
    private func play(_ bytes:Data,ticket:Int){
        receivedAudioBytes+=bytes.count
        guard capturesAudio else{bridge.played(ticket);return}
        let count=bytes.count/2;guard count>0,let buffer=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:AVAudioFrameCount(count)),let samples=buffer.floatChannelData?[0]else{bridge.played(ticket);return}
        buffer.frameLength=AVAudioFrameCount(count)
        bytes.withUnsafeBytes{raw in for i in 0..<count{samples[i]=Float(Int16(littleEndian:raw.loadUnaligned(fromByteOffset:i*2,as:Int16.self)))/32768}}
        levels.append((ticket,GeminiTutorBridge.rms(bytes)));if !playing{playing=true;onEvent?(.object(["type":.string("output_audio_buffer.started")]))}
        player.scheduleBuffer(buffer,completionCallbackType:.dataPlayedBack){[weak self] _ in Task{@MainActor in guard let self,!self.closed,self.levels.contains(where:{$0.0 == ticket}) else{return};self.levels.removeAll{$0.0 == ticket};self.playedAudioBuffers+=1;self.bridge.played(ticket)}}
    }
    private func stopAudio(){levels=[];if capturesAudio{player.stop();if !closed{player.play()}};if playing{playing=false;if !closed{onEvent?(.object(["type":.string("output_audio_buffer.cleared")]))}}}
    private func fail(){guard !closed else{return};close();onFailure?("Tutor disconnected. Try connecting again.")}
    func close(){
        guard !closed else{return};closed=true;epoch=UUID();bridge.close();socket?.close();socket=nil;receiveTask?.cancel();sendTask?.cancel();resetTask?.cancel();captureTask?.cancel();deadlines.values.forEach{$0.cancel()};deadlines=[:];continuation?.finish();continuation=nil
        engine.stop();player.stop();if tapped{engine.inputNode.removeTap(onBus:0);tapped=false};levels=[];inputLevel=0
        if ownsAudio{GeminiTutorAudioLease.release(audioLease);ownsAudio=false}
    }
}

/// Tutor and Settings previews can overlap. Closing a short preview must not
/// deactivate the audio session still held by a learner's live Tutor.
@MainActor private enum GeminiTutorAudioLease {
    private static var owners:Set<UUID>=[]
    static func acquire(_ id:UUID)throws {
        if owners.isEmpty{let audio=AVAudioSession.sharedInstance();try audio.setCategory(.playAndRecord,mode:.voiceChat,options:[.defaultToSpeaker,.allowBluetoothHFP]);try audio.setActive(true)}
        owners.insert(id)
    }
    static func release(_ id:UUID){guard owners.remove(id) != nil,owners.isEmpty else{return};try? AVAudioSession.sharedInstance().setActive(false,options:.notifyOthersOnDeactivation)}
}
