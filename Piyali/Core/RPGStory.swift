import Foundation

public enum RPGDialogue {
    public static func split(_ raw:String) -> (spoken:String,scene:String) {
        var text=raw.trimmingCharacters(in:.whitespacesAndNewlines);guard !text.isEmpty else { return ("","") }
        if (text.hasPrefix("\"") && text.hasSuffix("\"") && text.filter({ $0 == "\"" }).count == 2) || (text.hasPrefix("'") && text.hasSuffix("'") && text.filter({ $0 == "'" }).count == 2) || (text.hasPrefix("“") && text.hasSuffix("”")) || (text.hasPrefix("‘") && text.hasSuffix("’")) { text=String(text.dropFirst().dropLast()).trimmingCharacters(in:.whitespacesAndNewlines) }
        func match(_ pattern:String,insensitive:Bool = false) -> [String]? {
            guard let regex=try? NSRegularExpression(pattern:pattern,options:insensitive ? [.caseInsensitive] : []),let m=regex.firstMatch(in:text,range:NSRange(text.startIndex...,in:text)) else { return nil }
            return (0..<m.numberOfRanges).map { Range(m.range(at:$0),in:text).map { String(text[$0]) } ?? "" }
        }
        func scene(_ s:String) -> String { s.trimmingCharacters(in:.whitespacesAndNewlines).replacingOccurrences(of:"^[*_()\\[\\]]+|[*_()\\[\\]]+$",with:"",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines) }
        func spoken(_ s:String) -> String { var v=s.trimmingCharacters(in:.whitespacesAndNewlines).replacingOccurrences(of:"^[\"'“‘]+|[\"'”’]+$",with:"",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines);if v.hasSuffix(",") { v=String(v.dropLast()).trimmingCharacters(in:.whitespacesAndNewlines) };return v }
        if let m=match(#"^([*_]{1,2})([^*_]+)\1\s*(?:[:,-]\s*)?([\s\S]+)$"#) { return (spoken(m[3]),scene(m[2])) }
        if let m=match(#"^(\([^)]{2,120}\)|\[[^\]]{2,120}\])\s*(?:[:,-]\s*)?([\s\S]+)$"#) { return (spoken(m[2]),scene(m[1])) }
        if let m=match(#"^([^"“‘]+?)(?:,\s*|:\s*|\s+)(["'“‘])([\s\S]+?)\2(?:\s*\.?)*$"#),scene(m[1]).count > 1,!spoken(m[3]).isEmpty { return (spoken(m[3]),scene(m[1])) }
        if let m=match(#"^(["'“‘])([\s\S]+?)\1(?:,\s*|\s+)([^"“‘]{2,80})$"#) { return (spoken(m[2]),scene(m[3])) }
        if let m=match(#"^([^:\n]{2,60}?(?:says|said|dice|dijo|dit|sagt|smiles|looks|laughs|replies|exclaims|giggles|shouts|whispers))\s*:\s*([\s\S]+)$"#,insensitive:true) { return (spoken(m[2]),scene(m[1])) }
        if let m=match(#"^([\s\S]+?)\s*([*_]{1,2})([^*_]+)\2$"#) { return (spoken(m[1]),scene(m[3])) }
        if let m=match(#"^([\s\S]+?)\s*(\([^)\n]{2,80}\)|\[[^\]\n]{2,80}\])$"#) { return (spoken(m[1]),scene(m[2])) }
        return (text,"")
    }
}
public enum RPGStory {
    public static func languageScript(_ lang:String,text:String)->Bool {
        let patterns=["ja":"[぀-ヿ一-鿿]","zh":"[一-鿿]","ar":"[؀-ۿ]","hi":"[ऀ-ॿ]"]
        guard let pattern=patterns[lang],!text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else{return true};return text.range(of:pattern,options:.regularExpression) != nil
    }
    public static func preparing(_ scenario:RPGScenario,raw:JSONValue,target:String,support:String,policy:RPGPreparationPolicy)->RPGScenario? {
        guard let request=try? policy.request(scenario:scenario,lesson:.object([:]),target:target,support:support)else{return nil}
        return try? policy.prepare(response:raw.canonicalJSON,request:request)?.scenario
    }
}
