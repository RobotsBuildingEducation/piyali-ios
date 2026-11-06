import Foundation
import CryptoKit
import AVFoundation

struct PreparedNarrationAudio:Sendable {
    let wav:Data
    private init(_ wav:Data){self.wav=wav}
    /// Wrap the original PCM losslessly; reply clips must retain their original
    /// voice, pauses and prosody instead of using the TTS cache's trim/resample.
    static func original(_ recording:NarrationRecording)->Self?{
        let pcm=recording.pcm16,channels=recording.channels,rate=recording.sampleRate
        guard (1...2).contains(channels),(8000...192000).contains(rate),!pcm.isEmpty,pcm.count<=16*1024*1024,pcm.count%(channels*2)==0 else{return nil}
        var wav=Data()
        func tag(_ text:String){wav.append(contentsOf:text.utf8)}
        func word<T:FixedWidthInteger>(_ value:T){var value=value.littleEndian;withUnsafeBytes(of:&value){wav.append(contentsOf:$0)}}
        tag("RIFF");word(UInt32(36+pcm.count));tag("WAVEfmt ");word(UInt32(16));word(UInt16(1));word(UInt16(channels));word(UInt32(rate));word(UInt32(rate*channels*2));word(UInt16(channels*2));word(UInt16(16));tag("data");word(UInt32(pcm.count));wav.append(pcm)
        return .init(wav)
    }
    static func prepare(_ recording:NarrationRecording,rules:NarrationPCM.Rules)throws->Self?{
        guard (1...2).contains(recording.channels),(8000...192000).contains(recording.sampleRate),!recording.pcm16.isEmpty,recording.pcm16.count<=20*1024*1024,recording.pcm16.count%(recording.channels*2)==0 else{return nil}
        let frames=recording.pcm16.count/(recording.channels*2)
        guard let inputFormat=AVAudioFormat(commonFormat:.pcmFormatInt16,sampleRate:Double(recording.sampleRate),channels:AVAudioChannelCount(recording.channels),interleaved:true),let input=AVAudioPCMBuffer(pcmFormat:inputFormat,frameCapacity:AVAudioFrameCount(frames)),let outputFormat=AVAudioFormat(standardFormatWithSampleRate:24000,channels:AVAudioChannelCount(recording.channels)),let output=AVAudioPCMBuffer(pcmFormat:outputFormat,frameCapacity:AVAudioFrameCount(ceil(Double(frames)*24000/Double(recording.sampleRate)))+2048),let converter=AVAudioConverter(from:inputFormat,to:outputFormat)else{return nil}
        input.frameLength=AVAudioFrameCount(frames);recording.pcm16.withUnsafeBytes{bytes in memcpy(input.mutableAudioBufferList.pointee.mBuffers.mData!,bytes.baseAddress!,bytes.count)}
        var supplied=false,error:NSError?
        let status=converter.convert(to:output,error:&error){_,state in if supplied{state.pointee = .endOfStream;return nil};supplied=true;state.pointee = .haveData;return input}
        guard error == nil,status != .error,let channels=output.floatChannelData else{return nil};var samples=[Float]();samples.reserveCapacity(Int(output.frameLength)*recording.channels)
        for frame in 0..<Int(output.frameLength){for channel in 0..<recording.channels{samples.append(channels[channel][frame])}}
        let pcm=NarrationPCM(sampleRate:24000,channels:recording.channels,samples:samples),analysis=pcm.analyze(rules);guard analysis.audible,analysis.end>analysis.start else{return nil}
        return .init(pcm.wav(start:analysis.start,end:analysis.end))
    }
}

@MainActor final class NarrationCachePolicy {
    private let policy:PracticeAssistancePolicy
    let rules:NarrationPCM.Rules
    let ttl:TimeInterval
    init()throws{
        guard let source=Bundle.main.url(forResource:"narration-cache-policy",withExtension:"js"),let settings=Bundle.main.url(forResource:"narration-cache-rules",withExtension:"json")else{throw PracticeRecipeFailure.unavailable}
        policy=try PracticeAssistancePolicy(source:String(contentsOf:source,encoding:.utf8));let data=try Data(contentsOf:settings);rules=try JSONDecoder().decode(NarrationPCM.Rules.self,from:data);let info=try JSONDecoder().decode(JSONValue.self,from:data);ttl=info["ttlMilliseconds"].number/1000
    }
    func sourceKey(_ request:JSONValue)throws->String{try policy.runPolicy("key",request).string}
    func key(text:String,language:String,voice:String,session:JSONValue,request:JSONValue?)throws->String{
        let input=(request ?? .object(["text":.string(text),"language":.string(language),"voice":.string(voice)])).setting("text",.string(text))
        let original=try sourceKey(input),encoder=JSONEncoder();encoder.outputFormatting = .sortedKeys
        // Native PCM encoding and complete session are namespaced; the original request key is retained.
        return SHA256.hash(data:try encoder.encode(JSONValue.object(["version":.number(1),"original":.string(original),"session":session]))).map{String(format:"%02x",$0)}.joined()
    }
}

