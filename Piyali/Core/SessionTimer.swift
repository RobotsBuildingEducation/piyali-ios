import Foundation

public enum SessionToolPolicy {
    public static let goalPresets=[100,150,200,300],timerPresets=[10,20,30,45,60,90,120,180,240]
    public static func goal(_ draft:String)->Int {let n=Double(draft.trimmingCharacters(in:.whitespacesAndNewlines)) ?? 0;return n.isNaN ? 1 : Int(max(1,min(1000,floor(n+0.5))))}
    public static func minutes(_ draft:String)->Int {let n=Double(draft.trimmingCharacters(in:.whitespacesAndNewlines)) ?? 0;return n.isFinite && n>0 ? Int(max(1,min(Double(Int32.max),floor(n+0.5)))) : 10}
    public static func draft(_ value:String)->String {value.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty ? "10" : value}
    public static func angle(x:Double,y:Double)->Double {(atan2(x,-y)*180/Double.pi+360).truncatingRemainder(dividingBy:360)}
    public static func drag(minutes:Double,from:Double,to:Double)->Double {var delta=to-from;if delta>180{delta-=360};if delta < -180{delta+=360};return max(0,min(240,minutes+delta/3))}
    public static func snapped(_ value:Double)->Int {Int(floor(value/5+0.5))*5}
}

/// Account-local timer. Wall-clock deadlines keep elapsed time correct while
/// the app is suspended; a paused timer stores its remaining seconds instead.
public struct SessionTimer:Codable,Equatable,Sendable {
    public enum Status:String,Codable,Sendable {case idle,running,paused,finished}
    public let account:String
    public var draft="20" // App's actual empty-session hydration default.
    public private(set) var id:UUID?
    public private(set) var duration=0,pausedRemaining=0
    public private(set) var endsAt:Date?
    public private(set) var status:Status = .idle
    public init(account:String){self.account=account}
    public var hasTimer:Bool {status != .idle}
    public func remaining(at now:Date)->Int {status == .running ? max(0,Int(ceil((endsAt ?? now).timeIntervalSince(now)))) : status == .paused ? pausedRemaining : 0}
    public mutating func start(_ value:String,now:Date=Date(),id:UUID=UUID()) {draft=SessionToolPolicy.draft(value);duration=SessionToolPolicy.minutes(draft)*60;self.id=id;endsAt=now.addingTimeInterval(Double(duration));pausedRemaining=0;status = .running}
    @discardableResult public mutating func refresh(now:Date=Date())->Bool {guard status == .running,remaining(at:now)==0 else{return false};endsAt=nil;status = .finished;return true}
    public mutating func toggle(now:Date=Date()) {
        if status == .running {let seconds=remaining(at:now);if seconds==0{_ = refresh(now:now);return};pausedRemaining=seconds;endsAt=nil;status = .paused}
        else if status == .paused {endsAt=now.addingTimeInterval(Double(pausedRemaining));status = .running}
    }
    public mutating func clear(){duration=0;pausedRemaining=0;endsAt=nil;status = .idle;id=nil}
}
