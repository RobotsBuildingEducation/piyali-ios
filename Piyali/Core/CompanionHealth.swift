import Foundation

/// Calendar-day health and observed healthy-day evidence from the web's dailyGoalPet.js.
public enum CompanionHealth {
    public static let keys: Set<String> = ["createdAt","dailyXp","dailyHasCelebrated","dailyResetAt","dailyStartedAt","completedGoalDates","lastGoalDayKey","dailyGoalPetHealth","dailyGoalPetLastAccountedDay","dailyGoalPetTrackedDay","dailyGoalPetStartedFull","dailyGoalPetHealthyDates","dailyGoalPetReachedDates","dailyGoalPetLastOutcome","dailyGoalPetLastDelta","dailyGoalPetLastUpdatedAt"]
    private static func numeric(_ value: Any?, fallback: Double = 0) -> Double {
        let number: Double
        if value is NSNull { number = 0 }
        else if let n = value as? NSNumber { number = n.doubleValue }
        else if let s = value as? String { number = s.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty ? 0 : Double(s) ?? fallback }
        else { number = fallback }
        return number.isFinite ? number : fallback
    }
    public static func health(_ fields: [String:Any]) -> Int { Int(max(0,min(100,floor(numeric(fields["dailyGoalPetHealth"],fallback:100)+0.5)))) }
    public static func goal(_ fields: [String:Any]) -> Int {
        let progress = fields["progress"] as? [String:Any] ?? [:], stats = fields["stats"] as? [String:Any] ?? [:]
        let raw = [fields["dailyGoalXp"],progress["dailyGoalXp"],stats["dailyGoalXp"]].compactMap { $0 }.first { !($0 is NSNull) }
        let n = numeric(raw)
        return Int(max(0,min(Double(Int.max).nextDown,floor(n+0.5))))
    }
    public static func expired(_ fields: [String:Any], now: Date) -> Bool { (WebProgressContract.date(fields["dailyResetAt"]) ?? .distantPast) <= now }
    private static func index(_ key: String) -> Int? {
        guard key.range(of:"^\\d{4}-\\d{2}-\\d{2}$",options:.regularExpression) != nil else { return nil }
        let p = key.split(separator:"-").compactMap { Int($0) }
        var calendar = Calendar(identifier:.gregorian); calendar.timeZone = TimeZone(secondsFromGMT:0)!
        // JS Date.UTC normalizes overflow dates and treats years 0...99 as 1900...1999.
        let year = p[0] < 100 ? p[0] + 1900 : p[0]
        guard let start = calendar.date(from:DateComponents(year:year,month:1,day:1)), let month = calendar.date(byAdding:.month,value:p[1]-1,to:start), let date = calendar.date(byAdding:.day,value:p[2]-1,to:month) else { return nil }
        return Int(floor(date.timeIntervalSince1970/86400))
    }
    private static func key(_ index: Int) -> String {
        var calendar = Calendar(identifier:.gregorian); calendar.timeZone = TimeZone(secondsFromGMT:0)!
        return CalendarDay.key(Date(timeIntervalSince1970:Double(index)*86400),calendar:calendar)
    }
    private static func reached(_ fields: [String:Any]) -> Set<String> {
        var dates = Set((fields["completedGoalDates"] as? [String] ?? []) + (fields["dailyGoalPetReachedDates"] as? [String] ?? []))
        if let last = fields["lastGoalDayKey"] as? String, !last.isEmpty { dates.insert(last) }
        return dates
    }
    public static func missed(_ fields: [String:Any], now: Date, calendar: Calendar = .current) -> Int {
        guard goal(fields) > 0, let today = index(CalendarDay.key(now,calendar:calendar)) else { return 0 }
        let yesterday = today-1
        var through = index((fields["dailyGoalPetLastAccountedDay"] as? String ?? "").trimmingCharacters(in:.whitespacesAndNewlines))
        if through == nil {
            let date = (fields["createdAt"] as? NSNumber).map { Date(timeIntervalSince1970:$0.doubleValue/1000) } ?? WebProgressContract.date(fields["createdAt"])
            through = date.flatMap { index(CalendarDay.key($0,calendar:calendar)) }
        }
        let lower = max(through ?? yesterday,yesterday-400)
        guard lower < yesterday else { return 0 }
        let done = reached(fields)
        return ((lower+1)...yesterday).reduce(0) { $0 + (done.contains(key($1)) ? 0 : 1) }
    }
    public static func resetFields(_ fields: [String:Any], now: Date, resetWindow: Bool = true, calendar: Calendar = .current) -> [String:Any] {
        let current = health(fields), next = max(0,current - missed(fields,now:now,calendar:calendar)*10)
        let todayKey = CalendarDay.key(now,calendar:calendar), today = index(todayKey)!
        var healthy = Set(fields["dailyGoalPetHealthyDates"] as? [String] ?? [])
        if let tracked = index(fields["dailyGoalPetTrackedDay"] as? String ?? ""), tracked < today, fields["dailyGoalPetStartedFull"] as? Bool == true, current == 100 {
            let done = reached(fields)
            // Only scan bounded stored evidence; every credited day must have an observed goal hit.
            for day in tracked..<min(today,tracked+done.count+1) { guard done.contains(key(day)) else { break }; healthy.insert(key(day)) }
        }
        let sameDay = fields["dailyGoalPetTrackedDay"] as? String == todayKey
        var patch: [String:Any] = ["dailyGoalPetTrackedDay":todayKey,"dailyGoalPetStartedFull":sameDay ? fields["dailyGoalPetStartedFull"] as? Bool == true && current == 100 && next == 100 : next == 100,"dailyGoalPetHealthyDates":healthy.sorted(),"dailyGoalPetHealth":next,"dailyGoalPetLastAccountedDay":key(today-1)]
        if resetWindow { patch.merge(["dailyXp":0,"dailyHasCelebrated":false,"dailyResetAt":WebProgressContract.iso(now.addingTimeInterval(86400)),"dailyStartedAt":WebProgressContract.iso(now)]) { _,new in new } }
        if next < current { patch.merge(["dailyGoalPetLastOutcome":"missed","dailyGoalPetLastDelta":next-current,"dailyGoalPetLastUpdatedAt":WebProgressContract.iso(now)]) { _,new in new } }
        return patch
    }
    public static func reconcileFields(_ fields: [String:Any], now: Date = Date(), calendar: Calendar = .current) -> [String:Any] {
        guard goal(fields) > 0, expired(fields,now:now) || missed(fields,now:now,calendar:calendar) > 0 else { return [:] }
        return resetFields(fields,now:now,resetWindow:expired(fields,now:now),calendar:calendar)
    }
    /// Called inside the XP transaction, after reads, so concurrent devices celebrate only once.
    public static func awardFields(_ fields: [String:Any], amount: Int, now: Date, calendar: Calendar = .current) -> [String:Any] {
        var patch = expired(fields,now:now) ? resetFields(fields,now:now,calendar:calendar) : reconcileFields(fields,now:now,calendar:calendar)
        let effective = fields.merging(patch) { _,new in new }
        let daily = max(0,WebProgressContract.integer(effective["dailyXp"])) + max(0,amount)
        patch["dailyXp"] = daily
        guard goal(effective) > 0, daily >= goal(effective), effective["dailyHasCelebrated"] as? Bool != true else { return patch }
        let current = health(effective), next = min(100,current+15), today = CalendarDay.key(now,calendar:calendar)
        let dates = Set((fields["dailyGoalPetReachedDates"] as? [String] ?? []) + [today])
        patch.merge(["dailyHasCelebrated":true,"dailyGoalPetHealth":next,"dailyGoalPetReachedDates":Array(dates.sorted().suffix(400)),"dailyGoalPetStartedFull":effective["dailyGoalPetStartedFull"] as? Bool == true && current == 100 && next == 100,"dailyGoalPetLastOutcome":"achieved","dailyGoalPetLastDelta":15,"dailyGoalPetLastUpdatedAt":WebProgressContract.iso(now)]) { _,new in new }
        return patch
    }
}
public extension LearnerState {
    var companionHealth: Int { CompanionHealth.health(companionFields) }
    var companionStatus: String {
        switch companionHealth { case 0: return "Inactive"; case 1...24: return "Unhealthy"; case 25...49: return "Stressed"; case 50...74: return "Unhappy"; case 75...99: return "Healthy"; default: return "Happy" }
    }
    var companionFields: [String:Any] {
        var fields = companionProgress?.foundation as? [String:Any] ?? [:]; fields["dailyGoalXp"] = dailyGoal; return fields
    }
    mutating func reconcileCompanion(now: Date = Date(), calendar: Calendar = .current) {
        let fields = companionFields
        companionProgress = JSONValue.foundation(fields.filter { CompanionHealth.keys.contains($0.key) }.merging(CompanionHealth.reconcileFields(fields,now:now,calendar:calendar)) { _,new in new })
    }
    mutating func rewardCompanion(_ amount: Int, now: Date, calendar: Calendar = .current) {
        let fields = companionFields
        companionProgress = JSONValue.foundation(fields.filter { CompanionHealth.keys.contains($0.key) }.merging(CompanionHealth.awardFields(fields,amount:amount,now:now,calendar:calendar)) { _,new in new })
    }
}
