import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor private final class TeamsNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor private class TeamsPreviewAccess:TeamsPanelAccess {
    let snapshot:TeamsPanelSnapshot,posts:[CommunityPost]
    init(_ fixture:JSONValue,state:String){
        var teams=["empty","create","queued"].contains(state) ? []:fixture["teams"].array
        if state == "multi",let first=teams.first{teams.append(first.setting("id",.string("fixture-two")).setting("teamName",.string("Evening practice")))}
        snapshot = .init(teams:teams,invites:state == "pending" ? fixture["invites"].array:[],rows:Dictionary(uniqueKeysWithValues:teams.map{(LiveTeamsPanelAccess.key($0),fixture["rows"][$0["id"].string].array)}))
        posts=fixture["posts"].array.compactMap{v in let content=v["content"].string,tags=v["tags"].array.map{$0.array.map(\.string)},name=v["profile"]["name"].string;guard CommunityMilestone.isFeedAuthorVisible(name) else{return nil};let milestone=CommunityMilestone.parse(content:content,tags:tags,name:name);return CommunityPost(event:.init(id:v["id"].string,pubkey:v["pubkey"].string,created_at:1700000000,kind:1,tags:tags,content:content,sig:""),name:name,npub:v["npub"].string,milestone:milestone)}
    }
    func load(_ app:AppModel)async throws->TeamsPanelSnapshot{snapshot}
    func loadStaged(_ app:AppModel,onRoster:@escaping @MainActor(TeamsPanelSnapshot)async->Void)async throws->TeamsPanelSnapshot{try await load(app)}
    func create(name:String,members:[String],app:AppModel)async throws{throw URLError(.notConnectedToInternet)}
    func rename(_ team:JSONValue,name:String,app:AppModel)async throws->Bool{throw URLError(.notConnectedToInternet)}
    func add(_ team:JSONValue,members:[String],app:AppModel)async throws->Bool{throw URLError(.notConnectedToInternet)}
    func remove(_ team:JSONValue,app:AppModel)async throws{throw URLError(.notConnectedToInternet)}
    func respond(_ invite:JSONValue,accept:Bool,app:AppModel)async throws{throw URLError(.notConnectedToInternet)}
    func publish(_ app:AppModel)async throws{}
    func cachedFeed(_ app:AppModel)->[CommunityPost]?{nil}
    func feed(_ app:AppModel,force:Bool)async throws->[CommunityPost]{posts}
    func watchRoster(_ snapshot:TeamsPanelSnapshot,app:AppModel,onRecord:@escaping @MainActor(JSONValue)->Void,onInvalidate:@escaping @MainActor()->Void)async{}
    func memberRows(_ team:JSONValue,app:AppModel)async throws->[JSONValue]{[]}
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
            let sourceDirection=try await web.evaluateJavaScript("getComputedStyle(document.querySelector('[role=dialog]')).direction") as? String;XCTAssertEqual(sourceDirection,lang == "ar" ? "rtl":"ltr")
            let metrics=(try? await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('[role=dialog],[role=tab],button,input,p')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,label:e.getAttribute('aria-label'),x:r.x,y:r.y,width:r.width,height:r.height,font:s.font,color:s.color,background:s.backgroundColor,direction:s.direction}}))"))as?String ?? "[]";let data=XCTAttachment(data:Data(metrics.utf8),uniformTypeIdentifier:"public.json");data.name="Source Teams \(state) \(lang) geometry";data.lifetime = .keepAlways;add(data);web.stopLoading();window.isHidden=true;window.rootViewController=nil
            let access=TeamsPreviewAccess(fixture,state:state),controller=TeamsPanelController(access:access),editor:TeamsEditor? = state == "create" || state == "queued" ? .create:state == "rename" ? .rename(fixture["teams"].array[0]):nil
            window.rootViewController=UIHostingController(rootView:ZStack{PiyaliBrand(dark:theme == "dark").background;TeamsDrawerView(model:controller,initialTab:state == "feed" ? 1:0,initialEditor:editor,initialMembers:state == "queued" ? [fixture["creator"].string]:[],onClose:{})}.environmentObject(app).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());window.makeKeyAndVisible();try await Task.sleep(for:.milliseconds(800));let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native Teams \(state) \(lang)";native.lifetime = .keepAlways;add(native);controller.cancel();window.isHidden=true;window.rootViewController=nil
        }}
    }
}


