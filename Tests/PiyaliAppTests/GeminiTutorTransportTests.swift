import XCTest
@testable import Piyali

@MainActor private final class TutorSocketFixture:GeminiTutorSocket {
    var sent:[JSONValue]=[],closed=false,failSend=false
    private var pending:CheckedContinuation<JSONValue,Error>?,packets:[JSONValue]=[]
    func send(_ value:JSONValue)async throws{if failSend{throw URLError(.networkConnectionLost)};guard !closed else{throw CancellationError()};sent.append(value)}
    func receive()async throws->JSONValue{if !packets.isEmpty{return packets.removeFirst()};if closed{throw CancellationError()};return try await withCheckedThrowingContinuation{pending=$0}}
    func feed(_ packet:JSONValue){if let pending{self.pending=nil;pending.resume(returning:packet)}else{packets.append(packet)}}
    func close(){closed=true;pending?.resume(throwing:CancellationError());pending=nil}
}
@MainActor final class GeminiTutorTransportTests:XCTestCase {
    private func settle()async{for _ in 0..<30{await Task.yield()}}
    private func request(_ text:String)->JSONValue{.object(["type":.string("response.create"),"response":.object(["instructions":.string(text)])])}
    private func output(_ text:String)->JSONValue{.object(["serverContent":.object(["outputTranscription":.object(["text":.string(text)]),"turnComplete":.bool(true)])])}
    func testNativeLiveControllerGetsStableInputIDsPlaybackCompletionAndResetWithoutRepeatedOpen()async throws {
        var sockets:[TutorSocketFixture]=[]
        let transport=GeminiTutorTransport(capturesAudio:false,factory:{_ in let socket=TutorSocketFixture();sockets.append(socket);return socket})
        let live=LiveTutorService(permission:{true},transportFactory:{transport});var inputs:[RealtimeVoiceState.InputTurn]=[],assistants:[String]=[]
        await live.start(learner:LearnerState(),openingPrompt:nil,inactivityTimeout:0,onInputTurn:{inputs.append($0)},onAssistantTurn:{id,_ in assistants.append(id)},sessionConfiguration:.object(["provider":.string("gemini")]),externallyControlled:true)
        XCTAssertTrue(live.connected)
        for i in 0..<5 {
            live.requestResponse(request("Turn \(i)"));await settle();let socket=try XCTUnwrap(sockets.last)
            XCTAssertEqual(socket.sent.last?["clientContent"]["turns"].array.first?["parts"].array.first?["text"].string,"Turn \(i)")
            socket.feed(output("Reply \(i)"));await settle()
            XCTAssertEqual(live.voiceState,"listening");XCTAssertFalse(live.outputPending)
        }
        XCTAssertEqual(sockets.count,2);XCTAssertTrue(sockets[0].closed);XCTAssertEqual(assistants.count,5);XCTAssertEqual(Set(assistants).count,5)
        let socket=try XCTUnwrap(sockets.last);socket.feed(.object(["serverContent":.object(["inputTranscription":.object(["text":.string(" hola ")]),"turnComplete":.bool(true)])]));await settle()
        XCTAssertEqual(inputs.count,1);XCTAssertFalse(inputs[0].id.isEmpty);XCTAssertEqual(inputs[0].text,"hola");XCTAssertEqual(inputs[0].answered,"Reply 4")
        live.discardInput(inputs[0].id);await live.stop();XCTAssertTrue(socket.closed);XCTAssertFalse(live.connected)
    }
    func testCloseWhileInitialConnectPendingClosesLateSocketAndNeverOpens()async throws {
        var held:CheckedContinuation<GeminiTutorSocket,Error>?,opened=0
        let socket=TutorSocketFixture(),transport=GeminiTutorTransport(capturesAudio:false,factory:{_ in try await withCheckedThrowingContinuation{held=$0}})
        transport.onOpen={opened+=1};let task=Task{try await transport.connect(session:.null)}
        await settle();XCTAssertNotNil(held);transport.close();held?.resume(returning:socket)
        do{try await task.value;XCTFail("A closed connection must not open") }catch is CancellationError{}catch{XCTFail("\(error)")}
        XCTAssertTrue(socket.closed);XCTAssertEqual(opened,0)
    }
    func testCloseDuringFourthTurnResetClosesLateSocketAndDropsQueuedPrompt()async throws {
        let first=TutorSocketFixture(),late=TutorSocketFixture();var count=0,opened=0,held:CheckedContinuation<GeminiTutorSocket,Error>?
        let transport=GeminiTutorTransport(capturesAudio:false,factory:{_ in count+=1;if count == 1{return first};return try await withCheckedThrowingContinuation{held=$0}})
        transport.onOpen={opened+=1};try await transport.connect(session:.null)
        for i in 0..<4{XCTAssertTrue(transport.send(request("Turn \(i)")));await settle();first.feed(output("Reply"));await settle()}
        XCTAssertNotNil(held);XCTAssertTrue(first.closed);XCTAssertTrue(transport.send(request("Never send")));transport.close();held?.resume(returning:late);await settle()
        XCTAssertTrue(late.closed);XCTAssertTrue(late.sent.isEmpty);XCTAssertEqual(opened,1)
    }
    func testSendFailureClosesSocketAndReleasesLiveController()async throws {
        let socket=TutorSocketFixture();socket.failSend=true
        let transport=GeminiTutorTransport(capturesAudio:false,factory:{_ in socket}),live=LiveTutorService(permission:{true},transportFactory:{transport})
        await live.start(learner:LearnerState(),openingPrompt:nil,inactivityTimeout:0,sessionConfiguration:.object(["provider":.string("gemini")]),externallyControlled:true)
        live.requestResponse(request("Teach"));await settle();XCTAssertFalse(live.connected);XCTAssertNotNil(live.error);XCTAssertTrue(socket.closed)
    }

