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
            "progress":["targetLang":"fr","supportLang":"es","cefrLevel":"A1","activeTutorLevels":["fr":"A1"],"languageXp":["fr":100,"es":50],"totalXp":150],
            "patreonVerified":true,"unrelatedWebSetting":"preserve"
        ])
    }
    func testCompanionDecayReconcilesOnceWithoutResettingActiveXPWindow() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        let now = Date(), today = CalendarDay.key(now), reset = WebProgressContract.iso(now.addingTimeInterval(3600))
        let user = db.collection("users").document(npub)
        try await user.setData(["dailyGoalPetHealth":100,"dailyGoalPetLastAccountedDay":CalendarDay.shift(today,by:-4),"dailyResetAt":reset,"dailyXp":20],merge:true)
        let a = try requireState(try await service.load(npub:npub)), b = a
        XCTAssertEqual(a.companionHealth,70)
        async let first = service.save(a,npub:npub)
        async let second = service.save(b,npub:npub)
        _ = try await (first,second)
        let fields = try await user.getDocument(source:.server).data()!
        XCTAssertEqual(WebProgressContract.integer(fields["dailyGoalPetHealth"]),70)
        XCTAssertEqual(WebProgressContract.integer(fields["dailyXp"]),20); XCTAssertEqual(fields["dailyResetAt"] as? String,reset)
        XCTAssertEqual(fields["dailyGoalPetLastAccountedDay"] as? String,CalendarDay.shift(today,by:-1))
        XCTAssertEqual(fields["patreonVerified"] as? Bool,true); XCTAssertEqual(fields["unrelatedWebSetting"] as? String,"preserve")
        _ = try await service.save(a,npub:npub)
        let retry = try await service.load(npub:npub)
        XCTAssertEqual(retry?.companionHealth,70)
    }
    func testConcurrentGoalHitsRecoverCompanionOnlyOnceAndRetainHealthyEvidence() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        let now = Date(), today = CalendarDay.key(now), user = db.collection("users").document(npub)
        try await user.setData(["dailyGoalPetHealth":60,"dailyGoalPetLastAccountedDay":CalendarDay.shift(today,by:-1),"dailyResetAt":WebProgressContract.iso(now.addingTimeInterval(3600)),"dailyXp":20,"dailyHasCelebrated":false,"dailyGoalPetHealthyDates":["2026-09-01"]],merge:true)
        var a = try requireState(try await service.load(npub:npub)), b = a
        a.award(30,now:now); b.award(30,now:now)
        async let first = service.save(a,npub:npub)
        async let second = service.save(b,npub:npub)
        _ = try await (first,second)
        let fields = try await user.getDocument(source:.server).data()!
        XCTAssertEqual(WebProgressContract.integer(fields["dailyGoalPetHealth"]),75)
        XCTAssertEqual(WebProgressContract.integer(fields["dailyXp"]),80)
        XCTAssertEqual(fields["dailyGoalPetReachedDates"] as? [String],[today])
        XCTAssertEqual(fields["dailyGoalPetHealthyDates"] as? [String],["2026-09-01"])
        _ = try await service.save(a,npub:npub)
        let retry = try await service.load(npub:npub)
        XCTAssertEqual(retry?.companionHealth,75)
    }
    func testDailyQuestPlanIsStableAndBonusAndJourneyAreClaimedOnceAcrossDevices() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        let now = Date(), day = CalendarDay.key(now), user = db.collection("users").document(npub)
        try await user.setData(["progress":["dailyQuestFirstSeen":true,"dailyQuestFirstDayKey":day,"flashcardDailyActivity":["fr":[day:5]],"lessonDailyActivity":["fr":[day:1]],"speakDailyActivity":["fr":[day:1]]]],merge:true)
        var first = try requireState(try await service.load(npub:npub)); first.preparePlate(user:npub,available:DailyPlate.introductory)
        first = try requireState(try await service.save(first,npub:npub))
        XCTAssertEqual(first.questPlans?["fr"]?.kinds,DailyPlate.introductory)
        var second = try requireState(try await service.load(npub:npub))
        XCTAssertTrue(first.claimPlate(user:npub)); XCTAssertTrue(second.claimPlate(user:npub))
        async let savedOne = service.save(first,npub:npub)
        async let savedTwo = service.save(second,npub:npub)
        _ = try await (savedOne,savedTwo)
        let final = try requireState(try await service.load(npub:npub))
        XCTAssertEqual(final.xp,125); XCTAssertEqual(final.journeyQuestCounts?["fr"],1)
        XCTAssertFalse(final.plateProgress["plateBonusDailyActivity"]["fr"][day].string.isEmpty)
        _ = try await service.save(first,npub:npub)
        let journey = try await user.collection("voiceJourney").document("fr").getDocument().data() ?? [:]
        XCTAssertEqual(journey["completedQuests"] as? Int,1)
        XCTAssertNotNil((journey["unlockedAt"] as? [String:Any])?["1"])
    }
    func testStaleQuestScreenCannotAwardBonusOrJourney() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        let day = CalendarDay.key(Date()), user = db.collection("users").document(npub)
        try await user.setData(["progress":["dailyQuestFirstSeen":true,"dailyQuestFirstDayKey":day]],merge:true)
        var state = try requireState(try await service.load(npub:npub))
        // The UI snapshot is stale; the committed Firestore activity is still empty.
        state.questProgress = .object(["dailyQuestFirstSeen":.bool(true),"dailyQuestFirstDayKey":.string(day),"flashcardDailyActivity":.object(["fr":.object([day:.number(5)])]),"lessonDailyActivity":.object(["fr":.object([day:.number(1)])]),"speakDailyActivity":.object(["fr":.object([day:.number(1)])])])
        XCTAssertTrue(state.claimPlate(user:npub))
        let cloud = try requireState(try await service.save(state,npub:npub))
        XCTAssertEqual(cloud.xp,100); XCTAssertEqual(cloud.journeyQuestCounts?["fr"],0)
        XCTAssertTrue(cloud.plateProgress["plateBonusDailyActivity"]["fr"][day].string.isEmpty)
    }
    func testTutorAgendaMergesAndLessonCompletionDoesNotFillSkillTree() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        var first = try requireState(try await service.load(npub:npub)), second = first
        let day = CalendarDay.key(Date()), lesson = "lesson-a1-1-1"
        var a = PracticeChange(dayKey:day,target:"fr",level:"A1",amount:5,source:.tutorTurn,contentID:lesson); a.tutorAgendaItemID = "one"
        var b = PracticeChange(dayKey:day,target:"fr",level:"A1",amount:7,source:.tutorTurn,contentID:lesson); b.tutorAgendaItemID = "two"
        first.enqueue(a); second.enqueue(b)
        async let savedOne = service.save(first,npub:npub)
        async let savedTwo = service.save(second,npub:npub)
        _ = try await (savedOne,savedTwo)
        _ = try await service.save(first,npub:npub)
        var cloud = try requireState(try await service.load(npub:npub))
        XCTAssertEqual(cloud.tutorProgress(lesson).earnedXP,12); XCTAssertEqual(cloud.tutorProgress(lesson).items,["one","two"])
        XCTAssertEqual(cloud.xp,112)
        cloud.award(60,source:.speak,contentID:lesson)
        let completed = try requireState(try await service.save(cloud,npub:npub))
        _ = try await service.save(cloud,npub:npub)
        XCTAssertTrue(completed.completed.contains(completed.tutorKey(lesson)))
        XCTAssertFalse(completed.completed.contains(completed.completionKey(lesson)))
        XCTAssertEqual(completed.plateProgress["speakDailyActivity"]["fr"][day].number,1)
        XCTAssertEqual(completed.plateProgress["lessonDailyActivity"]["fr"][day].number,0)
        XCTAssertEqual(completed.courseCompletion?["fr"]?["tutor"]?["A1"],1)
    }
    func testPlacementSeedsBeforeOfflinePracticeAndPreservesEarnedScoreOnRetake() async throws {
        let (service,db,npub) = try context()
        var state = LearnerState(); state.onboardingComplete = true; state.preferencesModifiedAt = Date()
        state.place(PlacementAssessment.estimate(["read_write"])!)
        state.assess(correct:true,independent:true)
        let expected = state.rating
        let cloud = try requireState(try await service.save(state,npub:npub))
        XCTAssertEqual(cloud.placements?["es"]?.level,"B1")
        XCTAssertEqual(cloud.rating,expected,accuracy:0.0001)
        XCTAssertEqual(cloud.gradedByLanguage?["es"],1)
        XCTAssertTrue((cloud.pendingPlacements ?? [:]).isEmpty)
        _ = try await service.save(state,npub:npub)
        var next = cloud; next.place(PlacementAssessment.estimate(["nuance_precision"])!)
        let retaken = try requireState(try await service.save(next,npub:npub))
        XCTAssertEqual(retaken.placements?["es"]?.level,"C1")
        XCTAssertEqual(retaken.rating,expected,accuracy:0.0001)
        let fields = try await db.collection("users").document(npub).getDocument().data() ?? [:]
        XCTAssertEqual((fields["proficiencyPlacements"] as? [String:String])?["es"],"C1")
        XCTAssertEqual((fields["progress"] as? [String:Any])?["languageXp"] as? [String:Int], ["es":0])
    }
    func testPlacementAndCourseSummaryRestoreWithoutGrantingCompletion() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        let user = db.collection("users").document(npub)
        try await user.setData(["proficiencyPlacements":["fr":"B1"],"progress":["activeLessonLevels":["fr":"A2"],"activeFlashcardLevels":["fr":"B1"]]],merge:true)
        try await user.collection("courseProgress").document("fr").setData(["skillTree":["levels":["pre_a1":["completed":86]]]])
        let state = try requireState(try await service.load(npub:npub))
        XCTAssertEqual(state.level,"A2"); XCTAssertEqual(state.flashcardLevel,"B1")
        XCTAssertEqual(state.placements?["fr"]?.level,"B1"); XCTAssertNil(state.placements?["es"])
        XCTAssertEqual(state.courseCompletion?["fr"]?["skillTree"]?["Pre-A1"],86)
        XCTAssertTrue(state.completed.isEmpty); XCTAssertTrue(state.flashcardMastery.isEmpty)
    }
    func testFirstGoalUploadInitializesCanonicalProfile() async throws {
        let (service,db,npub) = try context()
        var state = LearnerState(); state.name = "First goal learner"; state.target = "fr"; state.support = "es"; state.onboardingComplete = true
        state.editGoal("Order a meal")
        XCTAssertNil(state.preferencesModifiedAt)
        _ = try await service.save(state,npub:npub)
        let fields = try await db.collection("users").document(npub).getDocument().data() ?? [:]
        XCTAssertEqual(fields["displayName"] as? String,"First goal learner")
        XCTAssertEqual((fields["progress"] as? [String:Any])?["targetLang"] as? String,"fr")
        XCTAssertEqual((fields["onboarding"] as? [String:Any])?["completed"] as? Bool,true)
    }
    func testNewGoalDayReplacesWholeProgressAndBlueprintMaps() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        var state = try requireState(try await service.load(npub:npub)); state.editGoal("Order a meal")
        let day = CalendarDay.key(Date())
        let first = GoalPractice.blueprint(raw:.object([:]),goal:state.goalBucket["activeGoal"],target:"fr",day:day,level:state.level,rating:state.rating,progress:.object([:]))
        state.applyGoal(GoalChange(action:.blueprint,target:"fr",payload:first))
        state.applyGoal(GoalChange(action:.attempt,target:"fr",payload:first.setting("mode",.string("tutor")).setting("success",.bool(true)).setting("observation",.string("Ordered soup politely"))))
        state = try requireState(try await service.save(state,npub:npub))
        let next = first.setting("dayKey",.string(CalendarDay.shift(day,by:1))).setting("modes",.array([.string("phonics"),.string("flashcards")])).setting("modeTargets",.object(["phonics":.number(2),"flashcards":.number(3)]))
        state.applyGoal(GoalChange(action:.blueprint,target:"fr",payload:next))
        state = try requireState(try await service.save(state,npub:npub))
        let daily = state.goalBucket["dailyGoal"]
        XCTAssertEqual(Set(daily["modeProgress"].object.keys),["phonics","flashcards"])
        XCTAssertEqual(Set(daily["blueprint"]["modeTargets"].object.keys),["phonics","flashcards"])
        XCTAssertTrue(daily["modeProgress"].object.values.allSatisfy { $0.number == 0 })
        XCTAssertFalse(daily["completed"].boolean)
    }
    func testDailyGoalBlueprintAndEvidenceConvergeAcrossDevices() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        var first = try requireState(try await service.load(npub:npub))
        first.editGoal("Order a meal"); first = try requireState(try await service.save(first,npub:npub))
        let goal = first.goalBucket["activeGoal"], day = CalendarDay.key(Date())
        let blueprint = GoalPractice.blueprint(raw:.object([:]),goal:goal,target:first.target,day:day,level:first.level,rating:first.rating,progress:first.goalBucket["goalProgress"])
        var second = first
        first.applyGoal(GoalChange(action:.blueprint,target:first.target,payload:blueprint))
        second.applyGoal(GoalChange(action:.blueprint,target:second.target,payload:blueprint.setting("objective",.string("Competing proposal"))))
        let firstRequest = first, secondRequest = second
        async let one = service.save(firstRequest,npub:npub)
        async let two = service.save(secondRequest,npub:npub)
        let initial = try await (one,two)
        first = try requireState(initial.0); second = try requireState(initial.1)
        XCTAssertEqual(first.dailyGoalTask?["blueprint"],second.dailyGoalTask?["blueprint"])
        let stored = try XCTUnwrap(first.dailyGoalTask?["blueprint"])
        let modes = GoalPractice.list(stored["modes"],max:4), firstMode = try XCTUnwrap(modes.first)
        let payload = stored.setting("mode",.string(firstMode)).setting("success",.bool(true)).setting("support",.string("prompted")).setting("observation",.string("Ordered a meal using a hint"))
        first.applyGoal(GoalChange(action:.attempt,target:first.target,payload:payload))
        second.applyGoal(GoalChange(action:.attempt,target:second.target,payload:payload))
        let firstAttempt = first, secondAttempt = second
        async let attemptOne = service.save(firstAttempt,npub:npub)
        async let attemptTwo = service.save(secondAttempt,npub:npub)
        _ = try await (attemptOne,attemptTwo)
        _ = try await service.save(firstAttempt,npub:npub)
        var restored = try requireState(try await service.load(npub:npub))
        XCTAssertEqual(restored.xp,100)
        XCTAssertTrue((restored.pendingGoalChanges ?? []).isEmpty)
        for mode in modes.dropFirst() {
            restored.applyGoal(GoalChange(action:.attempt,target:restored.target,payload:payload.setting("mode",.string(mode))))
            restored = try requireState(try await service.save(restored,npub:npub))
        }
        XCTAssertTrue(restored.dailyGoalTask?["completed"].boolean == true)
        let fields = try await db.collection("users").document(npub).getDocument().data() ?? [:]
        let activity = (fields["progress"] as? [String:Any])?["goalDailyActivity"] as? [String:[String:Int]]
        XCTAssertEqual(activity?["fr"]?[day],1)
        XCTAssertEqual(fields["patreonVerified"] as? Bool,true)
    }
    func testGoalPreparationDeckAndOutcomesUseSharedQuestArtifact() async throws {
        let (service,db,npub) = try context(); try await seed(db,npub)
        var state = try requireState(try await service.load(npub:npub)); state.editGoal("Order a meal")
        let day = CalendarDay.key(Date())
        let blueprint = GoalPractice.blueprint(raw:.object(["mode":.string("flashcards"),"targetLanguage":.array([.string("soupe")])]),goal:state.goalBucket["activeGoal"],target:state.target,day:day,level:state.level,rating:state.rating,progress:.object([:]))
        state.applyGoal(GoalChange(action:.blueprint,target:state.target,payload:blueprint))
        let card: JSONValue = .object(["id":.string("goal-card"),"concept":.object(["fr":.string("soupe"),"es":.string("sopa")])])
        state.applyGoal(GoalChange(action:.artifact,target:state.target,payload:blueprint.setting("mode",.string("flashcards")).setting("cards",.array([card]))))
        state = try requireState(try await service.save(state,npub:npub))
        let payload = blueprint.setting("mode",.string("flashcards")).setting("cardID",card["id"]).setting("success",.bool(true)).setting("support",.string("prompted")).setting("item",.string("soupe"))
        state.applyGoal(GoalChange(action:.outcome,target:state.target,payload:payload))
        let sent = state
        state = try requireState(try await service.save(state,npub:npub)); _ = try await service.save(sent,npub:npub)
        XCTAssertEqual(state.xp,102)
        let key = GoalPractice.artifactKey(target:"fr",day:day,mode:"flashcards",goalID:blueprint["goalId"].string)
        XCTAssertTrue(state.goalArtifacts?[key]?["outcomes"]["goal-card"]["success"].boolean == true)
        XCTAssertFalse(state.dailyGoalTask?["completed"].boolean == true)
        let artifact = try await db.collection("users").document(npub).collection("questDays").document("fr_" + day).getDocument().data() ?? [:]
        XCTAssertEqual((artifact["practice_flashcards_goal"] as? [String:Any])?["ownerKey"] as? String,key)
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
