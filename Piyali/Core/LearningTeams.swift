import Foundation

/// Wire templates and progress rows from the main web learningTeams.js contract.
public enum LearningTeams {
    public static let kind=30078
    public static let relays=["wss://relay.primal.net","wss://relay.ditto.pub","wss://nos.lol"]
    public static func teamIdentifier(_ id: String) -> String { "learning-team:"+id }
    public static func leaveIdentifier(creator: String, id: String) -> String { "learning-team-left:"+creator+":"+id }
    public static func memberLeft(teamCreatedAt: Int64, leaveCreatedAt: Int64?) -> Bool { leaveCreatedAt.map { $0 >= teamCreatedAt } ?? false }
    public static func teamTemplate(id: String, name: String, members: [String], createdAt: Int64, deleted: Bool = false) -> JSONValue {
        var seen=Set<String>()
        let unique=members.filter { seen.insert($0).inserted }
        let tags=[["d",teamIdentifier(id)],["t","learning-team"],["name",name]]+(deleted ? [["deleted"]] : [])+unique.map { ["p",$0] }
        return .object(["kind":.number(Double(kind)),"created_at":.number(Double(createdAt)),"content":.string(JSONValue.object(["name":.string(name),"createdAt":.number(Double(createdAt))]).json),"tags":.array(tags.map { .array($0.map(JSONValue.string)) })])
    }
    public static func leaveTemplate(creator: String, id: String, createdAt: Int64) -> JSONValue {
        .object(["kind":.number(Double(kind)),"created_at":.number(Double(createdAt)),"content":.string(""),"tags":.array([["d",leaveIdentifier(creator:creator,id:id)],["t","learning-team-left"],["a","\(kind):\(creator):\(teamIdentifier(id))"]].map { .array($0.map(JSONValue.string)) })])
    }
    private static func numeric(_ value: JSONValue) -> Double {
        let n:Double
        switch value { case .number(let v):n=v;case .string(let v):n=Double(v.trimmingCharacters(in:.whitespacesAndNewlines)) ?? 0;case .bool(let v):n=v ? 1 : 0;default:n=0 }
        return n.isFinite ? n : 0
    }
    public static func progressRow(member: String, data: JSONValue, creator: Bool) -> JSONValue {
        let schema=numeric(data["schemaVersion"]),rawScore=data["score"]
        let score:JSONValue
        let parsed:Double?;switch rawScore { case .number(let v):parsed=v;case .string(let v):parsed=v.isEmpty ? nil : Double(v.trimmingCharacters(in:.whitespacesAndNewlines)) ?? (v.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty ? 0 : nil);case .bool(let v):parsed=v ? 1 : 0;default:parsed=nil }
        if schema >= 2,data["scoreScale"].string == "0-100",let parsed,parsed.isFinite { score = .number(max(0,min(100,parsed))) } else { score = .null }
        let companion:JSONValue
        if schema >= 2,case .object=data["companion"] {
            let pet=data["companion"],level=max(1,floor(numeric(pet["level"])))
            companion = .object(["name":.string(String(pet["name"].string.prefix(80))),"type":.string(CompanionTypes.effective(pet["type"].string.lowercased(),level:Int(min(Double(Int.max).nextDown,level)))),"level":.number(level),"health":.number(max(0,min(100,numeric(pet["health"]))))])
        } else { companion = .object(["name":.string(""),"type":.string("ghost"),"level":.number(1),"health":.number(100)]) }
        let goal=data["goal"] == .null ? data["dailyGoalXp"] : data["goal"]
        return .object(["npub":.string(member),"name":.string(data["name"].string.trimmingCharacters(in:.whitespacesAndNewlines)),"targetLang":.string(data["targetLang"].string),"level":.string(data["level"].string.isEmpty ? "—" : data["level"].string),"score":score,"scoreLevel":.string(score == .null ? "" : data["scoreLevel"].string.isEmpty ? ConversationPractice.difficultyLevel(score.number) : data["scoreLevel"].string),"companion":companion,"streak":.number(numeric(data["streak"])),"answeredStepsCount":.number(numeric(data["answeredStepsCount"])),"dailyProgress":.number(numeric(data["progressPercent"])),"progressPercent":.number(numeric(data["progressPercent"])),"totalXp":.number(numeric(data["xp"])),"dailyGoalXp":.number(numeric(goal)),"dailyXp":.number(numeric(data["dailyXp"])),"isCreator":.bool(creator)])
    }
    public static func snapshot(_ state: LearnerState, now: Date = Date()) -> JSONValue {
        let level=[state.level,state.flashcardLevel,state.tutorLevel,state.placements?[state.target]?.level ?? "Pre-A1"].max { (LearningLanguages.levels.firstIndex(of:$0) ?? 0) < (LearningLanguages.levels.firstIndex(of:$1) ?? 0) } ?? state.level
        return .object(["schemaVersion":.number(2),"targetLang":.string(state.target),"name":.string(state.name.trimmingCharacters(in:.whitespacesAndNewlines)),"xp":.number(Double(state.totalXP)),"level":.string(level),"score":.number(Double(state.score)),"scoreScale":.string("0-100"),"scoreLevel":.string(PerformanceScore.level(score:state.score)),"goal":.number(Double(state.dailyGoal)),"dailyGoalXp":.number(Double(state.dailyGoal)),"dailyXp":.number(Double(state.dailyXP)),"streak":.number(Double(state.streak)),"progressPercent":.number(state.dailyGoal > 0 ? min(100,floor(Double(state.dailyXP)/Double(state.dailyGoal)*100+0.5)) : 0),"companion":.object(["name":.string(state.companionName),"type":.string(state.effectiveCompanionType),"level":.number(Double(state.companionLevel)),"health":.number(Double(state.companionHealth))]),"updatedAt":.number(floor(now.timeIntervalSince1970))])
    }
}
