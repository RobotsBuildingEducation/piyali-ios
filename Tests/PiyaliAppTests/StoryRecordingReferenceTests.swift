import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor private final class RecordingPoseTransport:RealtimeVoiceTransport{
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    var ready=false
    func connect(session:JSONValue)async throws{ready=true}
    func send(_ event:JSONValue)->Bool{true}
    func setMicrophoneEnabled(_ enabled:Bool){}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func audioAmplitude(speaking:Bool)async->Double{0.1}
    func close(){}
}
@MainActor final class StoryRecordingReferenceTests:XCTestCase{
    func testOriginalRecordingButtonsForBothStoryCallers()async throws{
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated source preview required")}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for mode in["speaking","conversation"]{for language in["en","ar"]{for state in(mode == "speaking" ? ["idle","connecting","recording","evaluating","wrong"]:["idle","connecting","recording","evaluating"]){
            let dark=language == "ar",config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:100),configuration:config);web.scrollView.contentInsetAdjustmentBehavior = .never
            let sourceWindow=UIWindow(windowScene:scene),vc=UIViewController();sourceWindow.frame=web.frame;sourceWindow.rootViewController=vc;vc.view.addSubview(web);sourceWindow.makeKeyAndVisible();defer{sourceWindow.isHidden=true;sourceWindow.rootViewController=nil}
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-story-recording?mode=\(mode)&language=\(language)&state=\(state)")!));var ready=false
            for _ in 0..<600{if(try? await web.evaluateJavaScript("window.__storyRecordingReady===true&&document.querySelectorAll('button').length===1"))as?Bool == true{ready=true;break};try await Task.sleep(for:.milliseconds(25))};XCTAssertTrue(ready);guard ready else{return};try await Task.sleep(for:.milliseconds(500))
            var painted:UIImage?;for _ in 0..<4{let candidate=try await web.takeSnapshot(configuration:nil);if hasPaint(candidate){painted=candidate;break};try await Task.sleep(for:.milliseconds(200))};let source=XCTAttachment(image:try XCTUnwrap(painted));source.name="Source Story capture \(mode) \(state) \(language)";source.lifetime = .keepAlways;add(source)
            let geometry=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('button,.chakra-spinner,[aria-hidden=true]')].map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,disabled:e.disabled,x:r.x,y:r.y,w:r.width,h:r.height,color:s.color,bg:s.background,shadow:s.boxShadow,radius:s.borderRadius,opacity:s.opacity,fontSize:s.fontSize,lineHeight:s.lineHeight}}))"),metrics=XCTAttachment(data:Data((geometry as? String ?? "").utf8),uniformTypeIdentifier:"public.json");metrics.name="Source Story capture geometry \(mode) \(state) \(language)";metrics.lifetime = .keepAlways;add(metrics)
            let transport=RecordingPoseTransport(),recorder=SpeechPracticeService(transportFactory:{transport},permission:{true});defer{recorder.cancel()}
            if ["connecting","recording","evaluating"].contains(state){recorder.start(target:"es",policy:try FlashcardPolicy()){_ in};for _ in 0..<200 where !transport.ready{try await Task.sleep(for:.milliseconds(2))};if state != "connecting"{transport.onOpen?();if state == "evaluating"{recorder.stop()}else{try await Task.sleep(for:.milliseconds(100))}}}
            let native=UIWindow(windowScene:scene);native.frame=web.frame
            let root=StoryCapturePose(recorder:recorder,speaking:mode == "speaking",language:language,wrong:state == "wrong").frame(width:402,height:100).background(PiyaliBrand(dark:dark).background).environment(\.layoutDirection,dark ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(dark ? .dark:.light).ignoresSafeArea(),host=UIHostingController(rootView:root);native.rootViewController=host;native.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(500));let capture=XCTAttachment(image:UIGraphicsImageRenderer(bounds:native.bounds).image{_ in native.drawHierarchy(in:native.bounds,afterScreenUpdates:true)});capture.name="Native Story capture \(mode) \(state) \(language)";capture.lifetime = .keepAlways;add(capture);native.isHidden=true;native.rootViewController=nil
        }}}
    }
    private func hasPaint(_ image:UIImage)->Bool{guard let cg=image.cgImage,let context=CGContext(data:nil,width:32,height:32,bitsPerComponent:8,bytesPerRow:128,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)else{return false};context.draw(cg,in:CGRect(x:0,y:0,width:32,height:32));guard let data=context.data else{return false};let pixels=data.bindMemory(to:UInt32.self,capacity:1024);return Set((0..<1024).map{pixels[$0]}).count>2}
}
private struct StoryCapturePose:View{
    @ObservedObject var recorder:SpeechPracticeService
    let speaking:Bool,language:String,wrong:Bool
    private var copy:StoryAppearance{StoryCharacterAvatar.appearance}
    var body:some View{HStack(spacing:8){Button{}label:{StoryRecordLabel(recorder:recorder,speaking:speaking,record:copy.text("record",language:language),connecting:copy.text("connectingMic",language:language))}.buttonStyle(ActivityPrimaryButtonStyle(tone:wrong ? "stop":"speak")).disabled(recorder.connecting || recorder.evaluating)}.padding(.leading,52)}
}
