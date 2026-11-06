import XCTest
@testable import PiyaliCore

final class PracticeQuestionTests:XCTestCase {
    private let options:JSONValue = .object(["cefrLevel":.string("A1"),"direction":.string("target-to-support")])
    func testPhasedObjectsMergeWithoutLeakingAnswersIntoVisibleQuestion() throws {
        let question=try PracticeQuestion.parse(#"""
        ```json
        {"type":"mc","phase":"q","question":"Choose {a greeting}: \"hello\""}
        {"type":"mc","phase":"choices","choices":["hola","adiós"]}
        {"type":"mc","phase":"meta","answer":"hola","hint":"Say hello","translation":"greeting"}
        {"type":"done"}
        ```
        """#,module:.grammar,kind:"mc",options:options,target:"es",support:"en")
        XCTAssertEqual(question.questionText,"Choose {a greeting}: \"hello\"");XCTAssertEqual(question.payload["answer"].string,"hola")
        XCTAssertFalse(question.ready(.object([:])))
        XCTAssertTrue(question.ready(.object(["indices":.array([.number(0)])])))
        XCTAssertThrowsError(try GenerationObjects.parse("{\"type\":\"mc\""))
        XCTAssertThrowsError(try PracticeQuestion.parse("{\"type\":\"fill\",\"question\":\"___\"}",module:.grammar,kind:"mc",options:options,target:"es",support:"en"))
    }
    func testWordBanksPreserveRepeatedTokensAndDirectionAndListeningChangesSourceAudio() throws {
        let raw="""
        {"type":"translate","phase":"q","sentence":"Yo no digo que no"}
        {"type":"translate","phase":"answer","correctWords":["I","do","not","say","no"],"distractors":["I","yes"]}
        {"type":"done"}
        """
        let translation=try PracticeQuestion.parse(raw,module:.vocabulary,kind:"translate",options:options,target:"es",support:"en")
        XCTAssertEqual(translation.sourceLanguage,"es");XCTAssertEqual(translation.answerLanguage,"en");XCTAssertEqual(translation.audioLanguage,"es")
        XCTAssertEqual(translation.responseText(.object(["indices":.array([.number(0),.number(5)])]),bank:["I","do","not","say","no","I","yes"]),"I I")
        let listeningRaw=raw.replacingOccurrences(of:"Yo no digo que no",with:"I do not say no").replacingOccurrences(of:"[\"I\",\"do\",\"not\",\"say\",\"no\"]",with:"[\"Yo\",\"no\",\"digo\",\"que\",\"no\"]")
        let listening=try PracticeQuestion.parse(listeningRaw,module:.grammar,kind:"repeat",options:options.setting("direction",.string("support-to-target")).setting("isListening",.bool(true)),target:"es",support:"en")
        XCTAssertEqual(listening.audioText,"Yo no digo que no");XCTAssertEqual(listening.audioLanguage,"es");XCTAssertEqual(listening.answerLanguage,"es")
        XCTAssertNotEqual(listening.audioText,listening.payload["sentence"].string)
    }
    func testMatchingRequiresCompleteMapAndVocabularyUsesImplicitOriginalOrder() throws {
        let vocab=try PracticeQuestion.parse("{\"left\":[\"hola\",\"adiós\",\"gracias\"],\"right\":[\"hello\",\"goodbye\",\"thank you\"]}",module:.vocabulary,kind:"match",options:options,target:"es",support:"en")
        XCTAssertFalse(vocab.ready(.object(["pairs":.object(["0":.number(0)])])))
        XCTAssertTrue(vocab.ready(.object(["pairs":.object(["0":.number(2),"1":.number(0),"2":.number(1)])])))
        XCTAssertThrowsError(try PracticeQuestion.parse("{\"type\":\"match\",\"left\":[\"a\",\"b\"],\"right\":[\"x\",\"y\"],\"map\":[0,0]}",module:.grammar,kind:"match",options:options,target:"es",support:"en"))
    }
}
