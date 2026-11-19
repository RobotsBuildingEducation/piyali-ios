import XCTest
@testable import PiyaliCore

final class PracticeRepairContextTests:XCTestCase {
    func testAllSeventeenFormatsUseOriginalSourceCaptureInputs()throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/practice-repair-contexts.json")
        let rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url))
        XCTAssertEqual(rows.count,36);XCTAssertEqual(Set(rows.map{$0["kind"].string}).count,17)
        for row in rows {
            let module=try XCTUnwrap(PracticeRecipeModule(rawValue:row["module"].string))
            let q=try PracticeQuestion(module:module,kind:row["kind"].string,payload:row["question"],options:.object(["cefrLevel":.string("A1")]),target:"es",support:"en")
            var run=PracticeRun(question:q,lessonID:"curriculum-id",lessonLevel:"Pre-A1",response:row["response"],bank:row["bank"].array.map(\.string))
            if row["order"] != .null{run.studyAssignmentOrder=row["order"].array.map(\.string)}
            XCTAssertEqual(run.repairMemoryContext,row["expected"],module.rawValue+":"+row["case"].string)
        }
    }
    func testStemlessMatchCapturesQuestionLevelAndOriginalPairingsSurvivesRestoreAndRetryWithoutXP()throws {
        let q=try PracticeQuestion(module:.vocabulary,kind:"match",payload:.object(["left":.array(["hola","adiós"].map(JSONValue.string)),"right":.array(["hello","goodbye"].map(JSONValue.string))]),options:.object(["cefrLevel":.string("A2")]),target:"es",support:"en")
        var state=LearnerState();state.target="es";state.support="en";state.level="Pre-A1"
        var run=PracticeRun(question:q,lessonID:"lesson-native-id",lessonLevel:"Pre-A1",response:.object(["pairs":.object(["0":.number(1),"1":.number(0)])]))
        state.savePractice(run);XCTAssertTrue(state.answerPractice(key:run.key,questionID:q.id,correct:false,reward:6))
        XCTAssertFalse(state.answerPractice(key:run.key,questionID:q.id,correct:false,reward:6))
        state=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state))
        let note=try XCTUnwrap(state.companionMemory?["es"]?.first)
        XCTAssertEqual(state.companionMemory?["es"]?.count,1);XCTAssertEqual(note.text("concept"),"Match the items:")
        XCTAssertEqual(note.text("userAnswer"),"hola → goodbye, adiós → hello");XCTAssertEqual(note.text("expectedAnswer"),"Check the correct pairings")
        XCTAssertEqual(note.text("sourceContext"),"vocabulary");XCTAssertEqual(note.text("cefrLevel"),"A2");XCTAssertEqual(state.totalXP,0)
        run=try XCTUnwrap(state.practiceRuns?[run.key]);run.response = .object(["pairs":.object(["0":.number(0),"1":.number(1)])]);state.savePractice(run)
        XCTAssertTrue(state.answerPractice(key:run.key,questionID:q.id,correct:true,reward:6));XCTAssertFalse(state.answerPractice(key:run.key,questionID:q.id,correct:true,reward:6));XCTAssertEqual(state.totalXP,6)
        XCTAssertEqual(state.companionMemory?["es"]?.first?.text("userAnswer"),note.text("userAnswer"))
    }
}
