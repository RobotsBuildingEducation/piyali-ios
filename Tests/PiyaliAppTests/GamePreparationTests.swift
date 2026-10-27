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
}
