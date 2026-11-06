import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor private final class TutorNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor private final class TutorTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    var recordings:[String:NarrationRecording]=[:]
    func takeResponseRecording(_ id:String)->NarrationRecording?{recordings.removeValue(forKey:id)}
    var session:JSONValue = .null,events:[JSONValue]=[],closed=false,microphone=false,rejectDeletes=false
    func connect(session:JSONValue)async throws{self.session=session;closed=false;onOpen?()}
    func send(_ event:JSONValue)->Bool{events.append(event);return !closed && !(rejectDeletes && event["type"].string == "conversation.item.delete")}
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
    func testPauseKeepsInterruptedResponseIDAndPlayedClipWithoutAwardingProgress()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let root=FileManager.default.temporaryDirectory.appendingPathComponent("piyali-pause-clip-"+UUID().uuidString);defer{try? FileManager.default.removeItem(at:root)}
        let clips=TutorAudioClips(directory:root),transport=TutorTransport(),session=TutorSessionController(live:LiveTutorService(permission:{true},transportFactory:{transport}),clips:clips,provider:provider());await session.prepare(app);await session.start(app)
        let id="interrupted-response",pcm=Data(repeating:3,count:1200);transport.recordings[id] = .init(pcm16:pcm,sampleRate:24000,channels:1)
        transport.onEvent?(.object(["type":.string("response.created"),"response":.object(["id":.string(id)])]));transport.onEvent?(.object(["type":.string("output_audio_buffer.started")]));transport.onEvent?(.object(["type":.string("response.output_audio_transcript.delta"),"response_id":.string(id),"delta":.string("Welcome! A partial reply.")]))
        XCTAssertEqual(session.live.assistantResponseID,id);XCTAssertFalse(session.live.assistantTurnText.isEmpty);let xp=app.learner.totalXP;await session.pause(app)
        XCTAssertTrue(session.paused);XCTAssertEqual(session.messages.last?["id"].string,id);XCTAssertEqual(session.messages.last?["lang"].string,"en");XCTAssertEqual(app.learner.totalXP,xp)
        var wav:Data?;for _ in 0..<100{wav=await clips.load(id,scope:session.clipScope(app));if wav != nil{break};await Task.yield()};XCTAssertEqual(wav?.dropFirst(44),pcm)
        await session.stop(app);XCTAssertEqual(app.learner.totalXP,xp)
    }
    func testEndingMidReplyKeepsVisibleTextAndClipForPrivateHistory()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let root=FileManager.default.temporaryDirectory.appendingPathComponent("piyali-stop-clip-"+UUID().uuidString);defer{try? FileManager.default.removeItem(at:root)}
        let clips=TutorAudioClips(directory:root),transport=TutorTransport(),session=TutorSessionController(live:LiveTutorService(permission:{true},transportFactory:{transport}),clips:clips,provider:provider());await session.prepare(app);await session.start(app)
        let id="stopped-response",pcm=Data(repeating:4,count:1200);transport.recordings[id] = .init(pcm16:pcm,sampleRate:24000,channels:1)
        transport.onEvent?(.object(["type":.string("response.created"),"response":.object(["id":.string(id)])]));transport.onEvent?(.object(["type":.string("output_audio_buffer.started")]));transport.onEvent?(.object(["type":.string("response.output_audio_transcript.delta"),"response_id":.string(id),"delta":.string("Welcome! Stopped during speech.")]))
        let xp=app.learner.totalXP;await session.stop(app);XCTAssertEqual(session.messages.last?["id"].string,id);XCTAssertEqual(session.messages.last?["textFinal"].string,"Welcome! Stopped during speech.");XCTAssertEqual(app.learner.totalXP,xp)
        var wav:Data?;for _ in 0..<100{wav=await clips.load(id,scope:session.clipScope(app));if wav != nil{break};await Task.yield()};XCTAssertEqual(wav?.dropFirst(44),pcm)
        await session.start(app);XCTAssertTrue(session.messages.isEmpty);await session.stop(app)
    }
    func testOpeningPreviewAndWelcomeAreUngradedThenExactSpeechAdvancesOnce()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport(),session=await session(app,transport)
        XCTAssertEqual(session.id,"lesson-tutorial-1");XCTAssertEqual(session.state["items"].array.count,7);XCTAssertEqual(app.learner.totalXP,0);XCTAssertTrue(app.learner.tutorLessons?.isEmpty ?? true)
        await session.start(app);XCTAssertEqual(transport.session["provider"].string,"gemini");XCTAssertEqual(transport.session["voice"].string,"Vindemiatrix");XCTAssertFalse(transport.session["inputLanguageCodes"].array.isEmpty);XCTAssertEqual(transport.session["audio"],.null)
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
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    var duringSave:(()->Void)?
    var fails=false
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{
        duringSave?();if fails{throw URLError(.notConnectedToInternet)};var acknowledged=state
        acknowledged.acknowledgedEventIDs=Set((state.pendingChanges ?? []).map(\.id));acknowledged.pendingChanges=[];acknowledged.pendingGoalChanges=[];acknowledged.pendingRepairEvidence=[];acknowledged.pendingMemoryChanges=[]
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
        session.closeReview(app);XCTAssertNotNil(app.scholarship.pending);XCTAssertFalse(session.completionPending);XCTAssertFalse(app.subscription.hasAccess);XCTAssertEqual(app.learner.totalXP,349);await session.stop(app)
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

extension TutorSessionTests {
    private func goal(_ app:AppModel)->JSONValue {
        app.learner.editGoal("Speak with family");app.learner.pendingGoalChanges=[]
        let bp:JSONValue = .object(["goalId":app.learner.goalBucket["activeGoal"]["id"],"goalText":.string("Speak with family"),"dayKey":.string(CalendarDay.key(Date())),"lang":.string("es"),"mode":.string("tutor"),"modes":.array([.string("tutor"),.string("flashcards")]),"modeTargets":.object(["tutor":.number(25),"flashcards":.number(3)]),"cefrLevel":.string("Pre-A1"),"objective":.string("Greet a family member"),"scenario":.string("A short family call"),"targetLanguage":.array([.string("Hola"),.string("¿Cómo estás?")]),"supports":.array([.string("One model, then a fresh attempt")]),"successCriteria":.array([.string("Greet a relative and ask how they are")])])
        app.learner.applyGoal(GoalChange(action:.blueprint,target:"es",payload:bp));app.learner.pendingGoalChanges=[];return bp
    }
    private func repair(_ app:AppModel)->RepairStep {
        let day=CalendarDay.key(Date()),item:JSONValue = .object(["memoryId":.string("greeting"),"concept":.string("Greet a relative"),"originalConcept":.string("Greetings"),"expectedAnswer":.string("Hola"),"errorType":.string("conversation_flow"),"cefrLevel":.string("Pre-A1")])
        let plan:JSONValue = .object(["targetLang":.string("es"),"dayKey":.string(day),"target":.number(1),"items":.array([item]),"memoryIds":.array([.string("greeting")])])
        app.learner.importQuestDay(.object(["repair":plan]),target:"es",day:day)
        app.learner.companionMemory=["es":[MemoryNote(fields:["id":.string("greeting"),"status":.string("captured"),"concept":.string("Greetings"),"createdDayKey":.string(CalendarDay.shift(day,by:-1))])]]
        return RepairStep(index:0,mode:"tutor",item:item,plan:plan,stepCount:1)
    }
    private func focused(_ app:AppModel,_ transport:TutorTransport,focus:TutorFocus,provider:TutorProvider)async->TutorSessionController {
        let session=TutorSessionController(focus:focus,live:LiveTutorService(permission:{true},transportFactory:{transport}),provider:provider,turnXP:{5});await session.prepare(app);return session
    }
    func testGoalTutorUsesOriginalRubricAndOnlyFinishesAt25XPWithoutTutorPathOrBonus()async throws {
        let cloud=TutorAcknowledgment(),app=try await app(progressService:cloud);defer{try? app.identity.disconnect()};let bp=goal(app),transport=TutorTransport();var correct=false,checks=0,pendingSeen=false
        var p=provider();p.goal={blueprint,response,context,support in checks+=1;XCTAssertEqual(blueprint,bp);XCTAssertEqual(support,"en");XCTAssertFalse(context.isEmpty);return GoalVerdict(success:correct,support:"prompted",feedback:"Public goal feedback",observation:"Produced the requested family greeting")}
        let session=await focused(app,transport,focus:.goal(bp),provider:p);XCTAssertTrue(session.lesson["isGoal"].boolean);XCTAssertEqual(session.required,25)
        app.learner.questProgress=app.learner.plateProgress.setting("currentTutorLesson",.string("lesson-tutorial-1"));await session.start(app);transport.assistant("Greet your relative and ask how they are.")
        await session.input(input("Please give me a hint"),app:app);XCTAssertEqual(app.learner.totalXP,0);XCTAssertEqual(app.readyGoal?["modeProgress"]["tutor"].number,0)
        correct=true
        for i in 0..<4{await session.input(input("Public greeting attempt \(i)"),app:app)}
        XCTAssertEqual(session.earnedXP(app),20);XCTAssertEqual(app.readyGoal?["modeProgress"]["tutor"].number,0)
        app.learner.subscriptionXPAdjustment=279;XCTAssertTrue(app.subscription.hasAccess)
        cloud.duringSave={if session.completionPending {pendingSeen=true;XCTAssertFalse(app.subscription.hasAccess)}}
        await session.input(input("Public final greeting"),app:app)
        XCTAssertTrue(pendingSeen);XCTAssertEqual(checks,6);XCTAssertTrue(session.focusedFinished);XCTAssertFalse(session.completionPending);XCTAssertEqual(app.learner.totalXP,25)
        XCTAssertEqual(app.readyGoal?["modeProgress"]["tutor"].number,25);XCTAssertEqual(GoalPractice.nextMode(try XCTUnwrap(app.readyGoal)),"flashcards")
        XCTAssertNil(session.completion);XCTAssertNil(session.review);XCTAssertTrue(app.learner.tutorLessons?.isEmpty ?? true);XCTAssertEqual(app.learner.plateProgress["currentTutorLesson"].string,"lesson-tutorial-1");XCTAssertEqual(app.learner.plateProgress["speakDailyActivity"]["es"][CalendarDay.key(Date())].number,0)
        await session.stop(app)
    }
    func testGoalTutorFailedSaveKeepsOneCompletionIntentAndRetryDoesNotAddXP()async throws {
        let cloud=TutorAcknowledgment();cloud.fails=true;let app=try await app(progressService:cloud);defer{try? app.identity.disconnect()};let bp=goal(app),transport=TutorTransport();var p=provider();p.goal={_,_,_,_ in GoalVerdict(success:true,support:"prompted",feedback:"Good",observation:"Produced the requested goal action")}
        let session=await focused(app,transport,focus:.goal(bp),provider:p);await session.start(app);transport.assistant("Try the goal.")
        for i in 0..<5{await session.input(input("Goal action \(i)"),app:app)}
        XCTAssertTrue(session.completionPending);XCTAssertFalse(session.focusedFinished);XCTAssertNotNil(session.error);XCTAssertEqual(app.readyGoal?["modeProgress"]["tutor"].number,0)
        await session.complete(app,ready:true);XCTAssertEqual(app.learner.totalXP,25);XCTAssertEqual(app.learner.pendingGoalChanges?.filter{$0.action == .attempt}.count,1)
        cloud.fails=false;await session.complete(app,ready:true);XCTAssertTrue(session.focusedFinished);XCTAssertEqual(app.readyGoal?["modeProgress"]["tutor"].number,25);XCTAssertEqual(app.learner.totalXP,25);await session.stop(app)
    }
    func testRepairTutorOneGoodRepCommitsOneRepairAndBonusWithoutOrdinaryTutorWrites()async throws {
        let cloud=TutorAcknowledgment();cloud.fails=true;let app=try await app(progressService:cloud);defer{try? app.identity.disconnect()};let step=repair(app),transport=TutorTransport()
        var p=provider();p.judge={prompt in XCTAssertTrue(prompt.contains("REPAIR WATCH"));XCTAssertTrue(prompt.contains("Hola"));return .object(["successful":.bool(true),"confidence":.number(1),"repairAdvanced":.bool(true)])}
        let session=await focused(app,transport,focus:.repair(step),provider:p);XCTAssertTrue(session.lesson["isRepair"].boolean);XCTAssertEqual(session.required,12)
        await session.start(app);transport.assistant("Greet a relative.");await session.input(input("Hola"),app:app)
        XCTAssertEqual(app.learner.totalXP,17);XCTAssertEqual(session.earnedXP(app),5);XCTAssertTrue(session.completionPending);XCTAssertEqual(app.learner.plateProgress["repairDailyActivity"]["es"][step.day].number,1)
        XCTAssertEqual(app.learner.pendingRepairEvidence?.first?.event["success"],.bool(true));XCTAssertEqual(app.learner.pendingChanges?.filter{$0.source == .repair}.first?.amount,12)
        XCTAssertTrue(app.learner.tutorLessons?.isEmpty ?? true);XCTAssertNil(session.completion);XCTAssertEqual(app.learner.companionMemory?["es"]?.first?.text("status"),"reinforced")
        await session.complete(app,ready:true);XCTAssertEqual(app.learner.totalXP,17);XCTAssertEqual(app.learner.pendingChanges?.filter{$0.source == .repair}.count,1)
        cloud.fails=false;await session.complete(app,ready:true);XCTAssertTrue(session.focusedFinished);XCTAssertEqual(app.learner.totalXP,17);XCTAssertEqual(app.learner.plateProgress["speakDailyActivity"]["es"][step.day].number,0);await session.stop(app)
    }
    func testRepairTutorXPCompletionDoesNotInventDemonstratedRepairEvidence()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let step=repair(app),transport=TutorTransport(),session=await focused(app,transport,focus:.repair(step),provider:provider(.object(["successful":.bool(true),"confidence":.number(1),"repairAdvanced":.bool(false)])))
        await session.start(app);transport.assistant("Practice a related task.");for i in 0..<3{await session.input(input("Related practice \(i)"),app:app)}
        XCTAssertEqual(app.learner.totalXP,27);XCTAssertEqual(app.learner.plateProgress["repairDailyActivity"]["es"][step.day].number,1);XCTAssertEqual(app.learner.pendingRepairEvidence?.first?.event["success"],.bool(false));XCTAssertTrue(app.learner.tutorLessons?.isEmpty ?? true);await session.stop(app)
    }
    func testSkippedRepairKeepsLiveLessonUntilStopThenRestoresOrdinaryTutor()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let step=repair(app),transport=TutorTransport(),session=await focused(app,transport,focus:.repair(step),provider:provider())
        await session.start(app);let id=session.id;await session.skipFocus(app);XCTAssertTrue(session.live.connected);XCTAssertTrue(session.focusSkipped);XCTAssertEqual(session.id,id)
        await session.stop(app);XCTAssertNil(session.focus);XCTAssertEqual(session.id,"lesson-tutorial-1");XCTAssertEqual(app.learner.totalXP,0);XCTAssertTrue(app.learner.repairStepIsCurrent(step));XCTAssertTrue(app.learner.tutorLessons?.isEmpty ?? true)
    }
    func testLateGoalVerdictCannotCompleteAfterTheGoalChanges()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let bp=goal(app),transport=TutorTransport();var held:CheckedContinuation<GoalVerdict,Error>?,p=provider()
        p.goal={_,_,_,_ in try await withCheckedThrowingContinuation{held=$0}}
        let session=await focused(app,transport,focus:.goal(bp),provider:p);await session.start(app);transport.assistant("Try the goal.")
        let work=Task{await session.input(input("Public goal action"),app:app)};for _ in 0..<100 where held == nil{await Task.yield()};XCTAssertNotNil(held);app.learner.editGoal("Order in a cafe")
        held?.resume(returning:GoalVerdict(success:true,support:"prompted",feedback:"Good",observation:"A stale action"));await work.value
        XCTAssertEqual(app.learner.totalXP,0);XCTAssertEqual(session.earnedXP(app),0);XCTAssertNil(app.learner.gradedByLanguage);await session.stop(app,saveDraft:false)
    }
}

