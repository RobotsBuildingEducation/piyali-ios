import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor final class MemoryFlowTests:XCTestCase {
    private func model()throws->AppModel {
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,MemoryDrawerFixture.enabled else{throw XCTSkip("Isolated Memory fixture required")}
        let app=AppModel();try app.identity.create();app.signedIn=true;app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.onboardingComplete=true;MemoryDrawerFixture.seed(app);return app
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
        let app=try model();defer{try? app.identity.disconnect()};var resume:CheckedContinuation<String,Error>?,calls=0
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
        for _ in 0..<200 where app.learner.companionMemory?["es"]?.first(where:{$0.id == id})?.text("iosMemoryEnrichedSupport") != "en"{try await Task.sleep(for:.milliseconds(10))}
        XCTAssertEqual(app.learner.companionMemory?["es"]?.first(where:{$0.id == id})?.text("iosMemoryEnrichedSupport"),"en");XCTAssertGreaterThanOrEqual(calls,2)
    }
    func testExerciseNoteKeepsSourceGeneratedContentAndPrivateStudyMetadata()async throws {
        let app=try model();defer{try? app.identity.disconnect()}
        let q=try PracticeQuestion(module:.vocabulary,kind:"mc",payload:.object(["question":.string("Choose a greeting"),"choices":.array([.string("hola"),.string("adiós")]),"answer":.string("hola")]),options:.object(["cefrLevel":.string("A1")]),target:"es",support:"en")
        var run=PracticeRun(question:q,lessonID:nil,lessonLevel:"A1",response:.object(["indices":.array([.number(0)])]));run.correct=true;app.learner.savePractice(run)
        let original=app.learner.notes.count,created=try await app.createStudyNote(run:run,lesson:nil)
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
