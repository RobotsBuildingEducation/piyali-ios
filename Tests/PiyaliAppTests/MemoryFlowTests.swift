import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor final class MemoryFlowTests:XCTestCase {
    private func model(memoryProvider:((String)async throws->String)?=nil,progressService:(any LearnerProgressService)?=nil)throws->AppModel {
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,MemoryDrawerFixture.enabled else{throw XCTSkip("Isolated Memory fixture required")}
        let app=AppModel(progressService:progressService,memoryProvider:memoryProvider);try app.identity.create();app.signedIn=true;app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.onboardingComplete=true;MemoryDrawerFixture.seed(app);return app
    }
    func testDigestIsCachedAndCannotLeakAcrossPracticeLanguages()async throws {
        let app=try model();defer{try? app.identity.disconnect()};var calls=0
        let controller=MemoryDrawerController(provider:{_ in calls += 1;return MemoryDrawerFixture.summary("en")});controller.refresh(app);defer{controller.cancel()}
        for _ in 0..<100 where controller.summary.isEmpty{try await Task.sleep(for:.milliseconds(20))};XCTAssertEqual(controller.summary,MemoryDrawerFixture.summary("en"));XCTAssertEqual(calls,1)
        controller.refresh(app);try await Task.sleep(for:.milliseconds(40));XCTAssertEqual(calls,1)
        app.learner.target="fr";controller.refresh(app);XCTAssertEqual(controller.summary,"")
    }
    func testArabicLocalizationRejectsLeakedSupportTextAndPreservesRepairStatus()async throws {
        let app=try model();defer{try? app.identity.disconnect()};app.learner.support="ar";var note=try XCTUnwrap(app.learner.companionMemory?["es"]?.first);note.fields["status"] = .string("reinforced");app.learner.companionMemory=["es":[note]];var requests=0
        let controller=MemoryDrawerController(provider:{prompt in requests += 1;return prompt.contains("digest") ? MemoryDrawerFixture.summary("ar"):"{\"did\":\"Your answer was wrong\",\"fix\":\"hola\",\"tip\":\"Keep your word\"}"});controller.refresh(app);defer{controller.cancel()}
        for _ in 0..<100 where app.learner.companionMemory?["es"]?.first?.text("supportLang") != "ar"{try await Task.sleep(for:.milliseconds(20))}
        let stored=try XCTUnwrap(app.learner.companionMemory?["es"]?.first);XCTAssertEqual(stored.text("mistake"),"");XCTAssertEqual(stored.text("tip"),"");XCTAssertEqual(stored.text("correction"),"hola");XCTAssertEqual(stored.text("status"),"reinforced");XCTAssertEqual(stored.severity,note.severity);XCTAssertGreaterThanOrEqual(requests,2)
        XCTAssertEqual(app.learner.pendingMemoryChanges?.filter{$0.action == .localize}.count,1)
    }
    func testActualWebNIP44WrappedKeyDecryptsWithNativeIdentity()async throws {
        let app=try model();defer{try? app.identity.disconnect()};let url=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"journey-crypto",withExtension:"json")),vector=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url))
        try app.identity.importKey(vector["nsec"].string);XCTAssertEqual(app.identity.npub,vector["npub"].string)
        let key=try await app.identity.decryptWallet(vector["envelope"]["wrappedKey"].string,expectedAuthor:app.identity.hex);XCTAssertEqual(key,vector["key"].string)
    }
    func testRepairArrivingDuringSummaryIsLocalizedBeforeRefreshSettles()async throws {
        let app=try model(memoryProvider:{_ in "{\"did\":\"A missing greeting\",\"fix\":\"hola\",\"tip\":\"Keep the h\"}"});defer{try? app.identity.disconnect()};var resume:CheckedContinuation<String,Error>?,calls=0
        let controller=MemoryDrawerController(provider:{prompt in
            calls += 1
            if calls == 1{return try await withCheckedThrowingContinuation{resume=$0}}
            return prompt.contains("digest") ? MemoryDrawerFixture.summary("en"):"{\"did\":\"A missing greeting\",\"fix\":\"hola\",\"tip\":\"Keep the h\"}"
        });controller.refresh(app);defer{resume?.resume(throwing:CancellationError());controller.cancel()}
        for _ in 0..<100 where resume == nil{try await Task.sleep(for:.milliseconds(10))}
        XCTAssertNotNil(resume)
        app.learner.captureMemory(mode:"grammar",concept:"new greeting",answer:"ola",expected:"hola",feedback:"")
        let id=try XCTUnwrap(app.learner.companionMemory?["es"]?.first{$0.text("concept") == "new greeting"}?.id)
        controller.refresh(app);resume?.resume(returning:MemoryDrawerFixture.summary("en"));resume=nil
        for _ in 0..<200 where calls<2 || app.learner.companionMemory?["es"]?.first(where:{$0.id == id})?.text("iosMemoryEnrichedSupport") != "en"{try await Task.sleep(for:.milliseconds(10))}
        XCTAssertEqual(app.learner.companionMemory?["es"]?.first(where:{$0.id == id})?.text("iosMemoryEnrichedSupport"),"en");XCTAssertGreaterThanOrEqual(calls,2)
    }
    func testExerciseNoteKeepsSourceGeneratedContentAndPrivateStudyMetadata()async throws {
        let app=try model();defer{try? app.identity.disconnect()}
        let q=try PracticeQuestion(module:.vocabulary,kind:"mc",payload:.object(["question":.string("Choose a greeting"),"choices":.array([.string("hola"),.string("adiós")]),"answer":.string("hola")]),options:.object(["cefrLevel":.string("A1")]),target:"es",support:"en")
        var run=PracticeRun(question:q,lessonID:nil,lessonLevel:"A1",response:.object(["indices":.array([.number(0)])]));run.correct=true;app.learner.savePractice(run)
        let original=app.learner.notes.count,created=try await app.createStudyNote(run:run,lesson:nil,respond:{_ in "{\"example\":\"Hola, mamá.\",\"summary\":\"Use hola to greet a family member.\"}"})
        XCTAssertTrue(created);XCTAssertEqual(app.learner.notes.count,original+1)
        let note=try XCTUnwrap(app.learner.notes.first),study=try XCTUnwrap(note.study)
        XCTAssertEqual(study["example"].string,"Hola, mamá.");XCTAssertEqual(study["summary"].string,"Use hola to greet a family member.");XCTAssertEqual(study["targetLang"].string,"es");XCTAssertEqual(study["supportLang"].string,"en");XCTAssertEqual(study["cefrLevel"].string,"A1");XCTAssertEqual(study["moduleType"].string,"vocabulary");XCTAssertEqual(study["wasCorrect"],.bool(true));XCTAssertNotNil(note.createdAt)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(app.learner));XCTAssertEqual(restored.notes.first?.study,study)
    }
    func testExerciseNoteFinishesAfterNextWithCapturedContextAndNoAdditionalReward()async throws {
        let app=try model();defer{try? app.identity.disconnect()};app.learner.notes=[]
        let q=try PracticeQuestion(module:.grammar,kind:"delight:three_clue_mystery",payload:.object(["variant":.string("three_clue_mystery"),"answer":.string("pan"),"example":.string("Como pan.")]),options:.object(["cefrLevel":.string("A1")]),target:"es",support:"en")
        var run=PracticeRun(question:q,lessonID:nil,lessonLevel:"A1",response:.object(["text":.string("pan")]));run.correct=true;app.learner.savePractice(run)
        var resume:CheckedContinuation<String,Error>?,prompt="";let xp=app.learner.totalXP
        let task=Task{try await app.createStudyNote(run:run,lesson:nil,respond:{value in prompt=value;return try await withCheckedThrowingContinuation{resume=$0}})}
        for _ in 0..<100 where resume == nil{await Task.yield()};XCTAssertNotNil(resume)
        var next=run;next.question.id=UUID();next.response = .object(["text":.string("new answer")]);app.learner.savePractice(next)
        resume?.resume(returning:"{\"example\":\"Como pan.\",\"summary\":\"Bread is pan.\"}");let saved=try await task.value;XCTAssertTrue(saved)
        let note=try XCTUnwrap(app.learner.notes.first);XCTAssertEqual(note.title,"pan — Como pan.");XCTAssertEqual(note.study?["userAnswer"].string,"pan");XCTAssertEqual(note.study?["lessonTitle"]["es"].string,"Gramática");XCTAssertTrue(prompt.contains("pan — Como pan."));XCTAssertFalse(prompt.contains("new answer"));XCTAssertEqual(app.learner.totalXP,xp);XCTAssertEqual(app.learner.practiceRuns?[run.key]?.question.id,next.question.id)
    }
    func testExerciseNoteRejectsAccountTargetSupportReplacementAndCancellation()async throws {
        let app=try model();defer{try? app.identity.disconnect()}
        for change in ["account","sameAccount","target","support","signedOut","cancel"] {
            app.signedIn=true;app.learner=LearnerState();app.learner.notes=[]
            let q=try PracticeQuestion(module:.vocabulary,kind:"mc",payload:.object(["question":.string("Choose a greeting"),"choices":.array([.string("hola"),.string("adiós")]),"answer":.string("hola")]),options:.object([:]),target:"es",support:"en")
            var run=PracticeRun(question:q,lessonID:nil,lessonLevel:nil,response:.object(["indices":.array([.number(0)])]));run.correct=true;app.learner.savePractice(run)
            var resume:CheckedContinuation<String,Error>?
            let task=Task{try await app.createStudyNote(run:run,lesson:nil,respond:{_ in try await withCheckedThrowingContinuation{resume=$0}})}
            for _ in 0..<100 where resume == nil{await Task.yield()};XCTAssertNotNil(resume)
            switch change{case "account":try app.identity.disconnect();try app.identity.create();case "sameAccount":let key=app.identity.exportKey();try app.identity.disconnect();try app.identity.importKey(key);case "target":app.learner.target="fr";case "support":app.learner.support="ar";case "signedOut":app.signedIn=false;default:task.cancel()}
            resume?.resume(returning:"{\"example\":\"Hola.\",\"summary\":\"A greeting.\"}")
            do {let saved=try await task.value;XCTAssertFalse(saved,change)}catch{XCTAssertEqual(change,"cancel");XCTAssertTrue(error is CancellationError)}
            XCTAssertTrue(app.learner.notes.isEmpty,change);XCTAssertEqual(app.learner.totalXP,0)
        }
    }
    func testLocalRepairCaptureSignalsOnceLocalizationDoesNotReplayAndScopeClearsIt()throws {
        let app=try model();defer{app.memoryCapture.cancel();try? app.identity.disconnect()};app.memoryCapture.cancel()
        app.learner.captureMemory(mode:"grammar",concept:"saludos",answer:"ola",expected:"hola",feedback:"")
        let id=try XCTUnwrap(app.memoryCapture.event?.id),note=try XCTUnwrap(app.learner.activeMemories.first{$0.text("concept")=="saludos"})
        app.learner.localizeMemory(note,fields:.object(["mistake":.string("Missing h")]),support:"en")
        XCTAssertEqual(app.memoryCapture.event?.id,id)
        app.learner.support="ar";XCTAssertNil(app.memoryCapture.event)
        app.learner.dailyGoal=200;XCTAssertNil(app.memoryCapture.event)
        let session=app.identity.sessionRevision;app.identity.cancelSigning();XCTAssertEqual(app.identity.sessionRevision,session)
    }
    func testActualFeedbackPublisherCapturesWrongOnceAndResetsForTheNextQuestion()async throws {
        let app=try model();defer{app.memoryCapture.cancel();try? app.identity.disconnect()};app.memoryCapture.cancel()
        let state=MemoryFooterProbeState(),scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow},window=UIWindow(windowScene:scene)
        window.frame=CGRect(x:0,y:0,width:402,height:400);window.rootViewController=UIHostingController(rootView:MemoryFooterProbe(app:app,state:state));window.makeKeyAndVisible()
        defer{window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
        try await Task.sleep(for:.milliseconds(50));state.correct=false;state.revision="wrong-1"
        for _ in 0..<100 where app.memoryCapture.event == nil{try await Task.sleep(for:.milliseconds(10))}
        let first=try XCTUnwrap(app.memoryCapture.event?.id);state.revision="explanation"
        try await Task.sleep(for:.milliseconds(100));XCTAssertEqual(app.memoryCapture.event?.id,first)
        state.correct=nil;state.revision="new-question";try await Task.sleep(for:.milliseconds(100))
        state.correct=false;state.revision="wrong-2"
        for _ in 0..<100 where app.memoryCapture.event?.id == first{try await Task.sleep(for:.milliseconds(10))}
        XCTAssertNotNil(app.memoryCapture.event);XCTAssertNotEqual(app.memoryCapture.event?.id,first)
    }
    func testActualMemoryDrawerAndNativeScreens()async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1" else{throw XCTSkip("Read-only source preview required")}
        let app=try model();defer{try? app.identity.disconnect()};let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow}
        for (lang,theme) in [("en","light"),("ar","dark")] {for state in ["repairs","goals","notes","journey","record"] {
            let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:config),vc=UIViewController(),window=UIWindow(windowScene:scene);vc.view=web;window.frame=web.frame;window.rootViewController=vc;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-onboarding?screen=memory&tool=\(state == "record" ? "journey":state)&language=\(lang)&theme=\(theme)"))))
            var ready=false;for _ in 0..<400{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && document.querySelectorAll('[role=tab]').length===4")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(ready,"Source Memory \(state) failed");guard ready else{return}
            if state == "record"{let title=MemoryUI.journey(lang,"record");let encoded=try JSONEncoder().encode(title),literal=String(data:encoded,encoding:.utf8)!;_=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(e=>e.textContent.trim()===\(literal)).click()");try await Task.sleep(for:.milliseconds(350))}
            try await Task.sleep(for:.milliseconds(300));let shot=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));shot.name="Source Memory \(state) \(lang)";shot.lifetime = .keepAlways;add(shot)
            let raw=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('.chakra-modal__content,.chakra-modal__header,.chakra-modal__body,[role=tab],p,button')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {text:e.textContent,x:r.x,y:r.y,width:r.width,height:r.height,font:s.font,padding:s.padding,bg:s.backgroundColor,border:s.borderColor,radius:s.borderRadius}}))");let metrics=XCTAttachment(data:Data(try XCTUnwrap(raw as? String).utf8),uniformTypeIdentifier:"public.json");metrics.name="Source Memory \(state) \(lang) geometry";metrics.lifetime = .keepAlways;add(metrics);web.stopLoading();window.isHidden=true;window.rootViewController=nil
            app.learner.support=lang;app.learner.notes=MemoryDrawerFixture.studyNotes(lang);app.learner.companionMemory=["es":MemoryDrawerFixture.repairNotes(lang)]
            let journey=VoiceJourneyController();if state == "record"{await journey.bind(app)}
            let host=UIHostingController(rootView:ZStack{BrandBackground();MemoryDrawerView(onClose:{},initialTab:state == "record" ? "journey":state);if state == "record"{JourneyRecordingView(journey:journey,milestone:5,onClose:{})}}.environmentObject(app).environment(\.layoutDirection,lang == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).ignoresSafeArea().preferredColorScheme(theme == "dark" ? .dark:.light));window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(500))
            let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native Memory \(state) \(lang)";native.lifetime = .keepAlways;add(native);window.isHidden=true;window.rootViewController=nil;journey.close()
        }};old?.makeKey()
    }
}

