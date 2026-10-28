import XCTest
import WebKit
import SwiftUI
@testable import Piyali

@MainActor final class PaperPencilReferenceTests:XCTestCase {
    func testOriginalPaperModalArtMotionAndIPhoneGeometry()async throws{
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated source preview required")}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow},script=try String(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"paper-pencil-art",withExtension:"js")),encoding:.utf8);defer{old?.makeKey()}
        for(language,theme)in[("en","light"),("ar","dark")]{
            let window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();let web=WKWebView(frame:window.bounds,configuration:config),vc=UIViewController();vc.view=web;web.scrollView.contentInsetAdjustmentBehavior = .never;window.rootViewController=vc;window.makeKeyAndVisible();defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-paper?language=\(language)&theme=\(theme)")!));var ready=false;for _ in 0..<500{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && document.querySelectorAll('.chakra-modal__content svg').length===2"))as?Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(ready);guard ready else{let diagnostic=XCTAttachment(string:(try? await web.evaluateJavaScript("JSON.stringify({body:document.body.innerText,errors:window.paperErrors,svg:document.querySelectorAll(\"svg\").length,url:location.href})"))as?String ?? "No DOM");diagnostic.lifetime = .keepAlways;add(diagnostic);throw NSError(domain:"PaperReferenceNotReady",code:1)};try await Task.sleep(for:.milliseconds(300))
            let raw=try await web.callAsyncJavaScript("return await ("+script+")()",arguments:[:],in:nil,contentWorld:.page),data=Data(try XCTUnwrap(raw as?String).utf8),value=try JSONDecoder().decode(JSONValue.self,from:data)
            for(name,layer)in value["layers"].object{let image=try XCTUnwrap(Data(base64Encoded:layer["png"].string));let a=XCTAttachment(data:image,uniformTypeIdentifier:"public.png");a.name="Paper art \(theme) \(name)";a.lifetime = .keepAlways;add(a);let svg=XCTAttachment(string:layer["svg"].string);svg.name="Paper SVG \(theme) \(name)";svg.lifetime = .keepAlways;add(svg)}
            let metrics=XCTAttachment(data:try JSONEncoder().encode(value.setting("layers",.null)),uniformTypeIdentifier:"public.json");metrics.name="Source Paper geometry and motion "+language;metrics.lifetime = .keepAlways;add(metrics)
            let shot=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));shot.name="Source Paper modal "+language;shot.lifetime = .keepAlways;add(shot)
            web.stopLoading();window.isHidden=true;window.rootViewController=nil
            let app=AppModel();app.learner.support=language
            let content=ZStack{PiyaliBrand(dark:theme == "dark").background;(theme == "dark" ? PiyaliBrand.unitColor("020617").opacity(0.92):PiyaliBrand.unitColor("1c140c").opacity(0.82));PaperPencilView(onClose:{},animated:false)}.ignoresSafeArea().environmentObject(app).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light)
            let host=UIHostingController(rootView:content);window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(350));let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native Paper modal "+language;native.lifetime = .keepAlways;add(native)

        }
    }
}
