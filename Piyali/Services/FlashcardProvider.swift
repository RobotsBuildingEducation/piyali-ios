import Foundation
import FirebaseAILogic

@MainActor struct FlashcardProvider {
    var judge:(String)async throws->String
    var stream:(String,@escaping @MainActor (String)->Void)async throws->String
    var quote:(JSONValue,LearnerState)async throws->JSONValue
    var note:(String)async throws->String
    init(judge:@escaping (String)async throws->String,stream:@escaping (String,@escaping @MainActor (String)->Void)async throws->String,quote:@escaping (JSONValue,LearnerState)async throws->JSONValue,note:((String)async throws->String)?=nil){
        self.judge=judge;self.stream=stream;self.quote=quote;self.note=note ?? judge
    }
    static func native(_ ai:AIService)->Self {
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        if env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_LIVE_API_TESTS"] != "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,env["PIYALI_FLASHCARD_FIXTURE"] == "1" {
            let note:((String)async throws->String)? = env["PIYALI_FLASHCARD_NOTE_FIXTURE"] == "1" ? {_ in
                if let ms=Int(env["PIYALI_FLASHCARD_NOTE_DELAY_MS"] ?? ""),(1...15000).contains(ms){try await Task.sleep(for:.milliseconds(ms))}
                return "{\"example\":\"Mi mamá vive cerca.\",\"summary\":\"Use mamá to talk about your mother.\"}"
            }:nil
            return .init(judge:{prompt in try await Task.sleep(for:.milliseconds(150));if env["PIYALI_FLASHCARD_NOTE_FIXTURE"] == "1",prompt.contains("Generate a study note") {return "{\"example\":\"Mi mamá vive cerca.\",\"summary\":\"Use mamá to talk about your mother.\"}"};return prompt.contains("WRONG_FIXTURE") ? "NO":"YES | 6"},stream:{_,update in try await Task.sleep(for:.milliseconds(100));update("ma");try await Task.sleep(for:.milliseconds(100));update("mamá");return "mamá"},quote:{card,state in try GeneratedQuestionWorth.fallback(level:card["cefrLevel"].string,learner:state,recipes:PracticeRecipes())},note:note)
        }
        #endif
        return .init(judge:{try await ai.responsesText($0)},stream:{try await ai.flashcardTextStream($0,onChunk:$1)},quote:{card,state in try await GeneratedQuestionWorth.assess(question:.object(["card":card,"task":.string("Recall and produce the target-language card answer")]),level:card["cefrLevel"].string,mode:"flashcard",learner:state,recipes:PracticeRecipes(),ai:ai)},note:{try await ai.studyNoteText($0)})
    }
}
extension AIService {
    func studyNoteText(_ prompt:String)async throws->String {try await sourceResponsesText(prompt)}
    func sourceResponsesText(_ prompt:String)async throws->String {
        // Source noteGeneration uses callResponses: Gemini stream first, then
        // Responses on failure. A normally empty stream reaches the note parser.
        if configuration.string("AIProvider") == "gemini",FirebaseService.shared.configured {
            do {
                let model=FirebaseAI.firebaseAI(backend:configuration.geminiBackend()).generativeModel(modelName:configuration.string("GeminiModel"),generationConfig:GenerationConfig(maxOutputTokens:4096))
                var output=""
                for try await part in try model.generateContentStream(prompt){try Task.checkCancellation();output += part.text ?? ""}
                return output
            }catch{try Task.checkCancellation()}
        }
        return try await responsesText(prompt)
    }
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
