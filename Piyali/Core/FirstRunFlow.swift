import Foundation

/// Companion Continue → install/key guidance → starting-level choice. The
/// guidance flag belongs to the account; placement prompting is once per
/// account/language in this mounted app session, as in the source ref.
public struct FirstRunFlow:Equatable,Sendable {
    public enum Step:String,Sendable {case gettingStarted,placement}
    public private(set) var step:Step?
    public private(set) var scope:String?
    public private(set) var promptedPlacement:String?
    public init() {}
    public mutating func request(scope:String,shown:Bool,hasPlacement:Bool) {
        guard step == nil else{return}
        self.scope=scope
        if !shown {step = .gettingStarted} else {openPlacement(scope:scope,hasPlacement:hasPlacement)}
    }
    @discardableResult public mutating func acknowledge(scope:String,hasPlacement:Bool)->Bool {
        guard self.scope == scope,step == .gettingStarted else{return false}
        step=nil;openPlacement(scope:scope,hasPlacement:hasPlacement);return true
    }
    private mutating func openPlacement(scope:String,hasPlacement:Bool) {
        guard !hasPlacement,promptedPlacement != scope else{step=nil;return}
        promptedPlacement=scope;step = .placement
    }
    public mutating func close() {step=nil;scope=nil}
    public mutating func reconcile(scope:String) {if let current=self.scope,current != scope {close()}}
}
public extension LearnerState {
    var hasFirstRunPlacement:Bool {placements?[target] != nil || legacyFirstRunPlacement != nil}
}