@MainActor private final class TutorGateAcknowledgment:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    var blocked=true
    var blockPracticeCompletion=false
    var waiters:[CheckedContinuation<Void,Never>]=[]
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState? {
        if blocked,((state.pendingGoalChanges ?? []).contains(where:{$0.action == .attempt}) || blockPracticeCompletion && (state.pendingChanges ?? []).contains(where:{[PracticeSource.speak,.repair].contains($0.source)})) {await withCheckedContinuation{waiters.append($0)}}
        var acknowledged=state;acknowledged.acknowledgedEventIDs=Set((state.pendingChanges ?? []).map(\.id));acknowledged.pendingChanges=[];acknowledged.pendingGoalChanges=[];return acknowledged
    }
    func release(){blocked=false;let pending=waiters;waiters=[];pending.forEach{$0.resume()}}
}
extension TutorSessionTests {
    func testPhonicsFallbackTutorKeepsOriginalModeAndOnlyRoutesAfterEarnedCompletionAcknowledges()async throws {
        for kind in ["goal","repair"] {
            let cloud=TutorAcknowledgment(),app=try await app(progressService:cloud);defer{try? app.identity.disconnect()};cloud.fails=true
            let original=goal(app),bp=original.setting("mode",.string("phonics")).setting("modes",.array(["phonics","lesson"].map(JSONValue.string))).setting("modeTargets",.object(["phonics":.number(2),"lesson":.number(20)])).setting("targetLanguage",.array([.string("casa")]))
            app.learner.goalIntelligence?["es"]=app.learner.goalBucket.setting("dailyGoal",.null);app.learner.applyGoal(.init(action:.blueprint,target:"es",payload:bp));app.learner.pendingGoalChanges=[]
            var step:RepairStep?
            if kind == "repair"{app.learner.goal="";app.learner.goalIntelligence=[:];let day=CalendarDay.key(Date()),item:JSONValue = .object(["memoryId":.string("pronunciation"),"concept":.string("casa"),"expectedAnswer":.string("casa"),"mode":.string("phonics"),"errorType":.string("phonics"),"cefrLevel":.string("Pre-A1")]),plan:JSONValue = .object(["dayKey":.string(day),"targetLang":.string("es"),"target":.number(2),"items":.array([item,.object(["memoryId":.string("agreement"),"concept":.string("Soy estudiante"),"mode":.string("lesson"),"cefrLevel":.string("Pre-A1")])]),"memoryIds":.array(["pronunciation","agreement"].map(JSONValue.string))]);app.learner.importQuestDay(.object(["repair":plan]),target:"es",day:day);step=try XCTUnwrap(app.currentRepairStep)}
            let artifact=try app.focusedPhonicsDeck(goal:kind == "goal" ? bp:nil,repair:step).setting("cards",.array([.null]));if let step{app.learner.storeRepairArtifact(artifact,step:step,mode:"phonics");app.learner.pendingCompanionQuestDays=[:]}else{app.learner.goalArtifacts=[artifact["ownerKey"].string:artifact]}
            let focus:TutorFocus=step.map(TutorFocus.repair) ?? .goal(bp),transport=TutorTransport();var p=provider(.object(["successful":.bool(true),"confidence":.number(1),"repairAdvanced":.bool(true)]));p.goal={candidate,_,_,_ in XCTAssertEqual(candidate,bp);return .init(success:true,support:"prompted",feedback:"Good",observation:"Produced the requested pronunciation")}
            let session=TutorSessionController(focus:focus,live:LiveTutorService(permission:{true},transportFactory:{transport}),provider:p,turnXP:{5}),scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow},window=UIWindow(windowScene:scene);var surfaces:[ProductMode]=[]
            let content:AnyView=kind == "goal" ? AnyView(FocusedGoalCourseView(onSurface:{surfaces.append($0)},tutorControllerFactory:{_ in session})):AnyView(RepairPracticeView(onSurface:{surfaces.append($0)},tutorControllerFactory:{_ in session}));window.rootViewController=UIHostingController(rootView:content.environmentObject(app));window.makeKeyAndVisible();window.rootViewController?.view.layoutIfNeeded();defer{window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
            for _ in 0..<160 where session.id.isEmpty{try await Task.sleep(for:.milliseconds(25))};XCTAssertEqual(surfaces,[.phonics,.tutor]);XCTAssertEqual(session.focus,focus);XCTAssertFalse(session.live.connected);XCTAssertEqual(app.learner.totalXP,0)
            if kind == "goal"{app.learner.subscriptionXPAdjustment=279}
            await session.start(app);transport.assistant("Say casa clearly.");for i in 0..<(kind == "goal" ? 5:1){await session.input(input("Public pronunciation attempt \(i)"),app:app)}
            if kind == "goal"{XCTAssertFalse(app.subscription.hasAccess);XCTAssertTrue(app.preservingEarnedPractice)}
            XCTAssertTrue(session.completionPending);XCTAssertFalse(session.focusedFinished);XCTAssertEqual(surfaces,[.phonics,.tutor]);XCTAssertEqual(app.learner.totalXP,kind == "goal" ? 25:17);XCTAssertTrue(app.learner.tutorLessons?.isEmpty ?? true);XCTAssertTrue(app.learner.phonicsDocuments.isEmpty)
            if kind == "goal"{XCTAssertEqual(app.readyGoal?["modeProgress"]["phonics"].number,0)}else{XCTAssertEqual(app.currentRepairStep?.index,0)}
            cloud.fails=false;await session.complete(app,ready:true);for _ in 0..<160 where surfaces.last != .path{try await Task.sleep(for:.milliseconds(25))};XCTAssertEqual(surfaces,[.phonics,.tutor,.path]);XCTAssertTrue(session.focusedFinished);XCTAssertEqual(app.learner.totalXP,kind == "goal" ? 25:17);XCTAssertEqual(app.learner.gradedByLanguage?["es"],kind == "goal" ? 5:1)
            if kind == "goal"{XCTAssertEqual(app.readyGoal?["modeProgress"]["phonics"].number,2);XCTAssertEqual(app.readyGoal?["modeProgress"]["tutor"].number ?? 0,0)}else{XCTAssertEqual(app.currentRepairStep?.index,1)}
            XCTAssertEqual(app.learner.plateProgress["speakDailyActivity"]["es"][CalendarDay.key(Date())].number,0)
            let trace:JSONValue = .object(["kind":.string(kind),"originalMode":.string("phonics"),"surfaces":.array(surfaces.map{.string($0.rawValue)}),"totalXP":.number(Double(app.learner.totalXP)),"gradedAttempts":.number(Double(app.learner.gradedByLanguage?["es"] ?? 0)),"goalModeProgress":app.readyGoal?["modeProgress"] ?? .null,"repairCompletedCount":app.learner.plateProgress["repairDailyActivity"]["es"][CalendarDay.key(Date())],"ordinaryTutorLessonCount":.number(Double(app.learner.tutorLessons?.count ?? 0)),"ordinaryAlphabetRecordCount":.number(Double(app.learner.phonicsDocuments.count)),"subscriptionXP":.number(Double(app.learner.subscriptionXP)),"access":.bool(app.subscription.hasAccess)]),attachment=XCTAttachment(data:Data(trace.json.utf8),uniformTypeIdentifier:"public.json");attachment.name="Native Phonics fallback Tutor \(kind) earned completion trace";attachment.lifetime = .keepAlways;add(attachment)
            await session.stop(app)
        }
    }
    func testRenderedGoalTutorRetainsEarnedWorkAcrossTrialGateAndRoutesAfterAcknowledgment()async throws {
        let cloud=TutorGateAcknowledgment(),app=try await app(progressService:cloud);defer{cloud.release();try? app.identity.disconnect()};let bp=goal(app),transport=TutorTransport();var p=provider();p.goal={_,_,_,_ in GoalVerdict(success:true,support:"prompted",feedback:"Good",observation:"Completed the requested goal action")}
        let session=await focused(app,transport,focus:.goal(bp),provider:p),scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow},window=UIWindow(windowScene:scene);var surfaces:[ProductMode]=[]
        let host=UIHostingController(rootView:ProductAccessGate(service:app.subscription){FocusedGoalCourseView(onSurface:{surfaces.append($0)},tutorControllerFactory:{_ in session})}.environmentObject(app));window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();defer{window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
        for _ in 0..<80 where app.activityFooter == nil{try await Task.sleep(for:.milliseconds(25))};XCTAssertEqual(surfaces,[.tutor]);XCTAssertNotNil(app.activityFooter)
        await session.start(app);transport.assistant("Greet your relative.");for i in 0..<4{await session.input(input("Public goal action \(i)"),app:app)}
        app.learner.subscriptionXPAdjustment=279;let finish=Task{await session.input(input("Final family greeting"),app:app)}
        for _ in 0..<100 where cloud.waiters.isEmpty{try await Task.sleep(for:.milliseconds(25))};XCTAssertFalse(cloud.waiters.isEmpty);XCTAssertTrue(session.completionPending);XCTAssertFalse(app.subscription.hasAccess);XCTAssertTrue(app.preservingEarnedPractice);XCTAssertEqual(surfaces,[.tutor]);XCTAssertEqual(app.readyGoal?["modeProgress"]["tutor"].number,0)
        try await Task.sleep(for:.milliseconds(200));let image=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});image.name="Native Goal Tutor saving earned work across trial gate";image.lifetime = .keepAlways;add(image)
        cloud.release();await finish.value
        for _ in 0..<100 where surfaces.last != .cards{try await Task.sleep(for:.milliseconds(25))};XCTAssertEqual(surfaces,[.tutor,.cards]);XCTAssertEqual(app.readyGoal?["modeProgress"]["tutor"].number,25);XCTAssertEqual(app.learner.totalXP,25);await session.stop(app)
    }
}

