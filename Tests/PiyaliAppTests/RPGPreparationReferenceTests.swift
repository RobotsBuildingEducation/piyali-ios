import XCTest
import SwiftUI
import SpriteKit
import WebKit
@testable import Piyali

@MainActor private final class PreparedReferenceNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class RPGPreparationReferenceTests:XCTestCase {
    func testOriginalPreparedChapterPromptAndReplyCaptions()async throws{
        let e=ProcessInfo.processInfo.environment
        guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated read-only source preview required")}
        let app=AppModel(progressService:PreparedReferenceNoCloud());try app.identity.create();defer{try? app.identity.disconnect()};app.subscription.bind(app.identity);app.learner=LearnerState();app.signedIn=true;app.learner.onboardingComplete=true
        let units=try ContentLibrary.load([String:[LearningUnit]].self,name:"curriculum-es"),lesson=try XCTUnwrap(units["Pre-A1"]?.flatMap(\.lessons).first{$0.id == "unit-pre-a1-people-game"}),scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for (support,theme) in [("en","light"),("ar","dark")]{
            app.learner.support=support
            let file=support == "ar" ? "rpg-prepared-fixture-ar":"rpg-prepared-fixture",raw=try String(contentsOf:XCTUnwrap(Bundle.main.url(forResource:file,withExtension:"json")),encoding:.utf8),directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),service=RPGService(cache:RPGPreparationCache(directory:directory),writer:{_ in raw});defer{try? FileManager.default.removeItem(at:directory)}
            await service.prepare(app,lesson:lesson,episode:nil,fresh:true);var run=try XCTUnwrap(app.learner.rpgRuns?["es"]);XCTAssertEqual(run.scenario.quest.steps.count,7)
            let npc=try XCTUnwrap(run.npc),path=try XCTUnwrap(run.world.path(from:run.position,to:RPGPoint(x:npc.tx,y:npc.ty))),window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874)
            defer{window.isHidden=true;window.rootViewController=nil}
            let web=WKWebView(frame:window.frame,configuration:WKWebViewConfiguration()),controller=UIViewController();controller.view=web;window.rootViewController=controller;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-rpg?prepared=1&language=\(support)&theme=\(theme)")!))
            var ready=false;for _ in 0..<400{ready=(try? await web.evaluateJavaScript("!!window.__piyaliRPGFixturePosition && document.fonts.status==='loaded'"))as?Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(ready);guard ready else{return};try await Task.sleep(for:.seconds(1))
            func touch(_ point:RPGPoint)async throws{
                _=try await web.evaluateJavaScript("(()=>{const p=window.__piyaliRPGFixturePosition,c=[...document.querySelectorAll('canvas')].find(c=>c.getBoundingClientRect().width>300),r=c.getBoundingClientRect(),s=r.height/10;c.dispatchEvent(new MouseEvent('click',{bubbles:true,clientX:r.left+r.width/2+(\(point.x)-p.x)*s,clientY:r.top+r.height/2+(\(point.y)-p.y+.12)*s}));})()")
                try await Task.sleep(for:.milliseconds(350))
            }
            for tile in path.dropFirst(){try await touch(tile)};try await touch(RPGPoint(x:npc.tx,y:npc.ty));try await Task.sleep(for:.seconds(1))
            let caption=try XCTUnwrap(run.node?.sceneLine),hasCaption=try await web.evaluateJavaScript("document.body.innerText.includes(\(quoted(caption)))");XCTAssertTrue(hasCaption as? Bool == true)
            for state in ["prompt","reply"]{
                if state == "reply"{_=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(b=>b.textContent.trim()==='A. Hola').click()");try await Task.sleep(for:.milliseconds(300))}
                let a=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));a.name="Source prepared \(state) \(support)";a.lifetime = .keepAlways;add(a)
            }
            web.stopLoading();window.isHidden=true;window.rootViewController=nil;run.position=try XCTUnwrap(path.last);app.learner.saveRPG(run)
            let host=UIHostingController(rootView:RPGView(lesson:lesson,episode:nil,embedded:true).environmentObject(app).environment(\.scenePhase,.active).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());window.rootViewController=host;window.makeKeyAndVisible();try await Task.sleep(for:.seconds(3))
            func find(_ view:UIView)->SKView?{if let value=view as? SKView{return value};return view.subviews.lazy.compactMap{find($0)}.first}
            let nativeScene=try XCTUnwrap(find(host.view)?.scene as? RPGWorldScene);nativeScene.onTile?(RPGPoint(x:npc.tx,y:npc.ty));try await Task.sleep(for:.milliseconds(300))
            for state in ["prompt","reply"]{
                if state == "reply"{app.learner.rpgRuns?["es"]?.choose(0);try await Task.sleep(for:.milliseconds(300))}
                let a=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});a.name="Native prepared \(state) \(support)";a.lifetime = .keepAlways;add(a)
            }
            window.isHidden=true;window.rootViewController=nil
        }
    }
    func testOwnedRecapStaysVisibleAtQuotaAndNewPresentationStartsFresh()async throws{
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated offline identity required")}
        let app=AppModel(progressService:PreparedReferenceNoCloud());try app.identity.create();defer{try? app.identity.disconnect()};app.subscription.bind(app.identity);app.learner=LearnerState();app.signedIn=true;app.learner.onboardingComplete=true
        let units=try ContentLibrary.load([String:[LearningUnit]].self,name:"curriculum-es"),lesson=try XCTUnwrap(units["Pre-A1"]?.flatMap(\.lessons).first{$0.id == "unit-pre-a1-people-game"}),raw=try String(contentsOf:XCTUnwrap(Bundle.main.url(forResource:"rpg-prepared-fixture",withExtension:"json")),encoding:.utf8),directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),service=RPGService(cache:RPGPreparationCache(directory:directory),writer:{_ in raw});defer{try? FileManager.default.removeItem(at:directory)}
        await service.prepare(app,lesson:lesson,episode:nil);var run=try XCTUnwrap(app.learner.rpgRuns?["es"]);run.stepIndex=run.scenario.quest.steps.count;app.learner.saveRPG(run)
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow},window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);defer{window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
        func host()->UIHostingController<some View>{UIHostingController(rootView:RPGView(lesson:lesson,episode:nil,embedded:true).environmentObject(app).environment(\.scenePhase,.active).ignoresSafeArea())}
        func find(_ view:UIView)->SKView?{if let v=view as? SKView{return v};return view.subviews.lazy.compactMap{find($0)}.first}
        window.rootViewController=host();window.makeKeyAndVisible();try await Task.sleep(for:.seconds(3));XCTAssertNotNil(find(window.rootViewController!.view))
        app.learner.rpgRuns?["es"]?.claimed=true;app.learner.xpByLanguage=["es":300];try await Task.sleep(for:.milliseconds(300));XCTAssertFalse(app.subscription.hasAccess);XCTAssertNotNil(find(window.rootViewController!.view),"Owned earned recap must remain visible through the trial boundary")
        window.isHidden=true;window.rootViewController=nil;try await Task.sleep(for:.milliseconds(100));window.rootViewController=host();window.makeKeyAndVisible();try await Task.sleep(for:.seconds(3));XCTAssertNil(find(window.rootViewController!.view),"A new gated game must not show the previously claimed recap")
        app.learner.xpByLanguage=["es":299];try await Task.sleep(for:.milliseconds(300));XCTAssertNotNil(find(window.rootViewController!.view));XCTAssertNotEqual(app.learner.rpgRuns?["es"]?.id,run.id);XCTAssertFalse(app.learner.rpgRuns?["es"]?.completed ?? true)
    }
    private func quoted(_ s:String)->String{String(data:try! JSONEncoder().encode(s),encoding:.utf8)!}
}
