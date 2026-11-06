import XCTest
@testable import PiyaliCore
final class PracticeAssistanceTests:XCTestCase {
    func testOriginalHelpAndWrongAnswerExplanationsAcrossAllNineFormatsAndFourLanguagePairs()throws {
        struct Sample:Decodable{let operation:String,input:JSONValue,expected:JSONValue}
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),policy=try PracticeAssistancePolicy(source:String(contentsOf:root.appendingPathComponent("Piyali/Resources/practice-assistance-policy.js")))
        let samples=try JSONDecoder().decode([Sample].self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/practice-assistance.json")))
        XCTAssertEqual(samples.count,144)
        for sample in samples {let actual=try policy.runPolicy(sample.operation,sample.input);XCTAssertEqual(actual,sample.expected);if sample.operation == "assistant"{XCTAssertTrue(actual["prompt"].string.contains("Start with the exact answer"))}}
    }
}