@MainActor private final class TeamsHeldLoadingAccess:TeamsPanelAccess {
    let invites:[JSONValue];var held:CheckedContinuation<TeamsPanelSnapshot,Never>?
    init(invites:[JSONValue]){self.invites=invites}
    func load(_ app:AppModel)async throws->TeamsPanelSnapshot{await withCheckedContinuation{held=$0}}
    func watchInvites(_ app:AppModel,onChange:@escaping @MainActor([JSONValue])->Void)async{onChange(invites)}
    func create(name:String,members:[String],app:AppModel)async throws{}
    func rename(_ team:JSONValue,name:String,app:AppModel)async throws->Bool{true}
    func add(_ team:JSONValue,members:[String],app:AppModel)async throws->Bool{true}
    func remove(_ team:JSONValue,app:AppModel)async throws{}
    func respond(_ invite:JSONValue,accept:Bool,app:AppModel)async throws{}
    func publish(_ app:AppModel)async throws{XCTFail("Loading a team drawer must not publish")}
    func feed(_ app:AppModel,force:Bool)async throws->[CommunityPost]{[]}
    func cancel(){held?.resume(returning:.init());held=nil}
}
extension TeamsPanelReferenceTests {
    func testOriginalLoadingDotsAndNativeHeldReadHidePendingCardsInEnglishAndArabic()async throws {
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated source preview required")}
        let app=AppModel(progressService:TeamsNoCloud());try app.identity.create();app.signedIn=true;defer{app.signOut()};let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        let fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"teams-panel-preview",withExtension:"json"))))
        for (language,theme) in [("en","light"),("ar","dark")] {
            app.learner.support=language;let window=UIWindow(windowScene:scene),web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874)),vc=UIViewController();vc.view=web;window.rootViewController=vc;window.frame=web.frame;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never;defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-teams?state=loading&language=\(language)&theme=\(theme)"))))
            var ready=false;for _ in 0..<500{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && !!document.querySelector('[role=status]') && typeof window.__releaseTeamLoad==='function'")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(40))};XCTAssertTrue(ready);guard ready else{return};try await Task.sleep(for:.milliseconds(500))
            let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source Teams held loading dots \(language)";source.lifetime = .keepAlways;add(source)
            let geometry=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('[role=status],[role=status] *')].map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {text:e.textContent,x:r.x,y:r.y,width:r.width,height:r.height,color:s.color,fontSize:s.fontSize}}))"),metrics=XCTAttachment(data:Data((geometry as? String ?? "").utf8),uniformTypeIdentifier:"public.json");metrics.name="Source Teams held loading geometry \(language)";metrics.lifetime = .keepAlways;add(metrics)
            let access=TeamsHeldLoadingAccess(invites:fixture["invites"].array),model=TeamsPanelController(access:access),native=UIWindow(windowScene:scene);native.frame=web.frame;native.rootViewController=UIHostingController(rootView:ZStack{PiyaliBrand(dark:theme == "dark").background;TeamsDrawerView(model:model,onClose:{})}.environmentObject(app).environment(\.scenePhase,.active).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());native.makeKeyAndVisible();native.layoutIfNeeded()
            for _ in 0..<200 where access.held == nil || model.snapshot.invites.isEmpty{try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(model.loading);XCTAssertFalse(model.snapshot.invites.isEmpty);try await Task.sleep(for:.milliseconds(500));let shot=XCTAttachment(image:UIGraphicsImageRenderer(bounds:native.bounds).image{_ in native.drawHierarchy(in:native.bounds,afterScreenUpdates:true)});shot.name="Native Teams held loading dots \(language)";shot.lifetime = .keepAlways;add(shot)
            model.cancel();native.isHidden=true;native.rootViewController=nil;window.makeKeyAndVisible();web.stopLoading();window.isHidden=true;window.rootViewController=nil
        }
    }
}

