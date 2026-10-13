import Foundation

public enum NostrAchievementCollection {
    public static let kind=30078
    public static let identifier="learning-achievements"
    public static let identifiers=[identifier,identifier+":nosabos",identifier+":robotsbuildingeducation"]
    public static func truthy(_ value: JSONValue) -> Bool {
        switch value { case .null:return false;case .bool(let v):return v;case .number(let v):return v.isFinite && v != 0;case .string(let v):return !v.isEmpty;case .array,.object:return true }
    }
    public static func merging(_ maps: [JSONValue]) -> JSONValue {
        var merged:[String:JSONValue]=[:]
        for map in maps { for (id,record) in map.object {
            guard case .number(let timestamp)=record["unlockedAt"],timestamp.isFinite,timestamp > 0 else { continue }
            let old=merged[id]
            if old == nil || truthy(old!["test"]) && !truthy(record["test"]) || truthy(old!["test"]) == truthy(record["test"]) && timestamp < old!["unlockedAt"].number { merged[id]=record }
        }}
        return .object(merged)
    }
    public static func completed(_ map: JSONValue, catalog: [JSONValue]) -> JSONValue {
        var result=merging([map]).object
        let byID=Dictionary(uniqueKeysWithValues:catalog.map { ($0["id"].string,$0) })
        func earned(_ id: String) -> Bool { guard let record=result[id] else { return false };return record["unlockedAt"].number > 0 && !truthy(record["test"]) }
        func index(_ level: String) -> Int { LearningLanguages.levels.firstIndex { AchievementProgress.levelKey($0) == AchievementProgress.levelKey(level) } ?? -1 }
        for (id,record) in map.object where earned(id) {
            guard let item=byID[id] else { continue }
            let req=item["requirement"],type=req["type"].string
            let tutorLevel = type == "level_set" && req["metric"].string == "tutor" ? LearningLanguages.levels[min(max(0,index(req["level"].string))+1,6)] : id == "piyali_full_curriculum_v4" ? "C2" : ""
            for candidate in catalog {
                let r=candidate["requirement"],ci=index(r["level"].string)
                let same=["level_set","level_counter","level"].contains(type) && r["type"].string == type && r["metric"] == req["metric"] && ci >= 0 && ci <= index(req["level"].string)
                let full=id == "piyali_full_curriculum_v4" && r["type"].string == "level_set" && req["modes"].array.contains(r["metric"])
                let reach = !tutorLevel.isEmpty && r["type"].string == "level" && r["metric"].string == "tutorEarnedLevel" && ci <= index(tutorLevel)
                let key=candidate["id"].string
                if (same || full || reach) && !earned(key) { result[key] = .object(["unlockedAt":record["unlockedAt"],"source":candidate["source"],"catalogVersion":candidate["catalogVersion"]]) }
            }
        }
        for candidate in catalog where candidate["requirement"]["type"].string == "collection" {
            let id=candidate["id"].string,required=candidate["requirement"]["all"].array.map(\.string)
            if !earned(id) && !required.isEmpty && required.allSatisfy(earned) { result[id] = .object(["unlockedAt":.number(required.map { result[$0]!["unlockedAt"].number }.max()!),"source":candidate["source"],"catalogVersion":candidate["catalogVersion"]]) }
        }
        return .object(result)
    }
    public static func body(_ records: JSONValue, createdAt: Int64) -> JSONValue { .object(["schemaVersion":.number(1),"catalogVersion":.number(8),"unlocked":records,"updatedAt":.number(Double(createdAt))]) }
}
