import XCTest
@testable import PiyaliCore

final class GuidedPracticeSessionTests:XCTestCase {
    func testGuidedSessionResumesOnlyItsAccountLanguageAndDayAndAdvancesInPlateOrder() throws {
        let courses=[PlateCourse(kind:"speak",count:0,target:1),PlateCourse(kind:"learn",count:0,target:1),PlateCourse(kind:"review",count:0,target:5)]
        let session=try XCTUnwrap(GuidedPracticeSession(account:"alice",target:"es",day:"2026-10-20",courses:courses))
        var restored=try JSONDecoder().decode(GuidedPracticeSession.self,from:JSONEncoder().encode(session))
        XCTAssertTrue(restored.matches(account:"alice",target:"es",day:"2026-10-20"))
        for scope in [("bob","es","2026-10-20"),("alice","fr","2026-10-20"),("alice","es","2026-10-21")] { XCTAssertFalse(restored.matches(account:scope.0,target:scope.1,day:scope.2)) }
        XCTAssertEqual(restored.current,"speak");XCTAssertFalse(restored.taskCompleted(courses))
        let spoken=[PlateCourse(kind:"speak",count:1,target:1),courses[1],courses[2]]
        XCTAssertTrue(restored.taskCompleted(spoken));XCTAssertTrue(restored.advance(spoken));XCTAssertEqual(restored.current,"learn")
        let complete=courses.map { PlateCourse(kind:$0.kind,count:$0.target,target:$0.target) }
        XCTAssertFalse(restored.advance(complete));XCTAssertNil(GuidedPracticeSession(account:"alice",target:"es",day:"2026-10-20",courses:complete))
    }
}

extension GuidedPracticeSessionTests {
    @MainActor func testOriginalWebConductorJourneysMatchNativePolicy()throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),rows=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/plate-session-policy.json.gz"))
        XCTAssertEqual(rows.count,6)
        for journey in rows {
            let policy=try PlateSessionPolicy(source:root.appendingPathComponent("Piyali/Resources/plate-session-policy.js"))
            for row in journey["cases"].array {XCTAssertEqual(try policy.run(row["operation"].string,row["input"]),row["expected"],journey["name"].string)}
        }
    }
}
