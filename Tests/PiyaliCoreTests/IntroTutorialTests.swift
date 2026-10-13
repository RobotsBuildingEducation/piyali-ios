import XCTest
@testable import PiyaliCore

final class IntroTutorialTests:XCTestCase {
    private var root:URL { URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent() }
    private func library(_ target:String = "es") throws -> IntroLibrary { try ContentLibrary.decode(IntroLibrary.self,url:root.appendingPathComponent("Piyali/Resources/intro-\(target).json.gz")) }
    func testSourceVisibilityAndAllAdaptedContentAndAdventures() throws {
        let fixtures=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/intro.json")))
        for value in fixtures["visibility"].array { XCTAssertEqual(IntroTutorial.needed(level:value["level"].string,completed:value["lessons"][IntroTutorial.lessonID]["status"].string == "completed",hasFirstQuest:value["hasFirstQuestHistory"].boolean),value["expected"].boolean) }
        var count=0
        for target in LearningLanguages.practice+["nah","yua"] {
            let content=try library(target);XCTAssertEqual(content.target,target);XCTAssertEqual(content.units.count,7)
            for level in LearningLanguages.levels {
                let lesson=try XCTUnwrap(content.units[level]?.lessons.first),review=try XCTUnwrap(content.games[level])
                XCTAssertEqual(lesson.id,IntroTutorial.lessonID);XCTAssertEqual(lesson.xpReward,50);XCTAssertEqual(lesson.modes,IntroTutorial.modes)
                if level != "Pre-A1" { XCTAssertEqual(lesson.content["game"]["tutorialPracticeLevel"].string,level);XCTAssertEqual(lesson.agenda["items"].array.count,6) }
                XCTAssertEqual(Set(review.bySupport.keys),Set(LearningLanguages.support))
                for scene in review.bySupport.values {
                    XCTAssertEqual(scene.quest.steps.count,7);XCTAssertEqual(scene.quest.steps.map(\.weight).reduce(0,+),8)
                    let world=try XCTUnwrap(content.worlds[scene.worldKey]);XCTAssertTrue(world.walkable(world.start))
                    for npc in scene.npcs { XCTAssertNotNil(world.path(from:world.start,to:.init(x:npc.tx,y:npc.ty))) }
                    for step in scene.quest.steps { let node=try XCTUnwrap(step.nodes.first);XCTAssertFalse(node.npcLine.isEmpty);if node.responseMode == "choice" { XCTAssertEqual(node.choices.filter(\.correct).count,1) } else { XCTAssertFalse((node.speechTarget ?? "").isEmpty) } }
                    count += 1
                }
            }
        }
        XCTAssertEqual(count,980)
    }
    func testOrderedExposureKeepsRatingAndPracticeSeparateAndAwardsOnce() throws {
        let lesson=try XCTUnwrap(library().units["Pre-A1"]?.lessons.first);var state=LearnerState()
        XCTAssertFalse(state.completeIntro(lesson));XCTAssertFalse(state.visitIntro("game",expectedLevel:"Pre-A1"));XCTAssertFalse(state.visitIntro("vocabulary",expectedLevel:"A1"))
        for mode in IntroTutorial.modes { XCTAssertTrue(state.visitIntro(mode,expectedLevel:"Pre-A1"));XCTAssertFalse(state.visitIntro(mode,expectedLevel:"Pre-A1")) }
        XCTAssertEqual(state.totalXP,0);XCTAssertEqual(state.rating,800);XCTAssertTrue(state.practicedModes.isEmpty)
        XCTAssertTrue(state.completeIntro(lesson));XCTAssertFalse(state.completeIntro(lesson));XCTAssertEqual(state.totalXP,50);XCTAssertEqual(state.pendingChanges?.count,1)
        XCTAssertEqual(state.pendingChanges?.first?.contentID,IntroTutorial.lessonID);XCTAssertEqual(state.pendingChanges?.first?.source,.lesson)
    }
    func testDraftsResumeAndRemainSeparateAcrossLanguageAndLevelChanges() throws {
        var state=LearnerState();_=state.visitIntro("vocabulary",expectedLevel:"Pre-A1")
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state));XCTAssertEqual(restored.introSession.next,"grammar")
        state.target="fr";XCTAssertEqual(state.introSession.next,"vocabulary");state.target="es";XCTAssertEqual(state.introSession.next,"grammar")
        state.level="B1";XCTAssertEqual(state.introSession.next,"vocabulary");XCTAssertFalse(state.visitIntro("grammar",expectedLevel:"Pre-A1"))
        XCTAssertFalse(state.needsIntro);state.journeyQuestCounts=["es":1];XCTAssertTrue(state.needsIntro)
    }
    func testTutorialAdventureNeverCompletesTheGuideOrAwardsAUnitReward() throws {
        let content=try library(),scene=try XCTUnwrap(content.games["Pre-A1"]?.bySupport["en"])
        var run=RPGRun(target:"es",support:"en",lessonID:IntroTutorial.lessonID,xpReward:50,scenario:scene,world:try XCTUnwrap(content.worlds[scene.worldKey]),tutorial:true),state=LearnerState()
        run.stepIndex=7;run.score=800;state.saveRPG(run)
        XCTAssertTrue(run.completed);XCTAssertEqual(run.reward,0);XCTAssertEqual(state.completeRPG(run),0);XCTAssertFalse(state.completed.contains(state.completionKey(IntroTutorial.lessonID)));XCTAssertEqual(state.totalXP,0)
    }
    func testLessonUnlockRequiresTheSourceIntroButDoesNotAlterTutorIndex() throws {
        let index=try ContentLibrary.decode([String:[String:[String]]].self,url:root.appendingPathComponent("Piyali/Resources/curriculum-index.json.gz"))["es"]!
        let withIntro=IntroTutorial.lessonCourseIndex(index)
        XCTAssertEqual(index["Pre-A1"]?.count,85);XCTAssertEqual(withIntro["Pre-A1"]?.count,86);XCTAssertEqual(withIntro["A1"],index["A1"])
        var state=LearnerState();state.completed=Set(index["Pre-A1"]!.map { state.completionKey($0) })
        XCTAssertFalse(state.unlockedLevels(mode:"skillTree",index:withIntro).contains("A1"))
        state.completed.insert(state.completionKey(IntroTutorial.lessonID));XCTAssertTrue(state.unlockedLevels(mode:"skillTree",index:withIntro).contains("A1"))
    }
}
