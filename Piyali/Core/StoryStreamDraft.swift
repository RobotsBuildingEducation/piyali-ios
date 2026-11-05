import Foundation

/// Complete speaking records displayed while the source stream is in flight.
/// These records require final validation and assessment before they can earn XP.
public enum StoryStreamDraft {
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
