import XCTest
import SwiftUI
import WebKit
@testable import Piyali
@MainActor private final class LoaderReferenceNoCloud:LearnerProgressService{
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class GameLoaderReferenceTests:XCTestCase{
    private struct Event{let operation:String,input:JSONValue;var shot:String?,frame:Int?}
    private func quote(_ s:String)->String{String(data:try! JSONEncoder().encode(s),encoding:.utf8)!}
    func testActualSourceAndNativeOutdoorMessagesAndIndoorPreparation()async throws{
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Read-only source preview and isolated identity required")}
        let app=AppModel(progressService:LoaderReferenceNoCloud());try app.identity.create();defer{try? app.identity.disconnect()};app.learner=LearnerState();app.signedIn=true;app.learner.onboardingComplete=true
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for(support,theme)in[("en","light"),("ar","dark")]{
            app.learner.support=support;let policy=try GameLoaderPolicy(),parameters:JSONValue = .object(["seed":.number(7),"now":.number(1000000),"support":.string(support),"pet":.string("ghost")]),initial=try policy.run("create",parameters),world=initial["world"]
            var state=initial["state"],now=1000000.0,events:[Event]=[]
            let window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);defer{window.isHidden=true;window.rootViewController=nil}
            let web=WKWebView(frame:window.bounds),sourceHost=UIViewController();sourceHost.view=web;window.rootViewController=sourceHost;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-game-loader?seed=7&frame=1&language=\(support)&theme=\(theme)&pet=ghost")!))
            func waitWeb(_ expression:String)async throws{var ok=false;for _ in 0..<1200{ok=(try? await web.evaluateJavaScript(expression))as?Bool == true;if ok{break};try await Task.sleep(for:.milliseconds(25))};let errors=(try? await web.evaluateJavaScript("JSON.stringify(window.__piyaliLoaderErrors||[])+document.body.innerText")) as? String ?? "";XCTAssertTrue(ok,expression+" "+(ok ? "":errors))}
            try await waitWeb("!!window.__piyaliLoader&&document.fonts.status==='loaded'");try await Task.sleep(for:.milliseconds(600))
            func step(_ operation:String,_ values:JSONValue = .object([:]))async throws{
                now+=150;let input=values.setting("now",.number(now)),result=try policy.run(operation,input);state=result["state"];events.append(.init(operation:operation,input:input))
                let command=operation == "move" ? "window.__piyaliLoader.move(\(quote(input["direction"].string)))":operation == "select" ? "window.__piyaliLoader.select(\(Int(input["x"].number)),\(Int(input["y"].number)))":""
                _=try await web.evaluateJavaScript("window.__piyaliLoader.clock(\(now));\(command)")
            }
            func frame()throws{let input:JSONValue = .object(["now":.number(now),"width":.number(402),"height":.number(874)]);state=try policy.run("frame",input)["state"];events.append(.init(operation:"frame",input:input))}
            func sourceShot(_ name:String)async throws{
                try frame();events[events.count-1].shot=name;events[events.count-1].frame=Int(state["frame"].number);let frame=Int(state["frame"].number)
                _=try await web.evaluateJavaScript("(()=>{const u=new URL(location.href);u.searchParams.set('frame','\(frame)');history.replaceState({},'',u);window.__piyaliLoader.clock(\(now));})()")
                try await Task.sleep(for:.milliseconds(500));let a=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));a.name="Source loader \(name) \(support)";a.lifetime = .keepAlways;add(a)
            }
            func approach(_ target:RPGPoint)async throws{
                let room=world["rooms"][state["currentRoom"].string],map=room["map"].array.map{$0.array.map{Int($0.number)}},start=RPGPoint(x:Int(state["px"].number),y:Int(state["py"].number)),blocked:Set<Int>=[4,2,8,14,15,18,19,20,21,22,6,7,11,23,16,12]
                var queue=[start],seen:Set<RPGPoint>=[start],parents:[RPGPoint:(RPGPoint,String)]=[:],cursor=0,end:RPGPoint?
                while cursor<queue.count{let p=queue[cursor];cursor+=1;if abs(p.x-target.x)+abs(p.y-target.y)==1{end=p;break};for(dx,dy,direction)in[(0,-1,"up"),(1,0,"right"),(0,1,"down"),(-1,0,"left")]{let n=RPGPoint(x:p.x+dx,y:p.y+dy);if n.x>=0,n.y>=0,n.y<map.count,n.x<map[0].count,!blocked.contains(map[n.y][n.x]),seen.insert(n).inserted{parents[n]=(p,direction);queue.append(n)}}}
                var route:[String]=[],point=try XCTUnwrap(end);while point != start{let parent=try XCTUnwrap(parents[point]);route.insert(parent.1,at:0);point=parent.0};for direction in route{try await step("move",.object(["direction":.string(direction)]))}
            }
            try await sourceShot("arrival");now+=2100;try await step("state");try await sourceShot("outdoor")
            let map=world["rooms"]["outdoor"]["map"].array.map{$0.array.map{Int($0.number)}}
            var object:RPGPoint?;for y in map.indices{for x in map[y].indices where [6,7,11].contains(map[y][x]){object=RPGPoint(x:x,y:y);break};if object != nil{break}}
            let target=try XCTUnwrap(object);try await approach(target);try await step("select",.object(["x":.number(Double(target.x)),"y":.number(Double(target.y))]));try await sourceShot("message")
            let door=world["rooms"]["outdoor"]["doors"].array[0];try await approach(.init(x:Int(door["x"].number),y:Int(door["y"].number)));try await step("select",.object(["x":door["x"],"y":door["y"]]))
            for _ in 0..<26{now+=16;try frame()};try await waitWeb("window.__piyaliLoader.state().currentRoom==='room1'&&!window.__piyaliLoader.state().transitioning");try await sourceShot("indoor")
            web.stopLoading();window.isHidden=true;window.rootViewController=nil
            let model=GameLoaderModel(seed:7,support:support,pet:"ghost",now:1000000),controller=GamePreparationController(),host=UIHostingController(rootView:GamePreparationView(preparation:controller,support:support,pet:"ghost",model:model,embedded:true,messageIndex:0,freezeAnimation:true,onCancel:{}).environmentObject(app).environment(\.scenePhase,.inactive).preferredColorScheme(theme=="light" ? .light:.dark).ignoresSafeArea())
            window.rootViewController=host;window.makeKeyAndVisible();try await Task.sleep(for:.milliseconds(400))
            func find(_ v:UIView)->GameLoaderCanvasView?{if let canvas=v as? GameLoaderCanvasView{return canvas};return v.subviews.lazy.compactMap{find($0)}.first}
            let canvas=try XCTUnwrap(find(host.view));canvas.paused=true;model.onSound=nil;_=try model.policy?.run("create",parameters)
            XCTAssertEqual(canvas.bounds.size,CGSize(width:402,height:874))
            for event in events{
                if event.operation=="frame"{canvas.render(now:event.input["now"].number)}
                else if let value=try model.policy?.run(event.operation,event.input){model.update(value.foundation)}
                if let name=event.shot{XCTAssertFalse(canvas.isAnimating);XCTAssertEqual(Int(try XCTUnwrap(model.policy).run("state")["state"]["frame"].number),event.frame);canvas.layer.displayIfNeeded();try await Task.sleep(for:.milliseconds(50));let a=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});a.name="Native loader \(name) \(support)";a.lifetime = .keepAlways;add(a)}
            }
            XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.rpgRuns);window.isHidden=true;window.rootViewController=nil
        }
    }
}

