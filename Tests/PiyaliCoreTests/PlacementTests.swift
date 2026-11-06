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

extension PlacementTests {
    @MainActor func testTutorProgressionMatchesActualWebHelpersAcrossEveryCompletedLevelCombination()throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let rows=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/tutor-source-policy.json.gz"))
        var cases=0
        for row in rows {
            let input=row["input"]
            if row["operation"].string == "earnedLevel" {
                let status=input["status"].object.mapValues{TutorLevelCompletion(completed:$0["isComplete"].boolean ? 1:0,total:1)}
                XCTAssertEqual(TutorProgression.earned(status),row["expected"].string);cases+=1
            }else if row["operation"].string == "levelStats" {
                let stats=TutorProgression.completion(summary:input["summary"],level:input["level"].string,fallbackTotal:Int(input["fallbackTotal"].number),localCompleted:Int(input["localCompleted"].number))
                XCTAssertEqual(stats.total,row["expected"]["total"].number);XCTAssertEqual(stats.completed,row["expected"]["completed"].number);XCTAssertEqual(stats.isComplete,row["expected"]["isComplete"].boolean);XCTAssertEqual(stats.progress,Int(row["expected"]["progress"].number));cases+=1
            }
        }
        XCTAssertEqual(cases,138)
    }
    func testTutorUnlockUsesStoredSummaryTotalAndHigherCourseEvidenceWithoutChangingBrowsingLevel() {
        var state=LearnerState();let index=["Pre-A1":(0..<87).map{"intro-\($0)"},"B1":["advanced"]]
        state.tutorLevels=["es":"Pre-A1"]
        state.importCourseSummary(.object(["tutor":.object(["levels":.object(["pre_a1":.object(["completed":.number(86),"total":.number(86)])])])]),target:"es")
        XCTAssertEqual(state.earnedTutorLevel(index:index),"A1");XCTAssertEqual(state.tutorCompletion(level:"Pre-A1",index:index).progress,100)
        state.completed.insert(state.tutorKey("advanced"));state.reconcileTutorUnlock(index:index)
        XCTAssertEqual(state.tutorUnlockedLevels?["es"],"B2");XCTAssertEqual(state.tutorLevel,"Pre-A1")
        state.completed=[];state.importCourseSummary(.object([:]),target:"es");state.reconcileTutorUnlock(index:index)
        XCTAssertEqual(state.earnedTutorLevel(index:index),"B2","Hydration or browsing never lowers an earned unlock")
        XCTAssertEqual(state.availableTutorLevels(index:index,lessons:["Pre-A1","A1"],flashcards:["Pre-A1","A1","A2"]),["Pre-A1","A1","A2","B1","B2"])
        state.target="fr";XCTAssertEqual(state.availableTutorLevels(index:[:],lessons:["Pre-A1"],flashcards:["Pre-A1"]),["Pre-A1"])
    }
    func testTutorRootImportAndRebasePreserveHigherServerUnlockWhilePreferencesStayDirty() {
        var sent=LearnerState();sent.tutorLevels=["es":"Pre-A1"];sent.tutorUnlockedLevels=["es":"A2"];sent.preferencesModifiedAt=Date()
        var current=sent;current.tutorUnlockedLevels?["fr"]="B1"
        let cloud=WebProgressContract.imported(["progress":["tutorUnlockedLevels":["es":"C1","ja":"B2"]]],native:sent)
        let merged=LearnerState.rebased(current:current,sent:sent,acknowledged:cloud)
        XCTAssertEqual(merged.tutorUnlockedLevels,["es":"C1","fr":"B1","ja":"B2"]);XCTAssertEqual(merged.tutorLevel,"Pre-A1")
        XCTAssertEqual(merged.companionQuestUser["progress"]["tutorUnlockedLevels"]["es"].string,"C1")
    }
}