extension TeamsPanelReferenceTests {
    /// Original component actions supply the source payload; native replay verifies presentation.
    /// Signed-relay product journeys separately exercise native validation and mutations.
    func testOriginalTeamToastActionsAndNativePresentationInEnglishAndArabic()async throws {
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated source preview required")}
        let fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"teams-panel-preview",withExtension:"json"))))
        let app=AppModel(progressService:TeamsNoCloud());try app.identity.create();app.signedIn=true;defer{app.signOut()}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for(language,theme)in [("en","light"),("ar","dark")] {for state in ["rename-error","rename-warning","rename-success","queue-error","queue-warning","copy"] {
            app.learner.support=language;app.teamsNotices.bind("")
            let window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);let web=WKWebView(frame:window.frame),vc=UIViewController();vc.view=web;window.rootViewController=vc;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-teams?state=\(state)&language=\(language)&theme=\(theme)"))))
            var ready=false;for _ in 0..<400{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && document.querySelectorAll('[role=tab]').length===2")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(40))};XCTAssertTrue(ready);guard ready else{return};try await Task.sleep(for:.milliseconds(500))
            if state.hasPrefix("rename"){
                _=try await web.evaluateJavaScript("document.querySelector('button[aria-label=\"Edit team\"]').click()")
                try await Task.sleep(for:.milliseconds(150))
                _=try await web.evaluateJavaScript("(()=>{const input=[...document.querySelectorAll('[role=dialog]')].at(-1).querySelector('input');Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set.call(input,'Evening practice');input.dispatchEvent(new Event('input',{bubbles:true}));})()")
                try await Task.sleep(for:.milliseconds(100));_=try await web.evaluateJavaScript("[...document.querySelectorAll('[role=dialog]')].at(-1).querySelectorAll('button')[2].click()")
            }else if state.hasPrefix("queue"){
                _=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(b=>b.textContent==='\(EntryCopy.ui(language,"teams_create_open"))').click()")
                for index in 0..<(state == "queue-warning" ? 2:1){
                    _=try await web.evaluateJavaScript("(()=>{const input=[...document.querySelectorAll('[role=dialog]')].at(-1).querySelectorAll('input')[1];Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set.call(input,\(state == "queue-error" ? "'bad'":"window.__teamsFixture.creator"));input.dispatchEvent(new Event('input',{bubbles:true}));})()")
                    try await Task.sleep(for:.milliseconds(100));_=try await web.evaluateJavaScript("[...document.querySelectorAll('[role=dialog]')].at(-1).querySelectorAll('button')[1].click()")
                    if index == 0{try await Task.sleep(for:.milliseconds(100))}
                }
            }else{
                _=try await web.evaluateJavaScript("Object.defineProperty(navigator,'clipboard',{value:{writeText:async()=>{}},configurable:true});[...document.querySelectorAll('button')].find(b=>b.textContent==='\(EntryCopy.ui(language,"teams_copy_id"))').click()")
            }
            var hasToast=false;for _ in 0..<100{hasToast=(try? await web.evaluateJavaScript("!!document.querySelector('.chakra-toast')")) as? Bool == true;if hasToast{break};try await Task.sleep(for:.milliseconds(20))};XCTAssertTrue(hasToast,state);guard hasToast else{return}
            _=try? await web.evaluateJavaScript("document.activeElement.blur()");web.endEditing(true);try await Task.sleep(for:.milliseconds(500))
            let rawTitle=try await web.evaluateJavaScript("document.querySelector('.chakra-alert__title').textContent");let title=try XCTUnwrap(rawTitle as? String),description=try await web.evaluateJavaScript("document.querySelector('.chakra-alert__desc')?.textContent||''") as? String ?? ""
            let expectedTitle=state.hasPrefix("queue") || state == "rename-error" ? "Error":state == "copy" ? "Your ID was copied":"Team renamed"
            XCTAssertEqual(title,expectedTitle);let status=state.hasSuffix("error") ? "error":state.hasSuffix("warning") ? "warning":"success"
            let expectedDescription:[String:String] = ["rename-error":"Public rename rejection","rename-warning":"The team name changed, but some local copies may still show the old name","queue-error":"Invalid npub format. npubs begin with 'npub'","queue-warning":"This npub is already on the list"]
            XCTAssertEqual(description,expectedDescription[state] ?? "")
            let sourceDirection=try await web.evaluateJavaScript("getComputedStyle(document.querySelector('.chakra-toast')).direction") as? String;XCTAssertEqual(sourceDirection,language == "ar" ? "rtl":"ltr")
            let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source Teams toast \(state) \(language)";source.lifetime = .keepAlways;add(source)
            let geometry=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('.chakra-toast,.chakra-toast *')].map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,x:r.x,y:r.y,width:r.width,height:r.height,color:s.color,background:s.backgroundColor,fontFamily:s.fontFamily,fontSize:s.fontSize,fontWeight:s.fontWeight,lineHeight:s.lineHeight,direction:s.direction}}))") as? String ?? "[]"
            let metrics=XCTAttachment(data:Data(geometry.utf8),uniformTypeIdentifier:"public.json");metrics.name="Source Teams toast geometry \(state) \(language)";metrics.lifetime = .keepAlways;add(metrics)
            // Replays the exact outcome above; this does not claim native actions were exercised here.
            var nativeFixture=fixture;if state == "rename-warning" || state == "rename-success"{nativeFixture=fixture.setting("teams",.array(fixture["teams"].array.map{$0.setting("teamName",.string("Evening practice"))}))}
            let access=TeamsPreviewAccess(nativeFixture,state:"single"),model=TeamsPanelController(access:access)
            let editor:TeamsEditor? = state.hasPrefix("queue") ? .create:state == "rename-error" ? .rename(fixture["teams"].array[0].setting("teamName",.string("Evening practice"))):nil
            let notice=TeamsNotice(title:title,description:description.isEmpty ? nil:description,status:status,duration:state == "copy" ? 2:5,closable:state == "copy")
            window.rootViewController=UIHostingController(rootView:ZStack{PiyaliBrand(dark:theme == "dark").background;TeamsDrawerView(model:model,initialEditor:editor,initialMembers:state == "queue-warning" ? [fixture["creator"].string]:[],initialMember:state == "queue-error" ? "bad":"",onClose:{});TeamsNoticeStack(notices:[notice],rtl:language == "ar")}.environmentObject(app).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());window.makeKeyAndVisible();try await Task.sleep(for:.milliseconds(600))
            let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native Teams toast \(state) \(language)";native.lifetime = .keepAlways;add(native);model.cancel();web.stopLoading();window.isHidden=true;window.rootViewController=nil
        }}
    }
}


