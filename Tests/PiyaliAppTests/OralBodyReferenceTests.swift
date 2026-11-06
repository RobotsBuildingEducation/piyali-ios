import XCTest
import SwiftUI
import WebKit
@testable import Piyali
@MainActor private final class OralReferenceNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor private final class OralReferenceTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    var connected=false
    func connect(session:JSONValue)async throws{connected=true}
    func send(_ event:JSONValue)->Bool{true}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func setMicrophoneEnabled(_ enabled:Bool){}
    func close(){}
}
@MainActor final class OralBodyReferenceTests:XCTestCase {
    func testOriginalSpeakingFlashcardAndDeckBodies()async throws {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated source preview required")}
        let url=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"oral-bodies",withExtension:"json")),samples=try JSONDecoder().decode(Piyali.JSONValue.self,from:Data(contentsOf:url)),app=AppModel(progressService:OralReferenceNoCloud());try app.identity.create();defer{try? app.identity.disconnect()};app.signedIn=true;app.subscription.bind(app.identity)
        let curriculum=try ContentLibrary.load([String:[LearningUnit]].self,name:"curriculum-es"),lesson=try XCTUnwrap(curriculum["Pre-A1"]?.first?.lessons.first),variants=Set((env["PIYALI_ORAL_VARIANTS"] ?? "speak-repeat,speak-translate,speak-complete,flashcard,flashcard-ja,deck").split(separator:",").map(String.init))
        for module in [PracticeRecipeModule.vocabulary,.grammar]{for language in ["en","ar"]{for variant in variants.sorted(){
            let states=variant == "deck" ? ["idle","flipped","last"]:variant == "flashcard-ja" ? ["keyboard"]:variant == "flashcard" ? ["idle","typed","flipped","wrong","locked","connecting","recording","grading"]:["idle","wrong","locked","connecting","recording"]
            for state in states{
                app.learner=LearnerState();app.learner.target=variant == "flashcard-ja" ? "ja":"es";app.learner.support=language;app.learner.onboardingComplete=true;app.activityFooter=nil;app.activityFooterHeight=0
                let sample=samples[variant == "deck" ? "flashcard":variant],question=try PracticeQuestion(module:module,kind:sample["kind"].string,payload:sample["question"],options:sample["options"],target:app.learner.target,support:language),service=PracticeService(),transport=OralReferenceTransport(),recorder=SpeechPracticeService(transportFactory:{transport},permission:{true}),oral=LessonSpeechController(recorder:recorder);var run=PracticeRun(question:question,lessonID:lesson.id,lessonLevel:"Pre-A1",response:.object(["text":.string(state == "typed" ? sample["question"]["answer"].string:state == "wrong" ? "WRONG_FIXTURE":""),"typedText":.string(state == "typed" ? sample["question"]["answer"].string:"")]))
                run.showAnswer=state == "flipped";if state == "wrong"{run.correct=false};if state == "locked"{run.correct=true;run.earnedXP=6;app.learner.lessonWork=[app.learner.completionKey(lesson.id):.init(earnedXP:6)];app.learner.collectPracticeCard(run)};app.learner.savePractice(run);service.busy=state == "grading"
                let root:AnyView
                if variant == "deck"{let cards=[("Hello","Hola"),("Thank you","Gracias"),("Goodbye","Adiós")].map{PracticeCollectedCard(id:UUID(),concept:$0.0,answer:$0.1,target:"es",support:language)};root=AnyView(PracticeDeckView(cards:cards,support:language,target:"es",initialIndex:state == "last" ? 2:0,initialFlipped:state == "flipped").background(PiyaliBrand(dark:language == "ar").background))}
                else{root=AnyView(OralReferenceHost(module:module,lesson:lesson,service:service,oral:oral,keyboard:state == "keyboard").environmentObject(app).task{if ["connecting","recording"].contains(state){try? await Task.sleep(for:.milliseconds(300));recorder.start(target:question.target,policy:try! FlashcardPolicy()){_ in XCTFail("Comparison cannot grade a transcript")};for _ in 0..<50 where !transport.connected{try? await Task.sleep(for:.milliseconds(5))};if state == "recording"{transport.onOpen?()}}})}
                try await compare(name:"\(module.rawValue) \(variant) \(state) \(language)",query:"module=\(module.rawValue)&variant=\(variant)&state=\(state)&language=\(language)",language:language,root:root);oral.clear()
            }
        }}}
    }
    func testOriginalFlashcardLoadingEmptyAndCollectedPlacement()async throws {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated source preview required")}
        let app=AppModel(progressService:OralReferenceNoCloud());try app.identity.create();defer{try? app.identity.disconnect()};app.signedIn=true;app.subscription.bind(app.identity)
        let curriculum=try ContentLibrary.load([String:[LearningUnit]].self,name:"curriculum-es"),lesson=try XCTUnwrap(curriculum["Pre-A1"]?.first?.lessons.first)
        for module in [PracticeRecipeModule.vocabulary,.grammar]{for language in ["en","ar"]{for state in ["loading","loading-no-deck","empty","locked"]{
            app.learner=LearnerState();app.learner.target="es";app.learner.support=language;app.learner.onboardingComplete=true;app.activityFooter=nil;app.activityFooterHeight=0
            let root:AnyView
            if state == "locked"{let q=try PracticeQuestion(module:module,kind:"flashcard",payload:.object(["concept":.string("Hello"),"answer":.string("Hola")]),options:.object(["cefrLevel":.string("A1")]),target:"es",support:language);var run=PracticeRun(question:q,lessonID:lesson.id,lessonLevel:"Pre-A1");run.correct=true;run.earnedXP=6;app.learner.lessonWork=[app.learner.completionKey(lesson.id):.init(earnedXP:6)];app.learner.collectPracticeCard(run);app.learner.savePractice(run)
                root=AnyView(OralReferenceHost(module:module,lesson:lesson,service:PracticeService(),oral:LessonSpeechController(),keyboard:false).environmentObject(app))
            }else{root=AnyView(VStack{LessonFlashcardPreparation(loading:state.hasPrefix("loading"),deckCount:state == "loading-no-deck" ? 0:3,support:language,openDeck:{});Spacer(minLength:0)}.padding(.horizontal,8).padding(.top,22).background(PiyaliBrand(dark:language == "ar").background))}
            try await compare(name:"\(module.rawValue) flashcard \(state) \(language)",query:"module=\(module.rawValue)&variant=flashcard&state=\(state)&language=\(language)",language:language,root:root)
        }}}
    }
    private func compare(name:String,query:String,language:String,root:AnyView)async throws {
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()};let theme=language == "ar" ? "dark":"light",background=language == "ar" ? "#0b1220":"#f7f1e7"
        let configuration=WKWebViewConfiguration();configuration.websiteDataStore = .nonPersistent();configuration.userContentController.addUserScript(WKUserScript(source:"window.__oralErrors=[];window.addEventListener('error',e=>window.__oralErrors.push(e.message));",injectionTime:.atDocumentStart,forMainFrameOnly:true));let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:configuration),window=UIWindow(windowScene:scene),vc=UIViewController();window.frame=web.frame;vc.view=web;window.rootViewController=vc;web.scrollView.contentInsetAdjustmentBehavior = .never;window.makeKeyAndVisible();defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
        web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-oral?\(query)&theme=\(theme)")!));var ready=false
        for _ in 0..<400{if let errors=try? await web.evaluateJavaScript("(window.__oralErrors||[]).join(' | ')")as?String,!errors.isEmpty{throw NSError(domain:"OralSourcePreview",code:2,userInfo:[NSLocalizedDescriptionKey:errors])};ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && !!document.querySelector('[data-oral-fixture]') && getComputedStyle(document.documentElement).getPropertyValue('--app-page-bg').trim()===\(quote(background))"))as?Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))}
        guard ready else{let message=(try? await web.evaluateJavaScript("document.body.innerText"))as?String ?? "Source unavailable";throw NSError(domain:"OralSourcePreview",code:1,userInfo:[NSLocalizedDescriptionKey:message])};try await Task.sleep(for:.milliseconds(1000));let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source oral \(name)";source.lifetime = .keepAlways;add(source)
        let geometry=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('button,input,p,[aria-roledescription],[data-activity-action-row]')].map(e=>{let r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,value:e.value,disabled:e.disabled,aria:e.getAttribute('aria-label'),x:r.x,y:r.y,w:r.width,h:r.height,color:s.color,bg:s.backgroundColor,radius:s.borderRadius,fontSize:s.fontSize,fontFamily:s.fontFamily,weight:s.fontWeight,line:s.lineHeight,shadow:s.boxShadow,padding:s.padding,border:s.borderColor,borderWidth:s.borderWidth,direction:s.direction,justify:s.justifyContent}}))"),metrics=XCTAttachment(data:Data((geometry as? String ?? "").utf8),uniformTypeIdentifier:"public.json");metrics.name="Source oral geometry \(name)";metrics.lifetime = .keepAlways;add(metrics)
        let native=UIWindow(windowScene:scene);native.frame=web.frame;let host=UIHostingController(rootView:root.environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());native.rootViewController=host;native.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(700));let capture=XCTAttachment(image:UIGraphicsImageRenderer(bounds:native.bounds).image{_ in native.drawHierarchy(in:native.bounds,afterScreenUpdates:true)});capture.name="Native oral \(name)";capture.lifetime = .keepAlways;add(capture);native.isHidden=true;native.rootViewController=nil
    }
    private func quote(_ value:String)->String{String(decoding:try! JSONEncoder().encode(value),as:UTF8.self)}
}
private struct OralReferenceHost:View {
    @EnvironmentObject var app:AppModel
    let module:PracticeRecipeModule,lesson:Lesson
    let service:PracticeService,oral:LessonSpeechController
    let keyboard:Bool
    var body:some View{LessonPracticeView(module:module,lesson:lesson,embedded:true,service:service,feedbackPortrait:7,oral:oral,allowsQuestionAutoFocus:false,writingKeyboardInitiallyOpen:keyboard).overlay(alignment:.bottom){if let footer=app.activityFooter{ZStack(alignment:.bottomLeading){footer.content.padding(12).background{SourceActivityDockBackground(correct:footer.correct,tone:footer.tone)}.padding(.horizontal,8).padding(.bottom,12);HStack{SourceActivityMenuGlyph().frame(width:18,height:18).frame(width:40,height:40);Spacer(minLength:0)}.frame(height:40).padding(.leading,20).padding(.bottom,24).environment(\.layoutDirection,.leftToRight)}.onGeometryChange(for:CGFloat.self,of:{$0.size.height}){app.activityFooterHeight=$0}}}}
}