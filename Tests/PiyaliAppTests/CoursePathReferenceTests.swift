import XCTest
import SwiftUI
import WebKit
@testable import Piyali
@MainActor private final class CoursePathNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class CoursePathReferenceTests:XCTestCase {
    func testOriginalAndNativeBeginnerAndResumedCourseInEnglishAndArabic()async throws {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Read-only source preview and isolated identity required")}
        let app=AppModel(progressService:CoursePathNoCloud());try app.identity.create();defer{try? app.identity.disconnect()};app.signedIn=true
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for (language,theme,state) in [("en","light","beginner"),("en","light","progress"),("ar","dark","beginner"),("ar","dark","progress")] {
            app.learner=LearnerState();app.learner.target="en";app.learner.support=language;app.learner.onboardingComplete=true;app.learner.place(.init(level:"Pre-A1",score:0,source:"completely_new",selectedIDs:[],updatedAt:Date()));await app.reloadContent()
            if state == "progress" {app.learner.completed.insert(app.learner.completionKey(IntroTutorial.lessonID));app.learner.xpByLanguage=["en":56];app.learner.lessonWork=[app.learner.completionKey(try XCTUnwrap(app.units.first?.lessons.first).id):.init(earnedXP:6)]}
            let configuration=WKWebViewConfiguration();configuration.websiteDataStore = .nonPersistent()
            let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:configuration),window=UIWindow(windowScene:scene),controller=UIViewController();window.frame=web.frame;controller.view=web;window.rootViewController=controller;web.scrollView.contentInsetAdjustmentBehavior = .never;window.makeKeyAndVisible();defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-course-path?language=\(language)&theme=\(theme)&state=\(state)")!))
            let expectedBackground=theme == "dark" ? "#0b1220":"#f7f1e7"
            var ready=false;for _ in 0..<600{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && document.querySelectorAll('button').length>4 && getComputedStyle(document.documentElement).getPropertyValue('--app-page-bg').trim()===\(quote(expectedBackground))")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};if !ready {let diagnostic=(try? await web.evaluateJavaScript("JSON.stringify({theme:document.documentElement.dataset.themeMode,body:document.body.dataset.themeMode,background:getComputedStyle(document.documentElement).getPropertyValue('--app-page-bg'),text:document.body.innerText.slice(0,500),buttons:document.querySelectorAll('button').length})")) as? String ?? "No source DOM";XCTFail(diagnostic);return};try await Task.sleep(for:.milliseconds(600))
            let enabled=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].filter(b=>b.textContent.includes(\(quote(CoursePathSource.text(app.introLesson!.title,language))))&&!b.disabled).length") as? Int;XCTAssertEqual(enabled,1)
            if state == "beginner" {XCTAssertEqual(app.learner.lessonAccess(app.units[0].lessons[0],units:app.units),.locked)}else{XCTAssertEqual(app.learner.lessonAccess(app.units[0].lessons[0],units:app.units),.inProgress)}
            for scroll in [0,360] {
                _=try await web.evaluateJavaScript("window.scrollTo(0,\(scroll))");try await Task.sleep(for:.milliseconds(250));let shot=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));shot.name="Source course \(state) \(language) \(scroll)";shot.lifetime = .keepAlways;add(shot)
            }
            let geometry=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('button,h2,p')].slice(0,24).map(e=>{const r=e.getBoundingClientRect();return{text:e.textContent,disabled:e.disabled,x:r.x,y:r.y+scrollY,width:r.width,height:r.height}}))");let record=XCTAttachment(data:Data((geometry as? String ?? "").utf8),uniformTypeIdentifier:"public.json");record.name="Source course geometry \(state) \(language)";record.lifetime = .keepAlways;add(record)
            let native=UIWindow(windowScene:scene);native.frame=web.frame;let host=UIHostingController(rootView:NavigationStack{LessonPathView(loadsContent:false).ignoresSafeArea()}.environmentObject(app).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());native.rootViewController=host;native.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(800))
            for scroll in [0,360] {
                if scroll>0,let view=findScroll(host.view){view.setContentOffset(CGPoint(x:0,y:scroll),animated:false);host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(250))}
                let shot=XCTAttachment(image:UIGraphicsImageRenderer(bounds:native.bounds).image{_ in native.drawHierarchy(in:native.bounds,afterScreenUpdates:true)});shot.name="Native course \(state) \(language) \(scroll)";shot.lifetime = .keepAlways;add(shot)
            }
            native.isHidden=true;native.rootViewController=nil;window.makeKeyAndVisible()
        }
    }
    private func quote(_ s:String)->String {String(decoding:try! JSONEncoder().encode(s),as:UTF8.self)}
    private func findScroll(_ view:UIView)->UIScrollView? {if let s=view as? UIScrollView{return s};return view.subviews.compactMap{findScroll($0)}.first}
}
