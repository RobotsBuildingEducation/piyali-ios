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
    public enum Action: String, Codable, Sendable { case capture, reinforce, usedInQuest, localize }
    public var id = UUID()
    public let action: Action
    public let target: String
    public let date: Date
    public let dayKey: String
    public let note: MemoryNote
    public let captureConcept:String?
    public init(action: Action, target: String, date: Date, dayKey: String, note: MemoryNote, captureConcept:String? = nil) { self.action = action; self.target = target; self.date = date; self.dayKey = dayKey; self.note = note;self.captureConcept=captureConcept }
}
public enum MemoryContract {
    static func supportCode(_ raw:String)->String {
        let code=raw.trimmingCharacters(in:.whitespacesAndNewlines).lowercased(),base=String(code.split(whereSeparator:{$0 == "-" || $0 == "_"}).first ?? "")
        if MemoryCaptureSourceData.summaries[code] != nil{return code}
        let alias=["arz":"ar","cmn":"zh"][base] ?? base
        return MemoryCaptureSourceData.summaries[alias] == nil ? "en":alias
    }
    static func cleanConcept(_ raw:String,support:String)->String {
        let trim=CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn:"\u{FEFF}")),text=raw.trimmingCharacters(in:trim)
        guard supportCode(support) != "en",!text.isEmpty else{return text}
        let regex=try! NSRegularExpression(pattern:"[\\s\\uFEFF]*\\(([^()]*)\\)"),words=try! NSRegularExpression(pattern:"[a-z]+")
        var clean=text
        for match in regex.matches(in:text,range:NSRange(text.startIndex...,in:text)).reversed() {
            guard let range=Range(match.range(at:1),in:text) else{continue};let inside=String(text[range]).lowercased()
            if words.matches(in:inside,range:NSRange(inside.startIndex...,in:inside)).contains(where:{m in Range(m.range,in:inside).map{MemoryCaptureSourceData.english.contains(String(inside[$0]))} ?? false}),let whole=Range(match.range,in:clean){clean.removeSubrange(whole)}
        }
        return clean.replacingOccurrences(of:"[\\s\\uFEFF]+",with:" ",options:.regularExpression).trimmingCharacters(in:trim)
    }
    static func conceptKey(_ value:String)->String {value.trimmingCharacters(in:.whitespacesAndNewlines).lowercased().replacingOccurrences(of:"[\\s\\uFEFF]+",with:" ",options:.regularExpression)}
    static func summary(_ concept:String,support:String)->String {(MemoryCaptureSourceData.summaries[supportCode(support)] ?? "").replacingOccurrences(of:"{concept}",with:concept)}
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
        let day = CalendarDay.key(now), error = errorType(mode),support=supportCode(support),concept=cleanConcept(concept,support:support)
        return MemoryNote(fields:[
            "id":.string("mem-\(Int(now.timeIntervalSince1970*1000))-\(UUID().uuidString.prefix(7).lowercased())"),
            "createdDayKey":.string(day),"createdAt":.number(now.timeIntervalSince1970*1000),"targetLang":.string(target),"supportLang":.string(support),
            "sourceMode":.string(mode),"sourceContext":.string(context),"concept":.string(String(concept.trimmingCharacters(in:.whitespacesAndNewlines).prefix(240))),
            "userAnswer":.string(String(answer.prefix(240))),"expectedAnswer":.string(String(expected.prefix(240))),"correction":.string(String(expected.prefix(240))),
            "errorType":.string(error),"cefrLevel":.string(level),"severity":.number(1),"recommendedRepairMode":.string(repairMode(error)),
            "companionSummary":.string(summary(concept,support:support)),"mistake":.string(feedback),"tip":.string(""),"enriched":.bool(!feedback.isEmpty),
            "expiresAfterDayKey":.string(CalendarDay.shift(day,by:1)),"usedInQuestDayKey":.null,"status":.string("captured")
        ])
    }
    public static func applying(_ change: MemoryChange, to original: [MemoryNote], today: String) -> [MemoryNote] {
        var notes = original
        if change.action == .localize {
            if let index=notes.firstIndex(where:{$0.id == change.note.id && $0.createdAt == change.note.createdAt}) {
                for key in ["mistake","correction","tip","supportLang","enriched","concept","iosMemoryEnrichedSupport"] {if let value=change.note.fields[key]{notes[index].fields[key]=value}}
            }
        } else if change.action == .reinforce {
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
            let support=supportCode(change.note.text("supportLang")),concept=cleanConcept(change.captureConcept ?? change.note.text("concept"),support:support)
            guard !concept.isEmpty else{return original}
            if let index = notes.firstIndex(where: { $0.text("createdDayKey") == change.dayKey && $0.text("sourceMode") == change.note.text("sourceMode") && conceptKey($0.text("concept")) == conceptKey(concept) }) {
                var existing=notes[index];let severity=min(3,existing.severity+1)
                if change.note.createdAt >= existing.createdAt {
                    // Preserve newer cross-device answers; source duplicate fields
                    // otherwise retain the original ID, correction and lifecycle.
                    let changedSupport=supportCode(existing.text("supportLang")) != support
                    existing.fields["createdAt"]=change.note.fields["createdAt"];existing.fields["supportLang"] = .string(support)
                    if !change.note.text("userAnswer").isEmpty{existing.fields["userAnswer"]=change.note.fields["userAnswer"]}
                    existing.fields["companionSummary"] = .string(summary(concept,support:support))
                    if changedSupport {existing.fields["mistake"] = .string("");existing.fields["tip"] = .string("");existing.fields["enriched"] = .bool(false)}
                }
                existing.fields["severity"] = .number(Double(severity));notes[index]=existing
            }else{notes.insert(change.note,at:0)}
        }
        return Array(notes.filter { $0.text("expiresAfterDayKey").isEmpty || $0.text("expiresAfterDayKey") >= today }.prefix(40))
    }
}
public extension LearnerState {
    var activeMemories: [MemoryNote] { (companionMemory?[target] ?? []).filter { $0.active(on:CalendarDay.key(Date())) }.sorted { $0.severity == $1.severity ? $0.createdAt > $1.createdAt : $0.severity > $1.severity } }
    mutating func captureMemory(mode: String, concept: String, answer: String, expected: String, feedback: String, context: String = "", now: Date = Date(), questionLevel:String? = nil,sourceContext:JSONValue? = nil,goalFocus:GoalMemoryFocus? = nil) {
        if let goalFocus,goalFocus.matches(self,now:now) {
            applyGoal(GoalChange(action:.evidence,target:target,date:now,payload:goalFocus.payload(mode:mode,concept:concept,answer:answer,expected:expected)))
            return
        }
        let concept=MemoryContract.cleanConcept(concept,support:support)
        guard !concept.isEmpty else { return }
        var note = MemoryContract.capture(target:target,support:support,level:questionLevel ?? level,mode:mode,concept:concept,answer:answer,expected:expected,feedback:feedback,context:context,now:now)
        if let sourceContext{note.fields["sourceContext"]=sourceContext}
        applyMemory(MemoryChange(action:.capture,target:target,date:now,dayKey:CalendarDay.key(now),note:note,captureConcept:concept))
    }
    /// Accepts the original source note builder's fields without replacing its
    /// localized pending summary or treating a private judge reason as enrichment.
    @discardableResult mutating func captureMemory(_ note:MemoryNote,concept:String?=nil,now:Date=Date())->MemoryNote? {
        let concept=MemoryContract.cleanConcept(concept ?? note.text("concept"),support:note.text("supportLang"))
        guard note.text("targetLang") == target,!note.id.isEmpty,!concept.isEmpty else{return nil}
        applyMemory(MemoryChange(action:.capture,target:target,date:now,dayKey:CalendarDay.key(now),note:note,captureConcept:concept))
        return companionMemory?[target]?.first{$0.id == note.id} ?? companionMemory?[target]?.first{$0.text("createdDayKey") == CalendarDay.key(now) && $0.text("sourceMode") == note.text("sourceMode") && MemoryContract.conceptKey($0.text("concept")) == MemoryContract.conceptKey(concept)}
    }
    mutating func localizeMemory(_ original:MemoryNote,fields:JSONValue,support:String,now:Date = Date()) {
        guard let current=companionMemory?[target]?.first(where:{$0.id == original.id}),current.createdAt == original.createdAt else{return}
        var note=original
        for key in ["mistake","correction","tip","concept"] {if fields[key] != .null{note.fields[key]=fields[key]}}
        note.fields["supportLang"] = .string(support);note.fields["enriched"] = .bool(true);note.fields["iosMemoryEnrichedSupport"] = .string(support)
        applyMemory(MemoryChange(action:.localize,target:target,date:now,dayKey:CalendarDay.key(now),note:note))
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

// BEGIN GENERATED MEMORY CAPTURE DATA
// Original support codes, capture summaries and English tokens; export-memory.mjs.
private enum MemoryCaptureSourceData {
    static let summaries:[String:String] = ["en":"Saved for tomorrow: {concept}","es":"Guardado para mañana: {concept}","pt":"Guardado para amanhã: {concept}","it":"Salvato per domani: {concept}","fr":"Gardé pour demain : {concept}","de":"Für morgen gemerkt: {concept}","ja":"明日のために保存：{concept}","hi":"कल के लिए सहेजा: {concept}","ar":"محفوظ لبكرة: {concept}","zh":"已为明天保存：{concept}"]
    static let english:Set<String> = ["answer","answered","captured","correct","ends","exercise","goodbye","greeting","greetings","hello","instead","learner","means","mistake","practice","reinforced","remember","repaired","said","saved","should","starts","tense","today","tomorrow","word","wrong","your"]
}
// END GENERATED MEMORY CAPTURE DATA
