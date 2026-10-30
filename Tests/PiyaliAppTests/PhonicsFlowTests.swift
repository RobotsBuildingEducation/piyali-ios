import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor private final class PhonicsNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class PhonicsFlowTests:XCTestCase {
    private func model()async throws->AppModel {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated offline identity required")}
        let app=AppModel(progressService:PhonicsNoCloud());try app.identity.create();app.subscription.bind(app.identity);app.signedIn=true;app.learner=LearnerState();app.learner.onboardingComplete=true;await app.reloadContent();return app
    }
    private func card(_ app:AppModel)throws->JSONValue {try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(XCTUnwrap(app.phonics.first)))}
    private func provider(_ raw:String)->PhonicsProvider {.init(judge:{_ in raw},quote:{card,state in try GeneratedQuestionWorth.fallback(level:card["cefrLevel"].string,learner:state,recipes:PracticeRecipes())})}
    private func settle(_ session:PhonicsSessionController)async {for _ in 0..<250 where session.busy{try? await Task.sleep(for:.milliseconds(20))};XCTAssertFalse(session.busy)}
    func testWrongRetryRepeatAndCollectionUseIndependentSourceBoundaries()async throws {
        let app=try await model();defer{try? app.identity.disconnect()};var raw="NO";var service=provider("");service.judge={_ in raw};let card=try card(app),session=try PhonicsSessionController(app:app,card:card,provider:service);defer{session.cancel()}
        session.practice(app);session.submit("WRONG_FIXTURE",app:app);await settle(session)
        XCTAssertEqual(session.grade?.correct,false);XCTAssertEqual(app.learner.totalXP,0);XCTAssertEqual(app.learner.phonicsDocuments.first?["attempts"].number,1);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1);XCTAssertEqual(app.learner.activeMemories.first?.fields["sourceContext"]?["card"]["id"],card["id"])
        raw="YES | 2";session.retry();session.submit(card["practiceWord"].string,app:app);await settle(session)
        XCTAssertEqual(app.learner.totalXP,2);XCTAssertEqual(session.correctCount,1);XCTAssertEqual(app.learner.phonicsDocuments.first?["attempts"].number,2);XCTAssertEqual(app.learner.phonicsDocuments.first?["correctCount"].number,1);XCTAssertEqual(app.learner.plateProgress["phonicsDailyActivity"],.null)
        session.back();session.practice(app);session.submit(card["practiceWord"].string,app:app);await settle(session);XCTAssertEqual(app.learner.totalXP,4);XCTAssertEqual(app.learner.gradedByLanguage?["es"],3)
        app.learner.collectPhonics(cardID:card["id"].string);XCTAssertEqual(app.learner.totalXP,4);XCTAssertEqual(app.learner.plateProgress["phonicsDailyActivity"]["es"][CalendarDay.key(Date())].number,1)
    }
    func testLatePronunciationCannotAffectAnotherSupportLanguage()async throws {
        let app=try await model();defer{try? app.identity.disconnect()};var held:CheckedContinuation<String,Error>?;var service=provider("");service.judge={_ in try await withCheckedThrowingContinuation{held=$0}};let session=try PhonicsSessionController(app:app,card:card(app),provider:service);defer{session.cancel()};session.practice(app);session.submit("casa",app:app)
        for _ in 0..<40 where held == nil{await Task.yield()};XCTAssertNotNil(held);app.learner.support="ar";held?.resume(returning:"YES | 2");await settle(session);XCTAssertNil(session.grade);XCTAssertTrue(app.learner.phonicsDocuments.isEmpty);XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.gradedByLanguage)
    }
    func testFocusedPhonicsFailureRetainsTwoXPAndDoesNotRepeatAssessmentOnSaveRetry()async throws {
        let app=try await model();defer{try? app.identity.disconnect()};app.learner.editGoal("Say casa");let card=try card(app).setting("authoredId",try card(app)["id"]).setting("id",.string("public-focused-a")).setting("isGoal",.bool(true)),day=CalendarDay.key(Date()),bp:JSONValue = .object(["goalId":app.learner.goalBucket["activeGoal"]["id"],"dayKey":.string(day),"lang":.string("es"),"mode":.string("phonics"),"modes":.array([.string("phonics"),.string("lesson")]),"cefrLevel":.string("Pre-A1")])
        app.learner.applyGoal(.init(action:.blueprint,target:"es",payload:bp));app.learner.applyGoal(.init(action:.artifact,target:"es",payload:bp.setting("cards",.array([card,card.setting("id",.string("public-focused-b"))]))))
        app.learner.pendingGoalChanges=[];XCTAssertNotNil(app.readyGoal);let session=try PhonicsSessionController(app:app,card:card,goal:bp,provider:provider("YES | 2"));defer{session.cancel()};session.practice(app);session.submit("casa",app:app);await settle(session)
        XCTAssertEqual(app.learner.totalXP,2);XCTAssertTrue(session.needsSaveRetry);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1);XCTAssertTrue(app.learner.phonicsDocuments.isEmpty);XCTAssertEqual(app.learner.plateProgress["phonicsDailyActivity"],.null)
        session.retrySave(app);await settle(session);XCTAssertEqual(app.learner.totalXP,2);XCTAssertEqual(app.learner.gradedByLanguage?["es"],1);XCTAssertEqual(app.readyGoal?["modeProgress"]["phonics"].number,0)
    }
    func testSourceAndNativePhonicsFrontPracticeWrongAndCorrect()async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1" else{throw XCTSkip("Read-only source preview required")}
        let app=try await model();defer{try? app.identity.disconnect()};let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow}
        for (language,theme) in [("en","light"),("ar","dark")] {
            let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:config),sourceWindow=UIWindow(windowScene:scene),sourceHost=UIViewController();sourceWindow.frame=web.frame;sourceHost.view=web;web.scrollView.contentInsetAdjustmentBehavior = .never;sourceWindow.rootViewController=sourceHost;sourceWindow.makeKeyAndVisible();defer{web.stopLoading();sourceWindow.isHidden=true;sourceWindow.rootViewController=nil;old?.makeKey()}
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-onboarding?screen=phonics&language=\(language)&theme=\(theme)"))))
            var ready=false;for _ in 0..<500{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && !!document.querySelector('[data-phonics-active-card]')")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};if !ready{let debug=try? await web.evaluateJavaScript("document.body.innerText.slice(0,2500)");print("PHONICS SOURCE PREVIEW: \(String(describing:debug))")};XCTAssertTrue(ready);guard ready else{return};try await Task.sleep(for:.milliseconds(700))
            let policy=try PhonicsPolicy(engine:app.companionQuestPolicy)
            func click(_ key:String)async throws{let label=String(decoding:try JSONEncoder().encode(policy.copy(key,language:language,target:"es")),as:UTF8.self);let found=try await web.evaluateJavaScript("(()=>{const b=[...document.querySelectorAll('[data-activity-action-row] button')].find(b=>b.textContent.trim()===\(label));if(!b)return false;b.click();return true})()");XCTAssertEqual(found as? Bool,true)}
            for state in ["front","practice","wrong","correct"] {
                if state == "practice"{try await click("practice")}
                if state == "wrong"{try await click("record")}
                if state == "correct"{try await click("tryAgain");try await click("record")}
                try await Task.sleep(for:.milliseconds(state == "front" || state == "practice" ? 700:1500))
                let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source phonics \(state) \(language)";source.lifetime = .keepAlways;add(source)
                let raw=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('p,button,[data-phonics-active-card]')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {text:e.textContent,x:r.x,y:r.y,width:r.width,height:r.height,fontSize:s.fontSize,lineHeight:s.lineHeight}}))");let geometry=XCTAttachment(data:Data(try XCTUnwrap(raw as? String).utf8),uniformTypeIdentifier:"public.json");geometry.name="Source phonics \(state) \(language) geometry";geometry.lifetime = .keepAlways;add(geometry)
                app.learner=LearnerState();app.learner.onboardingComplete=true;app.learner.support=language;await app.reloadContent();let course=PhonicsCourseController(),window=UIWindow(windowScene:scene);window.frame=web.frame
                let host=UIHostingController(rootView:PhonicsSnapshotHost(course:course).environmentObject(app).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());window.rootViewController=host;window.makeKeyAndVisible();defer{window.isHidden=true;window.rootViewController=nil}
                for _ in 0..<200 where course.currentSession == nil{try await Task.sleep(for:.milliseconds(20))};let session=try XCTUnwrap(course.currentSession)
                if state != "front"{session.practice(app)}
                if state == "wrong" || state == "correct"{session.submit(state == "wrong" ? "WRONG_FIXTURE":session.card["practiceWord"].string,app:app);await settle(session)}
                host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(700));let shot=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});shot.name="Native phonics \(state) \(language)";shot.lifetime = .keepAlways;add(shot)
                session.cancel();window.isHidden=true;window.rootViewController=nil;sourceWindow.makeKeyAndVisible()
            }
            web.stopLoading();sourceWindow.isHidden=true;sourceWindow.rootViewController=nil
        }
        old?.makeKey()
    }
}
private struct PhonicsSnapshotHost:View {
    @EnvironmentObject var app:AppModel
    let course:PhonicsCourseController
    var body:some View {PhonicsView(controller:course).ignoresSafeArea().overlay(alignment:.bottom){if let footer=app.activityFooter{footer.content.padding(12).background{SourceActivityDockBackground(correct:footer.correct)}.padding(.horizontal,8).padding(.bottom,12)}}}
}
