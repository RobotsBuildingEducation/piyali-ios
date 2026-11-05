import XCTest
@testable import PiyaliCore

final class StudyNoteContextTests:XCTestCase {
    func testSixteenNoteEligibleFormatsUseOriginalFullHandlerInputsAndLessonTitles()throws {
        let file=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/study-note-contexts.json"),rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:file))
        XCTAssertEqual(rows.count,32);XCTAssertEqual(Set(rows.map{$0["kind"].string}).count,16)
        for row in rows {
            let module=try XCTUnwrap(PracticeRecipeModule(rawValue:row["module"].string)),q=try PracticeQuestion(module:module,kind:row["kind"].string,payload:row["question"],options:.object(["cefrLevel":.string("A1")]),target:"es",support:"en")
            var run=PracticeRun(question:q,lessonID:nil,lessonLevel:"A1",response:row["response"],bank:row["bank"].array.map(\.string));run.correct=true
            if row["order"] != .null {run.studyAssignmentOrder=row["order"].array.map(\.string)}
            XCTAssertEqual(run.studyNoteContext,row["expected"],module.rawValue+q.kind)
            XCTAssertEqual(PracticeRun.studyLessonTitle(module,delight:q.isDelight),row["lessonTitle"],module.rawValue+q.kind)
        }
    }
    func testNeighborhoodNotePreservesPlacementOrderAcrossMovesReturnAndPrivateRestore()throws {
        let q=try PracticeQuestion(module:.grammar,kind:"delight:word_neighborhoods",payload:.object(["variant":.string("word_neighborhoods"),"groups":.array([.object(["label":.string("Food"),"items":.array(["pan","arroz","2","1"].map(JSONValue.string))]),.object(["label":.string("Other"),"items":.array([])])])]),options:.object([:]),target:"es",support:"en")
        var run=PracticeRun(question:q,lessonID:nil,lessonLevel:nil)
        func change(_ word:String,_ group:Int?) {let next=DelightInteraction.neighborhood(question:q.payload,response:run.response,word:word,group:group,locked:false);run.recordStudyAssignmentOrder(next:next);run.response=next}
        change("pan",0);change("arroz",0);change("pan",1);change("pan",0)
        XCTAssertEqual(run.studyAssignmentOrder,["pan","arroz"]);change("pan",nil);change("pan",0);change("2",0);change("1",0)
        let restored=try JSONDecoder().decode(PracticeRun.self,from:JSONEncoder().encode(run))
        XCTAssertEqual(restored.studyNoteContext["userAnswer"].string,"Food: 1, 2, arroz, pan | Other: ")
    }
}
