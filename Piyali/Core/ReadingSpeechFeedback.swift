import Foundation

/// Reading's original transcript-based practice review. Scores never change Elo.
public struct ReadingSpeechFeedback:Codable,Equatable,Sendable {
    public struct Score:Codable,Equatable,Sendable {
        public let score:Double
        public let note:String
    }
    public let summary:String
    public let scores:[String:Score]
    public static var criteria:[JSONValue] { ReadingRules.data["speechCriteria"].array }
    public init?(_ value:JSONValue) {
        guard case .object = value,value.json.utf8.count <= 16_000 else { return nil }
        summary=String(value["summary"].string.prefix(2000))
        var parsed:[String:Score]=[:]
        for criterion in Self.criteria {
            let key=criterion["key"].string,data=value["scores"][key],raw=data["score"] == .null ? data : data["score"]
            guard case .number(let score)=raw,score.isFinite else { continue }
            parsed[key]=Score(score:max(1,min(10,score)),note:String(data["note"].string.prefix(1000)))
        }
        guard !summary.isEmpty || !parsed.isEmpty else { return nil };scores=parsed
    }
    private init(summary:String) { self.summary=summary;scores=[:] }
    public static func unavailable(support:String)->Self { .init(summary:ReadingRules.data["speechUnavailable"].localized(support)) }
    public var total:Double { scores.values.reduce(0) { $0+$1.score } }
    public var maximum:Int { scores.count*10 }
    public static func color(_ score:Double)->String { score >= 8 ? "green" : score >= 6 ? "teal" : score >= 4 ? "yellow" : "purple" }
    public var value:JSONValue { .object(["summary":.string(summary),"scores":.object(scores.mapValues { .object(["score":.number($0.score),"note":.string($0.note)]) })]) }
}
