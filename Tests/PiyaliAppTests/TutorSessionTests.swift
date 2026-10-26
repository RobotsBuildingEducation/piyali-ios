import XCTest
import SwiftUI
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
        XCTAssertTrue(session.completionPending);XCTAssertFalse(session.focusedFinished);XCTAssertFalse(app.subscription.hasAccess);XCTAssertNotNil(session.error);XCTAssertTrue(app.preservingEarnedPractice);XCTAssertEqual(surfaces,[.tutor]);XCTAssertNil(app.currentRepairStep)
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