@MainActor private final class TeamsFeedPreviewAccess:TeamsPreviewAccess {
    let state:String
    var cache:[CommunityPost]?
    var calls:[Bool]=[]
    var held:CheckedContinuation<[CommunityPost],Error>?
    override init(_ fixture:JSONValue,state:String){self.state=state;super.init(fixture,state:"empty");if state == "feed-cached-refresh" || state == "feed"{cache=posts}}
    override func cachedFeed(_ app:AppModel)->[CommunityPost]?{cache}
    override func feed(_ app:AppModel,force:Bool)async throws->[CommunityPost]{
        calls.append(force)
        if state == "feed-error",calls.count == 1{throw AppError.message("Community relay unavailable")}
        if state == "feed-loading" || state == "feed-cached-refresh" || state == "feed-error"{let values=try await withCheckedThrowingContinuation{held=$0};cache=values;return values}
        let values=state == "feed-empty" ? []:posts;cache=values;return values
    }
    func complete(_ values:[CommunityPost]){held?.resume(returning:values);held=nil}
    func reject(){held?.resume(throwing:AppError.message("Community relay unavailable"));held=nil}
    override func cancel(){held?.resume(throwing:CancellationError());held=nil}
}
extension TeamsPanelReferenceTests {
    func testActualFeedCacheLoadingEmptyFailureRefreshAndQuestionCardsInBothDirections()async throws {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated source preview required")}
        let fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"teams-panel-preview",withExtension:"json"))))
        let app=AppModel(progressService:TeamsNoCloud());try app.identity.create();app.signedIn=true;defer{app.signOut()}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for(language,theme)in [("en","light"),("ar","dark")] {for state in ["feed-loading","feed-empty","feed-error","feed-cached-refresh","feed","feed-question"] {
            app.learner.support=language
            var nativeFixture=fixture
            if state == "feed-question"{nativeFixture=nativeFixture.setting("posts",.array(fixture["posts"].array.map{$0.setting("content",.string("Finished question 30! https://piyali.app **literal** #LearnWithNostr")).setting("tags",.array([]))}))}
            let sourceWindow=UIWindow(windowScene:scene);sourceWindow.frame=CGRect(x:0,y:0,width:402,height:874);let web=WKWebView(frame:sourceWindow.frame),vc=UIViewController();vc.view=web;sourceWindow.rootViewController=vc;sourceWindow.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            let access=TeamsFeedPreviewAccess(nativeFixture,state:state),model=TeamsPanelController(access:access),nativeWindow=UIWindow(windowScene:scene);nativeWindow.frame=sourceWindow.frame
            defer{model.cancel();web.stopLoading();sourceWindow.isHidden=true;sourceWindow.rootViewController=nil;nativeWindow.isHidden=true;nativeWindow.rootViewController=nil}
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-teams?state=\(state)&language=\(language)&theme=\(theme)"))))
            var ready=false;for _ in 0..<400{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded'&&document.querySelectorAll('[role=tab]').length===2")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(40))};XCTAssertTrue(ready);guard ready else{return}
            _=try await web.evaluateJavaScript("document.querySelectorAll('[role=tab]')[1].click()")
            nativeWindow.rootViewController=UIHostingController(rootView:ZStack{PiyaliBrand(dark:theme == "dark").background;TeamsDrawerView(model:model,initialTab:1,onClose:{})}.environmentObject(app).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());nativeWindow.makeKeyAndVisible()
            for _ in 0..<200 where access.calls.isEmpty{try await Task.sleep(for:.milliseconds(10))};XCTAssertFalse(access.calls.isEmpty)
            func capture(_ phase:String)async throws {
                try await Task.sleep(for:.milliseconds(600));sourceWindow.makeKeyAndVisible();try await Task.sleep(for:.milliseconds(120))
                let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source Teams \(phase) \(language)";source.lifetime = .keepAlways;add(source)
                let geometry=try await web.evaluateJavaScript("JSON.stringify({requests:window.__feedRequests,visible:[...document.querySelectorAll('[role=tabpanel]')].filter(e=>!e.hidden).flatMap(e=>[e,...e.querySelectorAll('*')]).filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,tag:e.tagName,x:r.x,y:r.y,width:r.width,height:r.height,fontSize:s.fontSize,lineHeight:s.lineHeight,color:s.color,bg:s.backgroundColor,border:s.border,direction:s.direction}})})") as? String ?? "{}"
                let metrics=XCTAttachment(data:Data(geometry.utf8),uniformTypeIdentifier:"public.json");metrics.name="Source Teams \(phase) \(language) geometry";metrics.lifetime = .keepAlways;add(metrics)
                nativeWindow.makeKeyAndVisible();try await Task.sleep(for:.milliseconds(120));let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:nativeWindow.bounds).image{_ in nativeWindow.drawHierarchy(in:nativeWindow.bounds,afterScreenUpdates:true)});native.name="Native Teams \(phase) \(language)";native.lifetime = .keepAlways;add(native)
            }
            try await capture(state)
            if state == "feed-loading"{XCTAssertTrue(model.feedLoading);XCTAssertTrue(model.posts.isEmpty);XCTAssertNil(model.feedError)}
            if state == "feed-empty"{XCTAssertFalse(model.feedLoading);XCTAssertTrue(model.posts.isEmpty);XCTAssertNil(model.feedError)}
            if state == "feed-cached-refresh"{
                XCTAssertFalse(model.feedLoading);XCTAssertEqual(model.posts.count,1);XCTAssertNotNil(access.held)
                _=try await web.evaluateJavaScript("window.__rejectFeed()");access.reject();try await capture("feed-cached-error")
                XCTAssertEqual(model.feedError,"Community relay unavailable");XCTAssertEqual(model.posts.count,1,"Old data remains in cache but the error branch hides it")
            }
            if state == "feed-error"{
                XCTAssertEqual(model.feedError,"Community relay unavailable");XCTAssertNil(model.error,"Feed failures never replace roster/action diagnostics")
                _=try await web.evaluateJavaScript("[...document.querySelectorAll('button')].find(b=>b.textContent==='Refresh').click()")
                let retry=Task{await model.loadFeed(app,force:true)};for _ in 0..<200 where access.held == nil{try await Task.sleep(for:.milliseconds(10))};XCTAssertNotNil(access.held);XCTAssertTrue(model.feedLoading);XCTAssertNil(model.feedError)
                try await capture("feed-retry-loading")
                _=try await web.evaluateJavaScript("window.__releaseFeed()");access.complete(access.posts);await retry.value;try await capture("feed-recovered")
                XCTAssertEqual(access.calls,[false,true]);XCTAssertNil(model.feedError);XCTAssertFalse(model.feedLoading);XCTAssertEqual(model.posts.count,1)
            }
            if state == "feed-question"{let links=try await web.evaluateJavaScript("[...document.querySelectorAll('[role=tabpanel]')].filter(e=>!e.hidden).flatMap(e=>[...e.querySelectorAll('a')]).map(a=>a.getAttribute('href'))") as? [String];XCTAssertEqual(links?.last,"https://piyali.app")}
        }}
    }
}


