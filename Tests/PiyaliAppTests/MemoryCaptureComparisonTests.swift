import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor final class MemoryCaptureComparisonTests:XCTestCase {
    func testOriginalCrystalFramesAndNativeGeometryInLightDarkAndReducedMotion()async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1" else{throw XCTSkip("Read-only source renderer required")}
        XCTAssertEqual(MemoryCaptureDesign.data["shards"].array.count,12)
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow}
        for(theme,language)in[("light","en"),("dark","ar")] {
            let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent()
            let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:400),configuration:config),controller=UIViewController(),window=UIWindow(windowScene:scene)
            controller.view=web;window.frame=web.frame;window.rootViewController=controller;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5183/?theme=\(theme)&language=\(language)"))))
            var ready=false
            for _ in 0..<400 {ready=(try? await web.evaluateJavaScript("document.querySelectorAll('[data-memory-crystal]').length===12 && typeof window.freezeCapture==='function'")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(30))}
            XCTAssertTrue(ready);guard ready else{return}
            let rgb=try await web.evaluateJavaScript("getComputedStyle(document.querySelector('#root').firstElementChild).backgroundColor.match(/[\\d.]+/g).map(Number)") as? [Double] ?? []
            let background=Color(.sRGB,red:(rgb.first ?? 0)/255,green:(rgb.count>1 ? rgb[1]:0)/255,blue:(rgb.count>2 ? rgb[2]:0)/255)
            for(ms,reduced)in[(500,false),(1600,false),(2300,false),(1600,true)] {
                window.rootViewController=controller;window.makeKeyAndVisible()
                _=try await web.evaluateJavaScript("window.frozenCapture=null;window.freezeCapture(\(ms),\(reduced)).then(value=>window.frozenCapture=value);true")
                var raw:String?
                for _ in 0..<200 {raw=(try? await web.evaluateJavaScript("window.frozenCapture")) as? String;if raw != nil{break};try await Task.sleep(for:.milliseconds(20))}
                let string=try XCTUnwrap(raw),metrics=try JSONDecoder().decode(JSONValue.self,from:Data(string.utf8)),elapsed=Double(ms)/1000
                if reduced {XCTAssertTrue(metrics["shards"].array.allSatisfy{$0["opacity"].number==0})}
                else {
                    XCTAssertEqual(metrics["shards"].array.count,12)
                    for(index,source)in metrics["shards"].array.enumerated() {
                        let state=MemoryCaptureMotion.shard(MemoryCaptureDesign.data,index:index,elapsed:elapsed),matrix=source["matrix"].array.map(\.number),angle=state.rotation*Double.pi/180
                        XCTAssertEqual(source["opacity"].number,state.opacity,accuracy:0.002)
                        XCTAssertEqual(matrix[0],cos(angle)*state.scale,accuracy:0.002);XCTAssertEqual(matrix[1],sin(angle)*state.scale,accuracy:0.002)
                        XCTAssertEqual(matrix[12],state.x-14.3/2,accuracy:0.03);XCTAssertEqual(matrix[13],state.y-14.3/2,accuracy:0.03)
                    }
                    let caught=MemoryCaptureMotion.crystal(MemoryCaptureDesign.data,elapsed:elapsed)
                    XCTAssertEqual(metrics["catch"]["opacity"].number,caught.opacity,accuracy:0.002);XCTAssertEqual(metrics["catch"]["matrix"].array[0].number,caught.scale,accuracy:0.002)
                    let trigger=MemoryCaptureMotion.trigger(MemoryCaptureDesign.data,elapsed:elapsed)
                    XCTAssertEqual(metrics["trigger"]["matrix"].array[0].number,trigger.scale,accuracy:0.002);XCTAssertEqual(metrics["trigger"]["matrix"].array[13].number,trigger.y,accuracy:0.002)
                }
                let suffix="\(theme) \(ms) \(reduced ? "reduced":"motion")"
                let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source Memory capture "+suffix;source.lifetime = .keepAlways;add(source)
                let detail=XCTAttachment(data:Data(string.utf8),uniformTypeIdentifier:"public.json");detail.name="Source Memory metrics "+suffix;detail.lifetime = .keepAlways;add(detail)
                let capture=MemoryCaptureController()
                let host=UIHostingController(rootView:ZStack{background;MemoryCaptureMenuButton(capture:capture,scope:"public:es:en",language:language,label:"Reading",glyphSize:22,size:44,radius:12,background:.clear,border:.clear,foreground:.black,action:{},frozenElapsed:elapsed,reducedMotionOverride:reduced).frame(width:44,height:44).position(x:201,y:222)}.environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).ignoresSafeArea().preferredColorScheme(theme == "dark" ? .dark:.light))
                window.rootViewController=host;host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(60))
                let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native Memory capture "+suffix;native.lifetime = .keepAlways;add(native)
            }
        }
    }
}
