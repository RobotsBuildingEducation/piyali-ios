import XCTest
@testable import PiyaliCore
final class LessonCardRulesTests:XCTestCase {
    func testSourceRetryAndCyclicDeckNavigation()throws {
        struct Case:Decodable{let input:JSONValue,expected:JSONValue}
        let file=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/oral-interactions.json"),cases=try JSONDecoder().decode([Case].self,from:Data(contentsOf:file));XCTAssertEqual(cases.count,42)
        for c in cases{let p=c.input,s=p["state"];if p["operation"].string == "retry"{let result=LessonCardRules.retry(.object(["text":s["text"],"recognizedText":s["recognized"],"typedText":s["text"]]));XCTAssertEqual(result["text"],c.expected["text"]);XCTAssertEqual(result["recognizedText"],c.expected["recognized"])}else{XCTAssertEqual(LessonCardRules.cycle(index:Int(s["index"].number),count:Int(p["count"].number),forward:p["operation"].string == "next"),Int(c.expected["index"].number));XCTAssertFalse(c.expected["flipped"].boolean)}}
    }
}
