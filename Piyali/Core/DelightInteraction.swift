import Foundation

/// Native response changes for the source's token, sorting and word-building controls.
public enum DelightInteraction {
    public static func wordOrder(_ words:[String])->[String] {
        func score(_ word:String)->UInt32 {word.unicodeScalars.reduce(UInt32(2166136261)){($0 ^ $1.value) &* 16777619}}
        return words.enumerated().sorted {let a=score($0.element),b=score($1.element);return a == b ? $0.offset < $1.offset:a < b}.map(\.element)
    }
    public static func neighborhood(question:JSONValue,response:JSONValue,word:String,group:Int?,locked:Bool)->JSONValue {
        let groups=question["groups"].array
        guard !locked,groups.flatMap({$0["items"].array.map(\.string)}).contains(word),group == nil || groups.indices.contains(group!) else{return response}
        var assignments=response["assignments"].object
        if let group{assignments[word] = .number(Double(group))}else{assignments.removeValue(forKey:word)}
        return .object(["assignments":.object(assignments)])
    }
    public static func forge(question:JSONValue,response:JSONValue,piece:Int,toForge:Bool,locked:Bool)->JSONValue {
        guard !locked,question["pieces"].array.indices.contains(piece) else{return response}
        var chosen=response["pieceIndices"].array.map{Int($0.number)}
        if toForge {guard !chosen.contains(piece)else{return response};chosen.append(piece)}
        else {guard let position=chosen.firstIndex(of:piece)else{return response};chosen.remove(at:position)}
        return .object(["pieceIndices":.array(chosen.map{.number(Double($0))})])
    }
    public static func detective(question:JSONValue,response:JSONValue,index:Int,locked:Bool)->JSONValue {
        let rejected=response["rejectedTokenIndices"].array
        guard !locked,question["tokens"].array.indices.contains(index),response["tokenIndex"] != question["incorrectIndex"],!rejected.contains(.number(Double(index))) else{return response}
        if index == Int(question["incorrectIndex"].number){return response.setting("tokenIndex",.number(Double(index))).setting("replacement",.string("")).setting("rejectedTokenIndices",.array([]))}
        var values=rejected;if !values.contains(.number(Double(index))){values.append(.number(Double(index)))}
        return response.setting("tokenIndex",.null).setting("replacement",.string("")).setting("rejectedTokenIndices",.array(values))
    }
    public static func repair(question:JSONValue,response:JSONValue,word:String,locked:Bool)->JSONValue {
        guard !locked,response["tokenIndex"] == question["incorrectIndex"],question["replacements"].array.contains(.string(word))else{return response}
        return response.setting("replacement",.string(word))
    }
}
