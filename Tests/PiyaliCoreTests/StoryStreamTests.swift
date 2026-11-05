import XCTest
@testable import PiyaliCore

final class StoryStreamTests:XCTestCase {
    func testSnapshotsFromWebSpeakingCallback() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/story-stream.json")
        let rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url))
        for row in rows {
            let actual=StoryStreamDraft.speaking(row["snapshot"].string,includeTrailingRecord:row["includeTrailing"].boolean)
            let expected=row["expected"].array
            XCTAssertEqual(actual.map(\.target),expected.map { $0["tgt"].string })
            XCTAssertEqual(actual.map(\.speaker),expected.map { $0["character"].string })
            XCTAssertEqual(actual.map { $0.support ?? "" },expected.map { $0["sup"].string })
            XCTAssertEqual(actual.map { $0.gender ?? "" },expected.map { $0["gender"].string })
        }
    }
    func testPartialRecordsAndInvalidLinesAreNotRunsOrRewards() {
        let first="{\"type\":\"sentence\",\"character\":\"Sheilfer\",\"tgt\":\"Hola.\"}\n"
        let partial="{\"type\":\"sentence\",\"character\":\"Yoruichi\",\"tgt\":\"Buenos"
        XCTAssertEqual(StoryStreamDraft.speaking(first+"{broken}\n"+partial).map(\.target),["Hola."])
        XCTAssertEqual(StoryStreamDraft.speaking(first+partial+" días.\"}",includeTrailingRecord:true).map(\.target),["Hola.","Buenos días."])
        let run=StoryRun(provisionalID:UUID(),turns:StoryStreamDraft.speaking(first),target:"es",support:"en",level:"A1",lessonID:nil,title:"Practice",worth:.null)
        var learner=LearnerState();learner.target="es";learner.support="en";learner.saveStory(run)
        XCTAssertNil(learner.story);XCTAssertEqual(learner.practiceStoryLine(words:"Hola."),0);XCTAssertEqual(learner.finishStory(),0);XCTAssertEqual(learner.totalXP,0)
    }
}
