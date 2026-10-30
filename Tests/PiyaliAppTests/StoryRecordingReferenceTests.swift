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
    func testOriginalCompactStoryFeedback()async throws{
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated source preview required")}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for language in["en","ar"]{for kind in["checkpoint","speaking","role"]{for correct in[false,true]{
            let dark=language == "ar",config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:config);web.scrollView.contentInsetAdjustmentBehavior = .never
            let window=UIWindow(windowScene:scene),vc=UIViewController();window.frame=web.frame;window.rootViewController=vc;vc.view.addSubview(web);window.makeKeyAndVisible();defer{window.isHidden=true;window.rootViewController=nil}
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-story-feedback?language=\(language)&kind=\(kind)&correct=\(correct ? 1:0)")!));var ready=false
            for _ in 0..<600{if(try? await web.evaluateJavaScript("window.__storyFeedbackReady===true"))as?Bool == true{ready=true;break};try await Task.sleep(for:.milliseconds(25))};XCTAssertTrue(ready);guard ready else{return};try await Task.sleep(for:.milliseconds(800))
            let metrics=try await web.evaluateJavaScript("JSON.stringify({height:document.querySelector('[data-source-story-feedback]').getBoundingClientRect().height,text:document.querySelector('[data-source-story-feedback]').innerText,controls:[...document.querySelectorAll('button,[data-activity-feedback-content],[role=progressbar],[role=status],p,[data-positive-feedback-character]')].map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return{x:r.x,y:r.y,w:r.width,h:r.height,text:e.innerText,color:s.color,bg:s.background,font:s.fontSize,weight:s.fontWeight,lineHeight:s.lineHeight,marginTop:s.marginTop,marginBottom:s.marginBottom}})})"),data=Data((metrics as? String ?? "").utf8),values=try JSONDecoder().decode(JSONValue.self,from:data),height=max(120,ceil(values["height"].number)+8),state=correct ? "correct":"wrong",name="\(kind) \(state) \(language)"
            XCTAssertFalse(values["text"].string.contains("This correct explanation"));let geometry=XCTAttachment(data:data,uniformTypeIdentifier:"public.json");geometry.name="Source Story feedback geometry "+name;geometry.lifetime = .keepAlways;add(geometry)
            let snap=WKSnapshotConfiguration();snap.rect=CGRect(x:0,y:0,width:402,height:height);var sourceImage:UIImage?;for _ in 0..<4{let image=try await web.takeSnapshot(configuration:snap);if hasPaint(image){sourceImage=image;break};try await Task.sleep(for:.milliseconds(200))};let source=XCTAttachment(image:try XCTUnwrap(sourceImage));source.name="Source Story feedback "+name;source.lifetime = .keepAlways;add(source)
            let copy=StoryCharacterAvatar.appearance,ui:(String)->String={EntryCopy.ui(language,$0)},label=kind == "speaking" ? ui(correct ? "story_well_done":"story_almost"):copy.text(correct ? "correct":kind == "role" ? "speechIncorrect":"incorrect",language:language),tips=try StoryFeedbackPolicy().tips(["low-char-sim","low-word-f1"],language:language,targetLabel:ui("language_es")),explanation=correct ? "":kind == "checkpoint" ? "His mother\n\nThe flowers are for his mother.":tips.joined(separator:kind == "speaking" ? " ":"\n\n"),showNext=kind != "speaking" || correct,percent=correct ? (kind == "role" ? 17:33):0
            let root=ActivityFooterSurface(showsActions:showNext,hasFeedback:true,feedback:{StoryFeedbackView(correct:correct,label:label,subtext:kind == "speaking" && correct ? ui("story_score")+": 95%":"",explanation:explanation,progress:percent,progressLabel:ui("story_progress"),xp:kind == "speaking" && correct ? 2:0,portrait:7,speaking:kind != "checkpoint")},actions:{Button{}label:{HStack(spacing:8){Text(kind == "speaking" ? ui("stories_next_sentence"):copy.text(kind == "checkpoint" || correct ? "next":"retry",language:language));PracticeIcon(name:"FiArrowRight",size:14)}}.buttonStyle(ActivityPrimaryButtonStyle(tone:correct ? "success":"stop"))}).frame(width:402).frame(height:height,alignment:.top).background(PiyaliBrand(dark:dark).background).environment(\.layoutDirection,dark ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(dark ? .dark:.light).ignoresSafeArea()
            let native=UIWindow(windowScene:scene);native.frame=CGRect(x:0,y:0,width:402,height:height);let host=UIHostingController(rootView:root);native.rootViewController=host;native.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(500));let image=XCTAttachment(image:UIGraphicsImageRenderer(bounds:native.bounds).image{_ in native.drawHierarchy(in:native.bounds,afterScreenUpdates:true)});image.name="Native Story feedback "+name;image.lifetime = .keepAlways;add(image);native.isHidden=true;native.rootViewController=nil
        }}}
    }
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
