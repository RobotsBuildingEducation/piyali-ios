import Foundation

@MainActor struct TutorProvider {
    var judge:(String)async throws->JSONValue
    var quote:(JSONValue,String,LearnerState)async throws->JSONValue
    var translate:(String,String)async throws->JSONValue = {_,_ in .null}
    var goal:(JSONValue,String,String,String)async throws->GoalVerdict = {_,_,_,_ in throw PracticeRecipeFailure.unavailable}
    static func native(_ ai:AIService)->Self {
        .init(judge:{try await ai.structured(JSONValue.self,prompt:$0)},quote:{question,level,learner in try await GeneratedQuestionWorth.assess(question:question,level:level,mode:"tutor",learner:learner,recipes:PracticeRecipes(),ai:ai)},translate:{prompt,text in try await ai.structured(JSONValue.self,prompt:prompt+"\n\n"+text)},goal:{try await ai.goalVerdict(blueprint:$0,response:$1,context:$2,support:$3)})
    }
}
