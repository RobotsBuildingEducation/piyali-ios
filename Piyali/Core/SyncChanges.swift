import Foundation

public enum PracticeSource: String, Codable, Sendable {
    case practice, assessment, lesson, review, phonics, goal, repair, immersion
    public var activityField: String? {
        switch self { case .lesson:"lessonDailyActivity"; case .review:"flashcardDailyActivity"; case .phonics:"phonicsDailyActivity"; case .goal:"goalDailyActivity"; case .repair:"repairDailyActivity"; default:nil }
    }
}
public struct PracticeChange: Codable, Identifiable, Sendable {
    public var id: UUID
    public var date: Date
    public var dayKey: String
    public var target: String
    public var level: String
    public var amount: Int
    public var source: PracticeSource
    public var contentID: String?
    public var reviewRating: ReviewRating?
    public var correct: Bool?
    public var independent: Bool?
    public init(date: Date = Date(), dayKey: String, target: String, level: String, amount: Int, source: PracticeSource, contentID: String? = nil, reviewRating: ReviewRating? = nil, correct: Bool? = nil, independent: Bool? = nil) {
        self.id = UUID(); self.date = date; self.dayKey = dayKey; self.target = target; self.level = level
        self.amount = amount; self.source = source; self.contentID = contentID; self.reviewRating = reviewRating; self.correct = correct; self.independent = independent
    }
}
public enum CalendarDay {
    public static func key(_ date: Date, calendar: Calendar = .current) -> String {
        let p = calendar.dateComponents([.year,.month,.day],from:date)
        return String(format:"%04d-%02d-%02d",p.year ?? 0,p.month ?? 0,p.day ?? 0)
    }
    public static func shift(_ day: String, by amount: Int, calendar: Calendar = .current) -> String {
        let parts = day.split(separator:"-").compactMap { Int($0) }
        guard parts.count == 3, let date = calendar.date(from:DateComponents(year:parts[0],month:parts[1],day:parts[2],hour:12)), let shifted = calendar.date(byAdding:.day,value:amount,to:date) else { return "" }
        return key(shifted,calendar:calendar)
    }
    public static func normalize(_ day: String) -> String {
        let p = day.split(separator:"-").compactMap { Int($0) }
        guard p.count == 3 else { return "" }; return String(format:"%04d-%02d-%02d",p[0],p[1],p[2])
    }
}
public extension LearnerState {
    mutating func enqueue(_ change: PracticeChange) { if pendingChanges == nil { pendingChanges = [] }; pendingChanges?.append(change) }
    mutating func review(cardID: String, rating: ReviewRating, now: Date = Date(), calendar: Calendar = .current) {
        rollDay(now:now,calendar:calendar)
        let key = completionKey(cardID)
        var review = cardReviews?[key] ?? FlashcardReview()
        if cardReviews?[key] == nil, flashcardMastery.contains(key) {
            // Preserve completion when importing a v1 native account with no scheduler record.
            review.completed = true; review.schedulerState = .review; review.intervalDays = 1
        }
        let next = review.applying(rating,now:now)
        if cardReviews == nil { cardReviews = [:] }; cardReviews?[key] = next
        if next.completed { flashcardMastery.insert(key) }
        let amount = rating == .again ? 0 : rating == .hard ? 4 : rating == .easy ? 7 : 5
        addXP(amount,now:now,calendar:calendar)
        enqueue(PracticeChange(date:now,dayKey:dailyKey,target:target,level:level,amount:amount,source:.review,contentID:cardID,reviewRating:rating))
    }
    // Merge a completed sync without losing practice performed while the network request was in flight.
    static func rebased(current: LearnerState, sent: LearnerState, acknowledged: LearnerState) -> LearnerState {
        var merged = current
        let sentIDs = Set((sent.pendingChanges ?? []).map(\.id))
        let newer = (current.pendingChanges ?? []).filter { !sentIDs.contains($0.id) && !(acknowledged.acknowledgedEventIDs ?? []).contains($0.id) }
        merged.pendingChanges = newer
        let sentMemoryIDs = Set((sent.pendingMemoryChanges ?? []).map(\.id))
        let newMemory = (current.pendingMemoryChanges ?? []).filter { !sentMemoryIDs.contains($0.id) && !(acknowledged.acknowledgedEventIDs ?? []).contains($0.id) }
        merged.pendingMemoryChanges = newMemory
        for (target,notes) in acknowledged.companionMemory ?? [:] {
            if merged.companionMemory == nil { merged.companionMemory = [:] }
            merged.companionMemory?[target] = notes
        }
        for change in newMemory.sorted(by:{ $0.date < $1.date }) {
            if merged.companionMemory == nil { merged.companionMemory = [:] }
            let notes = MemoryContract.applying(change,to:merged.companionMemory?[change.target] ?? [],today:CalendarDay.key(Date()))
            merged.companionMemory?[change.target] = notes
        }
        if current.preferencesModifiedAt == sent.preferencesModifiedAt {
            merged.preferencesModifiedAt = nil
            if current.name == sent.name { merged.name = acknowledged.name }
            if current.target == sent.target { merged.target = acknowledged.target }
            if current.support == sent.support { merged.support = acknowledged.support }
            if current.level == sent.level { merged.level = acknowledged.level }
            if current.dailyGoal == sent.dailyGoal { merged.dailyGoal = acknowledged.dailyGoal }
            if current.onboardingComplete == sent.onboardingComplete { merged.onboardingComplete = acknowledged.onboardingComplete }
            if current.companionName == sent.companionName { merged.companionName = acknowledged.companionName }
            if current.companionType == sent.companionType { merged.companionType = acknowledged.companionType }
        }
        merged.completed.formUnion(acknowledged.completed)
        merged.flashcardMastery.formUnion(acknowledged.flashcardMastery)
        var xp = acknowledged.xpByLanguage
        for change in newer { xp[change.target,default:0] += change.amount }
        merged.xpByLanguage = xp
        if acknowledged.dailyKey >= current.dailyKey {
            merged.dailyKey = acknowledged.dailyKey
            merged.dailyXP = acknowledged.dailyXP + newer.filter { $0.dayKey == acknowledged.dailyKey }.reduce(0) { $0 + $1.amount }
            merged.streak = max(acknowledged.streak,current.dailyKey == acknowledged.dailyKey ? current.streak : 0)
        }
        for (key, review) in acknowledged.cardReviews ?? [:] {
            if (merged.cardReviews?[key]?.updatedAt ?? .distantPast) <= (review.updatedAt ?? .distantPast) {
                if merged.cardReviews == nil { merged.cardReviews = [:] }; merged.cardReviews?[key] = review
            }
        }
        // A newer local assessment already includes all previous local evidence.
        if !newer.contains(where: { $0.source == .assessment }) { merged.ratingByLanguage = acknowledged.ratingByLanguage }
        return merged
    }
}
