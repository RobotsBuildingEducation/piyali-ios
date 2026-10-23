import Foundation

/// Realtime events are asynchronous: input transcription can finish after the
/// assistant's response. Keep their IDs until both sides of a turn are known.
public struct RealtimeVoiceState: Sendable {
    public struct Turn: Equatable, Sendable { public let text:String;public let answered:String;public let reply:String }
    private struct Input: Sendable { var text:String?;var answered:String;var response:String?;var delivered=false }
    private struct Output: Sendable { var text="";var channel="";var complete=false }
    private var inputs:[String:Input]=[:],order:[String]=[],outputs:[String:Output]=[:]
    private var timeline:[(user:Bool,id:String)]=[]
    private var currentResponse="",previousAssistant="",speechAnswer:String?
    public private(set) var assistantText="",assistantLocked=false
    public private(set) var muted=false
    public var microphoneEnabled:Bool { !muted && !assistantLocked }
    public var transcript:String {
        String(timeline.compactMap { item ->String? in
            let text=item.user ? inputs[item.id]?.text ?? "" : outputs[item.id]?.text ?? ""
            return text.isEmpty ? nil : (item.user ? "You: " : "Piyali: ")+text
        }.joined(separator:"\n").suffix(16000))
    }
    public init(previousAssistant:String="") { self.previousAssistant=previousAssistant }
    public mutating func setMuted(_ value:Bool) { muted=value }
    public mutating func receive(_ event:JSONValue)->[Turn] {
        let type=event["type"].string
        switch type {
        case "input_audio_buffer.speech_started": speechAnswer=previousAssistant
        case "input_audio_buffer.committed":
            assistantLocked=true
            let id=event["item_id"].string
            if !id.isEmpty,inputs[id] == nil { inputs[id]=Input(answered:speechAnswer ?? previousAssistant);order.append(id);timeline.append((true,id));speechAnswer=nil }
        case "conversation.item.input_audio_transcription.completed":
            let id=event["item_id"].string,text=event["transcript"].string.trimmingCharacters(in:.whitespacesAndNewlines)
            if !id.isEmpty,!text.isEmpty {
                if inputs[id] == nil { inputs[id]=Input(answered:speechAnswer ?? previousAssistant);order.append(id);timeline.append((true,id));speechAnswer=nil }
                if inputs[id]?.text == nil { inputs[id]?.text=String(text.prefix(12000)) }
            }
        case "response.created":
            let id=event["response"]["id"].string
            if !id.isEmpty,outputs[id] == nil {
                currentResponse=id;outputs[id]=Output();timeline.append((false,id));assistantText="";assistantLocked=true
                if let input=order.first(where:{inputs[$0]?.response == nil && inputs[$0]?.delivered == false}) { inputs[input]?.response=id }
            }
        case "response.audio_transcript.delta","response.output_audio_transcript.delta","response.output_text.delta","response.text.delta":
            let id=responseID(event),channel=type.replacingOccurrences(of:".delta",with:"")
            if var output=outputs[id],!output.complete,(output.channel.isEmpty || output.channel == channel) {
                output.channel=channel;output.text=String((output.text+event["delta"].string).suffix(12000));outputs[id]=output
                if id == currentResponse { assistantText=output.text }
            }
        case "response.audio_transcript.done","response.output_audio_transcript.done","response.output_text.done","response.text.done":
            let id=responseID(event),text=event["transcript"].string.isEmpty ? event["text"].string : event["transcript"].string
            if !text.isEmpty,outputs[id]?.complete == false { outputs[id]?.text=String(text.prefix(12000));if id == currentResponse { assistantText=String(text.prefix(12000)) } }
        case "response.done","response.completed","response.cancelled","response.canceled":
            let id=event["response"]["id"].string.isEmpty ? responseID(event) : event["response"]["id"].string
            if var output=outputs[id],!output.complete {
                let finalText=event["response"]["output"].array.flatMap { $0["content"].array }.map { $0["transcript"].string.isEmpty ? $0["text"].string : $0["transcript"].string }.joined()
                if !finalText.isEmpty { output.text=String(finalText.prefix(12000)) }
                output.complete=true;outputs[id]=output
                if !output.text.isEmpty { previousAssistant=output.text }
                if id == currentResponse { assistantText=output.text }
            }
            if type.contains("cancel") || ["cancelled","failed"].contains(event["response"]["status"].string) { assistantLocked=false }
        case "output_audio_buffer.stopped","output_audio_buffer.cleared": assistantLocked=false
        default: break
        }
        var turns:[Turn]=[]
        for id in order {
            guard let input=inputs[id],!input.delivered,let text=input.text,let response=input.response,let output=outputs[response],output.complete else { continue }
            inputs[id]?.delivered=true;turns.append(Turn(text:text,answered:input.answered,reply:output.text))
        }
        // Keep the most recent 64 inputs, including transcripts still pending.
        while order.count > 64,let id=order.first {
            let response=inputs[id]?.response
            if let response { outputs.removeValue(forKey:response) };inputs.removeValue(forKey:id);order.removeFirst()
            timeline.removeAll { ($0.user && $0.id == id) || (!$0.user && $0.id == response) }
        }
        return turns
    }
    private func responseID(_ event:JSONValue)->String { event["response_id"].string.isEmpty ? currentResponse : event["response_id"].string }
}

public enum RealtimeVoicePolicy {
    public static func vad(pauseMilliseconds:Int=2000,manualResponse:Bool)->JSONValue {
        .object(["type":.string("server_vad"),"silence_duration_ms":.number(Double(max(200,min(10000,pauseMilliseconds)))),"threshold":.number(0.35),"prefix_padding_ms":.number(120),"create_response":.bool(!manualResponse),"interrupt_response":.bool(false)])
    }
    public static func session(instructions:String,model:String="gpt-realtime-2.1-mini",voice:String="ash",manualResponse:Bool=false)->JSONValue {
        .object(["type":.string("realtime"),"model":.string(model),"instructions":.string(instructions),"output_modalities":.array([.string("audio")]),"audio":.object(["input":.object(["transcription":.object(["model":.string("gpt-4o-mini-transcribe")]),"turn_detection":vad(manualResponse:manualResponse)]),"output":.object(["voice":.string(voice),"format":.object(["type":.string("audio/pcm"),"rate":.number(24000)])])])])
    }
}
