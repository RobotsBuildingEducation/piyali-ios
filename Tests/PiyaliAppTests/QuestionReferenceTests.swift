import XCTest
import SwiftUI
import WebKit
@testable import Piyali
@MainActor private final class QuestionReferenceNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class QuestionReferenceTests:XCTestCase {
    func testOriginalQuestionAndActionAreaInEnglishAndArabic()async throws {
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Read-only source preview and isolated identity required")}
        let app=AppModel(progressService:QuestionReferenceNoCloud());try app.identity.create();defer{try? app.identity.disconnect()};app.signedIn=true;app.subscription.bind(app.identity)
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        let curriculum=try ContentLibrary.load([String:[LearningUnit]].self,name:"curriculum-es"),lesson=try XCTUnwrap(curriculum["Pre-A1"]?.first?.lessons.first)
        for (language,theme) in [("en","light"),("ar","dark")] {for state in ["idle","selected","wrong","explanation","assistant","correct"] {
            app.learner=LearnerState();app.learner.target="es";app.learner.support=language;app.learner.onboardingComplete=true;app.activityFooter=nil;app.activityFooterHeight=0
            let payload:JSONValue = .object(["variant":.string("natural_or_weird"),"sentence":.string("Yo somos Ana."),"isNatural":.bool(false),"correction":.string("Yo soy Ana."),"explanation":.string("Use soy with yo.")]),question=try PracticeQuestion(module:.grammar,kind:"delight:natural_or_weird",payload:payload,options:.object(["cefrLevel":.string("A1")]),target:"es",support:language)
            var run=PracticeRun(question:question,lessonID:lesson.id,lessonLevel:"Pre-A1",response:.object(["choice":.null]))
            if ["selected","wrong","explanation"].contains(state){run.response = .object(["choice":.bool(true)])}
            if state == "correct"{run.response = .object(["choice":.bool(false)]);run.correct=true;run.earnedXP=6;app.learner.lessonWork=[app.learner.completionKey(lesson.id):.init(earnedXP:6)]}
            if ["wrong","explanation"].contains(state){run.correct=false};app.learner.savePractice(run)
            let helper=PracticeAssistanceController(writer:{prompt,_ in prompt.contains("A student answered an exercise incorrectly") ? "Use **soy** with **yo**. Say **Yo soy Ana.**":"Use **Sounds weird**. The correct sentence is **Yo soy Ana.**"})
            let configuration=WKWebViewConfiguration();configuration.websiteDataStore = .nonPersistent();let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:configuration),window=UIWindow(windowScene:scene),vc=UIViewController();window.frame=web.frame;vc.view=web;window.rootViewController=vc;web.scrollView.contentInsetAdjustmentBehavior = .never;window.makeKeyAndVisible()
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-practice-question?language=\(language)&theme=\(theme)&state=\(state)")!))
            let background=theme == "dark" ? "#0b1220":"#f7f1e7";var ready=false
            for _ in 0..<700{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && !!document.querySelector('[data-activity-action-row]') && getComputedStyle(document.documentElement).getPropertyValue('--app-page-bg').trim()===\(quote(background))")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))}
            if !ready{let diagnostic=(try? await web.evaluateJavaScript("document.body.innerText")) as? String ?? "No source DOM";XCTFail(diagnostic);web.stopLoading();window.isHidden=true;window.rootViewController=nil;return};try await Task.sleep(for:.milliseconds(700))
            let shot=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));shot.name="Source question \(state) \(language)";shot.lifetime = .keepAlways;add(shot)
            let geometry=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('button,p,[data-activity-action-row]')].map(e=>{const r=e.getBoundingClientRect();return{text:e.textContent,aria:e.getAttribute('aria-label'),disabled:e.disabled,x:r.x,y:r.y,width:r.width,height:r.height}}))");let data=XCTAttachment(data:Data((geometry as? String ?? "").utf8),uniformTypeIdentifier:"public.json");data.name="Source question geometry \(state) \(language)";data.lifetime = .keepAlways;add(data)
            let native=UIWindow(windowScene:scene);native.frame=web.frame;let host=UIHostingController(rootView:QuestionReferenceHost(lesson:lesson,assistance:helper).environmentObject(app).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());native.rootViewController=host;native.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(500))
            if state == "assistant"{helper.ask(app,run:run)}else if state == "explanation"{helper.explain(app,run:run)}
            try await Task.sleep(for:.milliseconds(700));let screenshot=XCTAttachment(image:UIGraphicsImageRenderer(bounds:native.bounds).image{_ in native.drawHierarchy(in:native.bounds,afterScreenUpdates:true)});screenshot.name="Native question \(state) \(language)";screenshot.lifetime = .keepAlways;add(screenshot)
            helper.cancel();native.isHidden=true;native.rootViewController=nil;web.stopLoading();window.isHidden=true;window.rootViewController=nil
        }}
    }
    private func quote(_ value:String)->String{String(decoding:try! JSONEncoder().encode(value),as:UTF8.self)}
}
private struct QuestionReferenceHost:View {
    @EnvironmentObject var app:AppModel
    let lesson:Lesson,assistance:PracticeAssistanceController
    var body:some View {
        LessonPracticeView(module:.grammar,lesson:lesson,embedded:true,assistance:assistance,feedbackPortrait:7).overlay(alignment:.bottom){if let footer=app.activityFooter{ZStack(alignment:.bottomLeading){footer.content.padding(12).background{SourceActivityDockBackground(correct:footer.correct,tone:footer.tone)}.padding(.horizontal,8).padding(.bottom,12);HStack{SourceActivityMenuGlyph().frame(width:18,height:18).frame(width:40,height:40);Spacer(minLength:0)}.frame(height:40).padding(.leading,20).padding(.bottom,24).environment(\.layoutDirection,.leftToRight)}.onGeometryChange(for:CGFloat.self,of:{$0.size.height}){app.activityFooterHeight=$0}}}
    }
}
