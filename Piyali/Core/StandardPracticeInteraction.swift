import Foundation

/// The legacy standard exercises' original deterministic layout and movement rules.
public enum StandardPracticeInteraction {
    public struct State:Equatable,Sendable {
        public var bank:[Int],slots:[Int?],pick:String
        public init(bank:[Int],slots:[Int?],pick:String=""){self.bank=bank;self.slots=slots;self.pick=pick}
        public init(_ json:JSONValue){bank=json["bank"].array.map{Int($0.number)};slots=json["slots"].array.map{$0 == .null ? nil:Int($0.number)};pick=json["pick"].string}
        public var json:JSONValue{.object(["bank":.array(bank.map{.number(Double($0))}),"slots":.array(slots.map{$0.map{.number(Double($0))} ?? .null}),"pick":.string(pick)])}
    }
    public static func hash(_ text:String)->UInt32{text.utf16.reduce(0){($0 &* 31) &+ UInt32($1)}}
    public static func blankCount(_ text:String)->Int{text.components(separatedBy:"___").count-1}
    public static func useDrag(question:String,choices:[String],answers:[String],module:PracticeRecipeModule = .vocabulary)->Bool{!question.isEmpty && !choices.isEmpty && blankCount(question)>0 && (module != .grammar || blankCount(question)>=answers.count) && hash(question+"||"+choices.joined(separator:"|")+"||"+answers.joined(separator:"|"))%4<2}
    public static func usesSlots(_ question:PracticeQuestion)->Bool{
        guard ["mc","ma"].contains(question.kind)else{return false}
        let answers=question.kind == "mc" ? [question.payload["answer"].string].filter{!$0.isEmpty}:question.strings("answers")
        return useDrag(question:question.questionText,choices:question.strings("choices"),answers:answers,module:question.module) && (question.kind == "mc" || blankCount(question.questionText)==answers.count)
    }
    public static func tap(kind:String,state:State,index:Int,choices:[String])->State {
        guard let position=state.bank.firstIndex(of:index)else{return state};var next=state
        if kind == "match" {guard let slot=state.slots.firstIndex(of:nil)else{return state};return drag(kind:kind,state:state,choices:choices,source:"bank",sourceIndex:position,destination:"slot-\(slot)",destinationIndex:0,item:index)}
        if kind == "mc" {next.bank.remove(at:position);if let old=state.slots.first ?? nil{next.bank.insert(old,at:min(position,next.bank.count))};next.slots=[index];next.pick=choices.indices.contains(index) ? choices[index]:""}
        else if let slot=state.slots.firstIndex(of:nil){next.bank.remove(at:position);next.slots[slot]=index}
        return next
    }
    public static func returnSlot(kind:String,state:State,slot:Int)->State {
        guard state.slots.indices.contains(slot),let value=state.slots[slot]else{return state};var next=state;next.bank.append(value);next.slots[slot]=nil;return next
    }
    public static func drag(kind:String,state:State,choices:[String],source:String,sourceIndex:Int,destination:String?,destinationIndex:Int,item:Int?=nil)->State {
        guard let destination,source != destination || sourceIndex != destinationIndex else{return state}
        let bankID=kind == "match" ? "bank":kind+"-bank"
        func slot(_ id:String)->Int?{if kind == "mc"{return id == "mc-slot" ? 0:nil};let prefix=kind == "match" ? "slot-":"ma-slot-";return id.hasPrefix(prefix) ? Int(id.dropFirst(prefix.count)):nil}
        func insert(_ value:Int,at index:Int,into array:inout[Int]){array.insert(value,at:max(0,min(index,array.count)))}
        var next=state
        if kind == "match" {
            guard let ri=item,state.bank.contains(ri) || state.slots.contains(ri)else{return state}
            if destination == bankID {next.slots=state.slots.map{$0 == ri ? nil:$0};next.bank.removeAll{$0 == ri};insert(ri,at:destinationIndex,into:&next.bank);return next}
            guard let dest=slot(destination),state.slots.indices.contains(dest)else{return state}
            if source == bankID {next.bank.removeAll{$0 == ri};if let old=state.slots[dest]{next.bank.append(old)};next.slots[dest]=ri}
            else if let src=slot(source),state.slots.indices.contains(src),src != dest{next.slots[src]=state.slots[dest];next.slots[dest]=ri}
            return next
        }
        if source == bankID,destination == bankID {guard next.bank.indices.contains(sourceIndex)else{return state};let value=next.bank.remove(at:sourceIndex);insert(value,at:destinationIndex,into:&next.bank);return next}
        if source == bankID,let dest=slot(destination),state.slots.indices.contains(dest) {
            guard next.bank.indices.contains(sourceIndex)else{return state};let value=next.bank.remove(at:sourceIndex)
            if let old=state.slots[dest]{insert(old,at:kind == "mc" ? destinationIndex:sourceIndex,into:&next.bank)}
            next.slots[dest]=value;if kind == "mc"{next.pick=choices.indices.contains(value) ? choices[value]:""};return next
        }
        if let src=slot(source),state.slots.indices.contains(src),destination == bankID {
            guard let value=state.slots[src]else{return state};insert(value,at:destinationIndex,into:&next.bank);next.slots[src]=nil;if kind == "mc"{next.pick=""};return next
        }
        if kind == "ma",let src=slot(source),let dest=slot(destination),state.slots.indices.contains(src),state.slots.indices.contains(dest){next.slots.swapAt(src,dest)}
        return next
    }
    public static func state(_ run:PracticeRun)->State {
        let q=run.question,match=q.kind == "match",count=match ? q.strings("right").count:run.bank.count,slotCount=match ? q.strings("left").count:q.kind == "mc" ? 1:blankCount(q.questionText)
        if run.response["standardState"] != .null {
            let saved=State(run.response["standardState"]),all=saved.bank+saved.slots.compactMap{$0}
            if saved.slots.count==slotCount,all.sorted()==Array(0..<count){return saved}
        }
        var slots=Array<Int?>(repeating:nil,count:slotCount)
        if match{for index in slots.indices{let value=run.response["pairs"][String(index)];if value != .null,(0..<count).contains(Int(value.number)),!slots.contains(Int(value.number)){slots[index]=Int(value.number)}}}
        else{for (slot,value)in run.response["indices"].array.prefix(slotCount).enumerated(){let i=Int(value.number);if (0..<count).contains(i),!slots.contains(i){slots[slot]=i}}}
        let original=match ? run.rightOrder ?? Array(0..<count):Array(0..<count),bank=original.filter{!slots.contains($0)}
        return .init(bank:bank,slots:slots,pick:q.kind == "mc" ? slots.first.flatMap{$0}.flatMap{run.bank.indices.contains($0) ? run.bank[$0]:nil} ?? "":"")
    }
    public static func response(_ old:JSONValue,state:State,kind:String,choices:[String])->JSONValue {
        var response=old.setting("standardState",state.json)
        if kind == "match"{response=response.setting("pairs",.object(Dictionary(uniqueKeysWithValues:state.slots.enumerated().compactMap{index,value in value.map{(String(index),JSONValue.number(Double($0)))}})))}
        else{let indices=kind == "mc" ? choices.firstIndex(of:state.pick).map{[$0]} ?? []:state.slots.compactMap{$0};response=response.setting("indices",.array(indices.map{.number(Double($0))}))}
        return response
    }
}