@MainActor private final class MemoryFooterProbeState:ObservableObject {
    @Published var correct:Bool?
    @Published var revision="idle"
}
private struct MemoryFooterProbe:View {
    let app:AppModel
    @ObservedObject var state:MemoryFooterProbeState
    let owner=UUID()
    var body:some View {Text("Practice").activityFooter(owner:owner,revision:state.revision,access:app.subscription,fixtureAllowed:true,correct:state.correct){Text("Feedback")}.environmentObject(app)}
}

extension MemoryFlowTests {
    func testDrawerEnrichmentCannotRetryUnderAReplacedIdentitySession()async throws {
        let app=try model();defer{try? app.identity.disconnect()};app.learner.support="ar";var requests=0,held:CheckedContinuation<String,Error>?
        let drawer=MemoryDrawerController(provider:{_ in requests += 1;if requests == 1{return try await withCheckedThrowingContinuation{held=$0}};return "invalid"});defer{drawer.cancel()};drawer.refresh(app)
        for _ in 0..<100 where held == nil{await Task.yield()};XCTAssertNotNil(held);try app.identity.disconnect();try app.identity.create();let original=app.learner.companionMemory;held?.resume(returning:"{\"did\":\"The greeting was missing.\",\"fix\":\"Hola\",\"tip\":\"Start with hola.\"}");held=nil
        for _ in 0..<200{await Task.yield()};XCTAssertEqual(requests,1);XCTAssertTrue(drawer.summary.isEmpty);XCTAssertEqual(app.learner.companionMemory,original)
    }
}

