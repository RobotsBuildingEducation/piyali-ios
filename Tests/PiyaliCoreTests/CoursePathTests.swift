import XCTest
@testable import PiyaliCore

final class CoursePathTests:XCTestCase {
    func testOriginalPathDecisionsAndNodeStyles()throws {
        struct Fixture:Decodable {let operation:String;let input:JSONValue;let expected:JSONValue}
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let policy=try CoursePathPolicy(source:String(contentsOf:root.appendingPathComponent("Piyali/Resources/course-path-policy.js")))
        let cases=try JSONDecoder().decode([Fixture].self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/course-path.json")))
        XCTAssertEqual(cases.count,309)
        for sample in cases {
            XCTAssertEqual(try policy.run(sample.operation,sample.input),sample.expected,"\(sample.operation): \(sample.input)")
            if sample.operation == "placement" {XCTAssertEqual(LessonAccess.throughPlacement(sample.input["placement"].string,level:sample.input["level"].string),sample.expected.boolean)}
        }
    }
    func testBeginnerPlacementRetainsIntroductionAndSequentialAccessWithoutLosingSavedWork() {
        var state=LearnerState();state.target="en";state.level="Pre-A1";state.place(.init(level:"Pre-A1",score:0,source:"completely_new",selectedIDs:[],updatedAt:Date()))
        let a=Lesson(id:"lesson-pre-a1-first",title:.string("First"),description:.string(""),xpReward:20,modes:[],agenda:.null,content:.null),b=Lesson(id:"lesson-pre-a1-next",title:.string("Next"),description:.string(""),xpReward:20,modes:[],agenda:.null,content:.null)
        let units=[LearningUnit(id:"unit-pre-a1-test",title:.string("Test"),description:.string(""),lessons:[a,b])]
        XCTAssertEqual(state.lessonAccess(a,units:units),.locked);XCTAssertEqual(state.lessonAccess(b,units:units),.locked)
        state.completed.insert(state.completionKey(IntroTutorial.lessonID));XCTAssertEqual(state.lessonAccess(a,units:units),.available);XCTAssertEqual(state.lessonAccess(b,units:units),.locked)
        state.completed.insert(state.completionKey(a.id));XCTAssertEqual(state.lessonAccess(b,units:units),.available)
        state.completed=[];state.lessonWork=[state.completionKey(b.id):.init(earnedXP:6)];XCTAssertEqual(state.lessonAccess(b,units:units),.inProgress)
        XCTAssertEqual(state.xp,0)
    }
}
