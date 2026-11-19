import XCTest
import WebKit
@testable import Piyali

@MainActor final class SourceSessionToolsTests:XCTestCase {
    func testOriginalGoalManagerAndTimerInEnglishAndArabicIPhoneWebKit() async throws {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Requires isolated offline source-preview testing.")}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),oldKey=scene.windows.first{$0.isKeyWindow}
        for (lang,theme) in [("en","light"),("ar","dark")]{for tool in ["goal","timer"]{
            let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent()
            let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:config),controller=UIViewController(),window=UIWindow(windowScene:scene);window.frame=web.frame;controller.view=web;web.scrollView.contentInsetAdjustmentBehavior = .never;window.rootViewController=controller;window.makeKeyAndVisible()
            defer{web.stopLoading();web.removeFromSuperview();window.isHidden=true;window.rootViewController=nil;oldKey?.makeKey()}
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-onboarding?screen=tools&tool=\(tool)&language=\(lang)&theme=\(theme)"))))
            var ready=false
            for _ in 0..<400{ready=(try? await web.evaluateJavaScript("Boolean(document.querySelector('.chakra-modal__content') && document.fonts.status==='loaded')")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))}
            XCTAssertTrue(ready);guard ready else{return};try await Task.sleep(for:.milliseconds(300))
            let script="""
            JSON.stringify({viewport:{width:innerWidth,height:innerHeight},elements:[...document.querySelectorAll('header,.chakra-modal__content,.chakra-modal__header,.app-modal-header,.chakra-modal__body,.chakra-modal__footer,label,input,p,button')].filter(el=>el.getBoundingClientRect().width>0).map(el=>{const r=el.getBoundingClientRect(),s=getComputedStyle(el);return {tag:el.tagName,text:el.textContent,value:el.value,label:el.getAttribute('aria-label'),x:r.x,y:r.y,width:r.width,height:r.height,font:s.font,fontSize:s.fontSize,lineHeight:s.lineHeight,background:s.backgroundColor}})})
            """
            let raw=try await web.evaluateJavaScript(script),text=try XCTUnwrap(raw as? String)
            let data=Data(text.utf8),metrics=try JSONDecoder().decode(JSONValue.self,from:data);XCTAssertEqual(metrics["viewport"]["width"].number,402)
            let json=XCTAttachment(data:data,uniformTypeIdentifier:"public.json");json.name="Source tools \(tool) \(lang) geometry";json.lifetime = .keepAlways;add(json)
            let image=try await web.takeSnapshot(configuration:nil);XCTAssertGreaterThan(try XCTUnwrap(image.pngData()).count,20_000)
            let shot=XCTAttachment(image:image);shot.name="Source tools \(tool) \(lang)";shot.lifetime = .keepAlways;add(shot)
        }}
    }
}
