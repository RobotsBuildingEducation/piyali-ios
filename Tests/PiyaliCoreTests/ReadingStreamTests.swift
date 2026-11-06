import XCTest
@testable import PiyaliCore

final class ReadingStreamTests:XCTestCase {
    func testTranslationCompletionAndFailureMatchOriginalCallback() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/reading-translation-outcomes.json"),rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url))
        XCTAssertEqual(rows.count,13)
        for row in rows {
            let input=row["input"],result=ReadingTranslationStream.resolve(input["chunks"].array.map(\.string).joined(),limit:3,failed:input["fail"].boolean || input["noProvider"].boolean,supportFallback:input["support"].string)
            XCTAssertEqual(result.visible,row["expected"]["visible"].boolean,input["name"].string)
            XCTAssertEqual(result.lines,row["expected"]["lines"] == .null ? nil:row["expected"]["lines"].array.map(\.string),input["name"].string)
        }
    }
    func testGenerationErrorUsesOriginalCopyAndEnglishFallback() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/reading.json"),fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url))["generationUnavailable"]
        for language in ["en","es","it","fr","de","ja","ar","zh"] {
            let expected=fixture[language].string.isEmpty ? fixture["en"].string:fixture[language].string
            XCTAssertFalse(expected.isEmpty);XCTAssertEqual(Reading.generationFailure(support:language),expected)
        }
    }
    func testDuplicateGuardMatchesOriginalSourceAtTimeAndTextBoundaries() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/reading-duplicates.json"),rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url))
        XCTAssertEqual(rows.count,13)
        for row in rows {
            let input=row["input"],actual=Reading.isDuplicateOfLast(title:input["title"].string,target:input["target"].string,last:input["lectures"].array.last,now:Date(timeIntervalSince1970:input["now"].number/1000))
            XCTAssertEqual(actual,row["expected"].boolean,input["name"].string)
        }
    }
    func testBackendOutcomesMatchSourceCleaningAndMissingQuestion() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/reading-backend-outcomes.json"),rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url))
        for row in rows {
            let payload=ReadingStreamDraft.backendPayload(row["input"],target:"es",support:"en",questionType:"text")
            XCTAssertEqual(payload == nil,row["expected"]["error"].boolean)
            guard let payload,let expected=row["expected"]["lectures"].array.first else{continue}
            let run=try ReadingRun(payload:payload,target:"es",support:"en",level:"A1",lessonID:nil,selection:.null,worth:.null,roll:0)
            XCTAssertEqual(run.title,expected["title"].string);XCTAssertEqual(run.text,expected["target"].string);XCTAssertEqual(run.takeaways,expected["takeaways"].array.map(\.string));XCTAssertEqual(run.pendingQuestionType,"text")
        }
    }
    func testSourceCompleteStreamWithoutDoneOrThreeTakeawaysIsAccepted() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/reading-outcomes.json")
        let rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url)),row=try XCTUnwrap(rows.first{$0["input"]["name"].string == "valid-question-no-done"})
        let snapshot=row["input"]["chunks"].array.map(\.string).joined();XCTAssertEqual(row["expected"]["lectures"].array.count,1)
        let payload=try XCTUnwrap(ReadingStreamDraft.sourcePayload(snapshot,target:"es",support:"en",questionType:"text")),run=try ReadingRun(payload:payload,target:"es",support:"en",level:"A1",lessonID:nil,selection:.null,worth:.null,roll:0)
        XCTAssertEqual(run.text,row["expected"]["lectures"].array[0]["target"].string);XCTAssertEqual(run.takeaways.count,1);XCTAssertEqual(run.question.question,"What grows?");XCTAssertNil(run.pendingQuestionType)
    }
    func testSourceIncompleteStreamRetainsMissingQuestionWithoutInventingAnswer() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/reading-outcomes.json"),rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url))
        for row in rows where !row["input"]["fail"].boolean {
            let snapshot=row["input"]["chunks"].array.map(\.string).joined(),source=row["expected"]["lectures"].array.first,payload=ReadingStreamDraft.sourcePayload(snapshot,target:"es",support:"en",questionType:"text")
            XCTAssertEqual(payload != nil,source != nil,row["input"]["name"].string);guard let source,let payload else{continue}
            let run=try ReadingRun(payload:payload,target:"es",support:"en",level:"A1",lessonID:nil,selection:.null,worth:.null,roll:0)
            XCTAssertEqual(run.title,source["title"].string);XCTAssertEqual(run.text,source["target"].string);XCTAssertEqual(run.takeaways,source["takeaways"].array.map(\.string));XCTAssertEqual(run.pendingQuestionType != nil,source["reviewQuestion"] == .null)
            if run.pendingQuestionType != nil {var state=LearnerState();state.target="es";state.support="en";state.saveReading(run);XCTAssertEqual(state.reviewReading(answer:"invented",correct:true,feedback:""),0);XCTAssertEqual(state.totalXP,0)}
        }
    }
    func testMissingQuestionPromptsMatchOriginalSource() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/reading-review-prompts.json"),rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url));XCTAssertEqual(rows.count,15)
        for row in rows {XCTAssertEqual(Reading.reviewPrompt(type:row["type"].string,text:row["text"].string,target:row["target"].string,support:row["support"].string),row["expected"].string,"\(row["type"].string) \(row["target"].string)")}
    }
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
