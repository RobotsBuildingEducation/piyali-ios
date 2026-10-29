import XCTest
@testable import Piyali

@MainActor private final class UpcomingReviewNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class UpcomingGameReviewControllerTests:XCTestCase {
    private func app(pool:RPGPreparationPool,writer:@escaping(RPGPreparationPolicy.Request)async throws->String)throws->AppModel {
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated offline account required")}
        let app=AppModel(progressService:UpcomingReviewNoCloud(),gamePreparation:pool,gameReviewWriter:writer);try app.identity.create();app.signedIn=true;app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.onboardingComplete=true;app.learner.target="es";app.learner.support="en";return app
    }
    private func pool()->(RPGPreparationPool,URL){let directory=FileManager.default.temporaryDirectory.appendingPathComponent("UpcomingGameReview-"+UUID().uuidString);return(.init(cache:.init(directory:directory)),directory)}
    private func lessons()throws->(Lesson,Lesson){let units=try ContentLibrary.load([String:[LearningUnit]].self,name:"curriculum-es"),unit=try XCTUnwrap(units["Pre-A1"]?.first{$0.lessons.contains{$0.id == "unit-pre-a1-people-game"}}),index=try XCTUnwrap(unit.lessons.firstIndex{$0.id == "unit-pre-a1-people-game"});XCTAssertGreaterThan(index,0);return(unit.lessons[index-1],unit.lessons[index])}
    private func good()throws->String{try String(contentsOf:XCTUnwrap(Bundle(for:Self.self).url(forResource:"rpg-prepared-story",withExtension:"json")),encoding:.utf8)}
    private func wait(_ condition:()->Bool)async throws{for _ in 0..<600 where !condition(){try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(condition())}
    private func ready(_ lesson:Lesson,app:AppModel){if lesson.isFinalQuiz == true{var quiz=FinalQuizRun(lesson:lesson,learner:app.learner);quiz.answers=Array(repeating:true,count:quiz.rules.passingScore);app.learner.saveQuiz(quiz)};app.beginLesson(lesson);let key=app.learner.completionKey(lesson.id);if var work=app.learner.lessonWork?[key]{work.earnedXP=lesson.xpReward;app.learner.lessonWork?[key]=work};XCTAssertTrue(app.canComplete(lesson))}
    func testActualLessonCompletionWarmsWithoutSelectingOrAwardingTheGameAndForegroundJoins()async throws {
        let (pool,directory)=pool(),(prior,review)=try lessons(),good=try good();var calls=0,release:CheckedContinuation<String,Never>?,request:RPGPreparationPolicy.Request?
        let app=try app(pool:pool){r in calls+=1;request=r;return await withCheckedContinuation{release=$0}};defer{app.upcomingGameReviews.cancel();try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)}
        ready(prior,app:app);app.complete(prior);let progress=app.learner
        try await wait{release != nil};XCTAssertNil(app.learner.rpgRuns?["es"]);XCTAssertEqual(app.learner.completed,progress.completed);XCTAssertEqual(app.learner.totalXP,progress.totalXP)
        let foreground=RPGService(pool:pool,writer:{_ in XCTFail("Foreground must join the existing warm");return good}),preparation=Task{await foreground.prepare(app,lesson:review,episode:nil,stageOnly:true)}
        try await wait{pool.consumerCount==2};XCTAssertEqual(calls,1);release?.resume(returning:good);release=nil;await preparation.value;try await wait{!app.upcomingGameReviews.busy}
        XCTAssertEqual(foreground.stagedRun?.scenario.quest.steps.count,7);XCTAssertNil(app.learner.rpgRuns?["es"]);XCTAssertEqual(try RPGPreparationPolicy.value(app.learner.pendingChanges),try RPGPreparationPolicy.value(progress.pendingChanges));XCTAssertEqual(app.learner.lessonWork,progress.lessonWork);XCTAssertEqual(app.learner.totalXP,progress.totalXP);XCTAssertNotNil(pool.cache.load(account:app.identity.npub,key:try XCTUnwrap(request).cacheKey,support:"en"));XCTAssertEqual(pool.pendingCount,0)
        app.complete(prior);try await Task.sleep(for:.milliseconds(30));XCTAssertEqual(calls,1,"Repeated completion cannot trigger a second warm")
    }
    func testFinishedWarmSurvivesCacheRecreationAndDoesNotReplaceAnUnfinishedGame()async throws {
        let (pool,directory)=pool(),(prior,review)=try lessons(),good=try good();var calls=0
        let app=try app(pool:pool){_ in calls+=1;return good};defer{app.upcomingGameReviews.cancel();try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)}
        let savedService=RPGService(pool:pool,writer:{_ in "invalid"});await savedService.prepare(app,lesson:review,episode:nil);let saved=app.learner.rpgRuns?["es"]
        app.upcomingGameReviews.completed(prior,app:app);try await wait{!app.upcomingGameReviews.busy};XCTAssertEqual(app.learner.rpgRuns?["es"],saved);XCTAssertEqual(calls,0,"An unfinished matching game already owns its content")
        app.learner.rpgRuns=nil;app.upcomingGameReviews.completed(prior,app:app);try await wait{!app.upcomingGameReviews.busy};XCTAssertEqual(calls,1)
        let reopened=RPGService(cache:RPGPreparationCache(directory:directory),writer:{_ in XCTFail("Completed warm must be reusable after pool recreation");return ""});await reopened.prepare(app,lesson:review,episode:nil,stageOnly:true);XCTAssertEqual(reopened.stagedRun?.scenario.quest.steps.count,7);XCTAssertNil(app.learner.rpgRuns?["es"]);XCTAssertEqual(app.learner.totalXP,0)
    }
    func testCancellingOneConsumerKeepsTheOtherAndAllCancelledResponsesCannotPoisonCache()async throws {
        for cancelWarm in [false,true]{let(pool,directory)=pool(),(prior,review)=try lessons(),good=try good();var release:CheckedContinuation<String,Never>?,request:RPGPreparationPolicy.Request?
            let app=try app(pool:pool){r in request=r;return await withCheckedContinuation{release=$0}};app.upcomingGameReviews.completed(prior,app:app);try await wait{release != nil}
            let foreground=RPGService(pool:pool),operation=Task{await foreground.prepare(app,lesson:review,episode:nil,stageOnly:true)};try await wait{pool.consumerCount==2}
            if cancelWarm{app.upcomingGameReviews.cancel()}else{foreground.cancel()};try await wait{pool.consumerCount==1};release?.resume(returning:good);release=nil;await operation.value;try await wait{!app.upcomingGameReviews.busy};XCTAssertNotNil(pool.cache.load(account:app.identity.npub,key:try XCTUnwrap(request).cacheKey,support:"en"));if cancelWarm{XCTAssertEqual(foreground.stagedRun?.scenario.quest.steps.count,7)}else{XCTAssertNil(foreground.stagedRun)};XCTAssertNil(app.learner.rpgRuns?["es"]);app.upcomingGameReviews.cancel();try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)
        }
        let(pool,directory)=pool(),(prior,_)=try lessons(),good=try good();var release:CheckedContinuation<String,Never>?,request:RPGPreparationPolicy.Request?
        let app=try app(pool:pool){r in request=r;return await withCheckedContinuation{release=$0}};defer{app.upcomingGameReviews.cancel();try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)};app.upcomingGameReviews.completed(prior,app:app);try await wait{release != nil};app.upcomingGameReviews.cancel();try await wait{pool.pendingCount==0};release?.resume(returning:good);release=nil;try await Task.sleep(for:.milliseconds(30));XCTAssertNil(pool.cache.load(account:app.identity.npub,key:try XCTUnwrap(request).cacheKey,support:"en"));XCTAssertNil(app.learner.rpgRuns?["es"])
    }
    func testConcurrentRequestsKeepAccountAndSupportCachesSeparate()async throws {
        let(pool,directory)=pool(),(_,lesson)=try lessons(),good=try good(),arabic=try String(contentsOf:XCTUnwrap(Bundle.main.url(forResource:"rpg-prepared-fixture-ar",withExtension:"json")),encoding:.utf8),policy=try RPGPreparationPolicy(),library=try ContentLibrary.load(RPGLibrary.self,name:"rpg-es"),review=try XCTUnwrap(library.reviews[lesson.id]),data=try RPGPreparationPolicy.value(lesson).setting("gameReviewContext",review.context),en=try policy.request(scenario:XCTUnwrap(review.bySupport["en"]),lesson:data,target:"es",support:"en"),ar=try policy.request(scenario:XCTUnwrap(review.bySupport["ar"]),lesson:data,target:"es",support:"ar")
        defer{try? FileManager.default.removeItem(at:directory)};XCTAssertEqual(en.cacheKey,ar.cacheKey);var releases:[String:CheckedContinuation<String,Never>]=[:]
        let a=Task{await pool.prepared(request:en,policy:policy,account:"public-test-account-a",support:"en",valid:{true},produce:{await withCheckedContinuation{releases["a-en"]=$0}})},b=Task{await pool.prepared(request:en,policy:policy,account:"public-test-account-b",support:"en",valid:{true},produce:{await withCheckedContinuation{releases["b-en"]=$0}})},c=Task{await pool.prepared(request:ar,policy:policy,account:"public-test-account-a",support:"ar",valid:{true},produce:{await withCheckedContinuation{releases["a-ar"]=$0}})}
        try await wait{releases.count==3};XCTAssertEqual(pool.pendingCount,3);releases["a-en"]?.resume(returning:good);releases["b-en"]?.resume(returning:good);releases["a-ar"]?.resume(returning:arabic);releases=[:]
        let ra=await a.value,rb=await b.value,rc=await c.value;XCTAssertNotNil(ra);XCTAssertNotNil(rb);XCTAssertNotNil(rc);XCTAssertEqual(pool.pendingCount,0);XCTAssertNotNil(pool.cache.load(account:"public-test-account-a",key:en.cacheKey,support:"en"));XCTAssertNotNil(pool.cache.load(account:"public-test-account-b",key:en.cacheKey,support:"en"));XCTAssertNotNil(pool.cache.load(account:"public-test-account-a",key:ar.cacheKey,support:"ar"));XCTAssertNil(pool.cache.load(account:"public-test-account-b",key:ar.cacheKey,support:"ar"))
    }
    func testAbandonedResponseCannotOverwriteSameKeyRetry()async throws {
        let(pool,directory)=pool(),(_,lesson)=try lessons(),good=try good();var release:CheckedContinuation<String,Never>?,request:RPGPreparationPolicy.Request?
        let app=try app(pool:pool){_ in ""};defer{app.upcomingGameReviews.cancel();try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)}
        let old=RPGService(pool:pool,writer:{r in request=r;return await withCheckedContinuation{release=$0}}),operation=Task{await old.prepare(app,lesson:lesson,episode:nil,stageOnly:true)};try await wait{release != nil};old.cancel();try await wait{pool.pendingCount==0}
        let fresh=RPGService(pool:pool,writer:{_ in good});await fresh.prepare(app,lesson:lesson,episode:nil,stageOnly:true);let before=pool.cache.load(account:app.identity.npub,key:try XCTUnwrap(request).cacheKey,support:"en");XCTAssertNotNil(before)
        let stale=try JSONDecoder().decode(JSONValue.self,from:Data(good.utf8)).setting("title",.string("Abandoned response"));release?.resume(returning:stale.json);release=nil;await operation.value;XCTAssertNil(old.stagedRun);XCTAssertEqual(fresh.stagedRun?.scenario.quest.steps.count,7);XCTAssertEqual(pool.cache.load(account:app.identity.npub,key:request!.cacheKey,support:"en"),before);XCTAssertNil(app.learner.rpgRuns?["es"])
    }
    func testScopeAndEntitlementChangesRejectLateWarmAndReleaseAllLeases()async throws {
        for changed in ["target","support","level","signedOut","access","background"] {let(pool,directory)=pool(),(prior,_)=try lessons(),good=try good();var release:CheckedContinuation<String,Never>?,request:RPGPreparationPolicy.Request?
            let app=try app(pool:pool){r in request=r;return await withCheckedContinuation{release=$0}};let account=app.identity.npub;app.upcomingGameReviews.completed(prior,app:app);try await wait{release != nil}
            switch changed{case "target":app.learner.target="ja";case "support":app.learner.support="ar";case "level":app.learner.level="A1";case "signedOut":app.signedIn=false;case "access":app.subscription.updatePracticeXP(300);default:app.upcomingGameReviews.setApplicationActive(false)}
            try await wait{!app.upcomingGameReviews.busy && pool.pendingCount==0};release?.resume(returning:good);release=nil;try await Task.sleep(for:.milliseconds(30));XCTAssertNil(pool.cache.load(account:account,key:try XCTUnwrap(request).cacheKey,support:"en"),changed);XCTAssertNil(app.learner.rpgRuns?["es"],changed);XCTAssertNil(app.upcomingGameReviews.lastWarmedLessonID);app.upcomingGameReviews.cancel();try? app.identity.disconnect();try? FileManager.default.removeItem(at:directory)
        }
    }
}
