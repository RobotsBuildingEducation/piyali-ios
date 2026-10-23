import Foundation

public struct LandingGeminiPacket:Sendable {
    public var input="",transcript="",fallback=""
    public var audio:[Data]=[]
    public var hasModel=false,complete=false,interrupted=false
    public init() {}
}
/// Gemini's automatic VAD reply is discarded; only requested lesson responses
/// may reach the learner. Audio tickets fence completion after stop/interruption.
public struct LandingGeminiGate:Sendable {
    public enum Action:Equatable,Sendable {case event(JSONValue),play(Data,UUID),stopAudio,failure}
    public private(set) var inputEnabled=false
    private var input="",pending:String?,active:String?,fallback="",transcribed=false,complete=false,suppressing=false
    private var tickets:Set<UUID>=[]
    public init() {}
    public mutating func enableInput(_ value:Bool) {inputEnabled=value;if value {input=""}}
    public mutating func requested(_ id:String) {pending=id;inputEnabled=false}
    public mutating func receive(_ packet:LandingGeminiPacket)->[Action] {
        var actions:[Action]=[]
        if inputEnabled,!packet.input.isEmpty {input=String((input+packet.input).prefix(1600))}
        if packet.interrupted {
            tickets=[];complete=false;actions.append(.stopAudio)
            if suppressing {suppressing=false;return actions}
            if active != nil {active=nil;actions.append(.failure);return actions}
        }
        let output=packet.hasModel || !packet.transcript.isEmpty
        if output,active == nil,pending == nil {
            suppressing=true
            let text=input.split(whereSeparator:{$0.isWhitespace}).joined(separator:" ");input=""
            if !text.isEmpty {actions.append(.event(.object(["type":.string("conversation.item.input_audio_transcription.completed"),"transcript":.string(text)])))}
        }
        if suppressing {
            if packet.complete {
                suppressing=false
                let text=input.split(whereSeparator:{$0.isWhitespace}).joined(separator:" ");input=""
                if !text.isEmpty {actions.append(.event(.object(["type":.string("conversation.item.input_audio_transcription.completed"),"transcript":.string(text)])))}
            }
            return actions
        }
        if output,active == nil,let id=pending {
            active=id;pending=nil;fallback="";transcribed=false;complete=false
            actions.append(.event(.object(["type":.string("response.created"),"response":.object(["id":.string(id)])])))
        }
        if let id=active {
            if !packet.transcript.isEmpty {transcribed=true;actions.append(.event(.object(["type":.string("response.audio_transcript.delta"),"response_id":.string(id),"delta":.string(packet.transcript)])))}
            if !packet.fallback.isEmpty {fallback=String((fallback+(fallback.isEmpty ? "" : " ")+packet.fallback).prefix(1600))}
            for bytes in packet.audio where !bytes.isEmpty {let ticket=UUID();tickets.insert(ticket);actions.append(.play(bytes,ticket))}
            if packet.complete {
                if !transcribed,!fallback.isEmpty {actions.append(.event(.object(["type":.string("response.text.delta"),"response_id":.string(id),"delta":.string(fallback)])))}
                complete=true;actions += finishIfReady()
            }
        }
        if packet.complete,inputEnabled,!input.isEmpty {
            let text=input.split(whereSeparator:{$0.isWhitespace}).joined(separator:" ");input=""
            if !text.isEmpty {actions.append(.event(.object(["type":.string("conversation.item.input_audio_transcription.completed"),"transcript":.string(text)])))}
        }
        return actions
    }
    public mutating func played(_ ticket:UUID)->[Action] {guard tickets.remove(ticket) != nil else {return []};return finishIfReady()}
    private mutating func finishIfReady()->[Action] {
        guard complete,tickets.isEmpty,let id=active else {return []};active=nil;complete=false
        return [.event(.object(["type":.string("response.done"),"response_id":.string(id)]))]
    }
}
