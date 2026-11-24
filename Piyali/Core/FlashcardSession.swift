import Foundation

public struct FlashcardGrade:Codable,Equatable,Sendable {
    public let correct:Bool
    public let xp:Int
    public let suggested:ReviewRating
}
public struct FlashcardScope:Equatable,Sendable {
    public let account,target,support,cardID:String
    public let goalID,day:String?
    public init(account:String,target:String,support:String,cardID:String,goalID:String?=nil,day:String?=nil){self.account=account;self.target=target;self.support=support;self.cardID=cardID;self.goalID=goalID;self.day=day}
}
public extension FlashcardReview {
    var sourceFields:JSONValue {
        guard let data=try? JSONEncoder().encode(self),let value=try? JSONDecoder().decode(JSONValue.self,from:data) else{return .object([:])}
        var fields=value
        for (key,date) in [("nextReviewAt",nextReviewAt),("completedAt",completedAt),("updatedAt",updatedAt),("lastReviewedAt",lastReviewedAt)] {fields=fields.setting(key,date.map{.string(WebProgressContract.iso($0))} ?? .null)}
        return fields
    }
}
