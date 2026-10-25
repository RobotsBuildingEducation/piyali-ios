import XCTest
@testable import Piyali

@MainActor private final class TutorNoCloud:LearnerProgressService {
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor private final class TutorTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    var session:JSONValue = .null,events:[JSONValue]=[],closed=false,microphone=false
    func connect(session:JSONValue)async throws{self.session=session;closed=false;onOpen?()}
    func send(_ event:JSONValue)->Bool{events.append(event);return !closed}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func setMicrophoneEnabled(_ enabled:Bool){microphone=enabled}
    func close(){closed=true}
    func assistant(_ text:String,id:String="opening"){
        onEvent?(.object(["type":.string("response.created"),"response":.object(["id":.string(id)])]))
        onEvent?(.object(["type":.string("response.done"),"response":.object(["id":.string(id),"status":.string("completed"),"output":.array([.object(["content":.array([.object(["transcript":.string(text)])])])])])]))
        onEvent?(.object(["type":.string("output_audio_buffer.stopped")]))
    }
}
@MainActor final class TutorSessionTests:XCTestCase {
    private func app(progressService:(any LearnerProgressService)?=nil)async throws->AppModel {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,TutorSessionController.fixture == false else{throw XCTSkip("Isolated identity and injected transport required")}
        let app=AppModel(progressService:progressService ?? TutorNoCloud());try app.identity.create();app.signedIn=true;app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.target="es";app.learner.support="en";app.learner.onboardingComplete=true;await app.reloadContent();return app
    }
    private func provider(_ grade:JSONValue = .object(["successful":.bool(false),"confidence":.number(0.1)]))->TutorProvider{.init(judge:{_ in grade},quote:{_,_,_ in .null})}
    private func session(_ app:AppModel,_ transport:TutorTransport,provider:TutorProvider?=nil)async->TutorSessionController{let session=TutorSessionController(live:LiveTutorService(permission:{true},transportFactory:{transport}),provider:provider ?? self.provider());await session.prepare(app);return session}
    private func input(_ text:String,_ id:String=UUID().uuidString)->RealtimeVoiceState.InputTurn{.init(id:id,text:text,answered:"Say hola.",responseID:nil)}
    func testOpeningPreviewAndWelcomeAreUngradedThenExactSpeechAdvancesOnce()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport(),session=await session(app,transport)
        XCTAssertEqual(session.id,"lesson-tutorial-1");XCTAssertEqual(session.state["items"].array.count,7);XCTAssertEqual(app.learner.totalXP,0);XCTAssertTrue(app.learner.tutorLessons?.isEmpty ?? true)
        await session.start(app);XCTAssertEqual(transport.session["audio"]["output"]["voice"].string,"marin");XCTAssertEqual(transport.session["audio"]["input"]["turn_detection"]["silence_duration_ms"].number,1200);XCTAssertEqual(transport.session["audio"]["input"]["turn_detection"]["create_response"],.bool(false))
        transport.assistant("Welcome! Ready to learn?");await session.input(input("yes","welcome"),app:app);XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.gradedByLanguage)
        transport.assistant("Say hola.",id:"r2");await session.input(input("hola","u1"),app:app)
        let earned=app.learner.totalXP;XCTAssertTrue((3...7).contains(earned));XCTAssertEqual(app.learner.tutorProgress(session.id).items,["hello"]);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1)
        await session.input(input("hola","u1"),app:app);XCTAssertEqual(app.learner.totalXP,earned);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1)
        session.flushDraft(app);let draft=session.record(app)["conversationDraft"];XCTAssertEqual(draft["version"].number,1);XCTAssertTrue(draft["messages"].array.contains(where:{$0["text"].string == "hola"}));await session.stop(app)
    }
    func testHelpUncertaintyAndForeignScriptDoNotEarnOrReduceScoreAndFreshStartIsPrivate()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport(),session=await session(app,transport)
        await session.start(app);transport.assistant("Welcome!");await session.input(input("yes"),app:app);transport.assistant("Say hola.",id:"r2")
        await session.input(input("I do not know"),app:app);await session.input(input("नमस्ते"),app:app);XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.gradedByLanguage)
        await session.input(input("hola"),app:app);let xp=app.learner.totalXP;await session.stop(app);await session.start(app)
        XCTAssertTrue(session.messages.isEmpty);XCTAssertEqual(app.learner.totalXP,xp)
        let prompt=try XCTUnwrap(transport.events.last(where:{$0["type"].string == "response.create"}))["response"]["instructions"].string
        XCTAssertTrue(prompt.contains("hola"));XCTAssertFalse(prompt.contains("undefined"));await session.stop(app)
    }
    func testLateJudgeCannotApplyAfterSupportChanges()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};var held:CheckedContinuation<JSONValue,Error>?;var provider=provider();provider.judge={_ in try await withCheckedThrowingContinuation{held=$0}}
        let transport=TutorTransport(),session=await session(app,transport,provider:provider);await session.start(app);transport.assistant("Welcome!");await session.input(input("yes"),app:app);transport.assistant("Say hola.",id:"r2")
        let work=Task{await session.input(input("a fresh attempt"),app:app)}
        for _ in 0..<100 where held == nil{await Task.yield()};XCTAssertNotNil(held);app.learner.support="ar";held?.resume(returning:.object(["successful":.bool(true),"confidence":.number(1)]));await work.value
        XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.gradedByLanguage);await session.stop(app,saveDraft:false)
    }
    func testPauseRetainsVisibleTranscriptAndMuteWithoutRegradingOnResume()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport(),session=await session(app,transport);await session.start(app);transport.assistant("Welcome!");await session.input(input("yes"),app:app);transport.assistant("Say hola.",id:"r2");await session.input(input("hola"),app:app);let xp=app.learner.totalXP,count=session.messages.count
        session.live.setMuted(true);await session.pause(app);XCTAssertTrue(session.paused);XCTAssertEqual(session.messages.count,count);await session.start(app,resuming:true);XCTAssertTrue(session.live.muted);XCTAssertEqual(session.messages.count,count);XCTAssertEqual(app.learner.totalXP,xp);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1);await session.stop(app)
    }
    func testGameUsesOnlyTutorBonusAndFailedCloudRetryDoesNotDuplicateIt()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport(),session=await session(app,transport);await session.complete(app,ready:true,gameCompleted:true)
        XCTAssertTrue(session.completionPending);XCTAssertNotNil(session.error);XCTAssertEqual(app.learner.totalXP,50);XCTAssertEqual(app.learner.pendingChanges?.filter{$0.source == .speak}.count,1);XCTAssertEqual(app.learner.pendingChanges?.filter{$0.source == .lesson}.count,0)
        await session.complete(app,ready:true,gameCompleted:true);XCTAssertEqual(app.learner.totalXP,50);XCTAssertNil(session.completion);XCTAssertEqual(app.learner.pendingChanges?.filter{$0.source == .speak}.count,1);await session.stop(app)
    }
}

