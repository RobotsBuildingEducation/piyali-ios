import Foundation

/// The tutorial and starter Tutor share one account-wide prompt; pending UI is scoped.
public struct ScholarshipPrompt:Equatable,Sendable {
    public struct Scope:Equatable,Sendable {public let account:String,target:String;public init(account:String,target:String){self.account=account;self.target=target}}
    public private(set) var pending:Scope?
    public private(set) var visible:Scope?
    public init(){}
    public mutating func request(account:String,target:String,seen:Bool){guard !account.isEmpty,!seen,visible == nil else{return};pending = .init(account:account,target:target)}
    public mutating func reconcile(account:String,target:String,seen:Bool){let scope=Scope(account:account,target:target);if seen || pending != nil && pending != scope{pending=nil};if seen || visible != nil && visible != scope{visible=nil}}
    public mutating func present(account:String,target:String,seen:Bool,blocked:Bool){reconcile(account:account,target:target,seen:seen);guard !blocked,let pending else{return};visible=pending;self.pending=nil}
    @discardableResult public mutating func dismiss(account:String,target:String)->Bool{guard visible == Scope(account:account,target:target) else{return false};visible=nil;pending=nil;return true}
}
