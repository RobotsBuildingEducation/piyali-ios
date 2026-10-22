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
    func testQuotedAssessmentsUseTheSavedPriceAcrossConcurrentSyncAndRetriesWithoutXP() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        try await db.collection("users").document(npub).setData(["learningIntelligence":["fr":["elo":["rating":1100,"scaleVersion":4,"totalGraded":3]]]],merge:true)
        var state=try requireState(await service.load(npub:npub));state.pendingChanges=[]
        let recipes=try PracticeRecipes(),quote=try recipes.inspect("worth",parameters:.object(["user":state.recipeUser,"targetLang":.string("fr"),"questionLevel":.string("B2"),"assessment":.object(["difficultyScore":.number(10)])]))
        var first=state,second=state
        first.assess(correct:true,independent:true,questionLevel:"B2",worth:quote,concept:nil,mode:"vocabulary")
        second.assess(correct:false,independent:false,questionLevel:"B2",worth:quote,concept:"famille",mode:"grammar")
        async let a=service.save(first,npub:npub),b=service.save(second,npub:npub);_=try await(a,b)
        _=try await service.save(first,npub:npub);_=try await service.save(second,npub:npub)
        let fields=try await db.collection("users").document(npub).getDocument().data() ?? [:],bucket=((fields["learningIntelligence"] as? [String:[String:Any]])?["fr"] ?? [:]),elo=bucket["elo"] as? [String:Any] ?? [:]
        let expected=1100+quote["gainBySupport"]["independent"].number-quote["loss"].number
        XCTAssertEqual(WebProgressContract.number(elo["rating"]),expected,accuracy:1e-8);XCTAssertEqual(WebProgressContract.integer(elo["totalGraded"]),5);XCTAssertEqual(WebProgressContract.integer(fields["xp"]),150)
        let counts=(((bucket["performanceSummary"] as? [String:Any])?["byLevel"] as? [String:[String:Any]])?["Pre-A1"] ?? [:]);XCTAssertEqual(WebProgressContract.integer(counts["correct"]),1);XCTAssertEqual(WebProgressContract.integer(counts["missed"]),1)
        let restored=try requireState(await service.load(npub:npub));XCTAssertEqual(restored.rating,expected,accuracy:1e-8)
    }
    func testCurriculumOwnXPResumesAndConcurrentPracticeRetriesDoNotDuplicateWork() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        let lesson=Lesson(id:"lesson-a1-counter",title:.string("Greetings"),description:.string("Use greetings"),xpReward:50,modes:["grammar","vocabulary"],agenda:.object([:]),content:.object([:]),cefrLevel:"A1")
        var state=try requireState(await service.load(npub:npub));XCTAssertTrue(state.beginLessonWork(lesson))
        state=try requireState(await service.save(state,npub:npub));state.pendingChanges=[]
        let key=state.completionKey(lesson.id)
        XCTAssertEqual(state.lessonWork?[key]?.status,.inProgress);XCTAssertEqual(state.lessonWork?[key]?.earnedXP,0)
        var a=state,b=state;a.award(6,lesson:lesson);b.award(5,lesson:lesson)
        async let first=service.save(a,npub:npub),second=service.save(b,npub:npub);_=try await(first,second)
        _=try await service.save(a,npub:npub);_=try await service.save(b,npub:npub)
        state=try requireState(await service.load(npub:npub));state.pendingChanges=[]
        XCTAssertEqual(state.lessonWork?[key]?.earnedXP,11);XCTAssertEqual(state.totalXP,161)
        state.award(20,source:.tutorTurn);state=try requireState(await service.save(state,npub:npub));state.pendingChanges=[]
        XCTAssertEqual(state.lessonWork?[key]?.earnedXP,11)
        state.award(44,lesson:lesson);state=try requireState(await service.save(state,npub:npub));state.pendingChanges=[]
        XCTAssertTrue(try XCTUnwrap(state.lessonWork?[key]).ready(goal:50));XCTAssertTrue(state.complete(lesson))
        _=try await service.save(state,npub:npub);_=try await service.save(state,npub:npub)
        let restored=try requireState(await service.load(npub:npub))
        XCTAssertEqual(restored.lessonWork?[key]?.status,.completed);XCTAssertEqual(restored.lessonWork?[key]?.earnedXP,50);XCTAssertEqual(restored.totalXP,275)
        let document=try await db.collection("users").document(npub).collection("languageLessons").document("fr_"+lesson.id).getDocument().data()
        XCTAssertEqual(WebProgressContract.integer(document?["xpEarned"]),50)
    }
    func testWebCompletedLessonDoesNotClaimAnotherNativeCompletionBonus() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        let lesson=Lesson(id:"lesson-web-completed",title:.string("Greetings"),description:.string(""),xpReward:50,modes:["grammar"],agenda:.object([:]),content:.object([:]),cefrLevel:"A1")
        var offline=LearnerState();offline.target="fr";offline.level="A1";XCTAssertTrue(offline.complete(lesson))
        try await db.collection("users").document(npub).collection("languageLessons").document("fr_"+lesson.id).setData(["lessonId":lesson.id,"targetLang":"fr","cefrLevel":"A1","status":"completed","earnedXp":50,"xpEarned":50])
        _=try await service.save(offline,npub:npub)
        let restored=try requireState(await service.load(npub:npub))
        XCTAssertEqual(restored.totalXP,150);XCTAssertEqual(restored.lessonWork?["fr:"+lesson.id]?.status,.completed)
    }
    func testFinalQuizRestoresQuestionAndCountsAssessmentsAndLessonRewardOnce() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        let levels=try ContentLibrary.load([String:[LearningUnit]].self,name:"curriculum-fr"),lesson=try XCTUnwrap(levels["Pre-A1"]?.flatMap(\.lessons).first { $0.isFinalQuiz == true })
        var state=try requireState(await service.load(npub:npub)),run=FinalQuizRun(lesson:lesson,learner:try requireState(await service.load(npub:npub)))
        let startXP=state.totalXP
        for index in 0..<8 {
            XCTAssertTrue(run.prepare(Exercise(passage:"",question:"Choose a greeting",choices:["bonjour","au revoir"],answer:"bonjour",explanation:"Bonjour means hello."),mode:index%2==0 ? .grammar : .vocabulary));state.saveQuiz(run)
            if index == 4 {
                _=try await service.save(state,npub:npub);let restored=try requireState(await service.load(npub:npub)),draft=try XCTUnwrap(restored.quizRuns?[restored.quizKey(lesson.id)])
                XCTAssertEqual(draft.question?.id,run.question?.id);XCTAssertEqual(draft.answers.count,4);XCTAssertNil(draft.question?.grade);XCTAssertEqual(restored.totalXP,startXP);state=restored;run=draft
            }
            XCTAssertTrue(state.answerQuiz(lesson:lesson,runID:run.id,questionID:try XCTUnwrap(run.question?.id),answer:"bonjour",grade:Grade(correct:true,feedback:"Correct",correctedAnswer:"bonjour")))
            run=try XCTUnwrap(state.quizRuns?[state.quizKey(lesson.id)])
        }
        XCTAssertTrue(state.quizPassed(lesson));XCTAssertTrue(state.complete(lesson));let sent=state
        _=try await service.save(sent,npub:npub);_=try await service.save(sent,npub:npub)
        let restored=try requireState(await service.load(npub:npub))
        XCTAssertTrue(restored.quizPassed(lesson));XCTAssertTrue(restored.completed.contains(restored.completionKey(lesson.id)));XCTAssertEqual(restored.totalXP,startXP+lesson.xpReward);XCTAssertEqual(restored.gradedByLanguage?["fr"],8)
        let root=try await db.collection("users").document(npub).getDocument(source:.server);XCTAssertEqual(root.data()?["patreonVerified"] as? Bool,true)
        var newer=sent,edited=run;edited.updatedAt=Date().addingTimeInterval(2);newer.saveQuiz(edited)
        XCTAssertEqual(LearnerState.rebased(current:newer,sent:sent,acknowledged:restored).quizRuns?[newer.quizKey(lesson.id)]?.updatedAt,edited.updatedAt)
    }
    func testExplorationInventoryAndQuestDraftRestoreWithoutChangingXPOrEntitlements() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        let user=db.collection("users").document(npub)
        try await user.setData(["patreonVerified":true,"subscription":["active":true]],merge:true)
        let library=try ContentLibrary.load(ExplorationLibrary.self,name:"exploration"),template=try XCTUnwrap(library.templates.first { $0.baseLanguage == "es" && $0.level == "A2" && $0.theme == "home" && $0.quest["steps"].array.contains { $0["nodes"].array.contains { $0["responseMode"].string == "gather" } } })
        var run=try ExplorationRun(target:"es",support:"en",scenario:template)
        run.stepIndex=try XCTUnwrap(template.quest["steps"].array.firstIndex { $0["nodes"].array.contains { $0["responseMode"].string == "gather" } });run.nodeID=run.step["nodes"].array.first { $0["responseMode"].string == "gather" }?["id"].string
        let index=try XCTUnwrap(template.gatherPlacements.firstIndex { $0["name"] == run.node["gatherItem"]["name"] }),item=template.gatherPlacements[index]
        run.mapID=item["mapId"].string;run.position=try XCTUnwrap(run.area).world.start;XCTAssertTrue(run.approach(ExplorationTemplate.position(item)));XCTAssertTrue(run.pickUp(index))
        var state=try requireState(await service.load(npub:npub));let xp=state.totalXP;state.saveExploration(run)
        _=try await service.save(state,npub:npub)
        let restored=try requireState(await service.load(npub:npub)),draft=try XCTUnwrap(restored.explorationRuns?["es"])
        XCTAssertEqual(draft,run);XCTAssertEqual(restored.totalXP,xp);XCTAssertEqual(draft.inventory.first?.item["name"],item["name"])
        let raw=try await user.getDocument(source:.server);XCTAssertEqual(raw.data()?["patreonVerified"] as? Bool,true);XCTAssertEqual((raw.data()?["subscription"] as? [String:Any])?["active"] as? Bool,true)
        var newer=state;var edited=run;XCTAssertTrue(edited.drop(0));newer.saveExploration(edited)
        XCTAssertTrue(LearnerState.rebased(current:newer,sent:state,acknowledged:restored).explorationRuns?["es"]?.inventory.isEmpty ?? false)
    }
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
    private func immersionLearner() -> LearnerState {
        var state=LearnerState();state.target="fr";state.support="es";state.onboardingComplete=true
        state.place(Placement(level:"A1",score:18,source:"test",selectedIDs:[],updatedAt:Date()))
        return state
    }
    func testIntroCompletionClaimsOneRewardAndRestoresPrivateGuideProgress() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        let content=try ContentLibrary.load(IntroLibrary.self,name:"intro-fr"),lesson=try XCTUnwrap(content.units["Pre-A1"]?.lessons.first)
        func finished() -> LearnerState {
            var state=immersionLearner();state.level="Pre-A1"
            for mode in IntroTutorial.modes { _=state.visitIntro(mode,expectedLevel:"Pre-A1") }
            _=state.completeIntro(lesson);return state
        }
        let first=finished(),second=finished();async let a=service.save(first,npub:npub),b=service.save(second,npub:npub);_=try await(a,b)
        _=try await service.save(first,npub:npub);_=try await service.save(second,npub:npub)
        let user=db.collection("users").document(npub),root=try await user.getDocument(source:.server).data()!,document=try await user.collection("languageLessons").document("fr_"+lesson.id).getDocument(source:.server).data()!
        XCTAssertEqual(WebProgressContract.integer(root["xp"]),200);XCTAssertEqual(root["patreonVerified"] as? Bool,true);XCTAssertEqual(document["status"] as? String,"completed");XCTAssertEqual(WebProgressContract.integer(document["xpEarned"]),50)
        XCTAssertNil(document["gameResult"]);let restored=try requireState(try await service.load(npub:npub))
        XCTAssertTrue(restored.completed.contains("fr:"+lesson.id));XCTAssertEqual(restored.introSessions?["fr"]?.visited,IntroTutorial.modes)
    }
    func testGameRecapCompletesSharedLessonAndPreservesFirstResultAcrossConcurrentClaims() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        let library=try ContentLibrary.load(RPGLibrary.self,name:"rpg-fr"),review=try XCTUnwrap(library.reviews.sorted(by:{ $0.key < $1.key }).first),scenario=try XCTUnwrap(review.value.bySupport["es"]),world=try XCTUnwrap(library.worlds[scenario.worldKey])
        func finished(score:Int) -> LearnerState {
            var state=immersionLearner(),run=RPGRun(target:"fr",support:"es",lessonID:review.key,xpReward:30,scenario:scenario,world:world)
            run.stepIndex=7;run.score=score;state.saveRPG(run);_=state.completeRPG(run);return state
        }
        let first=finished(score:800),second=finished(score:400)
        async let a=service.save(first,npub:npub);async let b=service.save(second,npub:npub);_=try await(a,b)
        let user=db.collection("users").document(npub),fields=try await user.getDocument(source:.server).data()!,document=try await user.collection("languageLessons").document("fr_"+review.key).getDocument(source:.server).data()!
        let result=try XCTUnwrap(document["gameResult"] as? [String:Any]),reward=WebProgressContract.integer(result["xp"])
        XCTAssertTrue([15,30].contains(reward));XCTAssertEqual(WebProgressContract.integer(fields["xp"]),150+reward);XCTAssertEqual(WebProgressContract.integer(document["xpEarned"]),reward);XCTAssertEqual(document["status"] as? String,"completed");XCTAssertEqual(fields["patreonVerified"] as? Bool,true)
        _=try await service.save(first,npub:npub);_=try await service.save(second,npub:npub)
        let retried=try await user.getDocument(source:.server).data()!,content=try await user.collection("languageLessons").document("fr_"+review.key).getDocument(source:.server).data()!
        XCTAssertEqual(WebProgressContract.integer(retried["xp"]),150+reward);XCTAssertEqual(WebProgressContract.integer(content["xpEarned"]),reward);XCTAssertEqual(WebProgressContract.integer(content["earnedXp"]),reward);XCTAssertEqual(JSONValue.foundation(content["gameResult"]!),JSONValue.foundation(result))
        let restored=try requireState(try await service.load(npub:npub));XCTAssertTrue(restored.completed.contains("fr:"+review.key));XCTAssertNotNil(restored.rpgRuns?["fr"])
    }
    private func conversationLearner() -> LearnerState {
        var state=immersionLearner(),draft=ConversationDraft()
        draft.goal=ConversationGoal(text:.object(["en":.string("Say hello and your name")]),questionLevel:"A1",worth:ConversationPractice.worth(rating:state.rating,level:"A1",difficulty:21))
        state.saveConversation(draft);return state
    }
    func testConversationConcurrentGoalClaimsGiveOneBonusScoreAndProofButTwoTurns() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        let state=conversationLearner();var first=state,second=state
        _=first.conversationTurn(id:UUID(),answer:"Bonjour, je suis Ana.",verdict:.init(completed:true,reason:"Good"),turnXP:2,goalXP:3)
        _=second.conversationTurn(id:UUID(),answer:"Je m'appelle Ana.",verdict:.init(completed:true,reason:"Good"),turnXP:2,goalXP:3)
        async let a=service.save(first,npub:npub),b=service.save(second,npub:npub);_=try await (a,b)
        _=try await service.save(first,npub:npub);_=try await service.save(second,npub:npub)
        let root=try await db.collection("users").document(npub).getDocument().data()!,json=AchievementSyncService.jsonFields(root)
        XCTAssertEqual(WebProgressContract.integer(root["xp"]),157);XCTAssertEqual(root["patreonVerified"] as? Bool,true)
        XCTAssertEqual(json["learningIntelligence"]["fr"]["elo"]["totalGraded"].number,1)
        XCTAssertEqual(json["progress"]["conversationDailyActivity"]["fr"][CalendarDay.key(Date())].number,2)
        let events=try await db.collection("users").document(npub).collection("achievementProgress").document("nosabos").collection("events").getDocuments()
        XCTAssertEqual(events.documents.filter { $0.data()["metric"] as? String == "conversation_goals" }.count,1)
        let saved=try requireState(try await service.load(npub:npub))
        XCTAssertEqual(saved.completedConversationGoals?.count,1);XCTAssertEqual(saved.conversation.goal?.id,state.conversation.goal?.id)
    }
    func testConversationMissesAndDriftCountPracticeWithoutXPAndDriftDoesNotLowerScore() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        var state=conversationLearner()
        _=state.conversationTurn(id:UUID(),answer:"wrong topic",verdict:.init(completed:false,reason:"Try your name"),turnXP:3,goalXP:4)
        _=state.conversationTurn(id:UUID(),answer:"I don't watch TV",verdict:.init(completed:false,reason:"New direction",goalStillFits:false),turnXP:3,goalXP:4)
        _=try await service.save(state,npub:npub);_=try await service.save(state,npub:npub)
        let user=db.collection("users").document(npub),root=AchievementSyncService.jsonFields(try await user.getDocument().data())
        XCTAssertEqual(root["xp"].number,150);XCTAssertEqual(root["progress"]["conversationDailyActivity"]["fr"][CalendarDay.key(Date())].number,2)
        XCTAssertEqual(root["learningIntelligence"]["fr"]["elo"]["totalGraded"].number,1)
        XCTAssertEqual(root["learningIntelligence"]["fr"]["performanceSummary"]["weakConcepts"].array.count,1)
        let events=try await user.collection("achievementProgress").document("nosabos").collection("events").getDocuments()
        XCTAssertTrue(events.documents.filter { $0.data()["metric"] as? String == "conversation_goals" }.isEmpty)
    }
    private func immersionProposal(_ state: inout LearnerState, suffix: String = "") {
        let tasks=JSONValue.array((0..<3).map { .object(["title":.string("Private mission \($0)\(suffix)"),"description":.string("Practice with familiar things at home \($0)\(suffix).")]) })
        state.applyImmersion(.init(target:state.target,action:.batch,payload:state.immersionScope().setting("tasks",tasks)))
    }
    func testImmersionConcurrentCompletionAndRetriesGrantOneSharedReward() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        var state=immersionLearner();immersionProposal(&state)
        state=try requireState(try await service.save(state,npub:npub));state.pendingImmersionChanges=[]
        XCTAssertEqual(state.immersionState()["status"].string,"ready","Loaded scope: \(state.immersionScope().json); batch: \((state.immersionBatch ?? .null).json)")
        var first=state,second=state;first.toggleImmersion(index:0);second.toggleImmersion(index:1)
        async let savedFirst=service.save(first,npub:npub)
        async let savedSecond=service.save(second,npub:npub)
        _=try await (savedFirst,savedSecond)
        state=try requireState(try await service.load(npub:npub));XCTAssertTrue(DailyImmersion.completed(state.immersionBatch!,index:0));XCTAssertTrue(DailyImmersion.completed(state.immersionBatch!,index:1))
        state.toggleImmersion(index:2);let pending=state
        let saved=try requireState(try await service.save(pending,npub:npub))
        XCTAssertTrue(saved.immersionBatch?["rewarded"].boolean == true)
        _=try await service.save(pending,npub:npub)
        var duplicate=saved;duplicate.pendingImmersionChanges=[];duplicate.toggleImmersion(index:2);duplicate.toggleImmersion(index:2)
        _=try await service.save(duplicate,npub:npub)
        let fields=try await db.collection("users").document(npub).getDocument().data()!
        XCTAssertEqual(WebProgressContract.integer(fields["xp"]),165);XCTAssertEqual(fields["patreonVerified"] as? Bool,true)
        let key=DailyImmersion.receipt(target:"fr",day:CalendarDay.key(Date()))
        XCTAssertNotNil((fields["xpAwardReceipts"] as? [String:Any])?[key])
        let events=try await db.collection("users").document(npub).collection("achievementProgress").document("nosabos").collection("events").getDocuments()
        XCTAssertEqual(events.documents.filter { $0.data()["metric"] as? String == "immersion_tasks" }.count,3)
        XCTAssertEqual(events.documents.filter { $0.data()["metric"] as? String == "immersion_checklists" }.count,1)
        XCTAssertEqual(saved.gradedByLanguage?["fr"] ?? 0,0)
    }
    func testImmersionFirstBatchWinsAndStaleDeviceCannotCompleteDifferentTasks() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        var winner=immersionLearner();immersionProposal(&winner)
        winner=try requireState(try await service.save(winner,npub:npub))
        var loser=winner;loser.immersionBatch=nil;loser.pendingImmersionChanges=[]
        immersionProposal(&loser,suffix:" alternate")
        for i in 0..<3 { loser.toggleImmersion(index:i) }
        XCTAssertEqual(loser.totalXP,winner.totalXP+15)
        let acknowledged=try requireState(try await service.save(loser,npub:npub))
        XCTAssertEqual(acknowledged.immersionBatch?["tasks"],winner.immersionBatch?["tasks"])
        XCTAssertFalse(DailyImmersion.completed(acknowledged.immersionBatch!,index:0))
        let root=try await db.collection("users").document(npub).getDocument().data()!
        XCTAssertEqual(WebProgressContract.integer(root["xp"]),150);XCTAssertEqual(acknowledged.totalXP,winner.totalXP)
    }
    func testOfflineImmersionBaseSurvivesGoalEditBeforeItsFirstUpload() async throws {
        let (service,db,npub)=try context()
        var state=immersionLearner();immersionProposal(&state)
        state.toggleImmersion(index:0);state.editGoal("Read a French recipe privately at home")
        let original=try XCTUnwrap(state.immersionBatch)
        let task:JSONValue = .object(["title":.string("Find a familiar recipe word"),"description":.string("Privately read a short recipe and identify one known word.")])
        state.applyImmersion(.init(target:state.target,action:.batch,payload:state.immersionScope().setting("tasks",.array([task])).setting("baseBatch",original)))
        let saved=try requireState(try await service.save(state,npub:npub))
        XCTAssertEqual(saved.immersionBatch?["tasks"].array.count,4);XCTAssertTrue(DailyImmersion.completed(saved.immersionBatch!,index:0));XCTAssertEqual(saved.totalXP,0)
        let root=try await db.collection("users").document(npub).getDocument().data()!
        XCTAssertEqual(WebProgressContract.integer(root["xp"]),0)
    }
    func testImmersionProposalPreservesLegacyLanguageXPWithoutRootXPCounter() async throws {
        let (service,db,npub)=try context()
        try await db.collection("users").document(npub).setData(["local_npub":npub,"progress":["targetLang":"fr","supportLang":"es","cefrLevel":"A1","totalXp":42]])
        var state=immersionLearner();immersionProposal(&state)
        let saved=try requireState(try await service.save(state,npub:npub))
        XCTAssertEqual(saved.totalXP,42)
        let root=try await db.collection("users").document(npub).getDocument().data()!
        XCTAssertEqual(WebProgressContract.integer((root["progress"] as? [String:Any])?["totalXp"]),42)
    }
    func testImmersionExistingWebRewardReceiptAndLanguageHistoryArePreserved() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        let user=db.collection("users").document(npub),key=DailyImmersion.receipt(target:"fr",day:CalendarDay.key(Date()))
        try await user.setData(["xpAwardReceipts":[key:WebProgressContract.iso(Date())],"realWorldTaskHistoryByLanguage":["de":[["title":"Old German mission","description":"Preserve history"]]]],merge:true)
        var state=immersionLearner();immersionProposal(&state);state=try requireState(try await service.save(state,npub:npub));state.pendingImmersionChanges=[]
        for i in 0..<3 { state.toggleImmersion(index:i) }
        let saved=try requireState(try await service.save(state,npub:npub))
        XCTAssertTrue(saved.immersionBatch?["rewarded"].boolean == true);XCTAssertEqual(saved.totalXP,150)
        XCTAssertEqual(saved.immersionHistory?["de"]?.array.first?["title"].string,"Old German mission")
        let root=try await user.getDocument().data()!
        XCTAssertEqual(WebProgressContract.integer(root["xp"]),150);XCTAssertEqual(root["patreonVerified"] as? Bool,true)
    }
    func testOfflineCompletedBaseKeepsItsRewardAfterGoalChangeBeforeFirstUpload() async throws {
        let (service,db,npub)=try context()
        var state=immersionLearner();immersionProposal(&state)
        for index in 0..<3 { state.toggleImmersion(index:index) }
        XCTAssertEqual(state.totalXP,15)
        state.editGoal("Read a French recipe privately at home")
        let base=try XCTUnwrap(state.immersionBatch),task:JSONValue = .object(["title":.string("Read a recipe heading"),"description":.string("Privately find a familiar word in a short recipe heading.")])
        state.applyImmersion(.init(target:state.target,action:.batch,payload:state.immersionScope().setting("tasks",.array([task])).setting("baseBatch",base)))
        var saved=try requireState(try await service.save(state,npub:npub))
        XCTAssertEqual(saved.totalXP,15);XCTAssertTrue(saved.immersionBatch?["rewarded"].boolean == true)
        let ledger=try await db.collection("users").document(npub).collection("achievementProgress").document("nosabos").collection("events").getDocuments()
        XCTAssertEqual(ledger.documents.filter { $0.data()["metric"] as? String == "immersion_checklists" }.count,1)
        saved.pendingImmersionChanges=[];saved.toggleImmersion(index:3)
        _=try await service.save(saved,npub:npub);_=try await service.save(state,npub:npub)
        let root=try await db.collection("users").document(npub).getDocument().data()!
        XCTAssertEqual(WebProgressContract.integer(root["xp"]),15)
    }
    func testSignedCollectionImportPreservesRealAwardsAndOtherHostRecordsWithoutXP() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        let user=db.collection("users").document(npub)
        try await user.collection("achievements").document("tutor_reach_a2").setData(["unlockedAt":1,"source":"nosabos","catalogVersion":8,"test":false])
        try await user.collection("achievements").document("tutor_reach_b1").setData(["unlockedAt":2,"source":"nosabos","catalogVersion":8,"test":true])
        let records=JSONValue.foundation(["tutor_reach_a2":["unlockedAt":10],"tutor_reach_b1":["unlockedAt":10,"source":"nosabos"],"robots_full_curriculum_v4":["unlockedAt":20,"source":"robotsbuildingeducation"],"prototype/old":["unlockedAt":5]])
        let result=try await service.importAchievements(records,npub:npub)
        let imported=try XCTUnwrap(result)
        XCTAssertEqual(imported["tutor_reach_a2"]?["unlockedAt"].number,1)
        XCTAssertEqual(imported["tutor_reach_b1"]?["unlockedAt"].number,10)
        XCTAssertGreaterThan(imported["robots_full_curriculum_v4"]?["unlockedAt"].number ?? 0,0)
        XCTAssertNil(imported["prototype/old"])
        _=try await service.importAchievements(records,npub:npub)
        let root=try await user.getDocument().data()!
        XCTAssertEqual(WebProgressContract.integer(root["xp"]),150);XCTAssertEqual(root["patreonVerified"] as? Bool,true)
        let stored=try await user.collection("achievements").document("robots_full_curriculum_v4").getDocument().data()!
        XCTAssertEqual(stored["source"] as? String,"robotsbuildingeducation");XCTAssertEqual(stored["catalogVersion"] as? Int,8)
    }
    func testAchievementBackfillUsesCompletionAndPreservesRealAwards() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        let user=db.collection("users").document(npub)
        try await user.setData(["proficiencyPlacements":["fr":"C2"]],merge:true)
        try await user.collection("courseProgress").document("fr").setData(["migration":["complete":true],"tutor":["levels":["b2":["total":84,"completed":84]]],"updatedAt":Timestamp(date:Date())])
        try await user.collection("achievements").document("tutor_reach_a2").setData(["unlockedAt":1,"source":"nosabos","catalogVersion":8,"test":false])
        try await user.collection("achievements").document("tutor_reach_b1").setData(["unlockedAt":2,"source":"nosabos","catalogVersion":8,"test":true])
        let local=try requireState(try await service.load(npub:npub)),saved=try requireState(try await service.save(local,npub:npub))
        XCTAssertEqual(saved.achievementRecords?["tutor_reach_a2"]?["unlockedAt"].number,1)
        XCTAssertEqual(saved.achievementRecords?["tutor_reach_b1"]?["test"],.bool(false))
        XCTAssertGreaterThan(saved.achievementRecords?["piyali_tutor_complete_b2"]?["unlockedAt"].number ?? 0,0)
        XCTAssertGreaterThan(saved.achievementRecords?["piyali_tutor_complete_pre_a1"]?["unlockedAt"].number ?? 0,0)
        XCTAssertNil(saved.achievementRecords?["piyali_skillTree_complete_b2"]);XCTAssertNil(saved.achievementRecords?["piyali_tutor_complete_c2"])
        let first=try await user.collection("achievements").getDocuments(source:.server)
        _=try await service.save(local,npub:npub)
        let second=try await user.collection("achievements").getDocuments(source:.server)
        XCTAssertEqual(first.documents.count,second.documents.count)
        let marker=try await user.collection("achievementMigrations").document("nosabos_v1").getDocument().data()!
        XCTAssertEqual(marker["complete"] as? Bool,true)
        let root=try await user.getDocument().data()!;XCTAssertEqual(root["patreonVerified"] as? Bool,true)
    }
    func testSuccessfulUngradatedCardsEarnCountAwardAndIncrementalEventsDeduplicate() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        let user=db.collection("users").document(npub)
        for i in 1...5 { try await user.collection("languageFlashcards").document("fr_a1-achievement-\(i)").setData(["targetLang":"fr","cefrLevel":"A1","cardId":"a1-achievement-\(i)","completed":false,"successfulReviews":1,"lastReviewOutcome":"good","consecutiveCorrect":1]) }
        var local=try requireState(try await service.load(npub:npub))
        let saved=try requireState(try await service.save(local,npub:npub))
        XCTAssertGreaterThan(saved.achievementRecords?["nosabos_flashcards_completed_5"]?["unlockedAt"].number ?? 0,0)
        XCTAssertNil(saved.achievementRecords?["nosabos_flashcards_completed_10"]);XCTAssertTrue(saved.flashcardMastery.isEmpty)
        local=saved
        for i in 6...10 { local.review(cardID:"a1-achievement-\(i)",rating:.good) }
        async let first=service.save(local,npub:npub)
        async let second=service.save(local,npub:npub)
        _=try await (first,second)
        let result=try requireState(try await service.load(npub:npub))
        XCTAssertGreaterThan(result.achievementRecords?["nosabos_flashcards_completed_10"]?["unlockedAt"].number ?? 0,0)
        let events=try await user.collection("achievementProgress").document("nosabos").collection("events").getDocuments(source:.server)
        XCTAssertEqual(events.documents.count,10);XCTAssertTrue(result.flashcardMastery.isEmpty)
    }
    func testConfirmedGoalRepairAndImmersionEventsSharePermanentCollection() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        let user=db.collection("users").document(npub),day=CalendarDay.key(Date()),stamp=WebProgressContract.iso(Date())
        try await user.setData(["learningIntelligence":["fr":["dailyGoal":["completed":true,"blueprint":["modes":["lesson","tutor"],"cefrLevel":"B1","dayKey":day,"goalId":"goal-1"],"modeProgress":["lesson":20,"tutor":25]]]],"progress":["repairDailyActivity":["fr":[day:2]]],"realWorldTasks":["targetLang":"fr","dayKey":day,"generatedAt":stamp,"tasks":["a","b","c","d","e"],"completed":["0":true,"1":true,"2":true,"3":true,"4":true],"rewarded":true]],merge:true)
        try await user.collection("questDays").document("fr_"+day).setData(["dayKey":day,"lang":"fr","repair":["items":[["cefrLevel":"B1"],["cefrLevel":"B2"]],"target":2,"createdAt":stamp]])
        let local=try requireState(try await service.load(npub:npub)),saved=try requireState(try await service.save(local,npub:npub))
        for id in ["piyali_goals_complete_b1","piyali_repairs_complete_b2","nosabos_immersion_tasks_5","nosabos_immersion_checklists_1"] { XCTAssertGreaterThan(saved.achievementRecords?[id]?["unlockedAt"].number ?? 0,0,id) }
        XCTAssertNil(saved.achievementRecords?["piyali_goals_complete_b2"])
        _=try await service.save(local,npub:npub)
        let events=try await user.collection("achievementProgress").document("nosabos").collection("events").getDocuments(source:.server)
        XCTAssertEqual(events.documents.count,9)
    }
    func testNativePhonicsCompletionWritesSharedEvidenceAndDeckAwardOnce() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        var state=try requireState(try await service.load(npub:npub));state.level="Pre-A1"
        let decks=try ContentLibrary.load([String:[JSONValue]].self,name:"phonics")
        let cards=try XCTUnwrap(decks["fr:es:Pre-A1"])
        XCTAssertFalse(cards.isEmpty)
        for card in cards { state.award(5,source:.phonics,contentID:card["id"].string) }
        let saved=try requireState(try await service.save(state,npub:npub))
        XCTAssertGreaterThan(saved.achievementRecords?["nosabos_phonics_decks_1"]?["unlockedAt"].number ?? 0,0)
        XCTAssertGreaterThan(saved.achievementRecords?["nosabos_phonics_cards_all"]?["unlockedAt"].number ?? 0,0)
        _=try await service.save(state,npub:npub)
        let docs=try await db.collection("users").document(npub).collection("alphabetPractice").getDocuments(source:.server)
        XCTAssertEqual(docs.documents.count,cards.count)
        for doc in docs.documents { XCTAssertEqual(WebProgressContract.integer(doc.data()["correctCount"]),1) }
        let ledger=saved.achievementLedger ?? .null
        XCTAssertEqual(ledger["phonics_decks"].object.count,1)
    }
    func testLegacyTutorAgendaMarkerCannotBecomeRegularLessonAchievementEvidence() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        let user=db.collection("users").document(npub)
        try await user.collection("languageLessons").document("fr_lesson-b2-legacy").setData(["targetLang":"fr","cefrLevel":"B2","lessonId":"lesson-b2-legacy","status":"completed","tutorAgendaProgress":[:]])
        let local=try requireState(try await service.load(npub:npub)),saved=try requireState(try await service.save(local,npub:npub))
        XCTAssertEqual(saved.courseCompletion?["fr"]?["tutor"]?["B2"],1)
        XCTAssertEqual(saved.courseCompletion?["fr"]?["skillTree"]?["B2"],0)
        XCTAssertNil(saved.achievementRecords?["piyali_skillTree_complete_b2"])
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
    func testStoryLineAndEpisodeRewardsAreClaimedOnceAcrossDevicesWithPrivateProofs() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        var base=try requireState(try await service.load(npub:npub));base.target="es";base.support="en";base.level="A1";base.preferencesModifiedAt=Date()
        let payload=try ContentLibrary.load(JSONValue.self,name:"story-test-episode"),lines=payload["segments"].array.flatMap { $0["turns"].array }
        var spoken=try StoryRun(payload:.object(["title":payload["title"],"sentences":.array(Array((lines+lines).prefix(10)))]),mode:.speaking,target:"es",support:"en",level:"A1",lessonID:nil,worth:ConversationPractice.worth(rating:base.rating,level:"A1"))
        spoken.lessonLevel="A1";spoken.sourceContext="canonical-lesson-context";spoken.portraitIDs=["Ana":"25","Luis":"6"]
        base.saveStory(spoken);var first=base,second=base
        XCTAssertEqual(first.practiceStoryLine(words:spoken.sentences[0].target,typed:true),2);XCTAssertEqual(second.practiceStoryLine(words:spoken.sentences[0].target,typed:true),2)
        async let one=service.save(first,npub:npub);async let two=service.save(second,npub:npub);_=try await (one,two)
        var restored=try requireState(try await service.load(npub:npub));XCTAssertEqual(restored.totalXP,152);XCTAssertEqual(restored.gradedByLanguage?["es"],1)
        XCTAssertEqual(restored.story?.sourceContext,spoken.sourceContext);XCTAssertEqual(restored.story?.portraitIDs,spoken.portraitIDs);XCTAssertEqual(restored.story?.lessonLevel,"A1")
        let spokenProofs=try await db.collection("users").document(npub).collection("storyTurns").getDocuments(source:.server);XCTAssertEqual(spokenProofs.count,1)
        let fresh=try StoryRun(payload:payload,mode:.radio,target:"es",support:"en",level:"A1",lessonID:nil,worth:.null)
        var a=fresh;a.index=a.count;a.results=Dictionary(uniqueKeysWithValues:(0..<a.count).map { (String($0),true) });var b=a;b.results=Dictionary(uniqueKeysWithValues:(0..<b.count).map { (String($0),false) })
        first=restored;second=restored;first.saveStory(a);second.saveStory(b);XCTAssertEqual(first.finishStory(),6);XCTAssertEqual(second.finishStory(),6)
        let pendingFirst=first,pendingSecond=second
        async let three=service.save(pendingFirst,npub:npub);async let four=service.save(pendingSecond,npub:npub);_=try await (three,four)
        _=try await service.save(pendingFirst,npub:npub);_=try await service.save(pendingSecond,npub:npub)
        restored=try requireState(try await service.load(npub:npub));XCTAssertEqual(restored.totalXP,158);XCTAssertEqual(restored.gradedByLanguage?["es"],1)
        let records=try await db.collection("users").document(npub).collection("storyTurns").getDocuments(source:.server)
        XCTAssertEqual(records.count,2);XCTAssertTrue(records.documents.contains { $0.data()["mode"] as? String == "story-radio-complete" })
        let root=try await db.collection("users").document(npub).getDocument(source:.server);XCTAssertEqual(root.data()?["patreonVerified"] as? Bool,true)
    }

    func testReadingQuestionAndSpeechShareOneReceiptAcrossDevices() async throws {
        let (service,db,npub)=try context();try await seed(db,npub)
        var base=try requireState(try await service.load(npub:npub));base.target="es";base.support="en";base.level="A1";base.preferencesModifiedAt=Date()
        let payload=try ContentLibrary.load(JSONValue.self,name:"reading-test-passage")
        let reading=try ReadingRun(payload:payload,target:"es",support:"en",level:"A1",lessonID:nil,selection:.null,worth:ConversationPractice.worth(rating:base.rating,level:"A1"),roll:0.7)
        base.saveReading(reading);var question=base,speech=base
        XCTAssertEqual(question.reviewReading(answer:reading.question.answer,correct:true,feedback:"Correct"),7)
        XCTAssertEqual(speech.reviewReading(answer:"short recognized fragment",correct:false,feedback:"Compare wording",speech:true),7)
        async let one=service.save(question,npub:npub);async let two=service.save(speech,npub:npub);_=try await (one,two)
        _=try await service.save(question,npub:npub);_=try await service.save(speech,npub:npub)
        let restored=try requireState(try await service.load(npub:npub));XCTAssertEqual(restored.totalXP,157)
        let records=try await db.collection("users").document(npub).collection("readingTurns").getDocuments(source:.server);XCTAssertEqual(records.count,1)
        let method=records.documents.first?.data()["method"] as? String
        XCTAssertEqual(restored.gradedByLanguage?["es"] ?? 0,method == "question" ? 1 : 0)
        XCTAssertTrue(restored.reading!.awarded)
        let root=try await db.collection("users").document(npub).getDocument(source:.server);XCTAssertEqual(root.data()?["patreonVerified"] as? Bool,true)
    }

}
