import XCTest
import CryptoKit
import AVFoundation
@testable import Piyali

@MainActor private final class CacheCaptureTransport:RealtimeVoiceTransport{
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    var sent:[JSONValue]=[],microphone:[Bool]=[],closed=false,captureCalls=0
    let recording:NarrationRecording
    init(_ recording:NarrationRecording){self.recording=recording}
    func connect(session:JSONValue)async throws{onOpen?()}
    func send(_ event:JSONValue)->Bool{sent.append(event);return true}
    func setMicrophoneEnabled(_ enabled:Bool){microphone.append(enabled)}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func playbackDrainMilliseconds()async->Double{5}
    func completedNarrationRecording()->NarrationRecording?{captureCalls+=1;return recording}
    func close(){closed=true}
}
@MainActor private final class CacheReplay:NarrationReplay{
    var onFinished:(()->Void)?,onFailed:(()->Void)?
    var bytes=0,stopped=false
    func play(_ wav:Data)throws{bytes=wav.count}
    func stop(){stopped=true;onFinished=nil;onFailed=nil}
}
@MainActor final class NarrationCacheTests:XCTestCase{
    private func directory()->URL{FileManager.default.temporaryDirectory.appendingPathComponent("piyali-narration-test-"+UUID().uuidString,isDirectory:true)}
    private func recording()->NarrationRecording{
        var data=Data();for i in 0..<24000{let sample:Int16=i>=4800 && i<16800 ? Int16(sin(Double(i)*440*2*Double.pi/24000)*6000):0;var value=sample.littleEndian;withUnsafeBytes(of:&value){data.append(contentsOf:$0)}};return .init(pcm16:data,sampleRate:24000,channels:1)
    }
    private func ready(_ transport:CacheCaptureTransport)async throws{for _ in 0..<200 where transport.sent.isEmpty{try await Task.sleep(for:.milliseconds(2))};XCTAssertFalse(transport.sent.isEmpty)}
    private func complete(_ transport:CacheCaptureTransport){transport.onEvent?(.object(["type":.string("output_audio_buffer.started")]));transport.onEvent?(.object(["type":.string("response.done"),"response":.object(["status":.string("completed")])]));transport.onEvent?(.object(["type":.string("output_audio_buffer.stopped")]))}
    func testOriginalCacheKeysTrimmingAudibilityAndExactWAVBytes()throws{
        let policy=try NarrationCachePolicy(),url=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"narration-cache",withExtension:"json")),fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url));XCTAssertEqual(fixture["keys"].array.count,160);XCTAssertEqual(policy.ttl,604800)
        for row in fixture["keys"].array{XCTAssertEqual(try policy.sourceKey(row["input"]),row["expected"].string)}
        for row in fixture["pcm"].array{
            let channels=Int(row["channels"].number),length=Int(row["length"].number),buffers=try row["samples"].array.map{value->[Float] in let data=try XCTUnwrap(Data(base64Encoded:value.string));return stride(from:0,to:data.count,by:4).map{offset in let bits=(0..<4).reduce(UInt32(0)){$0 | UInt32(data[offset+$1]) << UInt32($1*8)};return Float(bitPattern:bits)}}
            var samples:[Float]=[];for frame in 0..<length{for channel in 0..<channels{samples.append(buffers[channel][frame])}}
            let pcm=NarrationPCM(sampleRate:Int(row["sampleRate"].number),channels:channels,samples:samples),result=pcm.analyze(policy.rules);XCTAssertEqual(result.audible,row["audible"].boolean);XCTAssertEqual(result.start,Int(row["start"].number));XCTAssertEqual(result.end,Int(row["end"].number));let hash=SHA256.hash(data:pcm.wav(start:result.start,end:result.end)).map{String(format:"%02x",$0)}.joined();XCTAssertEqual(hash,row["wavSHA256"].string,row["spec"]["name"].string)
        }
    }
    func testValidatedAudioPersistsExpiresAndRejectsCorruptedDiskData()async throws{
        let root=directory();defer{try? FileManager.default.removeItem(at:root)};let policy=try NarrationCachePolicy(),prepared=try XCTUnwrap(PreparedNarrationAudio.prepare(recording(),rules:policy.rules)),key=String(repeating:"a",count:64),date=Date(timeIntervalSince1970:1000000),cache=NarrationAudioCache(directory:root,ttl:policy.ttl)
        await cache.store(key,audio:prepared,now:date);let memory=await cache.load(key,now:date);XCTAssertEqual(memory?.source,"memory");XCTAssertEqual(memory?.wav,prepared.wav)
        let restored=NarrationAudioCache(directory:root,ttl:policy.ttl),disk=await restored.load(key,now:date.addingTimeInterval(policy.ttl));XCTAssertEqual(disk?.source,"disk");XCTAssertEqual(disk?.wav,prepared.wav);let expired=await restored.load(key,now:date.addingTimeInterval(policy.ttl+1));XCTAssertNil(expired)
        await cache.store(key,audio:prepared,now:date);await cache.clearMemory();try Data("corrupt".utf8).write(to:root.appendingPathComponent(key+".plist"));let invalid=await cache.load(key,now:date);XCTAssertNil(invalid);XCTAssertFalse(FileManager.default.fileExists(atPath:root.appendingPathComponent(key+".plist").path))
        let silent=NarrationRecording(pcm16:Data(repeating:0,count:48000),sampleRate:24000,channels:1);XCTAssertNil(try PreparedNarrationAudio.prepare(silent,rules:policy.rules))
    }
    func testOnlySuccessfulDrainProducesReplayAndLateReplayCannotFinishANewOwner()async throws{
        let root=directory();defer{try? FileManager.default.removeItem(at:root)};let cache=NarrationAudioCache(directory:root),transport=CacheCaptureTransport(recording()),replay=CacheReplay(),engine=try CompanionQuestPolicy();var connections=0,finished=0,starts=0
        let service=RealtimeNarrationService(factory:{connections+=1;return transport},cache:cache,replayFactory:{replay});defer{service.stopAll()};service.play("Hola, Ana.",language:"es",engine:engine,onStarted:{starts+=1},onFinished:{finished+=1});try await ready(transport);XCTAssertEqual(transport.microphone,[false]);transport.onEvent?(.object(["type":.string("output_audio_buffer.started")]));transport.onEvent?(.object(["type":.string("response.done"),"response":.object(["status":.string("completed")])]));try await Task.sleep(for:.milliseconds(30));XCTAssertEqual(transport.captureCalls,0);XCTAssertEqual(finished,0)
        transport.onEvent?(.object(["type":.string("output_audio_buffer.stopped")]));for _ in 0..<200 where finished==0{try await Task.sleep(for:.milliseconds(5))};XCTAssertEqual(finished,1);XCTAssertEqual(transport.captureCalls,1);XCTAssertTrue(transport.closed)
        service.play("  Hola,\n Ana. ",language:"es",engine:engine,onStarted:{starts+=1},onFinished:{finished+=1});for _ in 0..<200 where replay.bytes==0{try await Task.sleep(for:.milliseconds(5))};XCTAssertGreaterThan(replay.bytes,512);XCTAssertEqual(connections,1);XCTAssertEqual(starts,2);XCTAssertEqual(service.playbackSource,"memory");XCTAssertEqual(finished,1)
        let late=replay.onFinished;service.stopAll();late?();XCTAssertEqual(finished,1);XCTAssertTrue(replay.stopped)
    }
    func testCancelledIncompleteAndFailedNarrationNeverPromoteOrCapture()async throws{
        let root=directory();defer{try? FileManager.default.removeItem(at:root)};let cache=NarrationAudioCache(directory:root),engine=try CompanionQuestPolicy()
        for kind in["cancel","incomplete","error"]{let transport=CacheCaptureTransport(recording()),service=RealtimeNarrationService(factory:{transport},cache:cache);var finished=0;service.play(kind,language:"es",engine:engine,onFinished:{finished+=1});try await ready(transport)
            if kind=="cancel"{service.stopAll();complete(transport)}else if kind=="incomplete"{transport.onEvent?(.object(["type":.string("response.done"),"response":.object(["status":.string("incomplete")])]))}else{transport.onFailure?("network")}
            try await Task.sleep(for:.milliseconds(20));XCTAssertEqual(transport.captureCalls,0);XCTAssertEqual(finished,0);XCTAssertTrue(transport.closed);service.stopAll()
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath:root.path))
    }
    func testVoicePersonalityLocaleAndSessionChangesHaveDifferentIdentity()throws{
        let policy=try NarrationCachePolicy(),engine=try CompanionQuestPolicy(),session=try engine.run("ph_tts",.object(["language":.string("es"),"voice":.string("ash")])),key=try policy.key(text:"Hola",language:"es",voice:"ash",session:session,request:nil)
        for request in [JSONValue.object(["text":.string("Hola"),"language":.string("es"),"voice":.string("echo")]),.object(["text":.string("Hola"),"language":.string("ar"),"voice":.string("ash")]),.object(["text":.string("Hola"),"language":.string("es"),"voice":.string("ash"),"personality":.string("cheerful")])]{XCTAssertNotEqual(try policy.key(text:"Hola",language:"es",voice:"ash",session:session,request:request),key)}
        XCTAssertNotEqual(try policy.key(text:"Hola",language:"es",voice:"ash",session:session.setting("instructions",.string("New instructions")),request:nil),key)
    }
    func testActualNativeReplayCompletesWithPlaybackOnlyAudioSession()async throws{
        let policy=try NarrationCachePolicy(),audio=try XCTUnwrap(PreparedNarrationAudio.prepare(recording(),rules:policy.rules)),player=NarrationReplayPlayer(volume:0);defer{player.stop()};var finished=0,failures=0;player.onFinished={finished+=1};player.onFailed={failures+=1};try player.play(audio.wav);XCTAssertEqual(AVAudioSession.sharedInstance().category,.playback)
        for _ in 0..<200 where finished==0 && failures==0{try await Task.sleep(for:.milliseconds(10))};XCTAssertEqual(finished,1);XCTAssertEqual(failures,0)
    }
}
