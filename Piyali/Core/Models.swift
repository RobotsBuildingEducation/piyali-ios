import Foundation

public enum JSONValue: Codable, Equatable, Sendable {
    case string(String), number(Double), bool(Bool), object([String: JSONValue]), array([JSONValue]), null
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let v = try? c.decode(Bool.self) { self = .bool(v) }
        else if let v = try? c.decode(Double.self) { self = .number(v) }
        else if let v = try? c.decode(String.self) { self = .string(v) }
        else if let v = try? c.decode([String: JSONValue].self) { self = .object(v) }
        else { self = .array(try c.decode([JSONValue].self)) }
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let v): try c.encode(v)
        case .number(let v): try c.encode(v)
        case .bool(let v): try c.encode(v)
        case .object(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        case .null: try c.encodeNil()
        }
    }
    public subscript(key: String) -> JSONValue { if case .object(let v) = self { return v[key] ?? .null }; return .null }
    public var string: String { if case .string(let v) = self { return v }; return "" }
    public var array: [JSONValue] { if case .array(let v) = self { return v }; return [] }
    public func localized(_ language: String) -> String {
        if case .string(let v) = self { return v }
        return self[language].string.isEmpty ? self["en"].string : self[language].string
    }
    public var json: String { String(data: (try? JSONEncoder().encode(self)) ?? Data(), encoding: .utf8) ?? "{}" }
}

