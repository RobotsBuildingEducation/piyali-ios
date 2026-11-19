import XCTest
@testable import Piyali

@MainActor private final class RPGPreparationNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class RPGPreparationControllerTests:XCTestCase {
    private func app()throws->AppModel{
        let e=ProcessInfo.processInfo.environment
        guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Explicit isolated offline identity required")}
        let app=AppModel(progressService:RPGPreparationNoCloud());try app.identity.create();app.signedIn=true;app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.onboardingComplete=true;app.learner.target="es";app.learner.support="en";XCTAssertTrue(app.subscription.hasAccess);return app
    }
    private func lesson()throws->Lesson{let units=try ContentLibrary.load([String:[LearningUnit]].self,name:"curriculum-es");return try XCTUnwrap(units["Pre-A1"]?.flatMap(\.lessons).first{$0.id == "unit-pre-a1-people-game"})}
    private func response()throws->String{try String(contentsOf:XCTUnwrap(Bundle(for:Self.self).url(forResource:"rpg-prepared-story",withExtension:"json")),encoding:.utf8)}
    private func cache()->(RPGPreparationCache,URL){let url=FileManager.default.temporaryDirectory.appendingPathComponent("RPGPreparationController-"+UUID().uuidString);return(RPGPreparationCache(directory:url),url)}
    private func wait(_ condition:()->Bool)async throws{for _ in 0..<400 where !condition(){try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(condition())}
    func testOriginalCurriculumPreparationResumeAndNewRunReuseSurviveCacheRecreation()async throws{
        let app=try app(),lesson=try lesson(),response=try response(),(cache,directory)=cache();defer{try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)}
        var calls=0,request:RPGPreparationPolicy.Request?
        let service=RPGService(cache:cache,writer:{r in calls+=1;request=r;return "```json\n"+response+"\n```"})
        await service.prepare(app,lesson:lesson,episode:nil);let run=try XCTUnwrap(app.learner.rpgRuns?["es"]);XCTAssertEqual(run.scenario.quest.steps.count,7);XCTAssertEqual(calls,1)
        XCTAssertTrue(try XCTUnwrap(request).prompt.contains("Structured curriculum lessons:"));XCTAssertTrue(request!.prompt.contains("Unit objectives:"));XCTAssertFalse(request!.prompt.contains(app.identity.npub))
        app.learner.rpgRuns?["es"]?.position.x += 1;app.learner.rpgRuns?["es"]?.attempts=2
        let saved=app.learner.rpgRuns?["es"];await service.prepare(app,lesson:lesson,episode:nil);XCTAssertEqual(app.learner.rpgRuns?["es"],saved);XCTAssertEqual(calls,1)
        let reopened=RPGService(cache:RPGPreparationCache(directory:directory),writer:{_ in calls+=1;throw URLError(.notConnectedToInternet)})
        await reopened.prepare(app,lesson:lesson,episode:nil,fresh:true);let fresh=try XCTUnwrap(app.learner.rpgRuns?["es"]);XCTAssertNotEqual(fresh.id,run.id);XCTAssertEqual(fresh.scenario.quest.steps.count,7);XCTAssertEqual(calls,1);XCTAssertEqual(fresh.attempts,0);XCTAssertEqual(app.learner.totalXP,0)
        app.learner.support="fr";await reopened.prepare(app,lesson:lesson,episode:nil,fresh:true);XCTAssertEqual(calls,2,"A different support language must not borrow Latin-script narration from the English cache");XCTAssertEqual(app.learner.rpgRuns?["es"]?.support,"fr");XCTAssertEqual(app.learner.rpgRuns?["es"]?.scenario.quest.steps.count,3)
    }
    func testMalformedContentDoesNotPoisonCacheAndNextPreparationCanRecover()async throws{
        let app=try app(),lesson=try lesson(),good=try response(),(cache,directory)=cache();defer{try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)}
        var calls=0,request:RPGPreparationPolicy.Request?
        let service=RPGService(cache:cache,writer:{r in calls+=1;request=r;return calls == 1 ? "not JSON":good})
        await service.prepare(app,lesson:lesson,episode:nil);XCTAssertEqual(app.learner.rpgRuns?["es"]?.scenario.quest.steps.count,3);XCTAssertNil(cache.load(account:app.identity.npub,key:try XCTUnwrap(request).cacheKey,support:"en"))
        await service.prepare(app,lesson:lesson,episode:nil,fresh:true);XCTAssertEqual(calls,2);XCTAssertEqual(app.learner.rpgRuns?["es"]?.scenario.quest.steps.count,7);XCTAssertNotNil(cache.load(account:app.identity.npub,key:request!.cacheKey,support:"en"));XCTAssertEqual(app.learner.totalXP,0)
    }
    func testDuplicatePreparationSharesOneRequestAndCancellationRejectsLateCacheAndProgress()async throws{
        let app=try app(),lesson=try lesson(),good=try response(),(cache,directory)=cache();defer{try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)}
        var calls=0,complete:CheckedContinuation<String,Never>?,request:RPGPreparationPolicy.Request?
        let service=RPGService(cache:cache,writer:{r in calls+=1;request=r;return await withCheckedContinuation{complete=$0}})
        let first=Task{await service.prepare(app,lesson:lesson,episode:nil)};try await wait{complete != nil};let second=Task{await service.prepare(app,lesson:lesson,episode:nil)};await Task.yield();XCTAssertEqual(calls,1)
        service.cancel();complete?.resume(returning:good);complete=nil;await first.value;await second.value
        XCTAssertNil(app.learner.rpgRuns?["es"]);XCTAssertNil(cache.load(account:app.identity.npub,key:try XCTUnwrap(request).cacheKey,support:"en"));XCTAssertFalse(service.busy);XCTAssertNil(service.error)
    }
    func testNewLanguagePreparationWinsOverOldResponseAndAccountCacheIsPrivate()async throws{
        let app=try app(),lesson=try lesson(),good=try response(),(cache,directory)=cache();defer{try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)}
        let account=app.identity.npub;var complete:CheckedContinuation<String,Never>?,firstRequest:RPGPreparationPolicy.Request?,calls=0
        let service=RPGService(cache:cache,writer:{r in calls+=1;if calls == 1{firstRequest=r;return await withCheckedContinuation{complete=$0}};return good})
        let old=Task{await service.prepare(app,lesson:lesson,episode:nil)};try await wait{complete != nil};app.learner.support="fr";await service.prepare(app,lesson:lesson,episode:nil,fresh:true)
        let current=app.learner.rpgRuns?["es"];XCTAssertEqual(current?.support,"fr");XCTAssertEqual(current?.scenario.quest.steps.count,7)
        complete?.resume(returning:good);complete=nil;await old.value;XCTAssertEqual(app.learner.rpgRuns?["es"],current);XCTAssertNil(cache.load(account:account,key:try XCTUnwrap(firstRequest).cacheKey,support:"en"))
        try app.identity.disconnect();try app.identity.create();app.subscription.bind(app.identity);app.subscription.updatePracticeXP(0);XCTAssertNotEqual(app.identity.npub,account);XCTAssertTrue(app.subscription.hasAccess);await service.prepare(app,lesson:lesson,episode:nil,fresh:true);XCTAssertEqual(calls,3,"A new account must not reuse the other learner's preparation cache")
    }
    func testQuotaWithdrawalAndLevelChangeRejectPendingPreparation()async throws{
        for change in ["quota","level"]{
            let app=try app(),lesson=try lesson(),good=try response(),(cache,directory)=cache();var complete:CheckedContinuation<String,Never>?,request:RPGPreparationPolicy.Request?
            let service=RPGService(cache:cache,writer:{r in request=r;return await withCheckedContinuation{complete=$0}}),task=Task{await service.prepare(app,lesson:lesson,episode:nil)};try await wait{complete != nil}
            if change == "quota"{app.learner.xpByLanguage=["es":300]}else{app.learner.level="A1"}
            complete?.resume(returning:good);complete=nil;await task.value;XCTAssertNil(app.learner.rpgRuns?["es"]);XCTAssertNil(cache.load(account:app.identity.npub,key:try XCTUnwrap(request).cacheKey,support:"en"));XCTAssertFalse(service.busy)
            try app.identity.disconnect();try? FileManager.default.removeItem(at:directory)
        }
    }
    func testClosingDialogueCancelsLateSpeechAndReopenedTurnCanGradeExactlyOnce()async throws{
        let app=try app(),lesson=try lesson(),good=try response(),(cache,directory)=cache();defer{try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)}
        var calls=0,complete:CheckedContinuation<String,Never>?,prompt=""
        let service=RPGService(cache:cache,writer:{_ in good},speaker:{p in prompt=p;calls+=1;if calls == 1{return await withCheckedContinuation{complete=$0}};return "```json\n{\"grade\":\"full\",\"reply\":\"¡Gracias por ayudar!\",\"tip\":\"\"}\n```"})
        await service.prepare(app,lesson:lesson,episode:nil);app.learner.rpgRuns?["es"]?.stepIndex=2;let before=try XCTUnwrap(app.learner.rpgRuns?["es"])
        let old=Task{await service.speak("Hola, soy Ana.",app:app)};try await wait{complete != nil};XCTAssertTrue(prompt.contains(before.npc!.name));XCTAssertTrue(prompt.contains("<<<PLAYER_SPEECH>>>\nHola, soy Ana.\n<<<END_PLAYER_SPEECH>>>"))
        await service.speak("duplicate",app:app);XCTAssertEqual(calls,1);service.cancelSpeech();XCTAssertFalse(service.busy)
        await service.speak("Hola, soy Ana.",app:app);let completed=try XCTUnwrap(app.learner.rpgRuns?["es"]);XCTAssertTrue(completed.resolved);XCTAssertEqual(completed.score,100);XCTAssertEqual(completed.feedback,"¡Gracias por ayudar!")
        complete?.resume(returning:"{\"grade\":\"miss\",\"reply\":\"OLD\",\"tip\":\"OLD\"}");complete=nil;await old.value;XCTAssertEqual(app.learner.rpgRuns?["es"],completed);XCTAssertEqual(app.learner.totalXP,0)
    }
    func testInvalidSpeechUsesOriginalLocalMatcherAndNeverStallsNonemptyRoleplay()async throws{
        let app=try app(),lesson=try lesson(),good=try response(),(cache,directory)=cache();defer{try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)}
        let service=RPGService(cache:cache,writer:{_ in good},speaker:{_ in "malformed"});await service.prepare(app,lesson:lesson,episode:nil);app.learner.rpgRuns?["es"]?.stepIndex=2
        let example=try XCTUnwrap(app.learner.rpgRuns?["es"]?.node?.speechExample);await service.speak(example,app:app);XCTAssertEqual(app.learner.rpgRuns?["es"]?.score,100);XCTAssertTrue(app.learner.rpgRuns?["es"]?.resolved == true)
        await service.prepare(app,lesson:lesson,episode:nil,fresh:true);app.learner.rpgRuns?["es"]?.stepIndex=2;await service.speak("unrelated English words",app:app);XCTAssertEqual(app.learner.rpgRuns?["es"]?.score,50);XCTAssertTrue(app.learner.rpgRuns?["es"]?.resolved == true)
    }
    func testPendingAccountAndSpeechOwnershipChangesCannotApplyOldResults()async throws{
        for change in ["account","speech-quota","speech-run"]{
            let app=try app(),lesson=try lesson(),good=try response(),(cache,directory)=cache();var complete:CheckedContinuation<String,Never>?,request:RPGPreparationPolicy.Request?
            let owner=app.identity.npub,service=RPGService(cache:cache,writer:{r in request=r;if change == "account"{return await withCheckedContinuation{complete=$0}};return good},speaker:{_ in await withCheckedContinuation{complete=$0}})
            let task:Task<Void,Never>
            if change == "account"{task=Task{await service.prepare(app,lesson:lesson,episode:nil)}}
            else{await service.prepare(app,lesson:lesson,episode:nil);app.learner.rpgRuns?["es"]?.stepIndex=2;task=Task{await service.speak("Hola, soy Ana.",app:app)}}
            try await wait{complete != nil}
            if change == "account"{try app.identity.disconnect();try app.identity.create();app.subscription.bind(app.identity);app.subscription.updatePracticeXP(0)}
            else if change == "speech-quota"{app.learner.xpByLanguage=["es":300]}
            else{app.learner.rpgRuns?["es"]?.id=UUID()}
            let before=app.learner.rpgRuns?["es"];complete?.resume(returning:change == "account" ? good:"{\"grade\":\"full\",\"reply\":\"LATE\",\"tip\":\"\"}");complete=nil;await task.value
            XCTAssertEqual(app.learner.rpgRuns?["es"],before);XCTAssertFalse(service.busy)
            if change == "account"{XCTAssertNil(cache.load(account:owner,key:try XCTUnwrap(request).cacheKey,support:"en"))}
            try app.identity.disconnect();try? FileManager.default.removeItem(at:directory)
        }
    }
    func testUnavailableLanguageNeverReusesThePreviousLanguageLibrary()async throws{
        let app=try app(),lesson=try lesson(),good=try response(),(cache,directory)=cache();defer{try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)}
        var calls=0;let service=RPGService(cache:cache,writer:{_ in calls+=1;return good});await service.prepare(app,lesson:lesson,episode:nil);XCTAssertEqual(calls,1)
        app.learner.target="missing-language";await service.prepare(app,lesson:lesson,episode:nil);XCTAssertNil(app.learner.rpgRuns?["missing-language"]);XCTAssertNil(service.library);XCTAssertNotNil(service.error);XCTAssertFalse(service.busy);XCTAssertEqual(calls,1)
    }

}
