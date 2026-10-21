import Foundation

public enum PracticeQuestionFailure:LocalizedError {
    case malformed
    public var errorDescription:String? { "The question was incomplete or did not match this practice format. Please try again." }
}

/// Native state for the authored question contracts. Answer keys stay out of the
/// visible question; generated keys are references for semantic judging.
public struct PracticeQuestion:Codable,Equatable,Identifiable,Sendable {
    public var id=UUID()
    public let module:PracticeRecipeModule
    public let kind:String
    public let payload:JSONValue
    public let options:JSONValue
    public let target:String
    public let support:String
    private enum CodingKeys:String,CodingKey { case id,module,kind,payload,options,target,support }
    public init(from decoder:Decoder) throws {
        let c=try decoder.container(keyedBy:CodingKeys.self)
        try self.init(module:c.decode(PracticeRecipeModule.self,forKey:.module),kind:c.decode(String.self,forKey:.kind),payload:c.decode(JSONValue.self,forKey:.payload),options:c.decode(JSONValue.self,forKey:.options),target:c.decode(String.self,forKey:.target),support:c.decode(String.self,forKey:.support))
        id=try c.decode(UUID.self,forKey:.id)
    }
    public var isDelight:Bool { kind.hasPrefix("delight:") }
    public var variant:String { String(kind.dropFirst(8)) }
    public var level:String { options["cefrLevel"].string }
    public var sourceLanguage:String { options["isListening"].boolean ? target : options["direction"].string == "support-to-target" ? support : target }
    public var answerLanguage:String { ["translate","repeat"].contains(kind) && options["direction"].string == "target-to-support" ? support : target }
    public var audioText:String {
        if kind == "repeat",options["isListening"].boolean { return strings("correctWords").joined(separator:" ") }
        if ["translate","repeat"].contains(kind) { return payload["sentence"].string }
        if kind == "speak" { return payload["target"].string }
        if ["fill","mc","ma"].contains(kind) { return payload["question"].string }
        if kind == "match" { return payload["stem"].string }
        if isDelight { for field in ["audioText","line","source","sentence"] { if !payload[field].string.isEmpty { return payload[field].string } } }
        return ""
    }
    public var audioLanguage:String { ["translate","repeat"].contains(kind) ? sourceLanguage : target }
    public var questionText:String {
        if variant == "listen_difference" { return payload["audioText"].string }
        if variant == "sentence_detective" { return strings("tokens").joined(separator:payload["joiner"].string) }
        if variant == "three_clue_mystery" { return strings("clues").joined(separator:"\n") }
        if variant == "three_word_challenge" { return strings("cues").joined(separator:" · ") }
        if variant == "word_neighborhoods" { return payload["groups"].array.flatMap { $0["items"].array.map(\.string) }.joined(separator:" · ") }
        for field in ["question","stem","display","sentence","concept","source","line","instruction","prompt"] {
            if !payload[field].string.isEmpty { return payload[field].string }
        }
        return ""
    }
    public func strings(_ field:String)->[String] { payload[field].array.map(\.string) }
    public init(module:PracticeRecipeModule,kind:String,payload:JSONValue,options:JSONValue,target:String,support:String) throws {
        self.module=module;self.kind=kind;self.payload=payload;self.options=options;self.target=target;self.support=support
        guard payload.json.utf8.count <= 60_000 else { throw PracticeQuestionFailure.malformed }
        if kind.hasPrefix("delight:") {
            guard payload["variant"].string == String(kind.dropFirst(8)) else { throw PracticeQuestionFailure.malformed };return
        }
        let valid:Bool
        switch kind {
        case "fill":valid = !payload["question"].string.isEmpty && payload["question"].string.contains("___")
        case "mc":valid = !payload["question"].string.isEmpty && Self.validWords(payload["choices"],range:2...8) && !payload["answer"].string.isEmpty
        case "ma":valid = !payload["question"].string.isEmpty && Self.validWords(payload["choices"],range:2...12) && Self.validWords(payload["answers"],range:1...6)
        case "speak":valid = !payload["target"].string.isEmpty && !payload["prompt"].string.isEmpty
        case "match":
            let left=payload["left"].array,right=payload["right"].array,map=payload["map"].array
            valid = Self.validWords(payload["left"],range:2...8) && Self.validWords(payload["right"],range:2...8) && Set(left.map(\.string)).count == left.count && Set(right.map(\.string)).count == right.count && left.count == right.count && (module == .vocabulary || map.count == left.count && map.allSatisfy { if case .number(let n)=$0 { return n.isFinite && n.rounded() == n && n >= 0 && n < Double(right.count) };return false } && Set(map.map { Int($0.number) }) == Set(right.indices))
        case "translate","repeat":valid = !payload["sentence"].string.isEmpty && Self.validWords(payload["correctWords"],range:1...40) && payload["distractors"].array.count <= 20
        case "flashcard":valid = !payload["concept"].string.isEmpty && !payload["answer"].string.isEmpty
        default:valid=false
        }
        guard valid else { throw PracticeQuestionFailure.malformed }
    }
    private static func validWords(_ value:JSONValue,range:ClosedRange<Int>)->Bool { range.contains(value.array.count) && value.array.allSatisfy { !$0.string.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && $0.string.utf8.count <= 2000 } }
    public static func parse(_ text:String,module:PracticeRecipeModule,kind:String,options:JSONValue,target:String,support:String) throws ->Self {
        let parts=try GenerationObjects.parse(text)
        let types:[String:Set<String>]=["fill":["fill","vocab_fill"],"mc":["mc","vocab_mc"],"ma":["ma","vocab_ma"],"speak":["grammar_speak","vocab_speak"],"match":["match"],"translate":["translate"],"repeat":["translate"],"flashcard":["lesson_flashcard"]]
        var merged:[String:JSONValue]=[:]
        for part in parts {
            if part["type"].string == "done" { continue }
            let allowed=types[kind]?.contains(part["type"].string) == true || kind == "match" && module == .vocabulary && part["type"] == .null
            guard allowed else { throw PracticeQuestionFailure.malformed }
            merged.merge(part.object) { _,new in new }
        }
        return try .init(module:module,kind:kind,payload:.object(merged),options:options,target:target,support:support)
    }
    public func ready(_ response:JSONValue)->Bool {
        let bankCount=["translate","repeat"].contains(kind) ? strings("correctWords").count+strings("distractors").count : strings("choices").count
        let boundedIndices=response["indices"].array.allSatisfy { value in if case .number(let n)=value { return n.isFinite && n.rounded() == n && n >= 0 && n < Double(bankCount) };return false }
        let indices=boundedIndices ? response["indices"].array.map { Int($0.number) } : []
        let validIndices=boundedIndices && Set(indices).count == indices.count
        switch kind {
        case "fill","flashcard","speak":return !response["text"].string.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty
        case "mc":return validIndices && indices.count == 1
        case "ma","translate","repeat":return validIndices && !indices.isEmpty
        case "match":
            let pairs=response["pairs"].object,count=strings("left").count
            return Set(pairs.keys) == Set((0..<count).map(String.init)) && Set(pairs.values.compactMap { if case .number(let n)=$0,n.rounded() == n,n >= 0,n < Double(count) { return Int(n) };return nil }) == Set(0..<count)
        default:return false // Delight uses its original readiness policy.
        }
    }
    public func responseText(_ response:JSONValue,bank:[String])->String {
        if ["mc","ma","translate","repeat"].contains(kind) { return response["indices"].array.compactMap { value -> String? in let i=Int(value.number);return bank.indices.contains(i) ? bank[i] : nil }.joined(separator:" ") }
        if kind == "match" { return strings("left").enumerated().map { i,left in let index=response["pairs"][String(i)];return left+" → "+(index == .null ? "" : strings("right")[safe:Int(index.number)] ?? "") }.joined(separator:"\n") }
        return response["text"].string
    }
    public var standardReward:Int { kind == "mc" ? 5 : kind == "fill" && module == .vocabulary ? 5 : 6 }
}

