import XCTest
@testable import PiyaliCore
final class WritingExerciseRulesTests:XCTestCase {
    func testActualKeyboardHandlersLayoutsAndClueCalculations()throws {
        struct Key:Decodable{let input:JSONValue,expected:String}
        struct Clue:Decodable{let input:JSONValue,expected:JSONValue}
        struct Layout:Decodable{let language:String,mode:String,expected:[[String]]}
        struct Fixture:Decodable{let keys:[Key],clues:[Clue],layouts:[Layout]}
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),fixture=try JSONDecoder().decode(Fixture.self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/writing-exercises.json"))),keyboard=WritingKeyboard(data:try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:root.appendingPathComponent("Piyali/Resources/writing-keyboard.json"))))
        XCTAssertEqual(fixture.keys.count,70);XCTAssertEqual(fixture.clues.count,60);XCTAssertEqual(fixture.layouts.count,10)
        for sample in fixture.keys{XCTAssertEqual(WritingKeyboard.press(sample.input["key"].string,text:sample.input["value"].string,disabled:sample.input["isDisabled"].boolean),sample.expected)}
        for sample in fixture.clues{XCTAssertEqual(WritingExerciseRules.clues(sample.input["question"]["clues"].array.map(\.string),revealed:Int(sample.input["revealedClues"].number),locked:sample.input["locked"].boolean).json,sample.expected)}
        for sample in fixture.layouts{XCTAssertTrue(keyboard.supported(sample.language));XCTAssertEqual(keyboard.layout(language:sample.language,mode:sample.mode),sample.expected)}
        struct Widths:Decodable{let widths:[String:Double]}
        let measured=try JSONDecoder().decode(Widths.self,from:Data(contentsOf:root.appendingPathComponent("docs/reference/writing-keyboard-widths.json")))
        XCTAssertEqual(measured.widths.count,312)
        for (key,width) in measured.widths{XCTAssertEqual(keyboard.keyWidth(key),width)}
        XCTAssertNil(keyboard.keyWidth("not-an-offered-key"))
        XCTAssertFalse(keyboard.supported("es"));XCTAssertEqual(keyboard.label("backspace",language:"ar"),"حذف")
    }
}
