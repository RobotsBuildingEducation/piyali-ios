import XCTest
import WebKit
import SwiftUI
@testable import Piyali

/// QA only: render the unmodified source component with a public fixture in
/// iOS WebKit. The product continues to use native SwiftUI views.
@MainActor final class SourceWebKitTypographyTests:XCTestCase {
    private final class Navigation:NSObject,WKNavigationDelegate {
        var failure:Error?
        func webView(_ webView:WKWebView,didFailProvisionalNavigation navigation:WKNavigation!,withError error:Error){failure=error}
        func webView(_ webView:WKWebView,didFail navigation:WKNavigation!,withError error:Error){failure=error}
    }
    func testOriginalEnglishAndArabicHeadlinesRenderInIPhoneWebKit() async throws {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Requires the target-owned local source preview and an isolated offline identity.")}
        for (language,theme) in [("en","light"),("ar","dark")] {
            let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent()
            let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),oldKey=scene.windows.first{$0.isKeyWindow}
            let frame=CGRect(x:0,y:0,width:402,height:874),web=WKWebView(frame:frame,configuration:config),navigation=Navigation(),controller=UIViewController(),window=UIWindow(windowScene:scene)
            window.frame=frame
            web.navigationDelegate=navigation;web.scrollView.contentInsetAdjustmentBehavior = .never;controller.view=web;window.rootViewController=controller;window.makeKeyAndVisible()
            defer{web.stopLoading();web.removeFromSuperview();window.isHidden=true;window.rootViewController=nil;oldKey?.makeKey()}
            let url=try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-onboarding?screen=focus&state=headline&language=\(language)&theme=\(theme)"));web.load(URLRequest(url:url))
            var ready=false
            for _ in 0..<400 {
                if let failure=navigation.failure {throw failure}
                ready=(try? await web.evaluateJavaScript("Boolean([...document.querySelectorAll('p')].some(p=>p.textContent===\"Ask about today's plans with confidence.\"||p.textContent==='تحدث بثقة عن خططك لهذا اليوم.'))")) as? Bool == true
                if ready{break};try await Task.sleep(for:.milliseconds(50))
            }
            XCTAssertTrue(ready,"The source headline must actually render before recording the baseline.");guard ready else{return}
            let script="""
            (()=>{
            const elements=[...document.querySelectorAll('p')].slice(0,3).map(el=>{
              const s=getComputedStyle(el),r=el.getBoundingClientRect(),range=document.createRange();range.selectNodeContents(el);const glyph=range.getBoundingClientRect();
              return {text:el.textContent,x:r.x,y:r.y,width:r.width,height:r.height,glyphWidth:glyph.width,glyphHeight:glyph.height,fontFamily:s.fontFamily,fontSize:parseFloat(s.fontSize),fontWeight:parseInt(s.fontWeight),lineHeight:parseFloat(s.lineHeight),letterSpacing:s.letterSpacing};
            });
            return JSON.stringify({language:document.documentElement.lang,direction:document.documentElement.dir,width:innerWidth,height:innerHeight,userAgent:navigator.userAgent,elements});
            })()
            """
            for _ in 0..<200 {
                if (try await web.evaluateJavaScript("document.fonts.status")) as? String == "loaded"{break}
                try await Task.sleep(for:.milliseconds(25))
            }
            let raw=try await web.evaluateJavaScript(script),text=try XCTUnwrap(raw as? String),source=try JSONDecoder().decode(JSONValue.self,from:Data(text.utf8))
            XCTAssertEqual(source["width"].number,402);XCTAssertEqual(source["elements"].array.count,3)
            var metrics=source
            var native:[JSONValue]=[]
            for element in [source["elements"].array[0],source["elements"].array[2]] {
                let size=element["fontSize"].number,black=element["fontWeight"].number >= 800,font=UIFont.systemFont(ofSize:size,weight:black ? .black : .medium)
                let width=(element["text"].string as NSString).size(withAttributes:[.font:font]).width
                let sample=OnboardingText(text:element["text"].string,size:size,weight:black ? .black : .medium,lineHeight:element["lineHeight"].number).environment(\.dynamicTypeSize,.large).environment(\.layoutDirection,language == "ar" ? .rightToLeft : .leftToRight)
                let host=UIHostingController(rootView:sample),measured=host.sizeThatFits(in:CGSize(width:346,height:1000))
                native.append(.object(["text":element["text"],"glyphWidth":.number(width),"lineBoxHeight":.number(measured.height),"fontName":.string(font.fontName)]))
                if !black {
                    XCTAssertLessThanOrEqual(abs(element["glyphWidth"].number-width),1,"The headline should use equivalent iPhone system-font fallback.")
                    XCTAssertLessThanOrEqual(abs(element["height"].number-measured.height),1,"Allow one point for WebKit/SwiftUI line-box rounding.")
                }
                print("IOS SOURCE FONT \(language): size=\(size) weight=\(element["fontWeight"].number) sourceGlyph=\(element["glyphWidth"].number) nativeGlyph=\(width) sourceHeight=\(element["height"].number) nativeHeight=\(measured.height)")
            }
            metrics=metrics.setting("native",.array(native))
            let attachment=XCTAttachment(data:Data(metrics.json.utf8),uniformTypeIdentifier:"public.json");attachment.name="iOS WebKit typography \(language)";attachment.lifetime = .keepAlways;add(attachment)
            try await Task.sleep(for:.milliseconds(250))
            let picture=try await web.takeSnapshot(configuration:nil),image=XCTAttachment(image:picture);image.name="Source iOS WebKit \(language)";image.lifetime = .keepAlways;add(image)
            XCTAssertGreaterThan(try XCTUnwrap(picture.pngData()).count,20_000,"Reject a blank snapshot; source DOM metrics alone do not establish visual parity.")
        }
    }
}
