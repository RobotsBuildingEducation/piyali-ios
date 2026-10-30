import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor final class ScholarshipReferenceTests:XCTestCase {
    func testActualSourceAndNativeScholarshipModalStates()async throws {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated read-only reference preview required")}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for(lang,theme)in[("en","light"),("ar","dark")]{for state in["empty","selected","unfunded","recipients","invoice","funded"]{
            let window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();let web=WKWebView(frame:window.frame,configuration:config),vc=UIViewController();vc.view=web;window.rootViewController=vc;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never;defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-wallet?modal=1&language=\(lang)&theme=\(theme)&state=\(state)")!));var ready=false;for _ in 0..<600{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && !!document.querySelector('[role=dialog]')"))as?Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(ready);guard ready else{return};try await Task.sleep(for:.milliseconds(400))
            if state == "recipients"{let text=ScholarshipCopy.inline(lang,"Choose a recipient"),encoded=String(data:try JSONEncoder().encode(text),encoding:.utf8)!;_=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(e=>e.textContent.includes(\(encoded))).click()");try await Task.sleep(for:.milliseconds(150))}
            let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source Scholarship \(state) \(lang)";source.lifetime = .keepAlways;add(source)
            let metrics=(try? await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('[role=dialog],p,button,[role=radio],img')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{let r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,x:r.x,y:r.y,w:r.width,h:r.height,font:s.font,padding:s.padding,bg:s.backgroundColor}}))"))as?String ?? "[]";let geometry=XCTAttachment(data:Data(metrics.utf8),uniformTypeIdentifier:"public.json");geometry.name="Source Scholarship \(state) \(lang) geometry";geometry.lifetime = .keepAlways;add(geometry);web.stopLoading();window.isHidden=true;window.rootViewController=nil
            let selected=state == "empty" ? "":WalletCopy.recipients[0]["npub"].string,isReady = !["empty","selected"].contains(state)
            let view=ScholarshipSupportPanel(language:lang,selected:selected,ready:isReady,onChoose:{_ in},onClose:{},initialRecipientsOpen:state == "recipients"){
                WalletPanelView(language:lang,selected:selected,ready:isReady,canCreate:true,balance:state == "funded" ? 100:0,invoice:state == "invoice" ? "lnbc1publicwalletpreviewonly":"",compact:true,showIntro:false,showRecipients:false,transparent:true,forcePaper:true,choose:{_ in},create:{},deposit:{},copy:{},transactions:{})
            }
            window.rootViewController=UIHostingController(rootView:ZStack{PiyaliBrand.unitColor(theme == "dark" ? "0b1220":"fbf7f0");view}.environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());window.makeKeyAndVisible();try await Task.sleep(for:.milliseconds(500));let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native Scholarship \(state) \(lang)";native.lifetime = .keepAlways;add(native);window.isHidden=true;window.rootViewController=nil
        }}
    }
}
