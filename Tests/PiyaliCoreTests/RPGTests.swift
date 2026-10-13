import XCTest
@testable import PiyaliCore

final class RPGTests:XCTestCase {
    private var root:URL { URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent() }
    private func library(_ target:String = "es") throws -> RPGLibrary { try ContentLibrary.decode(RPGLibrary.self,url:root.appendingPathComponent("Piyali/Resources/rpg-\(target).json.gz")) }
    private func makeRun(lesson:String? = "unit-game") throws -> RPGRun { let content=try library(),scenario=try XCTUnwrap(content.scenarios(level:"Pre-A1",support:"en").first);return RPGRun(target:"es",support:"en",lessonID:lesson,xpReward:30,scenario:scenario,world:try XCTUnwrap(content.worlds[scenario.worldKey])) }
    private func finish(_ run:inout RPGRun) {
        while !run.completed {
            let node=run.node!
            if node.responseMode == "choice" { run.choose(node.choices.firstIndex { $0.correct }!) }
            else { run.speak(node.speechTarget ?? node.expectedAnswer,turn:RPGSpeechTurn(grade:"full",reply:"Bien",tip:"")) }
            run.advance()
        }
    }
    func testScoringAndSpeechMatchActualWebSource() throws {
        let fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/rpg.json")))
        for sample in fixture["scoring"].array { XCTAssertEqual(RPGScoring.stars(Int(sample["baseScore"].number)),Int(sample["stars"].number));XCTAssertEqual(RPGScoring.xp(reward:Int(sample["xpReward"].number),score:Int(sample["baseScore"].number),flair:Int(sample["flairScore"].number)),Int(sample["xp"].number)) }
        for sample in fixture["speech"].array { let result=RPGScoring.match(transcript:sample["transcript"].string,target:sample["target"].string,lang:sample["lang"].string,level:sample["level"].string);XCTAssertEqual(result.score,sample["score"].number,accuracy:1e-12);XCTAssertEqual(result.pass,sample["pass"].boolean) }
    }
    func testPreparedStoriesAndDialogueSplittingMatchReferenceValidation() throws {
        let fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/rpg.json")))
        for sample in fixture["stories"].array {
            let base=try JSONDecoder().decode(RPGScenario.self,from:JSONEncoder().encode(sample["base"]))
            let actual=RPGStory.preparing(base,raw:sample["raw"],target:sample["target"].string,support:sample["support"].string)
            if sample["expected"] == .null { XCTAssertNil(actual,sample["mode"].string) }
            else { let expected=try JSONDecoder().decode(RPGScenario.self,from:JSONEncoder().encode(sample["expected"]));XCTAssertEqual(actual?.npcs,expected.npcs,sample["mode"].string);XCTAssertEqual(actual?.quest.storySeed,expected.quest.storySeed,sample["mode"].string);XCTAssertEqual(actual?.quest.intro,expected.quest.intro);XCTAssertEqual(actual?.storyTitle,expected.storyTitle);XCTAssertEqual(actual?.storyIntro,expected.storyIntro);XCTAssertEqual(actual?.storyEpilogue,expected.storyEpilogue);for (a,e) in zip(actual?.quest.steps ?? [],expected.quest.steps) { XCTAssertEqual(a,e,sample["mode"].string) } }
        }
        for sample in fixture["dialogue"].array { let value=RPGDialogue.split(sample["text"].string);XCTAssertEqual(value.spoken,sample["expected"]["spokenText"].string);XCTAssertEqual(value.scene,sample["expected"]["subtext"].string) }
    }
    func testEveryAuthoredLanguageLevelEpisodeAndUnitReviewHasSevenPlayableTasks() throws {
        var count=0,reviews=0
        for target in LearningLanguages.practice+["nah","yua"] {
            let curriculum=try ContentLibrary.decode([String:[LearningUnit]].self,url:root.appendingPathComponent("Piyali/Resources/curriculum-\(target).json.gz"))
            let gameIDs=Set(curriculum.values.flatMap { $0 }.flatMap(\.lessons).filter { $0.modes.contains("game") }.map(\.id))
            let library=try library(target);XCTAssertEqual(Set(library.reviews.keys),gameIDs);XCTAssertEqual(library.catalog.count,7);XCTAssertEqual(library.reviews.count,89);reviews += library.reviews.count
            for (level,supports) in library.catalog {
                XCTAssertEqual(Set(supports.keys),Set(LearningLanguages.support))
                for scenarios in supports.values { XCTAssertEqual(scenarios.count,12);for scenario in scenarios { XCTAssertEqual(scenario.authoredEpisode.level,level);verify(scenario,library:library);count += 1 } }
            }
            for review in library.reviews.values { XCTAssertTrue(review.context["isGameReview"].boolean);XCTAssertFalse(review.context["sourceLessonIds"].array.isEmpty);for scenario in review.bySupport.values { verify(scenario,library:library) } }
            // All support-language variants share their actual seeded map.
            for scenario in library.catalog.values.flatMap({ $0["en"] ?? [] })+library.reviews.values.compactMap({ $0.bySupport["en"] }) {
                let world=try XCTUnwrap(library.worlds[scenario.worldKey]);XCTAssertTrue(world.walkable(world.start))
                for npc in scenario.npcs { XCTAssertNotNil(world.path(from:world.start,to:RPGPoint(x:npc.tx,y:npc.ty)),"Unreachable \(target) \(scenario.id) \(npc.name)") }
            }
        }
        XCTAssertEqual(count,11760);XCTAssertEqual(reviews,1246)
    }
    private func verify(_ scenario:RPGScenario,library:RPGLibrary,file:StaticString = #filePath,line:UInt = #line) {
        XCTAssertEqual(scenario.quest.steps.count,7,file:file,line:line);XCTAssertEqual(scenario.quest.steps.map(\.weight).reduce(0,+),8,file:file,line:line);XCTAssertFalse(scenario.npcs.isEmpty,file:file,line:line);XCTAssertNotNil(library.worlds[scenario.worldKey],file:file,line:line)
        for step in scenario.quest.steps { XCTAssertTrue(scenario.npcs.indices.contains(step.npcIdx),file:file,line:line);XCTAssertEqual(step.nodes.count,1,file:file,line:line);let node=step.nodes[0];XCTAssertFalse(node.npcLine.isEmpty,file:file,line:line);if node.responseMode == "choice" { XCTAssertEqual(node.choices.filter(\.correct).count,1,file:file,line:line) } else { XCTAssertFalse((node.speechTarget ?? "").isEmpty,file:file,line:line) } }
    }
    func testRetriesHaveDecliningPointsAndThreeMissesRevealWithoutCompletionXP() throws {
        var run=try makeRun(),state=LearnerState();state.saveRPG(run)
        XCTAssertEqual(state.completeRPG(run),0)
        let first=run.node!,wrong=first.choices.firstIndex { !$0.correct }!,right=first.choices.firstIndex { $0.correct }!
        run.choose(wrong);XCTAssertEqual(run.score,0);XCTAssertFalse(run.resolved);XCTAssertEqual(run.misses.first?.expected,first.expectedAnswer)
        run.choose(right);XCTAssertEqual(run.score,50);XCTAssertTrue(run.resolved);run.choose(right);XCTAssertEqual(run.score,50)
        run.advance();let next=run.node!,bad=next.choices.firstIndex { !$0.correct }!;for _ in 0..<3 { run.choose(bad) }
        XCTAssertTrue(run.resolved);XCTAssertTrue(run.feedback.contains(next.expectedAnswer));XCTAssertEqual(run.score,50);XCTAssertEqual(run.misses.count,2)
        run.advance();XCTAssertEqual(run.attempts,0);XCTAssertEqual(state.totalXP,0)
    }
    func testSpokenTurnsAlwaysMoveStoryAndCannotBeScoredTwice() throws {
        var run=try makeRun();while run.node?.responseMode != "speech" { run.choose(run.node!.choices.firstIndex { $0.correct }!);run.advance() }
        let before=run.score;run.speak("",turn:.init(grade:"full",reply:"OK",tip:""));XCTAssertEqual(run.score,before)
        run.speak("wrong language",turn:.init(grade:"miss",reply:"Seguimos.",tip:"Try a target-language phrase."));XCTAssertEqual(run.score,before+25*run.node!.weight);XCTAssertTrue(run.resolved)
        run.speak("new reply",turn:.init(grade:"full",reply:"OK",tip:""));XCTAssertEqual(run.score,before+25*run.node!.weight)
        run.advance();XCTAssertFalse(run.resolved)
    }
    func testRecapClaimsLessonRewardOnceAndFreeAdventureDoesNotGrantXP() throws {
        var run=try makeRun(),state=LearnerState();finish(&run);state.saveRPG(run)
        XCTAssertEqual(run.score,800);XCTAssertEqual(run.stars,3);XCTAssertEqual(state.completeRPG(run),30);XCTAssertEqual(state.completeRPG(run),0)
        XCTAssertEqual(state.totalXP,30);XCTAssertEqual(state.pendingChanges?.count,1);XCTAssertEqual(state.pendingChanges?.first?.gameResult?["score"].number,800);XCTAssertTrue(state.completed.contains("es:unit-game"));XCTAssertEqual(state.rating,800)
        var replay=try self.makeRun();finish(&replay);state.saveRPG(replay);XCTAssertEqual(state.completeRPG(replay),0)
        var free=try self.makeRun(lesson:nil);finish(&free);state.saveRPG(free);XCTAssertEqual(state.completeRPG(free),0);XCTAssertEqual(state.totalXP,30)
    }
    func testMapCollisionPathfindingAndSavedRunSurvivePersistence() throws {
        var run=try makeRun();let start=run.position
        XCTAssertFalse(run.move(dx:100,dy:0));XCTAssertEqual(run.position,start);XCTAssertTrue(run.approachNPC());let npc=run.npc!;XCTAssertLessThanOrEqual(abs(run.position.x-npc.tx)+abs(run.position.y-npc.ty),1)
        var state=LearnerState();state.saveRPG(run);let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state));XCTAssertEqual(restored.rpgRuns?["es"],run)
        state.target="fr";XCTAssertEqual(state.completeRPG(run),0)
    }
}
