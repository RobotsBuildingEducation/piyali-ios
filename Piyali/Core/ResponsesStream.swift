import Foundation

/// Typed Responses SSE events. Partial text is display-only until a completed
/// response validates through the same policy as buffered lesson responses.
public struct ResponsesStream {
    private struct Message { var phase:String;var parts:[Int:String]=[:] }
    private var messages:[Int:Message]=[:],data:[String]=[],frameBytes=0,deltaBytes=0
    private var lineBytes:[UInt8]=[],skipLF=false,firstLine=true
    public private(set) var completed=false
    public private(set) var text=""
    public init(){}

    /// Preserve empty lines: Foundation's AsyncLineSequence omits them, while
    /// SSE needs them to dispatch events. Decode UTF-8 only at a line boundary.
    public mutating func receive(byte:UInt8)throws->String? {
        if byte == 10 && skipLF{skipLF=false;return nil}
        skipLF=false
        if byte == 10 || byte == 13 {
            skipLF = byte == 13
            guard var line=String(bytes:lineBytes,encoding:.utf8) else{throw ResponsesOutput.Failure.incomplete}
            lineBytes=[]
            if firstLine{firstLine=false;if line.hasPrefix("\u{FEFF}"){line.removeFirst()}}
            return try receive(line:line)
        }
        lineBytes.append(byte)
        guard lineBytes.count <= 1_048_576 else{throw ResponsesOutput.Failure.incomplete}
        return nil
    }

    /// A blank line dispatches one SSE frame; non-data fields are ignored.
    public mutating func receive(line:String)throws->String? {
        guard !completed else{return nil}
        if line.isEmpty {
            defer{data=[];frameBytes=0}
            guard !data.isEmpty else{return nil}
            return try event(data.joined(separator:"\n"))
        }
        frameBytes += line.utf8.count
        guard frameBytes <= 1_048_576 else{throw ResponsesOutput.Failure.incomplete}
        guard line.hasPrefix("data:") else{return nil}
        var value=String(line.dropFirst(5));if value.hasPrefix(" "){value.removeFirst()};data.append(value)
        return nil
    }

    public func finish()throws->String {
        guard completed else{throw ResponsesOutput.Failure.incomplete};return text
    }

    private mutating func event(_ raw:String)throws->String? {
        if raw == "[DONE]"{return nil} // A sentinel alone cannot certify success.
        guard let value=try? JSONDecoder().decode(JSONValue.self,from:Data(raw.utf8)),case .object = value else{throw ResponsesOutput.Failure.incomplete}
        let previous=text
        switch value["type"].string {
        case "response.output_item.added":
            let item=value["item"]
            if item["type"].string == "message" {messages[try index(value["output_index"])]=Message(phase:item["phase"].string)}
        case "response.output_text.delta":
            let outputIndex=try index(value["output_index"]),part=try index(value["content_index"])
            guard var message=messages[outputIndex] else{return nil}
            deltaBytes += value["delta"].string.utf8.count
            guard deltaBytes <= 1_048_576 else{throw ResponsesOutput.Failure.incomplete}
            message.parts[part,default:""] += value["delta"].string;messages[outputIndex]=message
            let ordered=messages.sorted{$0.key<$1.key}.map(\.value),final=ordered.filter{$0.phase == "final_answer"}
            text=(final.isEmpty ? ordered.filter{$0.phase != "commentary"} : final).map{$0.parts.sorted{$0.key<$1.key}.map(\.value).joined()}.joined(separator:"\n")
            guard text.utf8.count <= 1_048_576 else{throw ResponsesOutput.Failure.incomplete}
        case "response.completed":
            guard value["response"]["status"].string == "completed" else{throw ResponsesOutput.Failure.incomplete}
            text=try ResponsesOutput.text(value["response"],structured:false);completed=true
        case "response.refusal.delta","response.refusal.done":throw ResponsesOutput.Failure.refused
        case "response.failed","response.incomplete","error":throw ResponsesOutput.Failure.incomplete
        default:break // Usage, reasoning, obfuscation and other event data are not text.
        }
        return text != previous && !text.isEmpty ? text : nil
    }
    private func index(_ value:JSONValue)throws->Int {
        let n=value.number;guard n.isFinite,n>=0,n<=8192,n.rounded()==n else{throw ResponsesOutput.Failure.incomplete};return Int(n)
    }
}
