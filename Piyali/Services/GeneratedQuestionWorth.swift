import Foundation

@MainActor enum GeneratedQuestionWorth {
    static func assess(question:JSONValue,level:String,mode:String,learner:LearnerState,recipes:PracticeRecipes,ai:AIService) async throws ->JSONValue {
        var parameters:JSONValue = .object(["question":question,"questionLevel":.string(level),"targetLang":.string(learner.target),"mode":.string(mode),"user":learner.recipeUser])
        let prompt=try recipes.inspect("difficultyPrompt",parameters:parameters).string
        do {
            let raw=try await ai.text(prompt,json:true);try Task.checkCancellation()
            let score=try recipes.inspect("parseDifficulty",parameters:.object(["raw":.string(raw)]))
            if score != .null { parameters=parameters.setting("assessment",.object(["difficultyScore":score])) }
        } catch is CancellationError { throw CancellationError() } catch { /* Original policy quotes a marked CEFR fallback during an outage. */ }
        return try recipes.inspect("worth",parameters:parameters)
    }
    static func fallback(level:String,learner:LearnerState,recipes:PracticeRecipes) throws ->JSONValue {
        try recipes.inspect("worth",parameters:.object(["questionLevel":.string(level),"targetLang":.string(learner.target),"user":learner.recipeUser]))
    }
}