extension TutorSessionTests {
    func testWarmupPhraseEarnsOnceWhileCapabilityNeedsItsOwnEvidence()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport();var advanced=false,judges=0
        var p=provider();p.judge={prompt in judges += 1;XCTAssertTrue(prompt.contains("Current agenda objective"));return .object(["successful":.bool(true),"confidence":.number(1),"objectiveAdvanced":.bool(advanced)])}
        let session=await session(app,transport,provider:p),unit=try XCTUnwrap(session.catalog["A1"].array.first),lesson=try XCTUnwrap(unit["lessons"].array.first);app.learner.tutorLevels=["es":"A1"];session.adoptLevel(app);session.select(app,lesson:lesson,unit:unit)
        let items=session.state["items"].array,index=try XCTUnwrap(items.firstIndex(where:{$0["isExactTargetItem"] == .bool(false)})),typed=try XCTUnwrap(session.typedLesson),prior=JSONValue.object(Dictionary(uniqueKeysWithValues:items.prefix(index).map{($0["id"].string,.bool(true))}))
        app.learner.storeTutorState(lesson:typed,data:.object(["agenda":prior]));session.refresh(app);let objective=session.state["currentItem"]["id"]
        await session.start(app);transport.assistant("Say ‘hola’.");await session.input(input("hola"),app:app);let xp=app.learner.totalXP
        XCTAssertTrue((3...7).contains(xp));XCTAssertEqual(session.state["currentItem"]["id"],objective);XCTAssertEqual(judges,1)
        advanced=true;await session.input(input("hola."),app:app);XCTAssertEqual(judges,2);XCTAssertNotEqual(session.state["currentItem"]["id"],objective);XCTAssertEqual(app.learner.gradedByLanguage?["es"],2);XCTAssertTrue((3...7).contains(app.learner.totalXP-xp));await session.stop(app)
    }
    func testQuizHelpStaysPutAndConfidentWrongRoundResetsCursorWithoutXP()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport();var attempted=false
        var p=provider();p.judge={_ in .object(["successful":.bool(false),"confidence":.number(1),"quizAnswered":.bool(attempted),"mistake":.bool(false)])}
        let session=await session(app,transport,provider:p),unit=try XCTUnwrap(session.catalog["Pre-A1"].array.first(where:{$0["lessons"].array.contains(where:{$0["isFinalQuiz"].boolean})})),lesson=try XCTUnwrap(unit["lessons"].array.first(where:{$0["isFinalQuiz"].boolean}));session.select(app,lesson:lesson,unit:unit);await session.start(app);transport.assistant("Choose the answer.")
        let first=session.state["currentItem"]["id"],count=session.state["items"].array.count;XCTAssertGreaterThan(count,1)
        await session.input(input("Please explain"),app:app);XCTAssertEqual(session.state["currentItem"]["id"],first)
        attempted=true;for i in 0..<count{await session.input(input("wrong public answer \(i)"),app:app)}
        XCTAssertEqual(session.state["currentItem"]["id"],first);XCTAssertTrue(app.learner.tutorProgress(session.id).items.isEmpty);XCTAssertEqual(session.record(app)["tutorAgendaProgress"]["quiz"]["attemptNumber"].number,2);XCTAssertEqual(app.learner.totalXP,0);XCTAssertEqual(app.learner.tutorProgress(session.id).earnedXP,0);await session.stop(app)
    }
}

