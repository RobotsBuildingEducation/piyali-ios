import XCTest
@testable import PiyaliCore

final class PracticeRecipesTests:XCTestCase {
    private var root:URL { URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent() }
    @MainActor func testOriginalPromptFixturesAgreeBetweenExportAndNativeJavaScriptCore() async throws {
        struct Fixture:Decodable { let module:PracticeRecipeModule;let kind:String;let parameters:JSONValue;let expected:String }
        let fixtures=try ContentLibrary.decode([Fixture].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/practice-prompts.json.gz"))
        let engine=try PracticeRecipes(source:root.appendingPathComponent("Piyali/Resources/practice-recipes.js"))
        XCTAssertEqual(fixtures.count,136)
        for sample in fixtures { XCTAssertEqual(try engine.build(module:sample.module,kind:sample.kind,parameters:sample.parameters),sample.expected,"\(sample.module) / \(sample.kind)") }
    }
    @MainActor func testOriginalQuizSelectorCoversEveryFormatAndKeepsRepeatDirectionsConsistent() async throws {
        let engine=try PracticeRecipes(source:root.appendingPathComponent("Piyali/Resources/practice-recipes.js"))
        let context:JSONValue = .object(["lesson":.object(["id":.string("quiz-a1"),"isFinalQuiz":.bool(true),"cefrLevel":.string("A1")]),"targetLang":.string("es"),"user":.object([:])])
        let options=try (0..<16).map { try engine.select(module:.grammar,context:context,randomSeed:UInt32($0+1)) }
        XCTAssertEqual(Set(options.map { $0["exerciseType"].string }).count,16);XCTAssertFalse(options.contains { $0["exerciseType"].string == "flashcard" });XCTAssertTrue(options.allSatisfy { $0["cefrLevel"].string == "A1" })
        let repeated=try XCTUnwrap(options.first { $0["exerciseType"].string == "repeat" })
        XCTAssertEqual(repeated["direction"].string,repeated["isListening"].boolean ? "support-to-target" : repeated["repeatMode"].string == "target-tts-support-bank" ? "target-to-support" : "support-to-target")
    }
    @MainActor func testOriginalDelightReadinessVerdictsAndClueRewardsRemainDistinct() async throws {
        let engine=try PracticeRecipes(source:root.appendingPathComponent("Piyali/Resources/practice-recipes.js"))
        let question:JSONValue = .object(["variant":.string("natural_or_weird"),"isNatural":.bool(false)])
        let correct:JSONValue = .object(["question":question,"response":.object(["choice":.bool(false)])])
        XCTAssertEqual(try engine.inspect("grade",parameters:correct),.bool(true));XCTAssertEqual(try engine.inspect("grade",parameters:correct.setting("response",.object(["choice":.bool(true)]))),.bool(false))
        let generative:JSONValue = .object(["question":.object(["variant":.string("three_word_challenge")]),"response":.object(["text":.string("a sentence")])])
        XCTAssertEqual(try engine.inspect("grade",parameters:generative),.null,"Generated answer keys do not exhaust valid language responses.")
        for (clues,expected) in [(1,10),(2,7),(3,4)] {
            let parameters:JSONValue = .object(["question":.object(["variant":.string("three_clue_mystery")]),"response":.object([:]),"options":.object(["revealedClues":.number(Double(clues))])])
            XCTAssertEqual(try engine.inspect("xp",parameters:parameters),.number(Double(expected)))
            XCTAssertEqual(try engine.inspect("xp",parameters:parameters.setting("options",.object(["isFinalQuiz":.bool(true)]))),.number(0))
        }
    }
    @MainActor func testPerCallProgressDoesNotLeakToAnotherLearnerAndUnknownFormatsFail() async throws {
        let engine=try PracticeRecipes(source:root.appendingPathComponent("Piyali/Resources/practice-recipes.js"))
        let basic:JSONValue = .object(["cefrLevel":.string("A1"),"targetLang":.string("es"),"supportLang":.string("en"),"appUILang":.string("en"),"showTranslations":.bool(true),"recentGood":.array([])])
        let user:JSONValue = .object(["learningIntelligence":.object(["es":.object(["elo":.object(["rating":.number(1810),"scaleVersion":.number(4)])])])])
        let advanced=try engine.build(module:.grammar,kind:"fill",parameters:basic.setting("user",user))
        XCTAssertTrue(advanced.contains("1810"))
        let fresh=try engine.build(module:.grammar,kind:"fill",parameters:basic)
        XCTAssertFalse(fresh.contains("1810"))
        XCTAssertThrowsError(try engine.build(module:.grammar,kind:"not-a-format",parameters:basic))
        XCTAssertFalse(fresh.isEmpty)
    }
}
