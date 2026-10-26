import Foundation

/// Existing main-product Firestore fields. This adapter does not touch subscription grants or migrate web-owned schemas.
public enum WebProgressContract {
    public static func iso(_ date: Date) -> String { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime,.withFractionalSeconds]; return f.string(from:date) }
    public static func date(_ value: Any?) -> Date? {
        if let value = value as? Date { return value }
        guard let text = value as? String else { return nil }
        let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withInternetDateTime,.withFractionalSeconds]
        return formatter.date(from:text) ?? ISO8601DateFormatter().date(from:text)
    }
    public static func number(_ value: Any?, default fallback: Double = 0) -> Double {
        let parsed = (value as? NSNumber)?.doubleValue ?? fallback
        return parsed.isFinite ? parsed : fallback
    }
    public static func integer(_ value: Any?, default fallback: Int = 0) -> Int { Int(max(Double(Int.min),min(Double(Int.max).nextDown,number(value,default:Double(fallback))))) }
    public static func review(_ fields: [String:Any]) -> FlashcardReview {
        var value = FlashcardReview()
        value.completed = fields["completed"] as? Bool ?? false
        value.completedAt = date(fields["completedAt"]); value.updatedAt = date(fields["updatedAt"])
        value.lastReviewedAt = date(fields["lastReviewedAt"]) ?? value.completedAt; value.nextReviewAt = date(fields["nextReviewAt"])
        value.schedulerState = (fields["schedulerState"] as? String).flatMap(SchedulerState.init(rawValue:)) ?? (value.completed ? .review : value.nextReviewAt != nil ? .learning : .new)
        value.lastReviewOutcome = (fields["lastReviewOutcome"] as? String).flatMap(ReviewRating.init(rawValue:))
        value.intervalDays = number(fields["intervalDays"],default:number(fields["intervalHours"])/24)
        value.intervalHours = number(fields["intervalHours"],default:value.intervalDays*24)
        value.easeFactor = number(fields["easeFactor"],default:2.5); value.learningStepIndex = integer(fields["learningStepIndex"])
        value.postLapseIntervalDays = max(1,number(fields["postLapseIntervalDays"],default:value.intervalDays))
        value.reviewCount = integer(fields["reviewCount"]); value.lapseCount = integer(fields["lapseCount"])
        value.successfulReviews = integer(fields["successfulReviews"]); value.consecutiveCorrect = integer(fields["consecutiveCorrect"])
        return value
    }
    public static func reviewFields(_ value: FlashcardReview) -> [String:Any] {
        ["completed":value.completed,"completedAt":value.completedAt.map(iso) as Any? ?? NSNull(),"updatedAt":value.updatedAt.map(iso) as Any? ?? NSNull(),
         "lastReviewedAt":value.lastReviewedAt.map(iso) as Any? ?? NSNull(),"nextReviewAt":value.nextReviewAt.map(iso) as Any? ?? NSNull(),
         "lastReviewOutcome":value.lastReviewOutcome?.rawValue as Any? ?? NSNull(),"intervalDays":value.intervalDays,"intervalHours":value.intervalHours,
         "easeFactor":value.easeFactor,"schedulerState":value.schedulerState.rawValue,"learningStepIndex":value.learningStepIndex,"postLapseIntervalDays":value.postLapseIntervalDays,
         "masteryStage":value.masteryStage,"lapseCount":value.lapseCount,"reviewCount":value.reviewCount,"successfulReviews":value.successfulReviews,"consecutiveCorrect":value.consecutiveCorrect]
    }
    public static func imported(_ fields: [String:Any], native: LearnerState? = nil, now: Date = Date()) -> LearnerState {
        var state = native ?? LearnerState()
        state.plateHeadlines=(fields["dailyPlateHeadline"] as? [String:Any] ?? [:]).compactMapValues(PlateHeadline.decode)
        for (target,pending) in state.pendingPlateHeadlines ?? [:] {state.plateHeadlines?[target]=pending}
        state.acknowledgedEventIDs = Set((fields["iosRecentEventIDs"] as? [String] ?? []).compactMap(UUID.init(uuidString:)))
        state.completedConversationGoals=(state.completedConversationGoals ?? []).union(fields["iosCompletedConversationGoalIDs"] as? [String] ?? [])
        state.companionProgress = JSONValue.foundation(fields.filter { CompanionHealth.keys.contains($0.key) }.merging(CompanionHealth.reconcileFields(fields,now:now)) { _,new in new })
        state.gettingStartedModalShown = state.gettingStartedModalShown == true || fields["gettingStartedModalShown"] as? Bool == true ? true : state.gettingStartedModalShown
        // The original prompt falls back to the old account-wide placement
        // only while the language placement map is entirely absent.
        state.legacyFirstRunPlacement = fields["proficiencyPlacements"] == nil || fields["proficiencyPlacements"] is NSNull ? (fields["proficiencyPlacement"] as? String).flatMap{$0.isEmpty ? nil : $0} : nil
        let legacy=fields["subscriptionPasscodeVerified"]
        state.legacySubscriptionPasscodeVerified=(legacy as? String == "true") || (legacy as? String == "1") || (legacy as? NSNumber)?.doubleValue == 1
        let progress = fields["progress"] as? [String:Any] ?? [:]
        state.userSettings=LearnerSettings.snapshot(LearnerSettings.sourceUser(fields))
        state.pendingSettingsChanges=(state.pendingSettingsChanges ?? []).filter{!(state.acknowledgedEventIDs ?? []).contains($0.id)}
        for change in state.pendingSettingsChanges ?? [] {state.userSettings=LearnerSettings.applying(change,to:state.settingsSnapshot)}
        state.tutorUnlockedLevels=TutorProgression.merging(state.tutorUnlockedLevels,progress["tutorUnlockedLevels"] as? [String:String])
        let questKeys = Set(DailyPlate.fields.values).union(["dailyQuestFirstSeen","dailyQuestFirstDayKey","plateBonusDailyActivity","currentTutorLesson"])
        state.questProgress = JSONValue.foundation(progress.filter { questKeys.contains($0.key) })
        for change in state.pendingChanges ?? [] where !(state.acknowledgedEventIDs ?? []).contains(change.id) { state.questProgress = DailyPlate.recorded(change,progress:state.plateProgress) }
        let placementLevels = fields["proficiencyPlacements"] as? [String:String] ?? [:]
        let details = fields["iosPlacementDetails"] as? [String:[String:Any]] ?? [:]
        for (language, level) in placementLevels where LearningLanguages.levels.contains(level) {
            let savedDetail = details[language] ?? [:]
            let detail = savedDetail["level"] as? String == level ? savedDetail : [:]
            let updated = date(detail["updatedAt"]) ?? date(fields["proficiencyPlacementAt"]) ?? .distantPast
            if let pending = state.pendingPlacements?[language], iso(pending.updatedAt) > iso(updated) { continue }
            if state.placements == nil { state.placements = [:] }
            state.placements?[language] = Placement(level:level,score:integer(detail["score"],default:Int(PerformanceScore.defaults[level] ?? 0)),source:detail["source"] as? String ?? "web",selectedIDs:detail["selectedIDs"] as? [String] ?? [],updatedAt:updated)
            state.pendingPlacements?.removeValue(forKey:language)
        }
        if native == nil || native?.preferencesModifiedAt == nil {
            state.name = fields["displayName"] as? String ?? fields["name"] as? String ?? state.name
            state.target = progress["targetLang"] as? String ?? state.target
            state.support = progress["supportLang"] as? String ?? fields["language"] as? String ?? state.support
            let candidate = progress["cefrLevel"] as? String ?? state.level
            state.level = LearningLanguages.levels.contains(candidate) ? candidate : "Pre-A1"
            let candidates=[fields["dailyGoalXp"],progress["dailyGoalXp"],(fields["stats"] as? [String:Any])?["dailyGoalXp"]]
            let rawGoal=candidates.compactMap{$0 is NSNull ? nil:$0}.first
            let goal=(rawGoal as? NSNumber)?.doubleValue ?? (rawGoal as? String).flatMap{Double($0.trimmingCharacters(in:.whitespacesAndNewlines))} ?? 0
            state.dailyGoal = goal.isFinite && goal>0 ? goal>=Double(Int.max) ? Int.max:max(1,Int(goal)) : 100
            state.companionName = fields["dailyGoalPetName"] as? String ?? state.companionName
            state.companionType = fields["dailyGoalPetType"] as? String ?? state.companionType
            state.onboardingComplete = (fields["onboarding"] as? [String:Any])?["completed"] as? Bool ?? state.onboardingComplete
            state.tutorLevels = progress["activeTutorLevels"] as? [String:String] ?? state.tutorLevels
            state.lessonLevels = progress["activeLessonLevels"] as? [String:String] ?? state.lessonLevels
            state.flashcardLevels = progress["activeFlashcardLevels"] as? [String:String] ?? state.flashcardLevels
            if let active = state.lessonLevels?[state.target], LearningLanguages.levels.contains(active) { state.level = active }
        }
        if let languages=progress["languageLessons"] as? [String:[String:[String:Any]]] {
            for (target,lessons) in languages { for (id,fields) in lessons { state.importLessonWork(fields,id:id,target:target) } }
        } else if let lessons=progress["lessons"] as? [String:[String:Any]] {
            for (id,fields) in lessons { state.importLessonWork(fields,id:id,target:state.target) }
        }
        if let languageXP = progress["languageXp"] as? [String:Any] {
            state.xpByLanguage = languageXP.mapValues { max(0,integer($0)) }
        } else if progress["totalXp"] != nil { state.xpByLanguage[state.target] = max(0,integer(progress["totalXp"])) }
        // App.jsx uses the first valid account XP value for its 300-XP gate.
        // Preserve legacy root XP that differs from the per-language ledger.
        let candidates:[Any?]=[fields["xp"],progress["totalXp"],(progress["languageXp"] as? [String:Any])?[state.target]]
        let accountXP=candidates.compactMap { value -> Double? in
            guard let value else { return nil }
            if value is NSNull { return 0 }
            let text=String(describing:value).trimmingCharacters(in:.whitespacesAndNewlines)
            let number=text.isEmpty ? 0 : Double(text)
            guard let number,number.isFinite,number >= 0 else { return nil };return number
        }.first
        state.subscriptionXPAdjustment=accountXP.map { Int(min($0,Double(Int32.max)))-state.totalXP } ?? 0
        let today = CalendarDay.key(now)
        let recent = fields["dailyXpRecent"] as? [String:Any] ?? fields["dailyXpHistory"] as? [String:Any] ?? [:]
        state.dailyKey = today
        state.dailyXP = integer(recent[today],default:date(fields["dailyStartedAt"]).map { CalendarDay.key($0) == today } == true ? integer(fields["dailyXp"]) : 0)
        let lastGoal = fields["lastGoalDayKey"] as? String ?? ""
        state.streak = [today,CalendarDay.shift(today,by:-1)].contains(lastGoal) ? integer(fields["goalStreakCount"]) : 0
        for (language, bucket) in fields["learningIntelligence"] as? [String:[String:Any]] ?? [:] {
            if state.goalIntelligence == nil { state.goalIntelligence = [:] }
            state.goalIntelligence?[language] = JSONValue.foundation(bucket.filter { ["version","activeGoal","dailyGoal","goalProgress","performanceSummary","repairSummary","elo","selfAssessment"].contains($0.key) })
            let elo = bucket["elo"] as? [String:Any] ?? [:]
            if state.gradedByLanguage == nil { state.gradedByLanguage = [:] }
            state.gradedByLanguage?[language] = max(0,integer(elo["totalGraded"]))
            if integer(elo["scaleVersion"]) == PerformanceScore.version, elo["rating"] != nil {
                if state.ratingByLanguage == nil { state.ratingByLanguage = [:] }
                state.ratingByLanguage?[language] = max(800,min(2200,number(elo["rating"])))
            }
        }
        for change in state.pendingGoalChanges ?? [] where !(state.acknowledgedEventIDs ?? []).contains(change.id) {
            if state.goalIntelligence == nil { state.goalIntelligence = [:] }
            let result = GoalPractice.applying(change,to:state.goalIntelligence?[change.target] ?? .object([:]))
            state.goalIntelligence?[change.target] = result.bucket
        }
        for change in state.pendingChanges ?? [] where !(state.acknowledgedEventIDs ?? []).contains(change.id) {state.applyGoalLessonWork(change)}
        if !state.goalBucket["activeGoal"]["text"].string.isEmpty { state.goal = state.goalBucket["activeGoal"]["text"].string }
        state.immersionBatch=JSONValue.foundation(fields["realWorldTasks"] as? [String:Any] ?? [:])
        state.immersionHistory=JSONValue.foundation(fields["realWorldTaskHistoryByLanguage"] as? [String:Any] ?? [:]).object
        state.immersionRewardReceipts=JSONValue.foundation(fields["xpAwardReceipts"] as? [String:Any] ?? [:])
        state.immersionPlacementAt=fields["proficiencyPlacementAt"] as? String
        for change in (state.pendingImmersionChanges ?? []).sorted(by:{ $0.date < $1.date }) where !(state.acknowledgedEventIDs ?? []).contains(change.id) {
            let reward=state.applyImmersion(change,enqueue:false,award:false)
            state.xpByLanguage[change.target,default:0] += reward
            if CalendarDay.key(change.date) == today { state.dailyXP += reward;state.rewardCompanion(reward,now:change.date) }
        }
        return state
    }
    public static func placementPatch(fields: [String:Any], language: String, placement: Placement) -> [String:Any] {
        let existingLevel = (fields["proficiencyPlacements"] as? [String:String])?[language]
        let savedDetail = (fields["iosPlacementDetails"] as? [String:[String:Any]])?[language] ?? [:]
        let detail = savedDetail["level"] as? String == existingLevel ? savedDetail : [:]
        guard iso(placement.updatedAt) > iso(date(detail["updatedAt"]) ?? (existingLevel == nil ? nil : date(fields["proficiencyPlacementAt"])) ?? .distantPast) else { return [:] }
        var patch: [String:Any] = ["proficiencyPlacements":[language:placement.level],"proficiencyPlacementAt":iso(placement.updatedAt),"iosPlacementDetails":[language:["level":placement.level,"score":placement.score,"source":placement.source,"selectedIDs":placement.selectedIDs,"updatedAt":iso(placement.updatedAt)]]]
        var bucket = (fields["learningIntelligence"] as? [String:[String:Any]])?[language] ?? [:]
        var elo = bucket["elo"] as? [String:Any] ?? [:]
        if placement.source == "self_report" { bucket["selfAssessment"] = ["selectedIds":placement.selectedIDs,"estimatedLevel":placement.level,"estimatedRating":placement.score,"updatedAt":iso(placement.updatedAt)] }
        if integer(elo["totalGraded"]) == 0 && (placement.gradedAtPlacement ?? 0) == 0 {
            elo["rating"] = PerformanceScore.rating(score:Double(placement.score)); elo["scaleVersion"] = 4
            elo["totalGraded"] = 0; elo["initializedFrom"] = placement.source; elo["updatedAt"] = iso(placement.updatedAt)
            bucket["elo"] = elo
        }
        patch["learningIntelligence"] = [language:bucket]
        return patch
    }
    public static func rootPatch(fields: [String:Any], month: [String:Any], change: PracticeChange, now: Date = Date()) -> (root:[String:Any], month:[String:Any]) {
        var progress = fields["progress"] as? [String:Any] ?? [:]
        var languages = progress["languageXp"] as? [String:Any] ?? [:]
        if progress["languageXp"] == nil, progress["totalXp"] != nil { languages[progress["targetLang"] as? String ?? change.target] = integer(progress["totalXp"]) }
        let amount = max(0,change.amount), today = CalendarDay.key(now)
        languages[change.target] = integer(languages[change.target]) + amount
        progress["languageXp"] = languages
        progress["totalXp"] = integer(progress["totalXp"]) + amount
        var recent = fields["dailyXpRecent"] as? [String:Any] ?? fields["dailyXpHistory"] as? [String:Any] ?? [:]
        var days = month["days"] as? [String:Any] ?? [:]
        let previous = max(integer(days[change.dayKey]),integer(recent[change.dayKey]))
        let next = previous + amount
        days[change.dayKey] = next; recent[change.dayKey] = next
        let cutoff = CalendarDay.shift(today,by:-13)
        recent = recent.filter { $0.key >= cutoff && $0.key <= today }
        if let field = change.source.activityField {
            var byLanguage = progress[field] as? [String:[String:Any]] ?? [:]
            var byDay = byLanguage[change.target] ?? [:]
            byDay[change.activityDayKey] = integer(byDay[change.activityDayKey]) + 1
            byLanguage[change.target] = byDay.filter { $0.key >= cutoff && $0.key <= today }
            progress[field] = byLanguage
        }
        if change.source == .questStart {
            progress["dailyQuestFirstSeen"] = true
            if change.questIntro == true && (progress["dailyQuestFirstDayKey"] as? String ?? "").isEmpty { progress["dailyQuestFirstDayKey"] = change.dayKey }
        }
        if change.source == .plateBonus {
            var markers = progress["plateBonusDailyActivity"] as? [String:[String:Any]] ?? [:]
            var days = markers[change.target] ?? [:]; days[change.dayKey] = iso(change.date); markers[change.target] = days
            progress["plateBonusDailyActivity"] = markers
        }
        var root: [String:Any] = ["xp":integer(fields["xp"]) + amount,"progress":progress,"dailyXpRecent":recent,"updatedAt":iso(now)]
        let goal = CompanionHealth.goal(fields)
        var goalDays = month["goalDays"] as? [String] ?? []
        if amount > 0 && goal > 0 && next >= goal {
            goalDays = Array(Set(goalDays + [change.dayKey])).sorted()
            let previousGoal = fields["lastGoalDayKey"] as? String ?? ""
            if change.dayKey > previousGoal {
                root["lastGoalDayKey"] = change.dayKey
                root["goalStreakCount"] = previousGoal == CalendarDay.shift(change.dayKey,by:-1) ? integer(fields["goalStreakCount"]) + 1 : 1
            }
        }
        if change.dayKey == today, amount > 0 {
            root.merge(CompanionHealth.awardFields(fields,amount:amount,now:now)) { _,new in new }
        }

        if change.source == .assessment || change.source == .conversation || change.source == .storyTurn || change.source == .readingTurn, let correct = change.correct {
            var intelligence = fields["learningIntelligence"] as? [String:[String:Any]] ?? [:]
            var bucket = intelligence[change.target] ?? [:]
            var elo = bucket["elo"] as? [String:Any] ?? [:]
            let baseline = integer(elo["scaleVersion"]) == 4 ? number(elo["rating"],default:800) : 800
            elo["rating"] = [.conversation,.storyTurn,.readingTurn].contains(change.source) ? ConversationPractice.rating(baseline,level:change.level,success:correct,worth:change.conversationWorth ?? .null) : QuestionWorth.rating(baseline,level:change.level,correct:correct,independent:change.independent ?? false,worth:change.gradedWorth,support:change.gradedSupport)
            elo["scaleVersion"] = 4; elo["updatedAt"] = iso(change.date)
            elo["totalGraded"] = integer(elo["totalGraded"]) + 1
            var summary = bucket["performanceSummary"] as? [String:Any] ?? [:]
            var levels = summary["byLevel"] as? [String:[String:Any]] ?? [:]
            let evidence=QuestionWorth.evidenceLevel(level:change.level,correct:correct,independent:change.independent ?? false,worth:change.gradedWorth,support:change.gradedSupport)
            var counts = levels[evidence] ?? [:]
            counts[correct ? "correct" : "missed"] = integer(counts[correct ? "correct" : "missed"]) + 1
            levels[evidence] = counts; summary["byLevel"] = levels
            bucket["elo"] = elo; bucket["performanceSummary"] = summary
            if change.source == .assessment,change.gradedWorth != nil { bucket=QuestionWorth.gradedBucket((fields["learningIntelligence"] as? [String:[String:Any]])?[change.target] ?? [:],change:change) }
            if [.conversation,.storyTurn,.readingTurn].contains(change.source) { bucket=ConversationPractice.gradedBucket((fields["learningIntelligence"] as? [String:[String:Any]])?[change.target] ?? [:],change:change) }
            intelligence[change.target] = bucket
            root["learningIntelligence"] = intelligence
        }
        if change.skillTreeLessonID?.hasPrefix("goal-") == true,change.earnedAmount > 0 {
            var intelligence=root["learningIntelligence"] as? [String:[String:Any]] ?? fields["learningIntelligence"] as? [String:[String:Any]] ?? [:]
            let bucket=JSONValue.foundation(intelligence[change.target] ?? [:]),next=GoalLessonProgress.applying(change,to:bucket)
            if next != bucket {intelligence[change.target]=next.foundation;root["learningIntelligence"]=intelligence}
        }
        return (root,["monthKey":String(change.dayKey.prefix(7)),"days":days,"goalDays":goalDays,"updatedAt":iso(now)])
    }
}