extension MemoryFlowTests {
    func testOpeningAnAlreadyLocalizedPendingNoteDoesNotInventEnrichmentOrRetryTheCapture()async throws {
        let app=try model();defer{try? app.identity.disconnect()};app.learner=LearnerState();app.learner.onboardingComplete=true
        let now=Date(),fields=MemoryUI.value("captureNote",.object(["targetLang":.string("es"),"supportLang":.string("en"),"sourceMode":.string("grammar"),"concept":.string("A greeting"),"expectedAnswer":.string("Hola"),"now":.string(WebProgressContract.iso(now))]))
        let note=try XCTUnwrap(app.learner.captureMemory(MemoryNote(fields:fields.object),now:now));var enrichments=0
        let drawer=MemoryDrawerController(provider:{prompt in if !prompt.contains("digest"){enrichments += 1};return ""});drawer.refresh(app);defer{drawer.cancel()}
        for _ in 0..<200{await Task.yield()}
        XCTAssertEqual(enrichments,0);XCTAssertEqual(app.learner.companionMemory?["es"]?.first?.fields["enriched"],.bool(false));XCTAssertEqual(app.learner.pendingMemoryChanges?.filter{$0.action == .localize}.count,0);XCTAssertEqual(app.learner.companionMemory?["es"]?.first?.id,note.id)
    }
}

