import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor final class ReadingAudioReferenceTests:XCTestCase{
    private func textLayout(_ sentences:[String],width:CGFloat,rtl:Bool=false)
        ->(NSTextStorage,ReadingSentenceLayout,NSTextContainer) {
        let storage=NSTextStorage(attributedString:ReadingSentenceLayout.content(sentences,dark:rtl,rtl:rtl))
        let layout=ReadingSentenceLayout()
        let container=NSTextContainer(size:CGSize(width:width,height:1_000))
        container.lineFragmentPadding=0
        storage.addLayoutManager(layout)
        layout.addTextContainer(container)
        layout.ensureLayout(for:container)
        return (storage,layout,container)
    }

    func testReadingSentenceFragmentsMatchTheReferenceWrapAndHitTargets() throws {
        let value=try ContentLibrary.load(JSONValue.self,name:"reading-test-passage")
        let sentences=Array(Reading.displaySentences(value["target"].string).prefix(3))
        let (storage,layout,container)=textLayout(sentences,width:333)
        withExtendedLifetime(storage) {
            let fragments=layout.fragments(in:layout.glyphRange(for:container)).filter { $0.sentence == 1 }
            XCTAssertEqual(fragments.count,2)
            if fragments.count == 2 {
                XCTAssertGreaterThan(fragments[0].bounds.minX,300)
                XCTAssertLessThan(fragments[1].bounds.minX,2)
                XCTAssertEqual(fragments[1].bounds.minY-fragments[0].bounds.minY,35.2,accuracy:0.8)
                let gap=CGPoint(x:100,y:fragments[0].bounds.maxY+5)
                XCTAssertNil(layout.sentence(at:gap,in:container))
            }
            for fragment in fragments {
                XCTAssertEqual(layout.sentence(at:CGPoint(x:fragment.bounds.midX,y:fragment.bounds.midY),in:container),1)
            }
        }
    }

    func testMixedArabicSentenceFragmentsKeepTheirLogicalPlaybackIndex() {
        let sentences=["ذهبتُ إلى السوق في 2026.","اشتريتُ خبزًا وقهوةً في Piyali."]
        let (storage,layout,container)=textLayout(sentences,width:225,rtl:true)
        withExtendedLifetime(storage) {
            let fragments=layout.fragments(in:layout.glyphRange(for:container))
            XCTAssertEqual(Set(fragments.map(\.sentence)),Set([0,1]))
            XCTAssertGreaterThan(fragments.filter { $0.sentence == 0 }.map { $0.bounds.maxX }.max() ?? 0,220)
            for fragment in fragments {
                let point=CGPoint(x:fragment.bounds.midX,y:fragment.bounds.midY)
                XCTAssertEqual(layout.sentence(at:point,in:container),fragment.sentence)
            }
        }
    }

    func testOriginalReadingAudioControlsInEnglishAndArabic()async throws{
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated source preview required")}
        _ = try ContentLibrary.load(JSONValue.self,name:"reading-audio-ui")
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for language in["en","ar"]{for state in["idle","loading","playing"]{
            let dark=language == "ar",config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent()
            let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:140),configuration:config),sourceWindow=UIWindow(windowScene:scene),vc=UIViewController();web.scrollView.contentInsetAdjustmentBehavior = .never;web.scrollView.contentInset = .zero;sourceWindow.frame=web.frame;sourceWindow.rootViewController=vc;vc.view.addSubview(web);sourceWindow.makeKeyAndVisible();defer{sourceWindow.isHidden=true;sourceWindow.rootViewController=nil}
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-reading-audio?language=\(language)&state=\(state)")!));var ready=false
            for _ in 0..<600{if(try? await web.evaluateJavaScript("window.__readingAudioReady===true&&document.querySelectorAll('button').length===2"))as?Bool == true{ready=true;break};try await Task.sleep(for:.milliseconds(25))};XCTAssertTrue(ready);guard ready else{return};let visible=try await web.evaluateJavaScript("[...document.querySelectorAll('button,p')].every(e=>{let r=e.getBoundingClientRect();return r.y>=0&&r.bottom<=140})");XCTAssertEqual(visible as? Bool,true,"Source audio controls must fit the capture");try await Task.sleep(for:.milliseconds(500))
            var painted:UIImage?;for _ in 0..<4{let candidate=try await web.takeSnapshot(configuration:nil);if hasPaint(candidate){painted=candidate;break};try await Task.sleep(for:.milliseconds(200))};let source=XCTAttachment(image:try XCTUnwrap(painted));source.name="Source Reading audio \(state) \(language)";source.lifetime = .keepAlways;add(source)
            let geometry=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('button,p,.chakra-spinner')].map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,x:r.x,y:r.y,w:r.width,h:r.height,color:s.color,bg:s.background,border:s.border,shadow:s.boxShadow,radius:s.borderRadius,opacity:s.opacity,fontSize:s.fontSize,lineHeight:s.lineHeight}}))"),metrics=XCTAttachment(data:Data((geometry as? String ?? "").utf8),uniformTypeIdentifier:"public.json");metrics.name="Source Reading audio geometry \(state) \(language)";metrics.lifetime = .keepAlways;add(metrics)
            let native=UIWindow(windowScene:scene);native.frame=web.frame;let host=UIHostingController(rootView:ReadingAudioControls(support:language,loading:state == "loading",stopActive:state != "idle",read:{},stop:{}).frame(width:402,height:140).background(PiyaliBrand(dark:dark).background).environment(\.layoutDirection,dark ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(dark ? .dark:.light).ignoresSafeArea());native.rootViewController=host;native.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(500));let capture=XCTAttachment(image:UIGraphicsImageRenderer(bounds:native.bounds).image{_ in native.drawHierarchy(in:native.bounds,afterScreenUpdates:true)});capture.name="Native Reading audio \(state) \(language)";capture.lifetime = .keepAlways;add(capture);native.isHidden=true;native.rootViewController=nil
        }}
    }
    private func hasPaint(_ image:UIImage)->Bool{guard let cg=image.cgImage,let context=CGContext(data:nil,width:32,height:32,bitsPerComponent:8,bytesPerRow:128,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)else{return false};context.draw(cg,in:CGRect(x:0,y:0,width:32,height:32));guard let data=context.data else{return false};let pixels=data.bindMemory(to:UInt32.self,capacity:1024);return Set((0..<1024).map{pixels[$0]}).count>2}
}
