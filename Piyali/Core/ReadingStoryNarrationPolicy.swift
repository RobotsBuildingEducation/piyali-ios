import Foundation

/// Original Reading and Stories request/voice expressions and verbatim narration session.
final class ReadingStoryNarrationPolicy {
    private let policy:PracticeAssistancePolicy
    init(bundle:Bundle = .main)throws{
        guard let url=bundle.url(forResource:"reading-story-narration",withExtension:"js")else{throw PracticeRecipeFailure.unavailable}
        policy=try PracticeAssistancePolicy(source:String(contentsOf:url,encoding:.utf8))
    }
    func request(_ operation:String,_ input:JSONValue)throws->JSONValue{try policy.runPolicy(operation,input)}
}
