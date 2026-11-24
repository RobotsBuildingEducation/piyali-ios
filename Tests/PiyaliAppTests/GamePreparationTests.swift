import XCTest
@testable import Piyali

@MainActor private final class GamePreparationNoCloud:LearnerProgressService{
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class GamePreparationTests:XCTestCase{
    private func app()throws->AppModel{
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated offline identity required")}
        let app=AppModel(progressService:GamePreparationNoCloud());try app.identity.create();app.signedIn=true;app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.onboardingComplete=true;app.learner.target="es";app.learner.support="en";return app
    }
    private func lesson()throws->Lesson{let units=try ContentLibrary.load([String:[LearningUnit]].self,name:"curriculum-es");return try XCTUnwrap(units["Pre-A1"]?.flatMap(\.lessons).first{$0.id == "unit-pre-a1-people-game"})}
    private func response()throws->String{try String(contentsOf:XCTUnwrap(Bundle(for:Self.self).url(forResource:"rpg-prepared-story",withExtension:"json")),encoding:.utf8)}
    private func wait(_ condition:()->Bool)async throws{for _ in 0..<600 where !condition(){try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(condition())}
    func testLegacyTutorialUsesTheSourceMapAndItsMalformedWorldFallback()async throws {
        let library=try ContentLibrary.load(IntroLibrary.self,name:"intro-es")
        let lesson=try XCTUnwrap(library.units["Pre-A1"]?.lessons.first)
        let input:JSONValue = .object(["lesson":try RPGPreparationPolicy.value(lesson),"target":.string("es"),
                                        "support":.string("en"),"user":.object([:])])
        var map=(0..<14).flatMap { y in (0..<20).map { x in x == 0 || x == 19 || y == 0 || y == 13 ? 2 : 0 } }
        map[3*20+5]=3
        map[4*20+2]=4
        map[2*20+4]=6
        let generated=try JSONSerialization.data(withJSONObject:[
            "mapWidth":20,"mapHeight":14,"mapData":map,"playerStart":["x":3,"y":3],
            "npcs":[["name":"Ana","tx":4,"ty":4],["name":"Mar","tx":8,"ty":6]]
        ])
        for validWorld in [true,false] {
            var prompts=0
            let policy=try TutorialPlazaPolicy()
            let scenario=try await policy.generate(input) { prompt in
                prompts+=1
                if prompts == 1 {
                    XCTAssertTrue(prompt.text.contains("TUTORIAL MODE"))
                    if validWorld { return String(decoding:generated,as:UTF8.self) }
                }
                return "{}"
            }
            XCTAssertEqual(scenario.id,"tutorialPlaza")
            XCTAssertEqual(scenario.maps.first?.world.width,validWorld ? 20 : 18)
            XCTAssertEqual(Array(scenario.npcs.prefix(2)).map { $0["name"].string },validWorld ? ["Ana","Mar"] : ["Ada","Bruno"])
            XCTAssertGreaterThan(prompts,1)
            let world=try XCTUnwrap(scenario.maps.first?.world)
            let run=try ExplorationRun(target:"es",support:"en",scenario:scenario,tutorialKey:"course-intro")
            XCTAssertEqual(world.start,RPGPoint(x:3,y:3))
            XCTAssertEqual(run.position,validWorld ? RPGPoint(x:9,y:6) : RPGPoint(x:8,y:5))
            let ordinary=try ExplorationRun(target:"es",support:"en",scenario:scenario)
            XCTAssertEqual(ordinary.position,world.start)
            let definitions=try XCTUnwrap(scenario.tileDefinitions)
            let rgba=try XCTUnwrap(policy.terrain(world,definitions:definitions,seed:1792936800000))
            XCTAssertEqual(rgba.count,world.width*world.height*16*16*4)
            XCTAssertEqual(rgba[3],255)
            let decorations=policy.decoration(world,definitions:definitions,seed:1792936800000,id:scenario.id)
            let props=decorations.filter { $0.z >= 1000 }
            XCTAssertEqual(Set(props.map(\.kind)),validWorld ? ["tree","bench","counter"] : [])
            XCTAssertTrue(decorations.contains { $0.kind == "paper_bits" })
            XCTAssertTrue(decorations.allSatisfy { $0.rgba.count == $0.pixelWidth*$0.pixelHeight*4 })
            if validWorld {
                let tree=try XCTUnwrap(props.first { $0.kind == "tree" })
                XCTAssertEqual(tree.x,5.5)
                XCTAssertEqual(tree.y,10.6,accuracy:0.0001)
                XCTAssertNotNil(tree.phase)
                XCTAssertFalse(world.walkable(RPGPoint(x:5,y:3)))
            }
        }
    }
    func testDraftPreparationAndExplorationStayUncommittedUntilHandoff()async throws{
        let app=try app(),lesson=try lesson(),response=try response(),directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)}
        let before=app.learner;var requests=0,delay=0.0,release:CheckedContinuation<Void,Never>?
        let service=RPGService(cache:RPGPreparationCache(directory:directory),writer:{_ in requests+=1;return response}),controller=GamePreparationController(service:service,random:{0.5},wait:{ms in delay=ms;await withCheckedContinuation{release=$0}})
        controller.start(app,lesson:lesson);controller.start(app,lesson:lesson);try await wait{release != nil};XCTAssertEqual(requests,1);XCTAssertEqual(delay,6500);XCTAssertFalse(controller.ready);XCTAssertTrue(controller.exploring);XCTAssertEqual(app.learner.rpgRuns,before.rpgRuns);XCTAssertEqual(app.learner.lessonWork,before.lessonWork);XCTAssertEqual(app.learner.totalXP,0)
        release?.resume();release=nil;try await wait{controller.ready};XCTAssertNil(app.learner.rpgRuns?["es"]);XCTAssertTrue(controller.commit(app));XCTAssertEqual(app.learner.rpgRuns?["es"]?.scenario.quest.steps.count,7);XCTAssertEqual(app.learner.totalXP,0);controller.cancel()
    }
    func testCancelPendingGenerationAndExplorationRejectUncooperativeCompletions()async throws{
        for stage in ["provider","exploration"]{
            let app=try app(),lesson=try lesson(),response=try response(),directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);var provider:CheckedContinuation<String,Never>?,exploration:CheckedContinuation<Void,Never>?
            let before=app.learner.lessonWork,service=RPGService(cache:RPGPreparationCache(directory:directory),writer:{_ in if stage == "provider"{return await withCheckedContinuation{provider=$0}};return response}),controller=GamePreparationController(service:service,wait:{_ in await withCheckedContinuation{exploration=$0}})
            controller.start(app,lesson:lesson);try await wait{stage == "provider" ? provider != nil:exploration != nil};controller.cancel();provider?.resume(returning:response);exploration?.resume();provider=nil;exploration=nil;try await Task.sleep(for:.milliseconds(50));XCTAssertFalse(controller.ready);XCTAssertFalse(controller.commit(app));XCTAssertNil(app.learner.rpgRuns?["es"]);XCTAssertEqual(app.learner.lessonWork,before);XCTAssertEqual(app.learner.totalXP,0);try app.identity.disconnect();try? FileManager.default.removeItem(at:directory)
        }
    }
    func testLostScopeAccessAndNewerSavedProgressCannotBeOverwritten()async throws{
        for change in ["support","target","level","account","access","newer"]{
            let app=try app(),lesson=try lesson(),response=try response(),directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);var release:CheckedContinuation<Void,Never>?
            let service=RPGService(cache:RPGPreparationCache(directory:directory),writer:{_ in response}),controller=GamePreparationController(service:service,wait:{_ in await withCheckedContinuation{release=$0}})
            controller.start(app,lesson:lesson);try await wait{release != nil}
            switch change{
            case "support":app.learner.support="ar"
            case "target":app.learner.target="fr"
            case "level":app.learner.level="A1"
            case "account":try app.identity.disconnect();try app.identity.create()
            case "access":app.learner.xpByLanguage=["es":300]
            default:var newer=try XCTUnwrap(service.stagedRun);newer.id=UUID();newer.stepIndex=1;app.learner.saveRPG(newer)
            }
            let latest=app.learner.rpgRuns;release?.resume();release=nil;try await wait{!controller.busy};XCTAssertFalse(controller.commit(app));XCTAssertEqual(app.learner.rpgRuns,latest);controller.cancel();try app.identity.disconnect();try? FileManager.default.removeItem(at:directory)
        }
    }
    func testStagedResumeRetainsLateProgressAndAvoidsAnotherProviderCall()async throws{
        let app=try app(),lesson=try lesson(),response=try response(),directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer{try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)}
        var calls=0,release:CheckedContinuation<Void,Never>?
        let service=RPGService(cache:RPGPreparationCache(directory:directory),writer:{_ in calls+=1;return response});await service.prepare(app,lesson:lesson,episode:nil)
        let controller=GamePreparationController(service:service,wait:{_ in await withCheckedContinuation{release=$0}});controller.start(app,lesson:lesson);try await wait{release != nil};app.learner.rpgRuns?["es"]?.attempts=2;let latest=app.learner.rpgRuns?["es"];release?.resume();release=nil;try await wait{controller.ready};XCTAssertTrue(controller.commit(app));XCTAssertEqual(app.learner.rpgRuns?["es"],latest);XCTAssertEqual(calls,1);controller.cancel()
    }
    func testLegacyProviderOutageBuildsOriginalLocalPlazaInProviderOrder()async throws {
        let library=try ContentLibrary.load(IntroLibrary.self,name:"intro-es")
        let lesson=try XCTUnwrap(library.units["Pre-A1"]?.lessons.first)
        let input:JSONValue = .object(["lesson":try RPGPreparationPolicy.value(lesson),"target":.string("es"),
                                        "support":.string("en"),"user":.object([:])])
        var order:[String]=[]
        var geminiPrompts:[LegacyGamePrompt]=[]
        var responsesPrompts:[LegacyGamePrompt]=[]
        let provider=LegacyGameProvider(gemini:{prompt in
            order.append("gemini")
            geminiPrompts.append(prompt)
            throw URLError(.notConnectedToInternet)
        },responses:{prompt in
            order.append("responses")
            responsesPrompts.append(prompt)
            throw URLError(.badServerResponse)
        })
        let policy=try TutorialPlazaPolicy()
        let scenario=try await policy.generate(input) { try await provider.send($0) }
        XCTAssertEqual(scenario.id,"tutorialPlaza")
        XCTAssertEqual(scenario.maps.first?.world.width,18)
        XCTAssertEqual(scenario.maps.first?.world.height,14)
        XCTAssertFalse(scenario.quest["steps"].array.isEmpty)
        XCTAssertEqual(geminiPrompts,responsesPrompts)
        XCTAssertEqual(order,geminiPrompts.flatMap { _ in ["gemini","responses"] })
        XCTAssertTrue(geminiPrompts.first?.text.contains("TUTORIAL MODE") == true)
        XCTAssertNil(geminiPrompts.first?.thinkingBudget)
        let localized=try XCTUnwrap(geminiPrompts.first { $0.mimeType == "application/json" })
        XCTAssertEqual(localized.thinkingBudget,2048)
        XCTAssertEqual(localized.temperature,1)
        XCTAssertEqual(policy.failureMessage("es"),"El juego no pudo iniciar. Inténtalo de nuevo.")
    }

    func testLegacyProviderKeepsSuccessfulEmptyReplyAndRejectsStaleFallback()async throws {
        var fallbackCalls=0
        let empty=LegacyGameProvider(gemini:{_ in ""},responses:{_ in fallbackCalls+=1;return "Unexpected"})
        let reply=try await empty.send(.init(text:""))
        XCTAssertEqual(reply,"")
        var current=true
        let stale=LegacyGameProvider(gemini:{_ in
            current=false
            throw URLError(.notConnectedToInternet)
        },responses:{_ in fallbackCalls+=1;return "Unexpected"})
        do {
            _=try await stale.send(.init(text:"")) { if !current { throw CancellationError() } }
            XCTFail("The previous run should not continue")
        } catch is CancellationError {}
        XCTAssertEqual(fallbackCalls,0)
    }

    func testTutorialWarmsBeforeGameStepAndOnlyThenStartsExploration()async throws{
        let app=try app();app.introLibrary=try ContentLibrary.load(IntroLibrary.self,name:"intro-es");let lesson=try XCTUnwrap(app.introLesson),directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer{try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)}
        var calls=0,delays=0,release:CheckedContinuation<Void,Never>?
        let service=RPGService(cache:RPGPreparationCache(directory:directory),writer:{_ in calls+=1;throw URLError(.notConnectedToInternet)}),controller=GamePreparationController(service:service,wait:{_ in delays+=1;await withCheckedContinuation{release=$0}})
        controller.start(app,lesson:lesson,deferReveal:true);try await wait{controller.prepared};XCTAssertEqual(calls,1);XCTAssertEqual(delays,0);XCTAssertFalse(controller.exploring);XCTAssertFalse(controller.ready);XCTAssertNil(app.learner.rpgRuns?["es"]);XCTAssertTrue(app.learner.introSession.visited.isEmpty);XCTAssertEqual(app.learner.totalXP,0)
        controller.reveal();controller.reveal();try await wait{release != nil};XCTAssertEqual(delays,1);XCTAssertFalse(controller.commit(app));release?.resume();release=nil;try await wait{controller.ready};XCTAssertTrue(controller.commit(app));XCTAssertEqual(app.learner.rpgRuns?["es"]?.tutorial,true);XCTAssertEqual(app.learner.totalXP,0);controller.cancel()
    }
    func testTutorialSkipBeforePreparationFinishesCannotCommitOrStartDelay()async throws{
        let app=try app();app.introLibrary=try ContentLibrary.load(IntroLibrary.self,name:"intro-es");let lesson=try XCTUnwrap(app.introLesson),response=try response(),directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer{try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)}
        var release:CheckedContinuation<String,Never>?,delays=0
        let service=RPGService(cache:RPGPreparationCache(directory:directory),writer:{_ in await withCheckedContinuation{release=$0}}),controller=GamePreparationController(service:service,wait:{_ in delays+=1})
        controller.start(app,lesson:lesson,deferReveal:true);try await wait{release != nil};controller.reveal();controller.cancel();release?.resume(returning:response);release=nil;try await Task.sleep(for:.milliseconds(50));XCTAssertFalse(controller.prepared);XCTAssertFalse(controller.ready);XCTAssertEqual(delays,0);XCTAssertFalse(controller.commit(app));XCTAssertNil(app.learner.rpgRuns?["es"])
    }
    func testTutorStagingUsesItsTrackAndDoesNotMutateLessonOrTutorWork()async throws{
        let app=try app();app.introLibrary=try ContentLibrary.load(IntroLibrary.self,name:"intro-es");let catalog=try ContentLibrary.load(JSONValue.self,name:"tutor-curriculum-es"),raw=try XCTUnwrap(catalog["Pre-A1"].array.first?["lessons"].array.first),lesson=try XCTUnwrap(TutorSessionController.decodeLesson(raw)),directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer{try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)}
        let before=app.learner;var release:CheckedContinuation<Void,Never>?
        let service=RPGService(cache:RPGPreparationCache(directory:directory),writer:{_ in throw URLError(.notConnectedToInternet)}),controller=GamePreparationController(service:service,wait:{_ in await withCheckedContinuation{release=$0}})
        controller.start(app,lesson:lesson,tutor:true);try await wait{release != nil};XCTAssertNil(app.learner.rpgRuns?["es"]);XCTAssertEqual(app.learner.tutorLessons,before.tutorLessons);XCTAssertEqual(app.learner.lessonWork,before.lessonWork);XCTAssertEqual(app.learner.totalXP,0);release?.resume();release=nil;try await wait{controller.ready};XCTAssertTrue(controller.commit(app));XCTAssertEqual(app.learner.rpgRuns?["es"]?.tutor,true);XCTAssertEqual(app.learner.lessonWork,before.lessonWork);XCTAssertEqual(app.learner.totalXP,0);controller.cancel()
    }

    func testChangedRunHandoffCanRetryAndResumeItsNewerProgress()async throws{
        let app=try app(),lesson=try lesson(),response=try response(),directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer{try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)};var release:CheckedContinuation<Void,Never>?,calls=0
        let service=RPGService(cache:RPGPreparationCache(directory:directory),writer:{_ in calls+=1;return response}),controller=GamePreparationController(service:service,wait:{_ in await withCheckedContinuation{release=$0}})
        controller.start(app,lesson:lesson);try await wait{release != nil};var newer=try XCTUnwrap(service.stagedRun);newer.id=UUID();newer.attempts=2;app.learner.saveRPG(newer);release?.resume();release=nil;try await wait{controller.ready};XCTAssertFalse(controller.commit(app));XCTAssertNotNil(controller.error);XCTAssertFalse(controller.ready);XCTAssertEqual(app.learner.rpgRuns?["es"],newer)
        controller.start(app,lesson:lesson);try await wait{release != nil};release?.resume();release=nil;try await wait{controller.ready};XCTAssertTrue(controller.commit(app));XCTAssertEqual(app.learner.rpgRuns?["es"],newer);XCTAssertEqual(calls,1);XCTAssertEqual(app.learner.totalXP,0);controller.cancel()
    }

}
