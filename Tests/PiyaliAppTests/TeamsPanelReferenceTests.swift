import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor private final class TeamsNoCloud:LearnerProgressService {
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor private final class TeamsPreviewAccess:TeamsPanelAccess {
    let snapshot:TeamsPanelSnapshot,posts:[CommunityPost]
    init(_ fixture:JSONValue,state:String){
        var teams=["empty","create","queued"].contains(state) ? []:fixture["teams"].array
        if state == "multi",let first=teams.first{teams.append(first.setting("id",.string("fixture-two")).setting("teamName",.string("Evening practice")))}
        snapshot = .init(teams:teams,invites:state == "pending" ? fixture["invites"].array:[],rows:Dictionary(uniqueKeysWithValues:teams.map{(LiveTeamsPanelAccess.key($0),fixture["rows"][$0["id"].string].array)}))
        posts=fixture["posts"].array.compactMap{v in let content=v["content"].string,tags=v["tags"].array.map{$0.array.map(\.string)},name=v["profile"]["name"].string;guard let milestone=CommunityMilestone.parse(content:content,tags:tags,name:name) else{return nil};return CommunityPost(event:.init(id:v["id"].string,pubkey:v["pubkey"].string,created_at:1700000000,kind:1,tags:tags,content:content,sig:""),name:name,npub:v["npub"].string,milestone:milestone)}
    }
    func load(_ app:AppModel)async throws->TeamsPanelSnapshot{snapshot}
    func create(name:String,members:[String],app:AppModel)async throws{throw URLError(.notConnectedToInternet)}
    func rename(_ team:JSONValue,name:String,app:AppModel)async throws->Bool{throw URLError(.notConnectedToInternet)}
    func add(_ team:JSONValue,members:[String],app:AppModel)async throws->Bool{throw URLError(.notConnectedToInternet)}
    func remove(_ team:JSONValue,app:AppModel)async throws{throw URLError(.notConnectedToInternet)}
    func respond(_ invite:JSONValue,accept:Bool,app:AppModel)async throws{throw URLError(.notConnectedToInternet)}
    func publish(_ app:AppModel)async throws{}
    func feed(_ app:AppModel,force:Bool)async throws->[CommunityPost]{posts}
    func cancel(){}
}
@MainActor final class TeamsPanelReferenceTests:XCTestCase {
    func testActualSourceAndNativeTeamDrawerFormsCardsFeedAndArabic()async throws{
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated reference opt-in required")}
        let fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"teams-panel-preview",withExtension:"json"))))
        let app=AppModel(progressService:TeamsNoCloud());try app.identity.create();defer{try? app.identity.disconnect()};app.signedIn=true;app.learner.onboardingComplete=true
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for(lang,theme)in [("en","light"),("ar","dark")] {for state in ["empty","single","multi","pending","create","queued","rename","feed"] {
            app.learner.support=lang
            let window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);let web=WKWebView(frame:window.frame),vc=UIViewController();vc.view=web;window.rootViewController=vc;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-teams?language=\(lang)&theme=\(theme)&state=\(state)")!))
            var ready=false;for _ in 0..<300{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && !!document.querySelector('[role=dialog]') && document.querySelectorAll('[role=tab]').length===2"))as?Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};XCTAssertTrue(ready);guard ready else{return};try await Task.sleep(for:.milliseconds(700))
            if state == "feed"{_=try await web.evaluateJavaScript("document.querySelectorAll('[role=tab]')[1].click()")}
            if state == "create" || state == "queued"{_=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(b=>b.textContent==='\(EntryCopy.ui(lang,"teams_create_open"))').click()")}
            if state == "rename"{_=try await web.evaluateJavaScript("document.querySelector('button[aria-label=\"Edit team\"]').click();document.activeElement.blur()")}
            if state == "queued"{_=try await web.evaluateJavaScript("(()=>{const input=[...document.querySelectorAll('input')][1];Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set.call(input,window.__teamsFixture.creator);input.dispatchEvent(new Event('input',{bubbles:true}));})()");try await Task.sleep(for:.milliseconds(100));_=try await web.evaluateJavaScript("[...document.querySelectorAll('[role=dialog]')].at(-1).querySelectorAll('button')[1].click();document.activeElement.blur()")}
            try await Task.sleep(for:.milliseconds(500));_=try? await web.evaluateJavaScript("document.activeElement.blur()");web.endEditing(true);try await Task.sleep(for:.milliseconds(400));let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source Teams \(state) \(lang)";source.lifetime = .keepAlways;add(source)
            let metrics=(try? await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('[role=dialog],[role=tab],button,input,p')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,label:e.getAttribute('aria-label'),x:r.x,y:r.y,width:r.width,height:r.height,font:s.font,color:s.color,background:s.backgroundColor}}))"))as?String ?? "[]";let data=XCTAttachment(data:Data(metrics.utf8),uniformTypeIdentifier:"public.json");data.name="Source Teams \(state) \(lang) geometry";data.lifetime = .keepAlways;add(data);web.stopLoading();window.isHidden=true;window.rootViewController=nil
            let access=TeamsPreviewAccess(fixture,state:state),controller=TeamsPanelController(access:access),editor:TeamsEditor? = state == "create" || state == "queued" ? .create:state == "rename" ? .rename(fixture["teams"].array[0]):nil
            window.rootViewController=UIHostingController(rootView:ZStack{PiyaliBrand(dark:theme == "dark").background;TeamsDrawerView(model:controller,initialTab:state == "feed" ? 1:0,initialEditor:editor,initialMembers:state == "queued" ? [fixture["creator"].string]:[],onClose:{})}.environmentObject(app).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());window.makeKeyAndVisible();try await Task.sleep(for:.milliseconds(800));let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native Teams \(state) \(lang)";native.lifetime = .keepAlways;add(native);controller.cancel();window.isHidden=true;window.rootViewController=nil
        }}
    }
}
