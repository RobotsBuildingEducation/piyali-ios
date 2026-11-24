import XCTest
@testable import Piyali

@MainActor final class RPGTranslationControllerTests:XCTestCase {
    private func input(_ support:String="en")->JSONValue{.object(["support":.string(support),"names":.array(["Neko","Ana"].map(JSONValue.string)),"inventory":.array([]),"dialogue":.object(["node":.object(["id":.string("node"),"responseMode":.string("choice"),"npcLine":.string("Hello. How are you?"),"choices":.array(["Sí","No","Tal vez"].map{.object(["text":.string($0)])})]),"npcReply":.string("")])])}
    private func wait(_ condition:()->Bool)async throws{for _ in 0..<300 where !condition(){try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(condition())}
    func testOriginalAsyncTracesMatchNativeChunkStatesAndFailureClearing()async throws{
        let file=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"rpg-dialogue-traces",withExtension:"json")),traces=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:file))
        XCTAssertEqual(traces.count,7)
        for (index,trace) in traces.enumerated(){
            let c=RPGTranslationController();c.configure(key:"trace-\(index)",parameters:trace["input"],isCurrent:{true});var prompts:[String]=[]
            c.toggle(provider:.init(stream:{prompt,update in
                prompts.append(prompt)
                let data=trace["input"]
                if data["responses"].boolean{
                    if data["failAfter"] != .null{throw URLError(.cannotConnectToHost)};update(data["chunks"].array.map(\.string).joined())
                }else{
                    for (i,chunk) in data["chunks"].array.enumerated(){update(chunk.string)
                        let expected=trace["expected"]["snapshots"].array[i]
                        for field in ["lineTranslations","choiceTranslations","actionTranslations"]{XCTAssertEqual(c.state[field],expected[field],"Trace \(index), chunk \(i), \(field)")}
                        if data["failAfter"] != .null,Int(data["failAfter"].number) == i{throw URLError(.networkConnectionLost)}
                    }
                }
            }));try await wait{!c.busy}
            XCTAssertEqual(prompts,[trace["expected"]["prompt"].string]);let final=trace["expected"]["final"]
            for field in ["lineTranslations","choiceTranslations","actionTranslations"]{XCTAssertEqual(c.state[field],final[field],"Final trace \(index), \(field)")}
            XCTAssertEqual(c.busy,final["busy"].boolean)
        }
    }
    func testIncompleteStreamIsVisibleThenUndoRestoresOriginalPresentation()async throws{
        let c=RPGTranslationController();c.configure(key:"same",parameters:input(),isCurrent:{true});var complete:CheckedContinuation<Void,Never>?,count=0
        c.toggle(provider:.init(stream:{_,update in count+=1;update("1) Hola\n2) ¿Cómo estás?");await withCheckedContinuation{complete=$0};update("\n3) Sí\n4) No\n5) Tal vez")}));try await wait{complete != nil}
        XCTAssertTrue(c.busy);XCTAssertEqual(c.lines,["Hola",""]);XCTAssertEqual(c.choices,["","",""])
        c.configure(key:"same",parameters:input(),isCurrent:{true});XCTAssertEqual(count,1);XCTAssertEqual(c.lines,["Hola",""])
        complete?.resume();complete=nil;try await wait{!c.busy};XCTAssertEqual(c.lines,["Hola","¿Cómo estás?"]);XCTAssertEqual(c.choices,["Sí","No","Tal vez"])
        c.toggle(provider:.init(stream:{_,_ in XCTFail("Undo must not request more translations")}));XCTAssertFalse(c.active);XCTAssertNil(c.lines);XCTAssertEqual(c.presentation?.prompt,"Hello. How are you?")
    }
    func testCloseNewNodeAndLostOwnerRejectDelayedChunksWithoutClearingTheNextRequest()async throws{
        for change in ["close","node","owner"]{
            let c=RPGTranslationController();var owner=true,finish:CheckedContinuation<Void,Never>?
            c.configure(key:"first",parameters:input(),isCurrent:{owner})
            c.toggle(provider:.init(stream:{_,update in update("1) OLD\n");await withCheckedContinuation{finish=$0};update("2) OLD FINAL\n")}));try await wait{finish != nil}
            if change == "close"{c.reset()}else if change == "node"{c.configure(key:"second",parameters:input("ar"),isCurrent:{true});c.toggle(provider:.init(stream:{_,update in update("1) جديد\n2) أيضاً\n3) نعم\n4) لا\n5) ربما")}));try await wait{!c.busy}}else{owner=false}
            finish?.resume();finish=nil;try await Task.sleep(for:.milliseconds(30))
            if change == "node"{XCTAssertEqual(c.lines,["جديد","أيضاً"]);XCTAssertEqual(c.choices,["نعم","لا","ربما"])}else{XCTAssertFalse(c.active);XCTAssertFalse(c.busy)}
        }
    }
    func testPartialFailureDiscardsTranslationsAndASecondAttemptCanRecover()async throws{
        let c=RPGTranslationController();c.configure(key:"one",parameters:input(),isCurrent:{true});var calls=0
        c.toggle(provider:.init(stream:{_,update in calls+=1;update("1) PARTIAL\n");throw URLError(.networkConnectionLost)}));try await wait{!c.busy};XCTAssertFalse(c.active);XCTAssertEqual(calls,1)
        c.toggle(provider:.init(stream:{_,update in calls+=1;update("1) Hola\n2) Bien\n3) Sí\n4) No\n5) Quizá")}));try await wait{!c.busy};XCTAssertEqual(calls,2);XCTAssertEqual(c.lines,["Hola","Bien"])
    }
    func testLabelKeepsFullAccessibleLayoutWhileRevealingAndStopsWhenDetached()async throws{
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow},window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);let host=UIViewController();window.rootViewController=host;window.makeKeyAndVisible();defer{window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
        let text="¿Hola? 👩🏽‍💻 This complete line remains in the accessible text.",label=RPGDialogueLabel();label.frame=CGRect(x:10,y:50,width:250,height:160);host.view.addSubview(label);label.configure(text:text,language:"es",color:.black,size:16,bold:true,animated:true)
        let first=label.sizeThatFits(CGSize(width:250,height:1000));XCTAssertTrue(label.isAnimating);XCTAssertEqual(label.accessibilityLabel,text);try await Task.sleep(for:.milliseconds(70));XCTAssertEqual(label.sizeThatFits(CGSize(width:250,height:1000)),first)
        label.removeFromSuperview();XCTAssertFalse(label.isAnimating);label.configure(text:text,language:"es",color:.black,size:16,bold:true,animated:false);XCTAssertEqual(label.sizeThatFits(CGSize(width:250,height:1000)),first);XCTAssertEqual(label.accessibilityLabel,text)
    }
}