actor NarrationAudioCache {
    struct Hit:Sendable{let wav:Data,source:String}
    private struct Entry:Codable{let version:Int,created:Date,checksum:String,wav:Data}
    static let shared=NarrationAudioCache()
    private let directory:URL,ttl:TimeInterval
    private var memory:[String:Entry]=[:]
    private struct Pending{let id:UUID,task:Task<PreparedNarrationAudio?,Never>}
    private var pending:[String:Pending]=[:]
    init(directory:URL?=nil,ttl:TimeInterval=7*24*60*60){
        let environment=ProcessInfo.processInfo.environment,scope=environment["PIYALI_OFFLINE_TESTS"] == "1" ? UUID(uuidString:environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "")?.uuidString:nil
        self.directory=directory ?? FileManager.default.urls(for:.cachesDirectory,in:.userDomainMask)[0].appendingPathComponent("piyali-narration-v1"+(scope.map{"-"+$0} ?? ""),isDirectory:true);self.ttl=ttl
    }
    func load(_ key:String,now:Date=Date())async->Hit?{
        guard valid(key)else{return nil}
        if let item=pending[key]{let audio=await item.task.value;settle(key,id:item.id,audio:audio)}
        if let entry=memory[key]{if now.timeIntervalSince(entry.created)<=ttl{return .init(wav:entry.wav,source:"memory")};memory[key]=nil}
        let file=directory.appendingPathComponent(key+".plist")
        guard let size=(try? file.resourceValues(forKeys:[.fileSizeKey]))?.fileSize,size<=20*1024*1024,let data=try? Data(contentsOf:file),let entry=try? PropertyListDecoder().decode(Entry.self,from:data),entry.version==1,now.timeIntervalSince(entry.created)<=ttl,Self.hash(entry.wav)==entry.checksum else{try? FileManager.default.removeItem(at:file);return nil}
        remember(key,entry);return .init(wav:entry.wav,source:"disk")
    }
    func store(_ key:String,audio:PreparedNarrationAudio,now:Date=Date()){
        guard valid(key),audio.wav.count>512,audio.wav.count<=16*1024*1024 else{return}
        let entry=Entry(version:1,created:now,checksum:Self.hash(audio.wav),wav:audio.wav);remember(key,entry)
        do{try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true);let encoder=PropertyListEncoder();encoder.outputFormat = .binary;let file=directory.appendingPathComponent(key+".plist");try encoder.encode(entry).write(to:file,options:[.atomic,.completeFileProtectionUntilFirstUserAuthentication]);var values=URLResourceValues();values.isExcludedFromBackup=true;var mutable=file;try? mutable.setResourceValues(values);trimDisk()}catch{/* Optional storage must not interrupt playback. */}
    }
    func complete(_ key:String,recording:NarrationRecording,rules:NarrationPCM.Rules){
        guard valid(key),pending[key] == nil else{return}
        let id=UUID(),task=Task.detached(priority:.utility){try? PreparedNarrationAudio.prepare(recording,rules:rules)};pending[key]=Pending(id:id,task:task)
        Task{let audio=await task.value;settle(key,id:id,audio:audio)}
    }
    private func settle(_ key:String,id:UUID,audio:PreparedNarrationAudio?){guard pending[key]?.id==id else{return};pending[key]=nil;if let audio{store(key,audio:audio)}}
    func remove(_ key:String){guard valid(key)else{return};pending[key]?.task.cancel();pending[key]=nil;memory[key]=nil;try? FileManager.default.removeItem(at:directory.appendingPathComponent(key+".plist"))}
    func clearMemory(){memory=[:]}
    private func valid(_ key:String)->Bool{key.count==64 && key.allSatisfy{$0.isHexDigit}}
    private static func hash(_ data:Data)->String{SHA256.hash(data:data).map{String(format:"%02x",$0)}.joined()}
    private func remember(_ key:String,_ entry:Entry){memory[key]=entry;while memory.count>32 || memory.values.reduce(0,{$0+$1.wav.count})>16*1024*1024{guard let oldest=memory.min(by:{$0.value.created<$1.value.created})?.key else{break};memory[oldest]=nil}}
    private func trimDisk(){
        let files=(try? FileManager.default.contentsOfDirectory(at:directory,includingPropertiesForKeys:[.contentModificationDateKey,.fileSizeKey])) ?? []
        let sorted=files.filter{$0.pathExtension=="plist"}.compactMap{url->(URL,Date,Int)? in guard let info=try? url.resourceValues(forKeys:[.contentModificationDateKey,.fileSizeKey])else{return nil};return(url,info.contentModificationDate ?? .distantPast,info.fileSize ?? 0)}.sorted{$0.1<$1.1};var total=sorted.reduce(0){$0+$1.2},count=sorted.count
        for file in sorted where count>256 || total>64*1024*1024{try? FileManager.default.removeItem(at:file.0);count-=1;total-=file.2}
    }
}
