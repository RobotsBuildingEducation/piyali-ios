import XCTest
import SwiftUI
import WebKit
import FirebaseFirestore
@testable import Piyali

@MainActor private final class StartupAccess:TeamsStartupAccess {
    var next=TeamsPanelSnapshot(),hold=false,reads=0,feeds=0,cancels=0
    var pending:[CheckedContinuation<TeamsPanelSnapshot,Never>]=[]
    var callbacks:[@MainActor([JSONValue])->Void]=[]
    var failures:[@MainActor(Error)->Void]=[]
    var failLoads=0,failWatches=0
    func preload(_ app:AppModel)async throws->TeamsPanelSnapshot {reads += 1;if failLoads>0{failLoads -= 1;throw URLError(.notConnectedToInternet)};if hold{return await withCheckedContinuation{pending.append($0)}};return next}
    func watchInvites(_ app:AppModel,onChange:@escaping @MainActor([JSONValue])->Void,onFailure:@escaping @MainActor(Error)->Void)async throws{callbacks.append(onChange);failures.append(onFailure);if failWatches>0{failWatches -= 1;throw URLError(.notConnectedToInternet)}}
    func preloadFeed(_ app:AppModel)async{feeds += 1}
    func cancel(){cancels += 1}
}
@MainActor private final class StartupDrawerAccess:TeamsPanelAccess {
    var held:CheckedContinuation<TeamsPanelSnapshot,Never>?
    func load(_ app:AppModel)async throws->TeamsPanelSnapshot{await withCheckedContinuation{held=$0}}
    func create(name:String,members:[String],app:AppModel)async throws->JSONValue{.null}
    func rename(_ team:JSONValue,name:String,app:AppModel)async throws->Bool{true}
    func add(_ team:JSONValue,members:[String],app:AppModel)async throws->Bool{true}
    func remove(_ team:JSONValue,app:AppModel)async throws{}
    func respond(_ invite:JSONValue,accept:Bool,app:AppModel)async throws{}
    func publish(_ app:AppModel)async throws{XCTFail("Startup/drawer preparation must not publish for legacy-only cached teams")}
    func feed(_ app:AppModel,force:Bool)async throws->[CommunityPost]{[]}
    func cancel(){}
}
@MainActor final class TeamsStartupTests:XCTestCase {
    private func app()throws->AppModel {let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated identity required")};let app=AppModel();try app.identity.create();app.signedIn=true;return app}
    private func invite(_ id:String,_ status:String="pending")->JSONValue {.object(["id":.string(id),"status":.string(status),"teamName":.string("Public invitation")])}
    private func until(_ predicate:()->Bool)async throws {for _ in 0..<200 where !predicate(){try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(predicate())}
    func testStartupReadsAndWatchesBeforeDrawerAndViewedSameIDsStayQuietUntilANewInvitation()async throws {
        let app=try app(),access=StartupAccess(),startup=TeamsStartupController(access:access);defer{startup.cancel();app.signOut()};access.hold=true
        startup.bind(app);startup.bind(app);try await until{access.pending.count==1 && access.callbacks.count==1 && access.feeds==1};XCTAssertEqual(access.reads,1);XCTAssertNil(startup.snapshot(app))
        access.callbacks[0]([invite("one")]);XCTAssertTrue(startup.attention.hasUnseen);XCTAssertEqual(startup.attention.count,1)
        let cached=TeamsPanelSnapshot(teams:[.object(["id":.string("cached"),"createdBy":.string(app.identity.npub)])],invites:[invite("outdated")])
        access.pending.removeFirst().resume(returning:cached);try await until{startup.initial != nil};XCTAssertEqual(startup.snapshot(app)?.invites.map{$0["id"].string},["one"])
        startup.viewed(app);access.callbacks[0]([invite("one").setting("teamName",.string("Renamed"))]);XCTAssertFalse(startup.attention.hasUnseen)
        access.callbacks[0]([invite("one"),invite("two")]);XCTAssertTrue(startup.attention.hasUnseen);XCTAssertEqual(startup.attention.count,2)
        startup.viewed(app);access.callbacks[0]([invite("one","accepted")]);XCTAssertFalse(startup.attention.hasUnseen);XCTAssertEqual(startup.attention.count,0)
        startup.cancel();access.callbacks[0]([invite("late")]);XCTAssertFalse(startup.attention.hasUnseen);XCTAssertNil(startup.snapshot(app));XCTAssertNil(startup.invites)
    }
    func testAccountReplacementRejectsOldLoadAndSubscriptionWithoutRestartingOnLanguageChanges()async throws {
        let app=try app(),access=StartupAccess(),startup=TeamsStartupController(access:access);defer{startup.cancel();app.signOut()};access.hold=true;startup.bind(app);try await until{access.pending.count==1 && access.callbacks.count==1}
        let old=access.pending.removeFirst();try app.identity.create();access.hold=false;access.next = .init(teams:[.object(["id":.string("new-owner")])]);startup.bind(app);try await until{access.callbacks.count==2 && startup.initial != nil}
        access.callbacks[0]([invite("old-account")]);old.resume(returning:.init(teams:[.object(["id":.string("stale")])]));try await Task.sleep(for:.milliseconds(30));XCTAssertEqual(startup.snapshot(app)?.teams.first?["id"].string,"new-owner");XCTAssertFalse(startup.attention.hasUnseen)
        access.callbacks[1]([invite("new-account")]);XCTAssertTrue(startup.attention.hasUnseen);app.learner.support="ar";app.learner.target="fr";startup.bind(app);XCTAssertEqual(access.reads,2);XCTAssertEqual(access.feeds,2)
        app.signedIn=false;startup.bind(app);XCTAssertEqual(startup.attention.count,0);XCTAssertNil(startup.initial)
    }
    func testPreloadedEmptyAndNonemptyDrawersRemainVisibleWhileTheirFirstFreshReadIsHeld()async throws {
        let app=try app();defer{app.signOut()}
        for teams in [[],[JSONValue.object(["id":.string("cached-team"),"createdBy":.string(app.identity.npub)])]] {
            let access=StartupDrawerAccess(),initial=TeamsPanelSnapshot(teams:teams,invites:[invite("pending")]),drawer=TeamsPanelController(access:access,initial:initial,initialOwner:app.identity.npub)
            let task=Task{await drawer.reload(app)};try await until{access.held != nil};XCTAssertFalse(drawer.loading);XCTAssertEqual(drawer.snapshot,initial)
            access.held?.resume(returning:.init());access.held=nil;await task.value;XCTAssertTrue(drawer.snapshot.teams.isEmpty);drawer.cancel()
        }
    }
    func testActualFirebaseInvitationWatchIncludesLegacyAndPublicRecordsAndSurvivesDrawerWatchClose()async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_FIRESTORE_EMULATOR_TESTS"] == "1" else{throw XCTSkip("Local SDK opt-in required")}
        let app=try app(),db=PrivateTeamTestDatabase.database(),mirror=TeamsMirrorService(database:db);defer{mirror.stopWatchingInvitations();app.signOut()};var records:[JSONValue]?;try await mirror.watchInvitations(identity:app.identity){records=$0};try await until{records != nil}
        let collection=db.collection("users").document(app.identity.npub).collection("teamInvites")
        try await collection.document("legacy").setData(["teamName":"Legacy public fixture","status":"pending"])
        try await collection.document("public").setData(["teamName":"Public roster fixture","status":"accepted","nostr":["id":"public"]])
        try await until{records?.count==2};XCTAssertEqual(Set((records ?? []).map{$0["id"].string}),["legacy","public"])
        mirror.stopWatching();try await collection.document("new").setData(["status":"pending"]);try await until{records?.count==3}
        mirror.stopWatchingInvitations();try await collection.document("late").setData(["status":"pending"]);try await Task.sleep(for:.milliseconds(200));XCTAssertEqual(records?.count,3)
        for id in ["legacy","public","new","late"]{try await collection.document(id).delete()}
    }
}


extension TeamsStartupTests {
    func testOriginalAppBadgeAndNativeMenuControlAcrossViewedAndNewInvitesInEnglishAndArabic()async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1" else{throw XCTSkip("Read-only source preview opt-in required")}
        let app=try app();defer{app.signOut()};let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow}
        for (language,theme) in [("en","light"),("ar","dark")] {
            app.learner.support=language;let access=StartupAccess(),startup=TeamsStartupController(access:access);startup.bind(app);try await until{access.callbacks.count==1}
            let window=UIWindow(windowScene:scene),web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874)),host=UIViewController();host.view=web;window.rootViewController=host;window.frame=web.frame;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil;startup.cancel();old?.makeKey()}
            web.load(URLRequest(url:try XCTUnwrap(URL(string:"http://127.0.0.1:5181/__piyali-teams-startup?language=\(language)&theme=\(theme)"))))
            var ready=false;for _ in 0..<500{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && typeof window.__emitTeamInvites==='function' && !!document.querySelector('[data-bottom-navigation] button')")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(40))};XCTAssertTrue(ready);guard ready else{return}
            for state in ["pending","viewed","same-id","new-id"] {
                let values=[invite("one")]+(state == "new-id" ? [invite("two")]:[])
                if state == "viewed"{_=try await web.evaluateJavaScript("window.__viewTeamInvites()");startup.viewed(app)}else{let json=String(decoding:try JSONEncoder().encode(values),as:UTF8.self);_=try await web.evaluateJavaScript("window.__emitTeamInvites(\(json))");access.callbacks[0](values)}
                try await Task.sleep(for:.milliseconds(250));let expected=state == "pending" || state == "new-id";let observed=try await web.evaluateJavaScript("window.__teamAttention.unseen");XCTAssertEqual(observed as? Bool,expected);XCTAssertEqual(startup.attention.hasUnseen,expected)
                let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source App invitation badge \(state) \(language)";source.lifetime = .keepAlways;add(source)
                let geometry=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('[data-bottom-navigation] button,[data-bottom-navigation] button div')].map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {role:e.getAttribute('role'),label:e.getAttribute('aria-label'),x:r.x,y:r.y,width:r.width,height:r.height,background:s.backgroundColor,border:s.borderWidth}}))"),metrics=XCTAttachment(data:Data((geometry as? String ?? "").utf8),uniformTypeIdentifier:"public.json");metrics.name="Source App invitation badge \(state) \(language) geometry";metrics.lifetime = .keepAlways;add(metrics)
                let native=UIWindow(windowScene:scene);native.frame=web.frame;let brand=PiyaliBrand(dark:theme == "dark"),content=ZStack(alignment:.bottom){brand.background;TeamInviteMenuButton(startup:startup,capture:app.memoryCapture,scope:app.memoryCaptureScope,language:language,label:EntryCopy.ui(language,"app_mode_plate"),glyphSize:22,size:66,radius:40,background:brand.surface.opacity(0.92),border:brand.border,foreground:brand.text,dotBorder:brand.background,standalone:true,action:{}).padding(.bottom,12)}.ignoresSafeArea().preferredColorScheme(theme == "dark" ? .dark:.light)
                native.rootViewController=UIHostingController(rootView:content);native.makeKeyAndVisible();native.layoutIfNeeded();try await Task.sleep(for:.milliseconds(200));let shot=XCTAttachment(image:UIGraphicsImageRenderer(bounds:native.bounds).image{_ in native.drawHierarchy(in:native.bounds,afterScreenUpdates:true)});shot.name="Native App invitation badge \(state) \(language)";shot.lifetime = .keepAlways;add(shot);native.isHidden=true;native.rootViewController=nil;window.makeKeyAndVisible()
            }
            startup.cancel();web.stopLoading();window.isHidden=true;window.rootViewController=nil
        };old?.makeKey()
    }
}


