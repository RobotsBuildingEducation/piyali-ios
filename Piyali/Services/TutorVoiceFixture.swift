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
    static func service()->LiveTutorService {
        #if DEBUG
        if enabled {let script=TutorVoiceScript();return LiveTutorService(capturesMicrophone:false,permission:{true},transportFactory:{TutorScriptTransport(script:script)})}
        #endif
        return LiveTutorService(transportFactory:{if TutorRealtime.provider == "gemini"{return GeminiTutorTransport()};return RealtimeRTCTransport()})
    }
    static var replySample:JSONValue {guard enabled,ProcessInfo.processInfo.environment["PIYALI_TUTOR_REPLY_FIXTURE"] == "1" else{return .null};guard let url=Bundle.main.url(forResource:"tutor-reply-fixture",withExtension:"json")else{return .null};return (try? ContentLibrary.decode(JSONValue.self,url:url)) ?? .null}
    static func provider(support:String="en")->TutorProvider {.init(judge:{_ in .object(["successful":.bool(false),"mistake":.bool(false),"confidence":.number(0.9),"reason":.string("Try the lesson phrase.")])},quote:{_,_,_ in .null},translate:{_,text in if replySample != .null,text == replySample["primary"].string{return replySample[support] == .null ? replySample["en"]:replySample[support]};return .object(["translation":.string(text == "Say hola." ? "Di hola.":"Public fixture translation"),"pairs":.array([])])})}
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
            emission=Task{try? await Task.sleep(for:.milliseconds(200));guard !Task.isCancelled,!closed else{return}
                let id=prefix+"-r\(index)",text=index == 0 && script.input == 0 ? "Welcome! Ready to learn Spanish?":TutorVoiceFixture.replySample != .null ? TutorVoiceFixture.replySample["primary"].string:"Say hola."
                captureFixture(id)
                emit(["type":.string("response.created"),"response":.object(["id":.string(id)])]);emit(["type":.string("output_audio_buffer.started")]);emit(["type":.string("response.output_audio_transcript.done"),"response_id":.string(id),"transcript":.string(text)]);emit(["type":.string("response.done"),"response":.object(["id":.string(id),"status":.string("completed"),"output":.array([.object(["content":.array([.object(["transcript":.string(text)])])])])])]);responsePending=false;emit(["type":.string("output_audio_buffer.stopped")]);scheduleInput()
            }
        }
        return true
    }
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func setMicrophoneEnabled(_ enabled:Bool){microphone=enabled;if !enabled{speech?.cancel();speech=nil}else{scheduleInput()}}
    private func scheduleInput(){guard microphone,!closed,!responsePending,script.response>0,speech == nil,script.input<(TutorVoiceFixture.replySample == .null ? 3:1) else{return}
        speech=Task{try? await Task.sleep(for:.seconds(script.input == 0 ? 3:5));guard !Task.isCancelled,!closed,microphone,!responsePending else{speech=nil;return};let index=script.input;script.input += 1;speech=nil;let id=prefix+"-u\(index)",text=index == 0 ? "yes":index == 1 ? "I do not know":"hola"
            emit(["type":.string("input_audio_buffer.speech_started")]);emit(["type":.string("input_audio_buffer.speech_stopped")]);emit(["type":.string("input_audio_buffer.committed"),"item_id":.string(id)]);emit(["type":.string("conversation.item.input_audio_transcription.completed"),"item_id":.string(id),"transcript":.string(text)])
        }
    }
    private func emit(_ event:[String:JSONValue]){guard !closed else{return};onEvent?(.object(event))}
    func close(){closed=true;microphone=false;emission?.cancel();speech?.cancel();emission=nil;speech=nil}
}
#endif

@MainActor enum TutorRealtime {static var provider:String{AppConfiguration().string("TutorRealtimeProvider",default:"gemini") == "openai" ? "openai":"gemini"}}
