import Foundation

public struct ImmersionChange: Codable, Identifiable, Sendable {
    public enum Action: String, Codable, Sendable { case batch, completion, claim, opened }
    public var id=UUID()
    public let date: Date
    public let target: String
    public let action: Action
    public let payload: JSONValue
    public init(date: Date = Date(), target: String, action: Action, payload: JSONValue) { self.date=date;self.target=target;self.action=action;self.payload=payload }
}
public enum DailyImmersion {
    public static let version=4, rewardXP=15
    public struct Candidate: Sendable { public let lesson: Lesson;public let index:Int;public let level:String;public let mode:String }
    public static func candidate(lessons: [Lesson], progress: JSONValue, completedCount: Int, level: String, mode: String, priority: String? = nil) -> Candidate? {
        guard !lessons.isEmpty else { return nil }
        let selected: Int
        if let priority,let index=lessons.firstIndex(where:{ $0.id == priority && progress[$0.id]["status"].string != "completed" }) { selected=index }
        else if let index=lessons.firstIndex(where:{ progress[$0.id]["status"].string == "in_progress" }) { selected=index }
        else { let last=lessons.indices.filter { progress[lessons[$0].id]["status"].string == "completed" }.max() ?? -1;selected=min(lessons.count-1,max(0,completedCount,last+1)) }
        return Candidate(lesson:lessons[selected],index:selected,level:level,mode:mode)
    }
    public static func leading(_ skill: Candidate?,_ tutor: Candidate?) -> Candidate? {
        guard let skill else { return tutor };guard let tutor else { return skill }
        let s=LearningLanguages.levels.firstIndex(of:skill.level) ?? -1,t=LearningLanguages.levels.firstIndex(of:tutor.level) ?? -1
        return t == s ? (tutor.index >= skill.index ? tutor : skill) : (t > s ? tutor : skill)
    }
    public static func context(_ candidate: Candidate?, support: String) -> JSONValue {
        guard let candidate else { return .null };let lesson=candidate.lesson
        var seen:Set<String>=[]
        let focus=(lesson.content["grammar"]["focusPoints"].array+lesson.content["vocabulary"]["focusPoints"].array).map { String($0.string.trimmingCharacters(in:.whitespacesAndNewlines).prefix(90)) }.filter { !$0.isEmpty && seen.insert($0).inserted }.prefix(4)
        return .object(["title":.string(String(lesson.title.localized(support).prefix(140))),"description":.string(String(lesson.description.localized(support).prefix(140))),"level":.string(candidate.level),"source":.string(candidate.mode),"objective":.string(String((lesson.objectives?["communicativeObjectives"].array.first?.string ?? lesson.agenda["communicativeObjectives"].array.first?.string ?? "").prefix(180))),"focusPoints":.array(focus.map(JSONValue.string))])
    }
    public static func completed(_ batch: JSONValue, index: Int) -> Bool {
        let values=batch["completed"]
        return NostrAchievementCollection.truthy(index < values.array.count ? values.array[index] : values[String(index)])
    }
    public static func state(_ batch: JSONValue, day: String, target: String, support: String, goal: JSONValue = .null, placementAt: String = "", calendar: Calendar = .current) -> JSONValue {
        let storedDay=batch["dayKey"].string.isEmpty ? WebProgressContract.date(batch["generatedAt"].string).map { CalendarDay.key($0,calendar:calendar) } ?? "" : batch["dayKey"].string
        let tasks=batch["tasks"].array,goalText=goal["text"].string.trimmingCharacters(in:.whitespacesAndNewlines)
        let empty:JSONValue = .object(["status":.string("new"),"tasks":.array([]),"completed":.array([]),"rewarded":.bool(false),"dayKey":.string(day)])
        guard storedDay == day,batch["targetLang"].string == target,batch["appLanguage"].string.isEmpty || support.isEmpty || batch["appLanguage"].string == support,tasks.count >= 3,tasks.prefix(3).allSatisfy({ NostrAchievementCollection.truthy($0["title"]) }) else { return empty }
        // The reference preserves a started/rewarded batch across placement/version changes.
        let untouched = batch["completed"].array.isEmpty || !batch["completed"].array.contains(where:NostrAchievementCollection.truthy)
        if (batch["generationVersion"].number < Double(version) || !placementAt.isEmpty && batch["placementAt"].string != placementAt) && untouched && !NostrAchievementCollection.truthy(batch["rewarded"]) { return empty }
        let fourth=tasks.count >= 4,matches=fourth && batch["goalId"].string == goal["id"].string && batch["goalText"].string == goalText
        let status = !goalText.isEmpty ? (matches ? "ready" : "goal_update") : (fourth ? "goal_removed" : "ready")
        let count = !goalText.isEmpty && matches ? 4 : 3
        return .object(["status":.string(status),"tasks":.array(Array(tasks.prefix(count))),"completed":.array((0..<count).map { .bool(completed(batch,index:$0)) }),"rewarded":.bool(NostrAchievementCollection.truthy(batch["rewarded"])),"dayKey":.string(day)])
    }
    private static func clean(_ text: String, limit: Int) -> String { String(text.replacingOccurrences(of:"\\s+",with:" ",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines).prefix(limit)) }
    private static func key(_ text: String) -> String { text.lowercased().precomposedStringWithCompatibilityMapping.replacingOccurrences(of:"[^\\p{L}\\p{N}]+",with:" ",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines) }
    public static func normalize(_ raw: JSONValue, count: Int, recent: [JSONValue] = []) -> [JSONValue]? {
        var value=raw
        if case .string(let text)=raw {
            let source=text.replacingOccurrences(of:"(?s)```(?:json)?\\s*(.*?)```",with:"$1",options:[.regularExpression,.caseInsensitive])
            guard let first=source.firstIndex(of:"{"),let last=source.lastIndex(of:"}"),first <= last,let decoded=try? JSONDecoder().decode(JSONValue.self,from:Data(source[first...last].utf8)) else { return nil };value=decoded
        }
        let tasks = value.array.isEmpty ? value["tasks"].array : value.array
        guard tasks.count == count else { return nil }
        var titles:Set<String>=[];let previous=Set(recent.map { key($0["title"].string)+"|"+key($0["description"].string) })
        var cleaned:[JSONValue]=[]
        for task in tasks {
            let title=clean(task["title"].string,limit:100),description=clean(task["description"].string,limit:320),text=(title+" "+description).lowercased()
            guard !title.isEmpty,!description.isEmpty,!key(title).isEmpty,titles.insert(key(title)).inserted,!previous.contains(key(title)+"|"+key(description)) else { return nil }
            let outsiders="\\b(stranger|clerk|cashier|employee|salesperson|local business|restaurant|cafe|store|shop|market)\\b",visit="\\b(ask|approach|visit|go to|travel to|buy|purchase|order from|talk to)\\b"
            if text.range(of:outsiders,options:.regularExpression) != nil && text.range(of:visit,options:.regularExpression) != nil { return nil }
            if text.range(of:"\\b(create|open|sign up for) an? (account|profile)\\b|\\bpost publicly\\b|\\bshare publicly\\b",options:.regularExpression) != nil { return nil }
            cleaned.append(.object(["title":.string(title),"description":.string(description)]))
        }
        return cleaned
    }
    public static func history(_ old: [JSONValue], adding tasks: [JSONValue]) -> [JSONValue] {
        var result:[JSONValue]=[]
        for task in old+tasks {
            let title=String(task["title"].string.trimmingCharacters(in:.whitespacesAndNewlines).prefix(100)),description=String(task["description"].string.trimmingCharacters(in:.whitespacesAndNewlines).prefix(320))
            guard !title.isEmpty else { continue }
            let id=(title+" "+description).lowercased().precomposedStringWithCompatibilityMapping
            result.removeAll { ($0["title"].string+" "+$0["description"].string).lowercased().precomposedStringWithCompatibilityMapping == id }
            result.append(.object(["title":.string(title),"description":.string(description)]))
        }
        return Array(result.suffix(24))
    }
    public static func receipt(target: String, day: String) -> String { "daily-immersion:\(target):\(day)" }
    /// Applies one operation to the committed web batch. Task identity and per-index timestamps reject stale edits.
    public static func applying(_ change: ImmersionChange, batch: JSONValue, history stored: JSONValue, receipts: JSONValue, goal: JSONValue, placementAt: String) -> (batch:JSONValue,history:JSONValue,receipts:JSONValue,reward:Int) {
        let p=change.payload,day=p["dayKey"].string,support=p["appLanguage"].string
        var next=batch,hist=stored,claims=receipts,baseReward=0
        let status=state(batch,day:day,target:change.target,support:support,goal:goal,placementAt:placementAt)["status"].string
        guard !day.isEmpty else { return (next,hist,claims,0) }
        if change.action == .batch {
            guard status != "ready",p["goalId"].string == goal["id"].string,p["goalText"].string == goal["text"].string.trimmingCharacters(in:.whitespacesAndNewlines),p["placementAt"].string == placementAt else { return (next,hist,claims,0) }
            let priorLanguage=batch["targetLang"].string
            if !priorLanguage.isEmpty { hist=hist.setting(priorLanguage,.array(history(hist[priorLanguage].array,adding:batch["recentTaskHistory"].array+batch["tasks"].array))) }
            if status == "goal_removed" {
                next=batch.setting("tasks",.array(Array(batch["tasks"].array.prefix(3)))).setting("completed",.array((0..<3).map { .bool(completed(batch,index:$0)) })).setting("goalId",.string("")).setting("goalText",.string(""))
            } else if status == "goal_update" {
                guard let task=normalize(p["tasks"],count:1,recent:history(hist[change.target].array,adding:batch["tasks"].array))?.first else { return (batch,stored,claims,0) }
                next=batch.setting("tasks",.array(Array(batch["tasks"].array.prefix(3))+[task])).setting("completed",.array((0..<3).map { .bool(completed(batch,index:$0)) } + [.bool(false)])).setting("goalId",p["goalId"]).setting("goalText",p["goalText"])
                var times=next["iosCompletedAt"].object;times.removeValue(forKey:"3");next=next.setting("iosCompletedAt",.object(times))
            } else if p["tasks"].array.count == 1,state(p["baseBatch"],day:day,target:change.target,support:support,goal:goal,placementAt:placementAt)["status"].string == "goal_update" {
                // A goal edit can reach Firebase before the offline proposal/completions that preceded it.
                // Retain that locally practiced base set when no committed batch has won this scope yet.
                let base=p["baseBatch"]
                guard let task=normalize(p["tasks"],count:1,recent:history(hist[change.target].array,adding:base["tasks"].array))?.first else { return (batch,stored,claims,0) }
                next=base.setting("tasks",.array(Array(base["tasks"].array.prefix(3))+[task])).setting("completed",.array((0..<3).map { .bool(completed(base,index:$0)) } + [.bool(false)])).setting("goalId",p["goalId"]).setting("goalText",p["goalText"])
                var times=next["iosCompletedAt"].object;times.removeValue(forKey:"3");next=next.setting("iosCompletedAt",.object(times))
                if base["rewarded"].boolean,base["tasks"].array.indices.allSatisfy({ completed(base,index:$0) }) {
                    let key=receipt(target:change.target,day:day)
                    baseReward=NostrAchievementCollection.truthy(claims[key]) ? 0 : rewardXP
                    if claims[key] == .null { claims=claims.setting(key,.string(WebProgressContract.iso(change.date))) }
                } else { next=next.setting("rewarded",.bool(false)) }
            } else {
                let recent = history(hist[change.target].array,adding:batch["targetLang"].string == change.target ? batch["recentTaskHistory"].array+batch["tasks"].array : [])
                guard let tasks=normalize(p["tasks"],count:goal["text"].string.isEmpty ? 3 : 4,recent:recent) else { return (batch,stored,claims,0) }
                var fields=p.object;fields.removeValue(forKey:"baseBatch")
                next=JSONValue.object(fields).setting("tasks",.array(tasks)).setting("completed",.array(tasks.map { _ in .bool(false) })).setting("rewarded",.bool(false)).setting("generationVersion",.number(Double(version))).setting("recentTaskHistory",.array(recent)).setting("targetLang",.string(change.target)).setting("generatedAt",.string(WebProgressContract.iso(change.date)))
                hist=hist.setting(change.target,.array(recent))
            }
            return (next,hist,claims,baseReward)
        }
        guard batch["targetLang"].string == change.target,batch["dayKey"].string == day,batch["generatedAt"] == p["generatedAt"],status == "ready" else { return (next,hist,claims,0) }
        if change.action == .opened { return (next.setting("iosOpenedAt",.string(WebProgressContract.iso(change.date))),hist,claims,0) }
        if change.action == .completion {
            let tasks=batch["tasks"].array,raw=p["index"].number
            guard raw >= 0,raw < Double(tasks.count),raw.rounded(.down) == raw else { return (next,hist,claims,0) }
            let index=Int(raw)
            guard index >= 0,index < tasks.count,tasks[index] == p["task"],WebProgressContract.iso(change.date) >= batch["iosCompletedAt"][String(index)].string else { return (next,hist,claims,0) }
            var values=tasks.indices.map { JSONValue.bool(completed(batch,index:$0)) };values[index] = .bool(p["value"].boolean)
            next=batch.setting("completed",.array(values)).setting("iosCompletedAt",batch["iosCompletedAt"].setting(String(index),.string(WebProgressContract.iso(change.date))))
        }
        let all = !next["tasks"].array.isEmpty && next["tasks"].array.indices.allSatisfy { completed(next,index:$0) }
        let rewardKey=receipt(target:change.target,day:day)
        guard all,!next["rewarded"].boolean else { return (next,hist,claims,0) }
        let earned = NostrAchievementCollection.truthy(claims[rewardKey]) ? 0 : rewardXP
        claims=claims.setting(rewardKey,claims[rewardKey] == .null ? .string(WebProgressContract.iso(change.date)) : claims[rewardKey])
        next=next.setting("rewarded",.bool(true)).setting("rewardedAt",.string(WebProgressContract.iso(change.date)))
        return (next,hist,claims,earned)
    }
}
public extension LearnerState {
    var immersionLevel: String { [level,flashcardLevel,tutorLevel].max { (LearningLanguages.levels.firstIndex(of:$0) ?? -1) < (LearningLanguages.levels.firstIndex(of:$1) ?? -1) } ?? "Pre-A1" }
    var immersionGoal: JSONValue { GoalPractice.active(goalBucket) ?? .null }
    var immersionPlacement: String { pendingPlacements?[target].map { WebProgressContract.iso($0.updatedAt) } ?? immersionPlacementAt ?? placements?[target].map { WebProgressContract.iso($0.updatedAt) } ?? "" }
    func immersionState(now: Date = Date()) -> JSONValue { DailyImmersion.state(immersionBatch ?? .null,day:CalendarDay.key(now),target:target,support:support,goal:immersionGoal,placementAt:immersionPlacement) }
    var immersionRecent: [JSONValue] { DailyImmersion.history(immersionHistory?[target]?.array ?? [],adding:immersionBatch?["targetLang"].string == target ? (immersionBatch?["recentTaskHistory"].array ?? []) + (immersionBatch?["tasks"].array ?? []) : []) }
    func immersionScope(now: Date = Date()) -> JSONValue { .object(["dayKey":.string(CalendarDay.key(now)),"targetLang":.string(target),"appLanguage":.string(support),"placementAt":.string(immersionPlacement),"cefrLevel":.string(immersionLevel),"goalId":immersionGoal["id"],"goalText":.string(immersionGoal["text"].string.trimmingCharacters(in:.whitespacesAndNewlines))]) }
    @discardableResult mutating func applyImmersion(_ change: ImmersionChange, enqueue: Bool = true, award: Bool = true) -> Int {
        let result=DailyImmersion.applying(change,batch:immersionBatch ?? .null,history:.object(immersionHistory ?? [:]),receipts:immersionRewardReceipts ?? .object([:]),goal:GoalPractice.active(goalIntelligence?[change.target] ?? .null) ?? .null,placementAt:change.target == target ? immersionPlacement : change.payload["placementAt"].string)
        immersionBatch=result.batch;immersionHistory=result.history.object;immersionRewardReceipts=result.receipts
        if award && result.reward > 0 {
            if CalendarDay.key(change.date) >= dailyKey { let selected=target;target=change.target;addXP(result.reward,now:change.date,calendar:.current);target=selected }
            else { xpByLanguage[change.target,default:0] += result.reward }
        }
        if enqueue { if pendingImmersionChanges == nil { pendingImmersionChanges=[] };pendingImmersionChanges?.append(change) }
        return result.reward
    }
    mutating func toggleImmersion(index: Int, now: Date = Date()) {
        guard immersionState(now:now)["status"].string == "ready",let batch=immersionBatch,index >= 0,index < batch["tasks"].array.count else { return }
        let payload=immersionScope(now:now).setting("generatedAt",batch["generatedAt"]).setting("index",.number(Double(index))).setting("task",batch["tasks"].array[index]).setting("value",.bool(!DailyImmersion.completed(batch,index:index)))
        applyImmersion(.init(date:now,target:target,action:.completion,payload:payload))
    }
}
