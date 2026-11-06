import XCTest
import SwiftUI
import SpriteKit
import WebKit
@testable import Piyali

@MainActor private final class DialogueReferenceNoCloud:LearnerProgressService{
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class RPGDialogueReferenceTests:XCTestCase{
    private func quote(_ s:String)->String{String(data:try! JSONEncoder().encode(s),encoding:.utf8)!}
    func testActualSourceAndNativeStreamingUndoFailureAndPartialTranslations()async throws{
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Read-only source preview and isolated identity required")}
        let app=AppModel(progressService:DialogueReferenceNoCloud());try app.identity.create();defer{try? app.identity.disconnect()};app.subscription.bind(app.identity);app.learner=LearnerState();app.signedIn=true;app.learner.onboardingComplete=true
        let units=try ContentLibrary.load([String:[LearningUnit]].self,name:"curriculum-es"),lesson=try XCTUnwrap(units["Pre-A1"]?.flatMap(\.lessons).first{$0.id == "unit-pre-a1-people-game"}),scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        let fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:try XCTUnwrap(Bundle.main.url(forResource:"rpg-dialogue-fixture",withExtension:"json"))))
        for (support,theme) in [("en","light"),("ar","dark")]{
            app.learner.support=support;let raw=try String(contentsOf:XCTUnwrap(Bundle.main.url(forResource:support == "ar" ? "rpg-prepared-fixture-ar":"rpg-prepared-fixture",withExtension:"json")),encoding:.utf8),directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),preparation=RPGService(cache:RPGPreparationCache(directory:directory),writer:{_ in raw});defer{try? FileManager.default.removeItem(at:directory)}
            await preparation.prepare(app,lesson:lesson,episode:nil,fresh:true);var run=try XCTUnwrap(app.learner.rpgRuns?["es"]);let before=run,npc=try XCTUnwrap(run.npc),path=try XCTUnwrap(run.world.path(from:run.position,to:.init(x:npc.tx,y:npc.ty))),window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);defer{window.isHidden=true;window.rootViewController=nil}
            let web=WKWebView(frame:window.frame,configuration:WKWebViewConfiguration()),controller=UIViewController();controller.view=web;window.rootViewController=controller;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-rpg?prepared=1&language=\(support)&theme=\(theme)")!))
            func waitWeb(_ expression:String)async throws{var ok=false;for _ in 0..<400{ok=(try? await web.evaluateJavaScript(expression))as?Bool == true;if ok{break};try await Task.sleep(for:.milliseconds(25))};XCTAssertTrue(ok,expression)}
            try await waitWeb("!!window.__piyaliRPGFixturePosition && document.fonts.status==='loaded'");try await Task.sleep(for:.seconds(1))
            func touch(_ point:RPGPoint)async throws{_=try await web.evaluateJavaScript("(()=>{const p=window.__piyaliRPGFixturePosition,c=[...document.querySelectorAll('canvas')].find(c=>c.getBoundingClientRect().width>300),r=c.getBoundingClientRect(),s=r.height/10;c.dispatchEvent(new MouseEvent('click',{bubbles:true,clientX:r.left+r.width/2+(\(point.x)-p.x)*s,clientY:r.top+r.height/2+(\(point.y)-p.y+.12)*s}));})()");try await Task.sleep(for:.milliseconds(350))}
            for tile in path.dropFirst(){try await touch(tile)};try await touch(.init(x:npc.tx,y:npc.ty));try await Task.sleep(for:.seconds(1))
            let translate=quote(RPGArt.shared.copy("translateText",lang:support)),undo=quote(RPGArt.shared.copy("undoTranslation",lang:support))
            func click(_ label:String)async throws{_=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(b=>b.getAttribute('aria-label')===\(label)).click()")}
            func sourceShot(_ state:String)async throws{let a=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));a.name="Source dialogue \(state) \(support)";a.lifetime = .keepAlways;add(a)}
            _=try await web.evaluateJavaScript("window.__piyaliRPGTranslationMode='complete'");try await click(translate);try await waitWeb("[...document.querySelectorAll('button')].some(b=>b.getAttribute('aria-label')===\(undo)&&!b.disabled)");try await sourceShot("translated")
            try await click(undo);try await Task.sleep(for:.seconds(1));try await sourceShot("undo")
            _=try await web.evaluateJavaScript("window.__piyaliRPGTranslationMode='partial'");try await click(translate);try await waitWeb("typeof window.__piyaliRPGTranslationRelease==='function'");try await sourceShot("partial")
            _=try await web.evaluateJavaScript("window.__piyaliRPGTranslationRelease();window.__piyaliRPGTranslationRelease=null");try await waitWeb("[...document.querySelectorAll('button')].some(b=>b.getAttribute('aria-label')===\(undo)&&!b.disabled)");try await click(undo)
            _=try await web.evaluateJavaScript("window.__piyaliRPGTranslationMode='failure'");try await click(translate);try await waitWeb("[...document.querySelectorAll('button')].some(b=>b.getAttribute('aria-label')===\(translate)&&!b.disabled)");try await Task.sleep(for:.seconds(1));try await sourceShot("failure")
            web.stopLoading();window.isHidden=true;window.rootViewController=nil
            run.position=try XCTUnwrap(path.last);app.learner.saveRPG(run);let translations=RPGTranslationController();var mode="complete",release:CheckedContinuation<Void,Never>?
            let provider=RPGTranslationProvider(stream:{prompt,update in
                let entries=prompt.components(separatedBy:"\nEntries:\n").last!.components(separatedBy:.newlines),table=fixture[support]
                let lines=entries.enumerated().map{i,entry in let text=entry.replacingOccurrences(of:"^\\d+\\. ",with:"",options:.regularExpression);return "\(i+1). "+(table[text].string.isEmpty ? text:table[text].string)}
                update(lines[0]+"\n");if mode == "partial"{await withCheckedContinuation{release=$0}};if mode == "failure"{throw URLError(.networkConnectionLost)};update(lines.dropFirst().joined(separator:"\n"))
            })
            let host=UIHostingController(rootView:RPGView(lesson:lesson,episode:nil,embedded:true,translationController:translations,translationProvider:provider).environmentObject(app).environment(\.scenePhase,.active).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());window.rootViewController=host;window.makeKeyAndVisible();try await Task.sleep(for:.seconds(3))
            func find(_ view:UIView)->SKView?{if let v=view as? SKView{return v};return view.subviews.lazy.compactMap{find($0)}.first}
            let nativeScene=try XCTUnwrap(find(host.view)?.scene as? RPGWorldScene);nativeScene.onTile?(.init(x:npc.tx,y:npc.ty));try await Task.sleep(for:.milliseconds(300))
            func waitNative(_ done:()->Bool)async throws{for _ in 0..<200 where !done(){try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(done())}
            func nativeShot(_ state:String){let a=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});a.name="Native dialogue \(state) \(support)";a.lifetime = .keepAlways;add(a)}
            translations.toggle(provider:provider);try await waitNative{!translations.busy};XCTAssertEqual(translations.lines?.count,3);nativeShot("translated")
            translations.toggle(provider:provider);try await Task.sleep(for:.seconds(1));nativeShot("undo")
            mode="partial";translations.toggle(provider:provider);try await waitNative{release != nil};nativeShot("partial");release?.resume();release=nil;try await waitNative{!translations.busy};translations.toggle(provider:provider)
            mode="failure";translations.toggle(provider:provider);try await waitNative{!translations.busy};XCTAssertFalse(translations.active);try await Task.sleep(for:.seconds(1));nativeShot("failure")
            let after=try XCTUnwrap(app.learner.rpgRuns?["es"]);XCTAssertEqual(after.stepIndex,before.stepIndex);XCTAssertEqual(after.score,before.score);XCTAssertEqual(after.attempts,before.attempts);XCTAssertEqual(app.learner.totalXP,0)
            translations.reset();window.isHidden=true;window.rootViewController=nil
        }
    }
}