extension TutorSessionTests {
    func testRenderedRepairTutorRetainsFailedCompletionUntilRetryAcknowledgesIt()async throws {
        let cloud=TutorAcknowledgment();cloud.fails=true;let app=try await app(progressService:cloud);defer{try? app.identity.disconnect()};let step=repair(app),transport=TutorTransport(),session=await focused(app,transport,focus:.repair(step),provider:provider(.object(["successful":.bool(true),"confidence":.number(1),"repairAdvanced":.bool(true)])))
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow},window=UIWindow(windowScene:scene);var surfaces:[ProductMode]=[]
        let host=UIHostingController(rootView:ProductAccessGate(service:app.subscription){RepairPracticeView(onSurface:{surfaces.append($0)},tutorControllerFactory:{_ in session})}.environmentObject(app));window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();defer{window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
        for _ in 0..<100 where app.activityFooter == nil{try await Task.sleep(for:.milliseconds(25))};XCTAssertEqual(surfaces,[.tutor]);XCTAssertNotNil(app.activityFooter)
        app.learner.subscriptionXPAdjustment=299;await session.start(app);transport.assistant("Greet a relative.");await session.input(input("Hola"),app:app)
        XCTAssertTrue(session.completionPending);XCTAssertFalse(session.focusedFinished);XCTAssertFalse(app.subscription.hasAccess);XCTAssertNotNil(session.error);XCTAssertTrue(app.preservingEarnedPractice);XCTAssertEqual(surfaces,[.tutor]);XCTAssertEqual(app.currentRepairStep?.id,step.id)
        try await Task.sleep(for:.milliseconds(200));let capture=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});capture.name="Native repair Tutor completion retry across trial gate";capture.lifetime = .keepAlways;add(capture)
        cloud.fails=false;await session.complete(app,ready:true);XCTAssertTrue(session.focusedFinished);XCTAssertFalse(session.completionPending);XCTAssertEqual(app.learner.totalXP,17);XCTAssertNil(app.currentRepairStep);XCTAssertEqual(surfaces,[.tutor]);await session.stop(app)
    }
}

extension TutorSessionTests {
    func testOrdinaryTutorCompletionAndReviewRemainVisibleThroughTheRootTrialGate()async throws {
        let cloud=TutorGateAcknowledgment();cloud.blockPracticeCompletion=true;let app=try await app(progressService:cloud);defer{cloud.release();try? app.identity.disconnect()};let transport=TutorTransport(),session=await session(app,transport),id=session.id
        let items=JSONValue.object(Dictionary(uniqueKeysWithValues:session.state["items"].array.map{($0["id"].string,.bool(true))}))
        app.learner.tutorLessons=[app.learner.tutorKey(id):TutorSourceProgress.importing(.object(["status":.string("in_progress"),"earnedXp":.number(50),"tutorAgendaProgress":.object(["schemaVersion":.number(2),"items":items])]))];app.learner.subscriptionXPAdjustment=299;session.refresh(app)
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow},window=UIWindow(windowScene:scene)
        let host=UIHostingController(rootView:ProductAccessGate(service:app.subscription){SourceTutorView(controller:session)}.environmentObject(app));window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();defer{window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
        for _ in 0..<80 where app.activityFooter == nil{try await Task.sleep(for:.milliseconds(25))};XCTAssertNotNil(app.activityFooter)
        let finish=Task{await session.complete(app,ready:true)};for _ in 0..<100 where cloud.waiters.isEmpty{try await Task.sleep(for:.milliseconds(25))}
        XCTAssertFalse(cloud.waiters.isEmpty);XCTAssertFalse(app.subscription.hasAccess);XCTAssertTrue(app.preservingEarnedPractice);cloud.release();await finish.value
        XCTAssertNotNil(session.completion);XCTAssertTrue(session.completionPending);XCTAssertTrue(app.preservingEarnedPractice)
        try await Task.sleep(for:.milliseconds(200));let image=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});image.name="Native ordinary Tutor earned completion through root trial gate";image.lifetime = .keepAlways;add(image)
        session.closeCompletion();XCTAssertNotNil(session.review);XCTAssertTrue(app.preservingEarnedPractice);session.closeReview();XCTAssertFalse(app.preservingEarnedPractice);XCTAssertFalse(app.subscription.hasAccess);XCTAssertEqual(app.learner.totalXP,50);await session.stop(app)
    }
}


