import Foundation
import Combine

@MainActor final class PhonicsCourseController:ObservableObject {
    @Published private(set) var deck:[JSONValue]=[]
    @Published private(set) var collected:[JSONValue]=[]
    @Published private(set) var counts:JSONValue = .object([:])
    @Published private(set) var course:JSONValue = .null
    @Published private(set) var activeLevel="Pre-A1"
    @Published private(set) var initialized=false
    @Published private(set) var sessionGeneration=UUID()
    @Published private(set) var generating=false
    @Published private(set) var error:String?
    weak var currentSession:PhonicsSessionController?
    private var all:[JSONValue]=[],authored:[JSONValue]=[],extras:[JSONValue]=[],scope="",interacted=false
    private var policy:PhonicsPolicy?
    let goal:JSONValue?,repair:RepairStep?
    init(goal:JSONValue?=nil,repair:RepairStep?=nil){self.goal=goal;self.repair=repair}
    var focused:Bool {goal != nil || repair != nil}
    var total:Int {focused ? deck.count+collected.count:authored.count+extras.count}
    var completed:Int {focused ? collected.count:(authored+extras).filter{counts[$0["id"].string].number>0}.count}
    var complete:Bool {initialized && deck.isEmpty && total>0 && collected.count>=total}
    func copy(_ key:String,app:AppModel)->String {policy?.copy(key,language:app.learner.support,target:app.learner.target) ?? key}
    func control(_ key:String,app:AppModel)->String {(try? policy?.run("ph_copy",.object(["language":.string(app.learner.support),"targetLang":.string(app.learner.target),"key":.string("progress")])))?["controls"][key].string ?? key}
    private func key(_ app:AppModel)->String {app.identity.npub+":"+app.learner.target+":"+app.learner.support+":"+(goal?["goalId"].string ?? repair?.id ?? "ordinary")}
    private func baseLevel(_ app:AppModel)->String {[app.lessonLevels.last,app.cardLevels.last,app.tutorLevels.last].compactMap{$0}.max{(LearningLanguages.levels.firstIndex(of:$0) ?? 0)<(LearningLanguages.levels.firstIndex(of:$1) ?? 0)} ?? "Pre-A1"}
    func load(_ app:AppModel)async {
        let token=key(app);scope=token;initialized=false;sessionGeneration=UUID();interacted=false;error=nil
        do {
            policy=try PhonicsPolicy(engine:app.companionQuestPolicy)
            if app.phonicsLibrary.isEmpty{await app.reloadContent()};try Task.checkCancellation();guard token == key(app) else{return}
            all=try LearningLanguages.levels.flatMap{app.phonicsLibrary[app.learner.target+":"+app.learner.support+":"+$0] ?? []}.map{try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode($0))}
            if let goal {try await app.prepareGoalDeck(goal,mode:"phonics");try await app.finishPhonicsFocus(goal:goal,repair:nil);let artifact=app.goalArtifact(goal,mode:"phonics");partitionFocus(artifact,app:app)}
            else if let repair {try await app.prepareRepairPhonics(repair);try await app.finishPhonicsFocus(goal:nil,repair:repair);partitionFocus(app.learner.repairArtifact(repair,mode:"phonics"),app:app)}
            else {
                refresh(app);activeLevel=course["unlockedLevel"].string.isEmpty ? "Pre-A1":course["unlockedLevel"].string;partition(app)
            }
            initialized=true
        }catch is CancellationError{}catch{if token == key(app){self.error=error.localizedDescription}}
    }
    private func partitionFocus(_ artifact:JSONValue,app:AppModel) {
        let saved=artifact["cards"].array
        let cards=saved.map{card->JSONValue in
            let authored=all.first{$0["id"].string == card["authoredId"].string};guard let authored else{return card}
            return authored.setting("id",card["id"]).setting("authoredId",card["authoredId"]).setting("practiceRole",card["practiceRole"]).setting("isGoal",.bool(goal != nil)).setting("isRepair",.bool(repair != nil))
        }
        activeLevel=cards.first?["cefrLevel"].string ?? "Pre-A1";deck=cards.filter{!artifact["outcomes"][$0["id"].string]["success"].boolean};collected=cards.filter{artifact["outcomes"][$0["id"].string]["success"].boolean};counts = .object([:])
    }
    func refresh(_ app:AppModel){
        guard !focused,let policy else{return}
        let records=app.learner.phonicsDocuments
        counts=(try? policy.run("ph_partition",.object(["cards":.array(all),"records":.array(records)])))?["counts"] ?? .object([:])
        course=(try? policy.run("ph_course",.object(["cards":.array(all),"counts":counts,"courseLevel":.string(baseLevel(app)),"placementLevel":app.learner.placements?[app.learner.target].map{.string($0.level)} ?? .null]))) ?? .null
        if initialized {refreshDeckDefinitions(app)}
    }
    private func refreshDeckDefinitions(_ app:AppModel){
        authored=all.filter{$0["cefrLevel"].string == activeLevel}
        let pendingIDs=Set((app.learner.pendingChanges ?? []).filter{$0.source == .phonicsDeck}.flatMap{$0.phonicsData?["records"].array ?? []}.map{$0["letterId"].string})
        let records=app.learner.phonicsDocuments.filter{!pendingIDs.contains($0["letterId"].string)}
        extras=(try? policy?.run("ph_extraRestore",.object(["target":.string(app.learner.target),"support":.string(app.learner.support),"level":.string(activeLevel),"records":.array(records)])))?.array ?? []
        let extraCounts=(try? policy?.run("ph_partition",.object(["cards":.array(extras),"records":.array(records)])))?["counts"] ?? .object([:])
        for (key,value) in extraCounts.object{counts=counts.setting(key,value)}
    }
    private func partition(_ app:AppModel){
        refreshDeckDefinitions(app);let cards=authored+extras;deck=cards.filter{counts[$0["id"].string].number<=0};collected=cards.filter{counts[$0["id"].string].number>0}
    }
    func select(_ level:String,app:AppModel){guard !focused,!generating,LearningLanguages.levels.contains(level),(try? policy?.run("ph_access",.object(["level":.string(level),"unlockedLevel":course["unlockedLevel"]])))?["allowed"].boolean == true else{return};activeLevel=level;partition(app)}
    func touch(){interacted=true}
    func collect(_ card:JSONValue,app:AppModel){
        guard scope == key(app),let index=deck.firstIndex(where:{$0["id"] == card["id"]}) else{return};interacted=true;deck.remove(at:index);if !collected.contains(where:{$0["id"] == card["id"]}){collected.append(card)}
        if !focused {_=app.learner.collectPhonics(cardID:card["id"].string);app.persist();refresh(app)}
    }
    func newRound(_ app:AppModel)async {
        guard !focused,complete,!generating,let policy else{return};generating=true;error=nil;let token=scope,level=activeLevel
        defer{if scope == token{generating=false}}
        do {
            let pending=(app.learner.pendingChanges ?? []).first{$0.source == .phonicsDeck && $0.target == app.learner.target && $0.level == level && $0.phonicsData?["records"].array.first?["supportLanguage"].string == app.learner.support}
            let records:[JSONValue]
            if let pending {records=pending.phonicsData?["records"].array ?? []}
            else {
                let words=Array(Set((all+extras).map{$0["practiceWord"].string}+app.learner.phonicsDocuments.map{$0["currentWord"].string})).sorted(),args:JSONValue = .object(["target":.string(app.learner.target),"support":.string(app.learner.support),"level":.string(level),"existingWords":.array(words.map(JSONValue.string))])
                let prompt=try policy.run("ph_generatePrompt",args).string,raw=try await PhonicsProvider.native(app.ai).judge(prompt)
                try Task.checkCancellation();guard token == key(app),level == activeLevel else{throw CancellationError()}
                let cards=try policy.run("ph_generateParse",args.setting("raw",.string(raw)).setting("batchId",.number((Date().timeIntervalSince1970*1000).rounded()*1000+Double(Int.random(in:0..<1000))))).array
                records=try cards.map{try policy.run("ph_extraRecord",.object(["card":$0]))};app.learner.storeSupplementalPhonics(records);app.persist()
            }
            await app.sync();try Task.checkCancellation();guard token == key(app),level == activeLevel else{throw CancellationError()}
            let ids=Set(records.map{$0["letterId"].string});guard !(app.learner.pendingChanges ?? []).contains(where:{$0.source == .phonicsDeck && !ids.isDisjoint(with:Set(($0.phonicsData?["records"].array ?? []).map{$0["letterId"].string}))}) else{throw AppError.message(copy("generateDeckError",app:app))}
            refresh(app);refreshDeckDefinitions(app);let cards=extras.filter{ids.contains($0["id"].string)};guard cards.count == 6 else{throw PracticeRecipeFailure.invalidRecipe};deck=cards
        }catch is CancellationError{}catch{if token == key(app){self.error=copy("generateDeckError",app:app)}}
    }
}
