import Foundation

public enum StoryMode:String,Codable,CaseIterable,Sendable {
    case speaking,radio,conversation
    public var label:String { switch self { case .speaking:"Sentence practice";case .radio:"Radio call";case .conversation:"Character conversation" } }
    public static func choose(content:JSONValue,random:Double) -> StoryMode {
        if content["topic"].string == "tutorial" { return .speaking }
        if let pinned=Self(rawValue:content["storyMode"].string) { return pinned }
        return allCases[max(0,min(2,Int(floor(random*3))))]
    }
    public func next(content:JSONValue,random:Double) -> StoryMode {
        if content["topic"].string == "tutorial" { return .speaking }
        if let pinned=Self(rawValue:content["storyMode"].string) { return pinned }
        let other=Self.allCases.filter { $0 != self };return other[max(0,min(1,Int(floor(random*2))))]
    }
}
public enum StoryFailure:LocalizedError,Equatable {
    case invalid,language
    public var errorDescription:String? { self == .language ? "The story was not in your selected language. Try another story." : "The story contained an unusable checkpoint. Try another story." }
}
public struct StoryTurn:Codable,Equatable,Sendable {
    public let speaker:String
    public let target:String
    public var support:String?
    public var gender:String?
    public init(speaker:String,target:String,support:String? = nil,gender:String? = nil) { self.speaker=speaker;self.target=target;self.support=support;self.gender=gender }
}
public struct StoryQuestion:Codable,Equatable,Sendable {
    public var type:String
    public let prompt:String
    public var options:[String]
    public var answer:[Int]
    public let explanation:String
    public var audioTurn:Int?
    public func correct(_ selected:[Int]) -> Bool {
        guard selected.count == answer.count,Set(selected).count == selected.count else { return false }
        return type == "order_words" ? selected == answer : Set(selected) == Set(answer)
    }
}
public struct StorySegment:Codable,Equatable,Sendable { public var turns:[StoryTurn];public var question:StoryQuestion }
public struct StoryEpisode:Codable,Equatable,Sendable {
    public var title:String
    public var segments:[StorySegment]
    public var text:String { segments.flatMap(\.turns).map(\.target).joined(separator:"\n") }
    public static func parse(_ raw:JSONValue,target:String = "",prepare:Bool = false) throws -> StoryEpisode {
        let data:Data
        if case .string(let string)=raw {
            var clean=string.trimmingCharacters(in:.whitespacesAndNewlines)
            if clean.hasPrefix("```") { clean=clean.replacingOccurrences(of:"^```(?:json)?\\s*",with:"",options:.regularExpression).replacingOccurrences(of:"\\s*```$",with:"",options:.regularExpression) }
            data=Data(clean.utf8)
        } else { data=try JSONEncoder().encode(raw) }
        guard data.count <= 100_000,var episode=try? JSONDecoder().decode(Self.self,from:data) else { throw StoryFailure.invalid }
        if prepare { for i in episode.segments.indices {
            if episode.segments[i].question.type == "order_words",let turn=episode.segments[i].question.audioTurn,episode.segments[i].turns.indices.contains(turn) {
                let tiles=Self.tiles(episode.segments[i].turns[turn].target);episode.segments[i].question.options=tiles.options;episode.segments[i].question.answer=tiles.answer
            }
        } }
        try episode.validate(target:target);return episode
    }
    public func validate(target:String = "") throws {
        func text(_ s:String) -> Bool { !s.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && s.utf8.count <= 8000 }
        guard text(title),(2...4).contains(segments.count) else { throw StoryFailure.invalid }
        var speakers=Set<String>()
        for segment in segments {
            guard (2...6).contains(segment.turns.count),segment.turns.allSatisfy({ text($0.speaker) && text($0.target) }) else { throw StoryFailure.invalid }
            speakers.formUnion(segment.turns.map(\.speaker));let q=segment.question
            guard ["choice","true_false","select_words","order_words","reply"].contains(q.type),text(q.prompt),text(q.explanation),(2...8).contains(q.options.count),q.options.allSatisfy(text),Set(q.options).count == q.options.count,!q.answer.isEmpty,Set(q.answer).count == q.answer.count,q.answer.allSatisfy({ q.options.indices.contains($0) }) else { throw StoryFailure.invalid }
            if ["choice","true_false","reply"].contains(q.type),q.answer.count != 1 { throw StoryFailure.invalid }
            if q.type == "true_false",q.options.count != 2 { throw StoryFailure.invalid }
            if ["select_words","order_words"].contains(q.type) {
                guard let index=q.audioTurn,segment.turns.indices.contains(index) else { throw StoryFailure.invalid };let excerpt=segment.turns[index].target
                if q.type == "order_words" {
                    guard Self.matches(q.answer.map { q.options[$0] }.joined(separator:" "),excerpt) else { throw StoryFailure.invalid }
                } else {
                    for i in q.options.indices {
                        let token=Self.normalize(q.options[i]),sentence=Self.normalize(excerpt)
                        let present=Self.unspaced(excerpt) ? sentence.replacingOccurrences(of:" ",with:"").contains(token.replacingOccurrences(of:" ",with:"")) : (" "+sentence+" ").contains(" "+token+" ")
                        guard present == q.answer.contains(i) else { throw StoryFailure.invalid }
                    }
                    guard q.answer.count < q.options.count else { throw StoryFailure.invalid }
                }
            }
            if !target.isEmpty,["reply","select_words","order_words"].contains(q.type),!Self.compatible(q.options,target:target) { throw StoryFailure.language }
        }
        guard speakers.count == 2 else { throw StoryFailure.invalid }
        if !target.isEmpty,!Self.compatible(segments.flatMap(\.turns).map(\.target),target:target) { throw StoryFailure.language }
    }
    public static func normalize(_ text:String) -> String { text.precomposedStringWithCompatibilityMapping.lowercased().replacingOccurrences(of:"[^\\p{L}\\p{N}\\p{M}]+",with:" ",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines) }
    public static func unspaced(_ text:String) -> Bool { text.range(of:"[\\p{Han}\\p{Hiragana}\\p{Katakana}]",options:.regularExpression) != nil }
    public static func matches(_ a:String,_ b:String) -> Bool { let left=normalize(a),right=normalize(b);return unspaced(b) ? left.replacingOccurrences(of:" ",with:"") == right.replacingOccurrences(of:" ",with:"") : left == right }
    public static func compatible(_ texts:[String],target:String) -> Bool {
        let scripts=["ar":"Arabic","el":"Greek","hi":"Devanagari","ja":"Han}\\p{Hiragana}\\p{Katakana","ru":"Cyrillic","zh":"Han"]
        let values=texts.filter { !$0.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty };guard !values.isEmpty else { return false }
        let pattern="[\\p{"+(scripts[target] ?? "Latin")+"}]",count=values.filter { $0.range(of:pattern,options:.regularExpression) != nil }.count
        return scripts[target] == nil ? count > 0 : count >= max(1,Int(ceil(Double(values.count)/2)))
    }
    public static func tiles(_ text:String) -> (options:[String],answer:[Int]) {
        var words=text.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        if words.count < 2,unspaced(text) { words=[];text.enumerateSubstrings(in:text.startIndex...,options:.byWords) { value,_,_,_ in if let value { words.append(value) } } }
        words=words.map { $0.replacingOccurrences(of:"^[^\\p{L}\\p{M}\\p{N}]+|[^\\p{L}\\p{M}\\p{N}]+$",with:"",options:.regularExpression) }.filter { !$0.isEmpty }
        guard !words.isEmpty else { return ([],[]) };let width=Int(ceil(Double(words.count)/6));var tiles:[String]=[]
        for start in stride(from:0,to:words.count,by:width) { tiles.append(words[start..<min(start+width,words.count)].joined(separator:" ")) }
        while let duplicate=tiles.indices.first(where: { index in normalize(tiles[index]).isEmpty || tiles[..<index].contains(where:{ normalize($0) == normalize(tiles[index]) }) }),tiles.count > 1 {
            let i=duplicate == tiles.count-1 ? duplicate-1 : duplicate;tiles.replaceSubrange(i...i+1,with:[tiles[i]+" "+tiles[i+1]])
        }
        let order=Array(tiles.indices.dropFirst())+Array(tiles.indices.prefix(1))
        return (order.map { tiles[$0] },tiles.indices.map { order.firstIndex(of:$0)! })
    }
}