extension TutorSessionTests {
    func testGameHandoffWaitsForAcknowledgmentAndReplayCannotAwardAgain()async throws{
        let cloud=TutorAcknowledgment();cloud.fails=true;let app=try await app(progressService:cloud);defer{try? app.identity.disconnect()};let transport=TutorTransport(),session=await session(app,transport),lesson=session.lesson,unit=session.unit
        let first=await session.completeGame(app);XCTAssertFalse(first);XCTAssertTrue(session.completionPending);XCTAssertNotNil(session.error);XCTAssertEqual(app.learner.totalXP,50);XCTAssertEqual(app.learner.pendingChanges?.filter{$0.source == .speak}.count,1);XCTAssertEqual(app.learner.pendingChanges?.filter{$0.source == .lesson}.count,0)
        cloud.fails=false;let second=await session.completeGame(app);XCTAssertTrue(second);XCTAssertNotNil(session.completion);XCTAssertEqual(app.learner.totalXP,50);XCTAssertTrue(app.learner.pendingChanges?.isEmpty ?? true)
        session.closeCompletion();session.closeReview(app);session.select(app,lesson:lesson,unit:unit);XCTAssertTrue(session.practicingCompletedLesson);let replay=await session.completeGame(app);XCTAssertTrue(replay);XCTAssertEqual(app.learner.totalXP,50);XCTAssertNil(session.completion);try app.identity.disconnect();try app.identity.create();let stale=await session.completeGame(app);XCTAssertFalse(stale);XCTAssertEqual(app.learner.totalXP,50);await session.stop(app,saveDraft:false)
    }
}


extension TutorSessionTests {
    func testPreparedGameSelectionStartsOnlyTutorProgressAndSurvivesReload()async throws{
        let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport(),session=await session(app,transport),lesson=session.lesson,unit=session.unit
        let before=app.learner.totalXP,typed=try XCTUnwrap(session.selectPreparedGame(app,lesson:lesson,unit:unit));XCTAssertEqual(typed.id,lesson["id"].string);XCTAssertEqual(app.learner.plateProgress["currentTutorLesson"].string,typed.id);XCTAssertEqual(app.learner.tutorProgress(typed.id).sourceState?["status"].string,"in_progress");let start=try XCTUnwrap(app.learner.pendingChanges?.first{$0.source == .tutorState && $0.contentID == typed.id && $0.tutorData?["kind"].string == "start"});XCTAssertEqual(start.amount,0);XCTAssertEqual(app.learner.totalXP,before);XCTAssertNil(app.learner.lessonWork)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(app.learner));app.learner=restored;let reload=await self.session(app,TutorTransport());XCTAssertEqual(reload.id,typed.id);XCTAssertEqual(app.learner.totalXP,before);await session.stop(app,saveDraft:false);await reload.stop(app,saveDraft:false)
    }
}

extension TutorSessionTests {
    func testTutorGameRetiresOnlyAfterAcknowledgmentAndCompletedReplayStartsFresh()async throws{
        let cloud=TutorAcknowledgment();cloud.fails=true;let app=try await app(progressService:cloud);defer{try? app.identity.disconnect()};let session=await session(app,TutorTransport()),lesson=session.lesson,unit=session.unit,typed=try XCTUnwrap(TutorSessionController.decodeLesson(lesson)),service=RPGService(writer:{_ in ""})
        await service.prepare(app,lesson:typed,episode:nil,tutor:true);var first=try XCTUnwrap(app.learner.rpgRuns?[app.learner.target]);first.stepIndex=first.scenario.quest.steps.count;app.learner.saveRPG(first)
        let failed=await session.completeGame(app);XCTAssertFalse(failed);XCTAssertEqual(app.learner.rpgRuns?[app.learner.target]?.claimed,false);XCTAssertEqual(app.learner.totalXP,50)
        cloud.fails=false;let saved=await session.completeGame(app);XCTAssertTrue(saved);XCTAssertEqual(app.learner.rpgRuns?[app.learner.target]?.claimed,true);XCTAssertEqual(app.learner.totalXP,50)
        session.closeCompletion();session.closeReview(app);XCTAssertNotNil(session.selectPreparedGame(app,lesson:lesson,unit:unit));XCTAssertEqual(app.learner.plateProgress["currentTutorLesson"].string,typed.id);XCTAssertTrue(session.practicingCompletedLesson);await service.prepare(app,lesson:typed,episode:nil,tutor:true);var replay=try XCTUnwrap(app.learner.rpgRuns?[app.learner.target]);XCTAssertNotEqual(replay.id,first.id);XCTAssertFalse(replay.completed);XCTAssertEqual(replay.stepIndex,0);XCTAssertEqual(app.learner.totalXP,50)
        replay.stepIndex=replay.scenario.quest.steps.count;app.learner.saveRPG(replay);let completed=await session.completeGame(app);XCTAssertTrue(completed);XCTAssertTrue(app.learner.rpgRuns?[app.learner.target]?.claimed == true);XCTAssertNil(session.completion);XCTAssertEqual(app.learner.totalXP,50);await session.stop(app,saveDraft:false)
    }
}

extension TutorSessionTests {
    func testRestoredTutorGameRetriesDurableBonusAndMigratesLegacyFinishedRun()async throws{
        let cloud=TutorAcknowledgment();cloud.fails=true;let app=try await app(progressService:cloud);defer{try? app.identity.disconnect()};let session=await session(app,TutorTransport()),lesson=session.lesson,unit=session.unit,typed=try XCTUnwrap(TutorSessionController.decodeLesson(lesson)),service=RPGService(writer:{_ in ""})
        await service.prepare(app,lesson:typed,episode:nil,tutor:true);var run=try XCTUnwrap(app.learner.rpgRuns?[app.learner.target]);run.stepIndex=run.scenario.quest.steps.count;app.learner.saveRPG(run);let first=await session.completeGame(app);XCTAssertFalse(first);let receipt=try XCTUnwrap(app.learner.pendingChanges?.first{$0.source == .speak}?.id);await session.stop(app,saveDraft:false)
        app.learner=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(app.learner));let restored=await self.session(app,TutorTransport());XCTAssertNotNil(restored.selectPreparedGame(app,lesson:lesson,unit:unit));XCTAssertTrue(restored.practicingCompletedLesson);await service.prepare(app,lesson:typed,episode:nil,tutor:true);XCTAssertEqual(app.learner.rpgRuns?[app.learner.target]?.id,run.id)
        let retry=await restored.completeGame(app);XCTAssertFalse(retry);XCTAssertEqual(app.learner.totalXP,50);XCTAssertEqual(app.learner.pendingChanges?.filter{$0.source == .speak}.map(\.id),[receipt]);XCTAssertFalse(app.learner.rpgRuns?[app.learner.target]?.claimed ?? true)
        cloud.fails=false;let acknowledged=await restored.completeGame(app);XCTAssertTrue(acknowledged);XCTAssertEqual(app.learner.totalXP,50);XCTAssertTrue(app.learner.pendingChanges?.isEmpty ?? true);XCTAssertTrue(app.learner.rpgRuns?[app.learner.target]?.claimed == true)
        restored.closeCompletion();restored.closeReview(app);XCTAssertNotNil(restored.selectPreparedGame(app,lesson:lesson,unit:unit));run.claimed=false;app.learner.saveRPG(run);await service.prepare(app,lesson:typed,episode:nil,tutor:true);let practice=try XCTUnwrap(app.learner.rpgRuns?[app.learner.target]);XCTAssertNotEqual(practice.id,run.id);XCTAssertEqual(practice.stepIndex,0);XCTAssertFalse(practice.completed);XCTAssertEqual(app.learner.totalXP,50);await restored.stop(app,saveDraft:false)
    }
}


extension TutorSessionTests {
    func testUnexpectedTranscriptDeletesContextAndRequestsTheSamePhraseWithoutGrading() async throws {
        let app=try await app();defer{try? app.identity.disconnect()}
        let transport=TutorTransport();var judged=0,p=provider();p.judge={_ in judged += 1;return .object(["successful":.bool(true),"confidence":.number(1)])}
        let session=await session(app,transport,provider:p);await session.start(app)
        transport.assistant("Welcome!");await session.input(input("yes","welcome"),app:app);transport.assistant("Say hola.",id:"practice")
        let messageCount=session.messages.count,before=transport.events.count
        transport.onEvent?(.object(["type":.string("input_audio_buffer.committed"),"item_id":.string("bad-script")]))
        transport.onEvent?(.object(["type":.string("conversation.item.input_audio_transcription.completed"),"item_id":.string("bad-script"),"transcript":.string("नमस्ते")]))
        for _ in 0..<100 {await Task.yield()}
        let emitted=Array(transport.events.dropFirst(before))
        XCTAssertTrue(emitted.contains{$0["type"].string == "conversation.item.delete" && $0["item_id"].string == "bad-script"})
        let recovery=emitted.first{$0["response"]["metadata"]["kind"].string == "tutor_transcript_recovery"}
        XCTAssertNotNil(recovery);XCTAssertTrue(recovery?["response"]["instructions"].string.contains("ASR RECOVERY:") == true)
        XCTAssertTrue(recovery?["response"]["instructions"].string.contains("hola") == true)
        XCTAssertFalse(recovery?["response"]["instructions"].string.contains("नमस्ते") == true)
        XCTAssertEqual(session.live.voiceState,"thinking");XCTAssertFalse(transport.microphone)
        XCTAssertEqual(session.messages.count,messageCount);XCTAssertEqual(judged,0);XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.gradedByLanguage)
        await session.stop(app)
    }
}


