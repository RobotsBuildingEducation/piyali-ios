import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor private final class RPGScreenNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class RPGReferenceScreensTests:XCTestCase {
    func testBundledWorldAndCharacterArtHasEveryReferencedTexture()throws {
        let art=RPGArt.shared.data;XCTAssertEqual(art["worlds"].object.count,443);XCTAssertEqual(art["npcs"].array.count,46)
        var names:Set<String>=["RPGIconInventory","RPGIconQuest","RPGIconMusicOn","RPGIconMusicOff","RPGIconHelp",art["indicator"].string]
        for world in art["worlds"].object.values{names.insert(world["ground"].string);names.insert(world["grade"].string);for prop in world["props"].array{names.insert(prop["image"].string)}}
        for pet in art["pets"].object.values{for frames in pet.object.values{names.formUnion(frames.array.map(\.string))}}
        for npc in art["npcs"].array{names.insert(npc["image"].string)}
        for pet in CompanionTypes.ordered{for frame in 0..<6{names.insert("RPGPetPreview-\(pet)-\(frame)")}}
        for name in names{let url=try XCTUnwrap(Bundle.main.url(forResource:name,withExtension:"png"),name);let image=try XCTUnwrap(UIImage(contentsOfFile:url.path),name);XCTAssertGreaterThan(image.size.width,0,name)}
        XCTAssertNotNil(Bundle.main.url(forResource:"RPGWalk",withExtension:"mp3"))
    }
    func testActualSourceAndNativeWorldAndQuestScreens()async throws {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Read-only source preview and isolated identity required")}
        let app=AppModel(progressService:RPGScreenNoCloud());try app.identity.create();defer{try? app.identity.disconnect()};app.signedIn=true;app.subscription.bind(app.identity);app.learner.onboardingComplete=true;app.learner.target="es"
        let units=try ContentLibrary.load([String:[LearningUnit]].self,name:"curriculum-es"),lesson=try XCTUnwrap(units["Pre-A1"]?.flatMap(\.lessons).first{$0.id == "unit-pre-a1-people-game"}),service=RPGService()
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for(lang,theme)in [("en","light"),("ar","dark")] {
            app.learner.support=lang;await service.prepare(app,lesson:lesson,episode:nil,fresh:true)
            XCTAssertEqual(app.learner.rpgRuns?["es"]?.scenario.quest.steps.count,3)
            for state in ["world","quest","inventory","companion"]{
                let window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874)
                let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();config.userContentController.addUserScript(WKUserScript(source:"window.__rpgErrors=[];window.addEventListener('error',e=>window.__rpgErrors.push(e.message));window.addEventListener('unhandledrejection',e=>window.__rpgErrors.push(String(e.reason)))",injectionTime:.atDocumentStart,forMainFrameOnly:true));let web=WKWebView(frame:window.frame,configuration:config),sourceController=UIViewController();sourceController.view=web;window.rootViewController=sourceController;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
                defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
                web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-rpg?language=\(lang)&theme=\(theme)")!))
                let inventoryLabel=quoted(RPGArt.shared.copy("inventory",lang:lang))
                var ready=false
                for _ in 0..<400 {
                    ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && [...document.querySelectorAll('button')].some(b=>b.getAttribute('aria-label')===\(inventoryLabel))")) as? Bool == true
                    if ready{break};try await Task.sleep(for:.milliseconds(50))
                }
                let diagnostic=(try? await web.evaluateJavaScript("JSON.stringify({fonts:document.fonts.status,body:document.body.innerText.slice(0,500),errors:window.__rpgErrors})")) as? String ?? "No source diagnostics"
                XCTAssertTrue(ready,"Source game failed to mount \(lang) \(state): \(diagnostic)");guard ready else{return};try await Task.sleep(for:.seconds(2))
                if state != "world"{let label=state == "quest" ? RPGArt.shared.quest("button",lang:lang):state == "inventory" ? RPGArt.shared.copy("inventory",lang:lang):RPGArt.shared.data["customize"][lang]["gameCompanion"].string;_=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(b=>b.getAttribute('aria-label')===\(quoted(label))).click()");try await Task.sleep(for:.milliseconds(300))}
                let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source RPG \(state) \(lang)";source.lifetime = .keepAlways;add(source)
                let geometry=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('p,button,canvas,[role=dialog],.chakra-modal__header')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {text:e.textContent,aria:e.getAttribute('aria-label'),x:r.x,y:r.y,width:r.width,height:r.height,font:s.font,bg:s.backgroundColor,border:s.border,radius:s.borderRadius}}))") as? String ?? "[]"
                let metrics=XCTAttachment(data:Data(geometry.utf8),uniformTypeIdentifier:"public.json");metrics.name="Source RPG \(state) \(lang) geometry";metrics.lifetime = .keepAlways;add(metrics)
                window.isHidden=true;web.stopLoading();window.rootViewController=nil
                let host=UIHostingController(rootView:RPGView(lesson:lesson,episode:nil,embedded:true,initialPanel:state == "world" ? "":state).environmentObject(app).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.seconds(3))
                let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native RPG \(state) \(lang)";native.lifetime = .keepAlways;add(native);window.isHidden=true;window.rootViewController=nil
            }
        }
    }
    private func quoted(_ value:String)->String{String(data:try! JSONEncoder().encode(value),encoding:.utf8)!}
}
