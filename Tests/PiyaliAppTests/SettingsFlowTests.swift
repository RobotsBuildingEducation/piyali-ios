import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor final class SettingsFlowTests:XCTestCase {
    private func model()throws->AppModel {guard SettingsFixture.enabled else{throw XCTSkip("Explicit isolated Settings fixture required")};let app=AppModel();try app.identity.create();app.signedIn=true;app.subscription.bind(app.identity);app.learner.onboardingComplete=true;SettingsFixture.seed(app);return app}
    func testVoicePersonaAutosavesAndSupportChangeLocalizesOnlyDefaults()async throws {
        let app=try model();defer{try? app.identity.disconnect()};let controller=SettingsPersonaController();controller.load(app)
        controller.change("A patient astronomer",app);try await Task.sleep(for:.milliseconds(500));XCTAssertEqual(app.learner.settingsSnapshot["progress"]["tutorVoicePersona"],.string("A patient astronomer"));XCTAssertTrue(controller.saved)
        app.settingsSupportLanguage("fr");XCTAssertEqual(app.learner.support,"fr");XCTAssertEqual(app.learner.settingsSnapshot["progress"]["tutorVoicePersona"],.string("A patient astronomer"))
        app.updateSettings(.object(["tutorVoicePersona":SettingsUI.run("persona",.object(["language":.string("en")]))["default"]]));app.settingsSupportLanguage("ar")
        XCTAssertEqual(app.learner.settingsSnapshot["progress"]["tutorVoicePersona"],SettingsUI.run("persona",.object(["language":.string("ar")]))["default"]);controller.close(app)
    }
    func testVoiceAndPauseAreNormalizedAndInvalidSwitchDoesNotReplaceIdentity()async throws {
        let app=try model();defer{try? app.identity.disconnect()};let account=app.identity.npub,xp=app.learner.totalXP
        app.updateSettings(.object(["tutorVoice":.string("ash"),"pauseMs":.number(850)]))
        XCTAssertEqual(app.learner.settingsSnapshot["progress"]["tutorVoice"],.string("Vindemiatrix"));XCTAssertEqual(app.learner.tutorPauseMilliseconds,900)
        let switched=await app.settingsSwitchAccount("npub1bad");XCTAssertFalse(switched);XCTAssertEqual(app.identity.npub,account);XCTAssertEqual(app.learner.totalXP,xp)
        app.updateSettings(.object(["soundEnabled":.bool(false),"allowPosts":.bool(false)]));XCTAssertFalse(app.learner.soundEffectsEnabled);XCTAssertFalse(app.learner.automaticPostsEnabled)
    }
}

extension SettingsFlowTests {
    func testAutomaticProgressPostingUsesConfirmedXPAndRespectsOptOutAndHydration()async throws {
        let app=try model();defer{try? app.identity.disconnect()};let relay=LocalNostrRelay();defer{relay.stop()}
        try await relay.start{frame,connection in if frame.first as? String == "EVENT",let event=frame[1] as? [String:Any],let id=event["id"] as? String{relay.send(["OK",id,true,""],to:connection)}}
        let service=CommunityFeedService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)))
        let observer=AutomaticProgressController(publish:{state,identity,author,xp,label in try await service.publish(state,identity:identity,expectedAuthor:author,totalXP:xp,languageLabel:label,refreshAfter:false)});defer{observer.reset()}
        var state=app.learner;state.changeSettings(.object(["allowPosts":.bool(true)]));observer.observe(state,identity:app.identity,locallyAllowed:true)
        try await Task.sleep(for:.milliseconds(100));XCTAssertTrue(relay.frames().isEmpty)
        state.award(5);observer.observe(state,identity:app.identity,locallyAllowed:true)
        for _ in 0..<100 where relay.frames().isEmpty{try await Task.sleep(for:.milliseconds(20))}
        let frames=relay.frames().filter{$0.first as? String == "EVENT"},raw=try XCTUnwrap(frames.first?[1] as? [String:Any]),event=try JSONDecoder().decode(NostrEventPayload.self,from:JSONSerialization.data(withJSONObject:raw))
        XCTAssertTrue(IdentityService.verify(event));XCTAssertEqual(event.kind,1);XCTAssertEqual(event.tag("total_xp"),String(state.subscriptionXP));XCTAssertTrue(event.content.contains("https://piyali.app"));XCTAssertFalse(event.content.contains(app.identity.exportKey()))
        observer.observe(state,identity:app.identity,locallyAllowed:true);state.award(5);observer.observe(state,identity:app.identity,locallyAllowed:false);try await Task.sleep(for:.milliseconds(150));XCTAssertEqual(relay.frames().filter{$0.first as? String == "EVENT"}.count,1)
    }
}


