import Foundation

/// The web reveals only complete nonempty lines and ignores output beyond the
/// number of source sentences. Partial lines are included only at stream end.
public enum ReadingTranslationStream {
    public struct Resolution:Equatable,Sendable {
        public let lines:[String]?
        public let visible:Bool
    }
    /// History discards incomplete/failed output, but a thrown stream leaves
    /// its sentence-stack visibility on. A matching legacy support block wins.
    public static func resolve(_ snapshot:String,limit:Int,failed:Bool,supportFallback:String="")->Resolution {
        let received=lines(snapshot,limit:limit,includeTrailing:true)
        if !failed,limit > 0,received.count == limit {return .init(lines:received,visible:true)}
        let fallback=Reading.displaySentences(supportFallback)
        if limit > 0,fallback.count == limit {return .init(lines:fallback,visible:true)}
        return .init(lines:nil,visible:failed)
    }
    public static func lines(_ snapshot:String,limit:Int,includeTrailing:Bool=false)->[String] {
        guard limit > 0,snapshot.utf8.count <= 100_000 else{return []}
        var lines=snapshot.components(separatedBy:"\n")
        if !includeTrailing {lines.removeLast()}
        return Array(lines.lazy.map { line in
            line.replacingOccurrences(of:"^\\s*\\d+[\\).:-]\\s*",with:"",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines)
        }.filter{!$0.isEmpty}.prefix(limit))
    }
}
