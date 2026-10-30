import XCTest
@testable import PiyaliCore
final class OralAssistancePolicyTests:XCTestCase{
    func testOriginalSpeakingAndFlashcardExplanationRequests()throws{
        struct Case:Decodable{let operation:String,input:JSONValue,output:JSONValue}
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),policy=try OralAssistancePolicy(source:String(contentsOf:root.appendingPathComponent("Piyali/Resources/oral-assistance.js"),encoding:.utf8)),cases=try JSONDecoder().decode([Case].self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/oral-assistance.json")));XCTAssertEqual(cases.count,112)
        for c in cases{XCTAssertEqual(try policy.runPolicy(c.operation,c.input),c.output);XCTAssertFalse(c.output["prompt"].string.contains("undefined"))}
    }
}
