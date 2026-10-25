import Foundation

public struct CommunityMilestone: Equatable, Sendable {
    public let question: Double?
    public let totalXP: Double?
    public let goalPercent: Double?
    public var questionPercent: Double? { question.map { min(100,$0/120*100) } }
    public static func parse(content:String,tags:[[String]],name:String) -> Self? {
        guard !["data","test","hi","text","hii"].contains(name.lowercased()) else { return nil }
        let expression=try! NSRegularExpression(pattern:"question ([0-9]+)",options:.caseInsensitive)
        let range=NSRange(content.startIndex...,in:content)
        let question=expression.firstMatch(in:content,range:range).flatMap { Range($0.range(at:1),in:content) }.flatMap { Double(content[$0]) }.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        let progress=tags.contains { $0.count >= 2 && $0[0] == "purpose" && $0[1] == "nosaboProgress" } || content.lowercased().contains("i just reached")
        guard question != nil || progress || content.lowercased().contains("a new scholarship") else { return nil }
        func number(_ key:String) -> Double? {
            guard let raw=tags.first(where:{ $0.count >= 2 && $0[0] == key })?[1] else { return nil }
            let trimmed=raw.trimmingCharacters(in:.whitespacesAndNewlines)
            guard let value=trimmed.isEmpty ? 0 : Double(trimmed),value.isFinite else { return nil };return value
        }
        return Self(question:question,totalXP:progress ? number("total_xp") : nil,goalPercent:progress ? number("daily_goal_percent").map { max(0,min(100,$0)) } : nil)
    }
    public static func progress(_ learner:LearnerState,totalXP:Int?=nil,languageLabel:String?=nil) -> (content:String,tags:[[String]]) {
        let language=languageLabel ?? LearningLanguages.names[learner.target] ?? learner.target.uppercased(),xp=totalXP ?? learner.totalXP
        var tags=[["t","learnwithnostr"],["purpose","nosaboProgress"],["total_xp",String(xp)]]
        let content:String
        if learner.dailyGoal > 0 {
            let percent=Int(max(0,min(100,(Double(learner.dailyXP)/Double(learner.dailyGoal)*100).rounded())))
            content="I'm \(percent)% through today's \(learner.dailyGoal) XP goal (\(learner.dailyXP)/\(learner.dailyGoal) XP) and now have \(xp) XP total on https://piyali.app practicing \(language)! #LearnWithNostr"
            tags += [["daily_goal_percent",String(percent)],["daily_xp",String(learner.dailyXP)],["daily_goal_target",String(learner.dailyGoal)]]
        } else { content="I just reached \(xp) XP on https://piyali.app practicing \(language)! #LearnWithNostr" }
        return (content,tags)
    }
}
