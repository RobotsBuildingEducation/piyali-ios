import Foundation

/// Complete speaking records displayed while the source stream is in flight.
/// These records require final validation and assessment before they can earn XP.
public enum StoryStreamDraft {
    /// Providers sometimes emit a scalar for a question that requires exactly one index.
    public static func normalizeSingleAnswer(_ question:JSONValue)->JSONValue {
        guard ["choice","true_false","reply"].contains(question["type"].string),case .number(let number)=question["answer"],number.isFinite,number.rounded() == number,number >= 0,number < 8 else{return question}
        return question.setting("answer",.array([.number(number)]))
    }
    public struct Episode:Equatable,Sendable {
        public var value:StoryEpisode
        public var ready:Set<Int>
    }
    /// An incomplete episode is presentation state, never a validated story.
    public static func episode(_ snapshot:String,includeTrailingRecord:Bool=false)->Episode? {
        guard snapshot.utf8.count <= 100_000 else{return nil}
        var lines=snapshot.components(separatedBy:"\n");if !includeTrailingRecord {lines.removeLast()}
        let empty=StoryQuestion(type:"",prompt:"",options:[],answer:[],explanation:"",audioTurn:nil)
        var title="",segments:[StorySegment]=[],ready=Set<Int>()
        for raw in lines {
            let line=raw.trimmingCharacters(in:.whitespacesAndNewlines)
            guard line.hasPrefix("{"),line.hasSuffix("}"),let object=try? JSONDecoder().decode(JSONValue.self,from:Data(line.utf8)) else{continue}
            if object["type"].string == "title" {
                let value=object["title"].string.trimmingCharacters(in:.whitespacesAndNewlines)
                if !value.isEmpty,value.utf8.count <= 8_000 {title=value};continue
            }
            guard ["turn","question"].contains(object["type"].string) else{continue}
            let fallback=object["type"].string == "turn" ? 0 : max(0,segments.count-1)
            let number=object["segment"].number
            let index: Int
            if case .number=object["segment"],number.isFinite,number.rounded() == number,number >= 0,number < 4 {index=Int(number)}
            else if object["segment"] == .null {index=fallback}
            else {continue}
            while segments.count <= index {segments.append(.init(turns:[],question:empty))}
            if object["type"].string == "turn" {
                guard case .string(let value)=object["target"] else{continue}
                let target=value.trimmingCharacters(in:.whitespacesAndNewlines),speaker=object["speaker"].string.trimmingCharacters(in:.whitespacesAndNewlines)
                guard !target.isEmpty,target.utf8.count <= 8_000,speaker.utf8.count <= 8_000,segments[index].turns.count < 6 else{continue}
                segments[index].turns.append(.init(speaker:speaker.isEmpty ? "Sheilfer":speaker,target:target,support:object["support"].string.trimmingCharacters(in:.whitespacesAndNewlines)))
            } else {
                guard var q=try? JSONDecoder().decode(StoryQuestion.self,from:JSONEncoder().encode(normalizeSingleAnswer(object["question"]))) else{continue}
                if q.type == "order_words" {let turn=q.audioTurn ?? 0;if segments[index].turns.indices.contains(turn) {let tiles=StoryEpisode.tiles(segments[index].turns[turn].target);q.options=tiles.options;q.answer=tiles.answer}}
                guard ["choice","true_false","select_words","order_words","reply"].contains(q.type),!q.prompt.isEmpty,q.prompt.utf8.count <= 8_000,q.explanation.utf8.count <= 8_000,(2...8).contains(q.options.count),q.options.allSatisfy({ !$0.isEmpty && $0.utf8.count <= 8_000 }),Set(q.options).count == q.options.count,!q.answer.isEmpty,Set(q.answer).count == q.answer.count,q.answer.allSatisfy({q.options.indices.contains($0)}) else{continue}
                segments[index].question=q;ready.insert(index)
            }
        }
        guard segments.first?.turns.isEmpty == false else{return nil}
        return .init(value:.init(title:title,segments:segments),ready:ready)
    }
    public static func speaking(_ snapshot:String,includeTrailingRecord:Bool=false)->[StoryTurn] {
        guard snapshot.utf8.count <= 100_000 else{return []}
        var lines=snapshot.components(separatedBy:"\n");if !includeTrailingRecord {lines.removeLast()}
        return Array(lines.lazy.compactMap { raw ->StoryTurn? in
            let line=raw.trimmingCharacters(in:.whitespacesAndNewlines)
            guard line.hasPrefix("{"),line.hasSuffix("}"),let object=try? JSONDecoder().decode(JSONValue.self,from:Data(line.utf8)),object["type"].string == "sentence",case .string(let rawTarget)=object["tgt"] else{return nil}
            let target=rawTarget.trimmingCharacters(in:.whitespacesAndNewlines)
            guard !target.isEmpty,target.utf8.count <= 8_000 else{return nil}
            let speaker=object["character"].string.isEmpty ? "Sheilfer":object["character"].string
            let support=object["sup"].string.trimmingCharacters(in:.whitespacesAndNewlines)
            return StoryTurn(speaker:speaker,target:target,support:support,gender:object["gender"].string.isEmpty ? nil:object["gender"].string)
        }.prefix(64))
    }
}
