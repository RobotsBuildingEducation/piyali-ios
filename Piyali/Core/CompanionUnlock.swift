import Foundation

public struct CompanionUnlock:Equatable,Identifiable,Sendable {
    public let account:String,type:String,name:String
    public let unlockLevel:Int,reachedLevel:Int
    public let expectsModal:Bool
    public var id:String{account+":"+type}
}
/// Mirrors the source's timed quiet check, including its shorter wait once a
/// real modal has been seen and the final hydration guard before presentation.
public struct CompanionUnlockState:Equatable,Sendable {
    public private(set) var account="",pending:[CompanionUnlock]=[],visible:CompanionUnlock?,revision=0
    private var seen=Set<String>()
    private var started:Double?,nextPoll=0.0,sawModal=false,expectsModal=false
    public init(){}
    public mutating func bind(_ account:String){guard self.account != account else{return};self.account=account;pending=[];visible=nil;seen=[];started=nil;revision += 1}
    public static func newlyUnlocked(previous:Int,next:Int)->[String]{guard next>previous else{return []};return CompanionTypes.ordered.filter{let level=CompanionTypes.unlocks[$0,default:1];return level>max(1,previous)&&level<=max(1,next)}}
    public mutating func enqueue(types:[String],level:Int,names:JSONValue,celebrated:Set<String>,expectsModal:Bool){
        guard !account.isEmpty else{return};var changed=false
        for raw in types{let type=CompanionTypes.effective(raw,level:40),key=account+":"+type;guard !celebrated.contains(type),seen.insert(key).inserted else{continue};pending.append(.init(account:account,type:type,name:names[type].string.isEmpty ? type:names[type].string,unlockLevel:CompanionTypes.unlocks[type,default:1],reachedLevel:level,expectsModal:expectsModal));changed=true}
        if changed{started=nil;revision += 1}
    }
    public mutating func poll(now:Double,blocked:Bool,celebrated:Set<String>)->CompanionUnlock?{
        guard visible == nil,!pending.isEmpty else{return nil}
        if started == nil{started=now;expectsModal=pending.contains{$0.expectsModal};nextPoll=now+(expectsModal ? 90:0);sawModal=false}
        guard now>=nextPoll else{return nil}
        if blocked{sawModal=true;nextPoll=now+90;return nil}
        if !sawModal,now-(started ?? now)<(expectsModal ? 900:120){nextPoll=now+80;return nil}
        while !pending.isEmpty{let next=pending.removeFirst();if celebrated.contains(next.type){continue};visible=next;return next}
        started=nil;return nil
    }
    public func delay(now:Double)->Double{max(0,nextPoll-now)}
    public mutating func dismiss(_ unlock:CompanionUnlock){guard visible?.id == unlock.id,account == unlock.account else{return};visible=nil;started=nil;revision += 1}
}
