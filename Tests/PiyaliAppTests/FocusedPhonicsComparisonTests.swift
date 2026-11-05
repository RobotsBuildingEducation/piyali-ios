import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor private final class PhonicsComparisonStore:LearnerProgressService {
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{var s=state;s.pendingChanges=[];s.pendingGoalChanges=[];s.pendingMemoryChanges=[];s.pendingCompanionQuestDays=[:];s.pendingRepairEvidence=[];return s}
}
@MainActor final class FocusedPhonicsComparisonTests:XCTestCase {
    func testOriginalFocusedDeckAndPracticeWrongRetryCorrectAgainstNativeInEnglishAndArabic()async throws {
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",e["PIYALI_PHONICS_FIXTURE"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated source/phonics fixtures required")}
        let app=AppModel(progressService:PhonicsComparisonStore());try app.identity.create();app.signedIn=true;app.subscription.bind(app.identity);defer{try? app.identity.disconnect()}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow}
        for (language,theme) in [("en","light"),("ar","dark")] {for kind in ["goal","repair"] {
            app.learner=LearnerState();app.learner.onboardingComplete=true;app.learner.support=language;await app.reloadContent();app.learner.editGoal("Pronounce Spanish clearly")
            let day=CalendarDay.key(Date()),bp:JSONValue = .object(["goalId":app.learner.goalBucket["activeGoal"]["id"],"goalText":.string(app.learner.goal),"dayKey":.string(day),"lang":.string("es"),"mode":.string("phonics"),"modes":.array(["phonics","lesson"].map(JSONValue.string)),"modeTargets":.object(["phonics":.number(2),"lesson":.number(20)]),"cefrLevel":.string("Pre-A1"),"objective":.string("Pronounce casa and mesa"),"targetLanguage":.array([.string("casa")])])
            app.learner.applyGoal(.init(action:.blueprint,target:"es",payload:bp))
            let plan:JSONValue = .object(["dayKey":.string(day),"targetLang":.string("es"),"target":.number(1),"items":.array([.object(["memoryId":.string("public-pronunciation"),"concept":.string("casa"),"expectedAnswer":.string("casa"),"mode":.string("phonics"),"errorType":.string("phonics"),"cefrLevel":.string("Pre-A1")])])]);app.learner.storeCompanionBlueprint(.object(["status":.string("ready"),"repair":plan]),target:"es",day:day)
            let engine=try XCTUnwrap(app.companionQuestPolicy),step=try JSONDecoder().decode(RepairStep.self,from:Data(engine.run("next",.object(["plan":plan,"completedCount":.number(0)])).json.utf8));var artifact=try app.focusedPhonicsDeck(goal:kind == "goal" ? bp:nil,repair:kind == "repair" ? step:nil);let cards=artifact["cards"].array,first=try XCTUnwrap(cards.first)
            artifact=artifact.setting("outcomes",.object([first["id"].string:.object(["success":.bool(true),"support":.string("modeled"),"item":first["practiceWord"]])]))
            if kind == "goal"{app.learner.applyGoal(.init(action:.artifact,target:"es",payload:bp.setting("cards",artifact["cards"])));let key=GoalPractice.artifactKey(target:"es",day:day,mode:"phonics",goalID:bp["goalId"].string);app.learner.goalArtifacts?[key]=artifact}
            else{app.learner.storeRepairArtifact(artifact,step:step,mode:"phonics")}
            app.learner.pendingGoalChanges=[];app.learner.pendingCompanionQuestDays=[:];let saved=app.learner
            let focus:JSONValue = kind == "goal" ? .object(["npub":.string(app.identity.npub),"targetLang":.string("es"),"supportLang":.string(language),"surface":.string("alphabet"),"blueprint":bp]):.object(["npub":.string(app.identity.npub),"targetLang":.string("es"),"supportLang":.string(language),"surface":.string("alphabet"),"mode":.string("phonics"),"stepIndex":.number(0),"stepCount":.number(1),"plan":step.plan])
            let input:JSONValue = .object(["kind":.string(kind),"language":.string(language),"focus":focus,"artifact":artifact,"user":app.learner.companionQuestUser.setting("local_npub",.string(app.identity.npub))])
            let publicInput=XCTAttachment(data:Data(input.json.utf8),uniformTypeIdentifier:"public.json");publicInput.name="Public focused phonics \(kind) \(language) input";publicInput.lifetime = .keepAlways;add(publicInput)
            let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:config),vc=UIViewController(),sourceWindow=UIWindow(windowScene:scene);vc.view=web;sourceWindow.frame=web.frame;sourceWindow.rootViewController=vc;sourceWindow.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            defer{web.stopLoading();sourceWindow.isHidden=true;sourceWindow.rootViewController=nil;old?.makeKey()}
            var url=URLComponents(string:"http://127.0.0.1:5181/__piyali-focused-phonics")!;url.queryItems=[.init(name:"snapshot",value:input.json),.init(name:"theme",value:theme)];web.load(URLRequest(url:try XCTUnwrap(url.url)))
            var ready=false
            for _ in 0..<600{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && !!document.querySelector('[data-phonics-active-card]')")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))}
            if !ready{XCTFail(String(describing:try? await web.evaluateJavaScript("JSON.stringify({text:document.body.innerText,html:document.body.innerHTML.slice(0,1000),state:document.readyState,boot:window.fixtureBoot,errors:fixtureErrors,scripts:[...document.scripts].map(s=>s.src)})")));return}
            let policy=try PhonicsPolicy(engine:engine)
            func click(_ key:String)async throws{let label=String(data:try JSONEncoder().encode(policy.copy(key,language:language,target:"es")),encoding:.utf8)!,found=try await web.evaluateJavaScript("(()=>{const b=[...document.querySelectorAll('[data-activity-action-row] button')].find(b=>b.textContent.trim()===\(label));if(!b)return false;b.click();return true})()");XCTAssertEqual(found as? Bool,true,key)}
            for state in ["front","practice","wrong","correct"] {
                if state == "practice"{try await click("practice")};if state == "wrong"{try await click("record")};if state == "correct"{try await click("tryAgain");try await click("record")};try await Task.sleep(for:.milliseconds(state == "front" || state == "practice" ? 700:1500))
                let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source focused phonics \(kind) \(state) \(language)";source.lifetime = .keepAlways;add(source)
                let metrics=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('p,button,[data-phonics-active-card]')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,x:r.x,y:r.y,width:r.width,height:r.height,fontSize:s.fontSize,lineHeight:s.lineHeight}}))"),geometry=XCTAttachment(data:Data(try XCTUnwrap(metrics as? String).utf8),uniformTypeIdentifier:"public.json");geometry.name="Source focused phonics \(kind) \(state) \(language) geometry";geometry.lifetime = .keepAlways;add(geometry)
                app.learner=saved;let course=PhonicsCourseController(goal:kind == "goal" ? bp:nil,repair:kind == "repair" ? step:nil),window=UIWindow(windowScene:scene);window.frame=web.frame;window.rootViewController=UIHostingController(rootView:FocusedPhonicsSnapshotHost(course:course,bp:kind == "goal" ? bp:nil,step:kind == "repair" ? step:nil).environmentObject(app).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());window.makeKeyAndVisible()
                for _ in 0..<250 where course.currentSession == nil{try await Task.sleep(for:.milliseconds(20))};let session=try XCTUnwrap(course.currentSession);XCTAssertEqual(course.collected.count,1)
                if state != "front"{session.practice(app)}
                if state == "wrong" || state == "correct"{session.submit("WRONG_FIXTURE",app:app);for _ in 0..<250 where session.busy{try await Task.sleep(for:.milliseconds(20))};XCTAssertEqual(session.grade?.correct,false)}
                if state == "correct"{session.retry();session.submit(session.card["practiceWord"].string,app:app);for _ in 0..<250 where session.busy{try await Task.sleep(for:.milliseconds(20))};XCTAssertEqual(session.grade?.correct,true);XCTAssertNil(session.error);XCTAssertEqual(app.learner.totalXP,2)}
                try await Task.sleep(for:.milliseconds(700));let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native focused phonics \(kind) \(state) \(language)";native.lifetime = .keepAlways;add(native);session.cancel();window.isHidden=true;window.rootViewController=nil;sourceWindow.makeKeyAndVisible()
            }
            let recorded=try await web.evaluateJavaScript("JSON.stringify({writes:window.__focusedPhonics.writes,artifact:window.__focusedPhonics.artifact})"),raw=try XCTUnwrap(recorded as? String),result=try JSONDecoder().decode(JSONValue.self,from:Data(raw.utf8)),writes=result["writes"].array
            XCTAssertEqual(writes.filter{$0.array.first?.string == "xp"}.count,1);XCTAssertEqual(writes.first{$0.array.first?.string == "xp"}?.array[1].array[1].number,2);XCTAssertEqual(writes.filter{$0.array.first?.string == "memory"}.count,kind == "goal" ? 0:1)
            if kind == "goal"{let expected=try engine.run("focusedPhonicsCompletion",.object(["goal":.bool(true),"artifact":result["artifact"]]));XCTAssertTrue(expected["complete"].boolean);XCTAssertEqual(writes.first{$0.array.first?.string == "attempt"}?.array[1].array[1]["observation"],expected["observation"])}else{XCTAssertTrue(writes.filter{$0.array.first?.string == "repair"}.isEmpty)}
            let trace=XCTAttachment(data:Data(raw.utf8),uniformTypeIdentifier:"public.json");trace.name="Source actual focused phonics \(kind) \(language) writes";trace.lifetime = .keepAlways;add(trace)
        }}
    }
}
private struct FocusedPhonicsSnapshotHost:View {
    @EnvironmentObject var app:AppModel
    let course:PhonicsCourseController,bp:JSONValue?,step:RepairStep?
    var body:some View{PhonicsView(repairStep:step,goalBlueprint:bp,controller:course).ignoresSafeArea().overlay(alignment:.bottom){if let footer=app.activityFooter{footer.content.padding(12).background{SourceActivityDockBackground(correct:footer.correct)}.padding(.horizontal,8).padding(.bottom,12)}}}
}


