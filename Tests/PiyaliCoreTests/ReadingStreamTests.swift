import XCTest
@testable import PiyaliCore

final class ReadingStreamTests:XCTestCase {
    func testDraftSnapshotsMatchSourceCallbacks() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/reading-stream.json")
        let rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url))
        XCTAssertEqual(rows.count,14)
        for row in rows {
            let expected=row["expected"],draft=ReadingStreamDraft.parse(row["snapshot"].string,target:row["target"].string,support:row["support"].string,includeTrailingRecord:row["includeTrailing"].boolean)
            if expected == .null {XCTAssertNil(draft);continue}
            XCTAssertEqual(draft?.title,expected["title"].string)
            XCTAssertEqual(draft?.text,expected["target"].string)
            XCTAssertEqual(draft?.takeaways,expected["takeaways"].array.map(\.string))
        }
    }
    func testIncompleteAndReplacedSnapshotsCannotBecomeSavedReading() throws {
        let title="{\"type\":\"title\",\"text\":\"A title\"}\n"
        XCTAssertNotNil(ReadingStreamDraft.parse(title,target:"en",support:"es"))
        XCTAssertThrowsError(try Reading.protocolPayload(title,questionType:"text"))
        XCTAssertNil(ReadingStreamDraft.parse("",target:"en",support:"es"))
        XCTAssertNil(ReadingStreamDraft.parse(String(repeating:"x",count:100_001),target:"en",support:"es"))
        let replacement="{\"type\":\"target\",\"text\":\"New text.\"}\n"
        XCTAssertEqual(ReadingStreamDraft.parse(replacement,target:"en",support:"es")?.text,"New text.")
        let learner=LearnerState();let before=learner.totalXP
        _=ReadingStreamDraft.parse(title,target:"en",support:"es")
        XCTAssertNil(learner.reading);XCTAssertEqual(learner.totalXP,before);XCTAssertTrue((learner.pendingChanges ?? []).isEmpty)
    }
    func testTranslationLinesMatchSourceAsChunksArrive() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/reading-translation-stream.json")
        let rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url))
        for row in rows {XCTAssertEqual(ReadingTranslationStream.lines(row["snapshot"].string,limit:3,includeTrailing:row["includeTrailing"].boolean),row["expected"].array.map(\.string))}
    }

}
