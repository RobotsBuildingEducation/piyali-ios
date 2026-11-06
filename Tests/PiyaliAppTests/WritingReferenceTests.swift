import XCTest
import SwiftUI
import WebKit
@testable import Piyali
@MainActor private final class WritingReferenceNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class WritingReferenceTests:XCTestCase {
    private func enabled()throws{let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated source preview required")}}
    func testOriginalWritingBodiesInEnglishAndArabic()async throws {
        try enabled();let url=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"writing-bodies",withExtension:"json")),samples=try JSONDecoder().decode(Piyali.JSONValue.self,from:Data(contentsOf:url)),app=AppModel(progressService:WritingReferenceNoCloud());try app.identity.create();defer{try? app.identity.disconnect()};app.signedIn=true;app.subscription.bind(app.identity)
        let curriculum=try ContentLibrary.load([String:[LearningUnit]].self,name:"curriculum-es"),lesson=try XCTUnwrap(curriculum["Pre-A1"]?.first?.lessons.first)
        for language in ["en","ar"]{for variant in WritingPracticeQuestion.variants.sorted(){for state in ["idle","typed","extra","locked"]{
            app.learner=LearnerState();app.learner.target="es";app.learner.support=language;app.learner.onboardingComplete=true;app.activityFooter=nil;app.activityFooterHeight=0
            let sample=samples[variant],question=try PracticeQuestion(module:.grammar,kind:"delight:"+variant,payload:sample["question"],options:.object(["cefrLevel":.string("A1")]),target:"es",support:language);var run=PracticeRun(question:question,lessonID:lesson.id,lessonLevel:"Pre-A1",response:sample["responses"][state]);run.revealedClues=state == "extra" || state == "locked" ? 3:state == "typed" ? 2:1
            if state == "locked"{run.correct=true;run.earnedXP=variant == "three_clue_mystery" ? 4:7;app.learner.lessonWork=[app.learner.completionKey(lesson.id):.init(earnedXP:run.earnedXP)]};app.learner.savePractice(run)
            try await compare(name:"\(variant) \(state) \(language)",query:"variant=\(variant)&state=\(state)&language=\(language)",language:language,root:AnyView(WritingReferenceHost(lesson:lesson).environmentObject(app)))
        }}}
    }
    func testAllFiveBetaKeyboardLayoutsAndModesInEnglishAndArabic()async throws {
        try enabled();let keyboard=try WritingKeyboard()
        for support in ["en","ar"]{for language in ["ja","ru","el","pl","ga"]{for mode in language == "ja" ? ["hiragana","katakana"]:["lower","upper"]{
            let content=WritingKeyboardReferenceHost(language:language,support:support,keyboard:keyboard,mode:mode)
            try await compare(name:"keyboard \(language) \(mode) \(support)",query:"variant=keyboard&target=\(language)&mode=\(mode)&language=\(support)",language:support,root:AnyView(content),mode:mode,target:language)
        }}}
    }
    private func compare(name:String,query:String,language:String,root:AnyView,mode:String?=nil,target:String="es")async throws {
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()};let theme=language == "ar" ? "dark":"light",background=language == "ar" ? "#0b1220":"#f7f1e7"
        let configuration=WKWebViewConfiguration();configuration.websiteDataStore = .nonPersistent();let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:configuration),window=UIWindow(windowScene:scene),vc=UIViewController();window.frame=web.frame;vc.view=web;window.rootViewController=vc;web.scrollView.contentInsetAdjustmentBehavior = .never;window.makeKeyAndVisible();defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
        web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-writing-exercises?\(query)&theme=\(theme)")!));let selector=mode == nil ? "[data-activity-action-row]":"[data-writing-keyboard-fixture]";var ready=false
        for _ in 0..<600{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && !!document.querySelector(\(quote(selector))) && getComputedStyle(document.documentElement).getPropertyValue('--app-page-bg').trim()===\(quote(background))"))as?Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))}
        guard ready else{XCTFail((try? await web.evaluateJavaScript("document.body.innerText"))as?String ?? "Source unavailable");return}
        if let mode,mode == "upper" || mode == "katakana"{let label:String;if target == "ja"{label="Katakana"}else{label=try WritingKeyboard().label("lowercase",language:language)};_=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(e=>e.textContent.trim()===\(quote(label)))?.click()")}
        _=try await web.evaluateJavaScript("document.activeElement?.blur()");try await Task.sleep(for:.milliseconds(500));let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source writing \(name)";source.lifetime = .keepAlways;add(source)
        let geometry=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('button,input,p,[data-activity-action-row]')].map(e=>{let r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,value:e.value,disabled:e.disabled,aria:e.getAttribute('aria-label'),x:r.x,y:r.y,w:r.width,h:r.height,color:s.color,bg:s.backgroundColor,radius:s.borderRadius,fontSize:s.fontSize,weight:s.fontWeight,line:s.lineHeight}}))"),metrics=XCTAttachment(data:Data((geometry as? String ?? "").utf8),uniformTypeIdentifier:"public.json");metrics.name="Source writing geometry \(name)";metrics.lifetime = .keepAlways;add(metrics)
        let native=UIWindow(windowScene:scene);native.frame=web.frame;let host=UIHostingController(rootView:root.environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());native.rootViewController=host;native.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(700));let capture=XCTAttachment(image:UIGraphicsImageRenderer(bounds:native.bounds).image{_ in native.drawHierarchy(in:native.bounds,afterScreenUpdates:true)});capture.name="Native writing \(name)";capture.lifetime = .keepAlways;add(capture);native.isHidden=true;native.rootViewController=nil
    }
    private func quote(_ value:String)->String{String(decoding:try! JSONEncoder().encode(value),as:UTF8.self)}
}
private struct WritingReferenceHost:View {
    @EnvironmentObject var app:AppModel
    let lesson:Lesson
    var body:some View{LessonPracticeView(module:.grammar,lesson:lesson,embedded:true,feedbackPortrait:7,allowsQuestionAutoFocus:false).overlay(alignment:.bottom){if let footer=app.activityFooter{ZStack(alignment:.bottomLeading){footer.content.padding(12).background{SourceActivityDockBackground(correct:footer.correct,tone:footer.tone)}.padding(.horizontal,8).padding(.bottom,12);HStack{SourceActivityMenuGlyph().frame(width:18,height:18).frame(width:40,height:40);Spacer(minLength:0)}.frame(height:40).padding(.leading,20).padding(.bottom,24).environment(\.layoutDirection,.leftToRight)}.onGeometryChange(for:CGFloat.self,of:{$0.size.height}){app.activityFooterHeight=$0}}}}
}
private struct WritingKeyboardReferenceHost:View {
    let language:String,support:String,keyboard:WritingKeyboard,mode:String
    var body:some View{ZStack(alignment:.top){PiyaliBrand(dark:support == "ar").background;ScrollView{WritingVirtualKeyboard(language:language,support:support,keyboard:keyboard,onKey:{_ in},onClose:{},initialMode:mode).padding(26)}.scrollIndicators(.hidden)}}
}
