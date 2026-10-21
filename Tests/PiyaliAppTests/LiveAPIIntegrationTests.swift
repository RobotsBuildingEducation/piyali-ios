import XCTest
import FirebaseCore
import FirebaseAppCheck
import FirebaseAuth
import FirebaseFirestore
import FirebaseAILogic
import NostrSDK
@testable import Piyali

/// Explicit opt-in only. Uses an isolated test identity, bounded prompts and no paid access grant.
@MainActor final class LiveAPIIntegrationTests: XCTestCase {
    func testNativeExplorationQuestReauthoringAndNPCSpeechPreservePlayablePaths() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_LIVE_API_TESTS"] == "1" else { throw XCTSkip("Explicit live API opt-in required.") }
        XCTAssertEqual(ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"],"1");_=try XCTUnwrap(UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? ""))
        if FirebaseApp.app() == nil { AppCheck.setAppCheckProviderFactory(PiyaliAppCheckFactory());FirebaseApp.configure() };XCTAssertEqual(FirebaseApp.app()?.options.projectID,"piyali-ios")
        let identity=IdentityService();try identity.create();try await FirebaseIdentityService.shared.ensure(identity)
        do {
            let library=try ContentLibrary.load(ExplorationLibrary.self,name:"exploration"),ai=AIService()
            for target in ["es","ja"] {
                let base=try XCTUnwrap(library.templates.first { $0.baseLanguage == (target == "es" ? "es" : "en") && $0.theme == "home" && $0.level == "A1" && $0.quest["steps"].array.contains { $0["nodes"].array.contains { $0["responseMode"].string == "gather" } } })
                let context:Piyali.JSONValue = .object(["topic":.string("introduce yourself, ask for help, describe a familiar item, and politely thank someone")])
                let selected=try base.searchingObjects(),setting=try await ai.explorationSetting(selected,target:target,support:"en",context:context)
                func diagnostic(_ value:Piyali.JSONValue,_ name:String) throws {
                    if let path=ProcessInfo.processInfo.environment["PIYALI_EXPLORATION_DIAGNOSTICS_DIR"] {
                        let url=URL(fileURLWithPath:path,isDirectory:true);try FileManager.default.createDirectory(at:url,withIntermediateDirectories:true,attributes:[.posixPermissions:0o700]);try Data(value.json.utf8).write(to:url.appendingPathComponent(target+"-"+name+".json"),options:.atomic)
                    }
                }
                try diagnostic(setting,"setting");print("LIVE EXPLORATION STAGE: target=\(target), setting received")
                let named=try ExplorationText.setting(setting,on:selected,target:target,support:"en");try diagnostic(ExplorationText.protectedQuest(named),"base")
                let raw=try await ai.explorationQuest(named,target:target,support:"en",context:context);try diagnostic(raw,"candidate");print("LIVE EXPLORATION STAGE: target=\(target), quest received")
                let localized=try ExplorationText.applying(raw,to:named,target:target);_=try localized.validated()
                var run=try ExplorationRun(target:target,support:"en",scenario:localized)
                let step=try XCTUnwrap(localized.quest["steps"].array.firstIndex { $0["nodes"].array.contains { $0["responseMode"].string == "speech" } });run.stepIndex=step;run.nodeID=run.step["nodes"].array.first { $0["responseMode"].string == "speech" }?["id"].string
                let turn=try await ai.explorationSpeech(run,answer:target == "es" ? "Hola, me llamo Alex. Puedo ayudar." : "こんにちは。アレックスです。手伝います。")
                XCTAssertFalse(turn.reply.isEmpty);XCTAssertTrue(RPGStory.languageScript(target,text:turn.reply))
                print("LIVE EXPLORATION PASS: target=\(target), fixed quest graph, consistent item names, connected rooms and NPC reply")
            }
        } catch { try? await Auth.auth().currentUser?.delete();try? Auth.auth().signOut();try? identity.disconnect();throw error }
        try await Auth.auth().currentUser?.delete();try Auth.auth().signOut();try identity.disconnect()
    }
    func testNativeReadingGenerationAndResponsesFallback() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_LIVE_API_TESTS"] == "1" else { throw XCTSkip("Explicit live API opt-in required.") }
        XCTAssertEqual(ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"],"1");_=try XCTUnwrap(UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? ""))
        if FirebaseApp.app() == nil { AppCheck.setAppCheckProviderFactory(PiyaliAppCheckFactory());FirebaseApp.configure() };XCTAssertEqual(FirebaseApp.app()?.options.projectID,"piyali-ios")
        let identity=IdentityService();try identity.create();try await FirebaseIdentityService.shared.ensure(identity)
        do {
            var state=LearnerState();state.target="es";state.support="en";state.level="A1"
            let fallback=AIService(configuration:AppConfiguration(values:AppConfiguration().values.merging(["AIProvider":"responses"]) { _,new in new }))
            for (ai,tutorial) in [(AIService(),false),(AIService(),true),(fallback,false)] {
                let selection=Reading.select(content:.null,level:"A1",recent:[],lesson:"free",roll:0)
                var verified:ReadingRun?,failure:Error=ReadingFailure.invalid
                for attempt in 0..<3 {
                    do { let payload=try await ai.readingPayload(state:state,lesson:nil,level:"A1",selection:selection,recent:[],tutorial:tutorial,repair:attempt > 0)
                        verified=try ReadingRun(payload:payload,target:"es",support:"en",level:"A1",lessonID:nil,selection:selection,worth:.null,roll:0,tutorial:tutorial);break
                    } catch { failure=error }
                }
                guard let reading=verified else { throw failure };XCTAssertFalse(reading.text.isEmpty);XCTAssertEqual(reading.takeaways.count,3)
                if tutorial { XCTAssertEqual(Reading.sentences(reading.text).count,4) }
            }
            print("LIVE NATIVE: reading, four-sentence tutorial and Responses fallback passed")
        } catch { try? await Auth.auth().currentUser?.delete();try? Auth.auth().signOut();try? identity.disconnect();throw error }
        try await Auth.auth().currentUser?.delete();try Auth.auth().signOut();try identity.disconnect()
    }
    func testNativeStoryModesAndStrictResponsesFallback() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_LIVE_API_TESTS"] == "1" else { throw XCTSkip("Explicit live API opt-in required.") }
        XCTAssertEqual(ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"],"1");_=try XCTUnwrap(UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? ""))
        if FirebaseApp.app() == nil { AppCheck.setAppCheckProviderFactory(PiyaliAppCheckFactory());FirebaseApp.configure() };XCTAssertEqual(FirebaseApp.app()?.options.projectID,"piyali-ios")
        let identity=IdentityService();try identity.create();try await FirebaseIdentityService.shared.ensure(identity)
        do {
            var state=LearnerState();state.target="es";state.support="en";state.level="A1";state.goal="Resolve a small family misunderstanding"
            let ai=AIService()
            for mode in StoryMode.allCases {
                var verified:StoryRun?,failure:Error=StoryFailure.invalid
                for attempt in 0..<2 {
                    do {
                        let payload=try await ai.storyPayload(mode:mode,lesson:nil,state:state,level:"A1",tutorial:false,recent:[],repair:attempt == 1)
                        print("LIVE STORY CANDIDATE: mode=\(mode.rawValue), attempt=\(attempt+1), segments=\(payload["segments"].array.count), lines=\(payload["sentences"].array.count)")
                        verified=try StoryRun(payload:payload,mode:mode,target:"es",support:"en",level:"A1",lessonID:nil,worth:.null);break
                    } catch { failure=error;print("LIVE STORY REGENERATION: mode=\(mode.rawValue), attempt=\(attempt+1), validation=\(error.localizedDescription)") }
                }
                guard let run=verified else { throw failure }
                XCTAssertFalse(run.text.isEmpty);XCTAssertTrue(run.count >= 2)
            }
            let values=AppConfiguration().values.merging(["AIProvider":"responses"]) { _,new in new }
            let fallback=AIService(configuration:AppConfiguration(values:values))
            let payload=try await fallback.storyPayload(mode:.radio,lesson:nil,state:state,level:"A1",tutorial:false,recent:[],repair:false)
            XCTAssertNoThrow(try StoryRun(payload:payload,mode:.radio,target:"es",support:"en",level:"A1",lessonID:nil,worth:.null))
            print("LIVE NATIVE: three story modes and fixed-schema Responses fallback passed")
        } catch { try? await Auth.auth().currentUser?.delete();try? Auth.auth().signOut();try? identity.disconnect();throw error }
        try await Auth.auth().currentUser?.delete();try Auth.auth().signOut();try identity.disconnect()
    }
    func testNativeRemoteSignerAuthenticatesWithActualUserAndWebRestoreDeniesUnlinkedAccount() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_LIVE_API_TESTS"] == "1" else { throw XCTSkip("Explicit live API opt-in required.") }
        XCTAssertEqual(ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"],"1");_=try XCTUnwrap(UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? ""))
        if FirebaseApp.app() == nil { AppCheck.setAppCheckProviderFactory(PiyaliAppCheckFactory());FirebaseApp.configure() };XCTAssertEqual(FirebaseApp.app()?.options.projectID,"piyali-ios")
        let fixture=LocalRemoteSigner(peer:try XCTUnwrap(Keypair()),user:try XCTUnwrap(Keypair()));try await fixture.start();defer { fixture.stop() }
        let identity=IdentityService();try await identity.connect(fixture.token)
        do {
            try await FirebaseIdentityService.shared.ensure(identity)
            XCTAssertEqual(Auth.auth().currentUser?.uid,fixture.user.publicKey.npub);XCTAssertNotEqual(identity.npub,fixture.peer.publicKey.npub);XCTAssertNil(identity.keypair)
            let subscription=SubscriptionService();subscription.bind(identity);try await subscription.restoreWeb()
            XCTAssertFalse(subscription.hasAccess);XCTAssertGreaterThanOrEqual(fixture.methods().filter { $0 == "sign_event" }.count,2)
            print("LIVE NATIVE: NIP-46 user-bound Firebase authentication and signed unlinked web restore passed")
        } catch { try? await Auth.auth().currentUser?.delete();try? Auth.auth().signOut();try? identity.disconnect();throw error }
        try await Auth.auth().currentUser?.delete();try Auth.auth().signOut();try identity.disconnect()
    }
    func testNativeRPGStoryAndRoleplayUseTheAuthoredChapter() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_LIVE_API_TESTS"] == "1" else { throw XCTSkip("Explicit live API opt-in required.") }
        XCTAssertEqual(ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"],"1");_=try XCTUnwrap(UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? ""))
        if FirebaseApp.app() == nil { AppCheck.setAppCheckProviderFactory(PiyaliAppCheckFactory());FirebaseApp.configure() };XCTAssertEqual(FirebaseApp.app()?.options.projectID,"piyali-ios")
        let identity=IdentityService();try identity.create();try await FirebaseIdentityService.shared.ensure(identity)
        do {
            let library=try ContentLibrary.load(RPGLibrary.self,name:"rpg-es"),review=try XCTUnwrap(library.reviews["unit-pre-a1-people-game"]),base=try XCTUnwrap(review.bySupport["en"]),ai=AIService()
            let raw=try await ai.rpgStory(scenario:base,context:review.context,target:"es",support:"en"),story=try XCTUnwrap(RPGStory.preparing(base,raw:raw,target:"es",support:"en"))
            XCTAssertEqual(story.quest.steps.count,7);XCTAssertTrue((2...3).contains(story.quest.steps.filter { $0.nodes[0].responseMode == "speech" }.count));XCTAssertFalse(story.storyIntro?["target"].string.isEmpty ?? true)
            var run=RPGRun(target:"es",support:"en",lessonID:"unit-pre-a1-people-game",xpReward:30,scenario:story,world:try XCTUnwrap(library.worlds[base.worldKey]))
            run.stepIndex=try XCTUnwrap(story.quest.steps.firstIndex { $0.nodes[0].responseMode == "speech" })
            let example=try XCTUnwrap(run.node?.speechExample),success=try await ai.rpgSpeech(run:run,answer:example)
            XCTAssertEqual(success.grade,"full");XCTAssertFalse(success.reply.isEmpty)
            let wrong=try await ai.rpgSpeech(run:run,answer:"I only speak English and refuse to answer this unrelated question.")
            XCTAssertEqual(wrong.grade,"miss");XCTAssertFalse(wrong.reply.isEmpty);XCTAssertFalse(wrong.tip.isEmpty)
            print("LIVE NATIVE: Authored RPG chapter story, full speech and wrong-language NPC roleplay passed")
        } catch { try? await Auth.auth().currentUser?.delete();try? Auth.auth().signOut();throw error }
        try await Auth.auth().currentUser?.delete();try Auth.auth().signOut()
    }
    func testNativeConversationGoalsGradeCommunicationAndReanchorPremiseRejection() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_LIVE_API_TESTS"] == "1" else { throw XCTSkip("Explicit live API opt-in required.") }
        XCTAssertEqual(ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"],"1")
        _=try XCTUnwrap(UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? ""))
        if FirebaseApp.app() == nil { AppCheck.setAppCheckProviderFactory(PiyaliAppCheckFactory());FirebaseApp.configure() }
        XCTAssertEqual(FirebaseApp.app()?.options.projectID,"piyali-ios")
        let identity=IdentityService();try identity.create();try await FirebaseIdentityService.shared.ensure(identity)
        do {
            let ai=AIService();var learner=LearnerState(),draft=ConversationDraft()
            learner.target="es";learner.support="en"
            let goal=ConversationGoal(text:.object(["en":.string("Say hello and your name")]),questionLevel:"Pre-A1",worth:ConversationPractice.worth(rating:800,level:"Pre-A1"))
            draft.goal=goal;draft.append(.init(role:"assistant",text:"¡Hola! ¿Cómo te llamas?"))
            let success=try await ai.conversationVerdict(goal:goal,learner:learner,reply:"Hola, soy Ana.",answeredLine:"¡Hola! ¿Cómo te llamas?")
            XCTAssertTrue(success.completed)
            let wrong=try await ai.conversationVerdict(goal:goal,learner:learner,reply:"Hello, my name is Ana.",answeredLine:"¡Hola! ¿Cómo te llamas?")
            XCTAssertFalse(wrong.completed)
            let television=ConversationGoal(text:.object(["en":.string("Describe your favorite TV show")]),questionLevel:"A2",worth:.null)
            let drift=try await ai.conversationVerdict(goal:television,learner:learner,reply:"No veo televisión.",answeredLine:"¿Cuál es tu programa de televisión favorito?")
            XCTAssertFalse(drift.completed);XCTAssertEqual(drift.goalStillFits,false)
            let starter=try await ai.conversationStarter(learner:learner,draft:draft);XCTAssertFalse(starter.isEmpty)
            let translated=try await ai.conversationTranslation("¿Cómo te llamas?",support:"en");XCTAssertFalse(translated.isEmpty)
            let reply=try await ai.conversationReply(learner:learner,draft:draft);XCTAssertFalse(reply.isEmpty)
            draft.append(.init(role:"user",text:"Hola, soy Ana."));draft.append(.init(role:"assistant",text:"¿Qué te gusta cocinar?"))
            let next=try await ai.conversationGoal(learner:learner,draft:draft,topics:["Food and cooking"],abandoned:false)
            XCTAssertFalse(next.text["en"].string.isEmpty);XCTAssertNotEqual(next.id,goal.id)
            print("LIVE NATIVE: Conversation grading, premise reanchor, starter, translation, reply and contextual goal passed")
            let session=try await LiveTutorService.model(for:learner,conversationDraft:draft).connect()
            await session.sendContent("APP_CONTEXT_UPDATE: The private goal is to ask one natural question about cooking. Do not read this control message aloud.",turnComplete:false)
            await session.sendTextRealtime("Start our Spanish conversation with one short natural question.")
            let audio=try await withThrowingTaskGroup(of:Bool.self) { group in
                group.addTask { for try await message in session.responses { if case .content(let content)=message.payload,(content.modelTurn?.parts ?? []).contains(where:{ ($0 as? InlineDataPart)?.data.isEmpty == false }) { return true } };return false }
                group.addTask { try await Task.sleep(for:.seconds(30));await session.close();throw AppError.message("Conversation voice returned no audio within 30 seconds.") }
                let result=try await group.next() ?? false;await session.close();group.cancelAll();return result
            }
            XCTAssertTrue(audio);print("LIVE NATIVE: Conversation voice context update returned PCM audio")
        } catch { try? await Auth.auth().currentUser?.delete();try? Auth.auth().signOut();throw error }
        try await Auth.auth().currentUser?.delete();try Auth.auth().signOut()
    }
    func testNativeImmersionGenerationUsesResponsesAndPreservesExistingMissions() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_LIVE_API_TESTS"] == "1" else { throw XCTSkip("Explicit live API opt-in required.") }
        XCTAssertEqual(ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"],"1")
        _=try XCTUnwrap(UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? ""))
        if FirebaseApp.app() == nil { AppCheck.setAppCheckProviderFactory(PiyaliAppCheckFactory());FirebaseApp.configure() }
        XCTAssertEqual(FirebaseApp.app()?.options.projectID,"piyali-ios")
        let identity=IdentityService();try identity.create();try await FirebaseIdentityService.shared.ensure(identity)
        do {
            var learner=LearnerState();learner.target="es";learner.support="en"
            learner.place(Placement(level:"A1",score:18,source:"test",selectedIDs:[],updatedAt:Date()))
            let ai=AIService(),first=try await ai.immersionTasks(learner:learner,context:.null,onlyGoal:false)
            XCTAssertEqual(first.count,3);XCTAssertNotNil(DailyImmersion.normalize(.array(first),count:3))
            learner.applyImmersion(.init(target:learner.target,action:.batch,payload:learner.immersionScope().setting("tasks",.array(first))))
            learner.toggleImmersion(index:0);learner.editGoal("Read a short Spanish recipe privately at home")
            let fourth=try await ai.immersionTasks(learner:learner,context:.null,onlyGoal:true)
            XCTAssertEqual(fourth.count,1)
            learner.applyImmersion(.init(target:learner.target,action:.batch,payload:learner.immersionScope().setting("tasks",.array(fourth))))
            XCTAssertEqual(Array(learner.immersionBatch!["tasks"].array.prefix(3)),first);XCTAssertTrue(DailyImmersion.completed(learner.immersionBatch!,index:0));XCTAssertEqual(learner.totalXP,0)
            print("LIVE NATIVE: Immersion three-mission generation and goal-only update passed")
        } catch { try? await Auth.auth().currentUser?.delete();try? Auth.auth().signOut();throw error }
        try await Auth.auth().currentUser?.delete();try Auth.auth().signOut()
    }
    func testNativeAuthenticationGeminiResponsesAndVoice() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_LIVE_API_TESTS"] == "1" else { throw XCTSkip("Run scripts/test-live-api.py to verify configured native services.") }
        XCTAssertEqual(ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"],"1")
        _ = try XCTUnwrap(UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? ""))
        if FirebaseApp.app() == nil { AppCheck.setAppCheckProviderFactory(PiyaliAppCheckFactory()); FirebaseApp.configure() }
        XCTAssertEqual(FirebaseApp.app()?.options.projectID,"piyali-ios")
        let identity = IdentityService(); try identity.create()
        try await FirebaseIdentityService.shared.ensure(identity)
        XCTAssertEqual(Auth.auth().currentUser?.uid,identity.npub)
        do {
            print("LIVE NATIVE: Firebase identity authenticated")
            let config = AppConfiguration()
            let textModel = FirebaseAI.firebaseAI(backend:config.geminiBackend()).generativeModel(modelName:config.string("GeminiModel"),generationConfig:GenerationConfig(maxOutputTokens:128))
            let text = try await textModel.generateContent("Say hola, the Spanish greeting, in one short sentence.")
            XCTAssertFalse((text.text ?? "").isEmpty)
            print("LIVE NATIVE: Gemini text returned")
            let geminiExercise = try await AIService().structured(Exercise.self,prompt:"Create one short Pre-A1 Spanish greeting exercise as JSON with fields passage, question, choices, answer, explanation. Use English instructions and three choices.")
            XCTAssertFalse(geminiExercise.question.isEmpty); XCTAssertFalse(geminiExercise.answer.isEmpty)
            print("LIVE NATIVE: Gemini JSON exercise returned")
            var responsesConfig = config.values; responsesConfig["AIProvider"] = "responses"
            let ai = AIService(configuration:AppConfiguration(values:responsesConfig))
            let exercise = try await ai.structured(Exercise.self,prompt:"Create one short Pre-A1 Spanish greeting exercise. JSON fields: passage, question, choices, answer, explanation. Explain in English. Use three choices.")
            XCTAssertFalse(exercise.question.isEmpty); XCTAssertFalse(exercise.answer.isEmpty)
            print("LIVE NATIVE: Responses exercise returned")
            let subscription = SubscriptionService(); subscription.bind(identity)
            try await subscription.restoreWeb(); XCTAssertFalse(subscription.webAuthorized)
            print("LIVE NATIVE: Signed Patreon restore kept the unlinked account paywalled")
            var goalLearner = LearnerState(); goalLearner.editGoal("Order soup politely in Spanish")
            let goalRaw = try await AIService().goalBlueprint(learner:goalLearner,goal:goalLearner.goalBucket["activeGoal"])
            let goalBlueprint = GoalPractice.blueprint(raw:goalRaw,goal:goalLearner.goalBucket["activeGoal"],target:"es",day:CalendarDay.key(Date()),level:"Pre-A1",rating:800,progress:.object([:]))
            XCTAssertFalse(goalBlueprint["objective"].string.isEmpty); XCTAssertGreaterThanOrEqual(goalBlueprint["modes"].array.count,2)
            let rubric: Piyali.JSONValue = .object(["goalText":.string("Order soup politely in Spanish"),"objective":.string("Order soup politely"),"scenario":.string("At a restaurant, ask for one soup politely"),"lang":.string("es"),"successCriteria":.array([.string("Ask for soup"),.string("Use a polite expression")])])
            let verdict = try await AIService().goalVerdict(blueprint:rubric,response:"Quisiera una sopa, por favor.",context:"The learner independently answered the restaurant waiter.",support:"en")
            XCTAssertTrue(verdict.success); XCTAssertFalse(verdict.observation.isEmpty)
            print("LIVE NATIVE: Goal blueprint and action-based check returned")
            let lesson = Lesson(id:"lesson-pre-a1-1-1",title:.string("Family"),description:.string("Name a family member"),xpReward:80,modes:["realtime"],agenda:.object(["items":.array([.object(["id":.string("mama"),"goal":.string("Use mamá in a short sentence"),"evidence":.object(["criteria":.string("Produces a meaningful sentence with mamá")])])])]),content:.object([:]))
            let turn = try await AIService().tutorVerdict(lesson:lesson,item:TutorCourse.agenda(lesson)[0],learner:goalLearner,response:"Mi mamá se llama Ana.",context:"Tutor: Use mamá in a short sentence. Learner: Mi mamá se llama Ana.")
            XCTAssertTrue(turn.successful); XCTAssertTrue(turn.objectiveAdvanced); XCTAssertGreaterThanOrEqual(turn.confidence,0.55)
            print("LIVE NATIVE: Authored tutor turn evidence returned")
            let nativeUser = Firestore.firestore().collection("users").document(identity.npub)
            _ = try await nativeUser.collection("tutorLanguageLessons").whereField("targetLang",isEqualTo:"es").whereField("cefrLevel",isEqualTo:"Pre-A1").getDocuments(source:.server)
            _ = try await nativeUser.collection("voiceJourney").document("es").getDocument(source:.server)
            print("LIVE NATIVE: Authenticated tutor and journey reads returned")
            let model = LiveTutorService.model(for:goalLearner,configuration:config,goalBlueprint:goalBlueprint)
            let session = try await model.connect()
            print("LIVE NATIVE: Voice session connected")
            await session.sendTextRealtime(LiveTutorService.openingPrompt)
            let hasAudio = try await withThrowingTaskGroup(of:Bool.self) { group in
                group.addTask {
                    for try await message in session.responses {
                        if case .content(let content) = message.payload {
                        print("LIVE NATIVE: Voice frame with \(content.modelTurn?.parts.count ?? 0) parts, complete: \(content.isTurnComplete)")
                        for part in content.modelTurn?.parts ?? [] {
                            print("LIVE NATIVE: Part type \(String(reflecting:type(of:part)))")
                            if let audio = part as? InlineDataPart { print("LIVE NATIVE: Media \(audio.mimeType), bytes \(audio.data.count)") }
                        }
                    }
                        if case .content(let content) = message.payload,
                           (content.modelTurn?.parts ?? []).contains(where: { ($0 as? InlineDataPart)?.data.isEmpty == false }) { return true }
                    }
                    return false
                }
                group.addTask { try await Task.sleep(for:.seconds(30)); await session.close(); throw AppError.message("Live voice did not return audio within 30 seconds.") }
                let result = try await group.next() ?? false
                await session.close(); group.cancelAll(); return result
            }
            XCTAssertTrue(hasAudio)
            print("LIVE NATIVE: Voice audio received")
        } catch {
            try? await Auth.auth().currentUser?.delete(); try? Auth.auth().signOut(); throw error
        }
        // No Firestore data or subscription was created. Remove only this generated test Auth account.
        try await Auth.auth().currentUser?.delete(); try Auth.auth().signOut()
    }
}
