import Foundation

public enum ResponsesOutput {
    public enum Failure:LocalizedError {
        case incomplete,refused,empty
        public var errorDescription:String? {
            switch self {
            case .incomplete:return "The AI response was interrupted. Try again shortly."
            case .refused:return "The AI service could not answer this request. Try a different prompt."
            case .empty:return "The AI service returned no text."
            }
        }
    }
    public static func text(_ body:JSONValue,structured:Bool) throws -> String {
        let status=body["status"].string
        guard status.isEmpty || status == "completed" else { throw Failure.incomplete }
        let messages=body["output"].array.filter { $0["type"].string.isEmpty || $0["type"].string == "message" }
        let final=messages.filter { $0["phase"].string == "final_answer" }
        let selected=final.isEmpty ? messages.filter { $0["phase"].string != "commentary" } : final
        if selected.flatMap({ $0["content"].array }).contains(where:{ $0["type"].string == "refusal" }) { throw Failure.refused }
        let texts=selected.map { message in message["content"].array.filter { $0["type"].string.isEmpty || $0["type"].string == "output_text" }.map { $0["text"].string }.joined() }.filter { !$0.isEmpty }
        // JSON is one completed message; concatenating separate objects corrupts it.
        let result=texts.isEmpty ? body["output_text"].string : structured ? texts.last! : texts.joined(separator:"\n")
        guard !result.isEmpty else { throw Failure.empty };return result
    }
}