extension MemoryFlowTests {
    func testSharedCaptureStartsBeforeDrawerAndEnrichesOriginalBucketAcrossModes()async throws {
        for mode in ["grammar","vocabulary","reading","story","phonics","flashcard","conversation","tutor"] {
            var held:CheckedContinuation<String,Error>?,requests=0
            let app=try model(memoryProvider:{_ in requests += 1;return try await withCheckedThrowingContinuation{held=$0}});defer{try? app.identity.disconnect()};app.learner=LearnerState();app.learner.onboardingComplete=true
            app.learner.captureMemory(mode:mode,concept:"A greeting",answer:"ola",expected:"hola",feedback:"Private grade reason");let note=try XCTUnwrap(app.learner.companionMemory?["es"]?.first)
            for _ in 0..<200 where held == nil{await Task.yield()};XCTAssertNotNil(held,mode);XCTAssertEqual(requests,1);XCTAssertTrue(note.text("mistake").isEmpty);XCTAssertEqual(note.fields["enriched"],.bool(false));XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.gradedByLanguage)
            let eligible=["grammar","vocabulary","reading","story","phonics"].contains(mode);XCTAssertEqual(app.learner.pendingRepairEvidence?.count ?? 0,eligible ? 1:0,mode);XCTAssertEqual(app.learner.goalBucket["repairSummary"]["openPatterns"].array.count,eligible ? 1:0,mode)
            XCTAssertEqual(app.learner.companionQuestUser["learningIntelligence"]["es"]["repairSummary"],app.learner.goalBucket["repairSummary"])
            app.learner.reinforceMemory(id:note.id);app.learner.target="fr";held?.resume(returning:"{\"did\":\"A missing greeting\",\"fix\":\"hola\",\"tip\":\"Start with hola.\"}");held=nil;await app.memoryEnrichment.wait(note,app:app)
            let enriched=try XCTUnwrap(app.learner.companionMemory?["es"]?.first);XCTAssertEqual(enriched.text("tip"),"Start with hola.",mode);XCTAssertEqual(enriched.fields["enriched"],.bool(true));XCTAssertEqual(enriched.text("status"),"reinforced");XCTAssertEqual(app.learner.target,"fr");XCTAssertNil(app.learner.companionMemory?["fr"]);XCTAssertEqual(app.learner.totalXP,0)
        }
    }
    func testFailedCaptureStaysPendingAndOnlyANewSlipRetriesEnrichment()async throws {
        var requests=0;let app=try model(memoryProvider:{_ in requests += 1;return ""});defer{try? app.identity.disconnect()};app.learner=LearnerState();app.learner.onboardingComplete=true
        app.learner.captureMemory(mode:"grammar",concept:"A greeting",answer:"ola",expected:"hola",feedback:"Private reason");let first=try XCTUnwrap(app.learner.companionMemory?["es"]?.first);await app.memoryEnrichment.wait(first,app:app);XCTAssertTrue(app.learner.pendingMemoryEnrichments?.isEmpty == true);app.resumeMemoryEnrichments();await app.reloadContent();XCTAssertEqual(requests,1);XCTAssertEqual(app.learner.companionMemory?["es"]?.first?.fields["enriched"],.bool(false))
        var drawerEnrichments=0;let drawer=MemoryDrawerController(provider:{p in if !p.contains("digest"){drawerEnrichments += 1};return ""});drawer.refresh(app);defer{drawer.cancel()};for _ in 0..<200{await Task.yield()};XCTAssertEqual(drawerEnrichments,0);XCTAssertEqual(app.learner.pendingMemoryChanges?.filter{$0.action == .localize}.count,0)
        app.learner.captureMemory(mode:"grammar",concept:"A greeting",answer:"second attempt",expected:"new correction",feedback:"Private reason",now:Date().addingTimeInterval(1));let second=try XCTUnwrap(app.learner.companionMemory?["es"]?.first);await app.memoryEnrichment.wait(second,app:app)
        XCTAssertEqual(requests,2);XCTAssertEqual(second.id,first.id);XCTAssertEqual(second.severity,2);XCTAssertEqual(second.text("expectedAnswer"),"hola");XCTAssertEqual(app.learner.goalBucket["repairSummary"]["openPatterns"].array.first?["recurrence"],.number(2));XCTAssertEqual(app.learner.totalXP,0)
    }
}

