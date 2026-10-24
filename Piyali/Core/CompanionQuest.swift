import Foundation
import JavaScriptCore

/// Pure policy copied from the reference's companion brain. The explicit user snapshot has no host bindings.
@MainActor public final class CompanionQuestPolicy {
    private let context:JSContext,api:JSValue
    public init(source:URL)throws {
        guard let context=JSContext() else{throw PracticeRecipeFailure.unavailable};self.context=context
        context.evaluateScript(try String(contentsOf:source,encoding:.utf8),withSourceURL:source)
        guard context.exception == nil,let api=context.objectForKeyedSubscript("PiyaliCompanionQuest"),!api.isUndefined else{throw PracticeRecipeFailure.unavailable};self.api=api
    }
    public convenience init(bundle:Bundle = .main)throws {guard let url=bundle.url(forResource:"companion-quest-policy",withExtension:"js") else{throw PracticeRecipeFailure.unavailable};try self.init(source:url)}
    public func run(_ operation:String,_ input:JSONValue)throws->JSONValue {
        context.exception=nil;let result=api.invokeMethod("run",withArguments:[operation,input.json])
        guard context.exception == nil,let text=result?.toString() else{throw PracticeRecipeFailure.invalidRecipe}
        return try JSONDecoder().decode(JSONValue.self,from:Data(text.utf8))
    }
}

public enum CompanionQuestDay {
    public static let artifactFields=Set((0..<3).flatMap{["practice_flashcards_repair\($0)","practice_phonics_repair\($0)_authored-v1"]})
    public static let ownedFields=artifactFields.union(["blueprint","repair","explanation","lang","dayKey","updatedAt"])
    public static func artifactField(_ step:RepairStep,mode:String)->String {"practice_\(mode)_repair\(step.index)"+(mode == "phonics" ? "_authored-v1":"")}
    public static func artifactKey(_ step:RepairStep,mode:String)->String {"\(step.target)_\(step.day)_\(mode)"+(mode == "phonics" ? "-authored-v1":"")+"_repair-s\(step.index)"}
    public static let staleMilliseconds:Double=600_000
    public static func key(_ target:String,_ day:String)->String {PlateHeadline.targetKey(target)+"_"+day}
    public static func reserve(_ document:JSONValue,id:String,target:String,day:String,now:Date)->JSONValue? {
        let bp=document["blueprint"],status=bp["status"].string
        guard status != "ready",status != "failed",status != "generating" || now.timeIntervalSince1970*1000-bp["startedAt"].number > staleMilliseconds else{return nil}
        return .object(["status":.string("generating"),"startedAt":.number(now.timeIntervalSince1970*1000),"dayKey":.string(day),"targetLang":.string(target),"iosGenerationID":.string(id)])
    }
    /// A late response or an offline device cannot replace an already committed plan. Other fields survive.
    public static func merging(_ patch:JSONValue,into document:JSONValue)->JSONValue {
        var merged=document
        if patch["blueprint"] != .null {
            let current=document["blueprint"],incoming=patch["blueprint"]
            let owner=incoming["iosGenerationID"].string,currentOwner=current["iosGenerationID"].string
            let accepts=current["status"].string != "ready" && (current["status"].string != "generating" || currentOwner.isEmpty || currentOwner == owner)
            if accepts {
                merged=merged.setting("blueprint",incoming)
                if !incoming["repair"]["items"].array.isEmpty {merged=merged.setting("repair",incoming["repair"])}
                if incoming["rationale"] != .null {merged=merged.setting("explanation",incoming["rationale"])}
            }
        }
        if document["explanation"] == .null,patch["explanation"] != .null,merged["explanation"] == .null {merged=merged.setting("explanation",patch["explanation"])}
        for field in artifactFields where patch[field] != .null {
            let incoming=patch[field],existing=document[field]
            if existing["cards"].array.isEmpty {merged=merged.setting(field,incoming)}
            else if existing["ownerKey"] == incoming["ownerKey"] {
                var outcomes=existing["outcomes"]
                for (id,value) in incoming["outcomes"].object where existing["cards"].array.contains(where:{$0["id"].string == id}) {
                    if !outcomes[id]["success"].boolean {outcomes=outcomes.setting(id,value)}
                }
                merged=merged.setting(field,existing.setting("outcomes",outcomes))
            }
        }
        for field in ["lang","dayKey","updatedAt"] where patch[field] != .null {merged=merged.setting(field,patch[field])}
        return merged
    }
}

