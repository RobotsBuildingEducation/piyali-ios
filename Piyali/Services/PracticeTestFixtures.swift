#if DEBUG
import Foundation

/// Explicit, isolated UI-test provider. The release app always uses live recipes.
enum PracticeTestFixtures {
    static var kind:String? {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_LIVE_API_TESTS"] != "1",env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { return nil }
        return env["PIYALI_PRACTICE_FIXTURE"]
    }
    private static var standardSamples:JSONValue{guard let url=Bundle.main.url(forResource:"standard-practice-fixture",withExtension:"json"),let data=try? Data(contentsOf:url),let value=try? JSONDecoder().decode(JSONValue.self,from:data)else{return .null};return value}
    private static var wordBankSamples:JSONValue{guard let url=Bundle.main.url(forResource:"word-bank-practice-fixture",withExtension:"json"),let data=try? Data(contentsOf:url),let value=try? JSONDecoder().decode(JSONValue.self,from:data)else{return .null};return value}
    static var bank:[String]?{guard let kind,kind.hasPrefix("wordbank:"),wordBankSamples[String(kind.dropFirst(9))] != .null else{return nil};return wordBankSamples[String(kind.dropFirst(9))]["bank"].array.map(\.string)}
    private static var oralSamples:JSONValue{guard let url=Bundle.main.url(forResource:"oral-practice-fixture",withExtension:"json"),let data=try? Data(contentsOf:url),let value=try? JSONDecoder().decode(JSONValue.self,from:data)else{return .null};return value}
    /// Finite offered-answer judge used only by explicitly opted-in offline gesture journeys.
    /// Production retains the source semantic provider and its alternative-answer rules.
    static func verdict(run:PracticeRun,prompt:String)->String? {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_LIVE_API_TESTS"] != "1",env["PIYALI_PRACTICE_JUDGE_FIXTURE"] == "offered-reference",let kind else{return nil}
        if kind.hasPrefix("oral:") {guard run.question.kind == "flashcard",oralSamples[String(kind.dropFirst(5))]["kind"].string == "flashcard",!prompt.isEmpty else{return nil};return run.response["text"].string == run.question.payload["answer"].string ? "YES | 6":"NO"}
        if kind.hasPrefix("wordbank:") {guard wordBankSamples[String(kind.dropFirst(9))]["kind"].string == run.question.kind,!prompt.isEmpty else{return nil};return run.answerText == run.question.strings("correctWords").joined(separator:" ") ? "YES":"NO"}
        if kind.hasPrefix("standard:") {
            let q=run.question,p=q.payload,r=run.response,choices=run.bank,words=r["indices"].array.compactMap{value->String? in let i=Int(value.number);return choices.indices.contains(i) ? choices[i]:nil}
            guard standardSamples[q.module.rawValue][String(kind.dropFirst(9))]["kind"].string == q.kind,!prompt.isEmpty,!prompt.contains("undefined")else{return nil}
            let correct:Bool
            switch q.kind{
            case "fill":correct=r["text"].string == p["answer"].string
            case "mc":correct=words == [p["answer"].string]
            case "ma":correct=Set(words)==Set(q.strings("answers"))
            case "match":correct=q.strings("left").indices.allSatisfy{i in let expected=q.module == .grammar ? Int(p["map"].array[i].number):i;return r["pairs"][String(i)] == .number(Double(expected))}
            default:return nil
            }
            return correct ? "YES":"NO"
        }
        guard kind == run.question.kind else{return nil}
        let q=run.question,p=q.payload,r=run.response,correct:Bool,title:String
        switch q.variant {
        case "sentence_detective":title="Sentence Detective";correct=r["tokenIndex"] == p["incorrectIndex"] && r["replacement"].string == p["answer"].string
        case "dialogue_fork","listen_difference":title=q.variant == "dialogue_fork" ? "Dialogue Fork":"Listen for the Difference";correct=r["selectedIndex"] == p["answerIndex"]
        case "morphology_forge":title="Morphology Forge";correct=run.answerText == p["answerWord"].string
        case "sentence_shapeshifter","three_clue_mystery","three_word_challenge":
            title=q.variant == "sentence_shapeshifter" ? "Sentence Shapeshifter":q.variant == "three_clue_mystery" ? "Three-Clue Mystery":"Three-Word Challenge"
            correct=r["text"].string == p["answer"].string || p["acceptableAnswers"].array.contains(r["text"]) || p["sampleAnswers"].array.contains(r["text"])
        case "word_neighborhoods":title="Word Neighborhoods";correct=p["groups"].array.enumerated().allSatisfy{index,group in group["items"].array.allSatisfy{r["assignments"][$0.string] == .number(Double(index))}}
        default:return nil
        }
        guard prompt.hasPrefix("Judge a "+title),(prompt.contains("Spanish") || prompt.contains("Japanese")),!prompt.contains("undefined")else{return nil}
        return correct ? "YES":"NO"
    }
    @MainActor static func question(module:PracticeRecipeModule,recipes:PracticeRecipes,target:String="es",support:String="en")->PracticeQuestion? {
        guard let kind else { return nil }
        if kind.hasPrefix("oral:") {let sample=oralSamples[String(kind.dropFirst(5))];guard sample != .null,sample["target"].string == target else{return nil};return try? PracticeQuestion(module:module,kind:sample["kind"].string,payload:sample["question"],options:sample["options"],target:target,support:support)}
        if target != "es" || support != "en" {
            guard ProcessInfo.processInfo.environment["PIYALI_WRITING_FIXTURE"] == "1",["sentence_shapeshifter","three_clue_mystery","three_word_challenge"].contains(String(kind.dropFirst(8))),let fallback=try? recipes.inspect("fallback",parameters:.object(["variant":.string(String(kind.dropFirst(8))),"moduleType":.string(module.rawValue),"targetLang":.string(target),"supportLang":.string(support)]))else{return nil}
            return try? PracticeQuestion(module:module,kind:kind,payload:fallback,options:.object(["cefrLevel":.string("A1")]),target:target,support:support)
        }
        if kind.hasPrefix("wordbank:") {let sample=wordBankSamples[String(kind.dropFirst(9))];guard sample != .null else{return nil};return try? PracticeQuestion(module:module,kind:sample["kind"].string,payload:sample["question"],options:sample["options"],target:target,support:support)}
        if kind.hasPrefix("standard:") {
            let sample=standardSamples[module.rawValue][String(kind.dropFirst(9))]
            guard sample != .null else{return nil}
            return try? PracticeQuestion(module:module,kind:sample["kind"].string,payload:sample["question"],options:.object(["cefrLevel":.string("A1")]),target:target,support:support)
        }
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
