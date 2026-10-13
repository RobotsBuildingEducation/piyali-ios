import XCTest
import FirebaseCore
import FirebaseAppCheck
import FirebaseAuth
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
            let model = LiveTutorService.model(for:LearnerState(),configuration:config)
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
