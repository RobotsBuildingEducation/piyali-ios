import Foundation

/// App.jsx keeps a viewed invitation quiet until a new pending ID arrives.
public struct TeamInviteAttention:Equatable,Sendable {
    public private(set) var pendingIDs:Set<String>?
    public private(set) var hasUnseen=false
    public init(){}
    public var count:Int {pendingIDs?.count ?? 0}
    public mutating func receive(_ invites:[JSONValue]) {
        let incoming=Set(invites.filter{$0["status"].string == "pending"}.map{$0["id"].string})
        if pendingIDs == nil{hasUnseen = !incoming.isEmpty}
        else if !incoming.subtracting(pendingIDs ?? []).isEmpty{hasUnseen=true}
        pendingIDs=incoming
    }
    public mutating func viewed(){hasUnseen=false}
}
