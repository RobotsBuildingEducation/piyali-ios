import Foundation

public struct WritingKeyboard {
    public let data:JSONValue
    public init(data:JSONValue){self.data=data}
    public init(bundle:Bundle = .main)throws{guard let url=bundle.url(forResource:"writing-keyboard",withExtension:"json")else{throw ContentError.missing("writing-keyboard")};data=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url))}
    public func keyWidth(_ key:String)->Double?{let value=data["widths"][key].number;return value>0 ? value:nil}
    public func supported(_ language:String)->Bool{data["beta"].array.contains(.string(language))}
    public func layout(language:String,mode:String)->[[String]]{data["layouts"][language][mode].array.map{$0.array.map(\.string)}}
    public func label(_ key:String,language:String)->String{let value=data["labels"][language][key].string;return value.isEmpty ? data["labels"]["en"][key].string:value}
    public static func press(_ key:String,text:String,disabled:Bool)->String {
        guard !disabled else{return text}
        if key == "BACKSPACE" || key == "⌫" {return String(decoding:Array(text.utf16).dropLast(),as:UTF16.self)}
        return text+key
    }
}
public enum WritingExerciseRules {
    public struct Clues:Equatable,Sendable {
        public let activeClueCount:Int,visibleClues:[String],potentialXp:Int,hasMoreClues:Bool,next:Int
        public var json:JSONValue{.object(["activeClueCount":.number(Double(activeClueCount)),"visibleClues":.array(visibleClues.map(JSONValue.string)),"potentialXp":.number(Double(potentialXp)),"hasMoreClues":.bool(hasMoreClues),"next":.number(Double(next))])}
    }
    public static func clues(_ clues:[String],revealed:Int,locked:Bool)->Clues {
        let active=min(max(1,revealed),clues.count),more=active<clues.count
        return .init(activeClueCount:active,visibleClues:Array(clues.prefix(active)),potentialXp:max(4,10-(active-1)*3),hasMoreClues:more,next:!locked && more ? min(clues.count,revealed+1):revealed)
    }
    public static func response(_ previous:JSONValue,text:String,variant:String)->JSONValue{variant == "sentence_shapeshifter" ? .object(["text":.string(text)]):previous.setting("text",.string(text))}
}
