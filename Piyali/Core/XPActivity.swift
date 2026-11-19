import Foundation

struct XPActivityPlan {
    struct Day:Identifiable {let id:String,title:String,level:String;let style:JSONValue;let blank:Bool}
    struct Week:Identifiable {let id:String,month:String,days:[Day]}
    static let ui=(try? ContentLibrary.load(JSONValue.self,name:"xp-activity-ui")) ?? .null
    let weeks:[Week]
    init(history:JSONValue,language:String,dark:Bool,now:Date=Date(),calendar supplied:Calendar = .current){
        let calendar=CalendarDay.gregorian(supplied)
        let today=calendar.startOfDay(for:now),year=calendar.component(.year,from:today),start=calendar.date(from:DateComponents(year:year,month:1,day:1))!,count=calendar.range(of:.day,in:.year,for:start)!.count,padding=calendar.component(.weekday,from:start)-1,done=Set(history["goalDays"].array.map(\.string)),locale=Self.ui["locales"][language] == .null ? Self.ui["locales"]["en"]:Self.ui["locales"][language]
        weeks=(0..<Int(ceil(Double(padding+count)/7))).map{week in
            var month=""
            let days=(0..<7).map{index->Day in
                let offset=week*7+index-padding
                guard (0..<count).contains(offset),let date=calendar.date(byAdding:.day,value:offset,to:start)else{return Day(id:"blank-\(week)-\(index)",title:"",level:"",style:.null,blank:true)}
                let key=CalendarDay.key(date,calendar:calendar),m=calendar.component(.month,from:date),d=calendar.component(.day,from:date),xp=max(0,Self.number(history["days"][key])),level=done.contains(key) ? "goal":xp>0 ? "some":"empty",future=date>today,isToday=date==today
                if month.isEmpty,d==1{month=locale["months"].array[m-1].string}
                let title=locale["dates"]["\(m)-\(d)"].string+" - "+Self.xpText(xp)+" XP",style=Self.ui["styles"]["\(dark ? "dark":"light"):\(level):\(future):\(isToday)"]
                return Day(id:key,title:title,level:level,style:style,blank:false)
            }
            return Week(id:"plate-week-\(year)-\(week)",month:month,days:days)
        }
    }
    static func number(_ value:JSONValue)->Double{switch value{case .number(let n):return n.isFinite ? n:0;case .string(let s):let n=Double(s.trimmingCharacters(in:.whitespacesAndNewlines)) ?? 0;return n.isFinite ? n:0;case .bool(let b):return b ? 1:0;default:return 0}}
    static func xpText(_ value:Double)->String{value.rounded()==value && abs(value)<Double(Int.max) ? String(Int(value)):String(value)}
    static func merge(_ legacy:JSONValue,_ loaded:JSONValue)->JSONValue{.object(["days":.object(legacy["days"].object.merging(loaded["days"].object){_,new in new}),"goalDays":.array(Set(legacy["goalDays"].array.map(\.string)+loaded["goalDays"].array.map(\.string)).sorted().map(JSONValue.string))])}
    static func effective(_ history:JSONValue,dailyXP:Int,goal:Int,now:Date=Date(),calendar:Calendar = .current)->JSONValue{
        let today=CalendarDay.key(now,calendar:calendar);var result=history,goals=Set(history["goalDays"].array.map(\.string));result=result.setting("days",history["days"].setting(today,.number(max(number(history["days"][today]),Double(dailyXP)))))
        if goal>0,dailyXP>=goal{goals.insert(today)};return result.setting("goalDays",.array(goals.sorted().map(JSONValue.string)))
    }
}

extension LearnerState {
    var activityLegacy:JSONValue{XPActivityPlan.merge(xpActivity ?? .object([:]),.object(["goalDays":companionProgress?["completedGoalDates"] ?? .array([])]))}
    mutating func rememberActivity(){
        guard dailyKey.range(of:"^\\d{4}-\\d{2}-\\d{2}$",options:.regularExpression) != nil else{return}
        var snapshot=activityLegacy,days=snapshot["days"].object
        if dailyXP>0{days[dailyKey] = .number(Double(dailyXP))}
        // Local fallback is bounded; canonical historical months stay in xpHistory.
        let keep=days.keys.sorted().suffix(400);snapshot=snapshot.setting("days",.object(Dictionary(uniqueKeysWithValues:keep.map{($0,days[$0]!)})))
        let reached=companionProgress?["dailyGoalPetReachedDates"] ?? .array([])
        xpActivity=XPActivityPlan.merge(snapshot,.object(["goalDays":reached]))
    }
}