extension MemoryFlowTests {
    func testConceptOnlyLocalizationFailurePreservesAnExistingEnrichedCorrection()async throws {
        let app=try model();defer{try? app.identity.disconnect()};app.learner=LearnerState();app.learner.onboardingComplete=true;app.learner.support="es"
        var note=MemoryContract.capture(target:"es",support:"es",level:"A1",mode:"grammar",concept:"hola",answer:"ola",expected:"hola",feedback:"");note.fields["concept"] = .string("hola (the word hello)");note.fields["correction"] = .string("¡Hola!");note.fields["mistake"] = .string("Faltaba un saludo.");note.fields["tip"] = .string("Saluda primero.");note.fields["enriched"] = .bool(true);app.learner.companionMemory=["es":[note]]
        let drawer=MemoryDrawerController(provider:{_ in ""});drawer.refresh(app);defer{drawer.cancel()};for _ in 0..<200 where app.learner.companionMemory?["es"]?.first?.text("concept") != "hola"{await Task.yield()}
        let saved=try XCTUnwrap(app.learner.companionMemory?["es"]?.first);XCTAssertEqual(saved.text("concept"),"hola");XCTAssertEqual(saved.text("correction"),"¡Hola!");XCTAssertEqual(saved.text("tip"),"Saluda primero.");XCTAssertEqual(saved.text("expectedAnswer"),"hola")
    }
}


