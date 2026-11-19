import Foundation
import CryptoKit

/// Optional content cache. Saved runs/rewards remain in canonical learner progress.
@MainActor final class RPGPreparationCache {
    private let directory:URL
    init(directory:URL?=nil){
        var selected=directory ?? FileManager.default.urls(for:.cachesDirectory,in:.userDomainMask)[0].appendingPathComponent("PiyaliRPGPreparation",isDirectory:true)
        #if DEBUG
        if directory == nil,ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",let scope=ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"],UUID(uuidString:scope) != nil{selected=FileManager.default.temporaryDirectory.appendingPathComponent("PiyaliRPGPreparationTests/"+scope,isDirectory:true)}
        #endif
        self.directory=selected
    }
    private func hash(_ value:String)->String{SHA256.hash(data:Data(value.utf8)).map{String(format:"%02x",$0)}.joined()}
    private func url(account:String,key:String,support:String)->URL{directory.appendingPathComponent(hash(account),isDirectory:true).appendingPathComponent(hash(key+":"+support)+".json")}
    func load(account:String,key:String,support:String)->JSONValue?{
        guard !account.isEmpty,let data=try? Data(contentsOf:url(account:account,key:key,support:support))else{return nil};return try? JSONDecoder().decode(JSONValue.self,from:data)
    }
    func save(_ value:JSONValue,account:String,key:String,support:String){
        guard !account.isEmpty,value != .null else{return};let path=url(account:account,key:key,support:support)
        do{try FileManager.default.createDirectory(at:path.deletingLastPathComponent(),withIntermediateDirectories:true);try JSONEncoder().encode(value).write(to:path,options:.atomic)}catch{/* Cache failure must not block a playable episode. */}
    }
}