extension TutorSessionTests {
    func testUnexpectedScriptDuringReplyDeletesOnlyAndNeverInterruptsOrUnlocksIt() async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport(),session=await session(app,transport)
        await session.start(app);transport.assistant("Welcome!");await session.input(input("yes","welcome"),app:app);transport.assistant("Say hola.",id:"practice")
        transport.onEvent?(.object(["type":.string("response.created"),"response":.object(["id":.string("active")])]))
        transport.onEvent?(.object(["type":.string("output_audio_buffer.started")]))
        let count=session.messages.count,before=transport.events.count
        transport.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"item_id":.string("late-script"),"transcript":.string("नमस्ते")]))
        for _ in 0..<100{await Task.yield()}
        let events=Array(transport.events.dropFirst(before))
        XCTAssertEqual(events.filter{$0["type"].string == "conversation.item.delete"}.count,1);XCTAssertFalse(events.contains{$0["type"].string == "response.create"})
        XCTAssertEqual(session.live.voiceState,"speaking");XCTAssertFalse(transport.microphone);XCTAssertTrue(session.live.connected);XCTAssertEqual(session.messages.count,count)
        transport.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"item_id":.string("late-script"),"transcript":.string("नमस्ते")]))
        for _ in 0..<100{await Task.yield()}
        XCTAssertFalse(session.live.transcript.contains("नमस्ते"));XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.gradedByLanguage);await session.stop(app)
    }
    func testRecoveryBeforeWelcomeReplyKeepsGreetingUngradedAndUsesCurrentAgendaPhrase() async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport(),session=await session(app,transport)
        await session.start(app);transport.assistant("Welcome!")
        await session.input(input("नमस्ते","rejected-welcome"),app:app)
        let recovery=try XCTUnwrap(transport.events.last{$0["response"]["metadata"]["kind"].string == "tutor_transcript_recovery"})
        transport.onEvent?(.object(["type":.string("response.created"),"response":.object(["id":.string("recovery"),"metadata":recovery["response"]["metadata"]])]))
        transport.onEvent?(.object(["type":.string("response.done"),"response":.object(["id":.string("recovery"),"output":.array([.object(["content":.array([.object(["transcript":.string("Please try hola once more.")])])])])])]))
        transport.onEvent?(.object(["type":.string("output_audio_buffer.stopped")]))
        XCTAssertEqual(session.messages.last?["welcome"],.bool(false));XCTAssertEqual(session.currentReplyLanguage,"target")
        await session.input(input("yes","greeting-retry"),app:app);XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.gradedByLanguage)
        transport.assistant("Say hola.",id:"practice");await session.input(input("hola","earned"),app:app)
        XCTAssertTrue((3...7).contains(app.learner.totalXP));XCTAssertEqual(app.learner.tutorProgress(session.id).items,["hello"])
        transport.assistant("Now introduce yourself.",id:"next")
        transport.rejectDeletes=true;await session.input(input("नमस्ते","next-rejection"),app:app)
        let next=try XCTUnwrap(transport.events.last{$0["response"]["metadata"]["kind"].string == "tutor_transcript_recovery"})
        XCTAssertTrue(next["response"]["instructions"].string.contains("me llamo"));XCTAssertTrue(session.live.connected);XCTAssertNil(session.live.error)
        XCTAssertEqual(app.learner.gradedByLanguage?["es"],1);session.flushDraft(app);XCTAssertFalse(session.record(app)["conversationDraft"].json.contains("नमस्ते"));await session.stop(app)
    }
    func testQueuedRecoveryCannotReachStoppedReplacedOrPausedSession() async throws {
        for boundary in ["stop","pause","support"] {
            let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport(),session=await session(app,transport)
            await session.start(app);transport.assistant("Welcome!")
            transport.onEvent?(.object(["type":.string("conversation.item.input_audio_transcription.completed"),"item_id":.string("old"),"transcript":.string("नमस्ते")]))
            if boundary == "support"{app.learner.support="ar"}else if boundary == "pause"{await session.pause(app)}else{await session.stop(app)}
            for _ in 0..<100{await Task.yield()}
            XCTAssertFalse(transport.events.contains{$0["response"]["metadata"]["kind"].string == "tutor_transcript_recovery"},boundary);XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.gradedByLanguage);await session.stop(app,saveDraft:false)
        }
    }
}


private struct TutorASRComparisonHost:View {
    @EnvironmentObject var app:AppModel
    let tutor:TutorSessionController
    var body:some View {SourceTutorView(controller:tutor).ignoresSafeArea().overlay(alignment:.bottom){if let footer=app.activityFooter{footer.content.padding(12).background{SourceActivityDockBackground(correct:footer.correct)}.padding(.horizontal,8).padding(.bottom,12)}}}
}

extension TutorSessionTests {
    func testOriginalTutorUnexpectedScriptRecoveryAndLateRejectionAgainstRenderedNativeInEnglishAndArabic() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1" else{throw XCTSkip("Explicit read-only source preview required")}
        let app=try await app();defer{try? app.identity.disconnect()}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for (support,theme) in [("en","light"),("ar","dark")] {
            app.learner=LearnerState();app.learner.target="es";app.learner.support=support;app.learner.onboardingComplete=true;await app.reloadContent()
            let transport=TutorTransport(),tutor=await session(app,transport),web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:WKWebViewConfiguration())
            let sourceWindow=UIWindow(windowScene:scene),sourceHost=UIViewController();sourceWindow.frame=web.frame;sourceHost.view=web;sourceWindow.rootViewController=sourceHost;web.scrollView.contentInsetAdjustmentBehavior = .never;sourceWindow.makeKeyAndVisible()
            let nativeWindow=UIWindow(windowScene:scene);nativeWindow.frame=web.frame
            let host=UIHostingController(rootView:TutorASRComparisonHost(tutor:tutor).environmentObject(app).environment(\.layoutDirection,support == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());nativeWindow.rootViewController=host;nativeWindow.makeKeyAndVisible();host.view.layoutIfNeeded()
            defer{web.stopLoading();sourceWindow.isHidden=true;sourceWindow.rootViewController=nil;nativeWindow.isHidden=true;nativeWindow.rootViewController=nil}
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-onboarding?screen=tutor&tutorASR=1&language=\(support)&theme=\(theme)"))))
            let startLabel=String(decoding:try JSONEncoder().encode(EntryCopy.ui(support,"ra_btn_start")),as:UTF8.self)
            var ready=false
            for _ in 0..<500 {ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && [...document.querySelectorAll('button')].some(b=>b.textContent.trim()===\(startLabel) && !b.disabled)")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))}
            XCTAssertTrue(ready);guard ready else{return}
            _=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(b=>b.textContent.trim()===\(startLabel)).click()")
            var connected=false
            for _ in 0..<100 {connected=(try? await web.evaluateJavaScript("!!window.__tutorASR?.sent.some(e=>e.response?.metadata?.kind==='tutor_welcome')")) as? Bool == true;if connected{break};try await Task.sleep(for:.milliseconds(50))}
            XCTAssertTrue(connected);guard connected else{return}
            func sourceEmit(_ events:[JSONValue])async throws {let data=JSONValue.array(events).json;_=try await web.callAsyncJavaScript("for(const event of events)await window.__tutorASR.emit(event)",arguments:["events":try JSONSerialization.jsonObject(with:Data(data.utf8))],in:nil,contentWorld:.page)}
            func sourceAssistant(_ text:String,_ id:String,_ kind:String="tutor_followup")async throws {
                try await sourceEmit([.object(["type":.string("response.created"),"response":.object(["id":.string(id),"metadata":.object(["kind":.string(kind)])])]),.object(["type":.string("response.audio_transcript.done"),"response_id":.string(id),"transcript":.string(text)]),.object(["type":.string("response.done"),"response":.object(["id":.string(id),"status":.string("completed")])])]);try await Task.sleep(for:.milliseconds(600))
            }
            func capture(_ state:String)async throws {
                try await Task.sleep(for:.milliseconds(400));let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source Tutor ASR \(state) \(support)";source.lifetime = .keepAlways;add(source)
                nativeWindow.makeKeyAndVisible();host.view.layoutIfNeeded();let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:nativeWindow.bounds).image{_ in nativeWindow.drawHierarchy(in:nativeWindow.bounds,afterScreenUpdates:true)});native.name="Native Tutor ASR \(state) \(support)";native.lifetime = .keepAlways;add(native)
            }
            await tutor.start(app);try await sourceAssistant("Welcome!","welcome","tutor_welcome");transport.assistant("Welcome!")
            try await sourceEmit([.object(["type":.string("conversation.item.input_audio_transcription.completed"),"item_id":.string("greeting"),"transcript":.string("yes")])]);await tutor.input(input("yes","greeting"),app:app)
            try await sourceAssistant("Say hola.","practice");transport.assistant("Say hola.",id:"practice")
            let initialCount=tutor.messages.count,sourceBefore=(try await web.evaluateJavaScript("window.__tutorASR.judges")) as? Int ?? -1
            let rejected:JSONValue = .object(["type":.string("conversation.item.input_audio_transcription.completed"),"item_id":.string("bad-script"),"transcript":.string("नमस्ते")])
            try await sourceEmit([rejected]);transport.onEvent?(.object(["type":.string("input_audio_buffer.committed"),"item_id":.string("bad-script")]));transport.onEvent?(rejected)
            for _ in 0..<100{await Task.yield()}
            let sourceRecoveryRaw=try await web.evaluateJavaScript("JSON.stringify(window.__tutorASR.sent.find(e=>e.response?.metadata?.kind==='tutor_transcript_recovery'))")
            let sourceRecovery=try JSONDecoder().decode(JSONValue.self,from:Data(try XCTUnwrap(sourceRecoveryRaw as? String).utf8)),nativeRecovery=try XCTUnwrap(transport.events.last{$0["response"]["metadata"]["kind"].string == "tutor_transcript_recovery"})
            XCTAssertEqual(nativeRecovery,sourceRecovery);XCTAssertEqual(tutor.live.voiceState,"thinking");XCTAssertFalse(transport.microphone);XCTAssertEqual(tutor.messages.count,initialCount)
            let sourceObserved1=(try await web.evaluateJavaScript("window.__tutorASR.judges")) as? Int
            XCTAssertEqual(sourceObserved1,sourceBefore)
            let sourceObserved2=(try await web.evaluateJavaScript("window.__tutorASR.microphone")) as? Bool
            XCTAssertEqual(sourceObserved2,false)
            let sourceObserved3=(try await web.evaluateJavaScript("document.body.textContent.includes('नमस्ते')")) as? Bool
            XCTAssertEqual(sourceObserved3,false)
            try await capture("waiting")
            let spoken=support == "ar" ? "حاول مرة أخرى: hola.":"Please try hola once more."
            try await sourceAssistant(spoken,"recovery","tutor_transcript_recovery")
            transport.onEvent?(.object(["type":.string("response.created"),"response":.object(["id":.string("recovery"),"metadata":nativeRecovery["response"]["metadata"]])]))
            transport.onEvent?(.object(["type":.string("response.done"),"response":.object(["id":.string("recovery"),"output":.array([.object(["content":.array([.object(["transcript":.string(spoken)])])])])])]))
            transport.onEvent?(.object(["type":.string("output_audio_buffer.stopped")]));try await capture("retry")
            let active:JSONValue = .object(["type":.string("response.created"),"response":.object(["id":.string("active"),"metadata":.object(["kind":.string("tutor_followup")])])])
            try await sourceEmit([active]);transport.onEvent?(active);transport.onEvent?(.object(["type":.string("output_audio_buffer.started")]))
            let before=transport.events.count,late:JSONValue = .object(["type":.string("input_audio_transcription.completed"),"item_id":.string("late-script"),"transcript":.string("नमस्ते")])
            try await sourceEmit([late]);transport.onEvent?(late);for _ in 0..<100{await Task.yield()}
            XCTAssertFalse(transport.events.dropFirst(before).contains{$0["type"].string == "response.create"});XCTAssertEqual(tutor.live.voiceState,"speaking");XCTAssertFalse(transport.microphone)
            let sourceObserved4=(try await web.evaluateJavaScript("window.__tutorASR.sent.filter(e=>e.response?.metadata?.kind==='tutor_transcript_recovery').length")) as? Int
            XCTAssertEqual(sourceObserved4,1)
            try await capture("late-script")
            let sourceTrace=try await web.evaluateJavaScript("JSON.stringify({deletes:window.__tutorASR.sent.filter(e=>e.type==='conversation.item.delete'),recovery:window.__tutorASR.sent.filter(e=>e.response?.metadata?.kind==='tutor_transcript_recovery'),microphone:window.__tutorASR.microphone,grades:window.__tutorASR.grades,notes:window.__tutorASR.notes,awards:window.__tutorASR.awards})")
            let sourceAttachment=XCTAttachment(data:Data(try XCTUnwrap(sourceTrace as? String).utf8),uniformTypeIdentifier:"public.json");sourceAttachment.name="Source Tutor ASR recovery trace \(support)";sourceAttachment.lifetime = .keepAlways;add(sourceAttachment)
            let trace:JSONValue = .object(["deletes":.array(transport.events.filter{$0["type"].string == "conversation.item.delete"}),"recovery":.array([nativeRecovery]),"microphone":.bool(transport.microphone),"totalXP":.number(Double(app.learner.totalXP)),"gradedAttempts":.number(Double(app.learner.gradedByLanguage?["es"] ?? 0)),"messages":.array(tutor.messages.map{.object(["role":$0["role"],"text":$0["textFinal"],"welcome":$0["welcome"]])})])
            let nativeAttachment=XCTAttachment(data:Data(trace.json.utf8),uniformTypeIdentifier:"public.json");nativeAttachment.name="Native Tutor ASR recovery trace \(support)";nativeAttachment.lifetime = .keepAlways;add(nativeAttachment)
            XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.gradedByLanguage);XCTAssertFalse(tutor.messages.contains{$0["textFinal"].string.contains("नमस्ते")});await tutor.stop(app)
            web.stopLoading();sourceWindow.isHidden=true;sourceWindow.rootViewController=nil;nativeWindow.isHidden=true;nativeWindow.rootViewController=nil
        }
    }
}


