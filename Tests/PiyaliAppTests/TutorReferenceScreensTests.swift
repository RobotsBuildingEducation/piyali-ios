import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor final class TutorReferenceScreensTests:XCTestCase {
    func testOriginalTutorIdlePathAndIntroductoryPreviewInEnglishAndArabic()async throws {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Read-only source preview and isolated native identity required")}
        let app=AppModel();try app.identity.create();defer{try? app.identity.disconnect()};app.signedIn=true;app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.onboardingComplete=true
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow}
        for (language,theme) in [("en","light"),("ar","dark")] {
            app.learner.support=language;await app.reloadContent();let tutor=TutorSessionController();await tutor.prepare(app)
            let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:WKWebViewConfiguration()),sourceWindow=UIWindow(windowScene:scene),sourceHost=UIViewController();sourceWindow.frame=web.frame;sourceHost.view=web;sourceWindow.rootViewController=sourceHost;web.scrollView.contentInsetAdjustmentBehavior = .never;sourceWindow.makeKeyAndVisible();defer{web.stopLoading();sourceWindow.isHidden=true;sourceWindow.rootViewController=nil;old?.makeKey()}
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-onboarding?screen=tutor&language=\(language)&theme=\(theme)"))))
            let label=EntryCopy.ui(language,"app_mode_path")
            let jsLabel=String(decoding:try JSONEncoder().encode(label),as:UTF8.self)
            var ready=false;for _ in 0..<500{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && [...document.querySelectorAll('button')].some(b=>b.textContent.trim()===\(jsLabel))")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(ready);guard ready else{return}
            for state in ["idle","path","preview"] {
                if state == "path"{let clicked=try await web.evaluateJavaScript("(()=>{const b=[...document.querySelectorAll('button')].find(b=>b.textContent.trim()===\(jsLabel));b?.click();return !!b})()");XCTAssertEqual(clicked as? Bool,true)}
                if state == "preview"{let clicked=try await web.evaluateJavaScript("(()=>{const b=[...document.querySelectorAll('button')].find(b=>b.getAttribute('aria-label')?.includes(\(String(decoding:try JSONEncoder().encode(tutor.lesson["title"].localized(language)),as:UTF8.self))));b?.click();return !!b})()");XCTAssertEqual(clicked as? Bool,true)}
                try await Task.sleep(for:.milliseconds(1000));let image=try await web.takeSnapshot(configuration:nil),shot=XCTAttachment(image:image);shot.name="Source Tutor \(state) \(language)";shot.lifetime = .keepAlways;add(shot)
                let geometry=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('button,p,[role=dialog]')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect();return {text:e.textContent,aria:e.getAttribute('aria-label'),x:r.x,y:r.y,width:r.width,height:r.height}}))");let json=XCTAttachment(data:Data((geometry as? String ?? "").utf8),uniformTypeIdentifier:"public.json");json.name="Source Tutor \(state) \(language) geometry";json.lifetime = .keepAlways;add(json)
                let window=UIWindow(windowScene:scene);window.frame=web.frame
                let selected:JSONValue = .object(["lesson":tutor.lesson,"unit":tutor.unit,"status":.string("available")])
                let host=UIHostingController(rootView:Group{if state == "idle"{TutorSnapshotHost(tutor:tutor)}else{TutorSourcePathView(tutor:tutor,onClose:{},initialPreview:state == "preview" ? selected:nil)}}.environmentObject(app).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(1200));let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native Tutor \(state) \(language)";native.lifetime = .keepAlways;add(native);window.isHidden=true;window.rootViewController=nil;sourceWindow.makeKeyAndVisible()
            }
            await tutor.stop(app);web.stopLoading();sourceWindow.isHidden=true;sourceWindow.rootViewController=nil
        }
        old?.makeKey()
    }
}
private struct TutorSnapshotHost:View {
    @EnvironmentObject var app:AppModel
    let tutor:TutorSessionController
    var body:some View {SourceTutorView(controller:tutor).ignoresSafeArea().overlay(alignment:.bottom){if let footer=app.activityFooter{footer.content.padding(12).background{SourceActivityDockBackground(correct:footer.correct)}.padding(.horizontal,8).padding(.bottom,12)}}}
}

