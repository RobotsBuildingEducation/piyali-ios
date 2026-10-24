#if DEBUG
import Foundation

/// Explicit, isolated UI-test provider. The release app always uses live recipes.
enum PracticeTestFixtures {
    static var kind:String? {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { return nil }
        return env["PIYALI_PRACTICE_FIXTURE"]
    }
    @MainActor static func question(module:PracticeRecipeModule,recipes:PracticeRecipes)->PracticeQuestion? {
        guard let kind else { return nil }
        let options:JSONValue = .object(["cefrLevel":.string("A1"),"direction":.string("target-to-support"),"isListening":.bool(false)])
        let payload:JSONValue
        switch kind {
        case "flashcard":payload = .object(["concept":.string("Hello"),"answer":.string("Hola")])
        case "translate":payload = .object(["sentence":.string("Yo no digo que no"),"correctWords":.array(["I","do","not","say","no"].map(JSONValue.string)),"distractors":.array([.string("I"),.string("yes")])])
        case "match":payload = .object(["stem":.string("Match the greetings"),"left":.array(["hola","adiós","gracias"].map(JSONValue.string)),"right":.array(["hello","goodbye","thank you"].map(JSONValue.string)),"map":.array([.number(0),.number(1),.number(2)])])
        case "delight:natural_or_weird":payload = .object(["variant":.string("natural_or_weird"),"instruction":.string("Does this sentence sound natural?"),"sentence":.string("Yo somos Ana."),"isNatural":.bool(false),"correction":.string("Yo soy Ana."),"explanation":.string("Use soy with yo.")])
        default:
            guard kind.hasPrefix("delight:"),let fallback=try? recipes.inspect("fallback",parameters:.object(["variant":.string(String(kind.dropFirst(8))),"moduleType":.string(module.rawValue),"targetLang":.string("es"),"supportLang":.string("en")])) else { return nil }
            payload=fallback
        }
        return try? PracticeQuestion(module:module,kind:kind,payload:payload,options:options,target:"es",support:"en")
    }
}
#endif