extension MemoryFlowTests {
    func testActualSourceSharedEnrichmentAndLearningEvidenceInEnglishAndArabic()async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1" else{throw XCTSkip("Read-only source preview required")}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for (support,theme) in [("en","light"),("ar","dark")] {
            let now=Date(timeIntervalSince1970:floor(Date().timeIntervalSince1970)),concept=support == "ar" ? "تحية":"A greeting",response:JSONValue = .object(["did":.string(support == "ar" ? "كانت التحية ناقصة.":"The greeting was missing."),"fix":.string("Hola"),"tip":.string(support == "ar" ? "ابدأ بالتحية.":"Start with a greeting.")]);var requests=0
            let app=try model(memoryProvider:{_ in requests += 1;return response.json});defer{try? app.identity.disconnect()};app.learner=LearnerState();app.learner.onboardingComplete=true;app.learner.support=support
            for (i,answer) in ["ola","another public attempt"].enumerated(){app.learner.captureMemory(mode:"grammar",concept:concept,answer:answer,expected:i == 0 ? "Hola":"Buen día",feedback:"Private grader reason",now:now.addingTimeInterval(Double(i)));let note=try XCTUnwrap(app.learner.companionMemory?["es"]?.first);await app.memoryEnrichment.wait(note,app:app)}
            let note=try XCTUnwrap(app.learner.companionMemory?["es"]?.first),changes=(app.learner.pendingMemoryChanges ?? []).filter{$0.action == .capture};XCTAssertEqual(changes.count,2);XCTAssertEqual(requests,1);XCTAssertEqual(note.fields["enriched"],.bool(true));XCTAssertEqual(app.learner.pendingRepairEvidence?.count,2);XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.gradedByLanguage)
            let sequence:JSONValue = .array(changes.enumerated().map{i,c in .object(["npub":.string("piyali-public-fixture"),"targetLang":.string("es"),"supportLang":.string(support),"sourceMode":.string("grammar"),"sourceContext":.string(""),"cefrLevel":.string("Pre-A1"),"concept":.string(concept),"userAnswer":.string(i == 0 ? "ola":"another public attempt"),"expectedAnswer":.string(i == 0 ? "Hola":"Buen día"),"enrichmentResponse":.string(response.json),"now":.string(WebProgressContract.iso(c.date))])})
            let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:WKWebViewConfiguration()),window=UIWindow(windowScene:scene),vc=UIViewController();window.frame=web.frame;vc.view=web;window.rootViewController=vc;web.scrollView.contentInsetAdjustmentBehavior = .never;window.makeKeyAndVisible();defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
            var url=URLComponents(string:"http://127.0.0.1:5181/__piyali-onboarding")!;url.queryItems=[.init(name:"screen",value:"memory"),.init(name:"captureSequence",value:sequence.json),.init(name:"language",value:support),.init(name:"theme",value:theme),.init(name:"goal",value:"0")];web.load(URLRequest(url:try XCTUnwrap(url.url)))
            var ready=false;for _ in 0..<400{ready=(try? await web.evaluateJavaScript("window.__sourceMemorySequence?.notes?.[0]?.severity===2&&!!document.querySelector('[role=dialog]')&&document.fonts.status==='loaded'")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};let sourceError=(try? await web.evaluateJavaScript("window.__sourceMemorySequenceError||''")) as? String ?? "";XCTAssertTrue(ready,sourceError);guard ready else{return}
            let raw=try await web.evaluateJavaScript("JSON.stringify(window.__sourceMemorySequence)"),trace=try JSONDecoder().decode(JSONValue.self,from:Data(try XCTUnwrap(raw as? String).utf8)),source=try XCTUnwrap(trace["notes"].array.first)
            XCTAssertEqual(trace["evidenceErrors"].array.count,0,trace["evidenceErrors"].json);XCTAssertEqual(trace["enrichmentRequests"].number,1);XCTAssertEqual(trace["grades"].number,0)
            for field in ["concept","userAnswer","expectedAnswer","correction","companionSummary","sourceMode","sourceContext","supportLang","targetLang","cefrLevel","severity","status","mistake","tip","enriched"]{XCTAssertEqual(source[field],note.fields[field],field)}
            let sourceSummary=trace["learning"]["repairSummary"],nativeSummary=app.learner.goalBucket["repairSummary"];XCTAssertEqual(sourceSummary["eventIds"].array.count,2);XCTAssertEqual(nativeSummary["eventIds"].array.count,2);XCTAssertEqual(sourceSummary["openPatterns"],nativeSummary["openPatterns"]);XCTAssertEqual(sourceSummary["guidance"],nativeSummary["guidance"]);XCTAssertEqual(app.learner.companionQuestUser["learningIntelligence"]["es"]["repairSummary"],nativeSummary)
            try await Task.sleep(for:.milliseconds(950));let sourceShot=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));sourceShot.name="Source shared enriched Memory \(support)";sourceShot.lifetime = .keepAlways;add(sourceShot)
            let host=UIHostingController(rootView:ZStack{PiyaliBrand(dark:theme == "dark").background;MemoryDrawerView(onClose:{})}.environmentObject(app).environment(\.layoutDirection,support == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(500));let nativeShot=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});nativeShot.name="Native shared enriched Memory \(support)";nativeShot.lifetime = .keepAlways;add(nativeShot)
            let a=XCTAttachment(data:Data(JSONValue.object(["source":trace,"native":.object(note.fields),"nativeRepairSummary":nativeSummary,"nativeEnrichmentRequests":.number(Double(requests))]).json.utf8),uniformTypeIdentifier:"public.json");a.name="Shared enriched Memory trace \(support)";a.lifetime = .keepAlways;add(a)
        }
    }
}


