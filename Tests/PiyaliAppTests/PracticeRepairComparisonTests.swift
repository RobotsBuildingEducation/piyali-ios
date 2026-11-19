import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor final class PracticeRepairComparisonTests:XCTestCase {
    func testSourceAndNativeDrawersShowActualStemlessMatchingCapture()async throws {
        let e=ProcessInfo.processInfo.environment
        guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",e["PIYALI_MEMORY_CAPTURE_ONLY"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated read-only source comparison required")}
        let app=AppModel();try app.identity.create();defer{try? app.identity.disconnect()};app.signedIn=true;app.learner=LearnerState();app.learner.target="es";app.learner.support="en";app.learner.onboardingComplete=true
        let q=try PracticeQuestion(module:.vocabulary,kind:"match",payload:.object(["left":.array(["hola","adiós","gracias"].map(JSONValue.string)),"right":.array(["hello","goodbye","thank you"].map(JSONValue.string))]),options:.object(["cefrLevel":.string("A1")]),target:"es",support:"en")
        let run=PracticeRun(question:q,lessonID:"lesson-pre-a1-1-1",lessonLevel:"Pre-A1",response:.object(["pairs":.object(["0":.number(1),"1":.number(0),"2":.number(2)])]));app.learner.savePractice(run)
        XCTAssertTrue(app.learner.answerPractice(key:run.key,questionID:q.id,correct:false,reward:6));XCTAssertEqual(app.learner.totalXP,0)
        let note=try XCTUnwrap(app.learner.companionMemory?["es"]?.first)
        XCTAssertEqual(note.text("concept"),"Match the items:");XCTAssertEqual(note.text("expectedAnswer"),"Check the correct pairings");XCTAssertEqual(note.text("sourceContext"),"vocabulary")
        let data=XCTAttachment(data:try JSONEncoder().encode(note),uniformTypeIdentifier:"public.json");data.name="Actual native stemless matching capture";data.lifetime = .keepAlways;add(data)
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow}
        for theme in ["light","dark"] {
            let configuration=WKWebViewConfiguration();configuration.websiteDataStore = .nonPersistent()
            configuration.userContentController.addUserScript(WKUserScript(source:"window.fixtureErrors=[];addEventListener('error',e=>fixtureErrors.push(e.message));addEventListener('unhandledrejection',e=>fixtureErrors.push(String(e.reason)));",injectionTime:.atDocumentStart,forMainFrameOnly:true))
            let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:configuration),vc=UIViewController(),window=UIWindow(windowScene:scene)
            vc.view=web;window.frame=web.frame;window.rootViewController=vc;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
            var url=URLComponents(string:"http://127.0.0.1:5181/__piyali-memory")!
            url.queryItems=[.init(name:"screen",value:"memory"),.init(name:"tool",value:"repairs"),.init(name:"language",value:"en"),.init(name:"theme",value:theme),.init(name:"goal",value:"0"),.init(name:"repairNote",value:JSONValue.object(note.fields).json)]
            web.load(URLRequest(url:try XCTUnwrap(url.url)))
            var ready=false
            for _ in 0..<600 {ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && document.body.innerText.includes('Check the correct pairings')")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))}
            if !ready {
                let diagnostic=(try? await web.evaluateJavaScript("JSON.stringify({errors:window.fixtureErrors,text:document.body.innerText,url:location.href,html:document.body.innerHTML.slice(0,6000)})")) as? String ?? "no DOM"
                let attachment=XCTAttachment(data:Data(diagnostic.utf8),uniformTypeIdentifier:"public.json");attachment.name="Source drawer readiness diagnostic";attachment.lifetime = .keepAlways;add(attachment)
                let screenshot=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));screenshot.name="Source drawer readiness failure";screenshot.lifetime = .keepAlways;add(screenshot)
            }
            XCTAssertTrue(ready);guard ready else{return}
            let text=try await web.evaluateJavaScript("document.body.innerText") as? String ?? ""
            XCTAssertTrue(text.contains(note.text("userAnswer")));XCTAssertTrue(text.contains(note.text("concept")))
            try await Task.sleep(for:.milliseconds(300))
            let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source actual matching repair drawer "+theme;source.lifetime = .keepAlways;add(source)
            let host=UIHostingController(rootView:ZStack{BrandBackground();MemoryDrawerView(onClose:{})}.environmentObject(app).environment(\.dynamicTypeSize,.large).ignoresSafeArea().preferredColorScheme(theme == "dark" ? .dark:.light))
            window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(400))
            let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native actual matching repair drawer "+theme;native.lifetime = .keepAlways;add(native)
        }
    }
}