extension TeamsPanelReferenceTests {
    func testFeedFailurePersistsAcrossRosterReloadAndForcedRetryCoalescesWithoutClearingManagementError()async throws {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated identity required")}
        let fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"teams-panel-preview",withExtension:"json"))))
        let app=AppModel(progressService:TeamsNoCloud());try app.identity.create();defer{app.signOut()};let access=TeamsFeedPreviewAccess(fixture,state:"feed-cached-refresh"),model=TeamsPanelController(access:access);defer{model.cancel()}
        await model.reload(app);model.error="Unrelated management failure"
        let initial=Task{await model.loadFeed(app)};for _ in 0..<200 where access.held == nil{try await Task.sleep(for:.milliseconds(10))};XCTAssertNotNil(access.held);XCTAssertFalse(model.feedLoading);XCTAssertEqual(model.posts.count,1)
        access.reject();await initial.value;XCTAssertEqual(model.feedError,"Community relay unavailable");XCTAssertEqual(model.error,"Unrelated management failure")
        await model.reload(app);XCTAssertNil(model.error);XCTAssertEqual(model.feedError,"Community relay unavailable")
        model.error="Another management failure";let retry=Task{await model.loadFeed(app,force:true)};for _ in 0..<200 where access.held == nil{try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(model.feedLoading);XCTAssertNil(model.feedError);XCTAssertEqual(model.posts.count,1)
        await model.loadFeed(app,force:true);XCTAssertEqual(access.calls,[false,true]);access.complete([]);await retry.value;XCTAssertFalse(model.feedLoading);XCTAssertTrue(model.posts.isEmpty);XCTAssertNil(model.feedError);XCTAssertEqual(model.error,"Another management failure");XCTAssertTrue(app.teamsNotices.notices.isEmpty)
    }
    func testLateFeedFailureAfterAccountReplacementCannotReappearOrStopTheNewRequest()async throws {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated identity required")}
        let fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"teams-panel-preview",withExtension:"json"))))
        let app=AppModel(progressService:TeamsNoCloud());try app.identity.create();defer{app.signOut()};let access=TeamsFeedPreviewAccess(fixture,state:"feed-loading"),model=TeamsPanelController(access:access);defer{model.cancel()}
        await model.reload(app);let old=Task{await model.loadFeed(app)};for _ in 0..<200 where access.held == nil{try await Task.sleep(for:.milliseconds(10))};let reply=try XCTUnwrap(access.held);access.held=nil
        try app.identity.create();await model.reload(app);let next=Task{await model.loadFeed(app)};for _ in 0..<200 where access.held == nil{try await Task.sleep(for:.milliseconds(10))};XCTAssertNotNil(access.held);reply.resume(throwing:AppError.message("Stale account failure"));await old.value
        XCTAssertTrue(model.feedLoading);XCTAssertNil(model.feedError);XCTAssertTrue(model.posts.isEmpty);access.complete(access.posts);await next.value;XCTAssertFalse(model.feedLoading);XCTAssertEqual(model.posts.count,1);XCTAssertNil(model.feedError)
    }
}


extension TeamsPanelReferenceTests {
    func testOriginalRetainedNonMilestoneFilteredMixedAndFallbackFeedScreens()async throws {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated source preview required")}
        let fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"teams-panel-preview",withExtension:"json"))))
        let app=AppModel(progressService:TeamsNoCloud());try app.identity.create();app.signedIn=true;defer{app.signOut()}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        let base=try XCTUnwrap(fixture["posts"].array.first)
        func entry(_ id:String,_ content:String,name:String="Ada",time:Double=1700000001)->JSONValue{base.setting("id",.string(id)).setting("content",.string(content)).setting("profile",.object(["name":.string(name)])).setting("tags",.array([])).setting("createdAt",.number(time))}
        for(language,theme)in [("en","light"),("ar","dark")] {for state in ["feed-ordinary","feed-zero","feed-scholarship","feed-banned","feed-mixed","feed-fallback"] {
            app.learner.support=language;let values:[JSONValue]
            switch state{case "feed-ordinary":values=[entry("ordinary","A community greeting")];case "feed-zero":values=[entry("zero","Finished question 0")];case "feed-scholarship":values=[entry("scholarship","A new scholarship")];case "feed-banned":values=[base.setting("profile",.object(["name":.string("TEST")]))];case "feed-mixed":values=[entry("ordinary","A community greeting",time:1700000003),base.setting("id",.string("blocked")).setting("profile",.object(["name":.string("TEST")])).setting("createdAt",.number(1700000004)),base.setting("id",.string("visible")).setting("createdAt",.number(1700000001))];default:values=[base.setting("profile",.object(["name":.string("New Private User")]))]}
            let access=TeamsPreviewAccess(fixture.setting("posts",.array(values)),state:"empty"),model=TeamsPanelController(access:access);let policy=try XCTUnwrap(model.policy)
            let window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);let web=WKWebView(frame:window.frame),vc=UIViewController();vc.view=web;window.rootViewController=vc;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            defer{model.cancel();web.stopLoading();window.isHidden=true;window.rootViewController=nil}
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-teams?state=\(state)&language=\(language)&theme=\(theme)"))))
            var ready=false;for _ in 0..<400{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded'&&document.querySelectorAll('[role=tab]').length===2&&window.__teamsCachedFeed?.()!==null")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(40))};XCTAssertTrue(ready);guard ready else{return}
            _=try await web.evaluateJavaScript("document.querySelectorAll('[role=tab]')[1].click()");try await Task.sleep(for:.milliseconds(600))
            let stats=try await web.evaluateJavaScript("JSON.stringify((()=>{const p=[...document.querySelectorAll('[role=tabpanel]')].find(e=>!e.hidden);return{rawCount:window.__teamsCachedFeed().length,posts:p.querySelectorAll('a[href^=\"https://ditto.pub/\"]').length,empty:p.textContent.includes('No posts yet. Start the conversation!'),text:p.textContent,geometry:[p,...p.querySelectorAll('*')].map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {tag:e.tagName,text:e.textContent,x:r.x,y:r.y,width:r.width,height:r.height,color:s.color,direction:s.direction}})}})())") as? String ?? "{}"
            let observed=try JSONDecoder().decode(JSONValue.self,from:Data(stats.utf8));XCTAssertEqual(observed["rawCount"].number,Double(values.count));XCTAssertEqual(observed["posts"].number,["feed-mixed","feed-fallback"].contains(state) ? 1:0);XCTAssertEqual(observed["empty"].boolean,state == "feed-banned")
            let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source Teams content \(state) \(language)";source.lifetime = .keepAlways;add(source);let geometry=XCTAttachment(data:Data(stats.utf8),uniformTypeIdentifier:"public.json");geometry.name="Source Teams content \(state) \(language) geometry";geometry.lifetime = .keepAlways;add(geometry)
            window.rootViewController=UIHostingController(rootView:ZStack{PiyaliBrand(dark:theme == "dark").background;TeamsDrawerView(model:model,initialTab:1,onClose:{})}.environmentObject(app).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());window.makeKeyAndVisible();try await Task.sleep(for:.milliseconds(600))
            let expected=try policy.run("feedSanitize",.object(["profiles":.array(values)]));XCTAssertEqual(model.posts.map(\.id),expected.array.map{$0["id"].string});XCTAssertFalse(model.feedLoading);XCTAssertNil(model.feedError)
            let nativeCards=try model.posts.filter{post in try policy.run("feedCard",.object(["profile":.object(["content":.string(post.event.content),"tags":.array(post.event.tags.map{.array($0.map(JSONValue.string))})])])) != .null}.count
            XCTAssertEqual(Double(nativeCards),observed["posts"].number);XCTAssertEqual(model.posts.isEmpty,observed["empty"].boolean)
            let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native Teams content \(state) \(language)";native.lifetime = .keepAlways;add(native)
            model.cancel();web.stopLoading();window.isHidden=true;window.rootViewController=nil
        }}
    }
}


