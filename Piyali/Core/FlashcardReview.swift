import Foundation

public enum ReviewRating: String, Codable, CaseIterable, Sendable { case again, hard, good, easy }
public enum SchedulerState: String, Codable, Sendable { case new, learning, review, relearning }
public struct FlashcardReview: Codable, Equatable, Sendable {
    public var completed = false
    public var completedAt: Date?
    public var updatedAt: Date?
    public var lastReviewedAt: Date?
    public var lastReviewOutcome: ReviewRating?
    public var nextReviewAt: Date?
    public var intervalDays = 0.0
    public var intervalHours = 0.0
    public var easeFactor = 2.5
    public var schedulerState: SchedulerState = .new
    public var learningStepIndex = 0
    public var postLapseIntervalDays = 1.0
    public var lapseCount = 0
    public var reviewCount = 0
    public var successfulReviews = 0
    public var consecutiveCorrect = 0
    public init() {}
    public var masteryStage: Int {
        if schedulerState == .new { return 0 }
        if schedulerState == .learning || schedulerState == .relearning || intervalDays < 1 { return 1 }
        if intervalDays < 4 { return 2 }; if intervalDays < 10 { return 3 }; if intervalDays < 30 { return 4 }; if intervalDays < 90 { return 5 }; return 6
    }
    public func isDue(at now: Date = Date()) -> Bool { schedulerState != .new && (nextReviewAt ?? .distantPast) <= now }
    public func applying(_ rating: ReviewRating, now: Date = Date()) -> FlashcardReview {
        var next = self
        next.reviewCount += 1; next.updatedAt = now; next.lastReviewedAt = now; next.lastReviewOutcome = rating
        next.easeFactor = min(3.5,max(1.3,easeFactor == 0 ? 2.5 : easeFactor))
        next.successfulReviews = max(0,successfulReviews == 0 && schedulerState != .new ? 1 : successfulReviews)
        if schedulerState == .review || schedulerState == .relearning { next.completed = true }
        let initialState = schedulerState
        var delay: TimeInterval
        if initialState == .review {
            let interval = max(1, intervalDays)
            switch rating {
            case .again:
                next.schedulerState = .relearning; next.completed = true; next.lapseCount += 1
                next.consecutiveCorrect = 0; next.easeFactor -= 0.2
                next.postLapseIntervalDays = 1; next.intervalDays = 1; next.learningStepIndex = 0; delay = 600
            case .hard:
                next.intervalDays = max(interval + 1,(interval * 1.2).rounded()); next.easeFactor -= 0.15; delay = next.intervalDays * 86400
            case .good:
                next.intervalDays = max(interval + 1,(interval * next.easeFactor).rounded()); delay = next.intervalDays * 86400
            case .easy:
                let good = max(interval + 1,(interval * next.easeFactor).rounded())
                next.intervalDays = max(good + 1,(good * 1.3).rounded()); next.easeFactor += 0.15; delay = next.intervalDays * 86400
            }
            if rating != .again { next.successfulReviews += 1; next.consecutiveCorrect += 1 }
        } else {
            let steps = initialState == .relearning ? [10] : [1,10]
            let index = initialState == .new ? -1 : min(steps.count - 1,max(0,learningStepIndex))
            let graduates = rating == .easy || (rating == .good && index + 1 >= steps.count)
            if graduates {
                next.schedulerState = .review; next.completed = true; next.completedAt = completedAt ?? now
                next.intervalDays = initialState == .relearning ? (rating == .easy ? max(2,(postLapseIntervalDays * 1.3).rounded()) : max(1,postLapseIntervalDays)) : 1
                if initialState == .new { next.learningStepIndex = 0 }
                if rating == .easy { next.easeFactor += 0.15 }
                next.successfulReviews += 1; next.consecutiveCorrect += 1; delay = next.intervalDays * 86400
            } else {
                next.schedulerState = initialState == .relearning ? .relearning : .learning
                next.completed = initialState == .relearning; if initialState == .new { next.completedAt = nil }
                let minutes: Int
                if rating == .again { next.learningStepIndex = 0; minutes = steps[0]; next.consecutiveCorrect = 0 }
                else if rating == .hard {
                    next.learningStepIndex = max(0,index)
                    minutes = index <= 0 && steps.count > 1 ? Int((Double(steps[0] + steps[1])/2).rounded()) : steps[max(0,index)]
                    next.easeFactor -= 0.15; next.successfulReviews += 1; next.consecutiveCorrect += 1
                } else { next.learningStepIndex = index + 1; minutes = steps[next.learningStepIndex]; next.successfulReviews += 1; next.consecutiveCorrect += 1 }
                next.intervalDays = Double(minutes)/1440; delay = Double(minutes)*60
            }
        }
        next.easeFactor = (min(3.5,max(1.3,next.easeFactor))*100).rounded()/100
        next.nextReviewAt = now.addingTimeInterval(delay)
        next.intervalHours = (next.intervalDays*2400).rounded()/100
        next.intervalDays = (next.intervalDays*100).rounded()/100
        return next
    }
}
