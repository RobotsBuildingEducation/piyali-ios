import Foundation

@MainActor struct TutorProvider {
    var judge:(String)async throws->JSONValue
    var quote:(JSONValue,String,LearnerState)async throws->JSONValue
    var translate:(String,String)async throws->JSONValue = {_,_ in .null}
    static func native(_ ai:AIService)->Self {
        .init(judge:{try await ai.structured(JSONValue.self,prompt:$0)},quote:{question,level,learner in try await GeneratedQuestionWorth.assess(question:question,level:level,mode:"tutor",learner:learner,recipes:PracticeRecipes(),ai:ai)},translate:{prompt,text in try await ai.structured(JSONValue.self,prompt:prompt+"\n\n"+text)})
    }
}
