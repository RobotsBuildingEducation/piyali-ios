import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor private final class PlateClock {var now=Date()}
@MainActor final class GuidedPracticeControllerTests:XCTestCase {
    private func model()throws->AppModel {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated identity required")}
        let app=AppModel();try app.identity.create();app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.onboardingComplete=true;app.signedIn=true;app.learner.preparePlate(user:app.identity.npub,available:DailyPlate.introductory);return app
    }
    private func tick(_ controller:PlatePracticeController,_ app:AppModel,_ clock:PlateClock,_ seconds:Double){clock.now += seconds;controller.presentationBlocked(false,app:app)}
    func testGuidedPracticeWaitsForTutorAndDailyGoalThenRoutesOnlyAfterAcknowledgment()throws {
        let app=try model();defer{try? app.identity.disconnect()};let clock=PlateClock(),controller=PlatePracticeController(clock:{clock.now}),tutor=UUID();var routes:[String]=[],sounds:[String]=[]
        controller.onNavigate={routes.append($0)};controller.onSound={sounds.append($0)};controller.start(app);defer{controller.unbind()};tick(controller,app,clock,2.1)
        app.retainEarnedPractice(owner:tutor,active:true,account:app.identity.npub,target:app.learner.target,day:CalendarDay.key(Date()))
        app.learner.award(100,source:.speak,contentID:"lesson-tutorial-1")
        XCTAssertNotNil(app.dailyGoalReward);XCTAssertNil(controller.dailyGoalVisible);XCTAssertNotNil(controller.pending);XCTAssertEqual(routes,["speak"])
        tick(controller,app,clock,0.5);XCTAssertNil(controller.visible)
        app.deferTutorReview(owner:tutor);XCTAssertNotNil(controller.dailyGoalVisible);XCTAssertNil(controller.visible)
        controller.closeDailyGoal(app);XCTAssertNil(controller.dailyGoalVisible);XCTAssertNil(app.dailyGoalReward);tick(controller,app,clock,1);XCTAssertNil(controller.visible,"Tutor review still owns its modal")
        app.releaseTutorReview(owner:tutor);app.releaseEarnedPractice(owner:tutor);tick(controller,app,clock,0.25);tick(controller,app,clock,0.25)
        XCTAssertEqual(controller.visible?["completed"].string,"speak");XCTAssertEqual(sounds,["questComplete"]);XCTAssertEqual(routes,["speak"])
        controller.continuePractice(app);XCTAssertEqual(routes,["speak","learn"]);XCTAssertNil(controller.visible);XCTAssertEqual(controller.guided?.current,"learn")
    }
    func testFinalReviewRetainsEarnedCelebrationAtTrialLimitAndNotesCloseReleasesIt()throws {
        let app=try model();defer{try? app.identity.disconnect()};app.learner.dailyGoal=1000
        app.learner.award(1,source:.speak);app.learner.award(1,source:.lesson)
        for _ in 0..<4{app.learner.award(1,source:.review)}
        app.learner.subscriptionXPAdjustment=268
        let clock=PlateClock(),controller=PlatePracticeController(clock:{clock.now});var routes:[String]=[],home=0,notes=0
        controller.onNavigate={routes.append($0)};controller.onHome={home += 1};controller.onNotes={notes += 1};controller.start(app);defer{controller.unbind()};tick(controller,app,clock,2.1)
        XCTAssertEqual(routes,["review"]);let review=UUID();app.retainEarnedPractice(owner:review,active:true,account:app.identity.npub,target:app.learner.target,day:CalendarDay.key(Date()))
        app.learner.award(1,source:.review);XCTAssertTrue(app.learner.claimPlate(user:app.identity.npub));XCTAssertEqual(app.learner.subscriptionXP,300);XCTAssertFalse(app.subscription.hasAccess);XCTAssertTrue(app.preservingEarnedPractice);XCTAssertNil(controller.visible);XCTAssertNil(controller.guided)
        app.releaseEarnedPractice(owner:review);tick(controller,app,clock,0.2);tick(controller,app,clock,0.25)
        XCTAssertEqual(controller.visible?["type"].string,"cleared");XCTAssertFalse(app.learner.claimPlate(user:app.identity.npub));XCTAssertEqual(home,0)
        controller.continuePractice(app,viewNotes:true);XCTAssertEqual(home,1);XCTAssertEqual(notes,1);XCTAssertTrue(controller.notesOpen);XCTAssertTrue(app.preservingEarnedPractice)
        controller.closeNotes(app);XCTAssertFalse(app.preservingEarnedPractice);tick(controller,app,clock,5);XCTAssertNil(controller.visible)
        let restored=PlatePracticeController(clock:{clock.now});restored.bind(app);defer{restored.unbind()};tick(restored,app,clock,5);XCTAssertNil(restored.guided);XCTAssertNil(restored.visible)
    }
    func testCloudHydrationCannotReplayDailyGoalAndLanguageChangeDropsQueuedCourse()throws {
        let app=try model();defer{try? app.identity.disconnect()};let clock=PlateClock(),controller=PlatePracticeController(clock:{clock.now});controller.start(app);defer{controller.unbind()};tick(controller,app,clock,2.1)
        var cloud=app.learner;cloud.pendingChanges=[];cloud.dailyXP=100;cloud.companionProgress = .object(["dailyHasCelebrated":.bool(true)]);app.learner=cloud;XCTAssertNil(app.dailyGoalReward)
        controller.presentationBlocked(true,app:app);app.learner.award(1,source:.speak);XCTAssertNotNil(controller.pending)
        app.learner.target="fr";XCTAssertNil(controller.pending);XCTAssertNil(controller.visible);XCTAssertNil(controller.guided);XCTAssertFalse(app.preservingEarnedPractice)
    }
    func testDailyGoalReachedDuringLessonAppearsWithoutWaitingForTheWholeLesson()throws {
        let app=try model();defer{try? app.identity.disconnect()};let controller=PlatePracticeController();controller.bind(app);defer{controller.unbind()};app.lessonActivityActive=true
        app.learner.award(100,source:.practice)
        XCTAssertNotNil(controller.dailyGoalVisible);XCTAssertTrue(app.lessonActivityActive);XCTAssertNil(app.pendingLessonCompletion);controller.closeDailyGoal(app);XCTAssertTrue(app.lessonActivityActive);XCTAssertNil(controller.visible)
    }
    func testPendingOfflineXPDoesNotReplayDailyRewardWhenRestoringLocalProfile()throws {
        let app=try model();defer{try? app.identity.disconnect()};app.learner.award(100,source:.practice);XCTAssertNotNil(app.dailyGoalReward);XCTAssertFalse(app.learner.pendingChanges?.isEmpty ?? true)
        app.dailyGoalReward=nil;app.persist()
        let restored=AppModel();XCTAssertTrue(restored.signedIn);XCTAssertGreaterThanOrEqual(restored.learner.dailyXP,100);XCTAssertNil(restored.dailyGoalReward);XCTAssertFalse(restored.learner.pendingChanges?.isEmpty ?? true)
    }
    func testDailyGoalArrivingBehindCourseDialogWaitsUntilCourseAcknowledged()throws {
        let app=try model();defer{try? app.identity.disconnect()};let clock=PlateClock(),controller=PlatePracticeController(clock:{clock.now});controller.bind(app);defer{controller.unbind()};tick(controller,app,clock,2.1)
        app.learner.award(1,source:.speak);tick(controller,app,clock,0.4);tick(controller,app,clock,2.6);XCTAssertNotNil(controller.visible)
        app.learner.award(100,source:.practice);XCTAssertNotNil(app.dailyGoalReward);XCTAssertNil(controller.dailyGoalVisible);XCTAssertNotNil(controller.visible)
        controller.continuePractice(app);XCTAssertNil(controller.visible);XCTAssertNotNil(controller.dailyGoalVisible);XCTAssertTrue(app.preservingEarnedPractice)
        controller.closeDailyGoal(app);XCTAssertFalse(app.preservingEarnedPractice)
    }
    func testSourceAndNativePlateAndDailyGoalScreens()async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1" else{throw XCTSkip("Source preview required")}
        let app=try model();defer{try? app.identity.disconnect()};let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow}
        for (lang,theme) in [("en","light"),("ar","dark")] {for kind in ["course","cleared","daily"] {
            let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:config),controller=UIViewController(),window=UIWindow(windowScene:scene);controller.view=web;window.frame=web.frame;window.rootViewController=controller;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            let screen=kind == "daily" ? "daily-goal-completion":"plate-completion"
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-onboarding?screen=\(screen)&kind=\(kind)&language=\(lang)&theme=\(theme)&details=1"))))
            var ready=false;for _ in 0..<400{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && Boolean(document.querySelector('.chakra-modal__content button'))")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(ready,"Source \(kind) failed to load");guard ready else{return}
            try await Task.sleep(for:.milliseconds(2700));let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source completion \(kind) \(lang)";source.lifetime = .keepAlways;add(source)
            let raw=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('.chakra-modal__content,.chakra-modal__body,p,button,img')].map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {text:e.textContent,x:r.x,y:r.y,width:r.width,height:r.height,font:s.font,padding:s.padding}}))");let metrics=XCTAttachment(data:Data(try XCTUnwrap(raw as? String).utf8),uniformTypeIdentifier:"public.json");metrics.name="Source completion \(kind) \(lang) geometry";metrics.lifetime = .keepAlways;add(metrics);web.stopLoading();window.isHidden=true;window.rootViewController=nil
            app.learner.support=lang;let data:JSONValue = .object(["type":.string(kind),"completed":.string("speak"),"next":.string("learn"),"details":.object(["what":.string("Greet a relative"),"why":.string("A short family call")])])
            let content:AnyView=kind == "daily" ? AnyView(DailyGoalCelebrationView(reward:.init(account:app.identity.npub,day:CalendarDay.key(Date()),goal:100,health:100),onContinue:{})):AnyView(PlateCelebrationView(data:data,language:lang,onContinue:{},onNotes:{}))
            let host=UIHostingController(rootView:content.environmentObject(app).environment(\.layoutDirection,lang == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).ignoresSafeArea().preferredColorScheme(theme == "dark" ? .dark:.light));window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(2700));let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native completion \(kind) \(lang)";native.lifetime = .keepAlways;add(native);window.isHidden=true;window.rootViewController=nil
        }};old?.makeKey()
    }
}
