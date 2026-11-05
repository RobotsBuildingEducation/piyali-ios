import Foundation

/// The web reveals only complete nonempty lines and ignores output beyond the
/// number of source sentences. Partial lines are included only at stream end.
public enum ReadingTranslationStream {
    public static func lines(_ snapshot:String,limit:Int,includeTrailing:Bool=false)->[String] {
        guard limit > 0,snapshot.utf8.count <= 100_000 else{return []}
        var lines=snapshot.components(separatedBy:"\n")
        if !includeTrailing {lines.removeLast()}
        return Array(lines.lazy.map { line in
            line.replacingOccurrences(of:"^\\s*\\d+[\\).:-]\\s*",with:"",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines)
        }.filter{!$0.isEmpty}.prefix(limit))
    }
}
