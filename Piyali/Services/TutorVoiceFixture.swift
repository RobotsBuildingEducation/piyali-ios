import Foundation

@MainActor enum TutorVoiceFixture {
    static var enabled:Bool {
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        return env["PIYALI_OFFLINE_TESTS"] == "1" && env["PIYALI_TUTOR_FIXTURE"] == "1" && UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil
        #else
        return false
        #endif
    }
    static func service(provider:String?=nil)->LiveTutorService {
        let provider=provider ?? TutorRealtime.provider
        #if DEBUG
        if enabled {let script=TutorVoiceScript();return LiveTutorService(capturesMicrophone:false,permission:{true},transportFactory:{TutorScriptTransport(script:script)})}
        #endif
        return LiveTutorService(transportFactory:{if provider == "gemini"{return GeminiTutorTransport()};return RealtimeRTCTransport()})
    }
    static var lateSpeech:Bool {
        #if DEBUG
        return enabled && ProcessInfo.processInfo.environment["PIYALI_TUTOR_LATE_SPEECH_FIXTURE"] == "1"
        #else
        return false
        #endif
    }
    static var asrRecovery:Bool {
        #if DEBUG
        return enabled && ProcessInfo.processInfo.environment["PIYALI_TUTOR_ASR_RECOVERY_FIXTURE"] == "1"
        #else
        return false
        #endif
    }
    static var memorySlip:Bool {
        #if DEBUG
        return enabled && ProcessInfo.processInfo.environment["PIYALI_TUTOR_MEMORY_FIXTURE"] == "1"
        #else
        return false
        #endif
    }
    static var repeatedMemory:Bool {memorySlip && ProcessInfo.processInfo.environment["PIYALI_TUTOR_MEMORY_REPEAT_FIXTURE"] == "1"}
    static var replySample:JSONValue {guard enabled,ProcessInfo.processInfo.environment["PIYALI_TUTOR_REPLY_FIXTURE"] == "1" else{return .null};guard let url=Bundle.main.url(forResource:"tutor-reply-fixture",withExtension:"json")else{return .null};return (try? ContentLibrary.decode(JSONValue.self,url:url)) ?? .null}
    static func provider(support:String="en")->TutorProvider {
        var judges=0
        var p=TutorProvider(judge:{_ in judges += 1;return memorySlip ? .object(["successful":.bool(false),"mistake":.bool(true),"confidence":.number(0.2),"concept":.string("A greeting"),"correction":.string(repeatedMemory && judges>1 ? "Buen día":"Hola"),"reason":.string("Private fixture judge reason")]):.object(["successful":.bool(false),"mistake":.bool(false),"confidence":.number(0.9),"reason":.string("Try the lesson phrase.")])},quote:{_,_,_ in
            #if DEBUG
            if enabled,let delay=Int(ProcessInfo.processInfo.environment["PIYALI_TUTOR_WORTH_DELAY_MS"] ?? ""),(1...120000).contains(delay){try await Task.sleep(for:.milliseconds(delay))}
            #endif
            return .null
        },translate:{_,text in if replySample != .null,text == replySample["primary"].string{return replySample[support] == .null ? replySample["en"]:replySample[support]};return .object(["translation":.string(text == "Say hola." ? "Di hola.":"Public fixture translation"),"pairs":.array([])])})
        if memorySlip {p.memory={try await MemoryDrawerFixture.enrichmentResponse($0,language:support) ?? ""}}
        return p
    }
}
#if DEBUG
@MainActor private final class TutorVoiceScript {var response=0,input=0}
/// Timed protocol events exercise the real source-driven controller. There are
/// no fixture buttons or alternate grading/progress paths in the learner UI.
@MainActor private final class TutorScriptTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    private let script:TutorVoiceScript
    private var closed=false,microphone=false,responsePending=false,emission:Task<Void,Never>?,speech:Task<Void,Never>?
    private let prefix=UUID().uuidString
    private var recordings:[String:NarrationRecording]=[:]
    func takeResponseRecording(_ id:String)->NarrationRecording?{recordings.removeValue(forKey:id)}
    private func captureFixture(_ id:String){
        guard TutorVoiceFixture.enabled,ProcessInfo.processInfo.environment["PIYALI_TUTOR_REPLAY_FIXTURE"] == "1" else{return}
        // Public synthetic tone exercises the real disk/player path in UI QA;
        // provider-generated spoken reply capture is verified separately.
        var pcm=Data(capacity:24000*2*6)
        for i in 0..<24000*6{var value=Int16(sin(Double(i)*330*2*Double.pi/24000)*1000).littleEndian;withUnsafeBytes(of:&value){pcm.append(contentsOf:$0)}}
        recordings[id] = .init(pcm16:pcm,sampleRate:24000,channels:1)
    }
    init(script:TutorVoiceScript){self.script=script}
    func connect(session:JSONValue)async throws{closed=false;onOpen?()}
    func send(_ event:JSONValue)->Bool {
        guard !closed else{return false}
        if event["type"].string == "response.create" {
            emission?.cancel();responsePending=true
            let index=script.response;script.response += 1
            let recovery=TutorVoiceFixture.asrRecovery && event["response"]["metadata"]["kind"].string == "tutor_transcript_recovery"
            emission=Task{try? await Task.sleep(for:.milliseconds(recovery ? 1800:200));guard !Task.isCancelled,!closed else{return}
                let id=prefix+"-r\(index)",text=recovery ? "Please try hola once more.":index == 0 && script.input == 0 ? "Welcome! Ready to learn Spanish?":TutorVoiceFixture.replySample != .null ? TutorVoiceFixture.replySample["primary"].string:"Say hola."
                captureFixture(id)
                emit(["type":.string("response.created"),"response":.object(["id":.string(id),"metadata":event["response"]["metadata"]])]);emit(["type":.string("output_audio_buffer.started")])
                if TutorVoiceFixture.lateSpeech,index == 2 {
                    emit(["type":.string("response.output_audio_transcript.delta"),"response_id":.string(id),"delta":.string(text)])
                    for (offset,phrase) in ["hola","me llamo","me llamo"].enumerated(){
                        do{try await Task.sleep(for:.milliseconds(500))}catch{return};guard !closed,!Task.isCancelled else{return}
                        emit(["type":.string("conversation.item.input_audio_transcription.completed"),"item_id":.string(prefix+"-late-\(offset)"),"transcript":.string(phrase)])
                    }
                    do{try await Task.sleep(for:.milliseconds(1800))}catch{return};guard !closed,!Task.isCancelled else{return}
                }
                emit(["type":.string("response.output_audio_transcript.done"),"response_id":.string(id),"transcript":.string(text)]);emit(["type":.string("response.done"),"response":.object(["id":.string(id),"status":.string("completed"),"output":.array([.object(["content":.array([.object(["transcript":.string(text)])])])])])]);responsePending=false;emit(["type":.string("output_audio_buffer.stopped")]);scheduleInput()
            }
        }
        return true
    }
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func setMicrophoneEnabled(_ enabled:Bool){microphone=enabled;if !enabled{speech?.cancel();speech=nil}else{scheduleInput()}}
    private func scheduleInput(){guard microphone,!closed,!responsePending,script.response>0,speech == nil,script.input<(TutorVoiceFixture.repeatedMemory ? 3:(TutorVoiceFixture.asrRecovery || TutorVoiceFixture.lateSpeech || TutorVoiceFixture.memorySlip) ? 2:TutorVoiceFixture.replySample == .null ? 3:1) else{return}
        speech=Task{try? await Task.sleep(for:.seconds(script.input == 0 ? 3:5));guard !Task.isCancelled,!closed,microphone,!responsePending else{speech=nil;return};let index=script.input;script.input += 1;speech=nil;let id=prefix+"-u\(index)",text=index == 0 ? "yes":TutorVoiceFixture.asrRecovery ? "नमस्ते":index == 1 ? (TutorVoiceFixture.memorySlip ? "a public complete attempt":"I do not know"):(TutorVoiceFixture.repeatedMemory ? "another public complete attempt":"hola")
            emit(["type":.string("input_audio_buffer.speech_started")]);emit(["type":.string("input_audio_buffer.speech_stopped")]);emit(["type":.string("input_audio_buffer.committed"),"item_id":.string(id)]);emit(["type":.string("conversation.item.input_audio_transcription.completed"),"item_id":.string(id),"transcript":.string(text)])
        }
    }
    private func emit(_ event:[String:JSONValue]){guard !closed else{return};onEvent?(.object(event))}
    func close(){closed=true;microphone=false;emission?.cancel();speech?.cancel();emission=nil;speech=nil}
}
#endif

@MainActor enum TutorRealtime {static var provider:String{AppConfiguration().string("TutorRealtimeProvider",default:"gemini") == "openai" ? "openai":"gemini"}}
