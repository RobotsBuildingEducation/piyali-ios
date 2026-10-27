import Foundation

public enum LessonCardRules {
    public static func retry(_ response:JSONValue)->JSONValue{response.setting("text",.string("")).setting("typedText",.string("")).setting("recognizedText",.string(""))}
    public static func cycle(index:Int,count:Int,forward:Bool)->Int{guard count>0 else{return 0};return (max(0,index)%count+(forward ? 1:count-1))%count}
}
