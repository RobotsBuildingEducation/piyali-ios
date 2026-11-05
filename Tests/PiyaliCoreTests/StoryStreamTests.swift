import XCTest
@testable import PiyaliCore

final class StoryStreamTests:XCTestCase {
    func testEpisodeSnapshotsFromWebCallbackAndUnsafeRecords() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/story-episode-stream.json")
        let rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url))
        for row in rows {
            let draft=StoryStreamDraft.episode(row["snapshot"].string,includeTrailingRecord:row["includeTrailing"].boolean),expected=row["expected"]
            if expected == .null {XCTAssertNil(draft);continue}
            let value=try XCTUnwrap(draft);XCTAssertEqual(value.value.title,expected["title"].string);XCTAssertEqual(value.value.segments.count,expected["segments"].array.count)
            for (index,segment) in value.value.segments.enumerated() {
                let source=expected["segments"].array[index]
                XCTAssertEqual(segment.turns.map(\.speaker),source["turns"].array.map { $0["speaker"].string })
                XCTAssertEqual(segment.turns.map(\.target),source["turns"].array.map { $0["target"].string })
                XCTAssertEqual(segment.turns.map { $0.support ?? "" },source["turns"].array.map { $0["support"].string })
                XCTAssertEqual(value.ready.contains(index),source["question"] != .null)
                if value.ready.contains(index) {XCTAssertEqual(segment.question.prompt,source["question"]["prompt"].string);XCTAssertEqual(segment.question.answer,source["question"]["answer"].array.map {Int($0.number)})}
            }
        }
        let unsafe="{\"type\":\"turn\",\"segment\":1000000,\"target\":\"hola\"}\n{\"type\":\"turn\",\"target\":\"hola\"}\n{\"type\":\"question\",\"question\":{\"type\":\"choice\",\"prompt\":\"Pick\",\"options\":[\"a\",\"b\"],\"answer\":[99],\"explanation\":\"x\"}}\n"
        let draft=try XCTUnwrap(StoryStreamDraft.episode(unsafe));XCTAssertEqual(draft.value.segments.count,1);XCTAssertTrue(draft.ready.isEmpty)
        let run=StoryRun(provisionalID:UUID(),episode:draft.value,ready:draft.ready,mode:.radio,target:"es",support:"en",level:"A1",lessonID:nil,worth:.null)
        var learner=LearnerState();learner.target="es";learner.saveStory(run);XCTAssertNil(learner.story);XCTAssertEqual(learner.finishStory(),0)
        let scalar="{\"type\":\"turn\",\"target\":\"hola\"}\n{\"type\":\"question\",\"question\":{\"type\":\"choice\",\"prompt\":\"Pick\",\"options\":[\"a\",\"b\"],\"answer\":1,\"explanation\":\"x\"}}\n"
        let normalized=try XCTUnwrap(StoryStreamDraft.episode(scalar));XCTAssertTrue(normalized.ready.contains(0));XCTAssertEqual(normalized.value.segments[0].question.answer,[1])
        XCTAssertEqual(StoryStreamDraft.normalizeSingleAnswer(.object(["type":.string("select_words"),"answer":.number(1)]))["answer"],.number(1))
    }
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

extension StoryStreamTests {
    func testSourceOneLineStreamCanBeCreditedOnceAndRestored() throws {
        let snapshot="{\"type\":\"sentence\",\"tgt\":\"Hola.\"}\n",payload=try XCTUnwrap(StoryStreamDraft.speakingPayload(snapshot,completed:false,title:"Practice"))
        let run=try StoryRun(payload:payload,mode:.speaking,target:"es",support:"en",level:"A1",lessonID:nil,worth:ConversationPractice.worth(rating:800,level:"A1"),tutorial:true,sourceSpeakingStream:true)
        var learner=LearnerState();learner.target="es";learner.support="en";learner.saveStory(run)
        XCTAssertEqual(learner.practiceStoryLine(words:"Hola.",confidence:0.9),2);XCTAssertEqual(learner.practiceStoryLine(words:"Hola.",confidence:0.9),0)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(learner));XCTAssertEqual(restored.totalXP,2);XCTAssertEqual(restored.story?.passedLines,[0]);XCTAssertEqual(restored.story?.sentences.count,1)
    }
    func testSourceSpeakingStreamCompletionAndFailureOutcomes() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/story-speak-stream-outcomes.json")
        let rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url));XCTAssertEqual(rows.count,8)
        for row in rows {let input=row["input"],expected=row["expected"],snapshot=input["chunks"].array.map(\.string).joined(),completed = !input["fail"].boolean
            let turns=StoryStreamDraft.speaking(snapshot,includeTrailingRecord:completed),sourceUsedStream=expected["fallback"].number == 0
            XCTAssertEqual(!turns.isEmpty,sourceUsedStream,input["name"].string)
            let payload=StoryStreamDraft.speakingPayload(snapshot,completed:completed,title:"Practice");XCTAssertEqual(payload != nil,sourceUsedStream,input["name"].string)
            if sourceUsedStream {
                XCTAssertEqual(turns.map(\.target),expected["sentences"].array.map{$0["tgt"].string},input["name"].string);XCTAssertEqual(turns.map(\.speaker),expected["sentences"].array.map{$0["character"].string},input["name"].string)
                let run=try StoryRun(payload:try XCTUnwrap(payload),mode:.speaking,target:"es",support:"en",level:"A1",lessonID:nil,worth:.null,tutorial:true,sourceSpeakingStream:true)
                XCTAssertEqual(run.sentences.map(\.target),turns.map(\.target));XCTAssertEqual(payload?["nativeSpeakingStream"].string,completed ? "completed":"interrupted")
            }
        }
    }
}