extension SettingsFlowTests {
    func testActualSourceSettingsAndNativeDrawerScreens()async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1" else{throw XCTSkip("Read-only source preview required")}
        let app=try model();defer{try? app.identity.disconnect()}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow}
        defer{old?.makeKey()}
        for (lang,theme) in [("en","light"),("ar","dark")] {for tab in ["settings","settings-voice","settings-lower","posts","account","subscription"] {
            let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent()
            let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:config),vc=UIViewController(),window=UIWindow(windowScene:scene);vc.view=web;window.frame=web.frame;window.rootViewController=vc;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-onboarding?screen=settings&language=\(lang)&theme=\(theme)&tutorRealtime=gemini"))))
            var ready=false;for _ in 0..<400 {ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && document.querySelectorAll('[role=tab]').length===3 && document.querySelectorAll('textarea').length===2")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))}
            XCTAssertTrue(ready,"Source Settings failed");guard ready else{return}
            if ["account","subscription"].contains(tab){_=try await web.evaluateJavaScript("document.querySelectorAll('[role=tab]')[\(tab == "account" ? 1:2)].click()");try await Task.sleep(for:.milliseconds(300))}
            try await Task.sleep(for:.milliseconds(300))
            if tab == "posts"{let label=String(data:try JSONEncoder().encode(EntryCopy.ui(lang,"allow_posts_info_aria")),encoding:.utf8)!;_=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(e=>e.getAttribute('aria-label')===\(label)).click()");try await Task.sleep(for:.milliseconds(300))}
            if tab == "settings-voice"{_=try await web.evaluateJavaScript("for(const panel of document.querySelectorAll('.chakra-modal__body, .chakra-tabs__tab-panels, [role=tabpanel]')){if(panel.scrollHeight>panel.clientHeight){panel.scrollTop=520}}");try await Task.sleep(for:.milliseconds(200))}
            if tab == "settings-lower"{_=try await web.evaluateJavaScript("for(const panel of document.querySelectorAll('.chakra-modal__body, .chakra-tabs__tab-panels, [role=tabpanel]')){panel.scrollTop=panel.scrollHeight}");try await Task.sleep(for:.milliseconds(200))}
            let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source Settings \(tab) \(lang)";source.lifetime = .keepAlways;add(source)
            let metrics=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('.chakra-modal__content,.chakra-modal__body,[role=tab],[role=tabpanel],p,button,textarea')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {text:e.textContent,x:r.x,y:r.y,width:r.width,height:r.height,font:s.font,padding:s.padding,bg:s.backgroundColor,border:s.borderColor,radius:s.borderRadius}}))")
            let geometry=XCTAttachment(data:Data(try XCTUnwrap(metrics as? String).utf8),uniformTypeIdentifier:"public.json");geometry.name="Source Settings \(tab) \(lang) geometry";geometry.lifetime = .keepAlways;add(geometry)
            web.stopLoading();window.isHidden=true;window.rootViewController=nil
            app.learner.support=lang;app.learner.name="Settings Learner";UserDefaults.standard.set(theme,forKey:"piyali.theme");app.learner.userSettings=app.learner.settingsSnapshot.setting("themeMode",.string(theme))
            let host=UIHostingController(rootView:ZStack{BrandBackground();SettingsDrawerView(onClose:{},onPlacement:{},initialTab:["settings-voice","settings-lower","posts"].contains(tab) ? "settings":tab,initialPostsInfo:tab == "posts")}.environmentObject(app).environment(\.layoutDirection,lang == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).ignoresSafeArea().preferredColorScheme(theme == "dark" ? .dark:.light));window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(500))
            if ["settings-voice","settings-lower"].contains(tab){func scrolls(_ view:UIView)->[UIScrollView]{(view as? UIScrollView).map{[$0]} ?? view.subviews.flatMap{scrolls($0)}};if let scroll=scrolls(host.view).first(where:{!($0 is UITextView) && $0.contentSize.height>$0.bounds.height}){scroll.setContentOffset(CGPoint(x:0,y:tab == "settings-voice" ? min(520,scroll.contentSize.height-scroll.bounds.height+scroll.adjustedContentInset.bottom):scroll.contentSize.height-scroll.bounds.height+scroll.adjustedContentInset.bottom),animated:false);try await Task.sleep(for:.milliseconds(200))}}
            let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native Settings \(tab) \(lang)";native.lifetime = .keepAlways;add(native)
            window.isHidden=true;window.rootViewController=nil
        }}
    }
}


extension SettingsFlowTests {
    func testDisplayNamePublishesOriginalMetadataThenSavesOnlyForItsAccount()async throws {
        let app=try model();defer{try? app.identity.disconnect()};let relay=LocalNostrRelay();defer{relay.stop()}
        try await relay.start{frame,connection in if frame.first as? String == "EVENT",let event=frame[1] as? [String:Any],let id=event["id"] as? String{relay.send(["OK",id,true,""],to:connection)}}
        let service=CommunityFeedService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2))),xp=app.learner.totalXP
        let saved=await app.settingsSaveDisplayName("  Settings Astronomer  ",publish:{name,identity,author in try await service.publishProfile(name:name,identity:identity,expectedAuthor:author)})
        XCTAssertTrue(saved);XCTAssertEqual(app.learner.name,"Settings Astronomer");XCTAssertEqual(app.learner.totalXP,xp)
        let raw=try XCTUnwrap(relay.frames().first{$0.first as? String == "EVENT"}?[1] as? [String:Any]),event=try JSONDecoder().decode(NostrEventPayload.self,from:JSONSerialization.data(withJSONObject:raw)),data=try JSONDecoder().decode(JSONValue.self,from:Data(event.content.utf8))
        XCTAssertTrue(IdentityService.verify(event));XCTAssertEqual(event.kind,0);XCTAssertEqual(data,.object(["name":.string("Settings Astronomer"),"about":.string("A student onboarded with Robots Building Education")]))
        let other=await app.settingsSaveDisplayName("Wrong account",publish:{_,_,_ in try app.identity.create()});XCTAssertFalse(other);XCTAssertEqual(app.learner.name,"Settings Astronomer")
        let failed=await app.settingsSaveDisplayName("Failed",publish:{_,_,_ in throw URLError(.notConnectedToInternet)});XCTAssertFalse(failed);XCTAssertEqual(app.learner.name,"Settings Astronomer")
    }
}
