import Foundation
import FirebaseAILogic

@MainActor struct FlashcardProvider {
    var judge:(String)async throws->String
    var stream:(String,@escaping @MainActor (String)->Void)async throws->String
    var quote:(JSONValue,LearnerState)async throws->JSONValue
    static func native(_ ai:AIService)->Self {
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        if env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_LIVE_API_TESTS"] != "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,env["PIYALI_FLASHCARD_FIXTURE"] == "1" {
            return .init(judge:{prompt in try await Task.sleep(for:.milliseconds(150));return prompt.contains("WRONG_FIXTURE") ? "NO":"YES | 6"},stream:{_,update in try await Task.sleep(for:.milliseconds(100));update("ma");try await Task.sleep(for:.milliseconds(100));update("mamá");return "mamá"},quote:{card,state in try GeneratedQuestionWorth.fallback(level:card["cefrLevel"].string,learner:state,recipes:PracticeRecipes())})
        }
        #endif
        return .init(judge:{try await ai.responsesText($0)},stream:{try await ai.flashcardTextStream($0,onChunk:$1)},quote:{card,state in try await GeneratedQuestionWorth.assess(question:.object(["card":card,"task":.string("Recall and produce the target-language card answer")]),level:card["cefrLevel"].string,mode:"flashcard",learner:state,recipes:PracticeRecipes(),ai:ai)})
    }
}
extension AIService {
    func flashcardTextStream(_ prompt:String,onChunk:@escaping @MainActor (String)->Void)async throws->String {
        if FirebaseService.shared.configured {
            do {
                let model=FirebaseAI.firebaseAI(backend:configuration.geminiBackend()).generativeModel(modelName:configuration.string("GeminiModel"),generationConfig:GenerationConfig(maxOutputTokens:4096))
                var output=""
                for try await part in try model.generateContentStream(prompt) {try Task.checkCancellation();output += part.text ?? "";onChunk(output.trimmingCharacters(in:.whitespacesAndNewlines))}
                if !output.isEmpty{return output.trimmingCharacters(in:.whitespacesAndNewlines)}
            }catch{try Task.checkCancellation()}
        }
        return try await responsesStream(prompt,onChunk:onChunk)
    }
}
