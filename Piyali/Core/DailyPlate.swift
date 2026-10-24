import Foundation

public struct DailyQuestPlan: Codable, Sendable, Equatable {
    public let day: String
    public let kinds: [String]
    public var carry: [String]? = nil
    public var yesterdayComplete:Bool? = nil
    public init(day: String, kinds: [String]) { self.day = day; self.kinds = kinds }
}
public struct PlateCourse: Identifiable, Sendable {
    public let kind: String
    public let count: Int
    public let target: Int
    public var id: String { kind }
    public var done: Bool { count >= target }
}
public enum DailyPlate {
    public static let introductory = ["speak","learn","review"]
    public static let order = ["repair","goal","speak","learn","review","conversation","phonics"]
    public static let fields = ["review":"flashcardDailyActivity","learn":"lessonDailyActivity","speak":"speakDailyActivity","conversation":"conversationDailyActivity","phonics":"phonicsDailyActivity","repair":"repairDailyActivity","goal":"goalDailyActivity"]
    public static let bonus = 25
    public static func hash(_ text: String) -> UInt32 {
        let units = Array(text.utf16)
        var value: UInt32 = 1779033703 ^ UInt32(units.count)
        for unit in units { value = (value ^ UInt32(unit)) &* 3432918353; value = (value << 13) | (value >> 19) }
        return value
    }
    public static func firstSession(progress: JSONValue, day: String, priorLearning: Bool) -> Bool {
        guard progress["dailyQuestFirstSeen"].boolean else { return true }
        let first = progress["dailyQuestFirstDayKey"].string
        return first.isEmpty ? !priorLearning : first == day
    }
    public static func compose(base: [String], carry: [String] = [], repair: Bool, goal: Bool, first: Bool) -> [String] {
        var seen: Set<String> = []
        let normal = (carry + base).filter { ["speak","learn","review","conversation","phonics"].contains($0) && seen.insert($0).inserted }
        return (repair ? ["repair"] : []) + (goal && !first ? ["goal"] : []) + normal + (goal && first ? ["goal"] : [])
    }
    public static func weights(progress: JSONValue, target: String, day: String, kinds: [String]) -> [String:Double] {
        Dictionary(uniqueKeysWithValues:kinds.map { kind in
            (kind,1 + Double((1...7).filter { progress[fields[kind] ?? ""][target][CalendarDay.shift(day,by:-$0)].number <= 0 }.count))
        })
    }
    public static func elect(available: [String], count: Int? = nil, avoid: [String] = [], seed: String, weights: [String:Double] = [:], score: Int? = nil) -> [String] {
        var value = hash(seed); if value == 0 { value = 1 }
        func random() -> Double {
            value = value &+ 0x6d2b79f5
            var t = (value ^ (value >> 15)) &* (1 | value)
            t = (t &+ ((t ^ (t >> 7)) &* (61 | t))) ^ t
            return Double(t ^ (t >> 14)) / 4294967296
        }
        let size: Int
        if let count { size = count } else { let r = random(); size = r < 0.18 ? 2 : r < 0.82 ? 3 : 4 }
        let candidates = available.filter { !$0.isEmpty && !["goal","repair"].contains($0) }
        let maximum = max(1,min(size,candidates.count))
        guard candidates.count > maximum else { return order.filter { candidates.contains($0) } }
        let difficulty: [String:Double] = score.map { $0 < 32 ? ["review":1.5,"phonics":1.35,"speak":1.2,"learn":0.9,"conversation":0.7] : $0 >= 60 ? ["conversation":1.45,"learn":1.25,"speak":1.15,"review":0.8,"phonics":0.8] : [:] } ?? [:]
        var pool = candidates.map { ($0,max(0.0001,(weights[$0] ?? 1) * (difficulty[$0] ?? 1) * (avoid.contains($0) ? 0.25 : 1))) }
        var picked: Set<String> = []
        while picked.count < maximum && !pool.isEmpty {
            var roll = random() * pool.reduce(0) { $0 + $1.1 }, index = 0
            while index < pool.count - 1 { roll -= pool[index].1; if roll <= 0 { break }; index += 1 }
            picked.insert(pool.remove(at:index).0)
        }
        return order.filter { picked.contains($0) }
    }
    public static func courses(progress: JSONValue, bucket: JSONValue, user: String, target: String, day: String, kinds: [String], first: Bool, repairTarget: Int = 1) -> [PlateCourse] {
        compose(base:kinds,repair:kinds.contains("repair"),goal:GoalPractice.active(bucket) != nil,first:first).map { kind in
            var required = ["review":5,"learn":1,"speak":1,"conversation":4,"phonics":3,"repair":max(1,repairTarget),"goal":1][kind] ?? 1
            if kind == "review" && !first { required = 4 + Int(hash("review|\(user)|\(target)|\(day)") % 3) }
            if kind == "conversation" { required = 4 + Int(hash("conversation|\(target)|\(day)") % 4) }
            var count = Int(max(0,min(999,progress[fields[kind] ?? ""][target][day].number.rounded())))
            if kind == "goal", let daily = GoalPractice.today(bucket,day:day) {
                let modes = GoalPractice.list(daily["blueprint"]["modes"],max:4)
                if !modes.isEmpty { required = modes.count; count = modes.filter { daily["modeProgress"][$0].number >= Double(GoalPractice.targets[$0] ?? 1) }.count }
            }
            return PlateCourse(kind:kind,count:count,target:required)
        }
    }
    public static func bonusAwarded(progress: JSONValue, target: String, day: String) -> Bool {
        switch progress["plateBonusDailyActivity"][target][day] {
        case .null: return false
        case .bool(let value): return value
        case .number(let value): return value.isFinite && value != 0
        case .string(let value): return !value.isEmpty
        case .array, .object: return true
        }
    }
    public static func recorded(_ change: PracticeChange, progress: JSONValue) -> JSONValue {
        var updated = progress
        if let field = change.source.activityField {
            let days = progress[field][change.target].setting(change.dayKey,.number(progress[field][change.target][change.dayKey].number + 1))
            updated = updated.setting(field,progress[field].setting(change.target,days))
        }
        if change.source == .questStart {
            let first = progress["dailyQuestFirstDayKey"].string
            if change.questIntro == true && first.isEmpty { updated = updated.setting("dailyQuestFirstDayKey",.string(change.dayKey)) }
            updated = updated.setting("dailyQuestFirstSeen",.bool(true))
        }
        if change.source == .plateBonus { updated = updated.setting("plateBonusDailyActivity",progress["plateBonusDailyActivity"].setting(change.target,progress["plateBonusDailyActivity"][change.target].setting(change.dayKey,.string(WebProgressContract.iso(change.date))))) }
        return updated
    }
    public static func hasActivity(_ progress: JSONValue) -> Bool { fields.values.contains { field in progress[field].object.values.contains { !$0.object.isEmpty } } }
}
public extension LearnerState {
    var plateProgress: JSONValue { questProgress ?? .object([:]) }
    func introductoryQuest(day: String) -> Bool { DailyPlate.firstSession(progress:plateProgress,day:day,priorLearning:totalXP > 0 || !completed.isEmpty || DailyPlate.hasActivity(plateProgress)) }
    mutating func preparePlate(user: String, available: [String], now: Date = Date()) {
        let day = CalendarDay.key(now)
        let first = introductoryQuest(day:day)
        if let plan = questPlans?[target], plan.day == day, !first || plan.kinds == DailyPlate.introductory { return }
        let previous = questPlans?[target]
        let base = first ? DailyPlate.introductory : DailyPlate.elect(available:available,avoid:previous?.kinds ?? [],seed:"\(user):\(target):\(day)",weights:DailyPlate.weights(progress:plateProgress,target:target,day:day,kinds:available),score:score)
        if questPlans == nil { questPlans = [:] }; var plan = DailyQuestPlan(day:day,kinds:base.isEmpty ? DailyPlate.introductory : base)
        if !first, let previous, previous.day == CalendarDay.shift(day,by:-1), !activeMemories.isEmpty || GoalPractice.active(goalBucket) != nil {
            let priorFirst = introductoryQuest(day:previous.day)
            let kinds = DailyPlate.compose(base:previous.kinds,carry:previous.carry ?? [],repair:repairPlan(day:previous.day) != nil,goal:false,first:priorFirst)
            let priorCourses=DailyPlate.courses(progress:plateProgress,bucket:goalBucket,user:user,target:target,day:previous.day,kinds:kinds,first:priorFirst,repairTarget:repairPlan(day:previous.day)?["items"].array.count ?? 1)
            plan.yesterdayComplete=priorCourses.allSatisfy(\.done)
            plan.carry = Array(priorCourses.filter { !$0.done && $0.kind != "repair" }.prefix(2).map(\.kind))
        }
        questPlans?[target] = plan
        var change = PracticeChange(date:now,dayKey:day,target:target,level:level,amount:0,source:.questStart)
        change.questCarry = plan.carry;change.questYesterdayComplete=plan.yesterdayComplete
        change.questIntro = first
        change.questKinds = questPlans?[target]?.kinds
        enqueue(change)
    }
    func plateCourses(user: String, now: Date = Date()) -> [PlateCourse] {
        let day = CalendarDay.key(now), first = introductoryQuest(day:day)
        let base = first ? DailyPlate.introductory : questPlans?[target].flatMap { $0.day == day ? $0.kinds : nil } ?? DailyPlate.introductory
        let savedRepair = repairPlan(day:day)
        let repair = savedRepair != nil
        let blueprint=questDay(day:day)["blueprint"],carry=blueprint["status"].string == "ready" ? blueprint["carryOverKinds"].array.map(\.string):[]
        let composed = DailyPlate.compose(base:base,carry:carry,repair:repair,goal:GoalPractice.active(goalBucket) != nil,first:first)
        return DailyPlate.courses(progress:plateProgress,bucket:goalBucket,user:user,target:target,day:day,kinds:composed,first:first,repairTarget:savedRepair?["items"].array.count ?? 1)
    }
    mutating func claimPlate(user: String, now: Date = Date()) -> Bool {
        let day = CalendarDay.key(now), courses = plateCourses(user:user,now:now)
        guard !courses.isEmpty, courses.allSatisfy(\.done), !DailyPlate.bonusAwarded(progress:plateProgress,target:target,day:day) else { return false }
        addXP(DailyPlate.bonus,now:now,calendar:.current)
        var change = PracticeChange(date:now,dayKey:day,target:target,level:level,amount:DailyPlate.bonus,source:.plateBonus)
        change.questKinds = courses.map(\.kind); enqueue(change)
        return true
    }
}
