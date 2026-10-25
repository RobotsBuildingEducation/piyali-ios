import XCTest
import SwiftUI
import SpriteKit
import WebKit
@testable import Piyali

@MainActor private final class ObjectPreviewNoCloud:LearnerProgressService {
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class RPGObjectReferenceTests:XCTestCase {
    func testActualSourceAndNativeBilingualObjectObservation()async throws {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Explicit read-only reference and isolated identity required")}
        let app=AppModel(progressService:ObjectPreviewNoCloud());try app.identity.create();defer{try? app.identity.disconnect()};app.signedIn=true;app.subscription.bind(app.identity);app.learner.onboardingComplete=true
        let units=try ContentLibrary.load([String:[LearningUnit]].self,name:"curriculum-es"),lesson=try XCTUnwrap(units["Pre-A1"]?.flatMap(\.lessons).first{$0.id == "unit-pre-a1-people-game"}),service=RPGService(),scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for(lang,theme)in [("en","light"),("ar","dark")] {
            app.learner.support=lang;await service.prepare(app,lesson:lesson,episode:nil,fresh:true);let run=try XCTUnwrap(app.learner.rpgRuns?["es"]),object=try XCTUnwrap(run.world.objects.first{$0.type == "counter"})
            let window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);let web=WKWebView(frame:window.frame,configuration:WKWebViewConfiguration()),controller=UIViewController();controller.view=web;window.rootViewController=controller;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-rpg?language=\(lang)&theme=\(theme)")!))
            var ready=false;for _ in 0..<400 {ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && [...document.querySelectorAll('canvas')].some(c=>c.getBoundingClientRect().width>300)"))as?Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(ready);guard ready else{return};try await Task.sleep(for:.seconds(2))
            let dx=object.tx-run.position.x,dy=object.ty-run.position.y
            _=try await web.evaluateJavaScript("(()=>{const c=[...document.querySelectorAll('canvas')].find(c=>c.getBoundingClientRect().width>300),r=c.getBoundingClientRect();c.dispatchEvent(new MouseEvent('click',{bubbles:true,clientX:r.left+r.width/2+\(dx)*r.height/10,clientY:r.top+r.height/2+(\(dy)+0.12)*r.height/10}));})()")
            var shown=false;for _ in 0..<40 {shown=(try? await web.evaluateJavaScript("document.body.innerText.includes('You notice counter.')"))as?Bool == true;if shown{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(shown,"Source object did not open");guard shown else{return}
            let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source RPG object \(lang)";source.lifetime = .keepAlways;add(source)
            let geometry=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('p')].filter(e=>e.textContent.includes('counter')||e.textContent.includes('كاونتر')).map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,x:r.x,y:r.y,width:r.width,height:r.height,fontSize:s.fontSize,lineHeight:s.lineHeight,color:s.color}}))")as?String ?? "[]";let metrics=XCTAttachment(data:Data(geometry.utf8),uniformTypeIdentifier:"public.json");metrics.name="Source RPG object \(lang) geometry";metrics.lifetime = .keepAlways;add(metrics)
            web.stopLoading();window.isHidden=true;window.rootViewController=nil
            let host=UIHostingController(rootView:RPGView(lesson:lesson,episode:nil,embedded:true).environmentObject(app).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());window.rootViewController=host;window.makeKeyAndVisible();try await Task.sleep(for:.seconds(2))
            func find(_ view:UIView)->SKView?{if let v=view as? SKView{return v};return view.subviews.lazy.compactMap{find($0)}.first}
            let nativeScene=try XCTUnwrap(find(host.view)?.scene as? RPGWorldScene);nativeScene.onTile?(RPGPoint(x:object.tx,y:object.ty));try await Task.sleep(for:.milliseconds(150))
            let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native RPG object \(lang)";native.lifetime = .keepAlways;add(native);window.isHidden=true;window.rootViewController=nil
        }
    }
}