@MainActor private final class TeamsStreamPreviewAccess:TeamsPreviewAccess {
    var held:CheckedContinuation<TeamsPanelSnapshot,Never>?
    var receive:(@MainActor(JSONValue)->Void)?
    var rowReads:[CheckedContinuation<[JSONValue],Error>]=[]
    override func load(_ app:AppModel)async throws->TeamsPanelSnapshot{await withCheckedContinuation{held=$0}}
    override func watchRoster(_ snapshot:TeamsPanelSnapshot,app:AppModel,onRecord:@escaping @MainActor(JSONValue)->Void,onInvalidate:@escaping @MainActor()->Void)async{receive=onRecord}
    override func memberRows(_ team:JSONValue,app:AppModel)async throws->[JSONValue]{try await withCheckedThrowingContinuation{rowReads.append($0)}}
    override func cancel(){held?.resume(returning:snapshot);held=nil;for row in rowReads{row.resume(throwing:CancellationError())};rowReads=[];receive=nil}
    func finishRows(_ result:Result<[JSONValue],Error>){guard !rowReads.isEmpty else{return};rowReads.removeFirst().resume(with:result)}
}
extension TeamsPanelReferenceTests {
    func testOriginalCachedRosterCardUpdatesWhileFreshRosterAndMemberReadsAreHeld()async throws {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated source preview required")}
        var fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"teams-panel-preview",withExtension:"json"))))
        fixture=fixture.setting("teams",.array(fixture["teams"].array.map{$0.setting("nostr",.null)}))
        let app=AppModel(progressService:TeamsNoCloud());try app.identity.create();app.signedIn=true;defer{app.signOut()};let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for(language,theme)in [("en","light"),("ar","dark")] {
            app.learner.support=language;let access=TeamsStreamPreviewAccess(fixture,state:"single"),model=TeamsPanelController(access:access,initial:access.snapshot,initialOwner:app.identity.npub)
            let sourceWindow=UIWindow(windowScene:scene);sourceWindow.frame=CGRect(x:0,y:0,width:402,height:874);let web=WKWebView(frame:sourceWindow.frame),vc=UIViewController();vc.view=web;sourceWindow.rootViewController=vc;sourceWindow.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            let nativeWindow=UIWindow(windowScene:scene);nativeWindow.frame=sourceWindow.frame;defer{model.cancel();web.stopLoading();sourceWindow.isHidden=true;sourceWindow.rootViewController=nil;nativeWindow.isHidden=true;nativeWindow.rootViewController=nil}
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-teams?state=stream&language=\(language)&theme=\(theme)"))))
            var ready=false;for _ in 0..<400{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded'&&typeof window.__releaseRosterRead==='function'&&document.querySelectorAll('[role=tab]').length===2")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(40))};XCTAssertTrue(ready);guard ready else{return}
            nativeWindow.rootViewController=UIHostingController(rootView:ZStack{PiyaliBrand(dark:theme == "dark").background;TeamsDrawerView(model:model,onClose:{})}.environmentObject(app).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());nativeWindow.makeKeyAndVisible()
            for _ in 0..<200 where access.receive == nil || access.held == nil{try await Task.sleep(for:.milliseconds(10))};XCTAssertNotNil(access.receive);XCTAssertNotNil(access.held);XCTAssertFalse(model.loading)
            func scroll(_ bottom:Bool)async throws {
                _=try await web.evaluateJavaScript("(()=>{const scroller=document.querySelector('.chakra-modal__body');scroller.scrollTop=\(bottom ? "scroller.scrollHeight":"0");return scroller.scrollTop})()")
                func findScroll(_ view:UIView)->UIScrollView?{if let value=view as? UIScrollView,value.bounds.height>100,value.contentSize.height>value.bounds.height{return value};for child in view.subviews{if let found=findScroll(child){return found}};return nil}
                nativeWindow.layoutIfNeeded();let scroller=try XCTUnwrap(findScroll(try XCTUnwrap(nativeWindow.rootViewController?.view)))
                scroller.setContentOffset(CGPoint(x:0,y:bottom ? max(0,scroller.contentSize.height-scroller.bounds.height+scroller.adjustedContentInset.bottom):-scroller.adjustedContentInset.top),animated:false)
                try await Task.sleep(for:.milliseconds(120))
            }
            func capture(_ phase:String)async throws {
                try await Task.sleep(for:.milliseconds(400));sourceWindow.makeKeyAndVisible();try await Task.sleep(for:.milliseconds(100));let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source Teams streamed \(phase) \(language)";source.lifetime = .keepAlways;add(source)
                let geometry=try await web.evaluateJavaScript("JSON.stringify({rowReads:window.__teamRowRequests.length,visible:[...document.querySelectorAll('[role=dialog],button,p')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,x:r.x,y:r.y,width:r.width,height:r.height,color:s.color,direction:s.direction}})})") as? String ?? "{}";let data=XCTAttachment(data:Data(geometry.utf8),uniformTypeIdentifier:"public.json");data.name="Source Teams streamed \(phase) \(language) geometry";data.lifetime = .keepAlways;add(data)
                nativeWindow.makeKeyAndVisible();try await Task.sleep(for:.milliseconds(100));let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:nativeWindow.bounds).image{_ in nativeWindow.drawHierarchy(in:nativeWindow.bounds,afterScreenUpdates:true)});native.name="Native Teams streamed \(phase) \(language)";native.lifetime = .keepAlways;add(native)
            }
            try await capture("cached")
            let team=fixture["teams"].array[0],update=team.setting("teamName",.string("Cached peer roster")).setting("members",.array(team["members"].array+[.object(["npub":fixture["streamPendingNpub"],"status":.string("pending")])]))
            _=try await web.evaluateJavaScript("void window.__emitTeamRecord({...window.__teamsFixture.teams[0],teamName:'Cached peer roster',members:[...window.__teamsFixture.teams[0].members,{npub:window.__teamsFixture.streamPendingNpub,status:'pending'}]});true")
            access.receive?(update);for _ in 0..<200 where access.rowReads.isEmpty{try await Task.sleep(for:.milliseconds(10))};XCTAssertEqual(model.snapshot.teams.first?["teamName"].string,"Cached peer roster");XCTAssertNotNil(access.held);XCTAssertFalse(model.loading);try await capture("member-held");try await scroll(true);try await capture("member-held-bottom");try await scroll(false)
            _=try await web.evaluateJavaScript("window.__rejectTeamRow(0);true");access.finishRows(.failure(AppError.message("Public member read failure")));let key=LiveTeamsPanelAccess.key(team);for _ in 0..<200 where model.rowErrors[key] == nil{try await Task.sleep(for:.milliseconds(10))};XCTAssertNotNil(model.rowErrors[key]);XCTAssertNil(model.error);try await capture("member-failed")
            _=try await web.evaluateJavaScript("void window.__emitTeamRecord({...window.__teamsFixture.teams[0],teamName:'Cached peer roster',members:[...window.__teamsFixture.teams[0].members,{npub:window.__teamsFixture.streamPendingNpub,status:'pending'}]});true");access.receive?(update);for _ in 0..<200 where access.rowReads.isEmpty{try await Task.sleep(for:.milliseconds(10))}
            let rows=fixture["rows"][team["id"].string].array.map{$0["isCreator"].boolean ? $0:$0.setting("totalXp",.number(778))}
            _=try await web.evaluateJavaScript("window.__releaseTeamRow(1,window.__teamsFixture.rows[window.__teamsFixture.teams[0].id].map(row=>row.isCreator?row:{...row,totalXp:778}));true");access.finishRows(.success(rows));for _ in 0..<200 where model.rowErrors[key] != nil{try await Task.sleep(for:.milliseconds(10))};XCTAssertEqual(model.snapshot.rows[key],rows);XCTAssertNotNil(access.held);try await capture("member-recovered");try await scroll(true);try await capture("member-recovered-bottom");try await scroll(false)
            model.cancel();sourceWindow.isHidden=true;sourceWindow.rootViewController=nil;nativeWindow.isHidden=true;nativeWindow.rootViewController=nil
        }
    }
}