extension TutorSessionTests {
    func testLateCorrectBurstsAdvanceStarterAgendaSilentlyButPayOnlyTheExistingTurnOnce()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport(),tutor=TutorSessionController(live:LiveTutorService(permission:{true},transportFactory:{transport}),provider:provider(),turnXP:{5})
        await tutor.prepare(app);await tutor.start(app);transport.assistant("Welcome!");await tutor.input(input("yes","welcome"),app:app);transport.assistant("Say hola.",id:"practice")
        await tutor.input(input("I do not know","attempt"),app:app);XCTAssertEqual(app.learner.totalXP,0)
        transport.onEvent?(.object(["type":.string("response.created"),"response":.object(["id":.string("followup")])]))
        transport.onEvent?(.object(["type":.string("output_audio_buffer.started")]))
        let count=tutor.messages.count,before=transport.events.count
        func burst(_ text:String,_ id:String)async {
            transport.onEvent?(.object(["type":.string("conversation.item.input_audio_transcription.completed"),"item_id":.string(id),"transcript":.string(text)]))
            for _ in 0..<100{await Task.yield()}
        }
        await burst("hola","late-hello");XCTAssertEqual(app.learner.totalXP,5);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1);XCTAssertEqual(app.learner.tutorProgress(tutor.id).items,["hello"])
        await burst("me llamo","late-name");await burst("me llamo","late-name-duplicate")
        XCTAssertEqual(app.learner.totalXP,5);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1);XCTAssertEqual(app.learner.tutorProgress(tutor.id).items,["hello","myNameIs"])
        XCTAssertEqual(tutor.messages.count,count);XCTAssertFalse(transport.events.dropFirst(before).contains{$0["type"].string == "response.create"})
        XCTAssertEqual(tutor.live.voiceState,"speaking");XCTAssertFalse(transport.microphone);XCTAssertEqual(app.learner.history.count,0)
        tutor.flushDraft(app);XCTAssertFalse(tutor.record(app)["conversationDraft"]["messages"].array.contains{$0["role"].string == "user" && ["hola","me llamo"].contains($0["text"].string)})
        await tutor.stop(app)
    }
}

