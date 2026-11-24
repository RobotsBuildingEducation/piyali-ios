import Foundation

@MainActor final class PhonicsPolicy {
    let engine:CompanionQuestPolicy
    init(engine:CompanionQuestPolicy?=nil)throws{self.engine=try engine ?? CompanionQuestPolicy()}
    func run(_ operation:String,_ input:JSONValue = .object([:]))throws->JSONValue{try engine.run(operation,input)}
    func copy(_ key:String,language:String,target:String)->String{(try? run("ph_copy",.object(["key":.string(key),"language":.string(language),"targetLang":.string(target)])))?["text"].string ?? key}
    func grade(_ raw:String)throws->PhonicsGrade{try JSONDecoder().decode(PhonicsGrade.self,from:Data(run("ph_grade",.object(["raw":.string(raw)])).json.utf8))}
}
