import XCTest
@testable import PiyaliCore

final class PlacementTests: XCTestCase {
    func testSelfReportUsesStrongestMilestoneAndLowerCourseOfRange() {
        let placement = PlacementAssessment.estimate(["grammar_struggle","read_write","home_language"])
        XCTAssertEqual(placement?.level,"B1"); XCTAssertEqual(placement?.score,53)
        XCTAssertEqual(PlacementAssessment.estimate(["grammar_struggle"])?.level,"A1")
        XCTAssertNil(PlacementAssessment.estimate(["invented"]))
    }
    func testPlacementIsPerLanguageAndDoesNotGrantCompletionOrXP() {
        var state = LearnerState()
        state.place(PlacementAssessment.estimate(["complex_topics"])!)
        let index = Dictionary(uniqueKeysWithValues:LearningLanguages.levels.map { ($0,["lesson-\($0)"]) })
        XCTAssertEqual(state.unlockedLevels(mode:"skillTree",index:index),["Pre-A1","A1","A2","B1","B2"])
        XCTAssertTrue(state.completed.isEmpty); XCTAssertTrue(state.flashcardMastery.isEmpty); XCTAssertEqual(state.xp,0)
        XCTAssertEqual(state.score,67)
        state.target = "fr"
        XCTAssertEqual(state.unlockedLevels(mode:"skillTree",index:index),["Pre-A1"])
    }
    func testCompletionUnlocksCoursesSeparatelyAndStopsAtFirstGap() {
        var state = LearnerState()
        let index = ["Pre-A1":["intro"],"A1":["basic"],"A2":["later"]]
        state.completed = ["es:intro","es:later"]
        XCTAssertEqual(state.unlockedLevels(mode:"skillTree",index:index),["Pre-A1","A1"])
        XCTAssertEqual(state.unlockedLevels(mode:"flashcards",index:index),["Pre-A1"])
        state.courseCompletion = ["es":["skillTree":["A1":1]]]
        XCTAssertEqual(state.unlockedLevels(mode:"skillTree",index:index),["Pre-A1","A1","A2","B1"])
    }
    func testPlacementPreservesGradedScoreAndOtherBackendFields() {
        var state = LearnerState(); state.assess(correct:true,independent:true)
        let rating = state.rating, placement = PlacementAssessment.estimate(["read_write"])!
        state.place(placement); XCTAssertEqual(state.rating,rating)
        let fields: [String:Any] = ["learningIntelligence":["es":["goal":"keep","elo":["totalGraded":4,"rating":901.0,"scaleVersion":4]]]]
        let patch = WebProgressContract.placementPatch(fields:fields,language:"es",placement:placement)
        let bucket = (patch["learningIntelligence"] as? [String:[String:Any]])?["es"]
        XCTAssertEqual(bucket?["goal"] as? String,"keep")
        XCTAssertEqual((bucket?["elo"] as? [String:Any])?["rating"] as? Double,901)
    }
    func testBackendImportUsesOnlyPerLanguagePlacementAndAcknowledgesPending() {
        var state = LearnerState(); let placement = PlacementAssessment.estimate(["home_language"])!; state.place(placement)
        var fields = WebProgressContract.placementPatch(fields:[:],language:"es",placement:placement)
        fields["proficiencyPlacement"] = "C2"
        let cloud = WebProgressContract.imported(fields,native:state)
        XCTAssertEqual(cloud.placements?["es"]?.level,"A1"); XCTAssertNil(cloud.pendingPlacements?["es"])
        XCTAssertNil(cloud.placements?["fr"])
        let stale = WebProgressContract.placementPatch(fields:fields,language:"es",placement:placement)
        XCTAssertTrue(stale.isEmpty)
    }
    func testOldSyncAcknowledgmentPreservesNewerPlacement() {
        var sent = LearnerState(); sent.place(PlacementAssessment.estimate(["common_words"],now:Date(timeIntervalSince1970:1))!)
        var current = sent; current.place(PlacementAssessment.estimate(["read_write"],now:Date(timeIntervalSince1970:2))!)
        var cloud = sent; cloud.pendingPlacements = [:]
        let merged = LearnerState.rebased(current:current,sent:sent,acknowledged:cloud)
        XCTAssertEqual(merged.placements?["es"]?.level,"B1"); XCTAssertEqual(merged.score,53)
        XCTAssertEqual(merged.pendingPlacements?["es"]?.level,"B1")
    }
}