public struct LearningUnit: Codable, Identifiable, Sendable {
    public let id: String
    public let title: JSONValue
    public let description: JSONValue
    public let lessons: [Lesson]
}
public struct Lesson: Codable, Identifiable, Sendable {
    public let id: String
    public let title: JSONValue
    public let description: JSONValue
    public let xpReward: Int
    public let modes: [String]
    public let agenda: JSONValue
    public let content: JSONValue
}
public struct Flashcard: Codable, Identifiable, Sendable {
    public let id: String
    public let concept: [String: String]
    public let cefrLevel: String
    public let category: String
    public let type: String
    public func text(_ language: String) -> String { concept[language] ?? concept["en"] ?? id }
}
public struct PhonicsCard: Codable, Identifiable, Sendable {
    public let id: String
    public let letter: String
    public let tts: String
    public let practiceWord: String
    public let practiceWordMeaning: [String: String]
    public let sound: String
    public let tip: String
}
public enum PracticeMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case vocabulary = "Vocabulary", grammar = "Grammar", reading = "Reading", listening = "Listening", speaking = "Speaking", stories = "Stories", conversation = "Conversation", game = "Adventure"
    public var id: String { rawValue }
    public var instruction: String {
        switch self {
        case .vocabulary: "Teach and test a word or phrase through meaningful translation."
        case .grammar: "Test the lesson's grammar with a contextual question."
        case .reading: "Write original single-author prose, then ask a comprehension question grounded in it. Preserve the required document format."
        case .listening: "Write a short passage for listening and one comprehension question."
        case .speaking: "Give a practical speaking task and a short model response to pronounce."
        case .stories: "Write an original encounter between characters with intentions, then ask a question about it."
        case .conversation: "Role-play a real situation and ask the learner to respond in the target language."
        case .game: "Create a text adventure with a concrete situation and a choice requiring the lesson language."
        }
    }
}
public struct Exercise: Codable, Sendable {
    public let passage: String
    public let question: String
    public let choices: [String]
    public let answer: String
    public let explanation: String
}
public struct Grade: Codable, Sendable {
    public let correct: Bool
    public let feedback: String
    public let correctedAnswer: String
}
public struct HistoryEntry: Codable, Identifiable, Sendable {
    public var id = UUID()
    public let date: Date
    public let target: String
    public let mode: String
    public let question: String
    public let answer: String
    public let feedback: String
    public let correct: Bool
    public var repairInMemory: Bool?
}
public struct Note: Codable, Identifiable, Sendable {
    public var id = UUID()
    public var title: String
    public var body: String
}
public struct LearnerState: Codable, Sendable {
    public var name = ""
    public var target = "es"
    public var support = "en"
    public var level = "Pre-A1"
    public var goal = "Hold everyday conversations"
    public var dailyGoal = 50
    public var xpByLanguage: [String: Int] = [:]
    public var dailyXP = 0
    public var dailyKey = ""
    public var streak = 0
    public var completed: Set<String> = []
    public var practicedModes: Set<String> = []
    public var flashcardMastery: Set<String> = []
    public var history: [HistoryEntry] = []
    public var notes: [Note] = []
    public var companionName = "Piyali"
    public var companionType = "ghost"
    public var preferencesModifiedAt: Date?
    public var pendingChanges: [PracticeChange]?
    public var cardReviews: [String: FlashcardReview]?
    public var companionMemory: [String:[MemoryNote]]?
    public var pendingMemoryChanges: [MemoryChange]?
    public var acknowledgedEventIDs: Set<UUID>?
    public var ratingByLanguage: [String: Double]?
    public var goalArtifacts: [String: JSONValue]?
    public var goalIntelligence: [String: JSONValue]?
    public var pendingGoalChanges: [GoalChange]?
    public var focusPlans: [String: FocusedPlan]?
    public var masteredPhonics: Set<String>?
    public var immersionDays: Set<String>?
    public var journeyDays: Set<String>?
    public var journeyRecordings: [String: String]?
    public var placements: [String: Placement]?
    public var pendingPlacements: [String: Placement]?
    public var gradedByLanguage: [String: Int]?
    public var lessonLevels: [String: String]?
    public var flashcardLevels: [String: String]?
    public var courseCompletion: [String: [String: [String: Int]]]?
    public var onboardingComplete = false
    public init() {}
    public var xp: Int { xpByLanguage[target, default: 0] }
    public var rating: Double { ratingByLanguage?[target] ?? 800 }
    public var score: Int { PerformanceScore.score(rating: rating) }
    public var effectiveCompanionType: String { CompanionTypes.effective(companionType, level: companionLevel) }
    public mutating func assess(correct: Bool, independent: Bool, now: Date = Date(), questionLevel: String? = nil) {
        if ratingByLanguage == nil { ratingByLanguage = [:] }
        if gradedByLanguage == nil { gradedByLanguage = [:] }; gradedByLanguage?[target, default: 0] += 1
        let updated = PerformanceScore.update(rating: rating, questionLevel: questionLevel ?? level, correct: correct, independent: independent)
        ratingByLanguage?[target] = updated
        enqueue(PracticeChange(date:now,dayKey:CalendarDay.key(now),target:target,level:questionLevel ?? level,amount:0,source:.assessment,correct:correct,independent:independent))
    }
    public var totalXP: Int { xpByLanguage.values.reduce(0, +) }
    public var companionLevel: Int { max(1, xp / 100 + 1) }
    public func completionKey(_ lesson: String) -> String { "\(target):\(lesson)" }
    public func modeKey(_ lesson: String, _ mode: String) -> String { "\(target):\(lesson):\(mode)" }
    public mutating func rollDay(now: Date = Date(), calendar: Calendar = .current) {
        dailyKey = CalendarDay.normalize(dailyKey)
        let key = CalendarDay.key(now,calendar:calendar)
        if dailyKey != key {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
            if dailyKey != CalendarDay.key(yesterday,calendar:calendar) || dailyXP < dailyGoal { streak = 0 }
            dailyKey = key; dailyXP = 0
        }
    }
    public mutating func award(_ amount: Int, source: PracticeSource = .practice, contentID: String? = nil, now: Date = Date(), calendar: Calendar = .current) {
        let earned = max(0, min(amount, 100))
        guard earned > 0 else { return }
        addXP(earned,now:now,calendar:calendar)
        enqueue(PracticeChange(date:now,dayKey:dailyKey,target:target,level:level,amount:earned,source:source,contentID:contentID))
    }
    mutating func addXP(_ amount: Int, now: Date, calendar: Calendar) {
        rollDay(now:now,calendar:calendar)
        let reachedBefore = dailyXP >= dailyGoal
        dailyXP += max(0,amount); xpByLanguage[target,default:0] += max(0,amount)
        if !reachedBefore && dailyXP >= dailyGoal { streak += 1 }
    }
    public mutating func complete(_ lesson: Lesson) -> Bool {
        let key = completionKey(lesson.id)
        guard !completed.contains(key) else { return false }
        let source: PracticeSource = lesson.id.hasPrefix("goal-") ? .goal : lesson.id.hasPrefix("repair-") ? .repair : .lesson
        completed.insert(key); award(lesson.xpReward,source:source,contentID:lesson.id)
        if lesson.id.hasPrefix("repair-memory-") { reinforceMemory(id:String(lesson.id.dropFirst("repair-memory-".count))) }
        return true
    }
}
public enum LearningLanguages {
    public static let levels = ["Pre-A1", "A1", "A2", "B1", "B2", "C1", "C2"]
    public static let practice = ["es", "en", "pt", "fr", "it", "nl", "de", "ja", "ru", "el", "pl", "ga"]
    public static let support = ["en", "es", "pt", "fr", "it", "de", "ja", "hi", "ar", "zh"]
    public static let names = ["es":"Spanish", "en":"English", "pt":"Portuguese", "fr":"French", "it":"Italian", "nl":"Dutch", "de":"German", "ja":"Japanese", "ru":"Russian", "el":"Greek", "pl":"Polish", "ga":"Irish", "nah":"Eastern Huasteca Nahuatl", "yua":"Yucatec Maya", "ar":"Egyptian Arabic", "hi":"Hindi", "zh":"Mandarin Chinese"]
    public static let locales = ["es":"es-MX", "en":"en-US", "pt":"pt-BR", "fr":"fr-FR", "it":"it-IT", "nl":"nl-NL", "de":"de-DE", "ja":"ja-JP", "ru":"ru-RU", "el":"el-GR", "pl":"pl-PL", "ga":"ga-IE", "ar":"ar-EG", "hi":"hi-IN", "zh":"zh-CN"]
}
