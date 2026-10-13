import XCTest
@testable import PiyaliCore
final class LearningProgressTests: XCTestCase {
    func testFirstSuccessCreatesScoreOneAndMissDoesNot() {
        XCTAssertEqual(PerformanceScore.score(rating: PerformanceScore.update(rating:800,questionLevel:"C2",correct:true,independent:true)),1)
        XCTAssertEqual(PerformanceScore.score(rating: PerformanceScore.update(rating:800,questionLevel:"Pre-A1",correct:false,independent:true)),0)
    }
    func testScoreBoundariesAndSupportWeight() {
        XCTAssertEqual(PerformanceScore.level(score:14),"Pre-A1")
        XCTAssertEqual(PerformanceScore.level(score:15),"A1")
        XCTAssertEqual(PerformanceScore.level(score:85),"C2")
        let baseline = PerformanceScore.rating(score:32)
        XCTAssertGreaterThan(PerformanceScore.update(rating:baseline,questionLevel:"A2",correct:true,independent:true),PerformanceScore.update(rating:baseline,questionLevel:"A2",correct:true,independent:false))
        XCTAssertLessThan(PerformanceScore.update(rating:baseline,questionLevel:"A2",correct:false,independent:true),baseline)
    }
    func testCompanionUnlocksMatchReference() {
        XCTAssertEqual(CompanionTypes.available(level:1),["ghost"])
        XCTAssertEqual(CompanionTypes.effective("robot",level:4),"ghost")
        XCTAssertEqual(CompanionTypes.effective("robot",level:5),"robot")
        XCTAssertEqual(CompanionTypes.available(level:40).last,"axolotl")
    }
    func testStateMigrationWithoutNewOptionalFields() throws {
        var state = LearnerState(); state.award(10)
        let bytes = try JSONEncoder().encode(state)
        var dictionary = try XCTUnwrap(JSONSerialization.jsonObject(with:bytes) as? [String:Any])
        for field in ["ratingByLanguage","focusPlans","masteredPhonics","journeyDays","journeyRecordings"] { dictionary.removeValue(forKey:field) }
        let restored = try JSONDecoder().decode(LearnerState.self,from:JSONSerialization.data(withJSONObject:dictionary))
        XCTAssertEqual(restored.xp,10); XCTAssertEqual(restored.score,0)
    }
}