public extension LearnerState {
    func questDay(target:String? = nil,day:String)->JSONValue {companionQuestDays?[CompanionQuestDay.key(target ?? self.target,day)] ?? .object([:])}
    func repairPlan(day:String)->JSONValue? {let plan=questDay(day:day)["repair"];return plan["items"].array.isEmpty ? nil : plan}
    /// Shape consumed by the original pure functions. Never includes identity or credentials.
    var companionQuestUser:JSONValue {
        var blueprint:[String:JSONValue]=[:],repair:[String:JSONValue]=[:],explanation:[String:JSONValue]=[:]
        for document in (companionQuestDays ?? [:]).values {
            let lang=document["lang"].string,day=document["dayKey"].string
            guard !lang.isEmpty,!day.isEmpty else{continue}
            for field in ["blueprint","repair","explanation"] where document[field] != .null {
                switch field {case "blueprint":blueprint[lang]=(blueprint[lang] ?? .object([:])).setting(day,document[field]);case "repair":repair[lang]=(repair[lang] ?? .object([:])).setting(day,document[field]);default:explanation[lang]=(explanation[lang] ?? .object([:])).setting(day,document[field])}
            }
        }
        var intelligence=goalIntelligence ?? [:]
        intelligence[target]=goalBucket.setting("elo",goalBucket["elo"].setting("rating",.number(rating)).setting("scaleVersion",.number(Double(PerformanceScore.version))).setting("totalGraded",.number(Double(gradedByLanguage?[target] ?? 0))))
        let progress=plateProgress.setting("targetLang",.string(target)).setting("level",.string(level)).setting("cefrLevel",.string(level)).setting("tutorUnlockedLevels",.object((tutorLevels ?? [:]).mapValues(JSONValue.string)))
        return .object(["schemaVersion":.number(2),"questDaysLoaded":.object(Dictionary(uniqueKeysWithValues:(companionQuestDays ?? [:]).keys.map{($0,.bool(true))})),"dailyQuestBlueprint":.object(blueprint),"dailyQuestRepair":.object(repair),"dailyQuestExplanations":.object(explanation),"companionMemory":.object((companionMemory ?? [:]).mapValues{.object(["notes":.array($0.map{.object($0.fields)})])}),"learningIntelligence":.object(intelligence),"progress":progress])
    }
    mutating func importQuestDay(_ value:JSONValue,target:String,day:String) {
        let key=CompanionQuestDay.key(target,day)
        if companionQuestDays == nil {companionQuestDays=[:]}
        var document=value.setting("lang",.string(target)).setting("dayKey",.string(day))
        if let pending=pendingCompanionQuestDays?[key] {document=CompanionQuestDay.merging(pending,into:document)}
        companionQuestDays?[key]=document
    }
    mutating func storeCompanionBlueprint(_ blueprint:JSONValue,target:String,day:String,now:Date = Date()) {
        queueQuestDay(.object(["blueprint":blueprint]),target:target,day:day,now:now)
        for id in blueprint["repair"]["memoryIds"].array.map(\.string) {markMemoryUsed(id:id,target:target,day:day,now:now)}
    }
    mutating func storeQuestExplanation(_ explanation:JSONValue,target:String,day:String,now:Date = Date()) {
        guard questDay(target:target,day:day)["explanation"] == .null else{return}
        queueQuestDay(.object(["explanation":explanation]),target:target,day:day,now:now)
    }
    func repairArtifact(_ step:RepairStep,mode:String)->JSONValue {
        let artifact=questDay(target:step.target,day:step.day)[CompanionQuestDay.artifactField(step,mode:mode)]
        return artifact["ownerKey"].string == CompanionQuestDay.artifactKey(step,mode:mode) ? artifact:.object([:])
    }
    mutating func storeRepairArtifact(_ artifact:JSONValue,step:RepairStep,mode:String,now:Date = Date()) {
        guard repairStepIsCurrent(step,now:now) else{return}
        queueQuestDay(.object([CompanionQuestDay.artifactField(step,mode:mode):artifact]),target:step.target,day:step.day,now:now)
    }
    @discardableResult mutating func recordRepairOutcome(_ step:RepairStep,mode:String,cardID:String,success:Bool,item:String,support:String,now:Date = Date())->Bool {
        guard repairStepIsCurrent(step,now:now) else{return false}
        let artifact=repairArtifact(step,mode:mode)
        guard let card=artifact["cards"].array.first(where:{$0["id"].string == cardID}),!artifact["outcomes"][cardID]["success"].boolean else{return false}
        let outcome:JSONValue = .object(["success":.bool(success),"support":.string(support),"item":.string(String(item.prefix(180))),"transfer":.bool(card["practiceRole"].string == "transfer")])
        storeRepairArtifact(artifact.setting("outcomes",artifact["outcomes"].setting(cardID,outcome)),step:step,mode:mode,now:now)
        if success {award(mode == "flashcards" ? 2:5,source:.repairPractice,contentID:CompanionQuestDay.artifactKey(step,mode:mode)+":"+cardID,now:now)}
        return true
    }
    private mutating func queueQuestDay(_ value:JSONValue,target:String,day:String,now:Date) {
        let key=CompanionQuestDay.key(target,day),patch=value.setting("lang",.string(target)).setting("dayKey",.string(day)).setting("updatedAt",.string(WebProgressContract.iso(now)))
        // Local generation owns its document until the authoritative sync reconciles a competing ready plan.
        var document=questDay(target:target,day:day)
        for (field,value) in patch.object {document=document.setting(field,value)}
        if patch["blueprint"] != .null {if !patch["blueprint"]["repair"]["items"].array.isEmpty {document=document.setting("repair",patch["blueprint"]["repair"])};if patch["blueprint"]["rationale"] != .null {document=document.setting("explanation",patch["blueprint"]["rationale"])}}
        if companionQuestDays == nil {companionQuestDays=[:]};companionQuestDays?[key]=document
        if pendingCompanionQuestDays == nil {pendingCompanionQuestDays=[:]}
        var pending=pendingCompanionQuestDays?[key] ?? .object([:]);for (field,value) in patch.object {pending=pending.setting(field,value)}
        pendingCompanionQuestDays?[key]=pending
    }
}

