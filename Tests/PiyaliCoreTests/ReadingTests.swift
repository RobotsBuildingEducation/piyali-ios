import XCTest
@testable import PiyaliCore

final class ReadingTests:XCTestCase {
    private func fixture() throws -> JSONValue { try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/reading.json"))) }
    func testReferenceQualityChecksPreserveDocumentsAndRejectScriptsAndRepeats() throws {
        let samples=try fixture()["quality"].array;XCTAssertEqual(samples.count,67)
        for sample in samples { let options=sample["options"];XCTAssertEqual(Reading.issues(candidate:sample["candidate"],recent:options["recentEntries"].array,selection:options["formatSelection"],tutorial:options["isTutorial"].boolean),sample["expected"].array.map(\.string),sample.json) }
    }
    func testReferenceFormatChoicesAndSubjectOrderAcrossSevenLevels() throws {
        let samples=try fixture()["selections"].array;XCTAssertEqual(samples.count,84)
        for sample in samples { let options=sample["options"],content:JSONValue = .object(["prompt":options["promptText"],"readingSubjects":options["readingSubjects"]]);XCTAssertEqual(Reading.select(content:content,level:options["cefrLevel"].string,recent:[],lesson:options["lessonId"].string,roll:sample["roll"].number),sample["expected"],sample.json) }
    }
    func testReferenceQuestionNormalizationRequiresFourDistinctChoicesAndARealAnswer() throws {
        for sample in try fixture()["questions"].array {
            let q=ReadingQuestion(sample["input"]),expected=sample["expected"]
            if expected == .null { XCTAssertNil(q,sample.json) }
            else { let q=try XCTUnwrap(q);XCTAssertEqual(q.type,expected["type"].string);XCTAssertEqual(q.question,expected["question"].string);XCTAssertEqual(q.answer,expected["answer"].string);XCTAssertEqual(q.options,expected["options"].array.map(\.string)) }
        }
    }
    func testReferenceFiveToEightXPIsLatchedWithinRange() throws {
        for sample in try fixture()["xp"].array { XCTAssertEqual(Reading.award(roll:sample["roll"].number),Int(sample["expected"].number)) }
        XCTAssertEqual(Reading.award(roll:.nan),5)
    }
    private func readingRun(text:String = "Mi libreta verde está sobre la mesa. Dibujo una flor roja y escribo su nombre. Mañana mi hermana quiere dibujar conmigo.",tutorial:Bool = false) throws -> ReadingRun {
        let payload:JSONValue = .object(["title":.string("La libreta"),"target":.string(text),"takeaways":.array(["A notebook","A flower","A plan"].map(JSONValue.string)),"reviewQuestion":.object(["type":.string("text"),"question":.string("What color is the flower?"),"answer":.string("red")])])
        return try ReadingRun(payload:payload,target:"es",support:"en",level:"A1",lessonID:"reading-unit",selection:.null,worth:ConversationPractice.worth(rating:800,level:"A1"),roll:0.7,tutorial:tutorial)
    }
    func testMissRetriesThenClaimsOneRewardAcrossReviewMethodsAndPersists() throws {
        var state=LearnerState();state.saveReading(try readingRun());let initial=state.rating
        XCTAssertEqual(state.reviewReading(answer:"blue",correct:false,feedback:"Try again"),0);XCTAssertEqual(state.rating,initial);XCTAssertEqual(state.activeMemories.count,1)
        XCTAssertEqual(state.reviewReading(answer:"red",correct:true,feedback:"Correct"),7)
        XCTAssertEqual(state.reviewReading(answer:"Mi libreta",correct:false,feedback:"Transcript",speech:true),0)
        XCTAssertEqual(state.totalXP,7);XCTAssertEqual(state.gradedByLanguage?["es"],1)
        let event=try XCTUnwrap(state.pendingChanges?.first { $0.source == .readingTurn })
        let patch=WebProgressContract.rootPatch(fields:[:],month:[:],change:event)
        XCTAssertEqual(JSONValue.foundation(patch.root["learningIntelligence"] ?? [:])["es"]["performanceSummary"]["lastMode"],.string("reading"))
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state));XCTAssertTrue(restored.reading!.awarded)
    }
    func testReadAloudEarnsRewardRegardlessOfTranscriptMatchAndDoesNotChangeScore() throws {
        var state=LearnerState();state.saveReading(try readingRun());let initial=state.rating
        XCTAssertEqual(state.reviewReading(answer:"short recognized fragment",correct:false,feedback:"Compare words",speech:true),7)
        XCTAssertEqual(state.reviewReading(answer:"red",correct:true,feedback:"Correct"),0)
        XCTAssertEqual(state.rating,initial);XCTAssertNil(state.gradedByLanguage?["es"])
        XCTAssertEqual(state.pendingChanges?.first?.source,.readingSpeech)
        XCTAssertEqual(state.pendingChanges?.first?.readingProof?["xpAwarded"],.number(7))
    }
    func testDraftKeepsAnswerAndSharedAwardThroughLanguageSwitchAndInFlightSync() throws {
        let sent=LearnerState();var current=sent;var draft=try readingRun();draft.answer="my unfinished answer";current.saveReading(draft)
        let merged=LearnerState.rebased(current:current,sent:sent,acknowledged:sent);XCTAssertEqual(merged.reading?.answer,draft.answer)
        current.target="fr";XCTAssertNil(current.reading);current.target="es";XCTAssertEqual(current.reading?.id,draft.id)
    }
    func testRequiredDocumentOverridesRandomFormatAndSubjectsRotateInAuthoredOrder() {
        let content:JSONValue = .object(["readingSubjects":.array([.object(["id":.string("a"),"name":.string("First")]),.object(["id":.string("b"),"name":.string("Second")])]),"readingScope":.object(["requiredDocument":.object(["name":.string("Cafe menu"),"requirements":.string("Include drinks and prices.")])])])
        let first=Reading.select(content:content,level:"A1",recent:[],lesson:"unit",roll:0)
        let second=Reading.select(content:content,level:"A1",recent:[.object(["lessonId":.string("unit"),"subject":.string("a")])],lesson:"unit",roll:0)
        XCTAssertEqual(first["format"]["id"],.string("document:Cafe menu"));XCTAssertEqual(first["subject"]["id"],.string("a"));XCTAssertEqual(second["subject"]["id"],.string("b"))
    }

    func testTutorialRequiresFourSentences() throws {
        XCTAssertThrowsError(try readingRun(text:"Hola. Soy Piyali.",tutorial:true))
        XCTAssertNoThrow(try readingRun(text:"Hola, buenos días. Me llamo Piyali. ¿Cómo estás? ¿Tienes ganas de aprender español?",tutorial:true))
    }

}