extension TutorReferenceScreensTests {
    func testOriginalFocusedTutorGoalAndRepairInEnglishAndArabic()async throws {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Read-only source preview and isolated identity required")}
        let app=AppModel();try app.identity.create();defer{try? app.identity.disconnect()};app.signedIn=true;app.subscription.bind(app.identity)
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow},day=CalendarDay.key(Date())
        for (language,theme) in [("en","light"),("ar","dark")] {for kind in ["goal","repair"] {
            app.learner=LearnerState();app.learner.onboardingComplete=true;app.learner.support=language
            let arabic=language == "ar"
            let bp:JSONValue = .object(["goalId":.string("public-tutor-goal"),"goalText":.string("Speak with family"),"dayKey":.string(day),"lang":.string("es"),"mode":.string("tutor"),"modes":.array([.string("tutor"),.string("flashcards")]),"modeTargets":.object(["tutor":.number(25),"flashcards":.number(3)]),"cefrLevel":.string("Pre-A1"),"objective":.string(arabic ? "حيّ أفراد عائلتك":"Greet a family member"),"scenario":.string(arabic ? "أنت تزور عائلتك. ابدأ محادثة قصيرة بالإسبانية.":"You are visiting family. Start a short conversation in Spanish."),"targetLanguage":.array([.string("Hola"),.string("¿Cómo estás?")]),"supports":.array((arabic ? ["تدرّب على تحية","استخدم نموذجًا"]:["Rehearse a greeting","Use a model"]).map(JSONValue.string)),"successCriteria":.array((arabic ? ["قل مرحبًا","اسأل كيف حالهم"]:["Say hello","Ask how they are"]).map(JSONValue.string))])
            app.learner.goal="Speak with family";app.learner.goalIntelligence=["es":.object(["activeGoal":.object(["id":bp["goalId"],"text":bp["goalText"],"status":.string("active")]),"dailyGoal":.object(["blueprint":bp,"modeProgress":.object(["tutor":.number(0),"flashcards":.number(0)]),"completed":.bool(false)])])]
            let item:JSONValue = .object(["memoryId":.string("public-greeting"),"concept":.string(arabic ? "حيّ أحد أقاربك":"Greet a relative"),"summary":.string(arabic ? "تدرّب على تحية قصيرة":"Practice a short greeting"),"expectedAnswer":.string("Hola"),"cefrLevel":.string("Pre-A1"),"errorType":.string("conversation_flow")])
            let plan:JSONValue = .object(["targetLang":.string("es"),"dayKey":.string(day),"target":.number(1),"items":.array([item]),"memoryIds":.array([.string("public-greeting")])]);app.learner.importQuestDay(.object(["repair":plan]),target:"es",day:day)
            let focus:TutorFocus=kind == "goal" ? .goal(bp):.repair(RepairStep(index:0,mode:"tutor",item:item,plan:plan,stepCount:1)),tutor=TutorSessionController(focus:focus);await tutor.prepare(app);XCTAssertFalse(tutor.id.isEmpty);XCTAssertNil(tutor.error)
            let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:WKWebViewConfiguration()),window=UIWindow(windowScene:scene),sourceHost=UIViewController();window.frame=web.frame;sourceHost.view=web;window.rootViewController=sourceHost;web.scrollView.contentInsetAdjustmentBehavior = .never;window.makeKeyAndVisible()
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-onboarding?screen=tutor&focus=\(kind)&language=\(language)&theme=\(theme)"))))
            let title=String(decoding:try JSONEncoder().encode(tutor.content["title"].string),as:UTF8.self);var ready=false
            for _ in 0..<500 {ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && document.body.textContent.includes(\(title))")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(ready);guard ready else{web.stopLoading();window.isHidden=true;window.rootViewController=nil;old?.makeKey();return}
            try await Task.sleep(for:.milliseconds(800));let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source Tutor focused-\(kind) \(language)";source.lifetime = .keepAlways;add(source)
            let geometry=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('button,p')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect();return {text:e.textContent,aria:e.getAttribute('aria-label'),x:r.x,y:r.y,width:r.width,height:r.height}}))"),metrics=XCTAttachment(data:Data((geometry as? String ?? "").utf8),uniformTypeIdentifier:"public.json");metrics.name="Source Tutor focused-\(kind) \(language) geometry";metrics.lifetime = .keepAlways;add(metrics)
            web.stopLoading();window.isHidden=true;window.rootViewController=nil
            let nativeWindow=UIWindow(windowScene:scene);nativeWindow.frame=web.frame;let host=UIHostingController(rootView:TutorSnapshotHost(tutor:tutor).environmentObject(app).environment(\.layoutDirection,arabic ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());nativeWindow.rootViewController=host;nativeWindow.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(800))
            let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:nativeWindow.bounds).image{_ in nativeWindow.drawHierarchy(in:nativeWindow.bounds,afterScreenUpdates:true)});native.name="Native Tutor focused-\(kind) \(language)";native.lifetime = .keepAlways;add(native);await tutor.stop(app);nativeWindow.isHidden=true;nativeWindow.rootViewController=nil
        }}
        old?.makeKey()
    }
}

