import XCTest
import SwiftUI
import UIKit
@testable import Piyali

@MainActor final class CompanionQuestFlowTests:XCTestCase {
    private func model()throws->AppModel {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Requires isolated offline identity.")}
        let app=AppModel();try app.identity.create();app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.onboardingComplete=true;app.signedIn=true;return app
    }
    private func note(_ id:String,day:String,type:String,concept:String,answer:String)->MemoryNote {
        MemoryNote(fields:["id":.string(id),"createdDayKey":.string(day),"createdAt":.number(Date().timeIntervalSince1970*1000),"status":.string("captured"),"concept":.string(concept),"expectedAnswer":.string(answer),"errorType":.string(type),"severity":.number(2),"cefrLevel":.string("Pre-A1")])
    }
    func testReturningQuestBuildsOnceRestoresAndCompletesSavedStepsWithoutBonusXP() async throws {
        let app=try model();defer{try? app.identity.disconnect()};let today=CalendarDay.key(Date()),yesterday=CalendarDay.shift(today,by:-1)
        app.learner.questProgress = .object(["dailyQuestFirstSeen":.bool(true),"dailyQuestFirstDayKey":.string(yesterday)])
        app.learner.questPlans=["es":DailyQuestPlan(day:today,kinds:["learn","review"])];app.learner.companionMemory=["es":[note("greeting",day:yesterday,type:"vocabulary",concept:"A greeting",answer:"Hola"),note("agreement",day:yesterday,type:"grammar",concept:"Use a simple agreement",answer:"Soy estudiante")]]
        await app.prepareCompanionQuest()
        let stored=app.learner.questDay(day:today),bubble=app.companionBubble()["display"].string
        XCTAssertEqual(stored["blueprint"]["status"].string,"ready");XCTAssertEqual(stored["repair"]["items"].array.count,2);XCTAssertFalse(bubble.isEmpty);XCTAssertEqual(app.plateCourses.first?.target,2)
        await app.prepareCompanionQuest();XCTAssertEqual(app.learner.questDay(day:today),stored)
        let first=try XCTUnwrap(app.currentRepairStep);XCTAssertEqual(first.mode,"flashcards")
        try await app.prepareRepairDeck(first);let card=try XCTUnwrap(try JSONDecoder().decode([Flashcard].self,from:Data(app.learner.repairArtifact(first,mode:"flashcards")["cards"].json.utf8)).first)
        XCTAssertEqual(card.concept["es"],"Hola");XCTAssertEqual(card.id,"repair-es-\(today)-s0-c0")
        app.recordRepairOutcome(first,mode:"flashcards",cardID:card.id,success:false,item:"Hola");XCTAssertEqual(app.plateCourses.first?.count,0);XCTAssertEqual(app.learner.totalXP,0)
        app.recordRepairOutcome(first,mode:"flashcards",cardID:card.id,success:true,item:"Hola");XCTAssertEqual(app.plateCourses.first?.count,1);XCTAssertEqual(app.learner.totalXP,2);XCTAssertEqual(app.learner.plateProgress["flashcardDailyActivity"]["es"][today].number,0)
        XCTAssertNil(app.learner.cardReviews)
        app.finishRepair(first,observation:"Stale duplicate");XCTAssertEqual(app.plateCourses.first?.count,1)
        let second=try XCTUnwrap(app.currentRepairStep);XCTAssertEqual(second.mode,"lesson");let lesson=try XCTUnwrap(app.repairLesson(second));XCTAssertTrue(lesson.isRepair == true);XCTAssertEqual(lesson.xpReward,10);XCTAssertEqual(lesson.modes,["vocabulary","grammar","reading","stories","realtime"])
        app.beginLesson(lesson);app.learner.award(6,lesson:lesson);XCTAssertFalse(app.canComplete(lesson));app.learner.award(5,lesson:lesson);XCTAssertTrue(app.canComplete(lesson));app.complete(lesson)
        XCTAssertEqual(app.plateCourses.first?.count,2);XCTAssertEqual(app.plateCourses.first?.target,2);XCTAssertNil(app.currentRepairStep);XCTAssertEqual(app.learner.totalXP,13,"The 10-XP threshold completes a repair; completion must not award another 10 or 20 XP.")
        XCTAssertEqual(app.learner.companionMemory?["es"]?.filter{$0.text("status") == "reinforced"}.count,2)
        XCTAssertEqual(app.learner.goalBucket["repairSummary"]["eventIds"].array.count,2);XCTAssertEqual(app.learner.pendingRepairEvidence?.count,2)
        app.persist();let ready=app.learner.questDay(day:today);app.learner=LearnerState();app.loadLocal();XCTAssertEqual(app.learner.questDay(day:today),ready);XCTAssertEqual(app.plateCourses.first?.count,2)
    }
    func testAuthoredPhonicsRepairKeepsOriginalAndTransferOutcomesSeparateFromNormalPhonics() async throws {
        let app=try model();defer{try? app.identity.disconnect()};let today=CalendarDay.key(Date()),yesterday=CalendarDay.shift(today,by:-1)
        app.phonicsLibrary=try ContentLibrary.load([String:[PhonicsCard]].self,name:"phonics")
        let original=try XCTUnwrap(app.phonicsLibrary["es:en:Pre-A1"]?.first)
        XCTAssertEqual(original.cefrLevel,"Pre-A1")
        app.learner.questProgress = .object(["dailyQuestFirstSeen":.bool(true),"dailyQuestFirstDayKey":.string(yesterday)]);app.learner.questPlans=["es":DailyQuestPlan(day:today,kinds:["learn"])]
        var memory=note("sound",day:yesterday,type:"pronunciation",concept:original.practiceWord,answer:original.practiceWord)
        memory.fields["sourceContext"] = .object(["card":.object(["id":.string(original.id),"practiceWord":.string(original.practiceWord)])]);app.learner.companionMemory=["es":[memory]]
        await app.prepareCompanionQuest();let step=try XCTUnwrap(app.currentRepairStep);XCTAssertEqual(step.mode,"phonics");XCTAssertEqual(app.authoredRepairPhonics(step).count,3)
        try await app.prepareRepairPhonics(step);let cards=app.repairPhonics(step);XCTAssertEqual(cards.count,3);XCTAssertEqual(cards.map(\.practiceRole),["original","contrast","transfer"])
        app.learner.support="ar";let arabic=app.repairPhonics(step);XCTAssertEqual(arabic.map(\.id),cards.map(\.id));XCTAssertEqual(arabic.first?.tip,app.phonicsLibrary["es:ar:Pre-A1"]?.first?.tip);app.learner.support="en"
        app.recordRepairOutcome(step,mode:"phonics",cardID:cards[0].id,success:true,item:cards[0].practiceWord);XCTAssertEqual(app.plateCourses.first?.count,0)
        app.recordRepairOutcome(step,mode:"phonics",cardID:cards[2].id,success:true,item:cards[2].practiceWord);XCTAssertEqual(app.plateCourses.first?.count,1);XCTAssertEqual(app.learner.totalXP,10)
        XCTAssertEqual(app.learner.plateProgress["phonicsDailyActivity"],.null);XCTAssertNil(app.learner.masteredPhonics)
        XCTAssertFalse(app.learner.repairArtifact(step,mode:"phonics")["outcomes"][cards[1].id]["success"].boolean)
    }
    func testFirstQuestUsesWelcomeButClearingItPreparesTomorrowsMemoryAndGoal() async throws {
        let app=try model();defer{try? app.identity.disconnect()};let today=CalendarDay.key(Date()),tomorrow=CalendarDay.shift(today,by:1)
        app.learner.editGoal("Speak with family");app.learner.preparePlate(user:app.identity.npub,available:DailyPlate.introductory)
        app.learner.companionMemory=["es":[note("today",day:today,type:"vocabulary",concept:"A greeting",answer:"Hola")]]
        app.learner.importQuestDay(.object([:]),target:"es",day:today)
        let awaitingTomorrow=app.companionQuestPreparationKey
        app.learner.importQuestDay(.object([:]),target:"es",day:tomorrow)
        XCTAssertNotEqual(app.companionQuestPreparationKey,awaitingTomorrow,"Tomorrow hydration must retrigger a waiting preparation task.")
        XCTAssertEqual(Set((0..<20).map{_ in app.companionQuestPreparationKey}).count,1,"A semantic goal snapshot must produce a stable task key.")
        await app.prepareCompanionQuest();XCTAssertEqual(app.learner.questDay(day:today)["blueprint"],.null);XCTAssertEqual(app.companionBubble()["leadKind"].string,"welcomeGoal")
        var progress=app.learner.plateProgress
        for kind in ["speak","learn","review","goal"] {progress=progress.setting(DailyPlate.fields[kind]!, .object(["es":.object([today:.number(20)])]))};app.learner.questProgress=progress
        XCTAssertTrue(app.plateCourses.allSatisfy(\.done))
        await app.prepareCompanionQuest();XCTAssertEqual(app.learner.questDay(day:tomorrow)["blueprint"]["status"].string,"ready");XCTAssertEqual(app.learner.questDay(day:tomorrow)["repair"]["items"].array.count,1);XCTAssertEqual(app.learner.questDay(day:today)["blueprint"],.null)
        XCTAssertTrue(app.companionBubble()["display"].string.isEmpty);XCTAssertEqual(app.learner.totalXP,25,"Clearing the first quest grants its plate bonus once; preparation grants no extra XP.")
    }
    func testReadyAIMessageWinsReturningBubbleAndClearedRepairKeepsSourceRecapRule() async throws {
        let app=try model();defer{try? app.identity.disconnect()};let today=CalendarDay.key(Date()),yesterday=CalendarDay.shift(today,by:-1)
        app.learner.questProgress = .object(["dailyQuestFirstSeen":.bool(true),"dailyQuestFirstDayKey":.string(yesterday)]);app.learner.questPlans=["es":DailyQuestPlan(day:today,kinds:["speak","learn","review"])]
        app.learner.companionMemory=["es":[note("a",day:yesterday,type:"vocabulary",concept:"saludos",answer:"Hola")]]
        let plan:JSONValue = .object(["targetLang":.string("es"),"dayKey":.string(today),"items":.array([.object(["memoryId":.string("a"),"concept":.string("saludos"),"mode":.string("flashcards")])]),"memoryIds":.array([.string("a")])])
        app.learner.importQuestDay(.object(["repair":plan,"blueprint":.object(["status":.string("ready"),"message":.object(["long":.string("A warm-up for greetings, then keep moving forward.")])])]),target:"es",day:today)
        XCTAssertEqual(app.companionBubble()["display"].string,"A warm-up for greetings, then keep moving forward.")
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),oldKey=scene.windows.first{$0.isKeyWindow}
        for support in ["en","ar"] {
            app.learner.support=support;app.learner.companionName="Piyali"
            let message=support == "ar" ? "حفظت لك تدريبًا قصيرًا على التحيات لتصبح أسهل اليوم. ثم سنواصل التقدم في تدريباتك المعتادة.":"I saved a quick warm-up for greetings so they feel easier today. Then we’ll keep moving forward with your regular practice."
            let key=CompanionQuestDay.key("es",today),document=app.learner.questDay(day:today)
            app.learner.companionQuestDays?[key]=document.setting("blueprint",document["blueprint"].setting("message",.object(["long":.string(message)])))
            app.learner.storePlateHeadline(.init(dayKey:today,appLanguage:support,text:support == "ar" ? "أكمل مهامك واحصل على مكافأة XP":"Complete your tasks to earn an XP bonus"),target:"es")
            let host=UIHostingController(rootView:TodayFocusHomeView(sessionActive:false,onStart:{},onPanel:{_ in},onCompanionContinue:{}).environmentObject(app).environment(\.layoutDirection,support == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).ignoresSafeArea().preferredColorScheme(.light))
            let window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded()
            defer{window.isHidden=true;window.rootViewController=nil;oldKey?.makeKey()}
            try await Task.sleep(for:.milliseconds(200))
            let image=UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)}
            let attachment=XCTAttachment(image:image);attachment.name="Returning companion \(support)";attachment.lifetime = .keepAlways;add(attachment)
        }
        let doc=app.learner.questDay(day:today);app.learner.companionQuestDays?[CompanionQuestDay.key("es",today)]=doc.setting("blueprint",doc["blueprint"].setting("message",.object(["long":.string("A warm-up for greetings, then keep moving forward.")])))
        var progress=app.learner.plateProgress;for kind in ["speak","learn","review","repair"] {progress=progress.setting(DailyPlate.fields[kind]!, .object(["es":.object([today:.number(10)])]))};app.learner.questProgress=progress
        XCTAssertEqual(app.companionBubble()["display"].string,"A warm-up for greetings, then keep moving forward.","The source still prefers a ready AI message on a cleared repair day.")
    }
}
