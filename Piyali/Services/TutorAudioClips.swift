import Foundation
import CryptoKit

/// Local reply recordings are private to the account and language pair. They
/// are optional cache data, never lesson state or a cloud progress receipt.
actor TutorAudioClips {
    static let shared=TutorAudioClips()
    private let cache:NarrationAudioCache
    struct Scope:Sendable,Equatable {let account:String,target:String,support:String}
    init(directory:URL?=nil){
        let env=ProcessInfo.processInfo.environment,test=env["PIYALI_OFFLINE_TESTS"] == "1" ? UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "")?.uuidString:nil
        cache=NarrationAudioCache(directory:directory ?? FileManager.default.urls(for:.cachesDirectory,in:.userDomainMask)[0].appendingPathComponent("piyali-tutor-clips-v1"+(test.map{"-"+$0} ?? "")))
    }
    private func key(_ id:String,_ scope:Scope)->String?{
        guard !id.isEmpty,!scope.account.isEmpty else{return nil}
        let parts=["tutor-clip-v1",scope.account,scope.target,scope.support,id]
        guard let data=try? JSONEncoder().encode(parts)else{return nil}
        return SHA256.hash(data:data).map{String(format:"%02x",$0)}.joined()
    }
    func store(_ recording:NarrationRecording,response:String,scope:Scope)async{
        guard let key=key(response,scope),let audio=PreparedNarrationAudio.original(recording)else{return}
        await cache.store(key,audio:audio)
    }
    func load(_ response:String,scope:Scope)async->Data?{
        guard let key=key(response,scope)else{return nil};return await cache.load(key)?.wav
    }
}
