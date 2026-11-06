import Foundation

public struct AchievementUnlock:Equatable,Identifiable,Sendable {
    public let id:Int
    public let achievementID:String
    public let test:Bool
    public let preview:Bool
}

/// Session-only delivery, separate from permanent award records (unlockStore.js).
public struct AchievementUnlockState:Equatable,Sendable {
    public private(set) var identity=""
    public private(set) var language="en"
    public private(set) var queue:[AchievementUnlock]=[]
    public private(set) var revision=0
    private var serial=0
    private let catalog:Set<String>
    public init(catalog:Set<String>){self.catalog=catalog}
    public var current:AchievementUnlock?{queue.first}
    public mutating func setIdentity(_ identity:String){guard identity != self.identity else{return};self.identity=identity;queue=[];revision += 1}
    public mutating func setLanguage(_ language:String){self.language=language}
    public mutating func recordsChanged(){revision += 1}
    public mutating func enqueue(identity:String,id:String,test:Bool=false,preview:Bool=false){
        guard identity == self.identity,catalog.contains(id) else{return}
        guard preview || !queue.contains(where:{$0.achievementID == id && $0.test == test}) else{return}
        serial += 1;queue.append(.init(id:serial,achievementID:id,test:test,preview:preview))
    }
    public mutating func dismiss(_ key:Int){queue.removeAll{$0.id == key}}
    public static func notifiable(before:JSONValue,after:JSONValue,order:[String],catalog:Set<String>,notify:Bool=true)->[String]{
        guard notify else{return []}
        return order.filter{id in let prior=before[id],record=after[id];return catalog.contains(id) && record["unlockedAt"].number>0 && (prior == .null || (NostrAchievementCollection.truthy(prior["test"]) && !NostrAchievementCollection.truthy(record["test"])))}
    }
}