    func testClosingVoicePreviewKeepsAnotherGeminiPlayerAliveThroughPlayback()async throws {
        let firstSocket=TutorSocketFixture(),secondSocket=TutorSocketFixture(),first=GeminiTutorTransport(capturesMicrophone:false,factory:{_ in firstSocket}),second=GeminiTutorTransport(capturesMicrophone:false,factory:{_ in secondSocket});defer{first.close();second.close()}
        try await first.connect(session:.null);try await second.connect(session:.null);first.close()
        var done=false;second.onEvent={if $0["type"].string == "response.done"{done=true}};XCTAssertTrue(second.send(request("Play")));await settle()
        let pcm=Data(repeating:0,count:24000)
        secondSocket.feed(.object(["serverContent":.object(["modelTurn":.object(["parts":.array([.object(["inlineData":.object(["mimeType":.string("audio/pcm;rate=24000"),"data":.string(pcm.base64EncodedString())])])])]),"turnComplete":.bool(true)])]))
        let deadline=Date().addingTimeInterval(5);while !done,Date()<deadline{try await Task.sleep(for:.milliseconds(50))}
        XCTAssertTrue(done);XCTAssertEqual(second.playedAudioBuffers,1);XCTAssertFalse(secondSocket.closed)
    }
    func testFirebaseWireKeepsLanguageHintsAndExcludesOpenAIVadSchema()throws {
        let config:JSONValue = .object(["instructions":.string("Teach"),"responseInstructionsSuffix":.string("One turn"),"voice":.string("Charon"),"inputLanguageCodes":.array([.string("fr-FR"),.string("en-US")])])
        let setup=GeminiTutorWire.setup(config,modelResource:"projects/piyali-ios/models/gemini-3.1-flash-live-preview")["setup"]
        XCTAssertEqual(setup["inputAudioTranscription"]["languageCodes"],config["inputLanguageCodes"]);XCTAssertEqual(setup["generationConfig"]["speechConfig"]["voiceConfig"]["prebuiltVoiceConfig"]["voiceName"],.string("Charon"));XCTAssertEqual(setup["systemInstruction"]["parts"].array.first?["text"],.string("Teach\n\nOne turn"));XCTAssertEqual(setup["audio"],.null)
        XCTAssertEqual(GeminiTutorWire.input(Data([0,0]))["realtimeInput"]["audio"]["mimeType"],.string("audio/pcm;rate=16000"))
    }
}
