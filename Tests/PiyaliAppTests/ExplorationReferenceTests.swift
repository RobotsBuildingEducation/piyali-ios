import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor private final class ExplorationNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class ExplorationReferenceTests:XCTestCase {
    func testEveryLegacyRoomAndItemUsesAnOriginalBundledTexture()throws {
        let library=try ContentLibrary.load(ExplorationLibrary.self,name:"exploration"),art=RPGArt.shared
        XCTAssertEqual(library.templates.count,224);XCTAssertEqual(art.exploration["worlds"].object.count,448)
        var names=Set<String>()
        for template in library.templates {for area in template.maps {
            let key=try XCTUnwrap(art.explorationKey(area)),world=art.world(key)
            XCTAssertNotEqual(world,.null);names.insert(world["ground"].string);names.insert(world["grade"].string)
            for prop in world["props"].array{names.insert(prop["image"].string)}
            // Restoring an existing save without the new optional key still resolves its exact geometry.
            var legacy=area;legacy.worldKey=nil;XCTAssertEqual(art.explorationKey(legacy),key)
        };for item in template.quest["gatherData"]["all"].array{let name=art.itemImage(item);XCTAssertFalse(name.isEmpty);names.insert(name)}}
        for name in names {let url=try XCTUnwrap(Bundle.main.url(forResource:name,withExtension:"png"),name);XCTAssertNotNil(UIImage(contentsOfFile:url.path),name)}
    }
    func testSceneDistinguishesConnectedRoomsThatShareGeometry()throws {
        let library=try ContentLibrary.load(RPGLibrary.self,name:"rpg-es"),scenario=try XCTUnwrap(library.scenarios(level:"Pre-A1",support:"en").first),world=try XCTUnwrap(library.worlds[scenario.worldKey]);var run=RPGRun(target:"es",support:"en",lessonID:nil,xpReward:0,scenario:scenario,world:world)
        let scene=RPGWorldScene(size:.init(width:402,height:874));scene.configure(run,pet:"ghost",size:.init(width:402,height:874));let before=scene.npcPositions;XCTAssertFalse(before.isEmpty)
        var data=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(scenario)),npcs=data["npcs"].array;let open=try XCTUnwrap((0..<world.height).flatMap{y in (0..<world.width).map{RPGPoint(x:$0,y:y)}}.first{world.walkable($0) && $0.x != scenario.npcs[0].tx && $0.y != scenario.npcs[0].ty});npcs[0]=npcs[0].setting("tx",.number(Double(open.x))).setting("ty",.number(Double(open.y)));data=data.setting("id",.string(scenario.id+"-connected-room")).setting("npcs",.array(npcs));run.scenario=try JSONDecoder().decode(RPGScenario.self,from:Data(data.json.utf8))
        scene.configure(run,pet:"ghost",size:.init(width:402,height:874));XCTAssertNotEqual(scene.npcPositions.first,before.first);XCTAssertEqual(scene.npcPositions.count,before.count)
    }
    func testActualLegacyWorldSearchDialogueAndCollectedInventoryInEnglishAndArabic()async throws {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else {throw XCTSkip("Isolated public source fixture required")}
        let app=AppModel(progressService:ExplorationNoCloud());try app.identity.create();defer{try? app.identity.disconnect()};app.signedIn=true;app.subscription.bind(app.identity);app.learner.onboardingComplete=true;app.learner.target="es";app.learner.level="A2"
        let library=try ContentLibrary.load(ExplorationLibrary.self,name:"exploration"),base=try XCTUnwrap(library.templates.first{$0.baseLanguage == "es" && $0.level == "A2" && $0.theme == "home" && $0.quest["steps"].array.contains{$0["nodes"].array.contains{$0["responseMode"].string == "gather"}}})
        var data=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(base)),steps=data["quest"]["steps"].array
        let stepIndex=try XCTUnwrap(steps.firstIndex{$0["nodes"].array.contains{$0["responseMode"].string == "gather"}}),nodeIndex=try XCTUnwrap(steps[stepIndex]["nodes"].array.firstIndex{$0["responseMode"].string == "gather"})
        var nodes=Array(steps[stepIndex]["nodes"].array.dropFirst(nodeIndex));nodes[0]=nodes[0].setting("responseMode",.string("objectSearch"));steps[stepIndex]=steps[stepIndex].setting("nodes",.array(nodes));steps=Array(steps.dropFirst(stepIndex));let npcIndex=Int(steps[0]["npcIdx"].number)
        data=data.setting("quest",data["quest"].setting("steps",.array(steps))).setting("startMapId",base.npcs[npcIndex]["mapId"])
        let template=try JSONDecoder().decode(ExplorationTemplate.self,from:Data(data.json.utf8)),scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for (language,theme) in [("en","light"),("ar","dark")] {
            app.learner.support=language
            for state in ["world","dialogue","inventory"] {
                var run=try ExplorationRun(target:"es",support:language,scenario:template)
                let window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874)
                let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();config.userContentController.addUserScript(WKUserScript(source:"window.__legacyErrors=[];window.addEventListener('error',e=>window.__legacyErrors.push(e.message));window.addEventListener('unhandledrejection',e=>window.__legacyErrors.push(String(e.reason)))",injectionTime:.atDocumentStart,forMainFrameOnly:true))
                let web=WKWebView(frame:window.frame,configuration:config),controller=UIViewController();controller.view=web;window.rootViewController=controller;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
                defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
                web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-rpg?legacy=search&language=\(language)&theme=\(theme)")!))
                func wait(_ js:String)async throws {var ready=false;for _ in 0..<400{ready=(try? await web.evaluateJavaScript(js))as?Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};let diagnostic=(try? await web.evaluateJavaScript("JSON.stringify({body:document.body.innerText.slice(0,800),errors:window.__legacyErrors})"))as?String ?? "No diagnostics";XCTAssertTrue(ready,diagnostic);if !ready{throw URLError(.cannotParseResponse)}}
                try await wait("!!window.__piyaliRPGFixturePosition && document.fonts.status==='loaded'");try await Task.sleep(for:.seconds(1))
                let sourceX=(try await web.evaluateJavaScript("window.__piyaliRPGFixturePosition.x"))as?Int,sourceY=(try await web.evaluateJavaScript("window.__piyaliRPGFixturePosition.y"))as?Int;XCTAssertEqual(sourceX,run.position.x);XCTAssertEqual(sourceY,run.position.y)
                func touch(_ point:RPGPoint)async throws {_=try await web.evaluateJavaScript("(()=>{const p=window.__piyaliRPGFixturePosition,c=[...document.querySelectorAll('canvas')].find(c=>c.getBoundingClientRect().width>300),r=c.getBoundingClientRect(),s=r.height/10;c.dispatchEvent(new MouseEvent('click',{bubbles:true,clientX:r.left+r.width/2+(\(point.x)-p.x)*s,clientY:r.top+r.height/2+(\(point.y)-p.y+.12)*s}));})()");try await Task.sleep(for:.milliseconds(300))}
                if state != "world" {
                    let point=ExplorationTemplate.position(run.npc),path=try XCTUnwrap(run.area?.world.path(from:run.position,to:point))
                    for tile in path.dropFirst(){try await touch(tile)};try await touch(point)
                    try await wait("document.body.innerText.includes(\(quote(RPGArt.shared.searchCopy("continueSearching",lang:language))))")
                    XCTAssertTrue(run.approach(point));XCTAssertTrue(run.talk())
                    if state == "inventory" {
                        _=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(b=>b.getAttribute('aria-label')===\(quote(RPGArt.shared.copy("closeDialogue",lang:language)))).click()")
                        run.talking=false
                        let area=try XCTUnwrap(run.area),routes=area.world.objects.enumerated().compactMap{index,object->(Int,[RPGPoint])? in guard let path=area.world.path(from:run.position,to:.init(x:object.tx,y:object.ty)),path.allSatisfy({tile in !area.portals.contains{ExplorationTemplate.position($0)==tile} && !run.scenario.npcs.contains{$0["mapId"].string == run.mapID && ExplorationTemplate.position($0)==tile}}) else{return nil};return(index,path)}.sorted{$0.1.count<$1.1.count},route=try XCTUnwrap(routes.first),index=route.0,object=area.world.objects[index]
                        for tile in route.1.dropFirst(){try await touch(tile)};run.position=try XCTUnwrap(route.1.last)
                        try await touch(.init(x:object.tx,y:object.ty));XCTAssertTrue(run.examine(index));XCTAssertEqual(run.inventory.count,1)
                        _=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(b=>b.getAttribute('aria-label')===\(quote(RPGArt.shared.copy("inventory",lang:language)))).click()")
                        try await wait("!!document.querySelector('[role=dialog] img')");try await Task.sleep(for:.milliseconds(800))
                        let count=(try? await web.evaluateJavaScript("document.querySelectorAll('[role=dialog] img').length"))as?Int;XCTAssertEqual(count,1)
                    }
                }
                let errors=(try? await web.evaluateJavaScript("window.__legacyErrors"))as?[String] ?? [];XCTAssertEqual(errors,[])
                if state == "dialogue"{try await Task.sleep(for:.seconds(4))}
                let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source legacy \(state) \(language)";source.lifetime = .keepAlways;add(source)
                let geometry=(try? await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('p,button,[role=dialog]')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {text:e.textContent,aria:e.getAttribute('aria-label'),x:r.x,y:r.y,width:r.width,height:r.height,font:s.font,bg:s.backgroundColor}}))"))as?String ?? "[]",metrics=XCTAttachment(data:Data(geometry.utf8),uniformTypeIdentifier:"public.json");metrics.name="Source legacy \(state) \(language) metrics";metrics.lifetime = .keepAlways;add(metrics)
                web.stopLoading();window.isHidden=true;window.rootViewController=nil;app.learner.saveExploration(run)
                let host=UIHostingController(rootView:ExplorationView(embedded:true,initialPanel:state == "inventory" ? "inventory":"").environmentObject(app).environment(\.scenePhase,.active).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.seconds(state == "dialogue" ? 4:2))
                if state == "dialogue"{func labels(_ view:UIView)->[RPGDialogueLabel]{(view as? RPGDialogueLabel).map{[$0]} ?? view.subviews.flatMap{labels($0)}};let label=try XCTUnwrap(labels(host.view).first{$0.accessibilityLabel?.contains("el libro antiguo") == true});let frame=label.convert(label.bounds,to:window);XCTAssertGreaterThan(frame.height,40);XCTAssertLessThanOrEqual(frame.maxY,window.bounds.height-16,"Dialogue must be visible inside its scroll viewport");let visible=try XCTUnwrap(sequence(first:label.superview,next:{$0?.superview}).compactMap{$0 as? UIScrollView}.first);let inScroll=label.convert(label.bounds,to:visible);XCTAssertLessThanOrEqual(inScroll.maxY,visible.bounds.maxY,"Fitting search dialogue must not be clipped below the viewport")}
                let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native legacy \(state) \(language)";native.lifetime = .keepAlways;add(native);window.isHidden=true;window.rootViewController=nil
                XCTAssertEqual(app.learner.totalXP,0)
            }
        }
    }
    private func quote(_ string:String)->String {String(data:try! JSONEncoder().encode(string),encoding:.utf8)!}
}
