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
