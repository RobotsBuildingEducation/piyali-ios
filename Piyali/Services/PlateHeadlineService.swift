import Foundation
import FirebaseAILogic

extension AIService {
    func plateHeadline(_ prompt:String,onProvider:((String)->Void)?=nil,onChunk:@escaping @MainActor (String)->Void) async throws->String {
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        if env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_LIVE_API_TESTS"] != "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil {
            guard ["stream","slow"].contains(env["PIYALI_HEADLINE_FIXTURE"] ?? "") else{throw AppError.message("Offline headline fixture unavailable.")}
            let french=prompt.contains("strictly in French"),arabic=prompt.contains("strictly in Arabic")
            try await Task.sleep(for:.milliseconds(600))
            onChunk(french ? "Demande" : arabic ? "تحدث" : "Ask about")
            try await Task.sleep(for:env["PIYALI_HEADLINE_FIXTURE"] == "slow" ? .seconds(10) : .milliseconds(1200))
            let text=french ? "Demande ton chemin avec confiance." : arabic ? "تحدث بثقة عن خططك لهذا اليوم." : "Ask about today's plans with confidence."
            onProvider?("fixture");onChunk(text);return "```text\n\""+text+"\"\n```"
        }
        #endif
        if configuration.string("AIProvider") == "gemini",FirebaseService.shared.configured {
            do {
                let model=FirebaseAI.firebaseAI(backend:configuration.geminiBackend()).generativeModel(modelName:configuration.string("GeminiModel"),generationConfig:GenerationConfig(maxOutputTokens:4096,responseMIMEType:"text/plain"))
                var output=""
                for try await chunk in try model.generateContentStream(prompt) {try Task.checkCancellation();output += chunk.text ?? "";onChunk(output)}
                if !output.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty{onProvider?("gemini");return output}
            }catch{try Task.checkCancellation()}
        }
        let text=try await responsesStream(prompt,onChunk:onChunk);try Task.checkCancellation();onProvider?("responses");return text
    }
}

extension AppModel {
    func plateHeadlinePrompt(scope:PlateHeadlineScope)throws->String {
        let state=learner,policy=try PlateHeadlinePolicy()
        let units=(try? ContentLibrary.load(JSONValue.self,name:"headline-curriculum-"+PlateHeadline.targetKey(scope.target))[state.level].array) ?? []
        var lessons:[String:JSONValue]=[:]
        for unit in units {for lesson in unit["lessons"].array {let key=scope.target+":"+lesson["id"].string;if state.completed.contains(key) || state.lessonWork?[key]?.status == .completed {lessons[lesson["id"].string] = .object(["completed":.bool(true)])}}}
        let courses=plateCourses.map{JSONValue.object(["kind":.string($0.kind),"count":.number(Double($0.count)),"target":.number(Double($0.target))])}
        let user:JSONValue = .object(["progress":.object(["languageLessons":.object([scope.target:.object(lessons)])])])
        let summary=try policy.run("summary",.object(["courses":.array(courses),"user":user,"targetLang":.string(scope.target),"levelUnits":.array(units)]))
        return try policy.run("prompt",.object(["targetLang":.string(scope.target),"appLanguage":.string(scope.support),"taskSummary":summary])).string
    }
    func savePlateHeadline(_ value:PlateHeadline,scope:PlateHeadlineScope) {
        guard identity.npub == scope.account,learner.target == scope.target,learner.support == scope.support,CalendarDay.key(Date()) == scope.day else{return}
        learner.storePlateHeadline(value,target:scope.target);persist()
    }
}
