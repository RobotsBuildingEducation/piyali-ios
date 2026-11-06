import Foundation

public struct TutorLessonProgress: Codable, Equatable, Sendable {
    public var earnedXP = 0
    public var items: Set<String> = []
    public var sourceState:JSONValue? = nil
    public init() {}
}
public struct TutorTurnVerdict: Codable, Sendable {
    public let successful: Bool
    public let objectiveAdvanced: Bool
    public let mistake: Bool
    public let confidence: Double
    public let correction: String
    public let reason: String
    public let support: String
}
public enum TutorCourse {
    public static func requiredXP(_ lessonID: String) -> Int {
        if ["lesson-tutorial-1","lesson-tutorial-a1"].contains(lessonID) { return 50 }
        var hash: UInt32 = 2166136261
        for unit in lessonID.utf16 { hash = (hash ^ UInt32(unit)) &* 16777619 }
        return 60 + Int(hash % 31)
    }
    public static func agenda(_ lesson: Lesson) -> [JSONValue] {
        let items = lesson.agenda["items"].array.filter { !$0["id"].string.isEmpty }
        return items.isEmpty ? [.object(["id":.string("lesson-objective"),"goal":lesson.description,"evidence":.object(["criteria":.string("Completes the authored lesson objective in the target language")])])] : items
    }
    public static func applying(_ change: PracticeChange, to original: TutorLessonProgress) -> TutorLessonProgress {
        guard change.source == .tutorTurn else { return original }
        var next = original; next.earnedXP += max(0,change.amount)
        if let item = change.tutorAgendaItemID, !item.isEmpty { next.items.insert(item) }
        return next
    }
}
public extension LearnerState {
    func tutorKey(_ lessonID: String) -> String { "\(target):tutor:\(lessonID)" }
    func tutorProgress(_ lessonID: String) -> TutorLessonProgress { tutorLessons?[tutorKey(lessonID)] ?? TutorLessonProgress() }
    func nextTutorItem(_ lesson: Lesson) -> JSONValue? { TutorCourse.agenda(lesson).first { !tutorProgress(lesson.id).items.contains($0["id"].string) } }
    mutating func tutorTurn(lesson: Lesson, item: JSONValue, verdict: TutorTurnVerdict, amount: Int = Int.random(in:3...7), now: Date = Date()) -> Int {
        guard !completed.contains(tutorKey(lesson.id)), verdict.confidence.isFinite, verdict.confidence >= 0.55 else { return 0 }
        if verdict.successful {
            let earned = max(3,min(7,amount))
            addXP(earned,now:now,calendar:.current)
            var change = PracticeChange(date:now,dayKey:dailyKey,target:target,level:tutorLevel,amount:earned,source:.tutorTurn,contentID:lesson.id)
            if verdict.objectiveAdvanced && TutorCourse.agenda(lesson).contains(where:{ $0["id"] == item["id"] }) { change.tutorAgendaItemID = item["id"].string }
            let key = tutorKey(lesson.id), progress = TutorCourse.applying(change,to:tutorProgress(lesson.id))
            if tutorLessons == nil { tutorLessons = [:] }; tutorLessons?[key] = progress
            enqueue(change); assess(correct:true,independent:verdict.support == "independent",now:now,questionLevel:tutorLevel)
            return earned
        }
        if verdict.mistake { assess(correct:false,independent:false,now:now,questionLevel:tutorLevel) }
        return 0
    }
    func canCompleteTutor(_ lesson: Lesson) -> Bool {
        let progress = tutorProgress(lesson.id)
        return progress.earnedXP >= TutorCourse.requiredXP(lesson.id) && TutorCourse.agenda(lesson).allSatisfy { progress.items.contains($0["id"].string) }
    }
    mutating func completeTutor(_ lesson: Lesson, now: Date = Date()) -> Bool {
        guard canCompleteTutor(lesson), completed.insert(tutorKey(lesson.id)).inserted else { return false }
        award(TutorCourse.requiredXP(lesson.id),source:.speak,contentID:lesson.id,now:now)
        return true
    }
}

/// A completed learner turn remains identifiable after transcript trimming or reconnecting.
public struct VoiceTurnCapture: Sendable {
    public private(set) var sequence = 0
    public private(set) var pending = ""
    public init() {}
    public mutating func append(_ chunk: String) { pending = String((pending + chunk).suffix(12000)) }
    public mutating func finish() -> String? {
        let text = pending.trimmingCharacters(in:.whitespacesAndNewlines); pending = ""
        guard !text.isEmpty else { return nil }
        sequence += 1; return text
    }
    public mutating func reset() { pending = "" }
}
