import Foundation

/// Online reauthoring may change human-readable text, never the playable graph or item identity mapping.
public enum ExplorationText {
    public static func setting(_ data:JSONValue,on original:ExplorationTemplate,target:String,support:String) throws -> ExplorationTemplate {
        let npcs=data["npcs"].array,rooms=data["rooms"].array
        guard npcs.count == original.npcs.count,rooms.count == original.maps.count,Set(npcs.map { $0["name"].string.lowercased() }).count == npcs.count else { throw ExplorationFailure.invalidQuest }
        func validText(_ value:JSONValue,_ maximum:Int) -> Bool { !value.string.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && value.string.count <= maximum }
        guard validText(data["title"],160),validText(data["supportTitle"],160),npcs.allSatisfy({ validText($0["name"],40) && validText($0["personality"],500) }),rooms.allSatisfy({ validText($0["title"],100) && validText($0["supportTitle"],100) }) else { throw ExplorationFailure.invalidQuest }
        func names(_ old:JSONValue,_ localized:JSONValue) -> JSONValue { old.setting(target,localized["title"]).setting(support,localized["supportTitle"]) }
        var result=original;result.name=names(original.name,data)
        result.npcs=zip(original.npcs,npcs).map { $0.0.setting("name",$0.1["name"]).setting("personality",$0.1["personality"]) }
        result.quest=transform(protectedQuest(original)) { text in npcs.enumerated().reduce(text) { $0.replacingOccurrences(of:"__NPC_\($1.offset)__",with:$1.element["name"].string) } }
        let roomNames=Dictionary(uniqueKeysWithValues:zip(original.maps,rooms).map { ($0.0.id,names($0.0.name ?? .object([:]),$0.1)) })
        result.maps=original.maps.map { old in ExplorationMap(id:old.id,name:roomNames[old.id],world:old.world,portals:old.portals.map { $0.setting("label",roomNames[$0["toMapId"].string] ?? $0["label"]) }) }
        return try result.validated()
    }
    private static let editable:Set<String>=["intro","storySeed","title","npcLine","npcReply","text","playerLine","playerBridge","speechFallbackReply","speechContinueReply","name","hint","gatherWrongItemTemplate","supportName","supportHint","transcription"]
    public static func transform(_ value:JSONValue,_ text:(String)->String) -> JSONValue {
        switch value { case .string(let v):return .string(text(v));case .array(let values):return .array(values.map { transform($0,text) });case .object(let values):return .object(values.mapValues { transform($0,text) });default:return value }
    }
    public static func protectedQuest(_ scenario:ExplorationTemplate) -> JSONValue {
        transform(scenario.quest) { value in scenario.npcs.enumerated().reduce(value) { result,pair in
            let name=NSRegularExpression.escapedPattern(for:pair.element["name"].string)
            return result.replacingOccurrences(of:"(?<![\\p{L}\\p{N}_])"+name+"(?![\\p{L}\\p{N}_])",with:"__NPC_\(pair.offset)__",options:.regularExpression)
        } }
    }
    private static func valid(_ candidate:JSONValue,_ base:JSONValue,key:String = "") -> Bool {
        switch (candidate,base) {
        case (.string(let text),.string(let original)):
            guard editable.contains(key) else { return text == original }
            guard text.utf8.count <= 4000,!original.isEmpty || text.isEmpty else { return false }
            for token in ["{{wrongItem}}","{{correctItem}}"] where original.contains(token) { if !text.contains(token) { return false } }
            return original.isEmpty || !text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty
        case (.array(let a),.array(let b)):return a.count == b.count && zip(a,b).allSatisfy { valid($0.0,$0.1,key:key) }
        case (.object(let a),.object(let b)):return Set(a.keys) == Set(b.keys) && b.allSatisfy { valid(a[$0.key] ?? .null,$0.value,key:$0.key) }
        default:return candidate == base
        }
    }
    public static func applying(_ candidate:JSONValue,to original:ExplorationTemplate,target:String) throws -> ExplorationTemplate {
        let protected=protectedQuest(original)
        guard valid(candidate,protected),candidate.json.utf8.count < 100_000 else { throw ExplorationFailure.invalidQuest }
        let restored=transform(candidate) { text in original.npcs.enumerated().reduce(text) { $0.replacingOccurrences(of:"__NPC_\($1.offset)__",with:$1.element["name"].string) } }
        guard !restored.json.contains("__NPC_") else { throw ExplorationFailure.invalidQuest }
        let prior=original.quest["gatherData"]["all"].array,items=restored["gatherData"]["all"].array
        guard prior.count == items.count,Set(items.map { $0["name"].string }).count == items.count else { throw ExplorationFailure.invalidQuest }
        let mapping=Dictionary(uniqueKeysWithValues:zip(prior,items).map { ($0.0["name"].string,$0.1) })
        func consistent(_ base:JSONValue,_ changed:JSONValue) -> Bool {
            if case .object(let fields)=base {
                if fields["name"] != nil,let expected=mapping[base["name"].string],changed["name"] != expected["name"] { return false }
                return fields.allSatisfy { consistent($0.value,changed[$0.key]) }
            }
            if case .array(let values)=base { return zip(values,changed.array).allSatisfy { consistent($0.0,$0.1) } };return true
        }
        guard consistent(original.quest,restored) else { throw ExplorationFailure.invalidQuest }
        let lines=restored["steps"].array.flatMap { $0["nodes"].array }.map { $0["npcLine"].string }.joined(separator:" ")
        guard RPGStory.languageScript(target,text:lines) else { throw ExplorationFailure.invalidQuest }
        if target != original.baseLanguage,lines == original.quest["steps"].array.flatMap({ $0["nodes"].array }).map({ $0["npcLine"].string }).joined(separator:" ") { throw ExplorationFailure.invalidQuest }
        var result=original;result.quest=restored;result.baseLanguage=target
        result.gatherPlacements=original.gatherPlacements.map { placement in
            guard let item=mapping[placement["name"].string] else { return placement }
            return placement.setting("name",item["name"]).setting("hint",item["hint"]).setting("supportName",item["supportName"]).setting("supportHint",item["supportHint"])
        };return try result.validated()
    }
}
