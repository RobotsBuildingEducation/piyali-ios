import Foundation

/// Keep generated reference answers in the offered bank before choosing its renderer.
public enum StandardChoiceRepair {
    public static func prompt(_ source:String)->String {
        source.replacingOccurrences(of:#"(?m)^(\s*\{\s*"type"\s*:\s*"vocab_(?:mc|ma)"\s*,\s*"phase"\s*:\s*"choices")\s*:\s*\["#,with:"$1,\"choices\":[",options:.regularExpression)
    }
    public static func normalized(_ text:String)->String{
        let lowered=text.lowercased().decomposedStringWithCanonicalMapping,allowed=CharacterSet.alphanumerics.union(.whitespacesAndNewlines).union(CharacterSet(charactersIn:"'_"))
        var scalars=String.UnicodeScalarView(),latin=false
        for scalar in lowered.unicodeScalars {
            if CharacterSet.nonBaseCharacters.contains(scalar){if !latin{scalars.append(scalar)};continue}
            latin=(0x61...0x7a).contains(scalar.value)||(0x00c0...0x024f).contains(scalar.value)||(0x1e00...0x1eff).contains(scalar.value)
            if allowed.contains(scalar){scalars.append(scalar)}
        }
        let cleaned=String(scalars).precomposedStringWithCanonicalMapping.split(whereSeparator:{$0.isWhitespace}).joined(separator:" ")
        return cleaned.isEmpty ? text.lowercased().precomposedStringWithCanonicalMapping.trimmingCharacters(in:.whitespacesAndNewlines):cleaned
    }
    private static func offered(_ answer:String,in choices:[String])->String? {
        choices.first{$0==answer} ?? choices.first{$0.lowercased()==answer.lowercased()} ?? choices.first{normalized($0)==normalized(answer)}
    }
    public static func repair(kind:String,payload:JSONValue,replacementIndex:Int?=nil)->JSONValue {
        guard ["mc","ma"].contains(kind)else{return payload};var choices=payload["choices"].array.map(\.string)
        guard !choices.isEmpty else{return payload}
        if kind == "mc" {
            let answer=payload["answer"].string
            if answer.isEmpty{return payload.setting("answer",.string(choices[0]))}
            if let found=offered(answer,in:choices){return payload.setting("answer",.string(found))}
            let index=replacementIndex.map{max(0,min(choices.count-1,$0))} ?? Int.random(in:choices.indices);choices[index]=answer
            return payload.setting("choices",.array(choices.map(JSONValue.string))).setting("answer",.string(answer))
        }
        let answers=payload["answers"].array.map(\.string);var valid:[String]=[]
        for answer in answers {
            if let found=offered(answer,in:choices){valid.append(found)}
            else if let index=choices.firstIndex(where:{choice in !valid.contains(where:{normalized($0)==normalized(choice)}) && !answers.contains(where:{normalized($0)==normalized(choice)})}){choices[index]=answer;valid.append(answer)}
        }
        return payload.setting("choices",.array(choices.map(JSONValue.string))).setting("answers",.array(valid.map(JSONValue.string)))
    }
}
