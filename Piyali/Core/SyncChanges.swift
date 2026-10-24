import Foundation

public enum PracticeSource: String, Codable, Sendable {
    case practice, repairPractice, assessment, lessonStart, lesson, review, phonics, goal, goalMode, repair, immersion, speak, tutorTurn, conversation, readingTurn, readingSpeech, storyTurn, storyCompletion, questStart, plateBonus
    public var activityField: String? {
        switch self { case .lesson:"lessonDailyActivity"; case .review:"flashcardDailyActivity"; case .phonics:"phonicsDailyActivity"; case .goal:"goalDailyActivity"; case .repair:"repairDailyActivity"; case .speak:"speakDailyActivity"; case .conversation:"conversationDailyActivity"; default:nil }
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
    public var skillTreeLessonID:String?
    public var skillTreeLessonLevel:String?
    public var tutorAgendaItemID: String?
    public var questYesterdayComplete:Bool?
    public var questCarry: [String]?
    public var questIntro: Bool?
    public var questKinds: [String]?
    public var reviewRating: ReviewRating?
    public var reviewPatch: FlashcardReview?
    public var activityDayKey:String {reviewPatch?.lastReviewedAt.map{CalendarDay.key($0)} ?? dayKey}
    public var correct: Bool?
    public var independent: Bool?
    public var conversationGoalID: String?
    public var conversationBonus: Int?
    public var gradedWorth:JSONValue?
    public var gradedConcept:String?
    public var gradedSupport:String?
    public var gradedMode:String?
    public var conversationWorth: JSONValue?
    public var conversationGoalText: JSONValue?
    public var gameResult: JSONValue?
    public var readingProof: JSONValue?
    public var storyProof: JSONValue?
    public var earnedAmount: Int { amount + (source == .conversation && correct == true ? max(0,min(4,conversationBonus ?? 0)) : 0) }
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
    mutating func enqueue(_ change: PracticeChange) { applyGoalLessonWork(change);applyLessonWork(change);questProgress = DailyPlate.recorded(change,progress:plateProgress); if pendingChanges == nil { pendingChanges = [] }; pendingChanges?.append(change) }
    mutating func review(cardID: String, rating: ReviewRating, xp:Int? = nil, patch:FlashcardReview? = nil, now: Date = Date(), calendar: Calendar = .current) {
        rollDay(now:now,calendar:calendar)
        let key = completionKey(cardID)
        var review = cardReviews?[key] ?? FlashcardReview()
        if cardReviews?[key] == nil, flashcardMastery.contains(key) {
            // Preserve completion when importing a v1 native account with no scheduler record.
            review.completed = true; review.schedulerState = .review; review.intervalDays = 1
        }
        let next = patch ?? review.applying(rating,now:now)
        if cardReviews == nil { cardReviews = [:] }; cardReviews?[key] = next
        if next.completed { flashcardMastery.insert(key) }
        let amount = max(0,min(7,xp ?? (rating == .again ? 0 : rating == .hard ? 4 : rating == .easy ? 7 : 5)))
        addXP(amount,now:now,calendar:calendar)
        var change=PracticeChange(date:now,dayKey:dailyKey,target:target,level:flashcardLevel,amount:amount,source:.review,contentID:cardID,reviewRating:rating)
        change.reviewPatch=next;enqueue(change)
    }
    // Merge a completed sync without losing practice performed while the network request was in flight.
    static func rebased(current: LearnerState, sent: LearnerState, acknowledged: LearnerState) -> LearnerState {
        var merged = current
        let sentRepair=Set((sent.pendingRepairEvidence ?? []).map(\.id))
        merged.pendingRepairEvidence=(current.pendingRepairEvidence ?? []).filter{!sentRepair.contains($0.id)}
        let pendingQuest=(current.pendingCompanionQuestDays ?? [:]).filter {sent.pendingCompanionQuestDays?[$0.key] != $0.value}
        merged.pendingCompanionQuestDays=pendingQuest
        for (key,value) in acknowledged.companionQuestDays ?? [:] {if merged.companionQuestDays == nil {merged.companionQuestDays=[:]};merged.companionQuestDays?[key]=value}
        for (key,value) in pendingQuest {if merged.companionQuestDays == nil {merged.companionQuestDays=[:]};let existing=merged.companionQuestDays?[key] ?? .object([:]);merged.companionQuestDays?[key]=CompanionQuestDay.merging(value,into:existing)}
        let pendingHeadlines=(current.pendingPlateHeadlines ?? [:]).filter {sent.pendingPlateHeadlines?[$0.key] != $0.value}
        merged.plateHeadlines=acknowledged.plateHeadlines
        merged.pendingPlateHeadlines=pendingHeadlines
        for (target,value) in pendingHeadlines {if merged.plateHeadlines == nil {merged.plateHeadlines=[:]};merged.plateHeadlines?[target]=value}
        let sentIDs = Set((sent.pendingChanges ?? []).map(\.id))
        let newer = (current.pendingChanges ?? []).filter { !sentIDs.contains($0.id) && !(acknowledged.acknowledgedEventIDs ?? []).contains($0.id) }
        merged.pendingChanges = newer
        merged.questProgress = acknowledged.questProgress
        for change in newer { merged.questProgress = DailyPlate.recorded(change,progress:merged.plateProgress) }
        for (target,plan) in acknowledged.questPlans ?? [:] {
            if !(newer.contains { $0.source == .questStart && $0.target == target }) {
                if merged.questPlans == nil { merged.questPlans = [:] }; merged.questPlans?[target] = plan
            }
        }
        merged.journeyQuestCounts = acknowledged.journeyQuestCounts
        merged.tutorLessons = acknowledged.tutorLessons
        merged.lessonWork=acknowledged.lessonWork
        for change in newer { merged.applyLessonWork(change) }
        for change in newer where change.source == .tutorTurn {
            let key = "\(change.target):tutor:\(change.contentID ?? "")"
            if merged.tutorLessons == nil { merged.tutorLessons = [:] }
            let progress = TutorCourse.applying(change,to:merged.tutorLessons?[key] ?? TutorLessonProgress())
            merged.tutorLessons?[key] = progress
        }
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
        let sentGoalIDs = Set((sent.pendingGoalChanges ?? []).map(\.id))
        let newGoals = (current.pendingGoalChanges ?? []).filter { !sentGoalIDs.contains($0.id) && !(acknowledged.acknowledgedEventIDs ?? []).contains($0.id) }
        merged.pendingGoalChanges = newGoals; merged.goalIntelligence = acknowledged.goalIntelligence; merged.goalArtifacts = acknowledged.goalArtifacts
        var newGoalRewards: [(GoalChange,Int)] = []
        for change in newGoals.sorted(by:{ $0.date < $1.date }) {
            let result = GoalPractice.applying(change,to:merged.goalIntelligence?[change.target] ?? .object([:]))
            if merged.goalIntelligence == nil { merged.goalIntelligence = [:] }; merged.goalIntelligence?[change.target] = result.bucket
            var reward = result.reward
            if [.artifact,.outcome].contains(change.action) {
                let key = GoalPractice.artifactKey(target:change.target,day:change.payload["dayKey"].string,mode:change.payload["mode"].string,goalID:change.payload["goalId"].string)
                let artifact = GoalPractice.applyingArtifact(change,to:merged.goalArtifacts?[key] ?? .object([:]))
                if merged.goalArtifacts == nil { merged.goalArtifacts = [:] }; merged.goalArtifacts?[key] = artifact.artifact
                reward += artifact.reward
            }
            newGoalRewards.append((change,reward))
        }
        for change in newer.sorted(by:{$0.date < $1.date}) {merged.applyGoalLessonWork(change)}
        merged.legacyFirstRunPlacement = (current.pendingPlacements ?? [:]).isEmpty ? acknowledged.legacyFirstRunPlacement : nil
        merged.gettingStartedModalShown = current.gettingStartedModalShown == true || acknowledged.gettingStartedModalShown == true ? true : acknowledged.gettingStartedModalShown
        if current.goal == sent.goal && newGoals.isEmpty { merged.goal = acknowledged.goal }
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
        for (language, placement) in acknowledged.placements ?? [:] {
            if current.pendingPlacements?[language] == sent.pendingPlacements?[language] {
                if merged.placements == nil { merged.placements = [:] }; merged.placements?[language] = placement
                merged.pendingPlacements?.removeValue(forKey: language)
            }
        }
        merged.courseCompletion = acknowledged.courseCompletion
        let sentImmersionIDs=Set((sent.pendingImmersionChanges ?? []).map(\.id))
        let newImmersion=(current.pendingImmersionChanges ?? []).filter { !sentImmersionIDs.contains($0.id) && !(acknowledged.acknowledgedEventIDs ?? []).contains($0.id) }
        merged.pendingImmersionChanges=newImmersion;merged.immersionBatch=acknowledged.immersionBatch;merged.immersionHistory=acknowledged.immersionHistory;merged.immersionRewardReceipts=acknowledged.immersionRewardReceipts;merged.immersionPlacementAt=acknowledged.immersionPlacementAt
        let newImmersionRewards=newImmersion.sorted(by:{ $0.date < $1.date }).map { ($0,merged.applyImmersion($0,enqueue:false,award:false)) }
        if current.flashcardLevels == sent.flashcardLevels { merged.flashcardLevels = acknowledged.flashcardLevels }
        if current.tutorLevels == sent.tutorLevels { merged.tutorLevels = acknowledged.tutorLevels }
        if current.lessonLevels == sent.lessonLevels { merged.lessonLevels = acknowledged.lessonLevels }
        merged.completed.formUnion(acknowledged.completed)
        merged.flashcardMastery.formUnion(acknowledged.flashcardMastery)
        var xp = acknowledged.xpByLanguage
        merged.completedConversationGoals=(current.completedConversationGoals ?? []).union(acknowledged.completedConversationGoals ?? [])
        func reward(_ change: PracticeChange) -> Int { change.amount + (change.conversationGoalID.map { (acknowledged.completedConversationGoals ?? []).contains($0) } == true ? 0 : change.earnedAmount-change.amount) }
        for change in newer { xp[change.target,default:0] += reward(change) }
        for (change,reward) in newGoalRewards { xp[change.target,default:0] += reward }
        for (change,reward) in newImmersionRewards { xp[change.target,default:0] += reward }
        merged.xpByLanguage = xp
        if acknowledged.dailyKey >= current.dailyKey {
            merged.dailyKey = acknowledged.dailyKey
            merged.dailyXP = acknowledged.dailyXP + newer.filter { $0.dayKey == acknowledged.dailyKey }.reduce(0) { $0 + reward($1) }
            merged.dailyXP += newGoalRewards.filter { CalendarDay.key($0.0.date) == acknowledged.dailyKey }.reduce(0) { $0 + $1.1 }
            merged.dailyXP += newImmersionRewards.filter { CalendarDay.key($0.0.date) == acknowledged.dailyKey }.reduce(0) { $0 + $1.1 }
            merged.streak = max(acknowledged.streak,current.dailyKey == acknowledged.dailyKey ? current.streak : 0)
        }
        for (key, review) in acknowledged.cardReviews ?? [:] {
            if (merged.cardReviews?[key]?.updatedAt ?? .distantPast) <= (review.updatedAt ?? .distantPast) {
                if merged.cardReviews == nil { merged.cardReviews = [:] }; merged.cardReviews?[key] = review
            }
        }
        // A chosen source patch is frozen when the card opens. Replay unsent choices
        // after the acknowledged snapshot even if that open timestamp is older.
        for change in newer.sorted(by:{$0.date < $1.date}) where change.source == .review {
            if let patch=change.reviewPatch,let id=change.contentID {
                if merged.cardReviews == nil {merged.cardReviews=[:]};merged.cardReviews?["\(change.target):\(id)"]=patch
            }
        }
        merged.achievementRecords = NostrAchievementCollection.merging([.object(current.achievementRecords ?? [:]),.object(acknowledged.achievementRecords ?? [:]),current.nostrAchievementRecords ?? .object([:])]).object; merged.achievementEvidence = acknowledged.achievementEvidence; merged.achievementLedger = acknowledged.achievementLedger
        merged.companionProgress = acknowledged.companionProgress
        for change in newer.sorted(by:{ $0.date < $1.date }) where reward(change) > 0 { merged.rewardCompanion(reward(change),now:change.date) }
        for (change,reward) in newGoalRewards where reward > 0 { merged.rewardCompanion(reward,now:change.date) }
        for (change,reward) in newImmersionRewards where reward > 0 { merged.rewardCompanion(reward,now:change.date) }
        merged.reconcileCompanion()
        // A newer local assessment already includes all previous local evidence.
        if !newer.contains(where: { $0.source == .assessment || $0.source == .conversation && $0.correct != nil }) && (merged.pendingPlacements ?? [:]).isEmpty { merged.ratingByLanguage = acknowledged.ratingByLanguage; merged.gradedByLanguage = acknowledged.gradedByLanguage }
        return merged
    }
}
