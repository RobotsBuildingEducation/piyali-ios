import XCTest
import FirebaseCore
import FirebaseAppCheck
import FirebaseFirestore
import NostrSDK
@testable import Piyali

// Used only by the explicitly opted-in, named emulator app. No production configuration uses this provider.
private final class EmulatorAppCheckProvider: NSObject, AppCheckProvider {
    func getToken(completion: @escaping (AppCheckToken?, Error?) -> Void) {
        completion(AppCheckToken(token:"local-emulator-token",expirationDate:Date().addingTimeInterval(3600)),nil)
    }
}
private final class EmulatorAppCheckFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? { EmulatorAppCheckProvider() }
}
@MainActor final class FirestoreContractTests: XCTestCase {
    private func context() throws -> (FirebaseService,Firestore,String) {
        guard ProcessInfo.processInfo.environment["PIYALI_FIRESTORE_EMULATOR_TESTS"] == "1" else { throw XCTSkip("Run with the local Firestore emulator and TEST_RUNNER_PIYALI_FIRESTORE_EMULATOR_TESTS=1.") }
        let name = "PiyaliContractEmulator"
        if FirebaseApp.app(name:name) == nil {
            let options = FirebaseOptions(googleAppID:"1:123456789012:ios:0123456789abcdef012345",gcmSenderID:"123456789012")
            options.apiKey = "emulator-only-not-a-production-key"; options.projectID = "demo-piyali-ios"
            AppCheck.setAppCheckProviderFactory(EmulatorAppCheckFactory())
            FirebaseApp.configure(name:name,options:options)
            let database = Firestore.firestore(app:FirebaseApp.app(name:name)!)
            // Set the local host before disabling SSL: Firestore rejects SSL=false on its default production host.
            database.useEmulator(withHost:"127.0.0.1",port:8180)
            let settings = database.settings; settings.cacheSettings = MemoryCacheSettings(); settings.isSSLEnabled = false; database.settings = settings
        }
        let database = Firestore.firestore(app:FirebaseApp.app(name:name)!)
        return (FirebaseService(database:database),database,try XCTUnwrap(Keypair()?.publicKey.npub))
    }
    private func requireState(_ state: LearnerState?) throws -> LearnerState { try XCTUnwrap(state) }
    private func seed(_ db: Firestore, _ npub: String) async throws {
        let today = CalendarDay.key(Date())
        try await db.collection("users").document(npub).setData([
            "local_npub":npub,"displayName":"Web learner","language":"es","dailyGoalXp":50,
            "onboarding":["completed":true],"xp":150,"dailyXp":5,"dailyXpRecent":[today:5],
            "dailyStartedAt":WebProgressContract.iso(Date()),"dailyResetAt":WebProgressContract.iso(Date().addingTimeInterval(3600)),
            "progress":["targetLang":"fr","supportLang":"es","cefrLevel":"A1","languageXp":["fr":100,"es":50],"totalXp":150],
            "patreonVerified":true,"unrelatedWebSetting":"preserve"
        ])
    }
    func testMemoryCapturesMergeWithWebNotesAndRetryOnce() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        let bucket = db.collection("users").document(npub).collection("companion").document("fr")
        let day = CalendarDay.key(Date())
        try await bucket.setData(["lang":"fr","webBucketField":"preserve","notes":[[
            "id":"mem-web","createdDayKey":day,"createdAt":Date().timeIntervalSince1970*1000,
            "targetLang":"fr","supportLang":"es","sourceMode":"grammar","concept":"Word order",
            "userAnswer":"before","expectedAnswer":"after","correction":"after","cefrLevel":"A1",
            "severity":1,"recommendedRepairMode":"lesson","status":"captured",
            "expiresAfterDayKey":CalendarDay.shift(day,by:1),"mistake":"Web diagnosis","tip":"Web tip","enriched":true,"webNoteField":"preserve"
        ]]])
        var state = try requireState(try await service.load(npub:npub))
        XCTAssertEqual(state.companionMemory?["fr"]?.first?.id,"mem-web")
        state.captureMemory(mode:"grammar",concept:"word order",answer:"new answer",expected:"after",feedback:"")
        _ = try await service.save(state,npub:npub); _ = try await service.save(state,npub:npub)
        let fields = try await bucket.getDocument(source:.server).data()!
        let notes = try XCTUnwrap(fields["notes"] as? [[String:Any]])
        XCTAssertEqual(notes.count,1); XCTAssertEqual(notes[0]["id"] as? String,"mem-web")
        XCTAssertEqual(WebProgressContract.integer(notes[0]["severity"]),2)
        XCTAssertEqual(notes[0]["tip"] as? String,"Web tip"); XCTAssertEqual(notes[0]["userAnswer"] as? String,"new answer")
        XCTAssertEqual(notes[0]["webNoteField"] as? String,"preserve"); XCTAssertEqual(fields["webBucketField"] as? String,"preserve")
    }
    func testTwoDevicesCaptureOneConceptWithoutLosingSeverity() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        var first = try requireState(try await service.load(npub:npub)), second = first
        first.captureMemory(mode:"flashcard",concept:"bonjour",answer:"wrong one",expected:"bonjour",feedback:"")
        second.captureMemory(mode:"flashcard",concept:"Bonjour",answer:"wrong two",expected:"bonjour",feedback:"")
        let a = first, b = second
        async let one = service.save(a,npub:npub)
        async let two = service.save(b,npub:npub)
        _ = try await (one,two)
        let snapshot = try await db.collection("users").document(npub).collection("companion").document("fr").getDocument(source:.server)
        let notes = try XCTUnwrap(snapshot.data()?["notes"] as? [[String:Any]])
        XCTAssertEqual(notes.count,1); XCTAssertEqual(WebProgressContract.integer(notes[0]["severity"]),2)
    }
    func testRepairReinforcementIsSharedAndDoesNotReviveOnRetry() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        var state = try requireState(try await service.load(npub:npub))
        state.captureMemory(mode:"grammar",concept:"agreement",answer:"wrong",expected:"correct",feedback:"Explanation")
        state = try requireState(try await service.save(state,npub:npub))
        let id = try XCTUnwrap(state.companionMemory?["fr"]?.first?.id)
        let oldSnapshot = state
        state.reinforceMemory(id:id)
        _ = try await service.save(state,npub:npub)
        _ = try await service.save(oldSnapshot,npub:npub)
        let restored = try requireState(try await service.load(npub:npub))
        XCTAssertEqual(restored.companionMemory?["fr"]?.first?.text("status"),"reinforced")
        XCTAssertTrue(restored.activeMemories.isEmpty)
    }
    func testFirstUploadCreatesSharedProfileAndFlushesOfflineWork() async throws {
        let (service,db,npub) = try context()
        var state = LearnerState(); state.name = "New learner"; state.onboardingComplete = true
        state.preferencesModifiedAt = Date(); state.award(12)
        let restored = try requireState(try await service.save(state,npub:npub))
        XCTAssertEqual(restored.name,"New learner"); XCTAssertEqual(restored.xp,12)
        XCTAssertEqual(restored.pendingChanges?.count,0); XCTAssertTrue(restored.onboardingComplete)
        let fields = try await db.collection("users").document(npub).getDocument(source:.server).data()!
        XCTAssertEqual(fields["local_npub"] as? String,npub)
        XCTAssertEqual((fields["progress"] as? [String:Any])?["targetLang"] as? String,"es")
        XCTAssertEqual(WebProgressContract.integer(fields["iosStateVersion"]),2)
    }
    func testOlderPreferenceRequestCannotReplaceNewerEdit() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        var older = try requireState(try await service.load(npub:npub))
        older.name = "Older edit"; older.preferencesModifiedAt = Date().addingTimeInterval(-1)
        var newer = older; newer.name = "Newer edit"; newer.target = "de"; newer.preferencesModifiedAt = Date()
        _ = try await service.save(newer,npub:npub)
        let restored = try requireState(try await service.save(older,npub:npub))
        XCTAssertEqual(restored.name,"Newer edit"); XCTAssertEqual(restored.target,"de")
        let fields = try await db.collection("users").document(npub).getDocument(source:.server).data()!
        XCTAssertEqual(WebProgressContract.integer(fields["xp"]),150)
        XCTAssertEqual((fields["progress"] as? [String:Any])?["languageXp"] as? [String:Int],["fr":100,"es":50])
        XCTAssertEqual(fields["patreonVerified"] as? Bool,true)
    }
    func testNativeAwardsVisibleToWebAndRetriesDoNotRepeatXP() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        var state = try requireState(try await service.load(npub:npub))
        XCTAssertEqual(state.name,"Web learner"); XCTAssertEqual(state.target,"fr"); XCTAssertTrue(state.onboardingComplete)
        state.award(10)
        let acknowledged = try requireState(try await service.save(state,npub:npub))
        XCTAssertEqual(acknowledged.xp,110); XCTAssertEqual(acknowledged.pendingChanges?.count,0)
        XCTAssertTrue(acknowledged.acknowledgedEventIDs?.contains(state.pendingChanges![0].id) == true)
        _ = try await service.save(state,npub:npub)
        let fields = try await db.collection("users").document(npub).getDocument(source:.server).data()!
        XCTAssertEqual(WebProgressContract.integer(fields["xp"]),160)
        XCTAssertEqual((fields["iosRecentEventIDs"] as? [String])?.count,1)
        XCTAssertEqual((fields["progress"] as? [String:Any])?["languageXp"] as? [String:Int],["fr":110,"es":50])
        XCTAssertEqual(fields["patreonVerified"] as? Bool,true); XCTAssertEqual(fields["unrelatedWebSetting"] as? String,"preserve")
        let receipts = try await db.collection("users").document(npub).collection("iosPracticeReceipts").getDocuments(source:.server)
        XCTAssertEqual(receipts.count,1)
    }
    func testTwoDevicesCompletingSameLessonOnlyEarnOneCompletionReward() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        let summary = db.collection("users").document(npub).collection("courseProgress").document("fr")
        try await summary.setData(["migration":["complete":true],"skillTree":["levels":["a1":["completed":2,"total":98]]]])
        let json = #"{"id":"lesson-a1-2-1","title":{"en":"Numbers"},"description":{"en":"Count"},"xpReward":30,"modes":["grammar"],"agenda":{},"content":{}}"#
        let lesson = try JSONDecoder().decode(Lesson.self,from:Data(json.utf8))
        var first = try requireState(try await service.load(npub:npub)), second = first
        XCTAssertTrue(first.complete(lesson)); XCTAssertTrue(second.complete(lesson))
        let firstSnapshot = first, secondSnapshot = second
        async let firstUpload = service.save(firstSnapshot,npub:npub)
        async let secondUpload = service.save(secondSnapshot,npub:npub)
        _ = try await (firstUpload,secondUpload)
        let user = db.collection("users").document(npub)
        let xpSnapshot = try await user.getDocument(source:.server)
        XCTAssertEqual(WebProgressContract.integer(xpSnapshot.data()?["xp"]),180)
        let record = try await user.collection("languageLessons").document("fr_lesson-a1-2-1").getDocument(source:.server).data()!
        XCTAssertEqual(record["status"] as? String,"completed"); XCTAssertEqual(record["cefrLevel"] as? String,"A1")
        let fields = try await summary.getDocument(source:.server).data()!
        XCTAssertEqual(((fields["skillTree"] as? [String:Any])?["levels"] as? [String:[String:Int]])?["a1"]?["completed"],3)
        XCTAssertEqual((fields["migration"] as? [String:Bool])?["complete"],true)
    }
    func testScheduledReviewsGraduateAndWebSummaryIncrementsOnce() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        var state = try requireState(try await service.load(npub:npub))
        let now = Date(); var lastSent = state
        for delay in [0.0,70.0,700.0] {
            state.review(cardID:"a1-greet-1",rating:.good,now:now.addingTimeInterval(delay)); lastSent = state
            state = try requireState(try await service.save(state,npub:npub))
        }
        _ = try await service.save(lastSent,npub:npub)
        let user = db.collection("users").document(npub)
        let record = try await user.collection("languageFlashcards").document("fr_a1-greet-1").getDocument(source:.server).data()!
        XCTAssertEqual(record["completed"] as? Bool,true); XCTAssertEqual(record["schedulerState"] as? String,"review")
        XCTAssertEqual(WebProgressContract.integer(record["reviewCount"]),3)
        XCTAssertEqual(WebProgressContract.number(record["intervalDays"]),1)
        let summary = try await user.collection("courseProgress").document("fr").getDocument(source:.server).data()!
        XCTAssertEqual(((summary["flashcards"] as? [String:Any])?["levels"] as? [String:[String:Int]])?["a1"]?["completed"],1)
        let xpSnapshot = try await user.getDocument(source:.server)
        XCTAssertEqual(WebProgressContract.integer(xpSnapshot.data()?["xp"]),165)
        let restored = try requireState(try await service.load(npub:npub))
        XCTAssertTrue(restored.flashcardMastery.contains("fr:a1-greet-1")); XCTAssertEqual(restored.cardReviews?["fr:a1-greet-1"]?.reviewCount,3)
    }
    func testOldOfflineAwardDoesNotCountAsTodaysXP() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        var state = try requireState(try await service.load(npub:npub))
        let yesterday = Date().addingTimeInterval(-86400), day = CalendarDay.key(yesterday)
        state.award(20,now:yesterday)
        _ = try await service.save(state,npub:npub)
        let user = db.collection("users").document(npub), fields = try await user.getDocument(source:.server).data()!
        XCTAssertEqual(WebProgressContract.integer(fields["dailyXp"]),5)
        let month = try await user.collection("xpHistory").document(String(day.prefix(7))).getDocument(source:.server).data()!
        XCTAssertEqual((month["days"] as? [String:Int])?[day],20)
    }
    func testWebCompletionsAndReviewsRestoreOnIPhone() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        let user = db.collection("users").document(npub)
        try await user.collection("languageLessons").document("fr_lesson-a1-2-1").setData(["targetLang":"fr","cefrLevel":"A1","lessonId":"lesson-a1-2-1","status":"completed"])
        try await user.collection("languageFlashcards").document("fr_a1-greet-1").setData(["targetLang":"fr","cefrLevel":"A1","cardId":"a1-greet-1","completed":true,"schedulerState":"review","intervalDays":4,"reviewCount":5,"nextReviewAt":"2027-01-01T12:00:00.000Z"])
        let restored = try requireState(try await service.load(npub:npub))
        XCTAssertTrue(restored.completed.contains("fr:lesson-a1-2-1")); XCTAssertTrue(restored.flashcardMastery.contains("fr:a1-greet-1"))
        XCTAssertEqual(restored.cardReviews?["fr:a1-greet-1"]?.reviewCount,5)
        XCTAssertFalse(restored.cardReviews?["fr:a1-greet-1"]?.isDue() ?? true)
    }
}