@MainActor private final class TutorAcknowledgment:LearnerProgressService {
    var duringSave:(()->Void)?
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{
        duringSave?();var acknowledged=state
        acknowledged.acknowledgedEventIDs=Set((state.pendingChanges ?? []).map(\.id));acknowledged.pendingChanges=[]
        return acknowledged
    }
}
extension TutorSessionTests {
    func testAcknowledgedCompletionKeepsItsReviewAcrossTheTrialBoundaryAndSelectsNextLesson()async throws {
        let cloud=TutorAcknowledgment(),app=try await app(progressService:cloud);defer{try? app.identity.disconnect()};let transport=TutorTransport(),session=await session(app,transport),completedID=session.id
        let items=JSONValue.object(Dictionary(uniqueKeysWithValues:session.state["items"].array.map{($0["id"].string,.bool(true))})),record:JSONValue = .object(["status":.string("in_progress"),"earnedXp":.number(50),"tutorAgendaProgress":.object(["schemaVersion":.number(2),"items":items])])
        app.learner.tutorLessons=[app.learner.tutorKey(completedID):TutorSourceProgress.importing(record)];app.learner.xpByLanguage=["es":299];app.subscription.updatePracticeXP(299);session.refresh(app)
        XCTAssertTrue(app.subscription.hasAccess);XCTAssertTrue(session.state["isComplete"].boolean)
        cloud.duringSave={app.subscription.updatePracticeXP(app.learner.subscriptionXP);XCTAssertFalse(app.subscription.hasAccess);XCTAssertTrue(session.completionPending)}
        await session.complete(app,ready:true)
        XCTAssertEqual(app.learner.totalXP,349);XCTAssertEqual(session.completion?["xpEarned"].number,50);XCTAssertEqual(session.id,"lesson-pre-a1-1-1");XCTAssertTrue(app.learner.completed.contains(app.learner.tutorKey(completedID)));XCTAssertTrue(app.learner.pendingChanges?.isEmpty == true)
        session.closeCompletion();XCTAssertNil(session.completion);XCTAssertEqual(session.review?["items"].array.count,7);XCTAssertTrue(session.completionPending)
        session.closeReview();XCTAssertFalse(session.completionPending);XCTAssertFalse(app.subscription.hasAccess);XCTAssertEqual(app.learner.totalXP,349);await session.stop(app)
    }
}

