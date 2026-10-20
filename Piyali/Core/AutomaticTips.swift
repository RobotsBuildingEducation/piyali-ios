import Foundation

public struct AutomaticTipIntent:Codable,Equatable,Sendable {
    public let id:String
    public let recipient:String
    public let maximumFee:Int
}
/// Financial intent journal, stored separately from the mutable wallet operation and learner snapshot.
public struct AutomaticTipJournal:Codable,Equatable,Sendable {
    public var enabled=false
    public var recipient=WalletContract.defaultRecipient
    public var maximumFee=0
    public var enabledAt:Date?
    public private(set) var queue:[AutomaticTipIntent]=[]
    public private(set) var handled:[String]=[]
    public var pauseReason:String?
    public init() {}
    public mutating func configure(enabled:Bool,recipient:String,maximumFee:Int) {
        clearQueue()
        self.enabled=enabled;self.recipient=recipient;self.maximumFee=maximumFee;enabledAt=enabled ? Date() : nil;pauseReason=nil
    }
    public mutating func enqueue(_ changes:[PracticeChange],available:Int) {
        guard enabled,maximumFee >= 0,maximumFee <= 1_000_000 else { return }
        let capacity=min(256,max(0,available)/(1+maximumFee)),known=Set(handled+queue.map(\.id))
        var seen=known
        for change in changes where change.earnedAmount > 0 {
            let id=change.id.uuidString.lowercased();guard seen.insert(id).inserted else { continue }
            guard queue.count < capacity else { remember(id);continue }
            queue.append(AutomaticTipIntent(id:id,recipient:recipient,maximumFee:maximumFee))
        }
    }
    private mutating func remember(_ id:String) { if !handled.contains(id) { handled.append(id) } }
    public mutating func clearQueue() { for item in queue { remember(item.id) };queue=[] }
    public mutating func complete(_ id:String) { queue.removeAll { $0.id == id };remember(id) }
    public mutating func pause(_ reason:String) { enabled=false;pauseReason=reason;clearQueue() }
}
