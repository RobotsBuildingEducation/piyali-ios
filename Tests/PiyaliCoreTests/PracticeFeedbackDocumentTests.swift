import XCTest
@testable import PiyaliCore
final class PracticeFeedbackDocumentTests:XCTestCase {
    func testListsKeepSeparateRowsAndInlineEmphasisWithoutRawMarkers(){
        let groups=PracticeFeedbackDocument.groups("**Answer:**\n\n* **hola** = hello\n* adiós = goodbye\n\nWhy it works.")
        XCTAssertEqual(groups.count,3);XCTAssertEqual(groups[1].blocks.map{String($0.text.characters)},["hola = hello","adiós = goodbye"]);XCTAssertEqual(groups[1].listDepth,1);XCTAssertEqual(groups[1].blocks.map(\.marker),["•","•"]);XCTAssertTrue(groups[1].blocks[0].text.runs.contains{$0.inlinePresentationIntent?.contains(.stronglyEmphasized) == true})
    }
    func testEscapedStarsAndFencedCodeAreNotConvertedIntoLists(){
        let groups=PracticeFeedbackDocument.groups("\\* literal star\n\n```text\n* code star\n```")
        XCTAssertEqual(groups.count,2);XCTAssertNil(groups[0].listID);XCTAssertEqual(String(groups[0].blocks[0].text.characters),"* literal star");XCTAssertTrue(groups[1].blocks[0].code);XCTAssertTrue(String(groups[1].blocks[0].text.characters).contains("* code star"))
    }
}
