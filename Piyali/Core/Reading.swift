import Foundation

public enum Reading {
    public static func normalize(_ text:String) -> String { text.precomposedStringWithCompatibilityMapping.lowercased().replacingOccurrences(of:"[^\\p{L}\\p{N}\\s]",with:" ",options:.regularExpression).replacingOccurrences(of:"\\s+",with:" ",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines) }
    public static func comparison(_ text:String) -> String { text.lowercased().replacingOccurrences(of:"\\s+",with:" ",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines) }
    public static func matches(_ text:String,_ pattern:String) -> Bool { text.range(of:pattern,options:[.regularExpression,.caseInsensitive]) != nil }
    private static func groups(_ text:String,_ pattern:String,capture:Int = 0) -> [String] {
        guard let regex=try? NSRegularExpression(pattern:pattern,options:[.caseInsensitive]) else { return [] }
        return regex.matches(in:text,range:NSRange(text.startIndex...,in:text)).compactMap { match in guard capture < match.numberOfRanges,let range=Range(match.range(at:capture),in:text) else { return nil };return String(text[range]) }
    }
    public static func words(_ text:String) -> [String] {
        let normalized=normalize(text);var values:[String]=[]
        normalized.enumerateSubstrings(in:normalized.startIndex...,options:.byWords) { value,_,_,_ in if let value { values.append(value) } };return values
    }
    public static func sentences(_ text:String) -> [String] { groups(text,"[^.!?。！？\\n]+[.!?。！？]*").map { $0.trimmingCharacters(in:.whitespacesAndNewlines) }.filter { !$0.isEmpty } }
    public static func award(roll:Double) -> Int { 5+Int(floor((roll.isFinite ? max(0,min(1-Double.ulpOfOne,roll)) : 0)*4)) }
    public static func stripPreamble(_ text:String) -> String { var result=text.trimmingCharacters(in:.whitespacesAndNewlines);for pattern in ReadingRules.data["preambles"].array.map(\.string) { result=result.replacingOccurrences(of:pattern,with:"",options:[.regularExpression,.caseInsensitive]).trimmingCharacters(in:.whitespacesAndNewlines) };return result }
    private static func reaction(_ text:String) -> Bool { matches(text.replacingOccurrences(of:"^[¡¿\\s]+",with:"",options:.regularExpression),"^(?:oh\\b|ah\\b|wow\\b|yay\\b|hooray\\b|really\\b|look\\b|how\\s+(?:nice|lovely|wonderful|exciting|great)|what\\s+(?:a|an)\\b|ay\\b|vaya\\b|guau\\b|qué\\s+(?:bien|bonito|bueno|maravilla)|waouh\\b|super\\b|comme\\s+c'est|che\\s+bello|que\\s+(?:bom|legal)|wie\\s+(?:schön|toll)|わあ|すごい|哇)") }
    private static func reactions(_ parts:[String]) -> String { let flags=parts.map(reaction);guard flags.filter({ $0 }).count >= 2 else { return "" };return flags.map { $0 ? "R" : "C" }.joined().replacingOccurrences(of:"C+",with:"C",options:.regularExpression) }
    private static func shingles(_ words:[String]) -> Set<String> { guard words.count >= 5 else { return [] };return Set((0...words.count-5).map { words[$0..<$0+5].joined(separator:" ") }) }
    public static func issues(candidate:JSONValue,recent:[JSONValue] = [],selection:JSONValue = .null,tutorial:Bool = false) -> [String] {
        let title=candidate["title"].string,text=candidate["target"].string
        guard !title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,!text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return ["missing_content"] }
        if tutorial { return [] };let parts=sentences(text),tokens=words(text);var issues:[String]=[]
        let reports=groups(text,"\\b(?:say|says|said|tell|tells|told|reply|replies|replied|answer|answers|answered|ask|asks|asked|dice|dijo|responde|respondió|pregunta|preguntó)\\b"),quotes=groups(text,"[\"“«][^\"”»\\n]+[\"”»]")
        if reports.count >= 2,(quotes.count >= 2 || matches(text,",\\s*(?:(?:I|he|she|we|they)\\s+)?(?:say|says|said|tell|tells|told|reply|replies|replied|answer|answers|answered)\\b")) { issues.append("reported_dialogue") }
        if stripPreamble(text) != text.trimmingCharacters(in:.whitespacesAndNewlines) { issues.append("meta_preamble") }
        let labels=groups(text,"(?:^|\\n|[.!?。！？]\\s+)([\\p{L}\\p{N}_][\\p{L}\\p{N}_ ]{0,24}):\\s+",capture:1).map { $0.trimmingCharacters(in:.whitespacesAndNewlines) }.filter { !matches($0,"^(notice|hours|schedule|warning|attention|bulletin|aviso|horario|note|tip|ingredients|opening hours|opening times|price|time|date|location)$") }
        let required=selection["format"]["id"].string.hasPrefix("document:")
        if (!required && Set(labels).count >= 2) || labels.contains(where:{ matches($0,"^(?:[A-Z]|speaker\\s*\\d+|person\\s*\\d+)$") }) || groups(text,"(?:^|\\n)\\s*[—–-]\\s*\\S").count >= 2 { issues.append("script") }
        let exclamations=parts.filter { matches($0,"[!?！？]$") }.count,flags=parts.map(reaction),informational=["practical_notice","everyday_guide","object_label","news_brief"].contains(selection["format"]["id"].string)
        if (parts.count >= 3 && exclamations >= 3 && Double(exclamations)/Double(parts.count) >= 0.75) || (informational && exclamations >= 2 && Double(exclamations)/Double(parts.count) >= 0.6) || flags.indices.contains(where:{ $0+1 < flags.count && flags[$0] && flags[$0+1] }) || flags.filter({ $0 }).count > parts.count/2 { issues.append("reaction_chain") }
        let substantial=parts.map(normalize).filter { words($0).count >= 5 };if Set(substantial).count < substantial.count { issues.append("repeated_sentence") }
        let grams=shingles(tokens)
        for entry in recent {
            let old=entry["targetText"].string.isEmpty ? entry["snippet"].string : entry["targetText"].string;if old.isEmpty { continue }
            let previous=sentences(old),oldGrams=shingles(words(old)),shared=grams.intersection(oldGrams).count,overlap=2*Double(shared)/Double(max(1,grams.count+oldGrams.count))
            if !reactions(parts).isEmpty,reactions(parts) == reactions(previous) { issues.append("repeated_reaction_structure");break }
            let a=parts.map { words($0) }.map { $0.count >= 2 ? $0.prefix(2).joined(separator:" ") : "" },b=previous.map { words($0) }.map { $0.count >= 2 ? $0.prefix(2).joined(separator:" ") : "" }
            let starts=a.indices.filter { !a[$0].isEmpty && b.indices.contains($0) && a[$0] == b[$0] }.map { a[$0] }
            let skeleton=starts.count >= 3 && Set(starts).count >= 2 && Double(starts.count)/Double(max(a.count,b.count)) >= 0.6
            if normalize(old) == normalize(text) || (shared >= 4 && overlap >= 0.45) || skeleton { issues.append("repeated_passage");break }
        }
        return issues
    }
    public static func select(content:JSONValue,level:String,recent:[JSONValue],lesson:String,roll:Double) -> JSONValue {
        let levels=["PRE-A1","A1","A2","B1","B2","C1","C2"],rank=max(0,levels.firstIndex(of:level.uppercased()) ?? 0),prompt=content["prompt"].string,goal=content["topic"].string+" "+prompt
        var formats=ReadingRules.data["formats"].array.filter { $0["minLevel"].string.isEmpty || (levels.firstIndex(of:$0["minLevel"].string) ?? 0) <= rank }
        if matches(goal,"courtesy|polite|apolog|thank") { formats=formats.filter { ["personal_note","diary_entry","personal_update"].contains($0["id"].string) } }
        else if matches(goal,"reaction|exclamation|interjection|greet|goodbye|reaccion|exclamaci") { formats=formats.filter { ["personal_note","diary_entry","personal_update","mini_review","photo_caption","travel_entry"].contains($0["id"].string) } }
        else if matches(prompt,"\\b(menu|timetable|schedule|recipe|directions)\\b") { formats=formats.filter { ["everyday_guide","practical_notice"].contains($0["id"].string) } }
        func pick(_ options:[JSONValue],history:[JSONValue],field:String) -> JSONValue {
            guard !options.isEmpty else { return .null };let unused=options.filter { option in !history.contains { $0[field] == option["id"] } }
            if !unused.isEmpty { return unused[min(unused.count-1,max(0,Int(floor(roll*Double(unused.count)))))] }
            return options.max { left,right in (history.firstIndex { $0[field] == left["id"] } ?? -1) < (history.firstIndex { $0[field] == right["id"] } ?? -1) }!
        }
        let subjects=content["readingSubjects"].array.filter { !$0["id"].string.isEmpty && !$0["name"].string.isEmpty },same=recent.filter { $0["lessonId"].string == lesson },document=content["readingScope"]["requiredDocument"]
        let subject=subjects.first { option in !same.contains { $0["subject"] == option["id"] } } ?? pick(subjects,history:same,field:"subject")
        let format=document == .null ? pick(formats,history:recent,field:"format") : .object(["id":.string("document:"+document["name"].string),"name":document["name"],"directive":.string(document["requirements"].string+" Use this required document format with no dialogue or speaker turns.")])
        let angle=pick(ReadingRules.data["angles"].array,history:recent,field:"readingAngle")
        return .object(["format":format,"readingAngle":angle,"structure":pick(ReadingRules.data["structures"].array,history:recent,field:"structure"),"subject":subject,"chatIntent":angle,"dialogueDynamic":angle])
    }
}
public struct ReadingQuestion:Codable,Equatable,Sendable {
    public let type:String
    public let question:String
    public let options:[String]
    public let answer:String
    public init?(_ input:JSONValue,expectedType:String = "") {
        let allowed=["text","fill","mc"],type=allowed.contains(expectedType) ? expectedType : allowed.contains(input["questionType"].string) ? input["questionType"].string : input["type"].string
        let question=(input["question"].string.isEmpty ? input["sentence"].string : input["question"].string).trimmingCharacters(in:.whitespacesAndNewlines),answer=input["answer"].string.trimmingCharacters(in:.whitespacesAndNewlines)
        guard allowed.contains(type),!question.isEmpty,!answer.isEmpty,type != "fill" || question.contains("___") else { return nil }
        let options=input["options"].array.map { $0.string.trimmingCharacters(in:.whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if type == "mc" { guard options.count == 4,Set(options.map(Reading.comparison)).count == 4,let matching=options.first(where:{ Reading.comparison($0) == Reading.comparison(answer) }) else { return nil };self.answer=matching } else { self.answer=answer }
        self.type=type;self.question=question;self.options=type == "mc" ? options : []
    }
}
