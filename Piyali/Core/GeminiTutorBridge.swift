import Foundation

/// Native counterpart of geminiLiveBridge.js. Network, audio and deadlines are
/// injected so provider callbacks cannot bypass the source turn-taking policy.
public final class GeminiTutorBridge {
    private final class Response {
        let id:String,metadata:JSONValue
        var text="",fallback="",transcribed=false,started=false
        init(_ id:String,_ metadata:JSONValue){self.id=id;self.metadata=metadata}
    }
    public var onEvent:((JSONValue)->Void)?
    public var onText:((String)->Void)?
    public var onAudio:((Data,Int)->Void)?
    public var onInput:((Data)->Void)?
    public var onStopAudio:(()->Void)?
    public var onReset:(()->Void)?
    public var onDeadline:((String,Bool)->Void)?
    public var onToolResponses:(([JSONValue])->Void)?
    private var pending:[Response]=[],queued:[Response]=[],active:Response?
    private var tickets:Set<Int>=[],nextResponse=0,nextAudio=0
    private var input="",desiredInput=true,speechUntil=0.0,lastSpeech=0.0
    public private(set) var closed=false,resetting=false,resetPending=false,suppressAuto=false,serverComplete=false
    public private(set) var completed=0,outputGain=1.0
    public var inputEnabled:Bool{desiredInput && !resetting && !closed}
    public var pendingAudio:Int{tickets.count}
    private let responseLimit:Int,responsePrefix:String
    public init(responseLimit:Int=4,responsePrefix:String="gemini_"){self.responseLimit=max(0,responseLimit);self.responsePrefix=responsePrefix}
    private func makeResponse(_ metadata:JSONValue = .object([:]))->Response {nextResponse+=1;return Response("\(responsePrefix)\(nextResponse)",metadata)}
    private func emit(_ type:String,_ fields:[String:JSONValue]=[:]){onEvent?(.object(fields.merging(["type":.string(type)]){_,new in new}))}
    public func request(_ instructions:String,metadata:JSONValue = .object([:])) {
        guard !closed else{return};let response=makeResponse(metadata)
        queued.append(response);prompts[response.id]=instructions.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty ? "Respond to the learner now.":instructions.trimmingCharacters(in:.whitespacesAndNewlines);dispatch()
    }
    private var prompts:[String:String]=[:]
    private func dispatch(allowSuppressed:Bool=false){
        guard !closed,!resetting,active == nil,pending.isEmpty,!queued.isEmpty,(!suppressAuto || allowSuppressed) else{return}
        if resetPending{beginReset();return}
        let response=queued.removeFirst();pending.append(response);onDeadline?(response.id,true);setInputEnabled(false)
        let prompt=prompts.removeValue(forKey:response.id) ?? "Respond now.";onText?(prompt)
    }
    public func setInputEnabled(_ value:Bool){desiredInput=value;if !inputEnabled{speechUntil=0}}
    public func clearInput(){input=""}
    public func inputPCM(_ bytes:Data,nowMilliseconds:Double){
        guard inputEnabled,!bytes.isEmpty else{return}
        if Self.rms(bytes)>=0.006 {
            let wasActive=nowMilliseconds<=speechUntil;speechUntil=nowMilliseconds+1200
            if !wasActive {lastSpeech=nowMilliseconds;emit("input_audio_buffer.local_speech_started")}
            else if nowMilliseconds-lastSpeech>=1000 {lastSpeech=nowMilliseconds;emit("input_audio_buffer.local_speech_active")}
        }
        onInput?(bytes)
    }
    public static func rms(_ bytes:Data)->Double {
        let count=bytes.count/2;guard count>0 else{return 0};var squares=0.0
        bytes.withUnsafeBytes{raw in for i in 0..<count{let value=Double(Int16(littleEndian:raw.loadUnaligned(fromByteOffset:i*2,as:Int16.self)))/32768;squares+=value*value}}
        return sqrt(squares/Double(count))
    }
    public func setOutputGain(_ raw:Double){guard raw.isFinite else{return};outputGain=raw>1.2 ? 1:max(0,min(1,raw))}
    private func ensureResponse(){
        guard active == nil else{return};active=pending.isEmpty ? makeResponse():pending.removeFirst();serverComplete=false
        guard let active else{return};onDeadline?(active.id,false)
        if !active.started{active.started=true;emit("response.created",["response":.object(["id":.string(active.id),"metadata":active.metadata])])}
    }
    private func finalizeInput(){
        let transcript=input.split(whereSeparator:{$0.isWhitespace}).joined(separator:" ");input="";guard !transcript.isEmpty else{return}
        emit("input_audio_buffer.speech_stopped");emit("input_audio_buffer.committed");emit("conversation.item.input_audio_transcription.completed",["transcript":.string(transcript)])
    }
    public func receive(_ message:JSONValue){
        guard !closed,!resetting else{return}
        if message["type"].string == "toolCall",case .array(let calls)=message["functionCalls"] {
            if (active ?? pending.first)?.metadata["kind"].string == "pause_resume" {
                onToolResponses?(calls.map{call in var fields:[String:JSONValue]=["name":call["name"],"response":.object(["allowed":.bool(false),"reason":.string("Finish the interrupted speech without grading or changing lesson progress.")])];if call["id"] != .null{fields["id"]=call["id"]};return .object(fields)})
            }else{emit("tool.call",["functionCalls":.array(calls)])};return
        }
        if message["type"].string == "toolCallCancellation"{let ids=message["functionIds"] == .null ? message["ids"]:message["functionIds"];emit("tool.cancel",["functionIds":ids == .null ? .array([]):ids]);return}
        let content=message["serverContent"] == .null ? (message["type"].string == "serverContent" ? message:.null):message["serverContent"]
        guard content != .null else{return}
        input+=content["inputTranscription"]["text"].string
        let interrupted=content["interrupted"].boolean,wasSuppressed=interrupted && suppressAuto
        if interrupted{suppressAuto=false;finish("response.canceled");interruptAudio();if wasSuppressed{dispatch();return}}
        let hasModel=content["modelTurn"] != .null,transcript=content["outputTranscription"]["text"].string
        let hasOutput=hasModel || !transcript.isEmpty,unrequested=hasOutput && active == nil && pending.isEmpty && queued.isEmpty
        var beganSuppressing=false
        if unrequested{suppressAuto=true;beganSuppressing=true;if !input.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty{finalizeInput()}}
        if hasModel,!input.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,active == nil{suppressAuto=true;beganSuppressing=true;finalizeInput()}
        if beganSuppressing{dispatch(allowSuppressed:true)}
        if suppressAuto{if content["turnComplete"].boolean || interrupted{suppressAuto=false;dispatch()};return}
        if hasOutput{ensureResponse()}
        if let active,!transcript.isEmpty{active.transcribed=true;active.text+=transcript;emit("response.audio_transcript.delta",["response_id":.string(active.id),"delta":.string(transcript)])}
        let parts=content["modelTurn"]["parts"].array,text=parts.filter{$0["thought"] != .bool(true)}.map{$0["text"].string}.filter{!$0.isEmpty}.joined(separator:" ")
        if let active,!text.isEmpty{active.fallback+=(active.fallback.isEmpty ? "":" ")+text}
        for part in parts {let data=part["inlineData"];if data["mimeType"].string.lowercased().hasPrefix("audio/"),!data["data"].string.isEmpty,let bytes=Data(base64Encoded:data["data"].string){nextAudio+=1;tickets.insert(nextAudio);onAudio?(bytes,nextAudio)}}
        if content["turnComplete"].boolean,let active {
            if !active.transcribed,!active.fallback.isEmpty{active.text+=active.fallback;emit("response.text.delta",["response_id":.string(active.id),"delta":.string(active.fallback)]);active.fallback=""}
            serverComplete=true;finishIfReady()
        }
        if content["turnComplete"].boolean,!input.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty{finalizeInput()}
    }
    public func played(_ ticket:Int){guard tickets.remove(ticket) != nil,!closed else{return};finishIfReady()}
    private func finishIfReady(){if serverComplete,tickets.isEmpty,let active{emit("response.output_audio.done",["response_id":.string(active.id)]);finish("response.done")}}
    private func finish(_ type:String){
        guard let current=active else{return};onDeadline?(current.id,false)
        emit(type,["response_id":.string(current.id),"response":.object(["id":.string(current.id),"metadata":current.metadata])]);active=nil
        if type == "response.done"{completed+=1;if responseLimit>0,completed>=responseLimit{resetPending=true;beginReset()}}
        dispatch()
    }
    private func interruptAudio(){tickets=[];onStopAudio?()}
    public func cancel(){guard !closed else{return};for response in pending+queued{onDeadline?(response.id,false)};queued=[];pending=[];prompts=[:];finish("response.canceled");interruptAudio()}
    public func responseTimedOut(_ id:String){
        guard !closed,!resetting,active?.id != id,let index=pending.firstIndex(where:{$0.id == id && !$0.started}) else{return}
        let response=pending.remove(at:index);onDeadline?(id,false)
        emit("response.canceled",["response_id":.string(id),"response":.object(["id":.string(id),"metadata":response.metadata]),"error":.object(["message":.string("Gemini Live did not start a response in time.")])]);dispatch()
    }
    private func beginReset(){guard !closed,!resetting,active == nil,pending.isEmpty else{return};resetting=true;speechUntil=0;suppressAuto=false;input="";onReset?()}
    public func resetReady(){guard !closed,resetting else{return};completed=0;resetPending=false;resetting=false;dispatch()}
    public func close(){guard !closed else{return};closed=true;for response in pending+queued+[active].compactMap({$0}){onDeadline?(response.id,false)};queued=[];pending=[];prompts=[:];interruptAudio()}
    public var snapshot:JSONValue{.object(["closed":.bool(closed),"inputEnabled":.bool(inputEnabled),"suppressAuto":.bool(suppressAuto),"active":active.map{.string($0.id)} ?? .null,"pending":.array(pending.map{.string($0.id)}),"queued":.array(queued.map{.string($0.id)}),"scheduled":.number(Double(tickets.count)),"complete":.bool(serverComplete),"completed":.number(Double(completed)),"resetting":.bool(resetting),"resetPending":.bool(resetPending),"gain":.number(outputGain)])}
}