extension TeamsStartupTests {
    func testForegroundRetriesFailedPreparationAndWatchWithoutRepeatingViewedAttentionOrAcceptingOldCallbacks()async throws {
        let app=try app(),access=StartupAccess(),startup=TeamsStartupController(access:access);defer{startup.cancel();app.signOut()};access.failLoads=1;access.failWatches=1;startup.bind(app)
        try await until{startup.initial != nil && access.callbacks.count==1};XCTAssertNotNil(startup.initial?.warning)
        access.next = .init(teams:[.object(["id":.string("recovered")])]);startup.resumeAfterForeground(app);try await until{startup.initial?.teams.count==1 && access.callbacks.count==2}
        access.callbacks[0]([invite("stale-first-watch")]);XCTAssertFalse(startup.attention.hasUnseen)
        access.callbacks[1]([invite("original")]);startup.viewed(app);startup.resumeAfterForeground(app);try await Task.sleep(for:.milliseconds(30));XCTAssertEqual(access.reads,2);XCTAssertEqual(access.callbacks.count,2);XCTAssertFalse(startup.attention.hasUnseen);XCTAssertEqual(access.feeds,1)
        access.failures[1](URLError(.notConnectedToInternet));startup.resumeAfterForeground(app);try await until{access.callbacks.count==3}
        access.callbacks[1]([invite("obsolete-watch")]);XCTAssertEqual(startup.invites?.first?["id"].string,"original")
        access.callbacks[2]([invite("original")]);XCTAssertFalse(startup.attention.hasUnseen);access.callbacks[2]([invite("original"),invite("new")]);XCTAssertTrue(startup.attention.hasUnseen);XCTAssertEqual(startup.attention.count,2)
    }
}
