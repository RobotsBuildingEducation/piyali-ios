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
@MainActor final class FirebaseService:LearnerProgressService {
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
    /// Claim before contacting the provider. Returns the authoritative day when another device already owns it.
    func reserveRepairArtifact(npub:String,step:RepairStep,mode:String,candidate:JSONValue) async throws -> JSONValue {
        guard let database else{throw AppError.message("Sync your account before preparing repair practice.")};try requireOwner(npub)
        let reference=database.collection("users").document(npub).collection("questDays").document(CompanionQuestDay.key(step.target,step.day)),field=CompanionQuestDay.artifactField(step,mode:mode)
        let result=try await database.runTransaction {transaction,error in
            do {
                let existing=JSONValue.foundation(Self.normalized(try transaction.getDocument(reference).data() ?? [:]))[field]
                if existing["ownerKey"] == candidate["ownerKey"],!existing["cards"].array.isEmpty{return existing.foundation}
                transaction.setData([field:candidate.foundation,"lang":step.target,"dayKey":step.day],forDocument:reference,merge:true)
                return candidate.foundation
            }catch let failure{error?.pointee=failure as NSError;return nil}
        }
        return JSONValue.foundation(result)
    }
    func reserveCompanionQuest(npub:String,target:String,day:String,id:String,now:Date = Date()) async throws -> JSONValue {
        guard let database else {throw AppError.message("Sync your account before preparing its daily quest.")};try requireOwner(npub)
        let reference=database.collection("users").document(npub).collection("questDays").document(CompanionQuestDay.key(target,day))
        let result=try await database.runTransaction {transaction,error in
            do {
                let existing=JSONValue.foundation(Self.normalized(try transaction.getDocument(reference).data() ?? [:]))
                guard let marker=CompanionQuestDay.reserve(existing,id:id,target:target,day:day,now:now) else{return existing.foundation}
                let patch:[String:Any]=["blueprint":marker.foundation,"lang":target,"dayKey":day,"updatedAt":WebProgressContract.iso(now)]
                transaction.setData(patch,forDocument:reference,merge:true)
                return existing.setting("blueprint",marker).setting("lang",.string(target)).setting("dayKey",.string(day)).foundation
            }catch let failure{error?.pointee=failure as NSError;return nil}
        }
        return JSONValue.foundation(result)
    }
    func recordSessionTimer(npub:String,id:String) async throws {
        guard let database else{throw AppError.message("Sync your account to save this timer achievement.")};try requireOwner(npub)
        guard UUID(uuidString:id) != nil else{throw AppError.message("Invalid timer completion.")}
        let user=database.collection("users").document(npub)
        let event=user.collection("achievementProgress").document("nosabos").collection("events").document(try AchievementSyncService.documentID(metric:"session_timers",id:id))
        _ = try await database.runTransaction {transaction,error in
            do{if !(try transaction.getDocument(event)).exists{transaction.setData(["source":"nosabos","metric":"session_timers","completionId":id,"createdAt":FieldValue.serverTimestamp()],forDocument:event)};return true}
            catch let failure{error?.pointee=failure as NSError;return nil}
        }
        try await AchievementSyncService.shared.refreshLedger(user:user)
        try await AchievementSyncService.shared.sync(user:user,changes:[])
    }
    func activityHistory(npub:String,year:Int) async throws -> JSONValue {
        guard (1900...2200).contains(year),let database else { return .object([:]) }
        try requireOwner(npub)
        let months=try await database.collection("users").document(npub).collection("xpHistory").whereField(FieldPath.documentID(),isGreaterThanOrEqualTo:"\(year)-01").whereField(FieldPath.documentID(),isLessThanOrEqualTo:"\(year)-12").getDocuments()
        var days:[String:Any]=[:],goals:Set<String>=[]
        for month in months.documents { let values=Self.normalized(month.data());days.merge(values["days"] as? [String:Any] ?? [:]) { _,new in new };goals.formUnion(values["goalDays"] as? [String] ?? []) }
        return JSONValue.foundation(["days":days,"goalDays":goals.sorted()])
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
            let data = Self.normalized(document.data())
            if let id=data["lessonId"] as? String { state.importLessonWork(data,id:id,target:state.target) }
        }
        let tutors = try await user.collection("tutorLanguageLessons").whereField("targetLang",isEqualTo:state.target).getDocuments(source:.server)
        for document in tutors.documents {
            let data = Self.normalized(document.data()); guard let id = data["lessonId"] as? String else { continue }
            if state.tutorLessons == nil { state.tutorLessons = [:] }
            let tutor = TutorSourceProgress.importing(PhonicsProgress.document(data))
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
        let phonics=try await user.collection("alphabetPractice").whereField("targetLang",isEqualTo:state.target).getDocuments(source:.server)
        state.phonicsRecords=(state.phonicsRecords ?? [:]).filter{!$0.key.hasPrefix(state.target+":")}
        for document in phonics.documents {let value=PhonicsProgress.document(Self.normalized(document.data()));let id=value["letterId"].string;if !id.isEmpty{state.phonicsRecords?[PhonicsProgress.key(state.target,id)]=value}}
        for change in state.pendingChanges ?? [] where !(state.acknowledgedEventIDs ?? []).contains(change.id){state.applyPhonics(change)}
        let summary = try await user.collection("courseProgress").document(state.target).getDocument(source:.server)
        state.importCourseSummary(PhonicsProgress.document(Self.normalized(summary.data() ?? [:])),target:state.target)
        let tutorIndex=(try? ContentLibrary.load([String:[String:[String]]].self,name:"tutor-curriculum-index"))?[state.target] ?? [:]
        state.reconcileTutorUnlock(index:tutorIndex)
        let day = CalendarDay.key(Date())
        let quest = try await user.collection("questDays").document("\(state.target)_\(day)").getDocument(source:.server)
        state.importQuestDay(JSONValue.foundation(Self.normalized(quest.data() ?? [:])),target:state.target,day:day)
        let tomorrow=CalendarDay.shift(day,by:1)
        let nextQuest=try await user.collection("questDays").document(CompanionQuestDay.key(state.target,tomorrow)).getDocument(source:.server)
        state.importQuestDay(JSONValue.foundation(Self.normalized(nextQuest.data() ?? [:])),target:state.target,day:tomorrow)
        if state.goalArtifacts == nil { state.goalArtifacts = [:] }
        for mode in ["flashcards","phonics"] {
            let artifact = JSONValue.foundation(quest.data()?[GoalPractice.artifactField(mode:mode)] as? [String:Any] ?? [:])
            if !artifact["ownerKey"].string.isEmpty { state.goalArtifacts?[artifact["ownerKey"].string] = artifact }
        }
        if let plate = quest.data()?["iosPlate"] as? [String:Any], let kinds = plate["kinds"] as? [String], !kinds.isEmpty {
            if state.questPlans == nil { state.questPlans = [:] }; var plan = DailyQuestPlan(day:day,kinds:kinds); plan.carry = plate["carry"] as? [String];plan.yesterdayComplete=plate["yesterdayComplete"] as? Bool
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
        for change in (state.pendingGoalChanges ?? []).filter({!$0.payload["requireLessonCompletion"].boolean}).sorted(by:{ $0.date < $1.date }) {
            try await applyGoal(change,state:state,user:user,database:database)
        }
        for change in (state.pendingChanges ?? []).sorted(by:{ $0.date < $1.date }) {
            try await apply(change, state:state, user:user, database:database)
        }
        // The final question's XP must reach the canonical goal counter before its completion is checked.
        for change in (state.pendingGoalChanges ?? []).filter({$0.payload["requireLessonCompletion"].boolean}).sorted(by:{$0.date < $1.date}) {
            try await applyGoal(change,state:state,user:user,database:database)
        }
        for change in (state.pendingImmersionChanges ?? []).sorted(by:{ $0.date < $1.date }) {
            try await applyImmersion(change,state:state,user:user,database:database)
        }
        for change in (state.pendingMemoryChanges ?? []).sorted(by:{ $0.date < $1.date }) {
            try await applyMemory(change,user:user,database:database)
        }
        if !(state.pendingRepairEvidence ?? []).isEmpty {
            guard let sourceURL=Bundle.main.url(forResource:"companion-quest-policy",withExtension:"js") else{throw PracticeRecipeFailure.unavailable}
            let source=try String(contentsOf:sourceURL,encoding:.utf8)
            for change in state.pendingRepairEvidence ?? [] {
                let receipt=user.collection("iosPracticeReceipts").document("repair-evidence-"+SHA256.hash(data:Data((change.target+":"+change.event["id"].string).utf8)).map{String(format:"%02x",$0)}.joined())
                _ = try await database.runTransaction {transaction,error in
                    do {
                        let existing=try transaction.getDocument(receipt),fields=Self.normalized(try transaction.getDocument(user).data() ?? [:])
                        if existing.exists{return false}
                        let summary=JSONValue.foundation((fields["learningIntelligence"] as? [String:[String:Any]])?[change.target]?["repairSummary"] as? [String:Any] ?? [:])
                        let next=try CompanionQuestRuntime.run(source:source,operation:"evidence",input:.object(["summary":summary,"event":change.event,"now":.number(change.date.timeIntervalSince1970*1000)]))
                        transaction.updateData([FieldPath(["learningIntelligence",change.target,"repairSummary"]):next.foundation],forDocument:user)
                        transaction.setData(["source":"repair-evidence","eventID":change.event["id"].string,"syncedAt":FieldValue.serverTimestamp()],forDocument:receipt)
                        return true
                    }catch let failure{error?.pointee=failure as NSError;return nil}
                }
            }
        }
        var savedQuestDays:[String:JSONValue]=[:]
        for (key,patch) in state.pendingCompanionQuestDays ?? [:] {
            guard key == CompanionQuestDay.key(patch["lang"].string,patch["dayKey"].string),!key.contains("/"),!patch["lang"].string.isEmpty,!patch["dayKey"].string.isEmpty else{throw AppError.message("Invalid quest day.")}
            let reference=user.collection("questDays").document(key)
            let result=try await database.runTransaction {transaction,error in
                do {
                    let document=JSONValue.foundation(Self.normalized(try transaction.getDocument(reference).data() ?? [:]))
                    let merged=CompanionQuestDay.merging(patch,into:document)
                    // Merge only these owned fields; a concurrently prepared goal artifact or plate is retained.
                    let fields=try merged.object.filter{CompanionQuestDay.ownedFields.contains($0.key)}.mapValues{try JSONSerialization.jsonObject(with:Data($0.json.utf8),options:.fragmentsAllowed)}
                    transaction.setData(fields,forDocument:reference,merge:true)
                    return merged.foundation
                }catch let failure{error?.pointee=failure as NSError;return nil}
            }
            savedQuestDays[key]=JSONValue.foundation(result)
        }
        var snapshotState = state; snapshotState.pendingCompanionQuestDays=[:];snapshotState.pendingRepairEvidence=[]; snapshotState.pendingPlateHeadlines = [:]; snapshotState.pendingImmersionChanges = []; snapshotState.pendingChanges = []; snapshotState.pendingMemoryChanges = []; snapshotState.pendingGoalChanges = []; snapshotState.preferencesModifiedAt = nil
        let uploaded = snapshotState
        let tutorIndex=(try? ContentLibrary.load([String:[String:[String]]].self,name:"tutor-curriculum-index"))?[uploaded.target] ?? [:]
        // Keep other-device completion evidence. Preference writes occur only after an explicit local change.
        _ = try await database.runTransaction { transaction, errorPointer -> Any? in
            do {
                let snapshot = try transaction.getDocument(user)
                let fields = snapshot.data() ?? [:]
                let courseSummary=Self.normalized(try transaction.getDocument(user.collection("courseProgress").document(uploaded.target)).data() ?? [:])
                let petPatch = CompanionHealth.reconcileFields(Self.normalized(fields))
                var merged = uploaded
                if let text = fields["iosStateJSON"] as? String, let remote = try? JSONDecoder().decode(LearnerState.self,from:Data(text.utf8)) {
                    merged.completed.formUnion(remote.completed); merged.flashcardMastery.formUnion(remote.flashcardMastery)
                    merged.practicedModes.formUnion(remote.practicedModes)
                }
                merged = WebProgressContract.imported(Self.normalized(fields),native:merged)
                merged.importCourseSummary(PhonicsProgress.document(courseSummary),target:uploaded.target)
                let selectedTarget=merged.target;merged.target=uploaded.target
                merged.reconcileTutorUnlock(index:tutorIndex);merged.target=selectedTarget
                merged.phonicsRecords=nil;merged.pendingRepairEvidence=[];merged.companionQuestDays=nil;merged.pendingCompanionQuestDays=[:];merged.plateHeadlines=nil;merged.pendingPlateHeadlines=[:];merged.immersionBatch=nil;merged.immersionHistory=nil;merged.immersionRewardReceipts=nil;merged.immersionPlacementAt=nil;merged.pendingImmersionChanges=[]
                // Companion memory has its own shared web document, not a second snapshot authority.
                merged.shareNostrAchievements = nil; merged.achievementRecords = nil; merged.achievementEvidence = nil; merged.achievementLedger = nil; merged.companionProgress = nil; merged.companionMemory = nil; merged.pendingMemoryChanges = []; merged.goalIntelligence = nil; merged.goalArtifacts = nil; merged.pendingGoalChanges = []; merged.questProgress = nil; merged.journeyQuestCounts = nil; merged.tutorLessons = nil; merged.acknowledgedEventIDs = nil
                var patch: [String:Any] = ["local_npub":npub,"iosStateJSON":String(decoding:try JSONEncoder().encode(merged),as:UTF8.self),"iosStateVersion":2,"iosUpdatedAt":FieldValue.serverTimestamp()]
                // The shared field is the sole headline authority. Merge only
                // dirty language entries, retaining the web's last-write
                // behavior across local-day/timezone and support changes.
                var headlinePatch:[String:Any]=[:]
                for (target,value) in state.pendingPlateHeadlines ?? [:] {
                    headlinePatch[target]=value.fields
                }
                if !headlinePatch.isEmpty {patch["dailyPlateHeadline"]=headlinePatch}
                // Acknowledging guidance is monotonic and independent of
                // preference timestamps, so a stale device cannot unsee it.
                if state.gettingStartedModalShown == true {patch["gettingStartedModalShown"]=true}
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
                if !(merged.tutorUnlockedLevels ?? [:]).isEmpty {
                    var progress=patch["progress"] as? [String:Any] ?? [:]
                    progress["tutorUnlockedLevels"]=merged.tutorUnlockedLevels
                    patch["progress"]=progress
                }
                transaction.setData(patch,forDocument:user,merge:true)
                return true
            } catch { errorPointer?.pointee = error as NSError; return nil }
        }
        if !(state.pendingImmersionChanges ?? []).isEmpty || (state.pendingChanges ?? []).contains(where:{ $0.conversationGoalID != nil }) { try await AchievementSyncService.shared.refreshLedger(user:user) }
        try await AchievementSyncService.shared.sync(user:user,changes:state.pendingChanges ?? [])
        var acknowledged=try await load(npub:npub,local:uploaded)
        for (key,value) in savedQuestDays {if acknowledged?.companionQuestDays == nil {acknowledged?.companionQuestDays=[:]};acknowledged?.companionQuestDays?[key]=value}
        return acknowledged
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
    private func applyPhonicsDeck(_ change:PracticeChange,user:DocumentReference,database:Firestore) async throws {
        let records=change.phonicsData?["records"].array ?? []
        guard records.count == 6,Set(records.map{$0["letterId"].string}).count == 6,records.allSatisfy({$0["targetLang"].string == change.target && $0["letterId"].string.hasPrefix("gen_") && !$0["letterId"].string.contains("/")}) else{throw AppError.message("Invalid pronunciation deck.")}
        let receipt=user.collection("iosPracticeReceipts").document(change.id.uuidString)
        _=try await database.runTransaction {transaction,error in
            do {
                let prior=try transaction.getDocument(receipt),fields=try transaction.getDocument(user).data() ?? [:]
                if prior.exists {Self.acknowledge(change.id,user:user,fields:fields,transaction:transaction);return false}
                for record in records {var data=record.foundation as? [String:Any] ?? [:];data["createdAt"]=FieldValue.serverTimestamp();data["updatedAt"]=FieldValue.serverTimestamp();transaction.setData(data,forDocument:user.collection("alphabetPractice").document(change.target+"_"+record["letterId"].string),merge:true)}
                Self.acknowledge(change.id,user:user,fields:fields,transaction:transaction)
                transaction.setData(["source":"phonicsDeck","syncedAt":FieldValue.serverTimestamp()],forDocument:receipt)
                return true
            }catch let failure{error?.pointee=failure as NSError;return nil}
        }
    }
    private func apply(_ change: PracticeChange, state: LearnerState, user: DocumentReference, database: Firestore) async throws {
        if change.source == .phonicsDeck {try await applyPhonicsDeck(change,user:user,database:database);return}
        let stable = [.readingTurn,.readingSpeech].contains(change.source) ? "reading:\(change.target):\(change.contentID ?? change.id.uuidString)" : [.lesson,.goal,.repair,.repairPractice,.plateBonus,.speak,.phonics,.storyTurn,.storyCompletion].contains(change.source) ? "\(change.source.rawValue):\(change.target):\(change.source == .plateBonus ? change.dayKey : change.source == .phonics ? change.dayKey + ":" + (change.contentID ?? change.id.uuidString) : change.contentID ?? change.id.uuidString)" : change.id.uuidString
        let receiptID = SHA256.hash(data:Data(stable.utf8)).map { String(format:"%02x",$0) }.joined()
        let receipt = user.collection("iosPracticeReceipts").document(receiptID)
        let month = user.collection("xpHistory").document(String(change.dayKey.prefix(7)))
        let collection = change.source == .phonicsAttempt ? (change.phonicsData?["focused"].boolean == true ? nil:"alphabetPractice"):change.source == .phonics ? (change.phonicsData?["collection"].boolean == true ? nil:"alphabetPractice") : change.source == .review ? "languageFlashcards" : [.lessonStart,.lesson].contains(change.source) ? "languageLessons" : [.tutorTurn,.tutorState,.speak].contains(change.source) ? "tutorLanguageLessons" : nil
        let content = collection.flatMap { collection in change.contentID.map { user.collection(collection).document("\(change.target)_\($0)") } }
        let activeLesson = change.skillTreeLessonID.flatMap { CurriculumLessonProgress.isCurriculumID($0) && change.amount > 0 && change.source != .lesson ? user.collection("languageLessons").document("\(change.target)_\($0)") : nil }
        let summary = user.collection("courseProgress").document(change.target)
        let quest = [.questStart,.plateBonus].contains(change.source) ? user.collection("questDays").document("\(change.target)_\(change.dayKey)") : nil
        let journey = change.source == .plateBonus ? user.collection("voiceJourney").document(change.target) : nil
        let journeyReceipt = journey?.collection("completions").document(change.dayKey)
        let goalID=change.source == .conversation && change.correct == true && !(change.conversationGoalText?["en"].string.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty ?? true) ? change.conversationGoalID : nil
        let goalClaim=goalID.map { user.collection("iosPracticeReceipts").document("conversation-goal-"+SHA256.hash(data:Data($0.utf8)).map { String(format:"%02x",$0) }.joined()) }
        let goalEvent=try goalID.map { user.collection("achievementProgress").document("nosabos").collection("events").document(try AchievementSyncService.documentID(metric:"conversation_goals",id:$0)) }
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
                let activeLessonSnapshot = try activeLesson.map { try transaction.getDocument($0) }
                var fields = Self.normalized(userSnapshot.data() ?? [:])
                if change.source == .lesson,contentSnapshot?.data()?["status"] as? String == "completed" {
                    Self.acknowledge(change.id,user:user,fields:fields,transaction:transaction)
                    transaction.setData(["eventID":change.id.uuidString,"source":change.source.rawValue,"amount":0,"syncedAt":FieldValue.serverTimestamp()],forDocument:receipt)
                    return false
                }
                let questFields = try quest.map { Self.normalized(try transaction.getDocument($0).data() ?? [:]) } ?? [:]
                let journeyFields = try journey.map { Self.normalized(try transaction.getDocument($0).data() ?? [:]) } ?? [:]
                let journeyCounted = try journeyReceipt.map { try transaction.getDocument($0).exists } ?? false
                let goalClaimed=try goalClaim.map { try transaction.getDocument($0).exists } ?? false
                let goalRecorded=try goalEvent.map { try transaction.getDocument($0).exists } ?? false
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
                var accepted=change
                if change.source == .conversation {
                    accepted.amount=min(3,max(0,change.amount))+(goalID != nil && !goalClaimed ? min(4,max(2,change.conversationBonus ?? 2)) : 0)
                    if goalClaimed || accepted.correct == true && goalID == nil { accepted.correct=nil }
                }
                let patch = WebProgressContract.rootPatch(fields:fields,month:Self.normalized(monthSnapshot.data() ?? [:]),change:accepted)
                let activityWithoutXP=accepted.amount == 0 && (accepted.source == .tutorState || accepted.source == .phonicsAttempt || accepted.source == .phonics && accepted.phonicsData?["collection"].boolean == true)
                var root=patch.root
                if activityWithoutXP {
                    var activity:[String:Any]=["lastActiveAt":WebProgressContract.iso(change.date)]
                    if accepted.source == .phonics,let progress=patch.root["progress"] as? [String:Any],let value=progress["phonicsDailyActivity"]{activity["phonicsDailyActivity"]=value}
                    root=["progress":activity,"updatedAt":WebProgressContract.iso(change.date)]
                }
                if change.tutorData != nil,change.source == .speak || change.source == .tutorState && change.tutorData?["kind"].string == "start" {
                    var progress=root["progress"] as? [String:Any] ?? [:];progress["currentTutorLesson"]=change.source == .speak ? NSNull():(change.contentID ?? "") as Any;root["progress"]=progress
                }
                root["local_npub"] = user.documentID
                root["iosRecentEventIDs"] = Self.recentIDs(fields,adding:change.id)
                if let goalID {
                    root["iosCompletedConversationGoalIDs"]=Array(((fields["iosCompletedConversationGoalIDs"] as? [String] ?? []).filter { $0 != goalID }+[goalID]).suffix(400))
                }
                if !userSnapshot.exists { root["createdAt"] = WebProgressContract.iso(change.date); root["dailyGoalXp"] = state.dailyGoal }
                transaction.setData(root,forDocument:user,merge:true)
                if !activityWithoutXP{transaction.setData(patch.month,forDocument:month,merge:true)}
                if let activeLesson,let saved=activeLessonSnapshot?.data(),saved["status"] as? String == "in_progress" {
                    transaction.setData(["earnedXp":max(0,WebProgressContract.integer(saved["earnedXp"]))+change.amount,"updatedAt":WebProgressContract.iso(change.date)],forDocument:activeLesson,merge:true)
                }
                if let quest, change.source == .questStart, savedKinds == nil {
                    transaction.setData(["iosPlate":["dayKey":change.dayKey,"kinds":base,"carry":change.questCarry ?? [],"yesterdayComplete":change.questYesterdayComplete ?? true,"createdAt":WebProgressContract.iso(change.date)]],forDocument:quest,merge:true)
                }
                if let journey, let journeyReceipt, !journeyCounted {
                    let count = max(0,WebProgressContract.integer(journeyFields["completedQuests"])) + 1
                    var unlocked = journeyFields["unlockedAt"] as? [String:Any] ?? [:]
                    for milestone in [1,5,15,30,45,60,90,120,150] where milestone <= count && unlocked[String(milestone)] == nil { unlocked[String(milestone)] = WebProgressContract.iso(change.date) }
                    transaction.setData(["version":1,"completedQuests":count,"unlockedAt":unlocked,"updatedAt":WebProgressContract.iso(change.date)],forDocument:journey,merge:true)
                    transaction.setData(["completedAt":WebProgressContract.iso(change.date),"session":count],forDocument:journeyReceipt)
                }
                if let content,change.source == .phonicsAttempt {
                    let next=PhonicsProgress.applying(change,to:PhonicsProgress.document(Self.normalized(contentSnapshot?.data() ?? [:])))
                    transaction.setData(next.foundation as? [String:Any] ?? [:],forDocument:content,merge:true)
                }
                if let content, change.source == .phonics {
                    transaction.setData(["letterId":change.contentID ?? "","targetLang":change.target,"cefrLevel":change.level,"correctCount":FieldValue.increment(Int64(1)),"updatedAt":WebProgressContract.iso(change.date)],forDocument:content,merge:true)
                }
                if let content, change.source != .phonics,change.source != .phonicsAttempt {
                    let existing = Self.normalized(contentSnapshot?.data() ?? [:])
                    var data: [String:Any] = ["targetLang":change.target,"cefrLevel":change.level,"updatedAt":WebProgressContract.iso(change.date)]
                    let completed: Bool, wasCompleted: Bool, mode: String
                    if change.source == .lessonStart {
                        data["lessonId"]=change.contentID
                        data["status"]=existing["status"] as? String == "completed" ? "completed" : "in_progress"
                        data["earnedXp"]=max(0,WebProgressContract.integer(existing["earnedXp"]))
                        data["startedAt"]=existing["startedAt"] ?? WebProgressContract.iso(change.date)
                        completed=false;wasCompleted=existing["status"] as? String == "completed";mode="skillTree"
                    } else if change.source == .review {
                        var review = WebProgressContract.review(existing)
                        if let patch=change.reviewPatch {review=patch}
                        else if (review.updatedAt ?? .distantPast) <= change.date, let rating=change.reviewRating {review=review.applying(rating,now:change.date)}
                        data.merge(WebProgressContract.reviewFields(review)) { _,new in new }; data["cardId"] = change.contentID
                        completed = review.completed; wasCompleted = existing["completed"] as? Bool == true; mode = "flashcards"
                    } else if change.tutorData != nil,[.tutorState,.tutorTurn,.speak].contains(change.source) {
                        let patch=TutorSourceProgress.patch(change,record:PhonicsProgress.document(existing))
                        data=patch.foundation as? [String:Any] ?? [:]
                        if change.source == .speak {data["tutorAgendaProgress"]=FieldValue.delete();data["conversationDraft"]=FieldValue.delete();data["lessonStartXp"]=FieldValue.delete()}
                        completed=change.source == .speak;wasCompleted=existing["status"] as? String == "completed";mode="tutor"
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
                        data["earnedXp"] = change.gameResult == nil ? change.amount : existing["earnedXp"] ?? change.amount
                        data["xpEarned"] = existing["xpEarned"] ?? change.amount
                        if let game=change.gameResult,existing["gameResult"] == nil { data["gameResult"]=game.foundation }
                        completed = true; wasCompleted = existing["status"] as? String == "completed"; mode = change.source == .speak ? "tutor" : "skillTree"
                    }
                    if !data.isEmpty {transaction.setData(data,forDocument:content,merge:true)}
                    if completed && !wasCompleted {
                        let levelKey = change.level.lowercased().replacingOccurrences(of:"-",with:"_")
                        let totals = ["skillTree","tutor"].contains(mode) ? ["Pre-A1":86,"A1":98,"A2":126,"B1":105,"B2":84,"C1":70,"C2":56] : ["Pre-A1":100,"A1":300,"A2":250,"B1":200,"B2":150,"C1":100,"C2":50]
                        transaction.setData(["schemaVersion":1,"targetLang":change.target,mode:["levels":[levelKey:["completed":FieldValue.increment(Int64(1)),"total":totals[change.level,default:0]]]],"updatedAt":FieldValue.serverTimestamp()],forDocument:summary,merge:true)
                    }
                }
                if let goalClaim,let goalID,!goalClaimed { transaction.setData(["source":"conversation-goal","completionId":goalID,"amount":accepted.amount-min(3,max(0,change.amount)),"syncedAt":FieldValue.serverTimestamp()],forDocument:goalClaim) }
                if let goalEvent,let goalID,!goalRecorded { transaction.setData(["source":"nosabos","metric":"conversation_goals","completionId":goalID,"version":1],forDocument:goalEvent) }
                if let proof=change.readingProof { var record=proof.foundation as? [String:Any] ?? [:];record["source"]="nosabos";record["createdAt"]=FieldValue.serverTimestamp();record["createdAtClient"]=Int(change.date.timeIntervalSince1970*1000);transaction.setData(record,forDocument:user.collection("readingTurns").document(receiptID)) }
                if let proof=change.storyProof { var record=proof.foundation as? [String:Any] ?? [:];record["source"]="nosabos";record["createdAt"]=FieldValue.serverTimestamp();record["createdAtClient"]=Int(change.date.timeIntervalSince1970*1000);transaction.setData(record,forDocument:user.collection("storyTurns").document(receiptID)) }
                transaction.setData(["eventID":change.id.uuidString,"source":change.source.rawValue,"targetLang":change.target,"amount":accepted.amount,"practicedAt":WebProgressContract.iso(change.date),"syncedAt":FieldValue.serverTimestamp()],forDocument:receipt)
                return true
            } catch { errorPointer?.pointee = error as NSError; return nil }
        }
    }
    private func applyImmersion(_ change: ImmersionChange, state: LearnerState, user: DocumentReference, database: Firestore) async throws {
        let operation=user.collection("iosPracticeReceipts").document("immersion-"+change.id.uuidString)
        let day=change.payload["dayKey"].string,key=DailyImmersion.receipt(target:change.target,day:day)
        let claimID=SHA256.hash(data:Data(key.utf8)).map { String(format:"%02x",$0) }.joined()
        let claim=user.collection("iosPracticeReceipts").document(claimID)
        let month=user.collection("xpHistory").document(String(day.prefix(7)))
        _=try await database.runTransaction { tx,error -> Any? in do {
            let already=try tx.getDocument(operation).exists
            let snapshot=try tx.getDocument(user),fields=Self.normalized(snapshot.data() ?? [:])
            if already { Self.acknowledge(change.id,user:user,fields:fields,transaction:tx);return false }
            let monthFields=Self.normalized(try tx.getDocument(month).data() ?? [:]),claimed=try tx.getDocument(claim).exists
            let profile=AchievementSyncService.jsonFields(fields),goal=GoalPractice.active(profile["learningIntelligence"][change.target]) ?? .null
            let result=DailyImmersion.applying(change,batch:profile["realWorldTasks"],history:profile["realWorldTaskHistoryByLanguage"],receipts:profile["xpAwardReceipts"],goal:goal,placementAt:profile["proficiencyPlacementAt"].string)
            let reward=claimed ? 0 : result.reward
            var proof=AchievementProgress.completionProof(profile:profile.setting("realWorldTasks",result.batch),summary:.object([:]),quest:.object([:]),language:change.target,day:day).events
            let base=change.payload["baseBatch"]
            if change.action == .batch,result.batch["rewarded"].boolean,base["rewarded"].boolean,result.batch["generatedAt"] == base["generatedAt"],result.batch["targetLang"].string == change.target,result.batch["dayKey"].string == day {
                proof += AchievementProgress.completionProof(profile:profile.setting("realWorldTasks",base),summary:.object([:]),quest:.object([:]),language:change.target,day:day).events
            }
            var seen:Set<String>=[];proof=proof.filter { seen.insert($0["metric"].string+"\u{1f}"+$0["id"].string).inserted }
            let events=try proof.map { event -> (DocumentReference,Bool,JSONValue) in
                let ref=user.collection("achievementProgress").document("nosabos").collection("events").document(try AchievementSyncService.documentID(metric:event["metric"].string,id:event["id"].string))
                return (ref,try tx.getDocument(ref).exists,event)
            }
            var root:[String:Any]=["local_npub":user.documentID,"iosRecentEventIDs":Self.recentIDs(fields,adding:change.id),"updatedAt":WebProgressContract.iso(change.date)]
            if fields["xp"] == nil && profile["progress"]["languageXp"].object.isEmpty && profile["progress"]["totalXp"] == .null {
                root["xp"]=0;root["progress"]=profile["progress"].setting("languageXp",.object([change.target:.number(0)])).setting("totalXp",.number(0)).foundation
            }
            if !snapshot.exists { root["createdAt"]=WebProgressContract.iso(change.date);root["dailyGoalXp"]=state.dailyGoal }
            if result.batch != profile["realWorldTasks"] { root["realWorldTasks"]=result.batch.foundation }
            if result.history != profile["realWorldTaskHistoryByLanguage"] { root["realWorldTaskHistoryByLanguage"]=result.history.foundation }
            if change.action == .opened && result.batch["iosOpenedAt"].string == WebProgressContract.iso(change.date) { root["realWorldTasksLastOpenedAt"]=WebProgressContract.iso(change.date) }
            if result.receipts != profile["xpAwardReceipts"] { root["xpAwardReceipts"]=result.receipts.foundation }
            if reward > 0 {
                let practice=PracticeChange(date:change.date,dayKey:day,target:change.target,level:change.payload["cefrLevel"].string,amount:reward,source:.immersion)
                let patch=WebProgressContract.rootPatch(fields:fields,month:monthFields,change:practice)
                root.merge(patch.root) { _,new in new };tx.setData(patch.month,forDocument:month,merge:true)
            }
            tx.setData(root,forDocument:user,merge:true)
            if result.batch["rewarded"].boolean,result.batch["targetLang"].string == change.target,result.batch["dayKey"].string == day,!claimed {
                tx.setData(["source":"immersion","targetLang":change.target,"dayKey":day,"amount":reward,"syncedAt":FieldValue.serverTimestamp()],forDocument:claim)
            }
            for (ref,exists,event) in events where !exists { tx.setData(["source":"nosabos","metric":event["metric"].string,"completionId":event["id"].string,"version":1],forDocument:ref) }
            tx.setData(["eventID":change.id.uuidString,"source":"immersion-"+change.action.rawValue,"targetLang":change.target,"amount":reward,"syncedAt":FieldValue.serverTimestamp()],forDocument:operation)
            return true
        } catch let failure { error?.pointee=failure as NSError;return nil } }
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
    nonisolated static func normalized(_ fields: [String:Any]) -> [String:Any] {
        func value(_ input: Any) -> Any {
            if let timestamp = input as? Timestamp { return timestamp.dateValue() }
            if let map = input as? [String:Any] { return map.mapValues(value) }
            if let array = input as? [Any] { return array.map(value) }
            return input
        }
        return fields.mapValues(value)
    }
}
