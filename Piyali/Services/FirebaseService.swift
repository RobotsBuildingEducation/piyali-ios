import Foundation
import CryptoKit
import FirebaseAuth
import FirebaseCore
import FirebaseAppCheck
import FirebaseFirestore

final class PiyaliAppCheckFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG
        return AppCheckDebugProvider(app: app)
        #else
        return AppAttestProvider(app: app) ?? DeviceCheckProvider(app: app)
        #endif
    }
}
@MainActor final class FirebaseService {
    static let shared = FirebaseService()
    private let injectedDatabase: Firestore?
    init(database: Firestore? = nil) { injectedDatabase = database }
    var configured: Bool { injectedDatabase != nil || (Bundle.main.url(forResource:"GoogleService-Info",withExtension:"plist") != nil && FirebaseApp.app() != nil) }
    private var database: Firestore? { injectedDatabase ?? (configured ? Firestore.firestore() : nil) }
    static func configure() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1" || ProcessInfo.processInfo.environment["PIYALI_FIRESTORE_EMULATOR_TESTS"] == "1" { return }
        #endif
        guard Bundle.main.url(forResource:"GoogleService-Info",withExtension:"plist") != nil, FirebaseApp.app() == nil else { return }
        AppCheck.setAppCheckProviderFactory(PiyaliAppCheckFactory()); FirebaseApp.configure()
    }
    func appCheckHeaders() async throws -> [String:String] {
        guard configured else { throw AppError.message("Add the iOS GoogleService-Info.plist from Firebase to enable online services.") }
        let token = try await AppCheck.appCheck().token(forcingRefresh:false)
        return ["X-Firebase-AppCheck":token.token]
    }
    private func requireOwner(_ npub: String) throws {
        guard injectedDatabase == nil else { return } // Named emulator databases belong to isolated test fixtures.
        guard Auth.auth().currentUser?.uid == npub else { throw AppError.message("Authenticate your Nostr account before syncing progress.") }
    }
    func load(npub: String, local: LearnerState? = nil) async throws -> LearnerState? {
        guard let database else { return nil }
        try requireOwner(npub)
        let user = database.collection("users").document(npub)
        let snapshot = try await user.getDocument(source:.server)
        guard let fields = snapshot.data() else { return nil }
        var native = local
        if native == nil, let text = fields["iosStateJSON"] as? String { native = try JSONDecoder().decode(LearnerState.self,from:Data(text.utf8)) }
        var state = WebProgressContract.imported(Self.normalized(fields),native:native)
        let lessons = try await user.collection("languageLessons").whereField("targetLang",isEqualTo:state.target).whereField("cefrLevel",isEqualTo:state.level).getDocuments(source:.server)
        for document in lessons.documents {
            let data = document.data()
            if data["status"] as? String == "completed", let id = data["lessonId"] as? String, data["tutorAgendaProgress"] == nil { state.completed.insert(state.completionKey(id)) }
        }
        let tutors = try await user.collection("tutorLanguageLessons").whereField("targetLang",isEqualTo:state.target).whereField("cefrLevel",isEqualTo:state.tutorLevel).getDocuments(source:.server)
        for document in tutors.documents {
            let data = Self.normalized(document.data()); guard let id = data["lessonId"] as? String else { continue }
            if state.tutorLessons == nil { state.tutorLessons = [:] }
            var tutor = TutorLessonProgress(); tutor.earnedXP = max(0,WebProgressContract.integer(data["earnedXp"]))
            let agenda = (data["tutorAgendaProgress"] as? [String:Any])?["items"] as? [String:Bool] ?? [:]
            tutor.items = Set(agenda.filter { $0.value }.keys)
            let key = state.tutorKey(id); state.tutorLessons?[key] = tutor
            if data["status"] as? String == "completed" { state.completed.insert(state.tutorKey(id)) }
        }
        let cards = try await user.collection("languageFlashcards").whereField("targetLang",isEqualTo:state.target).whereField("cefrLevel",isEqualTo:state.flashcardLevel).getDocuments(source:.server)
        for document in cards.documents {
            let data = Self.normalized(document.data())
            guard let id = data["cardId"] as? String else { continue }
            let key = state.completionKey(id), review = WebProgressContract.review(data)
            if state.cardReviews == nil { state.cardReviews = [:] }
            if (review.updatedAt ?? .distantPast) >= (state.cardReviews?[key]?.updatedAt ?? .distantPast) { state.cardReviews?[key] = review }
            if review.completed { state.flashcardMastery.insert(key) }
        }
        let summary = try await user.collection("courseProgress").document(state.target).getDocument(source:.server)
        if let data = summary.data() {
            if state.courseCompletion == nil { state.courseCompletion = [:] }
            for mode in ["skillTree", "flashcards", "tutor"] {
                let levels = (data[mode] as? [String:Any])?["levels"] as? [String:[String:Any]] ?? [:]
                var counts: [String:Int] = [:]
                for level in LearningLanguages.levels { counts[level] = WebProgressContract.integer(levels[level.lowercased().replacingOccurrences(of:"-",with:"_")]?["completed"]) }
                if state.courseCompletion?[state.target] == nil { state.courseCompletion?[state.target] = [:] }
                state.courseCompletion?[state.target]?[mode] = counts
            }
        }
        let day = CalendarDay.key(Date())
        let quest = try await user.collection("questDays").document("\(state.target)_\(day)").getDocument(source:.server)
        if state.goalArtifacts == nil { state.goalArtifacts = [:] }
        for mode in ["flashcards","phonics"] {
            let artifact = JSONValue.foundation(quest.data()?[GoalPractice.artifactField(mode:mode)] as? [String:Any] ?? [:])
            if !artifact["ownerKey"].string.isEmpty { state.goalArtifacts?[artifact["ownerKey"].string] = artifact }
        }
        if let plate = quest.data()?["iosPlate"] as? [String:Any], let kinds = plate["kinds"] as? [String], !kinds.isEmpty {
            if state.questPlans == nil { state.questPlans = [:] }; var plan = DailyQuestPlan(day:day,kinds:kinds); plan.carry = plate["carry"] as? [String]
            state.questPlans?[state.target] = plan
        }
        let journey = try await user.collection("voiceJourney").document(state.target).getDocument(source:.server)
        if state.journeyQuestCounts == nil { state.journeyQuestCounts = [:] }
        state.journeyQuestCounts?[state.target] = max(0,WebProgressContract.integer(journey.data()?["completedQuests"]))
        let memory = try await user.collection("companion").document(state.target).getDocument(source:.server)
        if state.companionMemory == nil { state.companionMemory = [:] }
        state.companionMemory?[state.target] = try Self.memoryNotes(memory.data()?["notes"])
        try await AchievementSyncService.shared.load(user:user,state:&state)
        return state
    }
    func importAchievements(_ records: JSONValue, npub: String) async throws -> [String:JSONValue]? {
        guard let database else { return nil };try requireOwner(npub)
        return try await AchievementSyncService.shared.importRecords(records,user:database.collection("users").document(npub))
    }
    /// Awards are flushed before the snapshot. A failed/partial flush leaves the local outbox intact; retry receipts prevent repeated credit.
    func save(_ state: LearnerState, npub: String) async throws -> LearnerState? {
        guard let database else { return nil }
        try requireOwner(npub)
        let user = database.collection("users").document(npub)
        if !(state.pendingPlacements ?? [:]).isEmpty {
            _ = try await database.runTransaction { transaction,errorPointer -> Any? in
                do {
                    let fields = Self.normalized(try transaction.getDocument(user).data() ?? [:])
                    for (language,placement) in state.pendingPlacements ?? [:] {
                        let patch = WebProgressContract.placementPatch(fields:fields,language:language,placement:placement)
                        if !patch.isEmpty { transaction.setData(patch.merging(["local_npub":npub]) { _,new in new },forDocument:user,merge:true) }
                    }
                    return true
                } catch { errorPointer?.pointee = error as NSError; return nil }
            }
        }
        for change in (state.pendingGoalChanges ?? []).sorted(by:{ $0.date < $1.date }) {
            try await applyGoal(change,state:state,user:user,database:database)
        }
        for change in (state.pendingChanges ?? []).sorted(by:{ $0.date < $1.date }) {
            try await apply(change, state:state, user:user, database:database)
        }
        for change in (state.pendingMemoryChanges ?? []).sorted(by:{ $0.date < $1.date }) {
            try await applyMemory(change,user:user,database:database)
        }
        var snapshotState = state; snapshotState.pendingChanges = []; snapshotState.pendingMemoryChanges = []; snapshotState.pendingGoalChanges = []; snapshotState.preferencesModifiedAt = nil
        let uploaded = snapshotState
        // Keep other-device completion evidence. Preference writes occur only after an explicit local change.
        _ = try await database.runTransaction { transaction, errorPointer -> Any? in
            do {
                let snapshot = try transaction.getDocument(user)
                let fields = snapshot.data() ?? [:]
                let petPatch = CompanionHealth.reconcileFields(Self.normalized(fields))
                var merged = uploaded
                if let text = fields["iosStateJSON"] as? String, let remote = try? JSONDecoder().decode(LearnerState.self,from:Data(text.utf8)) {
                    merged.completed.formUnion(remote.completed); merged.flashcardMastery.formUnion(remote.flashcardMastery)
                    merged.practicedModes.formUnion(remote.practicedModes)
                }
                merged = WebProgressContract.imported(Self.normalized(fields),native:merged)
                // Companion memory has its own shared web document, not a second snapshot authority.
                merged.shareNostrAchievements = nil; merged.achievementRecords = nil; merged.achievementEvidence = nil; merged.achievementLedger = nil; merged.companionProgress = nil; merged.companionMemory = nil; merged.pendingMemoryChanges = []; merged.goalIntelligence = nil; merged.goalArtifacts = nil; merged.pendingGoalChanges = []; merged.questProgress = nil; merged.journeyQuestCounts = nil; merged.tutorLessons = nil; merged.acknowledgedEventIDs = nil
                var patch: [String:Any] = ["local_npub":npub,"iosStateJSON":String(decoding:try JSONEncoder().encode(merged),as:UTF8.self),"iosStateVersion":2,"iosUpdatedAt":FieldValue.serverTimestamp()]
                patch.merge(petPatch) { _,new in new }
                if fields["createdAt"] == nil { patch["createdAt"] = WebProgressContract.iso(Date()) }
                if state.preferencesModifiedAt.map({ $0 > (WebProgressContract.date(Self.normalized(fields)["iosPreferencesModifiedAt"]) ?? .distantPast) }) == true || fields["iosStateJSON"] == nil || !snapshot.exists {
                    patch["iosPreferencesModifiedAt"] = WebProgressContract.iso(state.preferencesModifiedAt ?? Date())
                    let profile = state.preferencesModifiedAt == nil ? merged : state
                    patch["displayName"] = profile.name; patch["language"] = profile.support
                    patch["dailyGoalXp"] = profile.dailyGoal; patch["dailyGoalPetName"] = profile.companionName; patch["dailyGoalPetType"] = profile.effectiveCompanionType
                    patch["onboarding"] = ["completed":profile.onboardingComplete]
                    patch["progress"] = ["targetLang":profile.target,"supportLang":profile.support,"cefrLevel":profile.level,"activeTutorLevels":profile.tutorLevels ?? [profile.target:profile.tutorLevel],"activeLessonLevels":profile.lessonLevels ?? [profile.target:profile.level],"activeFlashcardLevels":profile.flashcardLevels ?? [profile.target:profile.flashcardLevel]]
                }
                transaction.setData(patch,forDocument:user,merge:true)
                return true
            } catch { errorPointer?.pointee = error as NSError; return nil }
        }
        try await AchievementSyncService.shared.sync(user:user,changes:state.pendingChanges ?? [])
        return try await load(npub:npub,local:uploaded)
    }
    private func applyGoal(_ change: GoalChange, state: LearnerState, user: DocumentReference, database: Firestore) async throws {
        let receiptID = SHA256.hash(data:Data(("goal:" + change.id.uuidString).utf8)).map { String(format:"%02x",$0) }.joined()
        let receipt = user.collection("iosPracticeReceipts").document(receiptID)
        let artifactMode = change.payload["mode"].string
        let quest = user.collection("questDays").document("\(change.target)_\(change.payload["dayKey"].string)")
        let day = CalendarDay.key(change.date), month = user.collection("xpHistory").document(String(day.prefix(7)))
        _ = try await database.runTransaction { transaction,errorPointer -> Any? in
            do {
                let existing = try transaction.getDocument(receipt)
                let snapshot = try transaction.getDocument(user)
                let fields = Self.normalized(snapshot.data() ?? [:])
                if existing.exists { Self.acknowledge(change.id,user:user,fields:fields,transaction:transaction); return false }
                let monthFields = Self.normalized(try transaction.getDocument(month).data() ?? [:])
                let original = JSONValue.foundation((fields["learningIntelligence"] as? [String:[String:Any]])?[change.target] ?? [:])
                let result = GoalPractice.applying(change,to:original)
                var reward = result.reward
                if [.artifact,.outcome].contains(change.action) {
                    let questFields = Self.normalized(try transaction.getDocument(quest).data() ?? [:])
                    if GoalPractice.active(original)?["id"] == change.payload["goalId"], original["dailyGoal"]["blueprint"]["dayKey"] == change.payload["dayKey"] {
                        let field = GoalPractice.artifactField(mode:artifactMode)
                        let artifact = GoalPractice.applyingArtifact(change,to:JSONValue.foundation(questFields[field] as? [String:Any] ?? [:]))
                        if !artifact.artifact.object.isEmpty { transaction.setData([field:artifact.artifact.foundation],forDocument:quest,merge:true) }
                        reward += artifact.reward
                    }
                }
                var root: [String:Any] = ["local_npub":user.documentID,"iosRecentEventIDs":Self.recentIDs(fields,adding:change.id)]
                let changed = result.bucket.object.filter { ["version","activeGoal","goalProgress","dailyGoal"].contains($0.key) }
                if !changed.isEmpty { root["learningIntelligence"] = [change.target:JSONValue.object(changed).foundation] }
                if !snapshot.exists { root["dailyGoalXp"] = state.dailyGoal; root["createdAt"] = WebProgressContract.iso(change.date) }
                if reward > 0 {
                    let practice = PracticeChange(date:change.date,dayKey:day,target:change.target,level:change.payload["cefrLevel"].string,amount:reward,source:.goalMode)
                    var awardFields = fields
                    if awardFields["dailyGoalXp"] == nil { awardFields["dailyGoalXp"] = state.dailyGoal }
                    let award = WebProgressContract.rootPatch(fields:awardFields,month:monthFields,change:practice)
                    root.merge(award.root) { _,new in new }
                    transaction.setData(award.month,forDocument:month,merge:true)
                }
                if result.bucket["dailyGoal"]["completed"].boolean && !original["dailyGoal"]["completed"].boolean {
                    var progress = root["progress"] as? [String:Any] ?? fields["progress"] as? [String:Any] ?? [:]
                    var activity = progress["goalDailyActivity"] as? [String:[String:Any]] ?? [:]
                    var days = activity[change.target] ?? [:]; days[change.payload["dayKey"].string] = 1; activity[change.target] = days
                    progress["goalDailyActivity"] = activity; root["progress"] = progress
                }
                transaction.setData(root,forDocument:user,merge:true)
                // Replace the owned goal maps as whole fields so a new day cannot inherit old mode counts or blueprint targets.
                var exactGoalFields: [AnyHashable:Any] = [:]
                for (key,value) in changed {
                    exactGoalFields[FieldPath(["learningIntelligence",change.target,key])] = try JSONSerialization.jsonObject(with:Data(value.json.utf8),options:.fragmentsAllowed)
                }
                if !exactGoalFields.isEmpty { transaction.updateData(exactGoalFields,forDocument:user) }
                transaction.setData(["eventID":change.id.uuidString,"source":"goal-" + change.action.rawValue,"targetLang":change.target,"syncedAt":FieldValue.serverTimestamp()],forDocument:receipt)
                return true
            } catch { errorPointer?.pointee = error as NSError; return nil }
        }
    }
    private func apply(_ change: PracticeChange, state: LearnerState, user: DocumentReference, database: Firestore) async throws {
        let stable = [.lesson,.goal,.repair,.plateBonus,.speak,.phonics].contains(change.source) ? "\(change.source.rawValue):\(change.target):\(change.source == .plateBonus ? change.dayKey : change.source == .phonics ? change.dayKey + ":" + (change.contentID ?? change.id.uuidString) : change.contentID ?? change.id.uuidString)" : change.id.uuidString
        let receiptID = SHA256.hash(data:Data(stable.utf8)).map { String(format:"%02x",$0) }.joined()
        let receipt = user.collection("iosPracticeReceipts").document(receiptID)
        let month = user.collection("xpHistory").document(String(change.dayKey.prefix(7)))
        let collection = change.source == .phonics ? "alphabetPractice" : change.source == .review ? "languageFlashcards" : change.source == .lesson ? "languageLessons" : [.tutorTurn,.speak].contains(change.source) ? "tutorLanguageLessons" : nil
        let content = collection.flatMap { collection in change.contentID.map { user.collection(collection).document("\(change.target)_\($0)") } }
        let summary = user.collection("courseProgress").document(change.target)
        let quest = [.questStart,.plateBonus].contains(change.source) ? user.collection("questDays").document("\(change.target)_\(change.dayKey)") : nil
        let journey = change.source == .plateBonus ? user.collection("voiceJourney").document(change.target) : nil
        let journeyReceipt = journey?.collection("completions").document(change.dayKey)
        _ = try await database.runTransaction { transaction, errorPointer -> Any? in
            do {
                // Complete all reads before any writes, including the first-ever user document.
                let receiptSnapshot = try transaction.getDocument(receipt)
                if receiptSnapshot.exists {
                    let fields = try transaction.getDocument(user).data() ?? [:]
                    Self.acknowledge(change.id,user:user,fields:fields,transaction:transaction)
                    return false
                }
                let userSnapshot = try transaction.getDocument(user)
                let monthSnapshot = try transaction.getDocument(month)
                let contentSnapshot = try content.map { try transaction.getDocument($0) }
                var fields = Self.normalized(userSnapshot.data() ?? [:])
                let questFields = try quest.map { Self.normalized(try transaction.getDocument($0).data() ?? [:]) } ?? [:]
                let journeyFields = try journey.map { Self.normalized(try transaction.getDocument($0).data() ?? [:]) } ?? [:]
                let journeyCounted = try journeyReceipt.map { try transaction.getDocument($0).exists } ?? false
                let progress = JSONValue.foundation(fields["progress"] as? [String:Any] ?? [:])
                let first = DailyPlate.firstSession(progress:progress,day:change.dayKey,priorLearning:WebProgressContract.integer(fields["xp"]) > 0 || DailyPlate.hasActivity(progress))
                let savedKinds = (questFields["iosPlate"] as? [String:Any])?["kinds"] as? [String]
                let base = first ? DailyPlate.introductory : savedKinds ?? change.questKinds ?? DailyPlate.introductory
                if change.source == .plateBonus {
                    let bucket = JSONValue.foundation((fields["learningIntelligence"] as? [String:[String:Any]])?[change.target] ?? [:])
                    let kinds = DailyPlate.compose(base:base,carry:(questFields["iosPlate"] as? [String:Any])?["carry"] as? [String] ?? [],repair:change.questKinds?.contains("repair") == true,goal:GoalPractice.active(bucket) != nil,first:first)
                    let courses = DailyPlate.courses(progress:progress,bucket:bucket,user:user.documentID,target:change.target,day:change.dayKey,kinds:kinds,first:first)
                    guard !courses.isEmpty, courses.allSatisfy(\.done), !DailyPlate.bonusAwarded(progress:progress,target:change.target,day:change.dayKey) else { return false }
                }
                if !userSnapshot.exists { fields["dailyGoalXp"] = state.dailyGoal; fields["onboarding"] = ["completed":state.onboardingComplete] }
                let patch = WebProgressContract.rootPatch(fields:fields,month:Self.normalized(monthSnapshot.data() ?? [:]),change:change)
                var root = patch.root; root["local_npub"] = user.documentID
                root["iosRecentEventIDs"] = Self.recentIDs(fields,adding:change.id)
                if !userSnapshot.exists { root["createdAt"] = WebProgressContract.iso(change.date); root["dailyGoalXp"] = state.dailyGoal }
                transaction.setData(root,forDocument:user,merge:true)
                transaction.setData(patch.month,forDocument:month,merge:true)
                if let quest, change.source == .questStart, savedKinds == nil {
                    transaction.setData(["iosPlate":["dayKey":change.dayKey,"kinds":base,"carry":change.questCarry ?? [],"createdAt":WebProgressContract.iso(change.date)]],forDocument:quest,merge:true)
                }
                if let journey, let journeyReceipt, !journeyCounted {
                    let count = max(0,WebProgressContract.integer(journeyFields["completedQuests"])) + 1
                    var unlocked = journeyFields["unlockedAt"] as? [String:Any] ?? [:]
                    for milestone in [1,5,15,30,45,60,90,120,150] where milestone <= count && unlocked[String(milestone)] == nil { unlocked[String(milestone)] = WebProgressContract.iso(change.date) }
                    transaction.setData(["version":1,"completedQuests":count,"unlockedAt":unlocked,"updatedAt":WebProgressContract.iso(change.date)],forDocument:journey,merge:true)
                    transaction.setData(["completedAt":WebProgressContract.iso(change.date),"session":count],forDocument:journeyReceipt)
                }
                if let content, change.source == .phonics {
                    transaction.setData(["letterId":change.contentID ?? "","targetLang":change.target,"cefrLevel":change.level,"correctCount":FieldValue.increment(Int64(1)),"updatedAt":WebProgressContract.iso(change.date)],forDocument:content,merge:true)
                }
                if let content, change.source != .phonics {
                    let existing = Self.normalized(contentSnapshot?.data() ?? [:])
                    var data: [String:Any] = ["targetLang":change.target,"cefrLevel":change.level,"updatedAt":WebProgressContract.iso(change.date)]
                    let completed: Bool, wasCompleted: Bool, mode: String
                    if change.source == .review {
                        var review = WebProgressContract.review(existing)
                        if (review.updatedAt ?? .distantPast) <= change.date, let rating = change.reviewRating { review = review.applying(rating,now:change.date) }
                        data.merge(WebProgressContract.reviewFields(review)) { _,new in new }; data["cardId"] = change.contentID
                        completed = review.completed; wasCompleted = existing["completed"] as? Bool == true; mode = "flashcards"
                    } else if change.source == .tutorTurn {
                        data["lessonId"] = change.contentID; data["status"] = existing["status"] ?? "in_progress"
                        data["earnedXp"] = WebProgressContract.integer(existing["earnedXp"]) + change.amount
                        var items = (existing["tutorAgendaProgress"] as? [String:Any])?["items"] as? [String:Bool] ?? [:]
                        if let item = change.tutorAgendaItemID { items[item] = true }
                        data["tutorAgendaProgress"] = ["schemaVersion":2,"items":items,"updatedAt":WebProgressContract.iso(change.date)]
                        completed = false; wasCompleted = existing["status"] as? String == "completed"; mode = "tutor"
                    } else {
                        data["lessonId"] = change.contentID; data["status"] = "completed"
                        data["completedAt"] = existing["completedAt"] ?? WebProgressContract.iso(change.date)
                        data["earnedXp"] = max(change.amount,WebProgressContract.integer(existing["earnedXp"]))
                        data["xpEarned"] = change.amount
                        completed = true; wasCompleted = existing["status"] as? String == "completed"; mode = change.source == .speak ? "tutor" : "skillTree"
                    }
                    transaction.setData(data,forDocument:content,merge:true)
                    if completed && !wasCompleted {
                        let levelKey = change.level.lowercased().replacingOccurrences(of:"-",with:"_")
                        let totals = ["skillTree","tutor"].contains(mode) ? ["Pre-A1":86,"A1":98,"A2":126,"B1":105,"B2":84,"C1":70,"C2":56] : ["Pre-A1":100,"A1":300,"A2":250,"B1":200,"B2":150,"C1":100,"C2":50]
                        transaction.setData(["schemaVersion":1,"targetLang":change.target,mode:["levels":[levelKey:["completed":FieldValue.increment(Int64(1)),"total":totals[change.level,default:0]]]],"updatedAt":FieldValue.serverTimestamp()],forDocument:summary,merge:true)
                    }
                }
                transaction.setData(["eventID":change.id.uuidString,"source":change.source.rawValue,"targetLang":change.target,"amount":change.amount,"practicedAt":WebProgressContract.iso(change.date),"syncedAt":FieldValue.serverTimestamp()],forDocument:receipt)
                return true
            } catch { errorPointer?.pointee = error as NSError; return nil }
        }
    }
    private func applyMemory(_ change: MemoryChange, user: DocumentReference, database: Firestore) async throws {
        let receipt = user.collection("iosPracticeReceipts").document("memory-" + change.id.uuidString)
        let bucket = user.collection("companion").document(change.target)
        _ = try await database.runTransaction { transaction,errorPointer -> Any? in
            do {
                if try transaction.getDocument(receipt).exists {
                    let fields = try transaction.getDocument(user).data() ?? [:]
                    Self.acknowledge(change.id,user:user,fields:fields,transaction:transaction)
                    return false
                }
                let userSnapshot = try transaction.getDocument(user)
                let memory = try transaction.getDocument(bucket)
                let original = try Self.memoryNotes(memory.data()?["notes"])
                let today = CalendarDay.key(Date())
                let notes = MemoryContract.applying(change,to:original,today:today)
                let json = try JSONEncoder().encode(notes.map(\.fields))
                let payload = try JSONSerialization.jsonObject(with:json)
                transaction.setData(["local_npub":user.documentID,"iosRecentEventIDs":Self.recentIDs(userSnapshot.data() ?? [:],adding:change.id)],forDocument:user,merge:true)
                var patch: [String:Any] = ["lang":change.target,"notes":payload]
                if original.contains(where:{ !$0.text("expiresAfterDayKey").isEmpty && $0.text("expiresAfterDayKey") < today }) { patch["lastPrunedDayKey"] = today }
                transaction.setData(patch,forDocument:bucket,merge:true)
                transaction.setData(["eventID":change.id.uuidString,"source":"memory-" + change.action.rawValue,"targetLang":change.target,"practicedAt":WebProgressContract.iso(change.date),"syncedAt":FieldValue.serverTimestamp()],forDocument:receipt)
                return true
            } catch { errorPointer?.pointee = error as NSError; return nil }
        }
    }
    // A bounded acknowledgment journal also covers changes committed by overlapping sync requests.
    nonisolated private static func recentIDs(_ fields: [String:Any], adding id: UUID) -> [String] {
        let value = id.uuidString
        return Array(((fields["iosRecentEventIDs"] as? [String] ?? []).filter { $0 != value } + [value]).suffix(512))
    }
    nonisolated private static func acknowledge(_ id: UUID, user: DocumentReference, fields: [String:Any], transaction: Transaction) {
        if !(fields["iosRecentEventIDs"] as? [String] ?? []).contains(id.uuidString) {
            transaction.setData(["local_npub":user.documentID,"iosRecentEventIDs":recentIDs(fields,adding:id)],forDocument:user,merge:true)
        }
    }
    nonisolated private static func memoryNotes(_ raw: Any?) throws -> [MemoryNote] {
        guard let raw else { return [] }
        func compatible(_ value: Any) -> Any {
            if let date = value as? Timestamp { return WebProgressContract.iso(date.dateValue()) }
            if let date = value as? Date { return WebProgressContract.iso(date) }
            if let map = value as? [String:Any] { return map.mapValues(compatible) }
            if let array = value as? [Any] { return array.map(compatible) }
            return value
        }
        let data = try JSONSerialization.data(withJSONObject:compatible(raw))
        return try JSONDecoder().decode([[String:JSONValue]].self,from:data).map(MemoryNote.init(fields:))
    }
    nonisolated private static func normalized(_ fields: [String:Any]) -> [String:Any] {
        func value(_ input: Any) -> Any {
            if let timestamp = input as? Timestamp { return timestamp.dateValue() }
            if let map = input as? [String:Any] { return map.mapValues(value) }
            if let array = input as? [Any] { return array.map(value) }
            return input
        }
        return fields.mapValues(value)
    }
}
