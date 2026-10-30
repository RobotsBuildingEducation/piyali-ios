import Foundation

/// The shared TranslateSentence / RepeatWhatYouHear bank and ordered answer callbacks.
public enum WordBankPracticeInteraction {
    public struct State:Equatable,Sendable {
        public var bank:[Int],selected:[Int]
        public init(bank:[Int],selected:[Int]){self.bank=bank;self.selected=selected}
        public var json:JSONValue{.object(["bank":.array(bank.map{.number(Double($0))}),"selected":.array(selected.map{.number(Double($0))})])}
    }
    public static func state(_ run:PracticeRun)->State {
        let count=run.bank.count
        func indices(_ value:JSONValue)->[Int]?{guard case .array(let values)=value else{return nil};var result:[Int]=[];for value in values{guard case .number(let n)=value,n.isFinite,n.rounded()==n,n>=0,n<Double(count)else{return nil};result.append(Int(n))};return Set(result).count==result.count ? result:nil}
        let selected=indices(run.response["indices"]) ?? []
        if let bank=indices(run.response["wordBankOrder"]),bank.count+selected.count==count,Set(bank+selected)==Set(0..<count){return .init(bank:bank,selected:selected)}
        return .init(bank:Array(0..<count).filter{!selected.contains($0)},selected:selected)
    }
    public static func tap(_ state:State,index:Int,selected:Bool,locked:Bool=false)->State {
        guard !locked else{return state};var next=state
        if selected{guard next.selected.indices.contains(index)else{return state};next.bank.append(next.selected.remove(at:index))}
        else{guard next.bank.indices.contains(index)else{return state};next.selected.append(next.bank.remove(at:index))}
        return next
    }
    public static func drag(_ state:State,fromSelected:Bool,index:Int,toSelected:Bool?,position:Int,locked:Bool=false)->State {
        guard !locked,let toSelected else{return state};var source=fromSelected ? state.selected:state.bank
        guard source.indices.contains(index)else{return state};let word=source.remove(at:index)
        if fromSelected==toSelected{source.insert(word,at:max(0,min(position,source.count)));return .init(bank:fromSelected ? state.bank:source,selected:fromSelected ? source:state.selected)}
        var destination=toSelected ? state.selected:state.bank;destination.insert(word,at:max(0,min(position,destination.count)))
        return .init(bank:fromSelected ? destination:source,selected:fromSelected ? source:destination)
    }
    public static func fallbackDistractors(words:[String],answerLanguage:String)->[String] {
        func normalized(_ text:String)->String{
            var result=""
            for scalar in text.lowercased().decomposedStringWithCanonicalMapping.unicodeScalars {
                let n=scalar.value
                if (97...122).contains(n)||(48...57).contains(n)||n==95||n==39{result.unicodeScalars.append(scalar)}
                else if [9,10,11,12,13,32,160,0x1680,0x2028,0x2029,0x202f,0x205f,0x3000,0xfeff].contains(n)||(0x2000...0x200a).contains(n){result.append(" ")}
            }
            return result.split(separator:" ").joined(separator:" ")
        }
        let used=Set(words.map(normalized)),pool=answerLanguage == "es" ? ["y","o","pero","muy","también","sin","con"]:["and","or","but","very","also","without","with"]
        return Array(pool.filter{!used.contains(normalized($0))}.prefix(4))
    }
    public static func response(_ old:JSONValue,state:State)->JSONValue{old.setting("indices",.array(state.selected.map{.number(Double($0))})).setting("wordBankOrder",.array(state.bank.map{.number(Double($0))}))}
}
