import XCTest
import FirebaseCore
import FirebaseAppCheck
import FirebaseAuth
import FirebaseFirestore
import FirebaseAILogic
@testable import Piyali

/// Explicit opt-in only. Uses an isolated test identity, bounded prompts and no paid access grant.
@MainActor final class LiveAPIIntegrationTests: XCTestCase {
    func testNativeAuthenticationGeminiResponsesAndVoice() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_LIVE_API_TESTS"] == "1" else { throw XCTSkip("Run scripts/test-live-api.py to verify configured native services.") }
        XCTAssertEqual(ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"],"1")
        _ = try XCTUnwrap(UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? ""))
        XCTAssertNil(FirebaseApp.app())
        AppCheck.setAppCheckProviderFactory(PiyaliAppCheckFactory()); FirebaseApp.configure()
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
