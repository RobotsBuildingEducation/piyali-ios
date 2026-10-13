import Foundation

public struct Placement: Codable, Equatable, Sendable {
    public let level: String
    public let score: Int
    public let source: String
    public let selectedIDs: [String]
    public let updatedAt: Date
    public var gradedAtPlacement: Int? = nil
}
public struct PlacementOption: Identifiable, Sendable {
    public let id: String
    public let level: String
    public let score: Int
    public let label: String
    public var modifier = false
}
public enum PlacementAssessment {
    public static let options: [PlacementOption] = [
        .init(id:"understands_more",level:"Pre-A1",score:3,label:"I understand more than I can speak"),
        .init(id:"common_words",level:"A1",score:18,label:"I know some common words and phrases"),
        .init(id:"home_language",level:"A1",score:25,label:"I mostly speak this language at home"),
        .init(id:"basic_conversations",level:"A2",score:32,label:"I can have basic conversations"),
        .init(id:"read_write",level:"B1",score:53,label:"I can comfortably read and write"),
        .init(id:"stories_opinions",level:"B1",score:53,label:"I can tell stories and express my opinions"),
        .init(id:"grammar_struggle",level:"A1",score:18,label:"I struggle with grammar",modifier:true),
        .init(id:"complex_topics",level:"B2",score:67,label:"I can discuss complex topics in detail"),
        .init(id:"professional_use",level:"B2",score:67,label:"I use this language professionally or academically"),
        .init(id:"nuance_precision",level:"C1",score:81,label:"I can express myself naturally, with nuance and precision")
    ]
    public static func estimate(_ selected: Set<String>, now: Date = Date()) -> Placement? {
        let picked = options.filter { selected.contains($0.id) }
        let milestones = picked.filter { !$0.modifier }
        guard let strongest = (milestones.isEmpty ? picked : milestones).max(by: { $0.score < $1.score }) else { return nil }
        return Placement(level:strongest.level,score:strongest.score,source:"self_report",selectedIDs:picked.map(\.id),updatedAt:now)
    }
}
public extension LearnerState {
    var tutorLevel: String { tutorLevels?[target] ?? placements?[target]?.level ?? "Pre-A1" }
    var flashcardLevel: String { flashcardLevels?[target] ?? level }
    mutating func place(_ placement: Placement) {
        guard LearningLanguages.levels.contains(placement.level) else { return }
        var placement = placement; placement.gradedAtPlacement = gradedByLanguage?[target] ?? 0
        if placements == nil { placements = [:] }; placements?[target] = placement
        if pendingPlacements == nil { pendingPlacements = [:] }; pendingPlacements?[target] = placement
        preferencesModifiedAt = placement.updatedAt
        level = placement.level
        if lessonLevels == nil { lessonLevels = [:] }; lessonLevels?[target] = level
        if flashcardLevels == nil { flashcardLevels = [:] }; flashcardLevels?[target] = level
        if tutorLevels == nil { tutorLevels = [:] }; tutorLevels?[target] = level
        if (gradedByLanguage?[target] ?? 0) == 0 {
            if ratingByLanguage == nil { ratingByLanguage = [:] }
            ratingByLanguage?[target] = PerformanceScore.rating(score:Double(placement.score))
        }
    }
    func unlockedLevels(mode: String, index: [String:[String]]) -> [String] {
        let placementIndex = LearningLanguages.levels.firstIndex(of:placements?[target]?.level ?? "") ?? 0
        var highest = 0
        for i in 0..<(LearningLanguages.levels.count - 1) {
            let level = LearningLanguages.levels[i], ids = index[level] ?? []
            let localCount = ids.filter { (mode == "flashcards" ? flashcardMastery : completed).contains(mode == "tutor" ? tutorKey($0) : completionKey($0)) }.count
            let summaryCount = courseCompletion?[target]?[mode]?[level] ?? 0
            if i < placementIndex || (!ids.isEmpty && max(localCount,summaryCount) >= ids.count) { highest = i + 1 }
            else { break }
        }
        return Array(LearningLanguages.levels.prefix(highest + 1))
    }
}
