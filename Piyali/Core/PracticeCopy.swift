import Foundation

public enum PracticeCopy {
    private static let values=(try? ContentLibrary.load([String:JSONValue].self,name:"practice-copy")) ?? [:]
    public static func text(variant:String,language:String,key:String,fallback:String="")->String {
        let value=values[language]?[variant][key].string ?? ""
        if !value.isEmpty { return value }
        let english=values["en"]?[variant][key].string ?? ""
        return english.isEmpty ? fallback : english
    }
}