@MainActor private final class PhonicsOfflineComparisonStore:LearnerProgressService {
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
extension FocusedPhonicsComparisonTests {
    func testOriginalFreshOfflineAuthoredGoalAndRepairFrontAndPracticeAgainstNative()async throws {
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",e["PIYALI_PHONICS_FIXTURE"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated source/phonics fixtures required")}
        let app=AppModel(progressService:PhonicsOfflineComparisonStore());try app.identity.create();app.signedIn=true;app.subscription.bind(app.identity);defer{try? app.identity.disconnect()};let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow}
        for (language,theme) in [("en","light"),("ar","dark")] {for kind in ["goal","repair"] {
            app.learner=LearnerState();app.learner.onboardingComplete=true;app.learner.support=language;await app.reloadContent();app.learner.editGoal("Pronounce Spanish clearly")
            let day=CalendarDay.key(Date()),bp:JSONValue = .object(["goalId":app.learner.goalBucket["activeGoal"]["id"],"lang":.string("es"),"dayKey":.string(day),"mode":.string("phonics"),"modes":.array(["phonics","lesson"].map(JSONValue.string)),"cefrLevel":.string("Pre-A1"),"targetLanguage":.array([.string("casa")])]),plan:JSONValue = .object(["dayKey":.string(day),"targetLang":.string("es"),"target":.number(1),"items":.array([.object(["memoryId":.string("public-pronunciation"),"expectedAnswer":.string("casa"),"concept":.string("casa"),"mode":.string("phonics"),"errorType":.string("phonics"),"cefrLevel":.string("Pre-A1")])])])
            app.learner.applyGoal(.init(action:.blueprint,target:"es",payload:bp));app.learner.storeCompanionBlueprint(.object(["status":.string("ready"),"repair":plan]),target:"es",day:day);app.learner.pendingGoalChanges=[];app.learner.pendingCompanionQuestDays=[:]
            let engine=try XCTUnwrap(app.companionQuestPolicy),step=try XCTUnwrap(app.currentRepairStep),focus:JSONValue = .object(["npub":.string(app.identity.npub),"targetLang":.string("es"),"supportLang":.string(language),"surface":.string("alphabet")]).setting(kind == "goal" ? "blueprint":"plan",kind == "goal" ? bp:plan).setting("stepIndex",.number(0)),input:JSONValue = .object(["kind":.string(kind),"language":.string(language),"focus":focus,"artifact":.null,"offlineArtifacts":.bool(true),"user":app.learner.companionQuestUser.setting("local_npub",.string(app.identity.npub))])
            let payload=XCTAttachment(data:Data(input.json.utf8),uniformTypeIdentifier:"public.json");payload.name="Public fresh offline phonics \(kind) \(language) input";payload.lifetime = .keepAlways;add(payload)
            let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:config),sourceWindow=UIWindow(windowScene:scene),vc=UIViewController();sourceWindow.frame=web.frame;vc.view=web;sourceWindow.rootViewController=vc;sourceWindow.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never;defer{web.stopLoading();sourceWindow.isHidden=true;sourceWindow.rootViewController=nil;old?.makeKey()}
            var url=URLComponents(string:"http://127.0.0.1:5181/__piyali-focused-phonics")!;url.queryItems=[.init(name:"snapshot",value:input.json),.init(name:"theme",value:theme)];web.load(URLRequest(url:try XCTUnwrap(url.url)))
            var ready=false;for _ in 0..<600{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && !!document.querySelector('[data-phonics-active-card]')")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};guard ready else{XCTFail(String(describing:try? await web.evaluateJavaScript("JSON.stringify({errors:fixtureErrors,text:document.body.innerText})")));return}
            let evaluated=try await web.evaluateJavaScript("JSON.stringify({artifact:window.__focusedPhonics.artifact,calls:window.__focusedPhonics.calls})"),raw=try XCTUnwrap(evaluated as? String),result=try JSONDecoder().decode(JSONValue.self,from:Data(raw.utf8));XCTAssertTrue(result["artifact"]["outcomes"].object.isEmpty);XCTAssertEqual(result["calls"].array.map(\.string),["local-read","remote-read","transaction","local-write"])
            let trace=XCTAttachment(data:Data(raw.utf8),uniformTypeIdentifier:"public.json");trace.name="Source fresh offline phonics \(kind) \(language) cache trace";trace.lifetime = .keepAlways;add(trace)
            let course=PhonicsCourseController(goal:kind == "goal" ? bp:nil,repair:kind == "repair" ? step:nil),nativeWindow=UIWindow(windowScene:scene);nativeWindow.frame=web.frame;nativeWindow.rootViewController=UIHostingController(rootView:FocusedPhonicsSnapshotHost(course:course,bp:kind == "goal" ? bp:nil,step:kind == "repair" ? step:nil).environmentObject(app).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());nativeWindow.makeKeyAndVisible();defer{nativeWindow.isHidden=true;nativeWindow.rootViewController=nil}
            for _ in 0..<250 where course.currentSession == nil{try await Task.sleep(for:.milliseconds(20))};let session=try XCTUnwrap(course.currentSession);XCTAssertTrue(course.initialized);XCTAssertNil(course.error);XCTAssertEqual(course.deck,result["artifact"]["cards"].array);XCTAssertTrue(course.collected.isEmpty)
            for state in ["front","practice"] {
                if state == "practice"{let policy=try PhonicsPolicy(engine:engine),label=String(decoding:try JSONEncoder().encode(policy.copy("practice",language:language,target:"es")),as:UTF8.self);let found=try await web.evaluateJavaScript("(()=>{const b=[...document.querySelectorAll('[data-activity-action-row] button')].find(b=>b.textContent.trim()===\(label));if(!b)return false;b.click();return true})()");XCTAssertEqual(found as? Bool,true);session.practice(app)}
                try await Task.sleep(for:.milliseconds(700));let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source fresh offline phonics \(kind) \(state) \(language)";source.lifetime = .keepAlways;add(source)
                let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:nativeWindow.bounds).image{_ in nativeWindow.drawHierarchy(in:nativeWindow.bounds,afterScreenUpdates:true)});native.name="Native fresh offline phonics \(kind) \(state) \(language)";native.lifetime = .keepAlways;add(native)
            }
            XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.gradedByLanguage);session.cancel();nativeWindow.isHidden=true;nativeWindow.rootViewController=nil;sourceWindow.isHidden=true;sourceWindow.rootViewController=nil
        }}
    }
}
