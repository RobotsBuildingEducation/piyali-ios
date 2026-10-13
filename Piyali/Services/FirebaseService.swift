import Foundation
import CryptoKit
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
    func load(npub: String, local: LearnerState? = nil) async throws -> LearnerState? {
        guard let database else { return nil }
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
        let cards = try await user.collection("languageFlashcards").whereField("targetLang",isEqualTo:state.target).whereField("cefrLevel",isEqualTo:state.level).getDocuments(source:.server)
        for document in cards.documents {
            let data = Self.normalized(document.data())
            guard let id = data["cardId"] as? String else { continue }
            let key = state.completionKey(id), review = WebProgressContract.review(data)
            if state.cardReviews == nil { state.cardReviews = [:] }
            if (review.updatedAt ?? .distantPast) >= (state.cardReviews?[key]?.updatedAt ?? .distantPast) { state.cardReviews?[key] = review }
            if review.completed { state.flashcardMastery.insert(key) }
        }
        let memory = try await user.collection("companion").document(state.target).getDocument(source:.server)
        if state.companionMemory == nil { state.companionMemory = [:] }
        state.companionMemory?[state.target] = try Self.memoryNotes(memory.data()?["notes"])
        return state
    }
    /// Awards are flushed before the snapshot. A failed/partial flush leaves the local outbox intact; retry receipts prevent repeated credit.
    func save(_ state: LearnerState, npub: String) async throws -> LearnerState? {
        guard let database else { return nil }
        let user = database.collection("users").document(npub)
        for change in (state.pendingChanges ?? []).sorted(by:{ $0.date < $1.date }) {
            try await apply(change, state:state, user:user, database:database)
        }
        for change in (state.pendingMemoryChanges ?? []).sorted(by:{ $0.date < $1.date }) {
            try await applyMemory(change,user:user,database:database)
        }
        var snapshotState = state; snapshotState.pendingChanges = []; snapshotState.pendingMemoryChanges = []; snapshotState.preferencesModifiedAt = nil
        let uploaded = snapshotState
        // Keep other-device completion evidence. Preference writes occur only after an explicit local change.
        _ = try await database.runTransaction { transaction, errorPointer -> Any? in
            do {
                let snapshot = try transaction.getDocument(user)
                let fields = snapshot.data() ?? [:]
                var merged = uploaded
                if let text = fields["iosStateJSON"] as? String, let remote = try? JSONDecoder().decode(LearnerState.self,from:Data(text.utf8)) {
                    merged.completed.formUnion(remote.completed); merged.flashcardMastery.formUnion(remote.flashcardMastery)
                    merged.practicedModes.formUnion(remote.practicedModes)
                }
                merged = WebProgressContract.imported(Self.normalized(fields),native:merged)
                // Companion memory has its own shared web document, not a second snapshot authority.
                merged.companionMemory = nil; merged.pendingMemoryChanges = []; merged.acknowledgedEventIDs = nil
                var patch: [String:Any] = ["local_npub":npub,"iosStateJSON":String(decoding:try JSONEncoder().encode(merged),as:UTF8.self),"iosStateVersion":2,"iosUpdatedAt":FieldValue.serverTimestamp()]
                if state.preferencesModifiedAt.map({ $0 > (WebProgressContract.date(Self.normalized(fields)["iosPreferencesModifiedAt"]) ?? .distantPast) }) == true || !snapshot.exists {
                    patch["iosPreferencesModifiedAt"] = WebProgressContract.iso(state.preferencesModifiedAt ?? Date())
                    patch["displayName"] = state.name; patch["language"] = state.support
                    patch["dailyGoalXp"] = state.dailyGoal; patch["dailyGoalPetName"] = state.companionName; patch["dailyGoalPetType"] = state.effectiveCompanionType
                    patch["onboarding"] = ["completed":state.onboardingComplete]
                    patch["progress"] = ["targetLang":state.target,"supportLang":state.support,"cefrLevel":state.level]
                }
                transaction.setData(patch,forDocument:user,merge:true)
                return true
            } catch { errorPointer?.pointee = error as NSError; return nil }
        }
        return try await load(npub:npub,local:uploaded)
    }
    private func apply(_ change: PracticeChange, state: LearnerState, user: DocumentReference, database: Firestore) async throws {
        let stable = [.lesson,.goal,.repair].contains(change.source) ? "\(change.source.rawValue):\(change.target):\(change.contentID ?? change.id.uuidString)" : change.id.uuidString
        let receiptID = SHA256.hash(data:Data(stable.utf8)).map { String(format:"%02x",$0) }.joined()
        let receipt = user.collection("iosPracticeReceipts").document(receiptID)
        let month = user.collection("xpHistory").document(String(change.dayKey.prefix(7)))
        let collection = change.source == .review ? "languageFlashcards" : change.source == .lesson ? "languageLessons" : nil
        let content = collection.flatMap { collection in change.contentID.map { user.collection(collection).document("\(change.target)_\($0)") } }
        let summary = user.collection("courseProgress").document(change.target)
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
                if !userSnapshot.exists { fields["dailyGoalXp"] = state.dailyGoal; fields["onboarding"] = ["completed":state.onboardingComplete] }
                let patch = WebProgressContract.rootPatch(fields:fields,month:Self.normalized(monthSnapshot.data() ?? [:]),change:change)
                var root = patch.root; root["local_npub"] = user.documentID
                root["iosRecentEventIDs"] = Self.recentIDs(fields,adding:change.id)
                if !userSnapshot.exists { root["createdAt"] = WebProgressContract.iso(change.date); root["dailyGoalXp"] = state.dailyGoal }
                transaction.setData(root,forDocument:user,merge:true)
                transaction.setData(patch.month,forDocument:month,merge:true)
                if let content {
                    let existing = Self.normalized(contentSnapshot?.data() ?? [:])
                    var data: [String:Any] = ["targetLang":change.target,"cefrLevel":change.level,"updatedAt":WebProgressContract.iso(change.date)]
                    let completed: Bool, wasCompleted: Bool, mode: String
                    if change.source == .review {
                        var review = WebProgressContract.review(existing)
                        if (review.updatedAt ?? .distantPast) <= change.date, let rating = change.reviewRating { review = review.applying(rating,now:change.date) }
                        data.merge(WebProgressContract.reviewFields(review)) { _,new in new }; data["cardId"] = change.contentID
                        completed = review.completed; wasCompleted = existing["completed"] as? Bool == true; mode = "flashcards"
                    } else {
                        data["lessonId"] = change.contentID; data["status"] = "completed"
                        data["completedAt"] = existing["completedAt"] ?? WebProgressContract.iso(change.date)
                        data["earnedXp"] = max(change.amount,WebProgressContract.integer(existing["earnedXp"]))
                        data["xpEarned"] = change.amount
                        completed = true; wasCompleted = existing["status"] as? String == "completed"; mode = "skillTree"
                    }
                    transaction.setData(data,forDocument:content,merge:true)
                    if completed && !wasCompleted {
                        let levelKey = change.level.lowercased().replacingOccurrences(of:"-",with:"_")
                        let totals = mode == "skillTree" ? ["Pre-A1":86,"A1":98,"A2":126,"B1":105,"B2":84,"C1":70,"C2":56] : ["Pre-A1":100,"A1":300,"A2":250,"B1":200,"B2":150,"C1":100,"C2":50]
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
