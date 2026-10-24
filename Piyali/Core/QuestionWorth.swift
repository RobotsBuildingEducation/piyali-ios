import Foundation

/// Fixed source quote rules; model difficulty never becomes a point award.
public enum QuestionWorth {
    public static func supportName(independent:Bool,provided:String?)->String {if let provided {return ["modeled","prompted","lightly supported","independent","transferred"].contains(provided) ? provided:"prompted"};return independent ? "independent":"prompted"}
    public static func delta(level:String,correct:Bool,independent:Bool,worth:JSONValue,support:String? = nil)->Double? {
        let support=supportName(independent:independent,provided:support)
        let rawGain=worth["gainBySupport"][support] == .null ? worth["gainBySupport"]["prompted"] : worth["gainBySupport"][support]
        guard worth["version"].number == 4,worth["questionLevel"].string == level,
              case .number(let origin)=worth["ratingAtGeneration"],origin.isFinite,(800...2200).contains(origin),
              case .number(let gain)=rawGain,gain.isFinite,(0...21).contains(gain),
              case .number(let loss)=worth["loss"],loss.isFinite,(0...4).contains(loss) else { return nil }
        return correct ? gain : -loss
    }
    public static func rating(_ rating:Double,level:String,correct:Bool,independent:Bool,worth:JSONValue?,support:String? = nil)->Double {
        if let worth,let delta=delta(level:level,correct:correct,independent:independent,worth:worth,support:support) { return min(2200,max(800,rating+delta)) }
        return PerformanceScore.update(rating:rating,questionLevel:level,correct:correct,independent:independent,support:support)
    }
    public static func evidenceLevel(level:String,correct:Bool,independent:Bool,worth:JSONValue?,support:String? = nil)->String {
        guard let worth,delta(level:level,correct:correct,independent:independent,worth:worth,support:support) != nil,
              case .number(let score)=worth["difficultyScore"],score.isFinite,(0...100).contains(score) else { return level }
        return zip(LearningLanguages.levels,[14.0,28,42,56,70,84,100]).first { score <= $0.1 }?.0 ?? "C2"
    }
    public static func gradedBucket(_ fields:[String:Any],change:PracticeChange)->[String:Any] {
        guard let correct=change.correct else { return fields }
        var result=fields,elo=fields["elo"] as? [String:Any] ?? [:],summary=fields["performanceSummary"] as? [String:Any] ?? [:]
        let id=change.id.uuidString,ids=elo["recentEventIds"] as? [String] ?? [];guard !ids.contains(id) else { return fields }
        let baseline=WebProgressContract.integer(elo["scaleVersion"]) == 4 ? WebProgressContract.number(elo["rating"],default:800) : 800
        let independent=change.independent ?? false,level=evidenceLevel(level:change.level,correct:correct,independent:independent,worth:change.gradedWorth,support:change.gradedSupport),time=WebProgressContract.iso(change.date)
        var levels=summary["byLevel"] as? [String:[String:Any]] ?? [:],counts=levels[level] ?? ["correct":0,"missed":0]
        counts["correct"]=WebProgressContract.integer(counts["correct"])+(correct ? 1 : 0);counts["missed"]=WebProgressContract.integer(counts["missed"])+(correct ? 0 : 1);levels[level]=counts
        let concept=String((change.gradedConcept ?? "").trimmingCharacters(in:.whitespacesAndNewlines).prefix(100)),old=summary["weakConcepts"] as? [[String:Any]] ?? []
        var weak=old.filter { $0["concept"] as? String != concept && (WebProgressContract.date($0["lastSeen"]) ?? .distantPast) >= change.date.addingTimeInterval(-45*86400) }
        if !concept.isEmpty,!correct { let prior=old.first { $0["concept"] as? String == concept };weak.insert(["concept":concept,"questionLevel":level,"misses":min(99,WebProgressContract.integer(prior?["misses"])+1),"lastSeen":time],at:0) }
        elo=["rating":rating(baseline,level:change.level,correct:correct,independent:independent,worth:change.gradedWorth,support:change.gradedSupport),"scaleVersion":4,"updatedAt":time,"totalGraded":WebProgressContract.integer(elo["totalGraded"])+1,"recentEventIds":Array(([id]+ids).prefix(40))]
        summary=["byLevel":levels,"weakConcepts":Array(weak.prefix(5)),"recentResults":Array(([correct ? 1 : 0]+(summary["recentResults"] as? [Int] ?? [])).prefix(10)),"lastQuestionLevel":level,"lastMode":String((change.gradedMode ?? "").trimmingCharacters(in:.whitespacesAndNewlines).prefix(32)),"lastSupport":correct ? supportName(independent:independent,provided:change.gradedSupport) : "missed","updatedAt":time]
        result["version"]=1;result["elo"]=elo;result["performanceSummary"]=summary;return result
    }

}
