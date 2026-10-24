import Foundation

/// The web's companion/{language}.notes payload, retaining fields owned by other clients.
public struct MemoryNote: Codable, Identifiable, Equatable, Sendable {
    public var fields: [String:JSONValue]
    public var id: String { text("id") }
    public func text(_ key: String) -> String { fields[key]?.string ?? "" }
    public func number(_ key: String) -> Double { if case .number(let value) = fields[key] { return value }; return 0 }
    public var severity: Int { Int(max(1,min(3,number("severity")))) }
    public var createdAt: Date { Date(timeIntervalSince1970:number("createdAt")/1000) }
    public func active(on day: String) -> Bool { !["reinforced","expired"].contains(text("status")) && (text("expiresAfterDayKey").isEmpty || text("expiresAfterDayKey") >= day) }
    public init(fields: [String:JSONValue]) { self.fields = fields }
}
public struct MemoryChange: Codable, Identifiable, Sendable {
    public enum Action: String, Codable, Sendable { case capture, reinforce, usedInQuest }
    public var id = UUID()
    public let action: Action
    public let target: String
    public let date: Date
    public let dayKey: String
    public let note: MemoryNote
    public init(action: Action, target: String, date: Date, dayKey: String, note: MemoryNote) { self.action = action; self.target = target; self.date = date; self.dayKey = dayKey; self.note = note }
}
public enum MemoryContract {
    public static func errorType(_ mode: String) -> String {
        ["flashcard":"vocabulary","vocabulary":"vocabulary","grammar":"grammar","phonics":"phonics","conversation":"conversation_flow","tutor":"conversation_flow","reading":"reading","story":"pronunciation"][mode] ?? "unknown"
    }
    public static func repairMode(_ error: String) -> String {
        ["vocabulary":"flashcards","grammar":"lesson","reading":"flashcards","writing":"lesson","pronunciation":"phonics","phonics":"phonics","listening":"flashcards","conversation_flow":"tutor","confidence":"tutor","unknown":"flashcards"][error] ?? "review"
    }
    public static func practiceMode(_ note: MemoryNote) -> PracticeMode {
        switch note.text("recommendedRepairMode") { case "lesson":.grammar; case "phonics":.speaking; case "tutor":.conversation; default:.vocabulary }
    }
    public static func capture(target: String, support: String, level: String, mode: String, concept: String, answer: String, expected: String, feedback: String, context: String = "", now: Date = Date()) -> MemoryNote {
        let day = CalendarDay.key(now), error = errorType(mode)
        return MemoryNote(fields:[
            "id":.string("mem-\(Int(now.timeIntervalSince1970*1000))-\(UUID().uuidString.prefix(7).lowercased())"),
            "createdDayKey":.string(day),"createdAt":.number(now.timeIntervalSince1970*1000),"targetLang":.string(target),"supportLang":.string(support),
            "sourceMode":.string(mode),"sourceContext":.string(context),"concept":.string(String(concept.trimmingCharacters(in:.whitespacesAndNewlines).prefix(240))),
            "userAnswer":.string(String(answer.prefix(240))),"expectedAnswer":.string(String(expected.prefix(240))),"correction":.string(String(expected.prefix(240))),
            "errorType":.string(error),"cefrLevel":.string(level),"severity":.number(1),"recommendedRepairMode":.string(repairMode(error)),
            "companionSummary":.string(""),"mistake":.string(feedback),"tip":.string(""),"enriched":.bool(!feedback.isEmpty),
            "expiresAfterDayKey":.string(CalendarDay.shift(day,by:1)),"usedInQuestDayKey":.null,"status":.string("captured")
        ])
    }
    public static func applying(_ change: MemoryChange, to original: [MemoryNote], today: String) -> [MemoryNote] {
        var notes = original
        if change.action == .reinforce {
            if let index = notes.firstIndex(where: { $0.id == change.note.id }) {
                notes[index].fields["status"] = .string("reinforced")
                if notes[index].text("usedInQuestDayKey").isEmpty { notes[index].fields["usedInQuestDayKey"] = .string(change.dayKey) }
                notes[index].fields["iosReinforcedAt"] = .number(change.date.timeIntervalSince1970*1000)
            }
        } else if change.action == .usedInQuest {
            if let index=notes.firstIndex(where:{$0.id == change.note.id}),notes[index].text("status") != "reinforced" {
                notes[index].fields["status"] = .string("used_in_quest")
                notes[index].fields["usedInQuestDayKey"] = .string(change.dayKey)
            }
        } else {
            func key(_ text: String) -> String { text.lowercased().split(whereSeparator: { $0.isWhitespace }).joined(separator:" ") }
            if let index = notes.firstIndex(where: { $0.text("createdDayKey") == change.dayKey && $0.text("sourceMode") == change.note.text("sourceMode") && key($0.text("concept")) == key(change.note.text("concept")) }) {
                var existing = notes[index]
                let severity = min(3,existing.severity + 1)
                if change.note.createdAt >= existing.createdAt {
                    // The existing ID, lifecycle and unknown web fields survive repeated slips.
                    let changedSupport = existing.text("supportLang") != change.note.text("supportLang")
                    for field in ["createdAt","supportLang","userAnswer","expectedAnswer","correction"] { existing.fields[field] = change.note.fields[field] }
                    if changedSupport || (existing.fields["enriched"] != .bool(true) && !change.note.text("mistake").isEmpty) {
                        for field in ["mistake","tip","enriched"] { existing.fields[field] = change.note.fields[field] }
                    }
                }
                existing.fields["severity"] = .number(Double(severity)); notes[index] = existing
            } else { notes.append(change.note) }
        }
        return Array(notes.filter { $0.text("expiresAfterDayKey").isEmpty || $0.text("expiresAfterDayKey") >= today }.sorted { $0.createdAt == $1.createdAt ? $0.id < $1.id : $0.createdAt > $1.createdAt }.prefix(40))
    }
}
public extension LearnerState {
    var activeMemories: [MemoryNote] { (companionMemory?[target] ?? []).filter { $0.active(on:CalendarDay.key(Date())) }.sorted { $0.severity == $1.severity ? $0.createdAt > $1.createdAt : $0.severity > $1.severity } }
    mutating func captureMemory(mode: String, concept: String, answer: String, expected: String, feedback: String, context: String = "", now: Date = Date(), questionLevel:String? = nil) {
        guard !concept.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return }
        let note = MemoryContract.capture(target:target,support:support,level:questionLevel ?? level,mode:mode,concept:concept,answer:answer,expected:expected,feedback:feedback,context:context,now:now)
        applyMemory(MemoryChange(action:.capture,target:target,date:now,dayKey:CalendarDay.key(now),note:note))
    }
    mutating func reinforceMemory(id: String, now: Date = Date()) {
        guard let note = companionMemory?[target]?.first(where: { $0.id == id }) else { return }
        applyMemory(MemoryChange(action:.reinforce,target:target,date:now,dayKey:CalendarDay.key(now),note:note))
    }
    mutating func markMemoryUsed(id:String,target:String,day:String,now:Date = Date()) {
        guard let note=companionMemory?[target]?.first(where:{$0.id == id}),note.text("status") != "reinforced",note.text("usedInQuestDayKey") != day else{return}
        applyMemory(MemoryChange(action:.usedInQuest,target:target,date:now,dayKey:day,note:note))
    }
    private mutating func applyMemory(_ change: MemoryChange) {
        if companionMemory == nil { companionMemory = [:] }
        let notes = MemoryContract.applying(change,to:companionMemory?[change.target] ?? [],today:CalendarDay.key(change.date))
        companionMemory?[change.target] = notes
        if pendingMemoryChanges == nil { pendingMemoryChanges = [] }; pendingMemoryChanges?.append(change)
    }
}