extension GameLoaderReferenceTests {
    func testActualTutorialAndTutorLoadingSurfacesAgainstNative()async throws{
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"]=="1",env["PIYALI_REFERENCE_PREVIEW_TESTS"]=="1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Explicit isolated source preview required")}
        let app=AppModel(progressService:LoaderReferenceNoCloud());try app.identity.create();app.signedIn=true;app.learner=LearnerState();defer{try? app.identity.disconnect()};let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as?UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for(surface,support,theme)in[("intro","en","light"),("intro","ar","dark"),("tutor","en","light"),("tutor","ar","dark")]{
            app.learner.support=support;let window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();let web=WKWebView(frame:window.bounds,configuration:config);web.scrollView.contentInsetAdjustmentBehavior = .never;let host=UIViewController();host.view=web;window.rootViewController=host;window.makeKeyAndVisible();defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-game-loader?surface=\(surface)&seed=7&frame=1&language=\(support)&theme=\(theme)&pet=ghost")!));var ready=false
            for _ in 0..<800{ready=(try? await web.evaluateJavaScript("!!window.__piyaliLoader&&document.fonts.status==='loaded'"))as?Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(25))};let errors=(try? await web.evaluateJavaScript("JSON.stringify(window.__piyaliLoaderErrors)+document.body.innerText"))as?String ?? "";XCTAssertTrue(ready,errors);guard ready else{return};try await Task.sleep(for:.milliseconds(600));let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source \(surface) playable loader \(support)";source.lifetime = .keepAlways;add(source)
            let metrics=(try? await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('canvas,button,p')].map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {text:e.textContent,x:r.x,y:r.y,w:r.width,h:r.height,fontFamily:s.fontFamily,fontSize:s.fontSize,fontWeight:s.fontWeight,lineHeight:s.lineHeight,color:s.color,dir:s.direction}}))"))as?String ?? "[]";let a=XCTAttachment(string:metrics);a.name="Source \(surface) loader metrics \(support)";a.lifetime = .keepAlways;add(a);web.stopLoading();window.isHidden=true;window.rootViewController=nil
            let model=GameLoaderModel(seed:7,support:support,pet:"ghost",now:1000000),controller=GamePreparationController(),height:CGFloat=surface=="intro" ? 874*0.62:580,width:CGFloat=surface=="intro" ? 402:378
            let view=ZStack(alignment:.topLeading){PiyaliBrand.unitColor(theme=="light" ? "f7f1e7":"0b1220");GamePreparationView(preparation:controller,support:support,pet:"ghost",model:model,embedded:true,showsCancel:surface=="tutor",messageIndex:0,freezeAnimation:true,onCancel:{}).environmentObject(app).frame(width:width,height:height).clipShape(RoundedRectangle(cornerRadius:surface=="intro" ? 12:16)).offset(x:surface=="intro" ? 0:12,y:surface=="intro" ? 8:100)}.environment(\.scenePhase,.inactive).preferredColorScheme(theme=="light" ? .light:.dark).ignoresSafeArea()
            let nativeHost=UIHostingController(rootView:view);window.rootViewController=nativeHost;window.makeKeyAndVisible();window.layoutIfNeeded();nativeHost.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(300));func find(_ v:UIView)->GameLoaderCanvasView?{if let c=v as?GameLoaderCanvasView{return c};return v.subviews.lazy.compactMap{find($0)}.first};let canvas=try XCTUnwrap(find(nativeHost.view));canvas.paused=true;_=try model.policy?.run("create",.object(["seed":.number(7),"now":.number(1000000),"support":.string(support),"pet":.string("ghost")]));canvas.render(now:1000000);XCTAssertEqual(canvas.bounds.width,width,accuracy:1);XCTAssertEqual(canvas.bounds.height,height,accuracy:1);try await Task.sleep(for:.milliseconds(100));let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native \(surface) playable loader \(support)";native.lifetime = .keepAlways;add(native);XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.rpgRuns);window.isHidden=true;window.rootViewController=nil
        }
    }
}