extension TutorSessionTests {
    private func speaking(_ transport:TutorTransport,_ id:String="followup",text:String="") {
        transport.onEvent?(.object(["type":.string("response.created"),"response":.object(["id":.string(id)])]))
        transport.onEvent?(.object(["type":.string("output_audio_buffer.started")]))
        if !text.isEmpty{transport.onEvent?(.object(["type":.string("response.audio_transcript.delta"),"response_id":.string(id),"delta":.string(text)]))}
    }
    private func late(_ text:String,_ id:String,_ transport:TutorTransport) async {
        transport.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"item_id":.string(id),"transcript":.string(text)]))
        for _ in 0..<100{await Task.yield()}
    }
    func testLateSpeechBeforePracticeDuringWelcomeAndDuringQuizNeverGradesOrConsumesAGreeting()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport();var calls=0,p=provider();p.judge={_ in calls += 1;return .object(["successful":.bool(false),"confidence":.number(1),"quizAnswered":.bool(false)])}
        let tutor=await session(app,transport,provider:p);await tutor.start(app);speaking(transport,"welcome")
        await late("hola","during-welcome",transport);XCTAssertTrue(tutor.messages.isEmpty);XCTAssertEqual(calls,0)
        transport.assistant("Welcome!",id:"welcome-finished");await tutor.input(input("yes","greeting"),app:app);speaking(transport,"kickoff")
        await late("me llamo","before-practice",transport);XCTAssertEqual(calls,0);XCTAssertEqual(app.learner.totalXP,0);XCTAssertEqual(tutor.messages.filter{$0["role"].string == "user"}.count,1)
        await tutor.stop(app);app.learner.tutorLevels=["es":"A1"];tutor.adoptLevel(app)
        let unit=try XCTUnwrap(tutor.catalog["A1"].array.first),quiz=try XCTUnwrap(unit["lessons"].array.first{$0["isFinalQuiz"].boolean});tutor.select(app,lesson:quiz,unit:unit)
        await tutor.start(app);transport.assistant("What should you say?",id:"quiz");await tutor.input(input("Please repeat the question","quiz-help"),app:app)
        let count=tutor.messages.count,cursor=tutor.state["currentItem"],judged=calls,before=transport.events.count;speaking(transport,"quiz-next")
        await late("A correct quiz answer","late-quiz",transport)
        XCTAssertEqual(calls,judged);XCTAssertEqual(tutor.state["currentItem"],cursor);XCTAssertEqual(tutor.messages.count,count);XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.gradedByLanguage)
        XCTAssertFalse(transport.events.dropFirst(before).contains{$0["type"].string == "response.create"});await tutor.stop(app)
    }
    func testLateSemanticRegularSuccessUsesStreamedPromptAdvancesOnceAndRatesTheOriginalQuestion()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport();var calls=0,p=provider();p.judge={prompt in calls += 1;if calls == 1{return .object(["successful":.bool(false),"confidence":.number(1)])};XCTAssertTrue(prompt.contains("Say agua."));return .object(["successful":.bool(true),"confidence":.number(1),"objectiveAdvanced":.bool(false)])}
        let tutor=TutorSessionController(live:LiveTutorService(permission:{true},transportFactory:{transport}),provider:p,turnXP:{5});await tutor.prepare(app);app.learner.tutorLevels=["es":"A1"];tutor.adoptLevel(app)
        let unit=try XCTUnwrap(tutor.catalog["A1"].array.first),lesson=try XCTUnwrap(unit["lessons"].array.first);tutor.select(app,lesson:lesson,unit:unit);await tutor.start(app);transport.assistant("Say hola.",id:"question")
        await tutor.input(input("I need more help","ordinary"),app:app);let count=tutor.messages.count,first=tutor.state["currentItem"]["id"].string;speaking(transport,text:"Say agua.")
        await late("a public complete attempt","semantic",transport);let next=tutor.state["currentItem"]["id"].string;XCTAssertNotEqual(next,first)
        await late("another public complete attempt","semantic-again",transport)
        XCTAssertEqual(calls,3);XCTAssertEqual(tutor.state["currentItem"]["id"].string,next);XCTAssertEqual(app.learner.totalXP,5);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1);XCTAssertEqual(tutor.messages.count,count)
        XCTAssertEqual(app.learner.pendingChanges?.filter{$0.source == .tutorTurn}.count,1);XCTAssertEqual(app.learner.history.count,0);await tutor.stop(app)
    }
    func testLateMistakesKeepOneAssessmentAndMemoryWithoutAddingChatOrAnotherReply()async throws {
        let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport();var calls=0,p=provider();p.judge={_ in calls += 1;return calls == 1 ? .object(["successful":.bool(false),"confidence":.number(1)]):.object(["successful":.bool(false),"confidence":.number(0.9),"mistake":.bool(true),"concept":.string("A greeting"),"correction":.string("Hola"),"reason":.string("Try the greeting")])}
        let tutor=await session(app,transport,provider:p);await tutor.start(app);transport.assistant("Welcome!");await tutor.input(input("yes","welcome"),app:app);transport.assistant("Say hola.",id:"practice");await tutor.input(input("Please explain","normal"),app:app)
        speaking(transport);let count=tutor.messages.count,before=transport.events.count
        await late("a public incorrect attempt","mistake",transport);await late("another public incorrect attempt","mistake-again",transport)
        XCTAssertEqual(app.learner.totalXP,0);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1);XCTAssertEqual(app.learner.companionMemory?["es"]?.count,1);XCTAssertEqual(tutor.messages.count,count);XCTAssertEqual(app.learner.history.count,0)
        XCTAssertFalse(transport.events.dropFirst(before).contains{$0["type"].string == "response.create"});XCTAssertEqual(tutor.live.voiceState,"speaking");await tutor.stop(app)
    }
    func testLateJudgeCannotCommitAfterPauseStopLanguageAccountOrLessonReplacement()async throws {
        for boundary in ["pause","stop","support","target","account","lesson"] {
            let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport();var held:CheckedContinuation<JSONValue,Error>?,calls=0,p=provider();p.judge={_ in calls += 1;if calls == 1{return .object(["successful":.bool(false),"confidence":.number(1)])};return try await withCheckedThrowingContinuation{held=$0}}
            let tutor=await session(app,transport,provider:p);await tutor.start(app);transport.assistant("Welcome!");await tutor.input(input("yes","welcome"),app:app);transport.assistant("Say hola.",id:"practice");await tutor.input(input("Please explain","normal"),app:app);speaking(transport)
            let task=Task{await tutor.input(input("a public late attempt","held"),app:app,assistantResponding:true)}
            for _ in 0..<100 where held == nil{await Task.yield()};XCTAssertNotNil(held,boundary)
            switch boundary {case "pause":await tutor.pause(app);case "stop":await tutor.stop(app);case "support":app.learner.support="ar";case "target":app.learner.target="fr";case "account":try app.identity.disconnect();try app.identity.create();default:let unit=try XCTUnwrap(tutor.catalog["Pre-A1"].array.last),lesson=try XCTUnwrap(unit["lessons"].array.last);tutor.select(app,lesson:lesson,unit:unit)}
            held?.resume(returning:.object(["successful":.bool(true),"confidence":.number(1),"mistake":.bool(true),"concept":.string("Old greeting"),"correction":.string("Hola")]));await task.value
            XCTAssertEqual(app.learner.totalXP,0,boundary);XCTAssertNil(app.learner.gradedByLanguage,boundary);XCTAssertTrue(app.learner.companionMemory?.isEmpty ?? true,boundary);await tutor.stop(app,saveDraft:false)
        }
    }
    func testLateEarnedCompletionKeepsTheReplyAndTrialOwnerUntilPlaybackStopsThenRetriesOnce()async throws {
        let cloud=TutorAcknowledgment();cloud.fails=true;let app=try await app(progressService:cloud);defer{try? app.identity.disconnect()};let transport=TutorTransport(),tutor=TutorSessionController(live:LiveTutorService(permission:{true},transportFactory:{transport}),provider:provider(),turnXP:{5})
        await tutor.prepare(app);let lessonID=tutor.id,items=tutor.state["items"].array,last=try XCTUnwrap(items.last),agenda:JSONValue = .object(Dictionary(uniqueKeysWithValues:items.dropLast().map{($0["id"].string,.bool(true))}))
        app.learner.storeTutorState(lesson:try XCTUnwrap(tutor.typedLesson),data:.object(["earnedXp":.number(45),"agenda":agenda]));
        // A restored record represents earlier earned XP, not a new reward.
        app.learner.tutorLessons?[app.learner.tutorKey(lessonID)]=TutorSourceProgress.importing(.object(["status":.string("in_progress"),"earnedXp":.number(45),"tutorAgendaProgress":.object(["schemaVersion":.number(2),"items":agenda])]))
        app.learner.xpByLanguage=["es":45];app.learner.subscriptionXPAdjustment=254;tutor.refresh(app)
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow},window=UIWindow(windowScene:scene);window.rootViewController=UIHostingController(rootView:ProductAccessGate(service:app.subscription){SourceTutorView(controller:tutor)}.environmentObject(app));window.makeKeyAndVisible();defer{window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
        for _ in 0..<80 where app.activityFooter == nil{try await Task.sleep(for:.milliseconds(25))}
        await tutor.start(app);transport.assistant("Say the final phrase.",id:"practice");await tutor.input(input("Please explain","normal"),app:app);speaking(transport,text:"Try that final phrase once more.")
        await late(last["phrase"].string,"earned-late",transport)
        XCTAssertEqual(tutor.earnedXP(app),50);XCTAssertTrue(tutor.completionPending);XCTAssertTrue(tutor.live.connected);XCTAssertFalse(app.subscription.hasAccess);XCTAssertTrue(app.preservingEarnedPractice);XCTAssertNil(tutor.completion);XCTAssertNil(tutor.error)
        XCTAssertEqual(app.learner.pendingChanges?.filter{$0.source == .speak}.count,0);XCTAssertEqual(app.learner.totalXP,50)
        let capture=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});capture.name="Native Tutor late completion waits through trial gate";capture.lifetime = .keepAlways;add(capture)
        transport.onEvent?(.object(["type":.string("response.done"),"response":.object(["id":.string("followup"),"output":.array([.object(["content":.array([.object(["transcript":.string("Try that final phrase once more.")])])])])])]))
        try await Task.sleep(for:.milliseconds(100));XCTAssertTrue(tutor.live.connected);XCTAssertNil(tutor.error)
        transport.onEvent?(.object(["type":.string("output_audio_buffer.stopped")]))
        for _ in 0..<100 where tutor.error == nil{try await Task.sleep(for:.milliseconds(25))}
        XCTAssertNotNil(tutor.error);XCTAssertTrue(tutor.completionPending);XCTAssertFalse(tutor.live.connected);XCTAssertEqual(app.learner.totalXP,100);XCTAssertEqual(app.learner.pendingChanges?.filter{$0.source == .speak}.count,1)
        cloud.fails=false;await tutor.complete(app,ready:true);XCTAssertNotNil(tutor.completion);XCTAssertEqual(app.learner.totalXP,100);await tutor.stop(app)
    }
}

