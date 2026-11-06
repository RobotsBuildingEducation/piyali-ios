import XCTest
@testable import Piyali

@MainActor final class HelpChatControllerTests:XCTestCase {
    private let progress:JSONValue = .object(["targetLang":.string("es"),"supportLang":.string("en")])
    private func make()throws->(HelpChatController,URL){let url=FileManager.default.temporaryDirectory.appendingPathComponent("help-"+UUID().uuidString);return(HelpChatController(directory:url),url)}
    private func finish(_ controller:HelpChatController)async throws{for _ in 0..<100 where controller.busy{try await Task.sleep(for:.milliseconds(10))};XCTAssertFalse(controller.busy)}
    func testTextStreamsOriginalHistoryAndFailurePreservesConversation()async throws {
        let(c,url)=try make();defer{try? FileManager.default.removeItem(at:url)};c.configure(account:"one",progress:progress,appLanguage:"en");var prompts:[String]=[]
        let provider=HelpChatProvider(text:{_ in XCTFail("Ordinary chat must stream");return ""},stream:{prompt,chunk in prompts.append(prompt);chunk("First");await Task.yield();chunk("First reply\n// Hola");return "First reply\n// Hola"})
        c.send(" Hello ",provider:provider);try await finish(c);XCTAssertEqual(c.messages.map(\.role),["user","assistant"]);XCTAssertEqual(c.messages.first?.text,"Hello");XCTAssertTrue(prompts[0].hasSuffix("User question:\nHello"));XCTAssertFalse(prompts[0].contains("Previous conversation"))
        c.send("Next",provider:provider);try await finish(c);XCTAssertTrue(prompts[1].contains("User: Hello\nAssistant: First reply\n// Hola"));XCTAssertEqual(c.messages.count,4)
        c.send("Fail",provider:.init(text:{_ in ""},stream:{_,_ in throw URLError(.notConnectedToInternet)}));try await finish(c);XCTAssertEqual(c.messages.last?.text,c.copy("requestFailed"));XCTAssertTrue(c.messages.allSatisfy(\.done));XCTAssertNotNil(c.notice)
    }
    func testMorphemePlanTranslationPrefixAndIncompleteStreamFallback()async throws {
        let(c,url)=try make();defer{try? FileManager.default.removeItem(at:url)};c.configure(account:"one",progress:progress,appLanguage:"en");c.setMorphemes(true);var requests:[String]=[]
        c.send("sister",provider:.init(text:{prompt in requests.append(prompt);return prompt.contains("Determine the translation direction") ? #"{"translation":"sister","targetText":"hermana"}"#:"**hermana** = herman + a\n- a: feminine"},stream:{prompt,chunk in requests.append(prompt);chunk("Incomplete");return "Incomplete"}));try await finish(c)
        XCTAssertEqual(requests.count,3);XCTAssertTrue(requests[1].contains("hermana"));XCTAssertTrue(c.messages.last?.text.hasPrefix("// sister\n\n**hermana**") == true);XCTAssertFalse(requests[1].contains("Previous conversation"))
    }
    func testStopAndAccountLanguageChangesRejectLateChunks()async throws {
        let(c,url)=try make();defer{try? FileManager.default.removeItem(at:url)};c.configure(account:"one",progress:progress,appLanguage:"en");var finishReply:CheckedContinuation<String,Never>?,late:((String)->Void)?
        let provider=HelpChatProvider(text:{_ in ""},stream:{_,chunk in late=chunk;chunk("Partial");return await withCheckedContinuation{finishReply=$0}})
        c.send("Hello",provider:provider);while finishReply == nil{await Task.yield()};c.stop();late?("Should not appear");finishReply?.resume(returning:"Late");try await Task.sleep(for:.milliseconds(10));XCTAssertEqual(c.messages.last?.text,"Partial");XCTAssertTrue(c.messages.last?.done == true)
        finishReply=nil;c.send("Again",provider:provider);while finishReply == nil{await Task.yield()};c.configure(account:"two",progress:progress,appLanguage:"ar");late?("Cross account");finishReply?.resume(returning:"Late");try await Task.sleep(for:.milliseconds(10));XCTAssertTrue(c.messages.isEmpty);XCTAssertEqual(c.copy("help"),"مساعدة")
    }
    func testSavedChatsMorphemePreferenceAndVoiceOrderingPersistPrivately()throws {
        let(c,url)=try make();defer{try? FileManager.default.removeItem(at:url)};c.configure(account:"one",progress:progress,appLanguage:"en")
        c.voiceReply("reply",text:"Hola");c.voiceInput(.init(id:"input",text:String(repeating:"A",count:60),answered:"",responseID:"reply"));c.voiceInput(.init(id:"input",text:"duplicate",answered:"",responseID:"reply"));XCTAssertEqual(c.messages.map(\.id),["input","reply"])
        for _ in 0..<23{c.save()};XCTAssertEqual(c.saved.count,20);XCTAssertEqual(c.saved.first?.title.count,50);c.setMorphemes(true)
        let restored=HelpChatController(directory:url);restored.configure(account:"one",progress:progress,appLanguage:"en");XCTAssertTrue(restored.morphemes);XCTAssertEqual(restored.saved,c.saved);XCTAssertTrue(restored.messages.isEmpty);let chat=try XCTUnwrap(restored.saved.first);restored.load(chat);XCTAssertEqual(restored.messages,c.messages);restored.delete(chat.id);XCTAssertEqual(restored.saved.count,19)
        restored.configure(account:"two",progress:progress,appLanguage:"en");XCTAssertTrue(restored.saved.isEmpty);XCTAssertFalse(restored.morphemes)
    }
}
