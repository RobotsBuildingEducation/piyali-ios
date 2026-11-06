import Foundation

public enum RPGCast {
    public struct Member:Sendable {public let name:String,image:String,kind:String;public init(name:String,image:String,kind:String){self.name=name;self.image=image;self.kind=kind}}
    public static func rename(_ text:String,mapping:[String:String])->String {
        mapping.sorted{$0.key.utf16.count>$1.key.utf16.count}.reduce(text){result,pair in
            let pattern="(^|[^\\p{L}\\p{N}_])("+NSRegularExpression.escapedPattern(for:pair.key)+")(?=$|[^\\p{L}\\p{N}_])"
            guard !pair.key.isEmpty,!pair.value.isEmpty,let expression=try? NSRegularExpression(pattern:pattern)else{return result}
            return expression.stringByReplacingMatches(in:result,range:NSRange(result.startIndex...,in:result),withTemplate:"$1"+NSRegularExpression.escapedTemplate(for:pair.value))
        }
    }
    public static func applying(_ members:[Member],to scenario:RPGScenario)throws->RPGScenario {
        guard members.count == scenario.npcs.count else{return scenario}
        let mapping=Dictionary(uniqueKeysWithValues:zip(scenario.npcs,members).map{($0.0.name,$0.1.name)})
        func apply(_ value:JSONValue)->JSONValue{switch value{case .string(let text):return .string(rename(text,mapping:mapping));case .array(let values):return .array(values.map(apply));case .object(let fields):return .object(fields.mapValues(apply));default:return value}}
        var result=try JSONDecoder().decode(RPGScenario.self,from:JSONEncoder().encode(apply(try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(scenario)))))
        for i in result.npcs.indices{result.npcs[i].appearance=members[i].image;result.npcs[i].characterKind=members[i].kind};return result
    }
}
