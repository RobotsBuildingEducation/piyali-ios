import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor private final class HelpNoCloud:LearnerProgressService {
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class HelpChatReferenceTests:XCTestCase {
    func testOriginalSourceAndNativeEmptyTranscriptAndSavedMenu()async throws {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated reference opt-in required")}
        let app=AppModel(progressService:HelpNoCloud());try app.identity.create();defer{try? app.identity.disconnect()};app.subscription.bind(app.identity);app.signedIn=true;app.learner.onboardingComplete=true
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for(lang,theme)in [("en","light"),("ar","dark")] {for state in ["empty","transcript","menu"] {
            app.learner.support=lang
            let window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);let web=WKWebView(frame:window.frame),vc=UIViewController();vc.view=web;window.rootViewController=vc;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-help?language=\(lang)&theme=\(theme)")!))
            var ready=false;for _ in 0..<400{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && !!document.querySelector('textarea')"))as?Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(ready);guard ready else{return};try await Task.sleep(for:.milliseconds(600))
            if state != "empty" {
                _=try await web.evaluateJavaScript("(()=>{const input=document.querySelector('textarea');Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype,'value').set.call(input,'How do I say sister?');input.dispatchEvent(new Event('input',{bubbles:true}));})()")
                try await Task.sleep(for:.milliseconds(100));_=try await web.evaluateJavaScript("document.querySelector('button[aria-label=\"\(lang == "ar" ? "إرسال":"Send")\"]').click()")
                var replied=false;for _ in 0..<100{replied=(try? await web.evaluateJavaScript("document.body.innerText.includes('Mi hermana vive aquí.')"))as?Bool == true;if replied{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(replied)
                if state == "menu"{_=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(b=>b.textContent.includes('\(lang == "ar" ? "احفظ المحادثة":"Save chat")')).click();document.querySelector('button[aria-label=\"\(lang == "ar" ? "القائمة":"Menu")\"]').click()");try await Task.sleep(for:.milliseconds(2100))}
            }
            try await Task.sleep(for:.milliseconds(500));let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source Help \(state) \(lang)";source.lifetime = .keepAlways;add(source)
            let metrics=(try? await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('[role=dialog], textarea, button,p')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,label:e.getAttribute('aria-label'),x:r.x,y:r.y,width:r.width,height:r.height,font:s.font,fontFamily:s.fontFamily,color:s.color,background:s.backgroundColor}}))"))as?String ?? "[]";let data=XCTAttachment(data:Data(metrics.utf8),uniformTypeIdentifier:"public.json");data.name="Source Help \(state) \(lang) geometry";data.lifetime = .keepAlways;add(data)
            web.stopLoading();window.isHidden=true;window.rootViewController=nil
            let directory=FileManager.default.temporaryDirectory.appendingPathComponent("help-snapshot-"+UUID().uuidString);defer{try? FileManager.default.removeItem(at:directory)}
            let chat=HelpChatController(directory:directory),progress:JSONValue = .object(["targetLang":.string("es"),"supportLang":.string(lang)])
            chat.configure(account:app.identity.npub,progress:progress,appLanguage:lang)
            if state != "empty"{chat.voiceInput(.init(id:"input",text:"How do I say sister?",answered:"",responseID:nil));chat.voiceReply("reply",text:lang == "ar" ? "استخدم **hermana** للكلام عن أختك.\n// Mi hermana vive aquí.":"Use **hermana** to talk about your sister.\n// Mi hermana vive aquí.");if state == "menu"{chat.save();chat.notice=nil}}
            window.rootViewController=UIHostingController(rootView:ZStack{PiyaliBrand(dark:theme == "dark").background;HelpChatView(controller:chat,progress:progress,initialSidebar:state == "menu",onClose:{})}.environmentObject(app).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());window.makeKeyAndVisible();try await Task.sleep(for:.milliseconds(800))
            let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native Help \(state) \(lang)";native.lifetime = .keepAlways;add(native);window.isHidden=true;window.rootViewController=nil
        }}
    }
}
