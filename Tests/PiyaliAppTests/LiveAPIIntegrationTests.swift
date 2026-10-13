import XCTest
import FirebaseCore
import FirebaseAppCheck
import FirebaseAuth
import FirebaseFirestore
import FirebaseAILogic
@testable import Piyali

/// Explicit opt-in only. Uses an isolated test identity, bounded prompts and no paid access grant.
@MainActor final class LiveAPIIntegrationTests: XCTestCase {
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
