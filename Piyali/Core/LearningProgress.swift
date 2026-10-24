import Foundation

public enum PerformanceScore {
    // Port of performanceEloModel.js score-scale v4, with CEFR fallback difficulty.
    public static let version = 4
    public static let defaults: [String: Double] = ["Pre-A1":1,"A1":18,"A2":32,"B1":46,"B2":60,"C1":74,"C2":89]
    public static let difficulties: [String: Double] = ["Pre-A1":7,"A1":21,"A2":35,"B1":49,"B2":63,"C1":77,"C2":93]
    public static func rating(score: Double) -> Double { score <= 0 ? 800 : score >= 100 ? 2200 : 800 + (score + 0.5) * 14 }
    public static func score(rating: Double) -> Int { max(0,min(100,Int(floor((rating - 800)/14 + 1e-8)))) }
    public static func level(score: Int) -> String {
        zip(LearningLanguages.levels,[14,28,42,56,70,84,100]).first { score <= $0.1 }?.0 ?? "C2"
    }
    public static func update(rating: Double, questionLevel: String, correct: Bool, independent: Bool, support:String? = nil) -> Double {
        if rating <= 800 && correct { return self.rating(score: 1) }
        let difficulty = self.rating(score: difficulties[questionLevel] ?? 21)
        let expected = 1 / (1 + pow(10,(difficulty - rating)/400))
        let weights:[String:Double] = ["modeled":0.55,"prompted":0.7,"lightly supported":0.85,"independent":1,"transferred":1]
        let weight=weights[QuestionWorth.supportName(independent:independent,provided:support)] ?? 0.7
        let delta = correct ? 4 * (1 - expected) * weight : -4 * expected
        return max(800,min(2200,rating+delta))
    }
}
public enum CompanionTypes {
    public static let unlocks = ["ghost":1,"alien":2,"robot":5,"slime":10,"dog":20,"axolotl":40]
    public static let ordered = ["ghost","alien","robot","slime","dog","axolotl"]
    public static func available(level: Int) -> [String] { ordered.filter { unlocks[$0,default:1] <= level } }
    public static func effective(_ type: String, level: Int) -> String { available(level: level).contains(type) ? type : "ghost" }
}
public struct FocusedPlan: Codable, Sendable {
    public let title: String
    public let objective: String
    public let words: [String]
    public let grammar: [String]
    public let scenarios: [String]
    public let successCriteria: [String]
}
public struct AchievementDefinition: Codable, Identifiable, Sendable {
    public let id: String
    public let tier: String
    public let title: JSONValue
    public let description: JSONValue
    public let requirement: JSONValue
    public let progression: Bool?
    public let catalogVersion: Int?
    public let orb: JSONValue?
    public let number: Int?
}
