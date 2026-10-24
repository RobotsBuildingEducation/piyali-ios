import Foundation
import CryptoKit
import Combine
import FirebaseFirestore

/// Uses the same private event ledger and permanent award documents as the main web product.
@MainActor final class AchievementSyncService {
    static let shared = AchievementSyncService()
    let updates=PassthroughSubject<(String,[String:JSONValue]),Never>()
    private let catalog = (try? ContentLibrary.load([AchievementDefinition].self,name:"achievements")) ?? []
    private lazy var phonics = (try? ContentLibrary.load([String:[JSONValue]].self,name:"phonics")) ?? [:]
    private var allowed: Set<String> { Set(catalog.flatMap { [$0.requirement["metric"].string] + $0.requirement["metrics"].array.map(\.string) }.filter { !$0.isEmpty }) }
    nonisolated static func documentID(metric: String, id: String) throws -> String {
        let data=try JSONSerialization.data(withJSONObject:[metric,id],options:[.withoutEscapingSlashes])
        return SHA256.hash(data:data).map { String(format:"%02x",$0) }.joined()
    }
    nonisolated static func jsonFields(_ data: [String:Any]?) -> JSONValue {
        func convert(_ input: Any) -> JSONValue {
            if let timestamp=input as? Timestamp { return .string(WebProgressContract.iso(timestamp.dateValue())) }
            if let date=input as? Date { return .string(WebProgressContract.iso(date)) }
            if let map=input as? [String:Any] { return .object(map.mapValues(convert)) }
            if let values=input as? [Any] { return .array(values.map(convert)) }
            guard JSONSerialization.isValidJSONObject([input]),let bytes=try? JSONSerialization.data(withJSONObject:input,options:[.fragmentsAllowed]),let value=try? JSONDecoder().decode(JSONValue.self,from:bytes) else { return .null }
            return value
        }
        return convert(data ?? [:])
    }
    private func value(_ data: [String:Any]?) -> JSONValue { Self.jsonFields(data) }
    private final class Cache {
        var records: [String:JSONValue] = [:]
        var ledger = JSONValue.object([:])
        var listeners: [ListenerRegistration] = []
        deinit { for listener in listeners { listener.remove() } }
    }
    private var caches: [String:Cache] = [:]
    private func cacheKey(_ user: DocumentReference) -> String { user.firestore.app.name + ":" + user.path }
    private func ledger(_ snapshot: QuerySnapshot) -> JSONValue {
        var ledger=JSONValue.object([:])
        for doc in snapshot.documents {
            let entry=value(doc.data());guard entry["source"].string == "nosabos" else { continue }
            ledger=AchievementProgress.recording([.object(["metric":entry["metric"],"id":entry["completionId"]])],ledger:ledger)
        }
        return AchievementProgress.mergedLedger([ledger],allowed:allowed)
    }
    private func cache(_ user: DocumentReference) async throws -> Cache {
        let key=cacheKey(user)
        if let cached=caches[key] { return cached }
        let awards=user.collection("achievements"),events=user.collection("achievementProgress").document("nosabos").collection("events")
        let records=try await awards.getDocuments(source:.server),snapshot=try await events.getDocuments(source:.server)
        if let cached=caches[key] { return cached }
        let result=Cache();result.records=Dictionary(uniqueKeysWithValues:records.documents.map { ($0.documentID,value($0.data())) });result.ledger=ledger(snapshot);caches[key]=result
        result.listeners.append(awards.addSnapshotListener(includeMetadataChanges:true) { [weak self,weak result] snapshot,_ in
            guard let snapshot,!snapshot.metadata.hasPendingWrites,!snapshot.metadata.isFromCache else { return }
            Task { @MainActor in guard let self,let result else { return };for doc in snapshot.documents {
                let incoming=self.value(doc.data()),current=result.records[doc.documentID] ?? .null
                let chosen=NostrAchievementCollection.merging([.object([doc.documentID:current]),.object([doc.documentID:incoming])])[doc.documentID]
                if chosen != .null { result.records[doc.documentID]=chosen }
            }
                self.updates.send((user.documentID,result.records))
            }
        })
        result.listeners.append(events.addSnapshotListener(includeMetadataChanges:true) { [weak self,weak result] snapshot,_ in
            guard let snapshot,!snapshot.metadata.hasPendingWrites,!snapshot.metadata.isFromCache else { return }
            Task { @MainActor in guard let self,let result else { return };result.ledger=AchievementProgress.mergedLedger([result.ledger,self.ledger(snapshot)],allowed:self.allowed) }
        })
        return result
    }
    func load(user: DocumentReference, state: inout LearnerState) async throws {
        let cache=try await cache(user)
        let summaries=try await user.collection("courseProgress").getDocuments(source:.server)
        state.achievementEvidence=Dictionary(uniqueKeysWithValues:summaries.documents.map { ($0.documentID,value($0.data())) })
        state.achievementRecords=cache.records;state.achievementLedger=cache.ledger
    }
    func refreshLedger(user: DocumentReference) async throws {
        let cache=try await cache(user)
        let snapshot=try await user.collection("achievementProgress").document("nosabos").collection("events").getDocuments(source:.server)
        cache.ledger=AchievementProgress.mergedLedger([cache.ledger,ledger(snapshot)],allowed:allowed)
    }
    func importRecords(_ records: JSONValue, user: DocumentReference) async throws -> [String:JSONValue] {
        let catalog=(try? ContentLibrary.load([JSONValue].self,name:"achievement-protocol")) ?? []
        let definitions=Dictionary(uniqueKeysWithValues:catalog.map { ($0["id"].string,$0) }),cache=try await cache(user)
        for (id,incoming) in NostrAchievementCollection.merging([records]).object {
            guard let definition=definitions[id] else { continue }
            let ref=user.collection("achievements").document(id)
            let saved=try await user.firestore.runTransaction { tx,error -> Any? in do {
                let old=Self.jsonFields(try tx.getDocument(ref).data()),chosen=NostrAchievementCollection.merging([.object([id:old]),.object([id:incoming])])[id]
                if chosen != incoming || chosen == old { return old.foundation }
                var fields=chosen.foundation
                fields["achievementId"]=id;fields["source"]=definition["source"].string;fields["catalogVersion"]=definition["catalogVersion"].number
                fields["title"]=definition["title"].string;fields["description"]=definition["description"].string;fields["orb"]=definition["orb"].foundation;fields["number"]=definition["number"].number
                tx.setData(fields,forDocument:ref);return fields
            } catch let failure { error?.pointee=failure as NSError;return nil } }
            if let fields=saved as? [String:Any] { cache.records[id]=value(fields) }
        }
        updates.send((user.documentID,cache.records));return cache.records
    }
    private func tutorRecord(_ data: JSONValue) -> Bool {
        guard let value=data.object["tutorAgendaProgress"] else { return false }
        switch value { case .null:return false;case .bool(let value):return value;case .number(let value):return value != 0;case .string(let value):return !value.isEmpty;case .object,.array:return true }
    }
    private func courseSummary(language: String, documents: [String:[JSONValue]], stored: JSONValue) -> JSONValue {
        var result=stored.object;result["schemaVersion"] = .number(1);result["targetLang"] = .string(language);result["migration"] = .object(["complete":.bool(true)])
        for (mode,collection) in ["tutor":"tutorLanguageLessons","skillTree":"languageLessons","flashcards":"languageFlashcards"] {
            var completed:[String:Set<String>]=[:]
            for entry in documents[collection] ?? [] {
                let data=entry["data"],documentID=entry["id"].string
                if mode == "skillTree" && tutorRecord(data) { continue }
                let id=mode == "flashcards" ? (data["cardId"].string.isEmpty ? documentID : data["cardId"].string) : (data["lessonId"].string.isEmpty ? documentID : data["lessonId"].string)
                let raw=data["cefrLevel"].string.isEmpty ? data["card"]["cefrLevel"].string : data["cefrLevel"].string
                var level=LearningLanguages.levels.first { AchievementProgress.levelKey($0) == AchievementProgress.levelKey(raw) }
                if level == nil {
                    if mode == "flashcards" { level=LearningLanguages.levels.first { id.lowercased().hasPrefix($0.lowercased()+"-") } }
                    else if id.lowercased().contains("lesson-tutorial") || id.lowercased().contains("unit-tutorial-pre-a1") || id.lowercased().range(of:"(?:lesson|unit)-pre-a1(?:-|$)|(?:lesson|unit)-a1-(?:1|3|4)(?:-|$)",options:.regularExpression) != nil { level="Pre-A1" }
                    else { level=LearningLanguages.levels.dropFirst().first { id.lowercased().range(of:"(?:lesson|unit)-"+$0.lowercased()+"(?:-|$)",options:.regularExpression) != nil } }
                }
                guard let level,!id.isEmpty,mode == "flashcards" ? data["completed"].boolean && id.lowercased().hasPrefix(level.lowercased()+"-") : data["status"].string == "completed" else { continue }
                completed[level,default:[]].insert(id)
            }
            var levels=result[mode]?["levels"].object ?? [:]
            let totals=mode == "flashcards" ? [100,300,250,200,150,100,50] : [86,98,126,105,84,70,56]
            for (i,level) in LearningLanguages.levels.enumerated() {
                let key=AchievementProgress.levelKey(level);var stats=levels[key]?.object ?? [:]
                stats["total"] = .number(Double(totals[i]));stats["completed"] = .number(max(Double(completed[level]?.count ?? 0),levels[key]?["completed"].number ?? 0));levels[key] = .object(stats)
            }
            var bucket=result[mode]?.object ?? [:];bucket["levels"] = .object(levels);result[mode] = .object(bucket)
        }
        return .object(result)
    }
    func sync(user: DocumentReference, changes: [PracticeChange]) async throws {
        let profile=value(try await user.getDocument(source:.server).data())
        let marker=user.collection("achievementMigrations").document("nosabos_v1")
        let migration=value(try await marker.getDocument(source:.server).data())
        let backfill = !migration["complete"].boolean || migration["version"].number != 1
        var records:[String:[JSONValue]]=[:]
        if backfill {
            for name in ["courseProgress","languageLessons","tutorLanguageLessons","languageFlashcards","alphabetPractice","questDays"] {
                let snapshot=try await user.collection(name).getDocuments(source:.server);records[name]=snapshot.documents.map { .object(["id":.string($0.documentID),"data":value($0.data())]) }
            }
        } else {
            let summaries=try await user.collection("courseProgress").getDocuments(source:.server)
            records["courseProgress"]=summaries.documents.map { .object(["id":.string($0.documentID),"data":value($0.data())]) }
            let reviews=Set(changes.filter { $0.source == .review }.compactMap { change in change.contentID.map { change.target+"_"+$0 } })
            for id in reviews { let doc=try await user.collection("languageFlashcards").document(id).getDocument(source:.server);if let data=doc.data() { records["languageFlashcards",default:[]].append(.object(["id":.string(id),"data":value(data)])) } }
            let targets=Set(changes.map(\.target)).union([profile["progress"]["targetLang"].string]).subtracting([""])
            for language in targets {
                let id=language+"_"+CalendarDay.key(Date()),quest=try await user.collection("questDays").document(id).getDocument(source:.server)
                if let data=quest.data() { records["questDays",default:[]].append(.object(["id":.string(id),"data":value(data)])) }
                if changes.contains(where:{ $0.target == language && ($0.source == .phonics || $0.source == .phonicsAttempt && $0.phonicsData?["focused"].boolean != true) }) {
                    let docs=try await user.collection("alphabetPractice").whereField("targetLang",isEqualTo:language).getDocuments(source:.server)
                    records["alphabetPractice",default:[]].append(contentsOf:docs.documents.map { .object(["id":.string($0.documentID),"data":value($0.data())]) })
                }
            }
        }
        var groups:[String:[String:[JSONValue]]]=[:],summaries:[String:JSONValue]=[:]
        for entry in records["courseProgress"] ?? [] { summaries[entry["data"]["targetLang"].string.isEmpty ? entry["id"].string : entry["data"]["targetLang"].string]=entry["data"] }
        for name in ["languageLessons","tutorLanguageLessons","languageFlashcards"] {
            for entry in records[name] ?? [] {
                let data=entry["data"],language=data["targetLang"].string.isEmpty ? String(entry["id"].string.split(separator:"_",maxSplits:1).first ?? "") : data["targetLang"].string
                guard !language.isEmpty else { continue }
                let field=name == "languageLessons" && tutorRecord(data) ? "tutorLanguageLessons" : name
                groups[language,default:[:]][field,default:[]].append(entry)
            }
            if backfill { for (language,map) in profile["progress"][name].object { for (id,data) in map.object {
                let field=name == "languageLessons" && tutorRecord(data) ? "tutorLanguageLessons" : name
                groups[language,default:[:]][field,default:[]].append(.object(["id":.string(id),"data":data]))
            }}}
        }
        var state=LearnerState();try await load(user:user,state:&state)
        var ledger=state.achievementLedger ?? .object([:]),evidences:[JSONValue]=[],legacyIDs:Set<String>=[]
        let cache=try await cache(user)
        let priorLedger=cache.ledger
        let otherLanguages=Set((records["alphabetPractice"] ?? []).map { $0["data"]["targetLang"].string }).union(profile["dailyQuestRepair"].object.keys)
        let languages=Set(groups.keys).union(otherLanguages).union(summaries.keys).union(profile["learningIntelligence"].object.keys).union([profile["realWorldTasks"]["targetLang"].string,profile["progress"]["targetLang"].string]).subtracting([""])
        for language in languages.sorted() {
            let summary=courseSummary(language:language,documents:groups[language] ?? [:],stored:summaries[language] ?? .object([:]))
            // Merge with the latest transaction snapshot so in-flight completions cannot be lost.
            let ref=user.collection("courseProgress").document(language)
            let committed = try await user.firestore.runTransaction { tx,error -> Any? in
                do { let current=Self.jsonFields(try tx.getDocument(ref).data());var merged=summary.object
                    for mode in ["tutor","skillTree","flashcards"] { var bucket=summary[mode].object,levels=summary[mode]["levels"].object
                        for (key,stats) in levels { var value=stats.object;value["completed"] = .number(max(stats["completed"].number,current[mode]["levels"][key]["completed"].number));levels[key] = .object(value) }
                        bucket["levels"] = .object(levels);merged[mode] = .object(bucket)
                    }
                    let fields=JSONValue.object(merged).foundation
                    if JSONValue.object(merged) != current { tx.setData(fields,forDocument:ref,merge:true) }
                    return fields
                } catch let failure { error?.pointee=failure as NSError;return nil }
            }
            let confirmed=(committed as? [String:Any]).map { Self.jsonFields($0) } ?? summary
            let proof=AchievementProgress.completionProof(profile:profile,summary:confirmed,quest:.object([:]),language:language,day:"")
            ledger=AchievementProgress.recording(proof.events,ledger:ledger);var evidence=proof.evidence.object
            let cards=(groups[language]?["languageFlashcards"] ?? []).compactMap { entry -> JSONValue? in let data=entry["data"];return AchievementProgress.flashcardEvent(language:language,id:data["cardId"].string.isEmpty ? entry["id"].string.replacingOccurrences(of:language+"_",with:"") : data["cardId"].string,progress:data) }
            ledger=AchievementProgress.recording(cards,ledger:ledger)
            var counts=evidence["counters"]?.object ?? [:];counts["flashcards_completed"] = .number(max(counts["flashcards_completed"]?.number ?? 0,Double(ledger["flashcards_completed:"+language].object.count)));evidence["counters"] = .object(counts);evidences.append(.object(evidence))
            let earned=AchievementProgress.tutorEarnedLevel(summary:confirmed),index=LearningLanguages.levels.firstIndex(of:earned) ?? 0
            for a in catalog where a.requirement["type"].string == "level" && index >= (LearningLanguages.levels.firstIndex(of:a.requirement["level"].string) ?? Int.max) { legacyIDs.insert(a.id) }
            for quest in records["questDays"] ?? [] where quest["data"]["lang"].string == language || quest["id"].string.hasPrefix(language+"_") {
                let data=quest["data"],day=data["dayKey"].string.isEmpty ? String(quest["id"].string.dropFirst(language.count+1)) : data["dayKey"].string
                ledger=AchievementProgress.recording(AchievementProgress.completionProof(profile:profile,summary:.object([:]),quest:data,language:language,day:day).events,ledger:ledger)
            }
            if backfill { for (day,repair) in profile["dailyQuestRepair"][language].object {
                ledger=AchievementProgress.recording(AchievementProgress.completionProof(profile:profile,summary:.object([:]),quest:.object(["repair":repair]),language:language,day:day).events,ledger:ledger)
            }}
            let docs=(records["alphabetPractice"] ?? []).map { $0["data"] }.filter { $0["targetLang"].string == language }
            let decks=phonics.filter { $0.key.hasPrefix(language+":"+(profile["progress"]["supportLang"].string.isEmpty ? "en" : profile["progress"]["supportLang"].string)+":") }
            for (_,base) in decks where !docs.isEmpty { let phonics=AchievementProgress.phonicsProof(language:language,base:base,documents:docs);ledger=AchievementProgress.recording(phonics.events,ledger:ledger);evidences.append(phonics.evidence) }
        }
        ledger=AchievementProgress.mergedLedger([ledger],allowed:allowed)
        // Write one document per stable completion ID. Existing events are never replaced.
        for (metric,entries) in ledger.object { for id in entries.object.keys.sorted() {
            if priorLedger[metric].object[id] != nil { continue }
            let ref=user.collection("achievementProgress").document("nosabos").collection("events").document(try Self.documentID(metric:metric,id:id))
            _ = try await user.firestore.runTransaction { tx,error -> Any? in do { if !(try tx.getDocument(ref)).exists { tx.setData(["source":"nosabos","metric":metric,"completionId":id,"version":1],forDocument:ref) };return true } catch let failure { error?.pointee=failure as NSError;return nil } }
        }}
        cache.ledger=AchievementProgress.mergedLedger([cache.ledger,ledger],allowed:allowed)
        ledger=cache.ledger
        // A saved successful card remains proof after switching devices or languages.
        for (metric,entries) in ledger.object where metric.hasPrefix("flashcards_completed:") { evidences.append(.object(["language":.string(String(metric.dropFirst("flashcards_completed:".count))),"counters":.object(["flashcards_completed":.number(Double(entries.object.count))])])) }
        evidences.append(.object([:]))
        var earned=legacyIDs
        for evidence in evidences { let snapshot=AchievementProgress.snapshot(ledger:ledger,evidence:evidence);for a in catalog where a.progression == true && AchievementProgress.meets(a.requirement,evidence:snapshot) { earned.insert(a.id) } }
        let timestamp=Int(Date().timeIntervalSince1970)
        for a in catalog where earned.contains(a.id) {
            let known=cache.records[a.id] ?? .null
            if known["unlockedAt"].number > 0 && !NostrAchievementCollection.truthy(known["test"]) { continue }
            let ref=user.collection("achievements").document(a.id)
            let saved = try await user.firestore.runTransaction { tx,error -> Any? in do {
                let current=try tx.getDocument(ref).data() ?? [:]
                if WebProgressContract.number(current["unlockedAt"]) > 0 && !NostrAchievementCollection.truthy(Self.jsonFields(current)["test"]) { return current }
                let record:[String:Any]=["unlockedAt":timestamp,"catalogVersion":a.catalogVersion ?? 8,"achievementId":a.id,"source":"nosabos","title":a.title.localized("en"),"description":a.description.localized("en"),"orb":a.orb?.foundation ?? [:],"number":a.number ?? 0,"test":false]
                tx.setData(record,forDocument:ref);return record
            } catch let failure { error?.pointee=failure as NSError;return nil } }
            if let record=saved as? [String:Any] { cache.records[a.id]=value(record) }
        }
        if backfill { try await marker.setData(["source":"nosabos","version":1,"complete":true,"completedAt":timestamp]) }
    }
}
