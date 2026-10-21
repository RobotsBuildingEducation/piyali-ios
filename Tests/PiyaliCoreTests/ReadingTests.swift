import XCTest
@testable import PiyaliCore

final class ReadingTests:XCTestCase {
    private func fixture() throws -> JSONValue { try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/reading.json"))) }
    @MainActor func testOriginalReadingPoliciesExecuteInNativeWithoutWebEffects() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        struct Fixture:Decodable { let operation:String;let parameters:JSONValue;let expected:String }
        let engine=try PracticeRecipes(source:root.appendingPathComponent("Piyali/Resources/practice-recipes.js")),fixtures=try ContentLibrary.decode([Fixture].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/reading-prompts.json.gz"))
        XCTAssertEqual(fixtures.count,16)
        for sample in fixtures { XCTAssertEqual(try engine.reading(sample.operation,parameters:sample.parameters),sample.expected,sample.operation) }
    }
    func testSourceReadingProtocolKeepsQuestionAndRejectsPartialOrInvalidOutput() throws {
        let lines:[JSONValue]=[.object(["type":.string("title"),"text":.string("A small garden")]),.object(["type":.string("target"),"text":.string("A plant grows near the window.")]),.object(["type":.string("takeaway"),"text":.string("A plant")]),.object(["type":.string("takeaway"),"text":.string("A window")]),.object(["type":.string("takeaway"),"text":.string("A garden")]),.object(["type":.string("review_question"),"questionType":.string("fill"),"question":.string("The plant is near the ___."),"answer":.string("window")]),.object(["type":.string("done")])]
        let output=lines.map(\.json).joined(separator:"\n"),payload=try Reading.protocolPayload(output,questionType:"mc")
        XCTAssertEqual(payload["target"].string,"A plant grows near the window.");XCTAssertEqual(ReadingQuestion(payload["reviewQuestion"])?.type,"fill");XCTAssertEqual(payload["rawReviewQuestion"],lines[5])
        XCTAssertThrowsError(try Reading.protocolPayload(lines.dropLast().map(\.json).joined(separator:"\n"),questionType:"mc"))
        XCTAssertThrowsError(try Reading.protocolPayload(output.replacingOccurrences(of:"___",with:"here"),questionType:"mc"))
    }
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
    func testDisplaySentenceBoundariesMatchExecutedSourceAndTranslationsResume() throws {
        for sample in try fixture()["displaySentences"].array { XCTAssertEqual(Reading.displaySentences(sample["text"].string),sample["expected"].array.map(\.string),sample["text"].string) }
        var run=try readingRun();run.lessonLevel="B1";run.lineTranslations=["My notebook is on the table.","I draw a red flower and write its name.","Tomorrow my sister wants to draw with me."]
        var state=LearnerState();state.saveReading(run)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state));XCTAssertEqual(restored.reading?.lineTranslations,run.lineTranslations);XCTAssertEqual(restored.xp,0)
        XCTAssertEqual(state.reviewReading(answer:"red",correct:true,feedback:"Correct"),7);let event=try XCTUnwrap(state.pendingChanges?.first { $0.source == .readingTurn });XCTAssertEqual(event.level,"A1");XCTAssertEqual(event.skillTreeLessonLevel,"B1")
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