extension TutorSessionTests {
    func testCompletedVoiceLessonAdvancesSessionAgendaAndRewardsPracticeWithoutRecompletion()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport(),session=await session(app,transport,provider:provider(.object(["successful":.bool(true),"confidence":.number(1),"objectiveAdvanced":.bool(true)])))
        let unit=try XCTUnwrap(session.catalog["A1"].array.first),lesson=try XCTUnwrap(unit["lessons"].array.first),id=lesson["id"].string,required=session.xpRequired(lesson)
        let canonical:JSONValue = .object(["lessonId":.string(id),"status":.string("completed"),"earnedXp":.number(Double(required)),"completedAt":.string("2026-10-25T00:00:00Z"),"foreign":.string("keep")])
        app.learner.tutorLevels=["es":"A1"];session.adoptLevel(app);app.learner.completed.insert(app.learner.tutorKey(id));app.learner.tutorLessons=[app.learner.tutorKey(id):TutorSourceProgress.importing(canonical)]
        session.select(app,lesson:lesson,unit:unit);let first=session.state["currentItem"]["id"];XCTAssertTrue(session.practicingCompletedLesson);XCTAssertFalse(first.string.isEmpty)
        await session.start(app);transport.assistant("Attempt this practice objective.")
        await session.input(input("A public practice response","review-turn"),app:app);let xp=app.learner.totalXP
        XCTAssertTrue((3...7).contains(xp));XCTAssertNotEqual(session.state["currentItem"]["id"],first);XCTAssertEqual(app.learner.tutorProgress(id).sourceState,canonical)
        XCTAssertEqual(app.learner.pendingChanges?.filter{$0.source == .speak}.count ?? 0,0);XCTAssertFalse(session.completionPending);XCTAssertNil(session.completion);XCTAssertTrue(session.live.connected)
        session.refresh(app);XCTAssertNotEqual(session.state["currentItem"]["id"],first,"Cloud refresh does not reset session-only progress")
        await session.complete(app,ready:true);XCTAssertEqual(app.learner.totalXP,xp);XCTAssertNil(session.completion)
        session.flushDraft(app);XCTAssertEqual(app.learner.tutorProgress(id).sourceState,canonical)
        await session.stop(app);await session.start(app);XCTAssertTrue(session.messages.isEmpty);XCTAssertNotEqual(session.state["currentItem"]["id"],first)
        await session.stop(app)
    }
    func testTutorInheritsHighestOtherCourseUnlockButKeepsExplicitLowerBrowsingChoice()async throws {
        let app=try await app();defer{try? app.identity.disconnect()}
        app.learner.place(PlacementAssessment.estimate(["read_write"])!);app.learner.tutorLevels=nil;await app.reloadContent()
        XCTAssertEqual(app.learner.tutorLevel,"B1");XCTAssertEqual(app.tutorLevels.last,"B1")
        app.setTutorLevel("Pre-A1");await app.reloadContent();XCTAssertEqual(app.learner.tutorLevel,"Pre-A1");XCTAssertEqual(app.tutorLevels.last,"B1")
        app.learner.tutorUnlockedLevels=["es":"C1"];XCTAssertEqual(app.tutorLevels.last,"C1");XCTAssertEqual(app.learner.tutorLevel,"Pre-A1")
    }
}

extension TutorSessionTests {
    func testFinalLessonContinuesIntoNextTutorCourseWithoutChangingCompletionReview()async throws {
        let app=try await app(progressService:TutorAcknowledgment());defer{try? app.identity.disconnect()};let transport=TutorTransport(),session=await session(app,transport)
        let units=session.catalog["Pre-A1"].array,unit=try XCTUnwrap(units.last),lesson=try XCTUnwrap(unit["lessons"].array.last),id=lesson["id"].string,required=session.xpRequired(lesson)
        for previous in units.flatMap({$0["lessons"].array}) where previous["id"].string != id {app.learner.completed.insert(app.learner.tutorKey(previous["id"].string))}
        app.learner.tutorLessons=[app.learner.tutorKey(id):TutorSourceProgress.importing(.object(["status":.string("in_progress"),"earnedXp":.number(Double(required))]))]
        session.select(app,lesson:lesson,unit:unit);await session.complete(app,ready:true)
        XCTAssertEqual(app.learner.tutorLevel,"A1");XCTAssertEqual(app.tutorLevels.last,"A1");XCTAssertEqual(session.id,"lesson-a1-5-1");XCTAssertEqual(session.unit["cefrLevel"].string,"A1")
        XCTAssertEqual(session.completion?["title"],session.details(app,lesson:lesson,unit:unit)["title"]);XCTAssertEqual(session.completion?["level"].string,"Pre-A1");XCTAssertEqual(session.completion?["xpEarned"].number,Double(required));XCTAssertFalse(session.practicingCompletedLesson)
        session.closeCompletion();XCTAssertEqual(session.review?["title"],session.details(app,lesson:lesson,unit:unit)["title"]);XCTAssertEqual(session.review?["level"].string,"Pre-A1");session.closeReview();await session.stop(app)
    }
}
