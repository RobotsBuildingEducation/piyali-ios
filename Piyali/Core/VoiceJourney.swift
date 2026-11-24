import Foundation
import CryptoKit

public enum VoiceJourneyModel {
    public static let milestones=[1,5,15,30,45,60,90,120,150]
    public static let maxBytes=650_000,maxSeconds=45
    private static func numeric(_ value:JSONValue)->Double {
        switch value {case .number(let n):return n;case .bool(let n):return n ? 1:0;case .null:return 0;case .string(let s):let s=s.trimmingCharacters(in:.whitespacesAndNewlines);if s.isEmpty{return 0};if s.hasPrefix("0x") || s.hasPrefix("0X"){return UInt64(s.dropFirst(2),radix:16).map(Double.init) ?? .nan};return Double(s) ?? .nan;default:return .nan}
    }
    public static func count(_ data:JSONValue)->Int {let n=numeric(data["completedQuests"]);return n.isFinite ? Int(min(Double(Int.max).nextDown,max(0,n.rounded(.down)))):0}
    public static func saved(_ data:JSONValue,_ milestone:Int)->Bool {switch data["recordings"][String(milestone)]{case .null:return false;case .bool(let n):return n;case .number(let n):return n.isFinite && n != 0;case .string(let n):return !n.isEmpty;default:return true}}
    public static func expired(_ data:JSONValue,_ milestone:Int)->Bool {guard let i=milestones.firstIndex(of:milestone),!saved(data,milestone),count(data)>=milestone,i+1<milestones.count else{return false};return count(data)>=milestones[i+1]}
    public static func canRecord(_ data:JSONValue,_ milestone:Int)->Bool {milestones.contains(milestone) && !saved(data,milestone) && count(data)>=milestone && !expired(data,milestone)}
    public static func pending(_ data:JSONValue)->Int? {let prompted=numeric(data["lastPromptedMilestone"]);guard let n=milestones.last(where:{$0<=count(data)}),Double(n)>(prompted.isNaN ? 0:prompted),!saved(data,n) else{return nil};return n}
    public static func baseline(_ data:JSONValue)->Int? {milestones.filter{saved(data,$0)}.sorted{a,b in let x=WebProgressContract.date(data["recordings"][String(a)]["createdAt"].string)?.timeIntervalSince1970 ?? 0,y=WebProgressContract.date(data["recordings"][String(b)]["createdAt"].string)?.timeIntervalSince1970 ?? 0;return x == y ? a<b:x<y}.first}
}
public struct JourneyEnvelope:Sendable {
    public let version:Int,wrappedKey:String,iv:Data,ciphertext:Data
    public init(version:Int=1,wrappedKey:String,iv:Data,ciphertext:Data){self.version=version;self.wrappedKey=wrappedKey;self.iv=iv;self.ciphertext=ciphertext}
}
public enum JourneyCryptography {
    public static func binding(account:String,target:String,milestone:Int)->Data {Data("piyali-voice-journey:v1:\(account):\(target):\(milestone)".utf8)}
    public static func seal(_ payload:JSONValue,key:Data,nonce:Data,account:String,target:String,milestone:Int)throws->Data {
        guard key.count == 32,nonce.count == 12 else{throw CryptoKitError.incorrectParameterSize}
        let result=try AES.GCM.seal(try JSONSerialization.data(withJSONObject:payload.foundation,options:[.sortedKeys,.withoutEscapingSlashes]),using:SymmetricKey(data:key),nonce:AES.GCM.Nonce(data:nonce),authenticating:binding(account:account,target:target,milestone:milestone));return result.ciphertext+result.tag
    }
    public static func open(_ envelope:JourneyEnvelope,key:Data,account:String,target:String,milestone:Int)throws->JSONValue {
        guard envelope.version == 1,key.count == 32,envelope.ciphertext.count>=16 else{throw CryptoKitError.incorrectParameterSize}
        let box=try AES.GCM.SealedBox(nonce:AES.GCM.Nonce(data:envelope.iv),ciphertext:envelope.ciphertext.dropLast(16),tag:envelope.ciphertext.suffix(16)),data=try AES.GCM.open(box,using:SymmetricKey(data:key),authenticating:binding(account:account,target:target,milestone:milestone))
        return try JSONDecoder().decode(JSONValue.self,from:data)
    }
    public static func hex(_ data:Data)->String {data.map{String(format:"%02x",$0)}.joined()}
    public static func key(_ value:String)throws->Data {guard value.count == 64,value.range(of:"^[a-f0-9]{64}$",options:.regularExpression) != nil else{throw CryptoKitError.incorrectParameterSize};return Data(stride(from:0,to:64,by:2).map{i in UInt8(value.dropFirst(i).prefix(2),radix:16)!})}
    public static func validate(_ payload:JSONValue)throws->Data {
        guard payload["mimeType"].string.hasPrefix("audio/"),let audio=Data(base64Encoded:payload["audio"].string),!audio.isEmpty,audio.count<=VoiceJourneyModel.maxBytes,payload["duration"].number>=1,payload["duration"].number<=47,payload["prompt"].string.utf16.count<=600 else{throw CryptoKitError.incorrectParameterSize};return audio
    }
}
