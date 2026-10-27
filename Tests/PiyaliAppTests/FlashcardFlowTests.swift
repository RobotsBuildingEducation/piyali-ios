import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor private final class FlashcardOfflineStore:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class FlashcardFlowTests:XCTestCase {
    private var card:JSONValue {.object(["id":.string("pre-a1-people-1"),"concept":.object(["en":.string("mom"),"es":.string("mamá"),"ar":.string("ماما"),"fr":.string("maman")]),"cefrLevel":.string("Pre-A1"),"category":.string("people"),"type":.string("word")])}
    private func model()throws->AppModel {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated offline identity required")}
        let app=AppModel(progressService:FlashcardOfflineStore());try app.identity.create();app.subscription.bind(app.identity);app.signedIn=true;app.learner=LearnerState();app.learner.onboardingComplete=true;return app
    }
    private func provider(_ response:String)->FlashcardProvider {.init(judge:{_ in response},stream:{_,update in update("ma");await Task.yield();update("mamá");return "mamá"},quote:{card,state in try GeneratedQuestionWorth.fallback(level:card["cefrLevel"].string,learner:state,recipes:PracticeRecipes())})}
    private func settle(_ session:FlashcardSessionController)async {for _ in 0..<100 where session.grading || session.revealing || session.saving || session.creatingNote {try? await Task.sleep(for:.milliseconds(20))}}
    func testRevealWrongRetryGradeAndChosenScheduleFollowSourceWithoutPrematureReview()async throws {
        let app=try model();defer{try? app.identity.disconnect()};var raw="NO",prompts:[String]=[]
        var service=provider("");service.judge={prompt in prompts.append(prompt);return raw}
        let session=try FlashcardSessionController(app:app,card:card,status:"active",provider:service);app.flashcardSession=session
        session.flip(app);await settle(session);XCTAssertEqual(session.revealed,"mamá");XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.cardReviews)
        session.flip(app);session.answer="WRONG_FIXTURE";session.submit(app);await settle(session)
        XCTAssertFalse(try XCTUnwrap(session.grade).correct);XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.cardReviews);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1);XCTAssertEqual(app.learner.activeMemories.count,1)
        session.retry();session.answer="mamá";raw="YES | 6";session.submit(app);await settle(session)
        XCTAssertTrue(try XCTUnwrap(session.grade).correct);XCTAssertEqual(session.grade?.xp,6);XCTAssertEqual(app.learner.gradedByLanguage?["es"],2)
        session.commit(.hard,app:app);await settle(session);XCTAssertNil(app.flashcardSession);XCTAssertEqual(app.learner.totalXP,6);XCTAssertEqual(app.learner.cardReviews?["es:pre-a1-people-1"]?.lastReviewOutcome,.hard)
        XCTAssertTrue(prompts.allSatisfy{$0.contains("Allow natural variations and synonyms")})
    }
    func testWrongAgainUsesTheActiveWebSaveFallbackAndNeverDuplicatesAssessmentOrReward()async throws {
        let app=try model();defer{try? app.identity.disconnect()};let session=try FlashcardSessionController(app:app,card:card,status:"active",provider:provider("NO"));app.flashcardSession=session
        session.answer="wrong";session.submit(app);await settle(session);session.retry();session.answer="wrong again";session.submit(app);await settle(session)
        XCTAssertEqual(app.learner.gradedByLanguage?["es"],1);XCTAssertEqual(app.learner.activeMemories.count,1)
        session.commit(.again,app:app);await settle(session);session.commit(.again,app:app);await settle(session)
        XCTAssertEqual(app.learner.totalXP,5,"The active App.jsx handler uses card.xpReward || 5 even when the modal submits zero.");XCTAssertEqual(app.learner.cardReviews?["es:pre-a1-people-1"]?.reviewCount,1)
    }
    func testClosingUnansweredCardHasNoStruggleButAbandoningTypedWorkCapturesOnce()throws {
        let app=try model();defer{try? app.identity.disconnect()}
        let empty=try FlashcardSessionController(app:app,card:card,status:"active",provider:provider("NO"));app.flashcardSession=empty;empty.close(app);XCTAssertTrue(app.learner.activeMemories.isEmpty)
        let typed=try FlashcardSessionController(app:app,card:card,status:"active",provider:provider("NO"));app.flashcardSession=typed;typed.answer="trying";typed.close(app);typed.close(app)
        XCTAssertEqual(app.learner.activeMemories.count,1);XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.cardReviews);XCTAssertNil(app.learner.gradedByLanguage)
    }
    func testFailedRepairSaveKeepsTheModalAndDefersStepCompletionWithoutDuplicateXP()async throws {
        let app=try model();defer{try? app.identity.disconnect()};let day=CalendarDay.key(Date()),item:JSONValue = .object(["memoryId":.string("public-memory"),"concept":.string("Say a greeting"),"expectedAnswer":.string("mamá"),"mode":.string("flashcards"),"cefrLevel":.string("Pre-A1")]),plan:JSONValue = .object(["targetLang":.string("es"),"dayKey":.string(day),"target":.number(1),"items":.array([item]),"memoryIds":.array([.string("public-memory")])])
        app.learner.storeCompanionBlueprint(.object(["status":.string("ready"),"repair":plan]),target:"es",day:day)
        let policy=try CompanionQuestPolicy(),next=try policy.run("next",.object(["plan":plan,"completedCount":.number(0)])),step=try JSONDecoder().decode(RepairStep.self,from:Data(next.json.utf8)),focused=card.setting("id",.string("public-repair-card")).setting("isRepair",.bool(true))
        app.learner.storeRepairArtifact(.object(["version":.number(1),"ownerKey":.string(CompanionQuestDay.artifactKey(step,mode:"flashcards")),"cards":.array([focused]),"outcomes":.object([:])]),step:step,mode:"flashcards")
        let session=try FlashcardSessionController(app:app,card:focused,status:"active",repair:step,provider:provider("YES | 6"));app.flashcardSession=session;session.answer="mamá";session.submit(app);await settle(session);session.commit(.good,app:app);await settle(session)
        XCTAssertNotNil(session.error);XCTAssertEqual(app.flashcardSession?.id,session.id);XCTAssertEqual(app.learner.totalXP,2);XCTAssertEqual(app.learner.plateProgress["repairDailyActivity"]["es"][day].number,0);XCTAssertNil(app.learner.cardReviews);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1)
        session.commit(.good,app:app);await settle(session);XCTAssertEqual(app.learner.totalXP,2);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1);XCTAssertFalse(session.canRate(.again));session.close(app,abandoned:false)
    }
    func testLateOldLanguageGradeAndStreamCannotWriteTheNewScope()async throws {
        let app=try model();defer{try? app.identity.disconnect()};var held:CheckedContinuation<String,Error>?
        var service=provider("");service.judge={_ in try await withCheckedThrowingContinuation{held=$0}}
        let session=try FlashcardSessionController(app:app,card:card,status:"active",provider:service);app.flashcardSession=session;session.answer="mamá";session.submit(app)
        for _ in 0..<30 where held == nil {await Task.yield()};XCTAssertNotNil(held);app.learner.support="ar";held?.resume(returning:"YES | 7");await settle(session)
        XCTAssertNil(session.grade);XCTAssertNil(app.learner.gradedByLanguage);XCTAssertEqual(app.learner.totalXP,0)
    }
    func testOriginalDeckAndNativeLevelHeaderQueuesAndLocksInEnglishAndArabic()async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1" else{throw XCTSkip("Read-only source preview required")}
        let app=try model();defer{try? app.identity.disconnect()};let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow}
        for (language,theme) in [("en","light"),("ar","dark")] {
            app.learner=LearnerState();app.learner.support=language;app.learner.xpByLanguage=["es":10];app.prepareDailyPlate();await app.reloadContent()
            let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:config),window=UIWindow(windowScene:scene),controller=UIViewController();window.frame=web.frame;controller.view=web;web.scrollView.contentInsetAdjustmentBehavior = .never;window.rootViewController=controller;window.makeKeyAndVisible()
            defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-onboarding?screen=flashcards&tool=deck&language=\(language)&theme=\(theme)"))))
            var ready=false;for _ in 0..<500 {ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && document.body.textContent.includes('10 XP') && [...document.querySelectorAll('p')].some(p=>p.textContent==='\(language == "ar" ? "ماما":"mom")')")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(ready);guard ready else{return};try await Task.sleep(for:.milliseconds(650))
            let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source flashcard deck \(language)";source.lifetime = .keepAlways;add(source)
            let raw=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('p,button')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {text:e.textContent,x:r.x,y:r.y,width:r.width,height:r.height,font:s.font,lineHeight:s.lineHeight,color:s.color}}))")
            let geometry=XCTAttachment(data:Data(try XCTUnwrap(raw as? String).utf8),uniformTypeIdentifier:"public.json");geometry.name="Source flashcard deck \(language) geometry";geometry.lifetime = .keepAlways;add(geometry)
            let host=UIHostingController(rootView:FlashcardsView().environmentObject(app).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).ignoresSafeArea().preferredColorScheme(theme == "dark" ? .dark:.light));window.rootViewController=host;host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(700))
            let shot=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});shot.name="Native flashcard deck \(language)";shot.lifetime = .keepAlways;add(shot)
            XCTAssertEqual(app.cards.first?.id,"pre-a1-people-1");web.stopLoading();window.isHidden=true;window.rootViewController=nil
        }
        old?.makeKey()
    }
    func testOriginalPracticeModalAndNativeInitialCorrectWrongInEnglishAndArabic()async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1" else{throw XCTSkip("Read-only source preview required")}
        let app=try model();defer{try? app.identity.disconnect()};let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow}
        for (language,theme) in [("en","light"),("ar","dark")] {
            let configuration=WKWebViewConfiguration();configuration.websiteDataStore = .nonPersistent();let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:configuration),window=UIWindow(windowScene:scene),controller=UIViewController();window.frame=web.frame;controller.view=web;web.scrollView.contentInsetAdjustmentBehavior = .never;window.rootViewController=controller;window.makeKeyAndVisible()
            defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-onboarding?screen=flashcards&language=\(language)&theme=\(theme)"))))
            var ready=false;for _ in 0..<500 {ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && Boolean(document.querySelector('.chakra-modal__content input'))")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(ready);guard ready else{return};try await Task.sleep(for:.milliseconds(300))
            for state in ["initial","wrong","correct"] {
                if state != "initial" {
                    if state == "correct" {_=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(b=>b.textContent.includes(\(String(data:try JSONEncoder().encode(EntryCopy.ui(language,"flashcard_try_again")),encoding:.utf8)!))).click()")}
                    let answer=state == "wrong" ? "WRONG_FIXTURE":"mamá",value=String(data:try JSONEncoder().encode(answer),encoding:.utf8)!
                    _=try await web.evaluateJavaScript("(()=>{const input=document.querySelector('.chakra-modal__content input');input.focus();Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set.call(input,\(value));input.dispatchEvent(new Event('input',{bubbles:true}));input.blur();})()")
                    try await Task.sleep(for:.milliseconds(100));let label=String(data:try JSONEncoder().encode(EntryCopy.ui(language,"flashcard_submit")),encoding:.utf8)!
                    _=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(b=>b.textContent.includes(\(label))).click()");var resultReady=false
                    for _ in 0..<150 {let expected=String(data:try JSONEncoder().encode(EntryCopy.ui(language,state == "wrong" ? "flashcard_try_again":"flashcard_correct")),encoding:.utf8)!;resultReady=(try? await web.evaluateJavaScript("document.body.textContent.includes(\(expected))")) as? Bool == true;if resultReady{break};try await Task.sleep(for:.milliseconds(50))}
                    if !resultReady {let debug=try await web.evaluateJavaScript("JSON.stringify({text:document.body.textContent.slice(-1800),input:document.querySelector('.chakra-modal__content input')?.value,buttons:[...document.querySelectorAll('button')].map(b=>[b.textContent,b.disabled])})");print("SOURCE FLASHCARD STATE: \(String(describing:debug))")};XCTAssertTrue(resultReady);guard resultReady else{return};try await Task.sleep(for:.milliseconds(350))
                }
                let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source flashcard \(state) \(language)";source.lifetime = .keepAlways;add(source)
                let raw=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('.chakra-modal__content,.chakra-modal__body,input,p,button')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {tag:e.tagName,text:e.textContent,label:e.getAttribute('aria-label'),x:r.x,y:r.y,width:r.width,height:r.height,color:s.color,bg:s.backgroundColor,font:s.font,lineHeight:s.lineHeight}}))")
                let geometry=XCTAttachment(data:Data(try XCTUnwrap(raw as? String).utf8),uniformTypeIdentifier:"public.json");geometry.name="Source flashcard \(state) \(language) geometry";geometry.lifetime = .keepAlways;add(geometry)
                app.learner.support=language;app.learner.xpByLanguage=["es":10];app.prepareDailyPlate();let session=try FlashcardSessionController(app:app,card:card,status:"active",provider:provider(state == "wrong" ? "NO":"YES | 6"));app.flashcardSession=session
                if state != "initial" {session.answer=state == "wrong" ? "WRONG_FIXTURE":"mamá";session.submit(app);await settle(session)}
                let host=UIHostingController(rootView:FlashcardPracticeDialog(session:session).environmentObject(app).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).ignoresSafeArea().preferredColorScheme(theme == "dark" ? .dark:.light));window.rootViewController=host;host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(250))
                let image=UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)},shot=XCTAttachment(image:image);shot.name="Native flashcard \(state) \(language)";shot.lifetime = .keepAlways;add(shot);session.close(app,abandoned:false)
                window.rootViewController=controller;window.makeKeyAndVisible()
            }
            web.stopLoading();window.isHidden=true;window.rootViewController=nil
        }
        old?.makeKey()
    }
}
