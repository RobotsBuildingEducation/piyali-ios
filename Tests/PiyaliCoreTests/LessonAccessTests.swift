import XCTest
@testable import PiyaliCore

final class LessonAccessTests:XCTestCase {
    func testActualWebRendererFixturesCoverTutorialSequentialCrossUnitPlacementAndResumedWork() throws {
        struct Fixture:Decodable { let units:[[String]];let lesson:String;let progress:[String:LessonAccessStatus];let tutorial:Bool;let placed:Bool;let expected:LessonAccessStatus }
        let file=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/lesson-access.json")
        let cases=try JSONDecoder().decode([Fixture].self,from:Data(contentsOf:file))
        XCTAssertEqual(cases.count,336)
        for sample in cases { XCTAssertEqual(LessonAccess.status(lesson:sample.lesson,units:sample.units,progress:sample.progress,tutorial:sample.tutorial,placed:sample.placed),sample.expected,"\(sample.lesson), tutorial=\(sample.tutorial), placed=\(sample.placed), progress=\(sample.progress)") }
    }
    func testPlacementDoesNotCrossLanguagesOrInventProgress() {
        let state=LearnerState()
        XCTAssertFalse(LessonAccess.throughPlacement(state.placements?["fr"]?.level,level:"A1"))
        XCTAssertTrue(LessonAccess.throughPlacement("B2",level:"A2"));XCTAssertFalse(LessonAccess.throughPlacement("A2",level:"B2"))
        XCTAssertTrue(state.completed.isEmpty);XCTAssertEqual(state.totalXP,0)
    }
}
