import XCTest
import SpriteKit
import SwiftUI
import WebKit
@testable import Piyali

@MainActor final class RPGEnvironmentSceneTests:XCTestCase {
    private func run(_ episode:String)throws->RPGRun{
        let library=try ContentLibrary.load(RPGLibrary.self,name:"rpg-es"),scenario=try XCTUnwrap(library.scenarios(level:"Pre-A1",support:"en").first{$0.authoredEpisode.id == episode})
        return RPGRun(target:"es",support:"en",lessonID:nil,xpReward:0,scenario:scenario,world:try XCTUnwrap(library.worlds[scenario.worldKey]))
    }
    func testBundledEnvironmentResourcesAndAnimationKeepNPCsAnchored()throws{
        let library=try XCTUnwrap(RPGArt.shared.environment)
        var names=Set(library.textures)
        for plan in library.plans.values{names.insert(plan.grade);names.formUnion(plan.layers.map(\.image))}
        for directions in library.pets.values{for frames in directions.values{names.formUnion(frames)}}
        for name in names{let url=try XCTUnwrap(Bundle.main.url(forResource:name,withExtension:"png"),name);XCTAssertNotNil(UIImage(contentsOfFile:url.path),name)}
        var run=try run("partyPrep");let before=run,scene=RPGWorldScene(size:CGSize(width:402,height:874));scene.configure(run,pet:"dog",size:scene.size)
        let plan=try XCTUnwrap(library.plan(run.scenario));XCTAssertEqual(scene.environmentLayerCount,plan.layers.count);XCTAssertGreaterThan(scene.movingEnvironmentLayerCount,18)
        let anchors=scene.npcPositions;scene.update(100);let positions=scene.environmentPositions,standing=scene.displayedPlayerImage
        scene.update(101);XCTAssertNotEqual(scene.environmentPositions,positions);XCTAssertEqual(scene.npcPositions,anchors);XCTAssertEqual(scene.displayedPlayerImage,standing);XCTAssertEqual(run,before)
        let neighbors=[(0,1),(1,0),(0,-1),(-1,0)].map{RPGPoint(x:run.position.x+$0.0,y:run.position.y+$0.1)}
        let tile=try XCTUnwrap(neighbors.first{tile in run.world.walkable(tile) && !run.scenario.npcs.contains(where:{$0.tx == tile.x && $0.ty == tile.y})})
        run.position=tile;scene.configure(run,pet:"dog",size:scene.size);XCTAssertNotEqual(scene.displayedPlayerImage,standing)
        scene.update(101.14);scene.update(101.54)
        let expected=library.frames(pet:"dog",direction:tile.y<before.position.y ? "up":tile.y>before.position.y ? "down":tile.x<before.position.x ? "left":"right")[0]
        XCTAssertEqual(scene.displayedPlayerImage,expected);XCTAssertEqual(scene.npcPositions,anchors)
        scene.configure(run,pet:"ghost",size:scene.size);let ghost=scene.displayedPlayerImage;for i in 1...14{scene.update(102+Double(i)*0.14)};XCTAssertNotEqual(scene.displayedPlayerImage,ghost)
    }
    func testActualMainRendererAndNativeEnvironmentAtControlledTimes()async throws{
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1" else{throw XCTSkip("Read-only reference preview required")}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for episode in ["marketRush","partyPrep"]{
            let run=try run(episode),window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874)
            defer{window.isHidden=true;window.rootViewController=nil}
            for time in [0.0,15.321]{
                let web=WKWebView(frame:window.frame,configuration:WKWebViewConfiguration()),controller=UIViewController();controller.view=web;window.rootViewController=controller;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
                web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-rpg?episode=\(episode)&environmentTime=\(time)&environmentOnly=1")!))
                var ready=false;for _ in 0..<400{ready=(try? await web.evaluateJavaScript("[...document.querySelectorAll('canvas')].some(c=>c.getBoundingClientRect().width>300)"))as?Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(ready);guard ready else{return}
                _=try await web.evaluateJavaScript("(()=>{const s=document.createElement('style');s.textContent='body * {visibility:hidden!important} canvas[data-environment] {visibility:visible!important}';document.head.append(s);[...document.querySelectorAll('canvas')].find(c=>c.getBoundingClientRect().width>300).setAttribute('data-environment','1');})()")
                try await Task.sleep(for:.seconds(2));let sourcePosition=try await web.evaluateJavaScript("window.__piyaliEnvironmentPosition") as? [String:Int];XCTAssertEqual(sourcePosition?["x"],run.position.x);XCTAssertEqual(sourcePosition?["y"],run.position.y);let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source environment \(episode) \(time)";source.lifetime = .keepAlways;add(source)
                web.stopLoading();window.isHidden=true;window.rootViewController=nil
                let host=UIHostingController(rootView:RPGWorldView(run:run,pet:"ghost",environmentTime:time,actorsVisible:false,onTile:{_ in}).environment(\.scenePhase,.active).ignoresSafeArea());window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.seconds(1))
                let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native environment \(episode) \(time)";native.lifetime = .keepAlways;add(native);window.isHidden=true;window.rootViewController=nil
            }
        }
    }

    func testLegacyPlazaMatchesTheOriginalLightAndMotePositions()async throws {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1"
        else { throw XCTSkip("Read-only reference preview required") }
        let library=try ContentLibrary.load(IntroLibrary.self,name:"intro-es")
        let lesson=try XCTUnwrap(library.units["Pre-A1"]?.lessons.first)
        let input:JSONValue = .object(["lesson":try RPGPreparationPolicy.value(lesson).setting("isTutorial",.bool(true)),
                                       "target":.string("es"),"support":.string("en"),"user":.object([:])])
        let plaza=try await TutorialPlazaPolicy().generate(input) { _ in "" }
        let world=try XCTUnwrap(plaza.maps.first?.world)
        let terrain=TutorialTerrain(definitions:try XCTUnwrap(plaza.tileDefinitions),seed:1792936800000)
        let scenario=RPGScenario(id:plaza.id,name:plaza.name,emoji:"",npcs:[],
                                 quest:RPGQuest(title:"",intro:"",storySeed:"",steps:[]),
                                 authoredEpisode:RPGEpisode(id:"legacy",level:"Pre-A1",maxBaseScore:0,unitGrounded:false),worldKey:"tutorialPlaza")
        var run=RPGRun(target:"es",support:"en",lessonID:nil,xpReward:0,scenario:scenario,world:world)
        // Exploration retains the saved tile when it adapts to RPGWorldView.
        run.position=world.start
        let windowScene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let old=windowScene.windows.first { $0.isKeyWindow }
        let window=UIWindow(windowScene:windowScene)
        window.frame=CGRect(x:0,y:0,width:402,height:874)
        defer { window.isHidden=true;window.rootViewController=nil;old?.makeKey() }
        let nativeScene=RPGWorldScene(size:window.bounds.size)

        for time in [0.0,15.321] {
            let web=WKWebView(frame:window.bounds),controller=UIViewController()
            controller.view=web
            window.rootViewController=controller
            window.makeKeyAndVisible()
            web.scrollView.contentInsetAdjustmentBehavior = .never
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-rpg?legacy=plaza&environmentTime=\(time)&environmentOnly=1")!))
            var sourceLayers:[[String:Double]]=[]
            for _ in 0..<320 {
                sourceLayers=(try? await web.evaluateJavaScript("window.__piyaliPlazaLayers")) as? [[String:Double]] ?? []
                if !sourceLayers.isEmpty { break }
                try await Task.sleep(for:.milliseconds(50))
            }
            guard sourceLayers.count == 22 else { return XCTFail("The original scene should draw four pools and 18 motes") }
            let sourcePosition=try await web.evaluateJavaScript("window.__piyaliEnvironmentPosition") as? [String:Int]
            XCTAssertEqual(sourcePosition?["x"],run.position.x)
            XCTAssertEqual(sourcePosition?["y"],run.position.y)
            nativeScene.configure(run,pet:"ghost",size:window.bounds.size,environmentTime:time,actorsVisible:false,tutorialTerrain:terrain)
            let grade=try XCTUnwrap(nativeScene.camera?.childNode(withName:"grade") as? SKSpriteNode)
            XCTAssertEqual(grade.size,window.bounds.size)
            let nativeLayers=nativeScene.children.filter { $0.zPosition == 55 || $0.zPosition == 940 }
            XCTAssertEqual(nativeLayers.count,sourceLayers.count)
            // SpriteKit stores node coordinates at Float precision.
            for (node,source) in zip(nativeLayers,sourceLayers) {
                XCTAssertEqual(node.position.x,CGFloat(try XCTUnwrap(source["x"])),accuracy:0.0001)
                XCTAssertEqual(node.position.y,CGFloat(try XCTUnwrap(source["y"])),accuracy:0.0001)
                XCTAssertEqual(node.alpha,CGFloat(try XCTUnwrap(source["alpha"])),accuracy:0.000001)
            }
            _=try await web.evaluateJavaScript("""
                (()=>{const s=document.createElement('style');s.textContent='body{background:#fff9ef!important} body * {visibility:hidden!important} canvas[data-environment] {visibility:visible!important}';document.head.append(s);[...document.querySelectorAll('canvas')].find(c=>c.getBoundingClientRect().width>300).setAttribute('data-environment','1');})()
                """)
            try await Task.sleep(for:.milliseconds(450))
            let sourceImage=XCTAttachment(image:try await web.takeSnapshot(configuration:nil))
            sourceImage.name="Source Greeting Plaza atmosphere \(time)"
            sourceImage.lifetime = .keepAlways
            add(sourceImage)
            web.stopLoading()
            let host=UIHostingController(rootView:ZStack {
                PiyaliBrand.unitColor("fff9ef")
                RPGWorldView(run:run,pet:"ghost",environmentTime:time,actorsVisible:false,tutorialTerrain:terrain,onTile:{_ in})
            }.environment(\.scenePhase,.active).ignoresSafeArea())
            window.rootViewController=host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()
            try await Task.sleep(for:.milliseconds(600))
            let nativeImage=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image { _ in
                window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)
            })
            nativeImage.name="Native Greeting Plaza atmosphere \(time)"
            nativeImage.lifetime = .keepAlways
            add(nativeImage)
        }

        let before=try XCTUnwrap(nativeScene.camera?.position)
        run.position=RPGPoint(x:run.position.x+1,y:run.position.y)
        nativeScene.configure(run,pet:"ghost",size:window.bounds.size,tutorialTerrain:terrain)
        XCTAssertEqual(nativeScene.camera?.position,before)
        nativeScene.update(1.0)
        XCTAssertEqual(try XCTUnwrap(nativeScene.camera?.position.x),before.x+32*0.35*0.1,accuracy:0.0001)
        for frame in 1...120 { nativeScene.update(1+Double(frame)/60) }
        XCTAssertEqual(try XCTUnwrap(nativeScene.camera?.position.x),before.x+32,accuracy:0.001)
    }
}