@MainActor private final class TeamsStagedPreviewAccess:TeamsPreviewAccess {
    let stage:TeamsPanelSnapshot,settled:TeamsPanelSnapshot
    var roster:CheckedContinuation<Void,Never>?,members:CheckedContinuation<TeamsPanelSnapshot,Never>?
    init(_ fixture:JSONValue,selfRow:JSONValue,joined:Bool){
        let team=fixture["teams"].array[0].setting("nostr",.null),key=LiveTeamsPanelAccess.key(team)
        stage = .init(teams:[team],rows:joined ? [:]:[key:[selfRow]],loadingRows:[key])
        settled = .init(teams:[team],rows:joined ? [:]:[key:fixture["rows"][team["id"].string].array],failedRows:joined ? [key]:[])
        super.init(fixture,state:"single")
    }
    override func loadStaged(_ app:AppModel,onRoster:@escaping @MainActor(TeamsPanelSnapshot)async->Void)async throws->TeamsPanelSnapshot{await withCheckedContinuation{roster=$0};await onRoster(stage);return await withCheckedContinuation{members=$0}}
    override func cancel(){roster?.resume();roster=nil;members?.resume(returning:settled);members=nil}
}
extension TeamsPanelReferenceTests {
    func testOriginalInitialRosterCreatorSkeletonAndJoinedFailureStages()async throws {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated reference required")}
        let fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"teams-panel-preview",withExtension:"json"))))
        let app=AppModel(progressService:TeamsNoCloud());try app.identity.create();app.signedIn=true;defer{app.signOut()};let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for(language,theme)in [("en","light"),("ar","dark")] {for joined in [false,true] {
            app.learner.support=language;let role=joined ? "joined":"owner",state="staged-"+role
            let sourceWindow=UIWindow(windowScene:scene);sourceWindow.frame=CGRect(x:0,y:0,width:402,height:874);let web=WKWebView(frame:sourceWindow.frame),vc=UIViewController();vc.view=web;sourceWindow.rootViewController=vc;sourceWindow.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-teams?state=\(state)&language=\(language)&theme=\(theme)"))))
            var ready=false;for _ in 0..<300{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded'&&typeof window.__releaseStagedRoster==='function'&&document.querySelectorAll('[role=tab]').length===2")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(40))};XCTAssertTrue(ready);guard ready else{return}
            let sourceFixture=try await web.evaluateJavaScript("JSON.stringify(window.__teamsFixture)") as? String ?? "{}",selfJSON=try await web.evaluateJavaScript("JSON.stringify(window.__stageSelf)") as? String ?? "{}"
            let f=try JSONDecoder().decode(JSONValue.self,from:Data(sourceFixture.utf8)),selfRow=try JSONDecoder().decode(JSONValue.self,from:Data(selfJSON.utf8)),access=TeamsStagedPreviewAccess(f,selfRow:selfRow,joined:joined),model=TeamsPanelController(access:access),nativeWindow=UIWindow(windowScene:scene);nativeWindow.frame=sourceWindow.frame
            defer{model.cancel();web.stopLoading();sourceWindow.isHidden=true;sourceWindow.rootViewController=nil;nativeWindow.isHidden=true;nativeWindow.rootViewController=nil}
            nativeWindow.rootViewController=UIHostingController(rootView:ZStack{PiyaliBrand(dark:theme == "dark").background;TeamsDrawerView(model:model,onClose:{})}.environmentObject(app).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());nativeWindow.makeKeyAndVisible()
            for _ in 0..<200 where access.roster == nil{try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(model.loading)
            func capture(_ phase:String)async throws {
                try await Task.sleep(for:.milliseconds(400));sourceWindow.makeKeyAndVisible();try await Task.sleep(for:.milliseconds(80));let a=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));a.name="Source Teams staged \(role) \(phase) \(language)";a.lifetime = .keepAlways;add(a)
                let geometry=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('p,.chakra-skeleton')].map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,x:r.x,y:r.y,width:r.width,height:r.height,background:s.backgroundColor,animation:s.animation,color:s.color}}))") as? String ?? "[]",g=XCTAttachment(data:Data(geometry.utf8),uniformTypeIdentifier:"public.json");g.name=(a.name ?? "Source Teams staged")+" geometry";g.lifetime = .keepAlways;add(g)
                nativeWindow.makeKeyAndVisible();try await Task.sleep(for:.milliseconds(80));let b=XCTAttachment(image:UIGraphicsImageRenderer(bounds:nativeWindow.bounds).image{_ in nativeWindow.drawHierarchy(in:nativeWindow.bounds,afterScreenUpdates:true)});b.name="Native Teams staged \(role) \(phase) \(language)";b.lifetime = .keepAlways;add(b)
            }
            try await capture("global")
            _=try await web.evaluateJavaScript("window.__releaseStagedRoster();true");access.roster?.resume();access.roster=nil
            for _ in 0..<200 where access.members == nil{try await Task.sleep(for:.milliseconds(10))};XCTAssertFalse(model.loading);XCTAssertEqual(model.snapshot.loadingRows.count,1);try await capture("members")
            _=try await web.evaluateJavaScript("(()=>{const e=document.querySelector('.chakra-modal__body');e.scrollTop=e.scrollHeight;return true})()")
            func find(_ v:UIView)->UIScrollView?{if let s=v as? UIScrollView,s.bounds.height>100,s.contentSize.height>s.bounds.height{return s};for c in v.subviews{if let s=find(c){return s}};return nil}
            let scroll=find(try XCTUnwrap(nativeWindow.rootViewController?.view));scroll?.setContentOffset(CGPoint(x:0,y:max(0,(scroll?.contentSize.height ?? 0)-(scroll?.bounds.height ?? 0))),animated:false);try await capture("members-bottom")
            _=try await web.evaluateJavaScript(joined ? "window.__rejectTeamRow(0);true":"window.__releaseTeamRow(0,window.__teamsFixture.rows[window.__teamsFixture.teams[0].id]);true");access.members?.resume(returning:access.settled);access.members=nil
            for _ in 0..<200 where !model.snapshot.loadingRows.isEmpty{try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(model.snapshot.loadingRows.isEmpty);XCTAssertEqual(model.snapshot.failedRows.count,joined ? 1:0)
            _=try await web.evaluateJavaScript("document.querySelector('.chakra-modal__body').scrollTop=0;true");scroll?.setContentOffset(.zero,animated:false);try await capture("settled")
            model.cancel()
        }}
    }
}