extension TutorSessionTests {
    func testOriginalLateBurstProgressAndCompletionGateAgainstRenderedNativeInEnglishAndArabic()async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1" else{throw XCTSkip("Read-only original source preview required")}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for (support,theme) in [("en","light"),("ar","dark")] {for finishing in [false,true] {
            // Distinct private identities prevent an old view's asynchronous
            // disappearance/draft callback from seeding the next scenario.
            let app=try await app();defer{try? app.identity.disconnect()}
            app.learner=LearnerState();app.learner.target="es";app.learner.support=support;app.learner.onboardingComplete=true;await app.reloadContent()
            let transport=TutorTransport(),tutor=TutorSessionController(live:LiveTutorService(permission:{true},transportFactory:{transport}),provider:provider(),turnXP:{5});await tutor.prepare(app)
            let items=tutor.state["items"].array,agenda:JSONValue = .object(Dictionary(uniqueKeysWithValues:(finishing ? Array(items.dropLast()):[]).map{($0["id"].string,.bool(true))})),seed:JSONValue = .object(["lessonId":.string(tutor.id),"targetLang":.string("es"),"cefrLevel":.string("Pre-A1"),"status":.string("in_progress"),"earnedXp":.number(finishing ? 45:0),"tutorAgendaProgress":.object(["schemaVersion":.number(2),"items":agenda])])
            if finishing{app.learner.tutorLessons=[app.learner.tutorKey(tutor.id):TutorSourceProgress.importing(seed)];app.learner.xpByLanguage=["es":45];tutor.refresh(app)}
            let label=finishing ? "finishing":"fresh",web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:WKWebViewConfiguration()),sourceWindow=UIWindow(windowScene:scene),sourceHost=UIViewController();sourceWindow.frame=web.frame;sourceHost.view=web;sourceWindow.rootViewController=sourceHost;web.scrollView.contentInsetAdjustmentBehavior = .never;sourceWindow.makeKeyAndVisible()
            let nativeWindow=UIWindow(windowScene:scene);nativeWindow.frame=web.frame;let host=UIHostingController(rootView:TutorASRComparisonHost(tutor:tutor).environmentObject(app).environment(\.layoutDirection,support == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());nativeWindow.rootViewController=host;nativeWindow.makeKeyAndVisible();host.view.layoutIfNeeded();defer{web.stopLoading();sourceWindow.isHidden=true;sourceWindow.rootViewController=nil;nativeWindow.isHidden=true;nativeWindow.rootViewController=nil}
            var url=URLComponents(string:"http://127.0.0.1:5181/__piyali-onboarding")!;url.queryItems=[.init(name:"screen",value:"tutor"),.init(name:"tutorASR",value:"1"),.init(name:"language",value:support),.init(name:"theme",value:theme)];if finishing{url.queryItems?.append(.init(name:"tutorLateSeed",value:seed.json))};web.load(URLRequest(url:try XCTUnwrap(url.url)))
            let startLabel=String(decoding:try JSONEncoder().encode(EntryCopy.ui(support,"ra_btn_start")),as:UTF8.self);var ready=false
            for _ in 0..<500{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && [...document.querySelectorAll('button')].some(b=>b.textContent.trim()===\(startLabel)&&!b.disabled) && document.querySelector('[role=progressbar]')?.getAttribute('aria-valuenow')==='\(finishing ? 90:0)'")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))}
            XCTAssertTrue(ready,"\(support) \(label)");guard ready else{return}
            _=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(b=>b.textContent.trim()===\(startLabel)).click()")
            var connected=false;for _ in 0..<120{connected=(try? await web.evaluateJavaScript("!!window.__tutorASR?.sent.some(e=>e.response?.metadata?.kind==='\(finishing ? "tutor_kickoff":"tutor_welcome")')")) as? Bool == true;if connected{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(connected);guard connected else{return}
            func emit(_ events:[JSONValue])async throws {let values=try JSONSerialization.jsonObject(with:Data(JSONValue.array(events).json.utf8));_=try await web.callAsyncJavaScript("for(const event of events)await window.__tutorASR.emit(event)",arguments:["events":values],in:nil,contentWorld:.page)}
            func assistant(_ text:String,_ id:String,_ kind:String="tutor_followup")async throws {try await emit([.object(["type":.string("response.created"),"response":.object(["id":.string(id),"metadata":.object(["kind":.string(kind)])])]),.object(["type":.string("response.audio_transcript.done"),"response_id":.string(id),"transcript":.string(text)]),.object(["type":.string("response.done"),"response":.object(["id":.string(id),"status":.string("completed")])])]);try await Task.sleep(for:.milliseconds(600))}
            func shot(_ state:String)async throws {try await Task.sleep(for:.milliseconds(950));let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source Tutor late \(label) \(state) \(support)";source.lifetime = .keepAlways;add(source);nativeWindow.makeKeyAndVisible();host.view.layoutIfNeeded();let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:nativeWindow.bounds).image{_ in nativeWindow.drawHierarchy(in:nativeWindow.bounds,afterScreenUpdates:true)});native.name="Native Tutor late \(label) \(state) \(support)";native.lifetime = .keepAlways;add(native)}
            await tutor.start(app)
            if !finishing {
                try await assistant("Welcome!","welcome","tutor_welcome");transport.assistant("Welcome!")
                try await emit([.object(["type":.string("conversation.item.input_audio_transcription.completed"),"item_id":.string("greeting"),"transcript":.string("yes")])]);await tutor.input(input("yes","greeting"),app:app)
            }
            try await assistant("Say hola.","practice");transport.assistant("Say hola.",id:"practice")
            try await emit([.object(["type":.string("conversation.item.input_audio_transcription.completed"),"item_id":.string("normal"),"transcript":.string("I do not know")])]);await tutor.input(input("I do not know","normal"),app:app)
            let before=transport.events.count,count=tutor.messages.count
            let created:JSONValue = .object(["type":.string("response.created"),"response":.object(["id":.string("followup"),"metadata":.object(["kind":.string("tutor_followup")])])]),delta:JSONValue = .object(["type":.string("response.audio_transcript.delta"),"response_id":.string("followup"),"delta":.string("Try that phrase once more.")])
            try await emit([created,delta]);speaking(transport,text:"Try that phrase once more.");try await Task.sleep(for:.milliseconds(200));_=try await web.evaluateJavaScript("Math.random=()=>0.5;window.__tutorLateBefore=window.__tutorASR.sent.filter(e=>e.type==='response.create').length")
            let phrase=finishing ? try XCTUnwrap(items.last?["phrase"].string):"hola",event:JSONValue = .object(["type":.string("input_audio_transcription.completed"),"item_id":.string("late"),"transcript":.string(phrase)])
            try await emit([event]);await late(phrase,"late",transport);try await shot("credited")
            if !finishing{let name:JSONValue = .object(["type":.string("conversation.item.input_audio_transcription.completed"),"item_id":.string("late-name"),"transcript":.string("me llamo")]);try await emit([name,name.setting("item_id",.string("duplicate"))]);await late("me llamo","late-name",transport);await late("me llamo","duplicate",transport);try await shot("duplicate")}
            let sourceRaw=try await web.evaluateJavaScript("JSON.stringify({awards:window.__tutorASR.awards,awardAmounts:window.__tutorASR.awardAmounts,agendaWrites:window.__tutorASR.agendaWrites,earnedWrites:window.__tutorASR.earnedWrites,completed:window.__tutorASR.completed,learnerJudges:window.__tutorASR.learnerJudges,extraResponses:window.__tutorASR.sent.filter(e=>e.type==='response.create').length-window.__tutorLateBefore,microphone:window.__tutorASR.microphone,percent:Number(document.querySelector('[role=progressbar]').getAttribute('aria-valuenow')),badge:{text:document.querySelector('.chakra-badge')?.textContent,width:document.querySelector('.chakra-badge')?.getBoundingClientRect().width}})")
            let sourceTrace=try JSONDecoder().decode(JSONValue.self,from:Data(try XCTUnwrap(sourceRaw as? String).utf8));XCTAssertEqual(sourceTrace["awards"].number,1);XCTAssertEqual(sourceTrace["awardAmounts"],.array([.number(5)]));XCTAssertEqual(sourceTrace["completed"].number,0);XCTAssertEqual(sourceTrace["extraResponses"].number,0);XCTAssertEqual(sourceTrace["microphone"],.bool(false));XCTAssertEqual(sourceTrace["percent"].number,finishing ? 100:10)
            XCTAssertEqual(tutor.messages.count,count);XCTAssertFalse(transport.events.dropFirst(before).contains{$0["type"].string == "response.create"});XCTAssertEqual(app.learner.totalXP,finishing ? 50:5);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1);XCTAssertTrue(tutor.live.connected);XCTAssertEqual(tutor.completionPending,finishing)
            let nativeTrace:JSONValue = .object(["seed":seed,"totalXP":.number(Double(app.learner.totalXP)),"gradedAttempts":.number(Double(app.learner.gradedByLanguage?["es"] ?? 0)),"agenda":tutor.record(app)["tutorAgendaProgress"]["items"],"extraResponses":.number(Double(transport.events.dropFirst(before).filter{$0["type"].string == "response.create"}.count)),"microphone":.bool(transport.microphone),"completionPending":.bool(tutor.completionPending),"completionReceipts":.number(Double(app.learner.pendingChanges?.filter{$0.source == .speak}.count ?? 0)),"learnerMessages":.array(tutor.messages.filter{$0["role"].string == "user"}.map{$0["textFinal"]})])
            for (side,trace) in [("Source",sourceTrace),("Native",nativeTrace)] {let a=XCTAttachment(data:Data(trace.json.utf8),uniformTypeIdentifier:"public.json");a.name="\(side) Tutor late \(label) trace \(support)";a.lifetime = .keepAlways;add(a)}
            await tutor.stop(app);web.stopLoading();sourceWindow.isHidden=true;sourceWindow.rootViewController=nil;nativeWindow.isHidden=true;nativeWindow.rootViewController=nil
        }}
    }
}

extension TutorSessionTests {
    func testLateCompletionSettlesOnExplicitPauseEndAndTimeoutButRejectsAReplacedOwner()async throws {
        var rows:[JSONValue]=[]
        for boundary in ["pause","end","timeout","owner"] {
            let app=try await app();defer{try? app.identity.disconnect()};let transport=TutorTransport(),tutor=TutorSessionController(live:LiveTutorService(permission:{true},transportFactory:{transport}),provider:provider(),turnXP:{5},completionIdleTimeout:boundary == "timeout" ? 0.3:45)
            await tutor.prepare(app);let lessonID=tutor.id,items=tutor.state["items"].array,agenda:JSONValue = .object(Dictionary(uniqueKeysWithValues:items.dropLast().map{($0["id"].string,.bool(true))})),phrase=try XCTUnwrap(items.last?["phrase"].string)
            app.learner.tutorLessons=[app.learner.tutorKey(lessonID):TutorSourceProgress.importing(.object(["status":.string("in_progress"),"earnedXp":.number(45),"tutorAgendaProgress":.object(["schemaVersion":.number(2),"items":agenda])]))];app.learner.xpByLanguage=["es":45];tutor.refresh(app)
            await tutor.start(app);transport.assistant("Try the final phrase.",id:"practice");await tutor.input(input("Please explain","normal"),app:app);speaking(transport,text:"Try once more.");await late(phrase,"earned",transport)
            if boundary == "pause"{await tutor.pause(app)}else if boundary == "end"{await tutor.stop(app)}else if boundary == "owner"{app.learner.target="fr";await tutor.stop(app,saveDraft:false)}
            if boundary == "owner" {
                try await Task.sleep(for:.milliseconds(400));XCTAssertEqual(app.learner.totalXP,50);XCTAssertEqual(app.learner.pendingChanges?.filter{$0.source == .speak}.count,0)
                app.learner.target="es";let restored=await session(app,TutorTransport());XCTAssertTrue(restored.completionPending);XCTAssertNotNil(restored.error);XCTAssertFalse(restored.live.connected)
                XCTAssertEqual(app.learner.totalXP,100);XCTAssertEqual(app.learner.pendingChanges?.filter{$0.source == .speak}.count,1);await restored.stop(app)
            }else {
                for _ in 0..<100 where tutor.error == nil{try await Task.sleep(for:.milliseconds(25))}
                XCTAssertNotNil(tutor.error,boundary);XCTAssertFalse(tutor.live.connected,boundary);XCTAssertEqual(app.learner.totalXP,100,boundary);XCTAssertEqual(app.learner.pendingChanges?.filter{$0.source == .speak}.count,1,boundary)
                await tutor.complete(app,ready:true);XCTAssertEqual(app.learner.totalXP,100,boundary);await tutor.stop(app)
            }
            rows.append(.object(["boundary":.string(boundary),"totalXP":.number(Double(app.learner.totalXP)),"completionReceipts":.number(Double(app.learner.pendingChanges?.filter{$0.source == .speak}.count ?? 0)),"tutorTurnReceipts":.number(Double(app.learner.pendingChanges?.filter{$0.source == .tutorTurn}.count ?? 0)),"gradedAttempts":.number(Double(app.learner.gradedByLanguage?["es"] ?? 0))]))
        }
        let trace=XCTAttachment(data:Data(JSONValue.array(rows).json.utf8),uniformTypeIdentifier:"public.json");trace.name="Native Tutor late completion close timeout and hydrated recovery";trace.lifetime = .keepAlways;add(trace)
    }
}
