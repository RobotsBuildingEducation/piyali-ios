import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor final class XPActivityReferenceTests:XCTestCase {
    func testActualSourceActivityAndNativeAtIPhoneSize()async throws{
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated source preview required")}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for language in ["en","ar"]{for state in ["empty","history"]{
            let key=state+"-"+language,window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();let web=WKWebView(frame:window.bounds,configuration:config),vc=UIViewController();vc.view=web;web.scrollView.contentInsetAdjustmentBehavior = .never;window.rootViewController=vc;window.makeKeyAndVisible();defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-xp-activity?language=\(language)&state=\(state)")!));var ready=false;for _ in 0..<400{ready=(try? await web.evaluateJavaScript("Boolean(window.__activityReady && document.querySelectorAll('#public-activity-card [title]').length===365)"))as?Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(ready,key);guard ready else{throw NSError(domain:"ActivityReferenceNotReady",code:1)};try await Task.sleep(for:.milliseconds(200))
            let metrics=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('#public-activity-card,#public-activity-card p,#public-activity-card button,#public-activity-card [title]')].map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {text:e.textContent,title:e.title,x:r.x,y:r.y,w:r.width,h:r.height,bg:s.background,border:s.border,font:s.font,color:s.color}}))") as! String;let data=XCTAttachment(string:metrics);data.name="Source activity geometry "+key;data.lifetime = .keepAlways;add(data)
            let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source activity "+key;source.lifetime = .keepAlways;add(source);_=try await web.evaluateJavaScript("document.querySelector('#public-activity-card button').click()");let action=try await web.evaluateJavaScript("window.activityAction");XCTAssertEqual(action as?String,"companion")
            web.stopLoading();window.isHidden=true;window.rootViewController=nil
            let app=AppModel();app.learner.support=language;let history:JSONValue=state == "empty" ? .object([:]):.object(["days":.object(["2026-01-01":.number(250),"2026-01-02":.number(15)]),"goalDays":.array([.string("2026-01-01"),.string("2026-01-03")])]),now=ISO8601DateFormatter().date(from:"2026-10-15T12:00:00-06:00")!
            let content=ZStack(alignment:.topLeading){PiyaliBrand(dark:language == "ar").background;DailyActivityView(onBack:{},onAchievements:{},now:now,historyOverride:history).frame(width:378,height:300).offset(x:12,y:120)}.ignoresSafeArea().environmentObject(app).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(language == "ar" ? .dark:.light)
            let host=UIHostingController(rootView:content);window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(350));let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native activity "+key;native.lifetime = .keepAlways;add(native);window.isHidden=true;window.rootViewController=nil
        }}
    }
}