/// Providers emit phased NDJSON. Scan complete objects so quoted braces,
/// escaped quotation marks and optional Markdown fences do not corrupt phases.
public enum GenerationObjects {
    public static func parse(_ text:String) throws ->[JSONValue] {
        guard text.utf8.count <= 100_000 else { throw PracticeQuestionFailure.malformed }
        var objects:[JSONValue]=[],start:String.Index?,depth=0,quoted=false,escaped=false
        for index in text.indices {
            let c=text[index]
            if depth == 0 { if c == "{" { start=index;depth=1;quoted=false;escaped=false };continue }
            if quoted { if escaped { escaped=false } else if c == "\\" { escaped=true } else if c == "\"" { quoted=false };continue }
            if c == "\"" { quoted=true } else if c == "{" { depth += 1 } else if c == "}" {
                depth -= 1
                if depth == 0,let start {
                    guard objects.count < 64,let object=try? JSONDecoder().decode(JSONValue.self,from:Data(text[start...index].utf8)),case .object=object else { throw PracticeQuestionFailure.malformed }
                    objects.append(object)
                }
            }
        }
        guard depth == 0,!objects.isEmpty else { throw PracticeQuestionFailure.malformed };return objects
    }
}
private extension Array { subscript(safe index:Int)->Element? { indices.contains(index) ? self[index] : nil } }
