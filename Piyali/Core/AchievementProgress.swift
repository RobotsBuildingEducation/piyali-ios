import Foundation

/// Permanent catalog rules and confirmed completion ledgers used by the main web product.
public enum AchievementProgress {
    public static func levelKey(_ level: String) -> String { level.lowercased().replacingOccurrences(of:"-",with:"_") }
    private static func integer(_ value: JSONValue) -> Bool { if case .number(let n) = value { return n.isFinite && n >= 0 && n <= 9_007_199_254_740_991 && n.rounded(.down) == n }; return false }
    public static func complete(_ stats: JSONValue) -> Bool { integer(stats["total"]) && stats["total"].number > 0 && integer(stats["completed"]) && stats["completed"].number >= stats["total"].number }
    private static func above(_ level: String, test: (String)->Bool) -> Bool {
        guard let i = LearningLanguages.levels.firstIndex(where:{ levelKey($0) == levelKey(level) }) else { return false }
        return LearningLanguages.levels[i...].contains { test(levelKey($0)) }
    }
    private static func completeSet(_ value: JSONValue) -> Bool {
        let required=value["required"].array,done=Set(value["completed"].array.map(\.string))
        return !required.isEmpty && required.allSatisfy { !$0.string.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && done.contains($0.string) }
    }
    public static func meets(_ requirement: JSONValue, evidence: JSONValue) -> Bool {
        let metric=requirement["metric"].string,target=requirement["target"].number
        switch requirement["type"].string {
        case "level_set": return !evidence["language"].string.isEmpty && above(requirement["level"].string) { complete(evidence["levels"][metric][$0]) }
        case "level_counter": return above(requirement["level"].string) { let n=evidence["levelCounts"][metric][$0]; return integer(n) && n.number >= target }
        case "counter": let n=evidence["counters"][metric];return integer(n) && n.number >= target
        case "complete_set": return (!evidence["course"].string.isEmpty || !evidence["language"].string.isEmpty) && completeSet(evidence["sets"][metric])
        case "full_language_course": return !evidence["language"].string.isEmpty && requirement["modes"].array.allSatisfy { mode in requirement["levels"].array.allSatisfy { level in above(level.string) { complete(evidence["levels"][mode.string][$0]) } } }
        default:return false
        }
    }
    public static func mergedLedger(_ ledgers: [JSONValue], allowed: Set<String>) -> JSONValue {
        var result:[String:JSONValue]=[:]
        for ledger in ledgers { for (metric,entries) in ledger.object where allowed.contains(String(metric.split(separator:":").first ?? "")) {
            var prior=result[metric]?.object ?? [:]
            for (id,amount) in entries.object where !id.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && integer(amount) && amount.number > 0 { prior[id] = .number(1) }
            result[metric] = .object(prior)
        }}
        return .object(result)
    }
    public static func recording(_ events: [JSONValue], ledger: JSONValue) -> JSONValue {
        var result=ledger.object
        for event in events where !event["metric"].string.isEmpty && !event["id"].string.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty {
            var entries=result[event["metric"].string]?.object ?? [:];entries[event["id"].string] = .number(1);result[event["metric"].string] = .object(entries)
        }
        return .object(result)
    }
    public static func snapshot(ledger: JSONValue, evidence: JSONValue) -> JSONValue {
        var result=evidence.object, counters=ledger.object.mapValues { JSONValue.number(Double($0.object.count)) }, counts:[String:JSONValue]=["goals":.object([:]),"repairs":.object([:])]
        for (metric,count) in counters { let parts=metric.split(separator:":",maxSplits:1).map(String.init); if parts.count==2 && counts[parts[0]] != nil { var levels=counts[parts[0]]!.object;levels[parts[1]]=count;counts[parts[0]] = .object(levels) } }
        counters.merge(evidence["counters"].object) { _,new in new };result["counters"] = .object(counters);result["levelCounts"] = .object(counts);return .object(result)
    }
    public static func counters(_ summary: JSONValue) -> JSONValue {
        var result:[String:JSONValue]=[:]
        for (mode,metric) in ["tutor":"tutor_lessons","skillTree":"skill_tree_lessons","flashcards":"flashcards_completed"] {
            var count:Double=0
            if summary["migration"]["complete"] != .bool(false) { for level in LearningLanguages.levels {
                let stats=summary[mode]["levels"][levelKey(level)]
                if integer(stats["completed"]) && integer(stats["total"]) && stats["total"].number > 0 { count += min(stats["completed"].number,stats["total"].number) }
            }}
            result[metric] = .number(count)
        }
        return .object(result)
    }
    public static func flashcardEvent(language: String, id: String, progress: JSONValue) -> JSONValue? {
        guard language.range(of:"^[a-z]{2,3}(?:-[a-z0-9]+)*$",options:.regularExpression) != nil,id.range(of:"^(pre-a1|a1|a2|b1|b2|c1|c2)-.+$",options:[.regularExpression,.caseInsensitive]) != nil,!progress["isGoal"].boolean,!progress["isRepair"].boolean else { return nil }
        let succeeded=progress["completed"].boolean || (integer(progress["successfulReviews"]) && progress["successfulReviews"].number > 0 && (["good","easy","hard"].contains(progress["lastReviewOutcome"].string) || integer(progress["consecutiveCorrect"]) && progress["consecutiveCorrect"].number > 0))
        return succeeded ? .object(["metric":.string("flashcards_completed:"+language),"id":.string(id)]) : nil
    }
    public static func completionProof(profile: JSONValue, summary: JSONValue, quest: JSONValue, language: String, day: String) -> (events:[JSONValue],evidence:JSONValue) {
        var events:[JSONValue]=[]
        let goal=profile["learningIntelligence"][language]["dailyGoal"],modes=goal["blueprint"]["modes"].array.map(\.string).filter { GoalPractice.targets[$0] != nil }
        let assigned=modes.isEmpty ? [goal["blueprint"]["mode"].string].filter { GoalPractice.targets[$0] != nil } : Array(Set(modes))
        if goal["completed"].boolean && !assigned.isEmpty && assigned.allSatisfy({ goal["modeProgress"][$0].number >= Double(GoalPractice.targets[$0] ?? 0) }) && !goal["blueprint"]["cefrLevel"].string.isEmpty {
            events.append(.object(["metric":.string("goals:"+levelKey(goal["blueprint"]["cefrLevel"].string)),"id":.string("\(language):\(goal["blueprint"]["dayKey"].string):\(goal["blueprint"]["goalId"].string)")]))
        }
        let repair=quest["repair"],items=repair["items"].array
        if !items.isEmpty && profile["progress"]["repairDailyActivity"][language][day].number >= max(Double(items.count),repair["target"].number) {
            for level in Set(items.map { $0["cefrLevel"].string }.filter { !$0.isEmpty }).sorted() { events.append(.object(["metric":.string("repairs:"+levelKey(level)),"id":.string("\(language):\(day):\(repair["createdAt"].string)")])) }
        }
        let immersion=profile["realWorldTasks"],tasks=immersion["tasks"].array
        if immersion["targetLang"].string == language && !immersion["generatedAt"].string.isEmpty && !tasks.isEmpty {
            for i in tasks.indices where immersion["completed"][String(i)].boolean { events.append(.object(["metric":.string("immersion_tasks"),"id":.string("\(language):\(immersion["dayKey"].string):\(immersion["generatedAt"].string):\(i)")])) }
            if immersion["rewarded"].boolean && tasks.indices.allSatisfy({ immersion["completed"][String($0)].boolean }) { events.append(.object(["metric":.string("immersion_checklists"),"id":.string("\(language):\(immersion["dayKey"].string)")])) }
        }
        let complete=summary["migration"]["complete"].boolean
        let levels=complete ? JSONValue.object(Dictionary(uniqueKeysWithValues:["tutor","skillTree","flashcards"].map { ($0,summary[$0]["levels"]) })) : .object([:])
        return (events,.object(["language":.string(language),"levels":levels,"counters":counters(complete ? summary : .object([:]))]))
    }
    public static func phonicsProof(language: String, base: [JSONValue], documents: [JSONValue]) -> (events:[JSONValue],evidence:JSONValue) {
        let authored = !base.isEmpty && base.allSatisfy { $0["authored"].boolean }
        let completed=Set(documents.filter { (!authored || $0["targetLang"].string == language) && integer($0["correctCount"]) && $0["correctCount"].number > 0 }.map { $0["letterId"].string })
        let required=Set(base.map { $0["id"].string } + (authored ? [] : documents.filter { $0["generated"].boolean }.map { $0["letterId"].string }))
        var groups:[String:Set<String>]=[:],sizes:[String:Int]=[:]
        if authored { for card in base { groups[card["deckId"].string,default:[]].insert(card["id"].string) } }
        else { for card in documents where card["generated"].boolean {
            let parts=card["letterId"].string.split(separator:"_");guard parts.count==3,parts[0]=="gen",Int(parts[1]) != nil,Int(parts[2]) != nil,integer(card["generatedDeckSize"]),card["generatedDeckSize"].number > 0 else { continue }
            let group=String(parts[1]),size=Int(card["generatedDeckSize"].number)
            if let prior=sizes[group],prior != size { sizes[group] = -1 } else { sizes[group]=size };groups[group,default:[]].insert(card["letterId"].string)
        }}
        let events=groups.keys.sorted().compactMap { id -> JSONValue? in
            let cards=groups[id]!
            let valid=authored ? !id.isEmpty && cards.isSubset(of:completed) : (sizes[id] ?? 0) > 0 && cards.count == sizes[id] && (0..<(sizes[id] ?? 0)).allSatisfy { cards.contains("gen_\(id)_\($0)") && completed.contains("gen_\(id)_\($0)") }
            return valid ? .object(["metric":.string("phonics_decks"),"id":.string(language+":"+id)]) : nil
        }
        return (events,.object(["language":.string(language),"sets":.object(["phonics_cards":.object(["required":.array(required.sorted().map(JSONValue.string)),"completed":.array(completed.sorted().map(JSONValue.string))])])]))
    }
    public static func tutorEarnedLevel(summary: JSONValue) -> String {
        var level="Pre-A1"
        for i in LearningLanguages.levels.indices where complete(summary["tutor"]["levels"][levelKey(LearningLanguages.levels[i])]) { level=LearningLanguages.levels[min(i+1,LearningLanguages.levels.count-1)] }
        return level
    }
}
