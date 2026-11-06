import Foundation

@MainActor final class StorySpeechPolicy {
    private let engine:PracticeAssistancePolicy
    init(bundle:Bundle = .main)throws{guard let url=bundle.url(forResource:"story-speech-policy",withExtension:"js")else{throw PracticeRecipeFailure.unavailable};engine=try PracticeAssistancePolicy(source:String(contentsOf:url,encoding:.utf8))}
    func options(mode:StoryMode,target:String,language:String,user:JSONValue,awaiting:Bool)throws->JSONValue{try engine.runPolicy("options",.object(["mode":.string(mode.rawValue),"target":.string(target),"language":.string(language),"user":user,"awaiting":.bool(awaiting)]))["capture"]}
    func result(_ transcript:String)throws->JSONValue{try engine.runPolicy("result",.object(["transcript":.string(transcript)]))}
    func run(_ op:String,_ input:JSONValue)throws->JSONValue{try engine.runPolicy(op,input)}
}
