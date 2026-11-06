import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor private final class OfflineGoalMemoryStore:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor final class GoalMemoryFlowTests:XCTestCase {
    private func setup()throws->(AppModel,Lesson,PracticeRun) {
        let e=ProcessInfo.processInfo.environment
        guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated offline identity required")}
        let app=AppModel(progressService:OfflineGoalMemoryStore());try app.identity.create();app.signedIn=true;app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.target="es";app.learner.support="en";app.learner.onboardingComplete=true;app.learner.editGoal("Speak with family")
        let bp:JSONValue = .object(["goalId":app.learner.goalBucket["activeGoal"]["id"],"lang":.string("es"),"dayKey":.string(CalendarDay.key(Date())),"mode":.string("lesson"),"modes":.array(["lesson","tutor"].map(JSONValue.string)),"modeTargets":.object(["lesson":.number(20),"tutor":.number(25)]),"cefrLevel":.string("A1"),"goalText":.string("Speak with family"),"scenario":.string("You are visiting family."),"supports":.array([.string("Use a model")]),"successCriteria":.array([.string("Say hello")]),"objective":.string("Greet a relative"),"targetLanguage":.array([.string("Hola")])])
        app.learner.applyGoal(GoalChange(action:.blueprint,target:"es",payload:bp));app.learner.pendingGoalChanges=[]
        let lesson=try app.sourceGoalLesson(bp),q=try PracticeQuestion(module:.vocabulary,kind:"fill",payload:.object(["question":.string("La niña come ___."),"answer":.string("pan"),"hint":.string("A food made from flour.")]),options:.object(["cefrLevel":.string("A1")]),target:"es",support:"en")
        let run=PracticeRun(question:q,lessonID:lesson.id,lessonLevel:"A1",response:.object(["text":.string("wrong")]))
        app.learner.savePractice(run);return(app,lesson,run)
    }
    func testActualGraderRoutesMissToGoalAndCachedAcknowledgedBlueprintReopensOfflineWithPendingEvidence()async throws {
        let(app,lesson,run)=try setup();defer{try? app.identity.disconnect()}
        let service=PracticeService(judge:{_ in "NO"});await service.check(app,run:run,lesson:lesson)
        XCTAssertEqual(app.learner.practiceRuns?[run.key]?.correct,false);XCTAssertTrue((app.learner.pendingMemoryChanges ?? []).isEmpty);XCTAssertEqual(app.learner.totalXP,0)
        XCTAssertEqual(app.learner.goalBucket["goalProgress"]["openCapabilities"].array.first?["target"].string,"La niña come ___.")
        XCTAssertEqual(app.learner.pendingGoalChanges?.filter{$0.action == .evidence}.count,1)
        try await app.prepareGoal();XCTAssertNotNil(app.readyGoal);XCTAssertEqual(GoalPractice.nextMode(try XCTUnwrap(app.readyGoal)),"lesson")
        XCTAssertEqual(GoalLessonProgress.earned(app.learner.goalBucket),0)
        var retry=try XCTUnwrap(app.learner.practiceRuns?[run.key]);retry.response = .object(["text":.string("pan")]);app.learner.savePractice(retry)
        await PracticeService(judge:{_ in "YES"}).check(app,run:retry,lesson:lesson)
        XCTAssertEqual(app.learner.totalXP,5);XCTAssertEqual(GoalLessonProgress.earned(app.learner.goalBucket),5);XCTAssertEqual(app.learner.goalBucket["dailyGoal"]["modeProgress"]["lesson"].number,0)
        XCTAssertEqual(app.learner.pendingGoalChanges?.filter{$0.action == .evidence}.count,1)
    }
    func testPendingGoalVerdictRejectsPauseGoalTargetSupportDaySignoutSameKeySessionAndCancellation()async throws {
        for boundary in ["pause","goal","target","support","day","signout","sameKey","cancel"] {
            let(app,lesson,run)=try setup();defer{try? app.identity.disconnect()}
            var continuation:CheckedContinuation<String,Error>?
            let service=PracticeService(judge:{_ in try await withCheckedThrowingContinuation{continuation=$0}})
            let task=Task{await service.check(app,run:run,lesson:lesson)}
            for _ in 0..<100 where continuation == nil{try await Task.sleep(for:.milliseconds(10))};XCTAssertNotNil(continuation,boundary)
            switch boundary {
            case "pause":app.setGoalStatus("paused")
            case "goal":app.learner.editGoal("Order a meal")
            case "target":app.learner.target="fr"
            case "support":app.learner.support="ar"
            case "day":let bucket=app.learner.goalBucket;app.learner.goalIntelligence?["es"]=bucket.setting("dailyGoal",bucket["dailyGoal"].setting("blueprint",bucket["dailyGoal"]["blueprint"].setting("dayKey",.string(CalendarDay.shift(CalendarDay.key(Date()),by:-1)))))
            case "signout":app.signedIn=false
            case "sameKey":let key=app.identity.exportKey();try app.identity.disconnect();try app.identity.importKey(key)
            default:service.cancel();task.cancel()
            }
            continuation?.resume(returning:"NO");await task.value
            XCTAssertNil(app.learner.practiceRuns?[run.key]?.correct,boundary);XCTAssertTrue((app.learner.pendingMemoryChanges ?? []).isEmpty,boundary);XCTAssertTrue((app.learner.pendingGoalChanges ?? []).filter{$0.action == .evidence}.isEmpty,boundary);XCTAssertEqual(app.learner.totalXP,0,boundary)
        }
    }
    func testReadingGraderCarriesTheMountedGoalContextAndOrdinaryReadingStillCapturesRepairs()async throws {
        let(app,lesson,_)=try setup();defer{try? app.identity.disconnect()}
        let payload:JSONValue = .object(["title":.string("La libreta"),"target":.string("Mi libreta verde está sobre la mesa. Dibujo una flor roja y escribo su nombre. Mañana mi hermana quiere dibujar conmigo."),"takeaways":.array(["A notebook","A flower","A plan"].map(JSONValue.string)),"reviewQuestion":.object(["type":.string("mc"),"question":.string("What color is the flower?"),"answer":.string("red"),"options":.array(["red","blue","green","yellow"].map(JSONValue.string))])])
        let run=try ReadingRun(payload:payload,target:"es",support:"en",level:"A1",lessonID:lesson.id,selection:.null,worth:.null,roll:0.5)
        app.learner.saveReading(run);let service=ReadingService();await service.check(app,run:run,answer:"blue",speech:false,lesson:lesson)
        XCTAssertEqual(app.learner.reading?.correct,false);XCTAssertTrue((app.learner.pendingMemoryChanges ?? []).isEmpty);XCTAssertEqual(app.learner.goalBucket["goalProgress"]["openCapabilities"].array.first?["domain"].string,"reading")
        app.learner.saveReading(run);await service.check(app,run:run,answer:"blue",speech:false)
        XCTAssertEqual(app.learner.companionMemory?["es"]?.count,1);XCTAssertEqual(app.learner.totalXP,0)
    }
    func testOriginalGoalCaptureAndNativeGoalMemoryDrawersInLightAndDark()async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1" else{throw XCTSkip("Read-only source renderer required")}
        let(app,lesson,run)=try setup();defer{try? app.identity.disconnect()}
        await PracticeService(judge:{_ in "NO"}).check(app,run:run,lesson:lesson)
        let change=try XCTUnwrap(app.learner.pendingGoalChanges?.first{$0.action == .evidence}),bp=try XCTUnwrap(lesson.goalBlueprint),memory=run.repairMemoryContext
        let input:JSONValue = .object(["npub":.string(app.identity.npub),"targetLang":.string("es"),"supportLang":.string("en"),"sourceMode":.string("vocabulary"),"concept":memory["concept"],"userAnswer":memory["userAnswer"],"expectedAnswer":memory["expectedAnswer"],"cefrLevel":.string("A1")])
        let snapshot:JSONValue = .object(["focus":.object(["npub":.string(app.identity.npub),"targetLang":.string("es"),"blueprint":bp]),"input":input,"now":.string(WebProgressContract.iso(change.date))])
        let captured=XCTAttachment(data:try JSONEncoder().encode(app.learner.goalBucket),uniformTypeIdentifier:"public.json");captured.name="Native actual Goal slip bucket";captured.lifetime = .keepAlways;add(captured)
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow}
        for theme in ["light","dark"] {
            let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent()
            config.userContentController.addUserScript(WKUserScript(source:"window.fixtureErrors=[];addEventListener('error',e=>fixtureErrors.push(e.message));addEventListener('unhandledrejection',e=>fixtureErrors.push(String(e.reason)));",injectionTime:.atDocumentStart,forMainFrameOnly:true))
            let web=WKWebView(frame:CGRect(x:0,y:0,width:402,height:874),configuration:config),vc=UIViewController(),window=UIWindow(windowScene:scene);vc.view=web;window.frame=web.frame;window.rootViewController=vc;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never
            defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
            var url=URLComponents(string:"http://127.0.0.1:5181/__piyali-memory")!
            url.queryItems=[.init(name:"tool",value:"goals"),.init(name:"language",value:"en"),.init(name:"theme",value:theme),.init(name:"goalSlip",value:snapshot.json)]
            web.load(URLRequest(url:try XCTUnwrap(url.url)))
            var ready=false
            for _ in 0..<600{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && window.__sourceGoalCapture && document.body.innerText.includes('La niña come ___.')")) as? Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))}
            if !ready{let errors=(try? await web.evaluateJavaScript("JSON.stringify({errors:fixtureErrors,text:document.body.innerText})")) as? String ?? "no DOM";XCTFail(errors);return}
            let evaluated=try await web.evaluateJavaScript("JSON.stringify(window.__sourceGoalCapture)");let raw=try XCTUnwrap(evaluated as? String),result=try JSONDecoder().decode(JSONValue.self,from:Data(raw.utf8))
            let surfaceValue=try await web.evaluateJavaScript("getComputedStyle(document.documentElement).getPropertyValue('--app-surface').trim()");let surface=try XCTUnwrap(surfaceValue as? String)
            let hex=try XCTUnwrap(UInt64(surface.dropFirst(),radix:16));var red:CGFloat=0,green:CGFloat=0,blue:CGFloat=0,alpha:CGFloat=0
            XCTAssertTrue(UIColor(MemoryPaint.surface(theme == "dark" ? .dark:.light)).getRed(&red,green:&green,blue:&blue,alpha:&alpha))
            XCTAssertEqual(Double(red)*255,Double((hex>>16)&255),accuracy:0.5);XCTAssertEqual(Double(green)*255,Double((hex>>8)&255),accuracy:0.5);XCTAssertEqual(Double(blue)*255,Double(hex&255),accuracy:0.5);XCTAssertEqual(alpha,1)
            let paint=JSONValue.object(["sourceSurface":.string(surface),"nativeRGBA":.array([red,green,blue,alpha].map{.number(Double($0))})])
            let paintAttachment=XCTAttachment(data:Data(paint.json.utf8),uniformTypeIdentifier:"public.json");paintAttachment.name="Goal Memory surface "+theme;paintAttachment.lifetime = .keepAlways;add(paintAttachment)
            for key in ["goalId","target","observation","expectedAnswer","mode","domain","success","support"]{XCTAssertEqual(change.payload[key],result["event"][key],key)}
            XCTAssertEqual(app.learner.goalBucket["goalProgress"],result["summary"].setting("eventIds",.array([.string(change.id.uuidString)])))
            let details=XCTAttachment(data:Data(raw.utf8),uniformTypeIdentifier:"public.json");details.name="Source actual Goal capture "+theme;details.lifetime = .keepAlways;add(details)
            try await Task.sleep(for:.milliseconds(300));let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source Goal slip Memory "+theme;source.lifetime = .keepAlways;add(source)
            let host=UIHostingController(rootView:ZStack{BrandBackground();MemoryDrawerView(onClose:{},initialTab:"goals")}.environmentObject(app).environment(\.dynamicTypeSize,.large).ignoresSafeArea().preferredColorScheme(theme == "dark" ? .dark:.light))
            window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded();try await Task.sleep(for:.milliseconds(400))
            let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native Goal slip Memory "+theme;native.lifetime = .keepAlways;add(native)
        }
    }

}