extension TutorReferenceScreensTests {
    func testOriginalCompletionAndAgendaReviewAcrossPhoneSizesAndSupportLanguages()async throws{
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_REFERENCE_PREVIEW_TESTS"]=="1",env["PIYALI_OFFLINE_TESTS"]=="1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Read-only source preview and isolated identity required")}
        let app=AppModel();try app.identity.create();defer{try? app.identity.disconnect()};app.signedIn=true;app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.onboardingComplete=true;app.learner.xpByLanguage=["es":50]
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as?UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for(width,height,target,support,theme)in[(402.0,874.0,"es","en","light"),(402.0,874.0,"es","ar","dark"),(375.0,667.0,"es","en","light"),(375.0,667.0,"es","ar","dark"),(402.0,874.0,"ja","en","light"),(375.0,667.0,"ja","ar","dark")]{
            app.learner.target=target;app.learner.support=support;app.learner.xpByLanguage=[target:50];await app.reloadContent();let tutor=TutorSessionController();await tutor.prepare(app);XCTAssertFalse(tutor.id.isEmpty,tutor.error ?? "Missing source lesson");XCTAssertNil(tutor.error);let policy=try TutorSourcePolicy(),data=try policy.run("completed",.object(["lesson":tutor.lesson,"unit":tutor.unit,"target":.string(target),"support":.string(support),"earned":.number(50)]));XCTAssertFalse(data["items"].array.isEmpty);XCTAssertTrue(data["items"].array.allSatisfy{$0["completed"].boolean})
            for state in ["completion","review"]{
                let size=CGRect(x:0,y:0,width:width,height:height),window=UIWindow(windowScene:scene);window.frame=size;let configuration=WKWebViewConfiguration();configuration.websiteDataStore = .nonPersistent();let web=WKWebView(frame:size,configuration:configuration);web.scrollView.contentInsetAdjustmentBehavior = .never;let sourceHost=UIViewController();sourceHost.view=web;window.rootViewController=sourceHost;window.makeKeyAndVisible();defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
                var url=URLComponents(string:"http://127.0.0.1:5181/__piyali-tutor-completion")!;url.queryItems=[.init(name:"state",value:state),.init(name:"language",value:support),.init(name:"theme",value:theme),.init(name:"data",value:data.canonicalJSON)];web.load(URLRequest(url:try XCTUnwrap(url.url)));var ready=false
                for _ in 0..<600{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded'&&!!document.querySelector('[role=dialog]')"))as?Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(25))};let errors=(try? await web.evaluateJavaScript("document.body.innerText"))as?String ?? "";XCTAssertTrue(ready,errors);guard ready else{return};try await Task.sleep(for:.milliseconds(900));let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source Tutor \(state) \(target)-\(support) \(Int(width))";source.lifetime = .keepAlways;add(source)
                let metrics=(try? await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('[role=dialog],button,p,h2,img')].map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,x:r.x,y:r.y,w:r.width,h:r.height,color:s.color,font:s.fontFamily,fontSize:s.fontSize,lineHeight:s.lineHeight,radius:s.borderRadius,background:s.background}}))"))as?String ?? "[]";let a=XCTAttachment(string:metrics);a.name="Source Tutor \(state) metrics \(target)-\(support) \(Int(width))";a.lifetime = .keepAlways;add(a);web.stopLoading();window.isHidden=true;window.rootViewController=nil
                let host=UIHostingController(rootView:ZStack{PiyaliBrand.unitColor(theme=="light" ? "f7f1e7":"0b1220");if state=="completion"{TutorSourceCompletion(data:data,copy:{tutor.copy($0,support)},onContinue:{})}else{TutorSourceReview(data:data,copy:{tutor.copy($0,support)},onContinue:{})}}.environmentObject(app).environment(\.layoutDirection,support=="ar" ? .rightToLeft:.leftToRight).preferredColorScheme(theme=="light" ? .light:.dark).ignoresSafeArea());window.rootViewController=host;window.makeKeyAndVisible();window.layoutIfNeeded();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(500));let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native Tutor \(state) \(target)-\(support) \(Int(width))";native.lifetime = .keepAlways;add(native);window.isHidden=true;window.rootViewController=nil
            };await tutor.stop(app,saveDraft:false)
        }
    }
}
