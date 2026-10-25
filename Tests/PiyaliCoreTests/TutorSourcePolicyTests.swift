import XCTest
@testable import PiyaliCore

final class TutorSourcePolicyTests:XCTestCase {
    private var root:URL {URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()}
    @MainActor func testOriginalTutorPolicyMatchesSourceExecutedCases()throws {
        let policy=try TutorSourcePolicy(source:root.appendingPathComponent("Piyali/Resources/tutor-policy.js")),rows=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/tutor-source-policy.json.gz"))
        XCTAssertGreaterThanOrEqual(rows.count,238)
        for row in rows {XCTAssertEqual(try policy.run(row["operation"].string,row["input"]),row["expected"],row["operation"].string+" "+row["input"]["target"].string+" "+row["input"]["support"].string)}
    }
    @MainActor func testActualTutorCurriculumRetainsIntroAndLessonLaunchMetadata()throws {
        let library=try ContentLibrary.decode([String:[LearningUnit]].self,url:root.appendingPathComponent("Piyali/Resources/tutor-curriculum-es.json.gz")),first=try XCTUnwrap(library["Pre-A1"]?.first),lesson=try XCTUnwrap(first.lessons.first),policy=try TutorSourcePolicy(source:root.appendingPathComponent("Piyali/Resources/tutor-policy.js"))
        XCTAssertEqual(lesson.id,"lesson-tutorial-1");XCTAssertEqual(first.color,"#6366F1");XCTAssertEqual(first.isTutorial,true);XCTAssertEqual(lesson.xpRequired,0,"Preserve the authored field; Tutor derives its separate 50-XP requirement")
        let raw=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(lesson)),unit=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(first)),content=try policy.run("content",.object(["lesson":raw,"unit":unit,"support":.string("en"),"target":.string("es")]))
        XCTAssertEqual(content["preview"].array.count,7);XCTAssertEqual(content["title"].string,"Tutorial - Basic Introductions");XCTAssertEqual(try policy.run("xp",.object(["lesson":raw])),.number(50))
        XCTAssertTrue(library.values.flatMap{$0}.flatMap(\.lessons).contains{$0.modes.contains("game")})
    }
}
