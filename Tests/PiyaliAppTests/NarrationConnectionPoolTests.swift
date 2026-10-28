import XCTest
@testable import Piyali

@MainActor private final class WarmTestTransport:RealtimeVoiceTransport{
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    var receiver=false,autoReady=true,hang=false,fail=false,closed=false,connects=0,activations=0
    var sent:[JSONValue]=[],microphone:[Bool]=[],session:JSONValue = .null
    private var continuation:CheckedContinuation<Void,Never>?
    var narrationReceiverReady:Bool{receiver}
    func connect(session:JSONValue)async throws{connects+=1;self.session=session;if fail{throw URLError(.notConnectedToInternet)};if hang{await withCheckedContinuation{continuation=$0};try Task.checkCancellation()};if autoReady{receiver=true};onOpen?()}
    func release(){continuation?.resume();continuation=nil}
    func send(_ event:JSONValue)->Bool{sent.append(event);return !closed}
    func setMicrophoneEnabled(_ enabled:Bool){microphone.append(enabled)}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func activateNarrationOutput()throws{activations+=1}
    func playbackDrainMilliseconds()async->Double{5}
    func close(){closed=true}
}
@MainActor private final class WarmTestReplay:NarrationReplay{var onFinished:(()->Void)?,onFailed:(()->Void)?;var started=false;func play(_ wav:Data)throws{started=true};func stop(){onFinished=nil;onFailed=nil}}
@MainActor final class NarrationConnectionPoolTests:XCTestCase{
    private func session(_ voice:String="ash")throws->JSONValue{try CompanionQuestPolicy().run("ph_tts",.object(["language":.string("es"),"voice":.string(voice)]))}
    private func fixture()throws->JSONValue{let url=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"narration-warm",withExtension:"json"));return try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url))}
    private func ready(_ predicate:()->Bool)async throws{for _ in 0..<300 where !predicate(){try await Task.sleep(for:.milliseconds(2))};XCTAssertTrue(predicate())}
    func testOriginalRulesAndVoiceUpdateEvents()throws{
        let fixture=try fixture(),rules=try NarrationWarmRules.load(),policy=try NarrationWarmPolicy();XCTAssertEqual(rules.idleMilliseconds,Int(fixture["rules"]["idleMilliseconds"].number));XCTAssertEqual(rules.connectTimeoutMilliseconds,Int(fixture["rules"]["connectTimeoutMilliseconds"].number));XCTAssertEqual(rules.retryMilliseconds,Int(fixture["rules"]["retryMilliseconds"].number));XCTAssertEqual(rules.defaultVoice,fixture["rules"]["defaultVoice"].string)
        for row in fixture["cases"].array{XCTAssertEqual(try policy.voice(row["voice"].string),row["event"])}
    }
    func testActualSourceSingleFlightAndExclusiveClaimTrace()async throws{
        let expected=try fixture()["traces"]["singleFlight"],transport=WarmTestTransport(),pool=NarrationConnectionPool(factory:{transport},authorized:{_ in true});pool.configure(account:"qa",active:true);defer{pool.clear();transport.close()};let session=try session()
        let first=Task{await pool.warm(session:session)},second=Task{await pool.warm(session:session)};let a=await first.value,b=await second.value,lease=await pool.take(),again=await pool.take();pool.clear()
        XCTAssertEqual(.object(["first":.bool(a),"second":.bool(b),"posts":.number(Double(transport.connects)),"claimed":.bool(lease != nil),"secondClaim":.bool(again != nil),"claimedStillOpen":.bool(!transport.closed),"receiveOnly":.string("recvonly")]),expected)
        XCTAssertTrue(transport.sent.isEmpty);XCTAssertEqual(transport.microphone,[false]);XCTAssertEqual(transport.activations,0)
    }
    func testActualSourceBackoffExpiryAndClearingUnusedTraces()async throws{
        let expected=try fixture()["traces"],session=try session();var time=Date(timeIntervalSince1970:0),fail=true,clients:[WarmTestTransport]=[]
        let pool=NarrationConnectionPool(factory:{let t=WarmTestTransport();t.fail=fail;clients.append(t);return t},now:{time},authorized:{_ in true});pool.configure(account:"qa",active:true);defer{pool.clear();clients.forEach{$0.close()}}
        let a=await pool.warm(session:session),b=await pool.warm(session:session),blocked=clients.count;time.addTimeInterval(30);fail=false;let retry=await pool.warm(session:session)
        XCTAssertEqual(.object(["first":.bool(a),"second":.bool(b),"blockedPosts":.number(Double(blocked)),"retry":.bool(retry),"posts":.number(Double(clients.count))]),expected["backoff"])
        time.addTimeInterval(240);let expired=await pool.take();XCTAssertEqual(.object(["claimed":.bool(expired != nil),"closed":.bool(clients.last!.closed)]),expected["expiry"])
        var others:[WarmTestTransport]=[];let next=NarrationConnectionPool(factory:{let t=WarmTestTransport();others.append(t);return t},authorized:{_ in true});next.configure(account:"qa",active:true);_=await next.warm(session:session);let lease=await next.take();_=await next.warm(session:session);next.clear()
        XCTAssertEqual(.object(["posts":.number(Double(others.count)),"claimedStillOpen":.bool(!others[0].closed),"unusedClosed":.bool(others[1].closed)]),expected["clearUnused"]);lease?.client.close()
    }
    func testReadinessRequiresChannelAndAudioReceiver()async throws{
        let transport=WarmTestTransport();transport.autoReady=false;let pool=NarrationConnectionPool(factory:{transport},authorized:{_ in true});pool.configure(account:"qa",active:true);defer{pool.clear()};let session=try session(),warming=Task{await pool.warm(session:session)}
        try await ready{transport.connects==1};try await Task.sleep(for:.milliseconds(25));XCTAssertFalse(pool.prepared);transport.receiver=true;let success=await warming.value;XCTAssertTrue(success);XCTAssertTrue(pool.prepared);XCTAssertTrue(transport.sent.isEmpty)
    }
    func testTimeoutAndCancelledClaimSettleEvenWhenExchangeHasNotReturned()async throws{
        let transport=WarmTestTransport();transport.hang=true;let rules=NarrationWarmRules(idleMilliseconds:240000,connectTimeoutMilliseconds:30,retryMilliseconds:30000,defaultVoice:"ash"),pool=NarrationConnectionPool(factory:{transport},rules:rules,authorized:{_ in true});pool.configure(account:"qa",active:true);let session=try session(),began=Date(),warming=Task{await pool.warm(session:session)};let result=await warming.value;XCTAssertFalse(result);XCTAssertLessThan(Date().timeIntervalSince(began),1);XCTAssertTrue(transport.closed);transport.release();pool.clear()
        let pending=WarmTestTransport();pending.hang=true;let second=NarrationConnectionPool(factory:{pending},authorized:{_ in true});second.configure(account:"qa",active:true);let warm=Task{await second.warm(session:session)};try await ready{pending.connects==1};let claim=Task{await second.take()};try await Task.sleep(for:.milliseconds(5));claim.cancel();let value=await claim.value;XCTAssertNil(value);let warmResult=await warm.value;XCTAssertFalse(warmResult);XCTAssertTrue(pending.closed);pending.release();second.clear()
    }
    func testBackgroundAccountAndAuthorizationChangesDiscardUnusedConnection()async throws{
        var allowed=true;let transport=WarmTestTransport(),pool=NarrationConnectionPool(factory:{transport},authorized:{_ in allowed});pool.configure(account:"qa",active:true);_=await pool.warm(session:try session());allowed=false;let denied=await pool.take();XCTAssertNil(denied);pool.configure(account:"other",active:true);XCTAssertTrue(transport.closed);XCTAssertEqual(pool.idleCount,0)
        let next=WarmTestTransport(),background=NarrationConnectionPool(factory:{next},authorized:{_ in true});background.configure(account:"qa",active:true);_=await background.warm(session:try session());background.configure(account:"qa",active:false);XCTAssertTrue(next.closed);XCTAssertFalse(background.usable)
    }
    func testNarrationUsesPreparedConnectionAndOriginalVoiceEventBeforeRequest()async throws{
        let transport=WarmTestTransport(),pool=NarrationConnectionPool(factory:{transport},authorized:{_ in true});pool.configure(account:"qa",active:true);_=await pool.warm(session:try session());var cold=0,finished=0
        let narration=RealtimeNarrationService(factory:{cold+=1;return WarmTestTransport()},cacheEnabled:false,pool:pool);defer{narration.stopAll();pool.clear()};narration.play("Hola.",language:"es",engine:try CompanionQuestPolicy(),voice:"echo",onFinished:{finished+=1});try await ready{transport.sent.count==3}
        XCTAssertEqual(cold,0);XCTAssertEqual(transport.connects,1);XCTAssertEqual(transport.activations,1);XCTAssertTrue(narration.usedPreparedConnection);XCTAssertEqual(transport.sent[0],try NarrationWarmPolicy().voice("echo"));XCTAssertEqual(transport.sent.map{$0["type"].string},["session.update","conversation.item.create","response.create"])
        transport.onEvent?(.object(["type":.string("output_audio_buffer.started")]));transport.onEvent?(.object(["type":.string("response.done"),"response":.object(["status":.string("completed")])]));try await Task.sleep(for:.milliseconds(20));XCTAssertEqual(finished,0);transport.onEvent?(.object(["type":.string("output_audio_buffer.stopped")]));try await ready{finished==1};XCTAssertTrue(transport.closed)
    }
    func testAutomaticRefillKeepsOnlyOneUnusedAndRequestsNoSpeech()async throws{
        var clients:[WarmTestTransport]=[];let pool=NarrationConnectionPool(factory:{let t=WarmTestTransport();clients.append(t);return t},authorized:{_ in true});pool.configure(account:"qa",active:true);pool.automaticRefill=true;_=await pool.warm(session:try session());let service=RealtimeNarrationService(factory:{WarmTestTransport()},cacheEnabled:false,pool:pool);defer{service.stopAll();pool.clear()};service.play("Hola.",language:"es",engine:try CompanionQuestPolicy());try await ready{clients.count==2 && pool.prepared};XCTAssertEqual(clients[0].sent.count,2);XCTAssertTrue(clients[1].sent.isEmpty);XCTAssertEqual(clients[1].activations,0);XCTAssertEqual(pool.idleCount,1)
    }
    func testClaimedTransportIsReleasedAfterStop()async throws{
        weak var connection:WarmTestTransport?
        let pool=NarrationConnectionPool(factory:{let transport=WarmTestTransport();connection=transport;return transport},authorized:{_ in true});pool.configure(account:"qa",active:true);_=await pool.warm(session:try session());let service=RealtimeNarrationService(factory:{WarmTestTransport()},cacheEnabled:false,pool:pool);service.play("Hola.",language:"es",engine:try CompanionQuestPolicy(),voice:"echo");try await ready{connection?.sent.count==3};service.stopAll();pool.clear();for _ in 0..<100 where connection != nil{try await Task.sleep(for:.milliseconds(2))};XCTAssertNil(connection)
    }
}
