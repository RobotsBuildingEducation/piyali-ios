import Foundation

/// A transient view of complete NDJSON records, never a saved or rewardable run.
/// Rebuilding from the provider's cumulative snapshot also handles a corrected
/// final Responses event without retaining text from an abandoned attempt.
public struct ReadingStreamDraft:Equatable,Sendable {
    public let title:String
    public let text:String
    public let takeaways:[String]

    public static func parse(_ snapshot:String,target:String,support:String,includeTrailingRecord:Bool=false)->ReadingStreamDraft? {
        guard snapshot.utf8.count <= 100_000 else{return nil}
        var lines=snapshot.components(separatedBy:"\n")
        if !includeTrailingRecord {lines.removeLast()}
        var title="",parts:[String]=[],takeaways:[String]=[]
        for line in lines {
            guard let value=try? JSONDecoder().decode(JSONValue.self,from:Data(line.trimmingCharacters(in:.whitespacesAndNewlines).utf8)),case .object=value else{continue}
            let type=value["type"].string
            guard ["title","target","takeaway"].contains(type),case .string(let raw)=value["text"] else{continue}
            let cleaned=normalize(stripLabel(raw,language:type == "takeaway" ? support:target))
            guard !cleaned.isEmpty else{continue}
            switch type {
            case "title":title=cleaned
            case "target":let sentence=stripSpeaker(cleaned);if parts.last != sentence {parts.append(sentence)}
            case "takeaway":if takeaways.count < 3 && !takeaways.contains(cleaned) {takeaways.append(cleaned)}
            default:break
            }
        }
        guard !title.isEmpty || !parts.isEmpty else{return nil}
        let text=Reading.stripPreamble(parts.joined(separator:" "))
        return .init(title:title.isEmpty ? (target == "en" ? "Generating...":"Generando...") : title,text:text,takeaways:takeaways)
    }
    private static func normalize(_ value:String)->String {value.replacingOccurrences(of:"\\s+",with:" ",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines)}
    private static let labels:[String:[String]] = [
        "en":["English","Inglés"],"es":["Spanish","Español"],"ar":["Egyptian Arabic","Arabic","Árabe egipcio","العربية المصرية"],"zh":["Mandarin Chinese","Chinese","Chino mandarín","普通话中文","中文"],"pt":["Portuguese","Portugués","Brazilian Portuguese","Portugués brasileño"],"fr":["French","Francés","Français","Francais"],"it":["Italian","Italiano"],"nl":["Dutch","Holandés","Nederlands"],"nah":["Eastern Huasteca Nahuatl","Náhuatl huasteco oriental"],"el":["Greek","Griego","Ελληνικά"],"ru":["Russian","Ruso"],"de":["German","Alemán","Deutsch"],"pl":["Polish","Polaco","Polski"],"ga":["Irish","Irlandés","Gaeilge"],"yua":["Yucatec Maya","Maya yucateco","Maaya t'aan"]
    ]
    private static let languageNames:[String:String] = ["en":"English","es":"Spanish","pt":"Brazilian Portuguese","fr":"French","it":"Italian","ar":"Egyptian Arabic","zh":"Mandarin Chinese","ja":"Japanese","nl":"Dutch","nah":"Eastern Huasteca Nahuatl","ru":"Russian","de":"German","el":"Greek","pl":"Polish","ga":"Irish","yua":"Yucatec Maya"]
    private static func stripLabel(_ raw:String,language:String)->String {
        let names=(labels[language] ?? []) + [languageNames[language] ?? language]
        let prefixes=["Target","Support","Translation","Traducción","Translated"]
        var tokens:[String]=[]
        for name in names {tokens += [name,name+" translation",name+" Translation",name+" traducción",name+" Traducción"]}
        for prefix in prefixes {tokens.append(prefix);for name in names {tokens += ["\(prefix) (\(name))","\(prefix) \(name)","\(name) \(prefix.lowercased())"]}}
        let pattern="^(?:"+tokens.map(NSRegularExpression.escapedPattern(for:)).joined(separator:"|")+")\\s*[:\\-–—]\\s*"
        var result=raw.trimmingCharacters(in:.whitespacesAndNewlines).replacingOccurrences(of:pattern,with:"",options:[.regularExpression,.caseInsensitive])
        result=result.replacingOccurrences(of:"^\\[\\s*|\\s*\\]$",with:"",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines)
        return result.replacingOccurrences(of:"^[•·\\-–—]+\\s*",with:"",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines)
    }
    private static func stripSpeaker(_ text:String)->String {
        let pattern="^(?!(?:notice|announcement|hours|schedule|warning|attention|bulletin|aviso|atención|horario|location|date|time|price|note|tip|ingredients|opening hours|opening times)\\s*:)[A-ZÁÉÍÓÚÑa-z0-9_\\s]{1,15}\\s*:\\s+"
        return text.replacingOccurrences(of:pattern,with:"",options:[.regularExpression,.caseInsensitive]).trimmingCharacters(in:.whitespacesAndNewlines)
    }
}