/// Isolated invocation for Firestore transaction reducers, which run on SDK worker threads.
public enum CompanionQuestRuntime {
    public static func run(source:String,operation:String,input:JSONValue)throws->JSONValue {
        guard let context=JSContext() else{throw PracticeRecipeFailure.unavailable}
        context.evaluateScript(source)
        guard context.exception == nil,let api=context.objectForKeyedSubscript("PiyaliCompanionQuest"),let result=api.invokeMethod("run",withArguments:[operation,input.json])?.toString(),context.exception == nil else{throw PracticeRecipeFailure.invalidRecipe}
        return try JSONDecoder().decode(JSONValue.self,from:Data(result.utf8))
    }
}
public struct RepairStep:Codable,Equatable,Sendable,Identifiable {
    public let index:Int
    public let mode:String
    public let item:JSONValue
    public let plan:JSONValue
    public let stepCount:Int
    public var target:String {plan["targetLang"].string}
    public var day:String {plan["dayKey"].string}
    public var id:String {"repair-\(target)-\(day)-s\(index)"}
    public var event:JSONValue {.object(["id":.string("repair:\(day):\(index):\(item["memoryId"].string.isEmpty ? item["concept"].string:item["memoryId"].string)"),"target":item["originalConcept"].string.isEmpty ? item["concept"]:item["originalConcept"],"expectedAnswer":item["expectedAnswer"],"mode":.string(mode),"domain":item["errorType"]])}
}
public struct RepairEvidenceChange:Codable,Identifiable,Sendable {
    public let id:UUID
    public let target:String
    public let date:Date
    public let event:JSONValue
    public init(target:String,date:Date,event:JSONValue) {self.id=UUID();self.target=target;self.date=date;self.event=event}
}
public extension LearnerState {
    func repairStepIsCurrent(_ step:RepairStep,now:Date = Date())->Bool {
        let day=CalendarDay.key(now),count=Int(max(0,min(999,plateProgress["repairDailyActivity"][target][day].number.rounded())))
        guard step.target == target,step.day == day,step.index == count,let plan=repairPlan(day:day),plan["items"].array.indices.contains(count) else{return false}
        return plan["items"].array[count] == step.item && !completed.contains(completionKey(step.id))
    }
    @discardableResult mutating func completeRepairStep(_ step:RepairStep,summary:JSONValue,observation:String,support:String = "prompted",now:Date = Date())->Bool {
        guard repairStepIsCurrent(step,now:now) else{return false}
        completed.insert(completionKey(step.id))
        enqueue(PracticeChange(date:now,dayKey:step.day,target:target,level:step.item["cefrLevel"].string.isEmpty ? level:step.item["cefrLevel"].string,amount:0,source:.repair,contentID:step.id))
        for id in step.plan["memoryIds"].array.map(\.string) {reinforceMemory(id:id,now:now)}
        let event=step.event.setting("success",.bool(true)).setting("observation",.string(observation)).setting("support",.string(support))
        if pendingRepairEvidence == nil {pendingRepairEvidence=[]};pendingRepairEvidence?.append(RepairEvidenceChange(target:target,date:now,event:event))
        let bucket=goalBucket.setting("version",.number(1)).setting("repairSummary",summary);if goalIntelligence == nil {goalIntelligence=[:]};goalIntelligence?[target]=bucket
        return true
    }
}
