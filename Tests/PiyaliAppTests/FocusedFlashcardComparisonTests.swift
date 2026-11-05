import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor final class FocusedFlashcardComparisonTests:XCTestCase {
    func testOriginalFocusedTreeAndNativeLibraryStatsConfirmedCountsAndDeckInEnglishAndArabic()async throws {
        let e=ProcessInfo.processInfo.environment
        guard e["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Read-only source preview and isolated identity required")}
        let app=AppModel();try app.identity.create();app.signedIn=true;app.subscription.bind(app.identity);defer{try? app.identity.disconnect()}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow}
        for (language,theme) in [("en","light"),("ar","dark")] {for kind in ["goal","repair"] {
            app.learner=LearnerState();app.learner.onboardingComplete=true;app.learner.support=language;app.learner.target="es";app.learner.xpByLanguage=["es":10];app.learner.flashcardLevels=["es":"Pre-A1"];app.learner.editGoal("Speak with family")
            let day=CalendarDay.key(Date()),bp:JSONValue = .object(["goalId":app.learner.goalBucket["activeGoal"]["id"],"goalText":.string("Speak with family"),"dayKey":.string(day),"lang":.string("es"),"mode":.string("flashcards"),"modes":.array(["flashcards","lesson"].map(JSONValue.string)),"modeTargets":.object(["flashcards":.number(3),"lesson":.number(20)]),"cefrLevel":.string("Pre-A1"),"objective":.string("Name your family members"),"targetLanguage":.array(["papá","hermana","mamá"].map(JSONValue.string))])
            app.learner.applyGoal(.init(action:.blueprint,target:"es",payload:bp))
            let item:JSONValue = .object(["memoryId":.string("greeting"),"concept":.string("A greeting"),"expectedAnswer":.string("Hola"),"mode":.string("flashcards"),"errorType":.string("vocabulary"),"cefrLevel":.string("Pre-A1")]),plan:JSONValue = .object(["targetLang":.string("es"),"dayKey":.string(day),"target":.number(1),"items":.array([item]),"memoryIds":.array([.string("greeting")])])
            app.learner.storeCompanionBlueprint(.object(["status":.string("ready"),"repair":plan]),target:"es",day:day)
            let engine=try XCTUnwrap(app.companionQuestPolicy),step=try JSONDecoder().decode(RepairStep.self,from:Data(engine.run("next",.object(["plan":plan,"completedCount":.number(0)])).json.utf8))
            let cards:JSONValue = .array((kind == "goal" ? [("papá","dad","أبي"),("hermana","sister","أختي"),("mamá","mom","أمي")]:[("Hola","Hello","مرحباً"),("Gracias","Thanks","شكراً")]).enumerated().map{index,value in .object(["id":.string("public-\(kind)-c\(index)"),"concept":.object(["es":.string(value.0),"en":.string(value.1),"ar":.string(value.2)]),"category":.string(kind),"type":.string("phrase"),"cefrLevel":.string("Pre-A1"),kind == "goal" ? "isGoal":"isRepair":.bool(true)])})
            if kind == "goal" {app.learner.applyGoal(.init(action:.artifact,target:"es",payload:bp.setting("mode",.string("flashcards")).setting("cards",cards)));app.learner.applyGoal(.init(action:.outcome,target:"es",payload:bp.setting("mode",.string("flashcards")).setting("cardID",cards.array[0]["id"]).setting("success",.bool(true)).setting("support",.string("prompted"))))}
            else{app.learner.storeRepairArtifact(.object(["ownerKey":.string(CompanionQuestDay.artifactKey(step,mode:"flashcards")),"cards":cards,"outcomes":.object([:])]),step:step,mode:"flashcards");_ = app.learner.recordRepairOutcome(step,mode:"flashcards",cardID:cards.array[0]["id"].string,success:true,item:"Hola",support:"prompted")}
            app.learner.pendingGoalChanges=[];app.learner.pendingCompanionQuestDays=[:];app.learner.xpByLanguage=["es":10];await app.reloadContent()
            let artifact=kind == "goal" ? app.goalArtifact(bp,mode:"flashcards"):app.learner.repairArtifact(step,mode:"flashcards"),focus:JSONValue = kind == "goal" ? .object(["npub":.string(app.identity.npub),"targetLang":.string("es"),"supportLang":.string(language),"surface":.string("flashcards"),"blueprint":bp]):.object(["npub":.string(app.identity.npub),"targetLang":.string("es"),"supportLang":.string(language),"surface":.string("flashcards"),"mode":.string("flashcards"),"stepIndex":.number(0),"stepCount":.number(1),"plan":plan])
            let input:JSONValue = .object(["kind":.string(kind),"language":.string(language),"xp":.number(10),"focus":focus,"artifact":artifact,"user":app.learner.companionQuestUser.setting("local_npub",.string(app.identity.npub)).setting("progress",.object(["targetLang":.string("es")]))])
            let publicInput=XCTAttachment(data:Data(input.json.utf8),uniformTypeIdentifier:"public.json");publicInput.name="Public focused \(kind) \(language) input";publicInput.lifetime = .keepAlways;add(publicInput)
            let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:1100),configuration:config),vc=UIViewController(),window=UIWindow(windowScene:scene);vc.view=web;window.frame=web.frame;window.rootViewController=vc;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
            var url=URLComponents(string:"http://127.0.0.1:5181/__piyali-focused-flashcards")!;url.queryItems=[.init(name:"snapshot",value:input.json),.init(name:"theme",value:theme)];web.load(URLRequest(url:try XCTUnwrap(url.url)))
            let subtitle=try engine.run("focusedDeckSubtitle",.object(["answered":.number(1),"cards":cards,"language":.string(language)])).string,literal=String(data:try JSONEncoder().encode(subtitle),encoding:.utf8)!
            var ready=false
            for _ in 0..<600{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && document.body.innerText.includes(\(literal))")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))}
            if !ready{XCTFail(String(describing:try? await web.evaluateJavaScript("JSON.stringify({text:document.body.innerText,errors:fixtureErrors})")));return}
            try await Task.sleep(for:.milliseconds(2400))
            let title=try engine.run("focusedDeckTitle",.object(["goal":.bool(kind == "goal"),"language":.string(language)])).string,titleLiteral=String(data:try JSONEncoder().encode(title),encoding:.utf8)!
            let titleVisible=try await web.evaluateJavaScript("[...document.querySelectorAll('p')].some(p=>p.textContent===\(titleLiteral))");XCTAssertEqual(titleVisible as? Bool,true)

            let label=String(data:try JSONEncoder().encode(EntryCopy.ui(language,"flashcard_new_queue")),encoding:.utf8)!,count=try await web.evaluateJavaScript("[...document.querySelectorAll('p')].find(p=>p.textContent===\(label))?.nextElementSibling?.textContent")
            XCTAssertEqual((count as? String).flatMap(Int.init),app.cards.count,"Focused source dashboard still counts the ordinary authored library")
            let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source focused \(kind) \(language) confirmed one";source.lifetime = .keepAlways;add(source)
            let metrics=try await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('p,button')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,x:r.x,y:r.y,width:r.width,height:r.height,color:s.color,font:s.font,lineHeight:s.lineHeight,animation:s.animation,boxShadow:s.boxShadow}}))"),geometry=XCTAttachment(data:Data(try XCTUnwrap(metrics as? String).utf8),uniformTypeIdentifier:"public.json");geometry.name="Source focused \(kind) \(language) geometry";geometry.lifetime = .keepAlways;add(geometry)
            window.rootViewController=UIHostingController(rootView:FlashcardsView(repairStep:kind == "repair" ? step:nil,goalBlueprint:kind == "goal" ? bp:nil).environmentObject(app).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large).ignoresSafeArea().preferredColorScheme(theme == "dark" ? .dark:.light));window.rootViewController?.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(450))
            let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native focused \(kind) \(language) confirmed one";native.lifetime = .keepAlways;add(native)
            window.rootViewController=vc;window.makeKeyAndVisible()
            var writes:JSONValue = .array([])
            for index in 1..<cards.array.count {
                let result=try await web.callAsyncJavaScript("return JSON.stringify(await window.runFocusedRecall(index));",arguments:["index":index],in:nil,contentWorld:.page)
                writes=try JSONDecoder().decode(JSONValue.self,from:Data(try XCTUnwrap(result as? String).utf8))
                let expected=try engine.run("focusedDeckSubtitle",.object(["answered":.number(Double(index+1)),"cards":cards,"language":.string(language)])).string,quoted=String(data:try JSONEncoder().encode(expected),encoding:.utf8)!
                let countVisible=try await web.evaluateJavaScript("document.body.innerText.includes(\(quoted))");XCTAssertEqual(countVisible as? Bool,true)
                XCTAssertEqual(writes.array.filter{$0.array.first?.string == "outcome"}.count,index)
                XCTAssertEqual(writes.array.filter{$0.array.first?.string == "xp"}.count,index)
                XCTAssertTrue(writes.array.filter{$0.array.first?.string == "xp"}.allSatisfy{$0.array[1].array[1].number == 2})
                if kind == "goal" {
                    let evidence=try XCTUnwrap(writes.array.last{$0.array.first?.string == "evidence"}).array[1].array[0]["event"]
                    XCTAssertEqual(evidence,try engine.run("focusedRecallEvent",.object(["focus":focus,"card":cards.array[index],"success":.bool(true)])))
                    XCTAssertEqual(writes.array.filter{$0.array.first?.string == "attempt"}.count,index == cards.array.count-1 ? 1:0)
                }
            }
            if kind == "goal" {let event=try XCTUnwrap(writes.array.first{$0.array.first?.string == "attempt"}).array[1].array[1];XCTAssertEqual(event,try engine.run("focusedRecallCompletion",.object(["focus":focus,"cards":cards])))}
            else{XCTAssertEqual(writes.array.filter{$0.array.first?.string == "repair"}.count,1)}
            let recorded=XCTAttachment(data:Data(writes.json.utf8),uniformTypeIdentifier:"public.json");recorded.name="Source actual focused \(kind) \(language) completion writes";recorded.lifetime = .keepAlways;add(recorded)
        }}
    }
}
