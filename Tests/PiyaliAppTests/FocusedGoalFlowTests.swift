import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor private final class UnavailableGoalStore:LearnerProgressService {
    func load(npub:String,local:LearnerState?) async throws->LearnerState? {throw URLError(.notConnectedToInternet)}
    func save(_ state:LearnerState,npub:String) async throws->LearnerState? {throw URLError(.notConnectedToInternet)}
}
@MainActor final class FocusedGoalFlowTests:XCTestCase {
    private func model()throws->AppModel {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Requires isolated offline identity.")}
        let app=AppModel(progressService:UnavailableGoalStore());try app.identity.create();app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.onboardingComplete=true;app.signedIn=true;app.learner.editGoal("Speak with family");app.learner.pendingGoalChanges=[];return app
    }
    private func blueprint(_ app:AppModel)->JSONValue {
        let arabic=app.learner.support == "ar"
        return .object(["goalId":app.learner.goalBucket["activeGoal"]["id"],"dayKey":.string(CalendarDay.key(Date())),"lang":.string("es"),"mode":.string("lesson"),"modes":.array([.string("lesson"),.string("tutor")]),"modeTargets":.object(["lesson":.number(20),"tutor":.number(25)]),"cefrLevel":.string("Pre-A1"),"objective":.string(arabic ? "حيّ أفراد عائلتك":"Greet a family member"),"scenario":.string(arabic ? "أنت تزور عائلتك. ابدأ محادثة قصيرة بالإسبانية.":"You are visiting family. Start a short conversation in Spanish."),"targetLanguage":.array([.string("Hola"),.string("¿Cómo estás?")]),"supports":.array((arabic ? ["تدرّب على تحية","استخدم نموذجًا"]:["Rehearse a greeting","Use a model"]).map(JSONValue.string)),"successCriteria":.array((arabic ? ["قل مرحبًا","اسأل كيف حالهم"]:["Say hello","Ask how they are"]).map(JSONValue.string))])
    }
    func testFailedLessonCommitPreservesAnsweredWorkAndOneRetryIntentWithoutAdvancingGoal() async throws {
        let app=try model();defer{try? app.identity.disconnect()};let bp=blueprint(app)
        app.learner.applyGoal(GoalChange(action:.blueprint,target:"es",payload:bp));app.learner.pendingGoalChanges=[]
        let lesson=try app.sourceGoalLesson(bp);app.learner.award(12,lesson:lesson);app.learner.award(10,lesson:lesson)
        app.learner.subscriptionXPAdjustment=290;XCTAssertFalse(app.subscription.hasAccess);XCTAssertTrue(app.preserveEarnedGoalLesson(lesson));XCTAssertTrue(app.canComplete(lesson));XCTAssertEqual(GoalPractice.nextMode(try XCTUnwrap(app.readyGoal)),"lesson")
        for _ in 0..<2 {do{try await app.completeFocusedGoalLesson(lesson);XCTFail("Unacknowledged goal must offer retry")}catch{XCTAssertEqual(error.localizedDescription,app.goalCompletionText("error"))}}
        XCTAssertEqual(GoalLessonProgress.earned(app.learner.goalBucket),22);XCTAssertEqual(app.learner.totalXP,22)
        XCTAssertEqual(app.learner.pendingGoalChanges?.filter{$0.payload["requireLessonCompletion"].boolean}.count,1)
        XCTAssertEqual(GoalPractice.nextMode(try XCTUnwrap(app.readyGoal)),"lesson");XCTAssertFalse(app.learner.completed.contains(app.learner.completionKey(lesson.id)))
        XCTAssertNil(app.learner.lessonWork?[app.learner.completionKey(lesson.id)])
    }
    func testEditorDebouncesLimitsTextAndFlushesCapturedTargetOnNavigation() async throws {
        let app=try model();defer{try? app.identity.disconnect()};let editor=GoalEditorController();editor.load(app);editor.focus(true,app:app)
        editor.change("  Greet my family  ",app:app);XCTAssertEqual(app.learner.goal,"Speak with family")
        try await Task.sleep(for:.milliseconds(470));XCTAssertEqual(app.learner.goal,"Greet my family");XCTAssertFalse(editor.saved)
        app.learner.pendingGoalChanges=[];editor.receive(app);XCTAssertTrue(editor.saved);try await Task.sleep(for:.milliseconds(3100));XCTAssertFalse(editor.saved)
        let id=app.learner.goalBucket["activeGoal"]["id"];editor.change("Greet my family",app:app);editor.focus(false,app:app);XCTAssertEqual(app.learner.goalBucket["activeGoal"]["id"],id)
        editor.change("Speak at dinner",app:app);app.learner.target="fr";app.learner.goal="";editor.load(app)
        XCTAssertEqual(app.learner.goalIntelligence?["es"]?["activeGoal"]["text"].string,"Speak at dinner");XCTAssertEqual(editor.draft,"")
        editor.change(String(repeating:"😀",count:400),app:app);XCTAssertEqual(editor.draft.utf16.count,600);editor.focus(false,app:app)
        XCTAssertEqual(app.learner.goalIntelligence?["fr"]?["activeGoal"]["text"].string.utf16.count,600)
        editor.change("Do not leak",app:app);try app.identity.create();editor.close(app)
        XCTAssertNotEqual(app.learner.goalIntelligence?["fr"]?["activeGoal"]["text"].string,"Do not leak")
    }
    func testGoalCourseRoutesNextConfirmedActivityAndKeepsFinalSurface() async throws {
        let app=try model();defer{try? app.identity.disconnect()};let bp=blueprint(app)
        app.learner.applyGoal(GoalChange(action:.blueprint,target:"es",payload:bp));app.learner.pendingGoalChanges=[]
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow},window=UIWindow(windowScene:scene);var surfaces:[ProductMode]=[]
        let host=UIHostingController(rootView:FocusedGoalCourseView(onSurface:{surfaces.append($0)}).environmentObject(app));window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded()
        defer{window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
        for _ in 0..<40 where surfaces.isEmpty {try await Task.sleep(for:.milliseconds(25))};XCTAssertEqual(surfaces,[.path])
        app.recordGoalAttempt(bp,mode:"lesson",success:true,support:"prompted",observation:"Produced a greeting against the written rubric")
        try await Task.sleep(for:.milliseconds(100));XCTAssertEqual(surfaces,[.path],"Pending completion must not advance")
        app.learner.pendingGoalChanges=[]
        for _ in 0..<40 where surfaces.count<2 {try await Task.sleep(for:.milliseconds(25))};XCTAssertEqual(surfaces,[.path,.tutor])
        app.recordGoalAttempt(bp.setting("mode",.string("tutor")),mode:"tutor",success:true,support:"independent",observation:"Greeted and asked a follow-up");app.learner.pendingGoalChanges=[]
        try await Task.sleep(for:.milliseconds(100));XCTAssertNil(GoalPractice.nextMode(try XCTUnwrap(app.readyGoal)));XCTAssertEqual(surfaces,[.path,.tutor],"Final activity stays mounted for the single Goal-course celebration")
    }
    func testSourceAndNativeFocusedGoalDialogAndEditorInEnglishAndArabic() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1" else{throw XCTSkip("Requires read-only source preview")}
        let app=try model();defer{try? app.identity.disconnect()};let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow}
        for (lang,theme) in [("en","light"),("ar","dark")] {for tool in ["dialog","editor"] {
            let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:config),controller=UIViewController(),window=UIWindow(windowScene:scene);controller.view=web;window.frame=web.frame;window.rootViewController=controller;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-onboarding?screen=focused-goal&tool=\(tool)&language=\(lang)&theme=\(theme)"))))
            var ready=false
            for _ in 0..<400 {ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && Boolean(document.querySelector('\(tool == "dialog" ? "button":"textarea")'))")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(ready);guard ready else{return}
            if tool == "dialog" {_=try await web.evaluateJavaScript("document.querySelector('button').click()");try await Task.sleep(for:.milliseconds(400));let modal=try await web.evaluateJavaScript("Boolean(document.querySelector('.chakra-modal__content'))");XCTAssertTrue(modal as? Bool == true)}
            let script="JSON.stringify([...document.querySelectorAll('.chakra-modal__content,.chakra-modal__header,.chakra-modal__body,label,textarea,p,button')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {tag:e.tagName,text:e.textContent,x:r.x,y:r.y,width:r.width,height:r.height,color:s.color,bg:s.backgroundColor,border:s.borderColor,radius:s.borderRadius,padding:s.padding,font:s.font,lineHeight:s.lineHeight}}))"
            let raw=try await web.evaluateJavaScript(script);let metrics=XCTAttachment(data:Data(try XCTUnwrap(raw as? String).utf8),uniformTypeIdentifier:"public.json");metrics.name="Source focused goal \(tool) \(lang) geometry";metrics.lifetime = .keepAlways;add(metrics)
            let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source focused goal \(tool) \(lang)";source.lifetime = .keepAlways;add(source)
            web.stopLoading();window.isHidden=true;window.rootViewController=nil
            app.learner.support=lang;let bp=blueprint(app);app.learner.applyGoal(GoalChange(action:.blueprint,target:"es",payload:bp));app.learner.pendingGoalChanges=[]
            let content:AnyView=tool == "dialog" ? AnyView(ZStack{PiyaliBrand.unitColor(theme == "dark" ? "0b1220":"fbf7f0");VStack{GoalFocusBanner(blueprint:bp);Spacer()};GoalCheckDialog(presentation:.init(scope:app.goalCourseScope,blueprint:bp))}):AnyView(VStack{LearningGoalEditorView().padding(16);Spacer()}.background(BrandBackground()))
            let host=UIHostingController(rootView:content.environmentObject(app).environment(\.layoutDirection,lang == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).ignoresSafeArea().preferredColorScheme(theme == "dark" ? .dark:.light));window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(200))
            let image=UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)},native=XCTAttachment(image:image);native.name="Native focused goal \(tool) \(lang)";native.lifetime = .keepAlways;add(native);window.isHidden=true;window.rootViewController=nil
        }}
        old?.makeKey()
    }
}
