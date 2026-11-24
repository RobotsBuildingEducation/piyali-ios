import Foundation

/// retrySync.js: a destination acknowledges only the generation it sent.
public struct AchievementRetry:Equatable,Sendable {
    public private(set) var active=true
    public private(set) var running=false
    public private(set) var pending=false
    public private(set) var generation=0
    public private(set) var attempts=0
    public init(pending:Bool=false){self.pending=pending}
    public mutating func schedule()->Int?{generation += 1;pending=true;return active && !running ? 0:nil}
    public mutating func resume()->Int?{active=true;return schedule()}
    public mutating func pause(){active=false}
    public mutating func begin()->Int?{guard active,!running else{return nil};running=true;return generation}
    public mutating func finish(sent:Int,failed:Bool)->Int?{
        guard running else{return nil};running=false
        if failed{attempts += 1;pending=true}else{attempts=0;if sent==generation{pending=false}}
        guard active,failed || sent != generation else{return nil}
        return failed ? min(60000,1000 * (1 << min(attempts-1,10))):0
    }
}
