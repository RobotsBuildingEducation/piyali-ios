import Foundation

public struct ConversationGoal: Codable, Identifiable, Equatable, Sendable {
    public var id=UUID()
    public var text: JSONValue
    public var questionLevel: String
    public var worth: JSONValue
    public var completed=false
    public var misses=0
    public var guidance=""
    public var starter: String?
    public init(text: JSONValue, questionLevel: String, worth: JSONValue) { self.text=text;self.questionLevel=questionLevel;self.worth=worth }
}
public struct ConversationVerdict: Codable, Equatable, Sendable {
    public let completed: Bool
    public let reason: String
    public let goalStillFits: Bool?
    public init(completed: Bool, reason: String, goalStillFits: Bool? = true) { self.completed=completed;self.reason=reason;self.goalStillFits=goalStillFits }
}
public struct ConversationMessage: Codable, Identifiable, Equatable, Sendable {
    public var id=UUID()
    public let role: String
    public var text: String
    public var translation: String?
    public init(role: String, text: String) { self.role=role;self.text=String(text.prefix(2000)) }
}
public struct ConversationDraft: Codable, Equatable, Sendable {
    public var id=UUID()
    public var goal: ConversationGoal?
    public var messages: [ConversationMessage]=[]
    public var interests=""
    public var challengeLevel: String?
    public var pronunciation=false
    public var personality=""
    public var turns=0
    public var goalsCompleted=0
    public var earnedXP=0
    public var seenTurnIDs: [UUID]=[]
    public init() {}
    public mutating func append(_ message: ConversationMessage) {
        messages.append(message);messages=Array(messages.suffix(40))
        while messages.count > 1,(try? JSONEncoder().encode(self).count) ?? 0 > 24_000 { messages.removeFirst() }
    }
    public var transcript: String { messages.map { ($0.role == "user" ? "You: " : "Piyali: ")+$0.text }.joined(separator:"\n") }
}
public struct ConversationVoiceContext: Sendable {
    private var previous="",output="",answered=""
    public init() {}
    public mutating func inputStarted() { answered=output.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty ? previous : output }
    public mutating func appendAssistant(_ text: String) { output=String((output+text).suffix(4000)) }
    public mutating func interrupted() { if !output.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty { previous=output };output="" }
    public mutating func finish() -> (answered:String,reply:String) {
        let value=(answered,output)
        if !output.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty { previous=output }
        output="";return value
    }
}
public enum ConversationPractice {
    public static func completionID(target: String, goal: ConversationGoal) -> String? {
        guard !target.isEmpty,!goal.text["en"].string.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return nil }
        return target+":"+goal.id.uuidString.lowercased()
    }
    public static func worth(rating: Double, level: String, difficulty: Double? = nil) -> JSONValue {
        let valid=difficulty.flatMap { $0.isFinite && (0...100).contains($0) ? $0 : nil }
        let target=valid.map { 800+$0*14 } ?? PerformanceScore.rating(score:PerformanceScore.difficulties[level] ?? 21)
        let expected=1/(1+pow(10,(target-rating)/400))
        let weights=["modeled":0.55,"prompted":0.7,"lightly supported":0.85,"independent":1.0,"transferred":1.0]
        let gains=weights.mapValues { rating <= 800 ? 21 : max(0,min(2200-rating,4*(1-expected)*$0)) }
        let assessed=valid.map { difficultyLevel($0) } ?? level
        return .object(["version":.number(4),"ratingAtGeneration":.number(rating),"questionLevel":.string(level),"difficultyScore":valid.map(JSONValue.number) ?? .null,"assessedQuestionLevel":.string(assessed),"difficultySource":.string(valid == nil ? "cefr_fallback" : "model_assessment"),"gainBySupport":.object(gains.mapValues(JSONValue.number)),"loss":.number(max(0,min(rating-800,4*expected)))])
    }
    public static func rating(_ rating: Double, level: String, success: Bool, worth: JSONValue) -> Double {
        let quoted=worth["gainBySupport"]["independent"].number,loss=worth["loss"].number
        guard worth["version"].number == 4,worth["questionLevel"].string == level,(800...2200).contains(worth["ratingAtGeneration"].number),(0...21).contains(quoted),(0...4).contains(loss),case .number=worth["gainBySupport"]["independent"],case .number=worth["loss"] else { return PerformanceScore.update(rating:rating,questionLevel:level,correct:success,independent:true) }
        return max(800,min(2200,rating+(success ? quoted : -loss)))
    }
    public static func nextGoal(_ goal: ConversationGoal) -> Bool { goal.completed || goal.misses >= 2 || goal.guidance == "__reanchor__" }
    public static func difficultyLevel(_ score: Double) -> String { zip(LearningLanguages.levels,[14.0,28,42,56,70,84,100]).first { score <= $0.1 }?.0 ?? "C2" }
    public static func gradedBucket(_ fields: [String:Any], change: PracticeChange) -> [String:Any] {
        guard let success=change.correct else { return fields }
        var result=fields,elo=fields["elo"] as? [String:Any] ?? [:],summary=fields["performanceSummary"] as? [String:Any] ?? [:]
        let ids=elo["recentEventIds"] as? [String] ?? [],id=change.id.uuidString
        guard !ids.contains(id) else { return fields }
        let rating=WebProgressContract.integer(elo["scaleVersion"]) == 4 ? WebProgressContract.number(elo["rating"],default:800) : 800
        let worth=change.conversationWorth ?? .null,level: String
        if case .number(let difficulty)=worth["difficultyScore"],(0...100).contains(difficulty) { level=difficultyLevel(difficulty) } else { level=change.level }
        let time=WebProgressContract.iso(change.date)
        elo=["rating":self.rating(rating,level:change.level,success:success,worth:worth),"scaleVersion":4,"updatedAt":time,"totalGraded":WebProgressContract.integer(elo["totalGraded"])+1,"recentEventIds":Array(([id]+ids).prefix(40))]
        var levels=summary["byLevel"] as? [String:[String:Any]] ?? [:],counts=levels[level] ?? [:]
        if counts["correct"] == nil { counts["correct"]=0 };if counts["missed"] == nil { counts["missed"]=0 }
        counts[success ? "correct" : "missed"]=WebProgressContract.integer(counts[success ? "correct" : "missed"])+1;levels[level]=counts
        let concept=String((change.conversationGoalText?["en"].string ?? "").trimmingCharacters(in:.whitespacesAndNewlines).prefix(100)),old=summary["weakConcepts"] as? [[String:Any]] ?? []
        var weak=old.filter { $0["concept"] as? String != concept && (WebProgressContract.date($0["lastSeen"]) ?? .distantPast) >= change.date.addingTimeInterval(-45*86400) }
        if !concept.isEmpty,!success { let prior=old.first { $0["concept"] as? String == concept };weak.insert(["concept":concept,"questionLevel":level,"misses":min(99,WebProgressContract.integer(prior?["misses"])+1),"lastSeen":time],at:0) }
        summary=["byLevel":levels,"weakConcepts":Array(weak.prefix(5)),"recentResults":Array(([success ? 1 : 0]+(summary["recentResults"] as? [Int] ?? [])).prefix(10)),"lastQuestionLevel":level,"lastMode":change.source == .readingTurn ? "reading" : change.source == .storyTurn ? "story" : "conversation","lastSupport":success ? "independent" : "missed","updatedAt":time]
        result["version"]=1;result["elo"]=elo;result["performanceSummary"]=summary;return result
    }
}
public extension LearnerState {
    var conversation: ConversationDraft { conversationDrafts?[target] ?? ConversationDraft() }
    mutating func saveConversation(_ draft: ConversationDraft) { if conversationDrafts == nil { conversationDrafts=[:] };conversationDrafts?[target]=draft }
    /// Each real turn counts once. A goal miss/drift gets no turn XP; only a demonstrated completed goal earns its bonus/proof.
    @discardableResult mutating func conversationTurn(id: UUID, answer: String, verdict: ConversationVerdict?, turnXP: Int, goalXP: Int, now: Date = Date()) -> Int {
        var draft=conversation
        guard !answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,!draft.seenTurnIDs.contains(id) else { return 0 }
        draft.seenTurnIDs=Array((draft.seenTurnIDs+[id]).suffix(256));draft.turns += 1
        let goal=draft.goal,gradable=answer.count >= 3 && goal?.completed == false && goal?.text["en"].string.isEmpty == false
        let checked=gradable ? verdict : nil,success=checked?.completed == true,drift=checked?.goalStillFits == false && !success
        let completion=success ? goal.flatMap { ConversationPractice.completionID(target:target,goal:$0) } : nil
        let first=completion.map { !(completedConversationGoals ?? []).contains($0) } ?? false
        let amount=checked != nil && !success ? 0 : max(1,min(3,turnXP)),bonus=first ? max(2,min(4,goalXP)) : 0
        var change=PracticeChange(date:now,dayKey:CalendarDay.key(now),target:target,level:goal?.questionLevel ?? PerformanceScore.level(score:score),amount:amount,source:.conversation)
        change.id=id;change.conversationGoalID=completion;change.conversationBonus=bonus;change.conversationWorth=goal?.worth;change.conversationGoalText=goal?.text
        if (success && first) || (checked != nil && !success && !drift) {
            change.correct=success;change.independent=true
            let updated=ConversationPractice.rating(rating,level:change.level,success:success,worth:goal?.worth ?? .null)
            if ratingByLanguage == nil { ratingByLanguage=[:] };ratingByLanguage?[target]=updated
            if gradedByLanguage == nil { gradedByLanguage=[:] };gradedByLanguage?[target,default:0] += 1
        }
        if success { draft.goal?.completed=true;draft.goal?.guidance="";draft.goal?.misses=0;if first { draft.goalsCompleted += 1;if completedConversationGoals == nil { completedConversationGoals=[] };completedConversationGoals?.insert(completion!) } }
        else if let checked { draft.goal?.misses += 1;draft.goal?.guidance=drift ? "__reanchor__" : checked.reason }
        let earned=amount+bonus;draft.earnedXP += earned;saveConversation(draft)
        if earned > 0 { addXP(earned,now:now,calendar:.current) }
        enqueue(change);return earned
    }
}
