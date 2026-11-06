import XCTest
@testable import PiyaliCore

@MainActor final class UpcomingGameReviewTests:XCTestCase {
    private var root:URL{URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()}
    func testEveryOriginalCompletionAndImmediateNextCandidate()throws {
        struct Case:Decodable{let target:String,lessonID:String,sourceLevel:String;let selectedLevel:String?;let expected:UpcomingGameReviewPolicy.Candidate?}
        let policy=try UpcomingGameReviewPolicy(url:root.appendingPathComponent("Piyali/Resources/upcoming-game-review-policy.js")),cases=try ContentLibrary.decode([Case].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/upcoming-game-review.json.gz"))
        XCTAssertEqual(cases.count,8750);var loaded:[String:[String:[LearningUnit]]]=[:],eligible=0
        for (index,entry)in cases.enumerated(){try autoreleasepool{if loaded[entry.target] == nil{loaded[entry.target]=try ContentLibrary.decode([String:[LearningUnit]].self,url:root.appendingPathComponent("Piyali/Resources/curriculum-"+entry.target+".json.gz"))};let levels=try XCTUnwrap(loaded[entry.target]),native=levels[entry.sourceLevel]?.flatMap(\.lessons).first{$0.id == entry.lessonID};let lesson:Lesson;if let native{lesson=native}else{let intro=try ContentLibrary.decode(IntroLibrary.self,url:root.appendingPathComponent("Piyali/Resources/intro-"+entry.target+".json.gz"));lesson=try XCTUnwrap(intro.units[entry.sourceLevel]?.lessons.first{$0.id == entry.lessonID})};XCTAssertEqual(try policy.level(after:lesson),entry.selectedLevel,"Source level \(index)");let result=try policy.candidate(after:lesson,units:levels[entry.selectedLevel ?? ""] ?? []);XCTAssertEqual(result,entry.expected,"Source candidate \(index) \(entry.target) \(entry.lessonID)");if result != nil{eligible += 1}}}
        XCTAssertEqual(eligible,1204)
    }
}
