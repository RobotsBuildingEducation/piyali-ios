import Foundation

public struct GuidedPracticeSession:Codable,Equatable,Sendable {
    public let account:String
    public let target:String
    public let day:String
    public private(set) var current:String
    public init?(account:String,target:String,day:String,courses:[PlateCourse]) {
        guard let first=courses.first(where:{ !$0.done }) else { return nil }
        self.account=account;self.target=target;self.day=day;current=first.kind
    }
    public func matches(account:String,target:String,day:String)->Bool { self.account == account && self.target == target && self.day == day }
    public func taskCompleted(_ courses:[PlateCourse])->Bool { courses.first { $0.kind == current }?.done == true }
    public mutating func advance(_ courses:[PlateCourse])->Bool {
        guard let next=courses.first(where:{ !$0.done }) else { return false }
        current=next.kind;return true
    }
}