@MainActor private final class MemoryRecoveryNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
extension MemoryFlowTests {
    func testInterruptedEnrichmentRestoresFromPrivateAccountFileWithOriginalContextAndRejectsOldSessionResult()async throws {
        var held:CheckedContinuation<String,Error>?,initialRequests=0
        let app=try model(memoryProvider:{_ in initialRequests += 1;return try await withCheckedThrowingContinuation{held=$0}},progressService:MemoryRecoveryNoCloud());app.learner=LearnerState();app.learner.onboardingComplete=true
        let concept=String(repeating:"x",count:241);app.learner.captureMemory(mode:"grammar",concept:concept,answer:"first attempt",expected:"hola",feedback:"Private grade reason")
        for _ in 0..<200 where held == nil{await Task.yield()};XCTAssertNotNil(held);let note=try XCTUnwrap(app.learner.companionMemory?["es"]?.first),intent=try XCTUnwrap(app.learner.pendingMemoryEnrichments?.first)
        app.learner.reinforceMemory(id:note.id);app.learner.target="fr";app.persist();let key=app.identity.exportKey();app.signOut()
        var recoveredRequests=0,prompt="";let recovered=AppModel(progressService:MemoryRecoveryNoCloud(),memoryProvider:{text in recoveredRequests += 1;prompt=text;return "{\"did\":\"The h was missing.\",\"fix\":\"hola\",\"tip\":\"Start with hola.\"}"});defer{recovered.signOut()}
        await recovered.signIn(nsec:key);recovered.resumeMemoryEnrichments();recovered.resumeMemoryEnrichments();await recovered.memoryEnrichment.wait(note,app:recovered)
        let result=try XCTUnwrap(recovered.learner.companionMemory?["es"]?.first);XCTAssertEqual(initialRequests,1);XCTAssertEqual(recoveredRequests,1);XCTAssertTrue(prompt.contains(concept));XCTAssertEqual(intent.concept,concept);XCTAssertEqual(result.id,note.id);XCTAssertEqual(result.text("tip"),"Start with hola.");XCTAssertEqual(result.text("status"),"reinforced");XCTAssertEqual(recovered.learner.target,"fr");XCTAssertTrue(recovered.learner.pendingMemoryEnrichments?.isEmpty == true);XCTAssertEqual(recovered.learner.pendingMemoryChanges?.filter{$0.action == .localize}.count,1);XCTAssertEqual(recovered.learner.pendingRepairEvidence?.count,1);XCTAssertEqual(recovered.learner.totalXP,0);XCTAssertNil(recovered.learner.gradedByLanguage)
        held?.resume(returning:"{\"did\":\"Stale\",\"fix\":\"Wrong\",\"tip\":\"Stale\"}");held=nil;for _ in 0..<200{await Task.yield()};XCTAssertEqual(recovered.learner.companionMemory?["es"]?.first?.text("tip"),"Start with hola.");recovered.resumeMemoryEnrichments();XCTAssertEqual(recoveredRequests,1)
    }
    func testRestoreDoesNotRetryUntrackedPendingFailuresOrExpiredAndReplacedNotes()async throws {
        var calls=0;let app=try model(memoryProvider:{_ in calls += 1;return ""},progressService:MemoryRecoveryNoCloud());defer{app.signOut()};app.learner=LearnerState();app.learner.onboardingComplete=true
        let note=MemoryContract.capture(target:"es",support:"en",level:"A1",mode:"grammar",concept:"A greeting",answer:"ola",expected:"hola",feedback:"")
        app.learner.companionMemory=["es":[note]];app.resumeMemoryEnrichments();await app.reloadContent();XCTAssertEqual(calls,0);XCTAssertEqual(app.learner.companionMemory?["es"]?.first?.fields["enriched"],.bool(false));XCTAssertNil(app.learner.pendingMemoryEnrichments)
        for kind in ["expired","replaced","enriched"] {
            app.learner.companionMemory=["es":[note]];_=app.learner.queueMemoryEnrichment(account:app.identity.npub,note:note,concept:"A greeting")
            if kind == "expired"{app.learner.companionMemory?["es"]?[0].fields["expiresAfterDayKey"] = .string("2000-01-01")}
            else if kind == "replaced"{app.learner.companionMemory?["es"]?[0].fields["createdAt"] = .number(note.createdAt.timeIntervalSince1970*1000+1000)}
            else{app.learner.companionMemory?["es"]?[0].fields["enriched"] = .bool(true)}
            app.resumeMemoryEnrichments();XCTAssertTrue(app.learner.pendingMemoryEnrichments?.isEmpty == true,kind);XCTAssertEqual(calls,0,kind)
        }
    }
    func testNewerSlipReplacesPendingVersionWhileRepeatedResumeCoalescesAndRejectsOldReply()async throws {
        var calls=0,firstHeld:CheckedContinuation<String,Error>?,secondHeld:CheckedContinuation<String,Error>?
        let app=try model(memoryProvider:{_ in calls += 1;return try await withCheckedThrowingContinuation{if calls == 1{firstHeld=$0}else{secondHeld=$0}}},progressService:MemoryRecoveryNoCloud());defer{app.signOut()};app.learner=LearnerState();app.learner.onboardingComplete=true
        let now=Date();app.learner.captureMemory(mode:"grammar",concept:"A greeting",answer:"first attempt",expected:"hola",feedback:"",now:now);for _ in 0..<200 where firstHeld == nil{await Task.yield()};let first=try XCTUnwrap(app.learner.pendingMemoryEnrichments?.first)
        app.resumeMemoryEnrichments();app.resumeMemoryEnrichments();XCTAssertEqual(calls,1)
        app.learner.captureMemory(mode:"grammar",concept:"A greeting",answer:"second attempt",expected:"new fix",feedback:"",now:now.addingTimeInterval(1));for _ in 0..<200 where secondHeld == nil{await Task.yield()};let latest=try XCTUnwrap(app.learner.pendingMemoryEnrichments?.first);app.resumeMemoryEnrichments();XCTAssertEqual(app.learner.pendingMemoryEnrichments?.count,1);XCTAssertNotEqual(latest.id,first.id);XCTAssertEqual(latest.note.text("userAnswer"),"second attempt");XCTAssertEqual(calls,2)
        firstHeld?.resume(returning:"{\"did\":\"Stale\",\"fix\":\"Wrong\",\"tip\":\"Stale\"}");firstHeld=nil;await app.memoryEnrichment.wait(first.note,app:app);XCTAssertEqual(app.learner.companionMemory?["es"]?.first?.text("tip"),"");XCTAssertEqual(app.learner.pendingMemoryEnrichments?.first?.id,latest.id)
        secondHeld?.resume(returning:"{\"did\":\"The h was missing.\",\"fix\":\"hola\",\"tip\":\"Start with hola.\"}");secondHeld=nil;await app.memoryEnrichment.wait(latest.note,app:app)
        XCTAssertTrue(app.learner.pendingMemoryEnrichments?.isEmpty == true);XCTAssertEqual(app.learner.companionMemory?["es"]?.first?.severity,2);XCTAssertEqual(app.learner.companionMemory?["es"]?.first?.text("userAnswer"),"second attempt");XCTAssertEqual(app.learner.pendingMemoryChanges?.filter{$0.action == .localize}.count,1);XCTAssertEqual(app.learner.pendingRepairEvidence?.count,2);XCTAssertEqual(app.learner.totalXP,0)
    }
}
