import XCTest
import SwiftUI
import WebKit
@testable import Piyali
@MainActor private final class DelightBodyNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class DelightBodyReferenceTests:XCTestCase {
    func testFiveOriginalExerciseBodiesInEnglishAndArabic()async throws {
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Read-only preview and isolated identity required")}
        let fixtureURL=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"delight-bodies",withExtension:"json")),samples=try JSONDecoder().decode(Piyali.JSONValue.self,from:Data(contentsOf:fixtureURL)),app=AppModel(progressService:DelightBodyNoCloud());try app.identity.create();defer{try? app.identity.disconnect()};app.signedIn=true;app.subscription.bind(app.identity)
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        let selection=e["PIYALI_DELIGHT_BODY_VARIANTS"]?.split(separator:",").map(String.init)
        let variants=AdvancedPracticeQuestion.variants.sorted().filter{selection == nil || selection!.contains($0)}
        XCTAssertFalse(variants.isEmpty)
        for language in ["en","ar"]{let theme=language == "ar" ? "dark":"light"
            for variant in variants{for state in ["idle","partial","filled","locked"] {
                app.learner=LearnerState();app.learner.target="es";app.learner.support=language;app.learner.onboardingComplete=true;app.activityFooter=nil;app.activityFooterHeight=0
                let curriculum=try ContentLibrary.load([String:[LearningUnit]].self,name:"curriculum-es"),lesson=try XCTUnwrap(curriculum["Pre-A1"]?.first?.lessons.first),sample=samples[variant],question=try PracticeQuestion(module:.grammar,kind:"delight:"+variant,payload:sample["question"],options:.object(["cefrLevel":.string("A1")]),target:"es",support:language)
                var run=PracticeRun(question:question,lessonID:lesson.id,lessonLevel:"Pre-A1",response:sample["responses"][state]);if state == "locked"{run.correct=true;run.earnedXP=6;app.learner.lessonWork=[app.learner.completionKey(lesson.id):.init(earnedXP:6)]};app.learner.savePractice(run)
                let configuration=WKWebViewConfiguration();configuration.websiteDataStore = .nonPersistent();let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:configuration),window=UIWindow(windowScene:scene),vc=UIViewController();window.frame=web.frame;vc.view=web;window.rootViewController=vc;web.scrollView.contentInsetAdjustmentBehavior = .never;window.makeKeyAndVisible()
                web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-delight-bodies?variant=\(variant)&language=\(language)&theme=\(theme)&state=\(state)")!));var ready=false
                let background=theme == "dark" ? "#0b1220":"#f7f1e7"
                for _ in 0..<600{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && !!document.querySelector('[data-activity-action-row]') && getComputedStyle(document.documentElement).getPropertyValue('--app-page-bg').trim()===\(quote(background))"))as?Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))}
                guard ready else{XCTFail((try? await web.evaluateJavaScript("document.body.innerText"))as?String ?? "Source failed");web.stopLoading();window.isHidden=true;window.rootViewController=nil;return};try await Task.sleep(for:.milliseconds(500))
                let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source body \(variant) \(state) \(language)";source.lifetime = .keepAlways;add(source)
                let geometry=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('button,[role=button],p,[data-activity-action-row]')].map(e=>{let r=e.getBoundingClientRect();return {text:e.textContent,disabled:e.disabled,radius:getComputedStyle(e).borderRadius,corner:getComputedStyle(e).cornerShape,font:getComputedStyle(e).font,line:getComputedStyle(e).lineHeight,x:r.x,y:r.y,w:r.width,h:r.height}}))"),metrics=XCTAttachment(data:Data((geometry as? String ?? "").utf8),uniformTypeIdentifier:"public.json");metrics.name="Source body geometry \(variant) \(state) \(language)";metrics.lifetime = .keepAlways;add(metrics)
                let native=UIWindow(windowScene:scene);native.frame=web.frame;let host=UIHostingController(rootView:DelightBodyHost(lesson:lesson).environmentObject(app).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());native.rootViewController=host;native.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(700));let capture=XCTAttachment(image:UIGraphicsImageRenderer(bounds:native.bounds).image{_ in native.drawHierarchy(in:native.bounds,afterScreenUpdates:true)});capture.name="Native body \(variant) \(state) \(language)";capture.lifetime = .keepAlways;add(capture)
                native.isHidden=true;native.rootViewController=nil;web.stopLoading();window.isHidden=true;window.rootViewController=nil
            }}
        }
    }
    private func quote(_ value:String)->String{String(decoding:try! JSONEncoder().encode(value),as:UTF8.self)}
}
private struct DelightBodyHost:View {
    @EnvironmentObject var app:AppModel
    let lesson:Lesson
    var body:some View{LessonPracticeView(module:.grammar,lesson:lesson,embedded:true,feedbackPortrait:7).overlay(alignment:.bottom){if let footer=app.activityFooter{ZStack(alignment:.bottomLeading){footer.content.padding(12).background{SourceActivityDockBackground(correct:footer.correct,tone:footer.tone)}.padding(.horizontal,8).padding(.bottom,12);HStack{SourceActivityMenuGlyph().frame(width:18,height:18).frame(width:40,height:40);Spacer(minLength:0)}.frame(height:40).padding(.leading,20).padding(.bottom,24).environment(\.layoutDirection,.leftToRight)}.onGeometryChange(for:CGFloat.self,of:{$0.size.height}){app.activityFooterHeight=$0}}}}
}
