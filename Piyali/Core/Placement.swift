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
        legacyFirstRunPlacement=nil
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

/// Source course summaries distinguish a missing count from a real zero, and
/// their stored total takes precedence over the currently bundled path length.
public struct TutorLevelCompletion:Equatable,Sendable {
    public let completed:Double
    public let total:Double
    public var isComplete:Bool {total>0 && completed>=total}
    public var progress:Int {total>0 ? Int(min(Double(Int.max).nextDown,(completed/total*100).rounded())):0}
}
public enum TutorProgression {
    public static func highest(_ levels:[String])->String {
        LearningLanguages.levels[levels.compactMap{LearningLanguages.levels.firstIndex(of:$0)}.max() ?? 0]
    }
    public static func earned(_ status:[String:TutorLevelCompletion])->String {
        var index=0
        for (i,level) in LearningLanguages.levels.enumerated() where status[level]?.isComplete == true {index=min(i+1,LearningLanguages.levels.count-1)}
        return LearningLanguages.levels[index]
    }
    static func finiteNumber(_ value:JSONValue?)->Double? {
        let n:Double?
        switch value {case .number(let v):n=v;case .string(let v):let text=v.trimmingCharacters(in:.whitespacesAndNewlines);n=text.isEmpty ? 0:Double(text);case .bool(let v):n=v ? 1:0;case .null:n=0;default:n=nil}
        return n.flatMap{$0.isFinite ? max(0,$0):nil}
    }
    public static func completion(summary:JSONValue,level:String,fallbackTotal:Int,localCompleted:Int)->TutorLevelCompletion {
        let stored=summary["tutor"]["levels"][level.lowercased().replacingOccurrences(of:"-",with:"_")].object
        let rawTotal=finiteNumber(stored["total"]) ?? Double(max(0,fallbackTotal))
        return .init(completed:finiteNumber(stored["completed"]) ?? Double(max(0,localCompleted)),total:rawTotal>0 ? rawTotal:Double(max(0,fallbackTotal)))
    }
    public static func merging(_ first:[String:String]?,_ second:[String:String]?)->[String:String] {
        var result:[String:String]=[:]
        for (lang,level) in (first ?? [:]).merging(second ?? [:],uniquingKeysWith:{highest([$0,$1])}) where LearningLanguages.levels.contains(level) {result[lang.lowercased()]=highest([result[lang.lowercased()] ?? "Pre-A1",level])}
        return result
    }
}
public extension LearnerState {
    mutating func importCourseSummary(_ summary:JSONValue,target:String) {
        if courseSummaries == nil {courseSummaries=[:]};courseSummaries?[target]=summary
        if courseCompletion == nil {courseCompletion=[:]};if courseCompletion?[target] == nil{courseCompletion?[target]=[:]}
        for mode in ["skillTree","flashcards","tutor"] {
            var counts:[String:Int]=[:]
            for level in LearningLanguages.levels {
                let entry=summary[mode]["levels"][level.lowercased().replacingOccurrences(of:"-",with:"_")]
                if let n=TutorProgression.finiteNumber(entry.object["completed"]) {counts[level]=Int(min(Double(Int.max).nextDown,n))}
            }
            courseCompletion?[target]?[mode]=counts
        }
    }
    func tutorCompletion(level:String,index:[String:[String]])->TutorLevelCompletion {
        let ids=index[level] ?? [],localCount=ids.filter{completed.contains(tutorKey($0))}.count
        var summary=courseSummaries?[target] ?? .object([:])
        let key=level.lowercased().replacingOccurrences(of:"-",with:"_")
        if summary["tutor"]["levels"][key].object["completed"] == nil,let count=courseCompletion?[target]?["tutor"]?[level] {
            summary=summary.setting("tutor",summary["tutor"].setting("levels",summary["tutor"]["levels"].setting(key,.object(["completed":.number(Double(count))]))))
        }
        return TutorProgression.completion(summary:summary,level:level,fallbackTotal:ids.count,localCompleted:localCount)
    }
    func earnedTutorLevel(index:[String:[String]])->String {
        let status=Dictionary(uniqueKeysWithValues:LearningLanguages.levels.map{($0,tutorCompletion(level:$0,index:index))})
        return TutorProgression.highest([TutorProgression.earned(status),tutorUnlockedLevels?[target] ?? "Pre-A1"])
    }
    mutating func reconcileTutorUnlock(index:[String:[String]]) {
        let earned=earnedTutorLevel(index:index)
        guard earned != "Pre-A1" else{return}
        if tutorUnlockedLevels == nil {tutorUnlockedLevels=[:]};tutorUnlockedLevels?[target]=earned
    }
    func availableTutorLevels(index:[String:[String]],lessons:[String],flashcards:[String])->[String] {
        let ceiling=TutorProgression.highest([lessons.last ?? "Pre-A1",flashcards.last ?? "Pre-A1",earnedTutorLevel(index:index)])
        return Array(LearningLanguages.levels.prefix((LearningLanguages.levels.firstIndex(of:ceiling) ?? 0)+1))
    }
}
