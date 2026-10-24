import Foundation

public struct PhonicsGrade:Codable,Equatable,Sendable {public let correct:Bool;public let xp:Int}
public enum PhonicsProgress {
    public static func key(_ target:String,_ id:String)->String {target+":"+id}
    public static func document(_ fields:[String:Any])->JSONValue {
        func json(_ value:Any)->Any {
            if let date=value as? Date{return WebProgressContract.iso(date)}
            if let map=value as? [String:Any]{return map.mapValues(json)}
            if let array=value as? [Any]{return array.map(json)}
            return value
        }
        return JSONValue.foundation(fields.mapValues(json))
    }
    /// Same alphabetPractice fields as saveAlphabetProgress, with an event receipt outside this reducer.
    public static func applying(_ change:PracticeChange,to original:JSONValue)->JSONValue {
        guard change.source == .phonicsAttempt,change.phonicsData?["focused"].boolean != true else{return original}
        let data=change.phonicsData ?? .null,word=data["word"].string
        var words=[word];for value in original["practicedWords"].array.map(\.string) where !words.contains(value){words.append(value)}
        return original.setting("letterId",.string(change.contentID ?? "")).setting("targetLang",.string(change.target)).setting("cefrLevel",.string(change.level))
            .setting("attempts",.number(original["attempts"].number+1)).setting("correctCount",.number(original["correctCount"].number+(change.correct == true ? 1:0)))
            .setting("practicedWords",.array(Array(words.prefix(10)).map(JSONValue.string))).setting("lastAttemptAt",.string(WebProgressContract.iso(change.date)))
            .setting("lastWord",.string(word)).setting("lastWordMeaning",data["meaning"]).setting("currentWord",.string(word)).setting("currentMeaning",data["meaning"])
            .setting("updatedAt",.string(WebProgressContract.iso(change.date)))
    }
}
public extension LearnerState {
    var phonicsDocuments:[JSONValue] {(phonicsRecords ?? [:]).filter{$0.key.hasPrefix(target+":")}.map(\.value)}
    mutating func applyPhonics(_ change:PracticeChange) {
        if change.source == .phonicsDeck {
            for record in change.phonicsData?["records"].array ?? [] {
                let key=PhonicsProgress.key(change.target,record["letterId"].string)
                if phonicsRecords == nil{phonicsRecords=[:]}
                var merged=phonicsRecords?[key] ?? .object([:]);for (field,value) in record.object{merged=merged.setting(field,value)}
                phonicsRecords?[key]=merged
            }
        }else if change.source == .phonicsAttempt,change.phonicsData?["focused"].boolean != true,let id=change.contentID {
            let key=PhonicsProgress.key(change.target,id);if phonicsRecords == nil{phonicsRecords=[:]};let original=phonicsRecords?[key] ?? .object([:]);phonicsRecords?[key]=PhonicsProgress.applying(change,to:original)
        }
    }
    @discardableResult mutating func attemptPhonics(card:JSONValue,grade:PhonicsGrade,focused:Bool=false,now:Date=Date())->UUID {
        let amount=grade.correct ? max(1,min(2,grade.xp)):0;addXP(amount,now:now,calendar:.current)
        var change=PracticeChange(date:now,dayKey:CalendarDay.key(now),target:target,level:card["cefrLevel"].string.isEmpty ? level:card["cefrLevel"].string,amount:amount,source:.phonicsAttempt,contentID:card["id"].string,correct:grade.correct,independent:false)
        change.phonicsData = .object(["focused":.bool(focused),"word":card["practiceWord"],"meaning":card["practiceWordMeaning"]]);enqueue(change);return change.id
    }
    @discardableResult mutating func collectPhonics(cardID:String,now:Date=Date())->UUID? {
        if masteredPhonics == nil {masteredPhonics=[]};guard masteredPhonics?.insert(target+":"+CalendarDay.key(now)+":"+cardID).inserted == true else{return nil}
        var change=PracticeChange(date:now,dayKey:CalendarDay.key(now),target:target,level:level,amount:0,source:.phonics,contentID:cardID)
        change.phonicsData = .object(["collection":.bool(true)]);enqueue(change);return change.id
    }
    @discardableResult mutating func storeSupplementalPhonics(_ records:[JSONValue],now:Date=Date())->UUID {
        var change=PracticeChange(date:now,dayKey:CalendarDay.key(now),target:target,level:records.first?["cefrLevel"].string ?? level,amount:0,source:.phonicsDeck)
        change.phonicsData = .object(["records":.array(records)]);enqueue(change);return change.id
    }
}
