import Foundation

public struct LessonCompletionPresentation:Identifiable,Sendable {
    public let id=UUID()
    public let account:String
    public let target:String
    public let lessonID:String
    public let title:JSONValue
    public let reward:Int
    public let languageXP:Int
    public init(account:String,target:String,lesson:Lesson,reward:Int,languageXP:Int) { self.account=account;self.target=target;lessonID=lesson.id;title=lesson.title;self.reward=max(0,reward);self.languageXP=max(0,languageXP) }
}
