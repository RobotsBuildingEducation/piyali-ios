import Foundation
import Combine
import SwiftUI

@MainActor final class AppModel: ObservableObject {
    @Published var learner = LearnerState() { didSet {captureDailyGoalReward(previous:oldValue);captureCompanionUnlock(previous:oldValue);notifyPracticeObservers();subscription.updatePracticeXP(learner.subscriptionXP);bindAchievementDelivery()} }
    @Published private(set) var companionUnlock:CompanionUnlock?
    @Published private(set) var companionUnlockRevision=0
    private var companionDelivery=CompanionUnlockState()
    var pendingCompanionUnlocks:[CompanionUnlock]{companionDelivery.pending}
    @Published private(set) var companionSaveNotices:[CompanionSaveNotice]=[]
    private var companionSaveAccount=""
    private var companionSaveTasks:[UUID:Task<Void,Never>]=[:]
    private var companionNoticeTasks:[UUID:Task<Void,Never>]=[:]
    let nostrAchievements:NostrAchievementsService
    let achievementRetries:AchievementRetryController
    private let automaticAchievementRecovery:Bool
    private var achievementRetryUpdates:AnyCancellable?
    private var importedAchievementSnapshots:[String:JSONValue]=[:]
    private var achievementApplicationActive=true
    @Published var signedIn = false {didSet{bindAchievementDelivery()}}
    @Published private(set) var achievementUnlock=AchievementUnlockState(catalog:Set(((try? ContentLibrary.load([JSONValue].self,name:"achievement-protocol")) ?? []).map{$0["id"].string}))
    @Published var tutorUnits: [LearningUnit] = []
    @Published var units: [LearningUnit] = []
    @Published var introLibrary:IntroLibrary?
    @Published var cards: [Flashcard] = []
    @Published var phonics: [PhonicsCard] = []
    var curriculumIndex: [String:[String:[String]]] = [:]
    var phonicsLibrary: [String:[PhonicsCard]] = [:]
    var flashcardIndex: [String:[String]] = [:]
    var tutorCurriculumIndex:[String:[String:[String]]] = [:]
    @Published var achievements: [AchievementDefinition] = []
    @Published var error: String?
    @Published private(set) var localStorageUnavailable=false
    @Published var syncStatus = "Saved on this iPhone"
    @Published var loadingContent = false
    @Published private(set) var localPracticeRevision=UUID()
    private var restoringLearner=false
    private var practiceObservers:[UUID:()->Void]=[:]
    func observePractice(owner:UUID,_ update:@escaping()->Void){practiceObservers[owner]=update}
    func stopObservingPractice(owner:UUID){practiceObservers.removeValue(forKey:owner)}
    private func notifyPracticeObservers(){for callback in Array(practiceObservers.values){callback()}}
    @Published var journeyRecording:JourneyRecordingPresentation?
    @Published var plateCourseCompletion:PlateCourseCompletion?
    @Published var dailyGoalReward:DailyGoalReward?
    private var deferredTutorReviews:Set<UUID>=[]
    func deferTutorReview(owner:UUID){deferredTutorReviews.insert(owner);notifyPracticeObservers()}
    func releaseTutorReview(owner:UUID){deferredTutorReviews.remove(owner);notifyPracticeObservers()}
    func dailyGoalBlocked(excluding owner:UUID)->Bool {
        let scope=[identity.npub,learner.target,CalendarDay.key(Date())].joined(separator:":")
        return earnedPracticeOwners.contains{$0.key != owner && $0.value == scope && !deferredTutorReviews.contains($0.key)}
    }
    private func captureDailyGoalReward(previous:LearnerState){
        guard !restoringLearner,signedIn,learner.onboardingComplete,learner.companionProgress?["dailyHasCelebrated"].boolean == true,previous.companionProgress?["dailyHasCelebrated"].boolean != true else{return}
        let oldIDs=Set((previous.pendingChanges ?? []).map(\.id))
        guard (learner.pendingChanges ?? []).contains(where:{!oldIDs.contains($0.id) && $0.amount>0}) else{return}
        dailyGoalReward=DailyGoalReward(account:identity.npub,day:CalendarDay.key(Date()),goal:learner.dailyGoal,health:learner.companionHealth)
    }

    @Published private var earnedPracticeOwners:[UUID:String]=[:]
    var preservingEarnedPractice:Bool {earnedPracticeOwners.values.contains([identity.npub,learner.target,CalendarDay.key(Date())].joined(separator:":"))}
    func retainEarnedPractice(owner:UUID,active:Bool,account:String,target:String,day:String) {
        let value=active && !account.isEmpty ? [account,target,day].joined(separator:":"):nil
        guard earnedPracticeOwners[owner] != value else{return}
        earnedPracticeOwners[owner]=value;notifyPracticeObservers()
    }
    func releaseEarnedPractice(owner:UUID){guard earnedPracticeOwners.removeValue(forKey:owner) != nil else{return};notifyPracticeObservers()}
    func hasEarnedPractice(excluding owner:UUID)->Bool {let scope=[identity.npub,learner.target,CalendarDay.key(Date())].joined(separator:":");return earnedPracticeOwners.contains{$0.key != owner && $0.value == scope}}
    @Published var lessonActivityActive=false
    @Published var activityFooter:ActivityFooterPresentation?
    @Published var activityFooterHeight:CGFloat=0
    @Published var goalCheck:GoalCheckPresentation?
    @Published var flashcardSession:FlashcardSessionController?
    @Published var pendingLessonCompletion:LessonCompletionPresentation?
    @Published var scholarship=ScholarshipPrompt()
    var goalEditorFlush:(id:UUID,flush:()->Void)?
    let progressService:any LearnerProgressService
    let identity = IdentityService()
    let ai = AIService()
    let companionQuestPolicy=try? CompanionQuestPolicy()
    let subscription = SubscriptionService()
    let teams = NostrTeamsService()
    let teamFeed = CommunityFeedService()
    let automaticProgress=AutomaticProgressController()
    private let automaticWallet:WalletService
    private var automaticTipTask:(id:UUID,task:Task<Void,Never>)?
    private var automaticTipUpdates:AnyCancellable?
    private var lastPersisted = LearnerState()
    private var saveTask: Task<Void, Never>?
    private var goalTasks: [String:Task<Void,Error>] = [:]
    private var goalJudging:[String:Task<GoalVerdict,Error>] = [:]
    private var achievementUpdates: AnyCancellable?
    private var achievementDeliveries:AnyCancellable?
    private var contentTask: Task<Void, Never>?
    var introLesson:Lesson? { guard introLibrary?.target == learner.target else { return nil };return introLibrary?.units[learner.level]?.lessons.first }
    var selectedLesson: Lesson? { if learner.needsIntro,!learner.completed.contains(learner.completionKey(IntroTutorial.lessonID)),!LessonAccess.throughPlacement(learner.placements?[learner.target]?.level,level:learner.level) { return introLesson };return units.flatMap(\.lessons).first { !learner.completed.contains(learner.completionKey($0.id)) && learner.lessonAccess($0,units:units).canOpen } }
    var selectedTutorLesson: Lesson? { tutorUnits.flatMap(\.lessons).first { !learner.completed.contains(learner.tutorKey($0.id)) && learner.lessonAccess($0,units:tutorUnits,tutor:true).canOpen } }
    var plateCourses: [PlateCourse] { learner.plateCourses(user:identity.npub) }
    func prepareDailyPlate() {
        guard signedIn, learner.onboardingComplete else { return }
        let prior = learner.questPlans?[learner.target], day = CalendarDay.key(Date())
        if let prior, prior.day == day, !learner.introductoryQuest(day:day) || prior.kinds == DailyPlate.introductory { return }
        learner.preparePlate(user:identity.npub,available:availablePlateKinds)
        if prior != learner.questPlans?[learner.target] { persist() }
    }
    private var availablePlateKinds: [String] {
        var kinds = ["speak","review","conversation"]
        if units.isEmpty || selectedLesson.map({ !learner.completed.contains(learner.completionKey($0.id)) }) == true { kinds.append("learn") }
        if curriculumIndex[learner.target] != nil { kinds.append("phonics") }
        return kinds
    }
    func setPracticeLanguage(_ target: String) {
        guard learner.target != target else { return }
        learner.target = target
        learner.goal = learner.goalIntelligence?[target]?["activeGoal"]["text"].string ?? ""
        learner.level = learner.lessonLevels?[target] ?? learner.placements?[target]?.level ?? "Pre-A1"
        persist(); Task { await reloadContent(); await sync() }
    }
    func recordConversationTurn(_ text: String) {
        guard !text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return }
        learner.award(Int.random(in:1...3),source:.conversation); persist()
    }
    func recordTutorTurn(lesson: Lesson, item: JSONValue, answer: String, verdict: TutorTurnVerdict) -> Int {
        let earned = learner.tutorTurn(lesson:lesson,item:item,verdict:verdict)
        if verdict.mistake && verdict.confidence >= 0.55 {
            learner.captureMemory(mode:"tutor",concept:item["goal"].string,answer:answer,expected:verdict.correction,feedback:verdict.reason,context:lesson.id)
        }
        if earned > 0 || (verdict.mistake && verdict.confidence >= 0.55) {
            learner.history.insert(HistoryEntry(date:Date(),target:learner.target,mode:"Tutor",question:item["goal"].string,answer:answer,feedback:verdict.reason,correct:earned > 0,repairInMemory:earned == 0),at:0)
            learner.history = Array(learner.history.prefix(500))
        }
        _ = learner.completeTutor(lesson); persist(); return earned
    }
    init(automaticWallet:WalletService? = nil,progressService:(any LearnerProgressService)? = nil,nostrAchievements:NostrAchievementsService?=nil,achievementRetries:AchievementRetryController?=nil) {
        let recoveryFixture=AchievementDeliveryUIFixture.retryServices()
        self.nostrAchievements=nostrAchievements ?? recoveryFixture?.1 ?? NostrAchievementsService();self.achievementRetries=achievementRetries ?? recoveryFixture?.0 ?? AchievementRetryController()
        let env=ProcessInfo.processInfo.environment
        automaticAchievementRecovery=achievementRetries != nil || recoveryFixture != nil || (env["PIYALI_OFFLINE_TESTS"] != "1" && env["PIYALI_FIRESTORE_EMULATOR_TESTS"] != "1")
        self.progressService=progressService ?? CompanionSaveUIFixture.progressService() ?? AchievementDeliveryUIFixture.progressService() ?? FirebaseService.shared
        self.automaticWallet=automaticWallet ?? WalletService()
        curriculumIndex = (try? ContentLibrary.load([String:[String:[String]]].self, name: "curriculum-index")) ?? [:]
        flashcardIndex = (try? ContentLibrary.load([String:[String]].self, name: "flashcard-index")) ?? [:]
        tutorCurriculumIndex = (try? ContentLibrary.load([String:[String:[String]]].self,name:"tutor-curriculum-index")) ?? [:]
        achievements = (try? ContentLibrary.load([AchievementDefinition].self, name: "achievements")) ?? []
        achievementUpdates=AchievementSyncService.shared.updates.sink { [weak self] npub,records in
            guard let self,self.signedIn,self.identity.npub == npub else { return }
            let previous=self.learner.achievementRecords
            self.learner.achievementRecords=NostrAchievementCollection.merging([.object(previous ?? [:]),.object(records),self.learner.nostrAchievementRecords ?? .object([:])]).object
            if previous != self.learner.achievementRecords,self.learner.shareNostrAchievements == true { self.scheduleNostrAchievements() }
            try? self.writeLocal()
        }
        self.achievementRetries.configure(cloud:{[weak self] account in guard let self,self.signedIn,self.identity.npub==account else{throw CancellationError()};try await self.performAchievementCloudSync(account:account)},relay:{[weak self] account in guard let self,self.signedIn,self.identity.npub==account else{throw CancellationError()};try await self.performNostrAchievements(publish:self.learner.shareNostrAchievements == true)})
        achievementRetryUpdates=self.achievementRetries.objectWillChange.sink{[weak self] _ in self?.objectWillChange.send()}
        achievementDeliveries=AchievementSyncService.shared.delivery.sink{[weak self] event in self?.receiveConfirmedAchievement(event)}
        signedIn = !identity.npub.isEmpty
        if signedIn { loadLocal(); subscription.bind(identity);subscription.updatePracticeXP(learner.subscriptionXP) }
        bindAchievementDelivery()
        automaticTipUpdates=NotificationCenter.default.publisher(for:.walletAutomaticTipsChanged).sink { [weak self] notification in
            Task { @MainActor in guard let self,self.identity.hex == notification.object as? String else { return };self.scheduleAutomaticTips() }
        }
    }
    private func bindAchievementDelivery(){achievementRetries.setAccount(signedIn ? identity.npub:"");achievementUnlock.setIdentity(signedIn ? identity.npub:"");achievementUnlock.setLanguage(learner.support);bindCompanionDelivery()}
    func receiveConfirmedAchievement(_ event:ConfirmedAchievementDelivery){
        guard signedIn,identity.npub == event.account else{return};bindAchievementDelivery()
        let prior=learner.achievementRecords
        learner.achievementRecords=NostrAchievementCollection.merging([.object(prior ?? [:]),event.records]).object
        if prior != learner.achievementRecords{achievementUnlock.recordsChanged()}
        try? writeLocal()
        for id in event.ids where NostrAchievementCollection.merging([event.records])[id] != .null{achievementUnlock.enqueue(identity:event.account,id:id,test:NostrAchievementCollection.truthy(event.records[id]["test"]))}
    }
    func dismissAchievement(_ key:Int){achievementUnlock.dismiss(key)}
    private func publishCompanionDelivery(){if companionUnlockRevision != companionDelivery.revision{companionUnlockRevision=companionDelivery.revision};if companionUnlock != companionDelivery.visible{companionUnlock=companionDelivery.visible}}
    private func bindCompanionDelivery(){let account=signedIn ? identity.npub:"";companionDelivery.bind(account);bindCompanionSave(account:account);publishCompanionDelivery()}
    private func bindCompanionSave(account:String){
        guard companionSaveAccount != account else{return};companionSaveAccount=account
        companionSaveTasks.values.forEach{$0.cancel()};companionSaveTasks=[:];companionNoticeTasks.values.forEach{$0.cancel()};companionNoticeTasks=[:];companionSaveNotices=[]
    }
    func customizeCompanion(name:String,type:String){
        bindCompanionDelivery();learner.customizeCompanion(name:name,type:type)
        guard let change=learner.pendingSettingsChanges?.last else{return};persist()
        guard signedIn,!identity.npub.isEmpty else{return}
        let account=identity.npub,title=CompanionUnlockUI.copy(learner.support)["saveFailed"].string
        // Every fast write carries its unacknowledged predecessors. A newer
        // receipt therefore cannot commit before the older companion intent,
        // even when an earlier direct request or snapshot resumes late.
        let changes=(learner.pendingSettingsChanges ?? []).filter{Set($0.partial.object.keys) == Set(["dailyGoalPetName","dailyGoalPetType"])}
        companionSaveTasks[change.id]=Task{[weak self] in
            guard let self else{return};defer{self.companionSaveTasks.removeValue(forKey:change.id)}
            do{try await FirebaseIdentityService.shared.ensure(identity);try Task.checkCancellation();guard signedIn,identity.npub == account else{return};for queued in changes{try Task.checkCancellation();guard signedIn,identity.npub == account else{return};guard try await progressService.saveCompanionCustomization(queued,npub:account) else{return}}}
            catch is CancellationError{}
            catch{guard !Task.isCancelled,signedIn,identity.npub == account,companionSaveAccount == account else{return};showCompanionSaveNotice(.init(account:account,title:title,description:error.localizedDescription))}
        }
    }
    private func showCompanionSaveNotice(_ notice:CompanionSaveNotice){
        companionSaveNotices.append(notice);UIAccessibility.post(notification:.announcement,argument:notice.title+". "+notice.description)
        companionNoticeTasks[notice.id]=Task{[weak self] in do{try await Task.sleep(for:.seconds(5));try Task.checkCancellation();self?.dismissCompanionSaveNotice(notice.id)}catch{}}
    }
    func dismissCompanionSaveNotice(_ id:UUID){companionSaveNotices.removeAll{$0.id == id};companionNoticeTasks.removeValue(forKey:id)?.cancel()}

    private var celebratedCompanions:Set<String>{Set(CompanionTypes.ordered.filter{NostrAchievementCollection.truthy(learner.settingsSnapshot["companionUnlocksCelebrated"][$0]) || UserDefaults.standard.bool(forKey:"companionUnlockCelebrated:"+identity.npub+":"+$0)})}
    private func captureCompanionUnlock(previous:LearnerState,acknowledgment:Bool=false){
        guard (!restoringLearner || acknowledgment),signedIn,learner.onboardingComplete,previous.target == learner.target,learner.xp>previous.xp else{return}
        bindCompanionDelivery();let types=CompanionUnlockState.newlyUnlocked(previous:previous.companionLevel,next:learner.companionLevel);guard !types.isEmpty else{return}
        let oldIDs=Set((previous.pendingChanges ?? []).map(\.id)),changes=(learner.pendingChanges ?? []).filter{!oldIDs.contains($0.id)&&$0.amount>0}
        let expects=changes.contains{[PracticeSource.lesson,.speak,.repair].contains($0.source)} || lessonActivityActive
        companionDelivery.enqueue(types:types,level:learner.companionLevel,names:CompanionUnlockUI.copy(learner.support)["names"],celebrated:celebratedCompanions,expectsModal:expects);publishCompanionDelivery()
    }
    func pollCompanionUnlock(now:Double,blocked:Bool)->CompanionUnlock?{
        bindCompanionDelivery();guard signedIn else{return nil}
        let item=companionDelivery.poll(now:now,blocked:blocked,celebrated:celebratedCompanions)
        if let item{UserDefaults.standard.set(true,forKey:"companionUnlockCelebrated:"+item.account+":"+item.type);learner.changeSettings(.object(["companionUnlocksCelebrated":.object([item.type:.bool(true)])]));persist()}
        publishCompanionDelivery();return item
    }
    func companionUnlockDelay(now:Double)->Double{companionDelivery.delay(now:now)}
    func finishCompanionUnlock(_ item:CompanionUnlock,equip:Bool){
        guard signedIn,identity.npub == item.account,companionDelivery.visible?.id == item.id else{return}
        if equip{customizeCompanion(name:learner.companionName,type:item.type)}
        companionDelivery.dismiss(item);publishCompanionDelivery()
    }
    private var localURL: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Piyali", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.appendingPathComponent(identity.npub + ".json")
    }
    private func restoreLearner(_ state:LearnerState){restoringLearner=true;learner=state;restoringLearner=false}
    func loadLocal() {
        restoringLearner=true;defer{restoringLearner=false}
        if let data = try? Data(contentsOf: localURL), let state = try? JSONDecoder().decode(LearnerState.self, from: data) { learner = state } else { learner = LearnerState() }
        learner.migrateCompanionCustomization();learner.rollDay(); syncSettingsAppearance();lastPersisted = learner
    }
    func signIn(nsec: String?,name:String? = nil,support:String? = nil) async {
        flushGoalEditor();goalCheck=nil;automaticProgress.reset()
        achievementRetries.pause();nostrAchievements.cancel()
        teams.cancel(clear:true);teamFeed.cancel(clear:true)
        do {
            if let nsec { try identity.importKey(nsec) } else { try identity.create() }
            await activateIdentity(newProfile:nsec == nil && name != nil ? (name!,support ?? "en") : nil)
        } catch { self.error = error.localizedDescription;resumeAchievementSync() }
    }
    private func activateIdentity(newProfile:(name:String,support:String)? = nil) async {
        automaticTipTask?.task.cancel();automaticTipTask=nil;automaticWallet.cancel(clear:true)
        saveTask?.cancel(); contentTask?.cancel()
        let account = identity.npub
        lessonActivityActive=false;activityFooter=nil;pendingLessonCompletion=nil;scholarship=ScholarshipPrompt()
        loadLocal()
        if let profile=newProfile {
            learner.name=profile.name;learner.support=LearningLanguages.support.contains(profile.support) ? profile.support : "en"
            learner.target=learner.support == "es" ? "en" : "es";learner.goal=""
        }
        signedIn = true; subscription.bind(identity);subscription.updatePracticeXP(learner.subscriptionXP)
        do {
            try await FirebaseIdentityService.shared.ensure(identity)
            if FileManager.default.fileExists(atPath:localURL.path) { await sync() }
            else if let cloud = try await progressService.load(npub:account) {
                guard identity.npub == account else { return }
                restoreLearner(cloud); syncSettingsAppearance();automaticProgress.observe(cloud,identity:identity,locallyAllowed:learner.automaticPostsEnabled); lastPersisted = learner; try writeLocal()
            }
        } catch { syncStatus = "Saved on iPhone; cloud sync pending" }
        await reloadContent(); await subscription.refresh();resumeAchievementSync()
    }
    func signInRemote(_ token:String,onConnected:@MainActor ()->Void = {}) async -> Bool {
        flushGoalEditor();goalCheck=nil;automaticProgress.reset()
        achievementRetries.pause();nostrAchievements.cancel();teams.cancel(clear:true);teamFeed.cancel(clear:true)
        do { try await identity.connect(token);try Task.checkCancellation();onConnected();await activateIdentity();return true }
        catch { if !(error is CancellationError) { self.error=error.localizedDescription };resumeAchievementSync();return false }
    }
    func signOut(){disconnectRemote()}
    func disconnectRemote() {
        flushGoalEditor();goalCheck=nil
        do {
            try writeLocal();automaticProgress.reset();automaticTipTask?.task.cancel();automaticTipTask=nil;automaticWallet.cancel(clear:true);saveTask?.cancel();contentTask?.cancel();achievementRetries.pause();nostrAchievements.cancel();teams.cancel(clear:true);teamFeed.cancel(clear:true)
            journeyRecording?.controller.close();journeyRecording=nil;try identity.disconnect();FirebaseIdentityService.shared.clearSession();signedIn=false;lessonActivityActive=false;activityFooter=nil;pendingLessonCompletion=nil;scholarship=ScholarshipPrompt();subscription.bind(identity);learner=LearnerState()
        } catch { self.error=error.localizedDescription }
    }
    func boot() async { guard signedIn else { return };scheduleAutomaticTips(recovering:true); await reloadContent();resumeAchievementSync(); await sync(); await subscription.refresh();scheduleAutomaticTips() }
    func finishOnboarding(_ draft:OnboardingDraft?=nil) {
        if let draft {learner.completeOnboarding(draft)} else {learner.onboardingComplete=true;learner.preferencesModifiedAt=Date()}
        restoringLearner=true;PlatePracticeFixture.seed(self);MemoryDrawerFixture.seed(self);SettingsFixture.seed(self);restoringLearner=false;persist();Task { await reloadContent() }
    }
    var immersionPreparationKey: String {
        let scope=learner.immersionScope()
        return ([identity.npub]+["dayKey","targetLang","appLanguage","placementAt","cefrLevel","goalId","goalText"].map { scope[$0].string }+[learner.immersionState()["status"].string]).joined(separator:"\u{1f}")
    }
    func prepareImmersion() async throws {
        guard learner.placements?[learner.target] != nil else { return }
        let state=learner,scope=state.immersionScope(),account=identity.npub,status=state.immersionState()["status"].string
        if status == "ready" {
            let checklist=state.immersionState()
            if !checklist["rewarded"].boolean,!checklist["completed"].array.isEmpty,checklist["completed"].array.allSatisfy(\.boolean) {
                learner.applyImmersion(.init(target:state.target,action:.claim,payload:scope.setting("generatedAt",state.immersionBatch?["generatedAt"] ?? .null)));persist()
            }
            return
        }
        var payload=scope.setting("baseBatch",state.immersionBatch ?? .null)
        if status != "goal_removed" {
            let skillLessons=units.flatMap(\.lessons),tutorLessons=tutorUnits.flatMap(\.lessons)
            let skillProgress=JSONValue.object(Dictionary(uniqueKeysWithValues:skillLessons.filter { state.completed.contains(state.completionKey($0.id)) }.map { ($0.id,.object(["status":.string("completed")])) }))
            let tutorProgress=JSONValue.object(Dictionary(uniqueKeysWithValues:tutorLessons.compactMap { lesson -> (String,JSONValue)? in
                let completed=state.completed.contains(state.tutorKey(lesson.id)),started=(state.tutorLessons?[state.tutorKey(lesson.id)]?.earnedXP ?? 0) > 0
                return completed || started ? (lesson.id,.object(["status":.string(completed ? "completed" : "in_progress")])) : nil
            }))
            let skill=DailyImmersion.candidate(lessons:skillLessons,progress:skillProgress,completedCount:state.courseCompletion?[state.target]?["skillTree"]?[state.level] ?? 0,level:state.level,mode:"Lessons")
            let tutor=DailyImmersion.candidate(lessons:tutorLessons,progress:tutorProgress,completedCount:state.courseCompletion?[state.target]?["tutor"]?[state.tutorLevel] ?? 0,level:state.tutorLevel,mode:"Tutor")
            let context=DailyImmersion.context(DailyImmersion.leading(skill,tutor),support:state.support)
            var generated:[JSONValue]
            #if DEBUG
            if ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",ProcessInfo.processInfo.environment["PIYALI_IMMERSION_FIXTURE"] == "1" {
                let titles=["Notice a familiar word","Listen for a useful detail","Describe something nearby","Advance your personal goal"]
                generated=(status == "goal_update" ? [titles[3]] : Array(titles.prefix(state.immersionGoal == .null ? 3 : 4))).map { .object(["title":.string($0),"description":.string("Practice privately at home, then mark this mission complete.")]) }
            } else { generated=try await ai.immersionTasks(learner:state,context:context,onlyGoal:status == "goal_update") }
            #else
            generated=try await ai.immersionTasks(learner:state,context:context,onlyGoal:status == "goal_update")
            #endif
            payload=payload.setting("tasks",.array(generated))
        }
        try Task.checkCancellation();guard identity.npub == account,learner.immersionScope() == scope else { throw CancellationError() }
        learner.applyImmersion(.init(target:state.target,action:.batch,payload:payload));persist()
    }
    func setAchievementApplicationActive(_ active:Bool){achievementApplicationActive=active;if active{resumeAchievementSync()}else{achievementRetries.pause();nostrAchievements.cancel()}}
    func resumeAchievementSync(){guard automaticAchievementRecovery,signedIn,achievementApplicationActive else{return};achievementRetries.setAccount(identity.npub);importedAchievementSnapshots.removeValue(forKey:identity.npub);achievementRetries.resume()}
    func setNostrAchievementSharing(_ enabled:Bool){
        learner.shareNostrAchievements=enabled
        do{try writeLocal()}catch{self.error="Could not save progress: \(error.localizedDescription)"}
        nostrAchievements.cancel();scheduleNostrAchievements()
    }
    private func scheduleNostrAchievements(){guard automaticAchievementRecovery,signedIn,achievementApplicationActive else{return};achievementRetries.setAccount(identity.npub);achievementRetries.schedule(.relay)}
    func syncNostrAchievements(publish:Bool)async throws{
        if automaticAchievementRecovery{
            achievementRetries.setAccount(identity.npub)
            try await achievementRetries.runNow(.relay,operation:{[weak self] account in guard let self,self.signedIn,self.identity.npub==account else{throw CancellationError()};try await self.performNostrAchievements(publish:publish)})
        }else{try await performNostrAchievements(publish:publish)}
    }
    private func performNostrAchievements(publish:Bool)async throws{
        let account=identity.npub
        _ = try await nostrAchievements.synchronize(identity:identity,publish:publish,current:{[weak self] in
            guard let self,self.signedIn,self.identity.npub==account else{return .object([:])}
            return NostrAchievementCollection.merging([self.learner.nostrAchievementRecords ?? .object([:]),.object(self.learner.achievementRecords ?? [:])])
        },persist:{[weak self] records in
            try Task.checkCancellation();guard let self,self.signedIn,self.identity.npub==account else{throw CancellationError()}
            self.learner.nostrAchievementRecords=records
            self.learner.achievementRecords=NostrAchievementCollection.merging([.object(self.learner.achievementRecords ?? [:]),records]).object
            // Keep the memory copy and the visible storage warning if the local
            // profile is full; an authorized remote copy is still recoverable.
            do{try self.writeLocal()}catch{}
            // A cloud outage cannot block an independently authorized relay write.
            if self.automaticAchievementRecovery,!records.object.isEmpty,self.importedAchievementSnapshots[account] != records{self.achievementRetries.schedule(.cloud)}
        })
    }
    private func performAchievementCloudSync(account:String)async throws{
        do{
            try await FirebaseIdentityService.shared.ensure(identity);try Task.checkCancellation();guard signedIn,identity.npub==account else{throw CancellationError()}
            let records=learner.nostrAchievementRecords ?? .object([:])
            if !records.object.isEmpty,importedAchievementSnapshots[account] != records{
                guard let saved=try await progressService.importAchievements(records,npub:account)else{throw AppError.message("Achievement cloud import is pending.")}
                try Task.checkCancellation();guard signedIn,identity.npub==account else{throw CancellationError()}
                learner.achievementRecords=NostrAchievementCollection.merging([.object(learner.achievementRecords ?? [:]),.object(saved),records]).object
                do{try writeLocal()}catch{};importedAchievementSnapshots[account]=records
            }
            let sent=learner
            guard let cloud=try await progressService.save(sent,npub:account)else{throw AppError.message("Cloud progress is pending.")}
            try Task.checkCancellation();guard signedIn,identity.npub==account else{throw CancellationError()}
            try applyAcknowledgment(cloud,sent:sent);syncStatus=synchronizedStatus
        }catch{if signedIn,identity.npub==account,!(error is CancellationError){syncStatus="Saved on iPhone; cloud sync pending"};throw error}
    }
    func reloadContent() async {
        contentTask?.cancel()
        if !lessonLevels.contains(learner.level) { learner.level = lessonLevels.last ?? "Pre-A1" }
        if !cardLevels.contains(learner.flashcardLevel) {
            if learner.flashcardLevels == nil { learner.flashcardLevels = [:] }; learner.flashcardLevels?[learner.target] = cardLevels.last ?? "Pre-A1"
        }
        if learner.tutorLevels?[learner.target] == nil || !tutorLevels.contains(learner.tutorLevel) {
            if learner.tutorLevels == nil { learner.tutorLevels = [:] }; learner.tutorLevels?[learner.target] = tutorLevels.last ?? "Pre-A1"
        }
        let target = learner.target, support = learner.support, level = learner.level, cardLevel = learner.flashcardLevel, tutorLevel = learner.tutorLevel
        loadingContent = true
        let task = Task { [weak self] in
            do {
                let data = try await Task.detached(priority: .userInitiated) { () -> ([LearningUnit], [Flashcard], [PhonicsCard], [String:[PhonicsCard]], [LearningUnit], IntroLibrary) in
                    let curriculum = try ContentLibrary.load([String:[LearningUnit]].self, name: "curriculum-" + target)
                    let cards = try ContentLibrary.load([Flashcard].self, name: "flashcards").filter { $0.cefrLevel == cardLevel }
                    let allPhonics = try ContentLibrary.load([String:[PhonicsCard]].self, name: "phonics")
                    let tutor = try ContentLibrary.load([String:[LearningUnit]].self,name:"tutor-curriculum-"+target)
                    return (curriculum[level] ?? [], cards, allPhonics["\(target):\(support):\(level)"] ?? [], allPhonics, tutor[tutorLevel] ?? [],try ContentLibrary.load(IntroLibrary.self,name:"intro-"+target))
                }.value
                guard !Task.isCancelled else { return }
                self?.units = data.0; self?.cards = data.1; self?.phonics = data.2; self?.phonicsLibrary = data.3; self?.tutorUnits = data.4;self?.introLibrary=data.5
            } catch { if !Task.isCancelled { self?.error = error.localizedDescription } }
            if !Task.isCancelled { self?.loadingContent = false }
        }
        contentTask = task; await task.value
    }
    private func writeLocal() throws {do{try JSONEncoder().encode(learner).write(to:localURL,options:[.atomic,.completeFileProtection]);if localStorageUnavailable{localStorageUnavailable=false}}catch{if !localStorageUnavailable{localStorageUnavailable=true};throw error}}
    func acknowledgeFirstRun(_ acknowledgment:FirstRunAcknowledgment){
        guard signedIn,!identity.npub.isEmpty else{return};let account=identity.npub
        switch acknowledgment{case .paperPencil:learner.paperPencilModalShown=true;case .gettingStarted:learner.gettingStartedModalShown=true}
        // Acknowledgment never prepares/claims a plate, awards XP or flushes unrelated work.
        do{try writeLocal()}catch{self.error="Could not save progress: \(error.localizedDescription)"}
        Task{[weak self] in guard let self else{return};do{try await FirebaseIdentityService.shared.ensure(identity);guard signedIn,identity.npub == account else{return};try await progressService.saveFirstRunAcknowledgment(acknowledgment,npub:account)}catch{guard signedIn,identity.npub == account else{return};syncStatus="Saved on iPhone; cloud sync pending"}}
    }
    func persist() {
        learner.migrateCompanionCustomization()
        if learner.companionName != lastPersisted.companionName || learner.companionType != lastPersisted.companionType{
            let partial=CompanionCustomization.partial(name:learner.companionName,type:learner.companionType,level:learner.companionLevel),last=(learner.pendingSettingsChanges ?? []).last{$0.partial["dailyGoalPetName"] != .null || $0.partial["dailyGoalPetType"] != .null}
            if last?.partial != partial{learner.customizeCompanion(name:learner.companionName,type:learner.companionType)}
        }
        learner.reconcileTutorUnlock(index:tutorCurriculumIndex[learner.target] ?? [:])
        if learner.onboardingComplete && !learner.goal.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && (learner.goalBucket["activeGoal"]["id"].string.isEmpty || learner.goal != learner.goalBucket["activeGoal"]["text"].string) { learner.editGoal(learner.goal) }
        if learner.onboardingComplete { learner.preparePlate(user:identity.npub,available:availablePlateKinds); _ = learner.claimPlate(user:identity.npub) }
        if learner.name != lastPersisted.name || learner.target != lastPersisted.target || learner.support != lastPersisted.support || learner.level != lastPersisted.level || learner.dailyGoal != lastPersisted.dailyGoal || learner.onboardingComplete != lastPersisted.onboardingComplete || learner.flashcardLevels != lastPersisted.flashcardLevels || learner.lessonLevels != lastPersisted.lessonLevels || learner.tutorLevels != lastPersisted.tutorLevels { learner.preferencesModifiedAt = Date() }
        let prior=Set((lastPersisted.pendingChanges ?? []).map(\.id)),newPractice=(learner.pendingChanges ?? []).filter { !prior.contains($0.id) }
        do { try writeLocal(); lastPersisted = learner }
        catch { self.error = "Could not save progress: \(error.localizedDescription)"; return }
        if newPractice.contains(where:{ $0.amount > 0 || $0.source == .repair }) { localPracticeRevision=UUID() }
        scheduleAutomaticTips(changes:newPractice)
        saveTask?.cancel()
        let state = learner, npub = identity.npub
        saveTask = Task {
            do {
                try await Task.sleep(for:.milliseconds(500))
                guard !Task.isCancelled,identity.npub == npub else { return }
                if automaticAchievementRecovery{await sync();return}
                try await FirebaseIdentityService.shared.ensure(identity)
                guard identity.npub == npub, !Task.isCancelled else { return }
                let acknowledged = try await progressService.save(state,npub:npub)
                guard identity.npub == npub, !Task.isCancelled else { return }
                if let acknowledged { try applyAcknowledgment(acknowledged,sent:state); syncStatus = synchronizedStatus }
                else { syncStatus = "Saved on this iPhone" }
            } catch is CancellationError { }
            catch { if identity.npub == npub { syncStatus = "Saved on iPhone; cloud sync pending" } }
        }
    }
    var achievementSyncPending:Bool{achievementRetries.pending || synchronizedStatus != "Synced with Firebase" || syncStatus == "Saved on iPhone; cloud sync pending"}
    private var synchronizedStatus: String {
        (learner.pendingChanges ?? []).isEmpty && (learner.pendingImmersionChanges ?? []).isEmpty && (learner.pendingMemoryChanges ?? []).isEmpty && (learner.pendingSettingsChanges ?? []).isEmpty && (learner.pendingPlacements ?? [:]).isEmpty && (learner.pendingGoalChanges ?? []).isEmpty && (learner.pendingPlateHeadlines ?? [:]).isEmpty && (learner.pendingCompanionQuestDays ?? [:]).isEmpty && (learner.pendingRepairEvidence ?? []).isEmpty ? "Synced with Firebase" : "Saved on iPhone; cloud sync pending"
    }
    private func applyAcknowledgment(_ cloud: LearnerState, sent: LearnerState) throws {
        automaticProgress.observe(cloud,identity:identity,locallyAllowed:learner.automaticPostsEnabled)
        let priorGoalModes=readyGoal?["modeProgress"]
        let target = learner.target, support = learner.support, level = learner.level, cardLevel = learner.flashcardLevel, tutorLevel = learner.tutorLevel
        let priorLearner=learner;restoreLearner(LearnerState.rebased(current:learner,sent:sent,acknowledged:cloud));captureCompanionUnlock(previous:priorLearner,acknowledgment:true);syncSettingsAppearance()
        for change in learner.pendingRepairEvidence ?? [] {
            let bucket=learner.goalIntelligence?[change.target] ?? .object([:])
            if let summary=try? companionQuestPolicy?.run("evidence",.object(["summary":bucket["repairSummary"],"event":change.event,"now":.number(change.date.timeIntervalSince1970*1000)])) {if learner.goalIntelligence == nil {learner.goalIntelligence=[:]};learner.goalIntelligence?[change.target]=bucket.setting("repairSummary",summary)}
        }
        if readyGoal?["modeProgress"] != priorGoalModes {localPracticeRevision=UUID()}
        let claimed = learner.claimPlate(user:identity.npub)
        lastPersisted = learner; try writeLocal()
        if claimed { persist() }
        if target != learner.target || support != learner.support || level != learner.level || cardLevel != learner.flashcardLevel || tutorLevel != learner.tutorLevel { Task { await reloadContent() } }
    }
    func sync() async {
        let state = learner, npub = identity.npub
        do {
            if automaticAchievementRecovery{achievementRetries.setAccount(npub);try await achievementRetries.runNow(.cloud);return}
            try await FirebaseIdentityService.shared.ensure(identity)
            guard identity.npub == npub else { return }
            if let cloud = try await progressService.save(state,npub:npub) {
                guard identity.npub == npub else { return }
                try applyAcknowledgment(cloud,sent:state); syncStatus = synchronizedStatus
            } else { syncStatus = "Saved on this iPhone" }
        } catch is CancellationError {}
        catch { if identity.npub == npub { syncStatus = "Saved on iPhone; cloud sync pending" } }
    }
    func reviewFlashcard(_ card: Flashcard, rating: ReviewRating, correct: Bool?, answer: String = "", now: Date = Date()) {
        if let correct { learner.assess(correct:correct,independent:true,now:now,questionLevel:card.cefrLevel) }
        if correct == false { learner.captureMemory(mode:"flashcard",concept:card.text(learner.target),answer:answer,expected:card.text(learner.target),feedback:"",context:card.id,now:now) }
        learner.review(cardID:card.id,rating:rating,now:now)

        learner.history.insert(HistoryEntry(date:now,target:learner.target,mode:"Flashcard review",question:card.text(learner.support),answer:card.text(learner.target),feedback:"Review: \(rating.rawValue)",correct:correct ?? false,repairInMemory:correct == false),at:0)
        learner.history = Array(learner.history.prefix(500)); persist()
    }
    func record(exercise: Exercise, answer: String, grade: Grade, mode: PracticeMode, lesson: Lesson?, flashcardID: String? = nil) {
        learner.history.insert(HistoryEntry(date: Date(), target: learner.target, mode: mode.rawValue, question: exercise.question, answer: answer, feedback: grade.feedback, correct: grade.correct,repairInMemory:!grade.correct), at: 0)
        learner.history = Array(learner.history.prefix(500))
        learner.assess(correct: grade.correct, independent: exercise.choices.isEmpty, questionLevel:lesson?.isGoal == true ? lesson?.cefrLevel : nil)
        if !grade.correct {
            let source = flashcardID != nil ? "flashcard" : mode == .speaking || mode == .stories ? "story" : mode.rawValue.lowercased()
            learner.captureMemory(mode:source,concept:exercise.question,answer:answer,expected:grade.correctedAnswer,feedback:grade.feedback,context:lesson?.id ?? "")
        }
        if let flashcardID { learner.review(cardID:flashcardID,rating:grade.correct ? .good : .again) }
        if grade.correct {
            if flashcardID == nil { learner.award(10,lesson:lesson) }
            if mode == .speaking || mode == .conversation {
                if learner.journeyDays == nil { learner.journeyDays = [] }
                learner.journeyDays?.insert(learner.target + ":" + learner.dailyKey)
            }
            if let lesson { learner.practicedModes.insert(learner.modeKey(lesson.id, mode.rawValue)) }
        }
        persist()
    }
    var readyGoal: JSONValue? {
        guard !(learner.pendingGoalChanges ?? []).contains(where:{ $0.target == learner.target && [.edit,.blueprint,.bundleUpgrade].contains($0.action) }) else { return nil }
        return GoalPractice.today(learner.confirmedGoalBucket,day:CalendarDay.key(Date()))
    }
    var goalPreparationKey:String {[identity.npub,learner.target,learner.support,learner.goalBucket["activeGoal"]["id"].string,learner.goal,learner.goalBucket["activeGoal"]["status"].string,CalendarDay.key(Date()),String(subscription.hasAccess)].joined(separator:"\u{1f}")}
    func prepareGoal() async throws {
        guard subscription.hasAccess, !learner.goal.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return }
        if learner.goalBucket["activeGoal"]["id"].string.isEmpty { learner.editGoal(learner.goal); persist() }
        let key = goalPreparationKey
        if let task = goalTasks[key] { return try await task.value }
        let task = Task { @MainActor in try await self.buildDailyGoal() }
        goalTasks[key] = task
        defer { goalTasks.removeValue(forKey:key) }
        try await task.value
    }
    func setGoalStatus(_ status: String) { learner.editGoal(learner.goal,status:status); persist() }
    func goalArtifact(_ blueprint: JSONValue, mode: String) -> JSONValue {
        let key = GoalPractice.artifactKey(target:learner.target,day:blueprint["dayKey"].string,mode:mode,goalID:blueprint["goalId"].string)
        let artifact = learner.goalArtifacts?[key] ?? .object([:])
        guard mode == "phonics", !artifact["cards"].array.isEmpty else { return artifact }
        let authored = LearningLanguages.levels.flatMap { phonicsLibrary["\(learner.target):\(learner.support):\($0)"] ?? [] }
        let cards = artifact["cards"].array.compactMap { saved -> JSONValue? in
            guard let source = authored.first(where:{ $0.id == saved["authoredId"].string }), let data = try? JSONEncoder().encode(source), let localized = try? JSONDecoder().decode(JSONValue.self,from:data) else { return nil }
            return localized.setting("id",saved["id"]).setting("authoredId",saved["authoredId"]).setting("practiceRole",saved["practiceRole"]).setting("isGoal",.bool(true))
        }
        return artifact.setting("cards",.array(cards)).setting("requiresTutor",.bool(cards.isEmpty))
    }
    func prepareGoalDeck(_ blueprint: JSONValue, mode: String) async throws {
        guard goalIsCurrent(blueprint), subscription.hasAccess else { return }
        let account = identity.npub, target = learner.target, state = learner
        if !goalArtifact(blueprint,mode:mode)["cards"].array.isEmpty || goalArtifact(blueprint,mode:mode)["requiresTutor"].boolean { return }
        var cards: [JSONValue] = []
        if mode == "flashcards" {
            var entries: [JSONValue] = []
            do {
                let raw = try await ai.structured(JSONValue.self,prompt:"Generate exactly three recall cards preparing this goal. Goal data: \(blueprint.json). Use current Elo \(state.rating) and prior evidence \(state.goalBucket["goalProgress"].json) to adapt recall challenge and support. Needed language may exceed CEFR with simple cues in \(state.support). Return JSON array [{\"target\":\"answer in \(target)\",\"support\":\"translation cue in \(state.support)\"}].")
                entries = raw.array.filter { !$0["target"].string.isEmpty && !$0["support"].string.isEmpty }
            } catch { /* Blueprint chunks remain usable. */ }
            if entries.isEmpty { entries = GoalPractice.list(blueprint["targetLanguage"]).map { .object(["target":.string($0),"support":blueprint["objective"]]) } }
            if !entries.isEmpty {
                cards = (0..<3).map { index in
                    let entry = entries[index % entries.count]
                    var concept: [String:JSONValue] = [target:entry["target"]]
                    concept[state.support == target ? "iosCue" : state.support] = entry["support"]
                    return .object(["id":.string("goal-\(blueprint["goalId"].string)-\(blueprint["dayKey"].string)-c\(index)"),"isGoal":.bool(true),"category":.string("goal"),"type":.string("phrase"),"cefrLevel":blueprint["cefrLevel"],"concept":.object(concept)])
                }
            }
        } else if mode == "phonics" {
            let all = phonicsLibrary.isEmpty ? try ContentLibrary.load([String:[PhonicsCard]].self,name:"phonics") : phonicsLibrary
            let requested = all["\(target):\(state.support):\(blueprint["cefrLevel"].string)"] ?? []
            let chunks = GoalPractice.list(blueprint["targetLanguage"])
            let levels = LearningLanguages.levels
            let first = requested.first { $0.practiceWord == chunks.first } ?? levels.flatMap { all["\(target):\(state.support):\($0)"] ?? [] }.first { $0.practiceWord == chunks.first }
            if let first, let level = levels.first(where:{ (all["\(target):\(state.support):\($0)"] ?? []).contains(where:{ $0.id == first.id }) }) {
                let siblings = all["\(target):\(state.support):\(level)"] ?? []
                let selected = Array(([first] + siblings.filter { $0.id != first.id }).prefix(2))
                cards = try selected.enumerated().map { index,card in
                    var fields = try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(card))
                    fields = fields.setting("authoredId",.string(card.id)).setting("id",.string("focused-" + GoalPractice.artifactKey(target:target,day:blueprint["dayKey"].string,mode:mode,goalID:blueprint["goalId"].string) + "-\(index)"))
                    return fields.setting("practiceRole",.string(index == 0 ? "original" : "transfer")).setting("isGoal",.bool(true))
                }
            }
        }
        guard identity.npub == account, learner.target == target, goalIsCurrent(blueprint) else { return }
        let payload = blueprint.setting("mode",.string(mode)).setting("cards",.array(cards)).setting("requiresTutor",.bool(cards.isEmpty))
        learner.applyGoal(GoalChange(action:.artifact,target:target,payload:payload)); persist(); await sync()
        guard identity.npub == account, learner.target == target else { return }
        guard !(learner.pendingGoalChanges ?? []).contains(where:{ $0.target == target && $0.action == .artifact }) else { throw AppError.message("Reconnect to save this practice deck across devices.") }
    }
    func recordGoalPreparation(_ blueprint: JSONValue, mode: String, card: JSONValue, success: Bool, answer: String, assess:Bool = true) {
        guard goalIsCurrent(blueprint) else { return }
        guard !goalArtifact(blueprint,mode:mode)["outcomes"][card["id"].string]["success"].boolean else{return}
        let item = mode == "phonics" ? card["practiceWord"].string : card["concept"][learner.target].string
        let support = mode == "phonics" ? "modeled" : "prompted"
        let payload = blueprint.setting("mode",.string(mode)).setting("cardID",card["id"]).setting("success",.bool(success)).setting("support",.string(support)).setting("item",.string(item)).setting("transfer",.bool(card["practiceRole"].string == "transfer"))
        learner.applyGoal(GoalChange(action:.outcome,target:learner.target,payload:payload))
        if assess {learner.assess(correct:success,independent:false,questionLevel:card["cefrLevel"].string.isEmpty ? blueprint["cefrLevel"].string:card["cefrLevel"].string,support:mode == "phonics" ? "modeled":"prompted")}
        let observation = "\(success ? "Correct" : "Unsuccessful") \(mode == "phonics" ? "modeled practice of" : "recall of") \(item): \(answer). Preparation, not independent production."
        let evidence = payload.setting("target",.string(item)).setting("observation",.string(observation)).setting("domain",.string(mode == "phonics" ? "pronunciation" : "recall")).setting("expectedAnswer",.string(item))
        learner.applyGoal(GoalChange(action:.evidence,target:learner.target,payload:evidence))
        if mode == "phonics" || mode == "flashcards" {
            let artifact = goalArtifact(blueprint,mode:mode), required = mode == "phonics" ? Array(artifact["cards"].array.prefix(2)):artifact["cards"].array
            if required.count == (mode == "phonics" ? 2:3) && required.allSatisfy({ artifact["outcomes"][$0["id"].string]["success"].boolean }) {
                recordGoalAttempt(blueprint,mode:mode,success:true,support:mode == "phonics" ? "modeled":"prompted",observation:required.map{mode == "phonics" ? $0["practiceWord"].string+" pronounced successfully after a model":$0["concept"][learner.target].string+" recalled correctly; recall only, not independent production"}.joined(separator:"; "),domain:mode == "phonics" ? "pronunciation":"recall")
            }
        }
        persist()
    }
    func goalIsCurrent(_ blueprint: JSONValue) -> Bool {
        guard let daily = readyGoal else { return false }
        return daily["blueprint"]["goalId"] == blueprint["goalId"] && daily["blueprint"]["dayKey"] == blueprint["dayKey"] && blueprint["lang"].string == learner.target
    }
    func recordGoalAttempt(_ blueprint: JSONValue, mode: String, success: Bool, support: String, observation: String, domain: String = "production") {
        guard goalIsCurrent(blueprint) else { return }
        let payload: JSONValue = .object(["goalId":blueprint["goalId"],"dayKey":blueprint["dayKey"],"cefrLevel":blueprint["cefrLevel"],"mode":.string(mode),"success":.bool(success),"support":.string(support),"observation":.string(observation),"domain":.string(domain),"priorModeProgress":learner.goalBucket["dailyGoal"]["modeProgress"][mode]])
        learner.applyGoal(GoalChange(action:.attempt,target:learner.target,payload:payload)); persist()
    }
    func checkGoal(_ blueprint: JSONValue, mode: String, response: String, context: String) async throws -> GoalVerdict {
        guard !response.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else{return GoalVerdict(success:false,support:"prompted",feedback:"Try a response first.",observation:"")}
        let scope=goalCourseScope,key=[scope.account,scope.target,scope.support,scope.goalID,scope.day,mode,response].joined(separator:"\u{1f}")
        if let pending=goalJudging[key] {return try await pending.value}
        let task=Task { @MainActor in try await self.performGoalCheck(blueprint,mode:mode,response:response,context:context) }
        goalJudging[key]=task;defer{goalJudging.removeValue(forKey:key)}
        return try await task.value
    }
    private func performGoalCheck(_ blueprint:JSONValue,mode:String,response:String,context:String)async throws->GoalVerdict {
        guard subscription.hasAccess, goalIsCurrent(blueprint) else { throw AppError.message("This daily task has changed. Open today's goal again.") }
        if (readyGoal?["modeProgress"][mode].number ?? 0) >= Double(GoalPractice.targets[mode] ?? 1) {
            return GoalVerdict(success:true,support:"prompted",feedback:"This part of today’s bundle is already complete. Continue with the next task.",observation:"Previously recorded goal evidence")
        }
        let scope=goalCourseScope, state = learner
        let verdict = try await ai.goalVerdict(blueprint:blueprint,response:response,context:context,support:state.support)
        guard goalCourseScope == scope, goalIsCurrent(blueprint), !verdict.observation.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { throw AppError.message("This check is no longer current. Open today's goal again.") }
        let worth=blueprint["worth"] == .null ? try GeneratedQuestionWorth.fallback(level:blueprint["cefrLevel"].string,learner:state,recipes:PracticeRecipes()):blueprint["worth"]
        learner.assess(correct:verdict.success,independent:["independent","transferred"].contains(verdict.support),questionLevel:blueprint["cefrLevel"].string,worth:worth,concept:blueprint["objective"].string,mode:mode,support:verdict.support)
        recordGoalAttempt(blueprint,mode:mode,success:verdict.success,support:verdict.support,observation:verdict.observation,domain:mode == "phonics" ? "pronunciation":"production")
        await sync();try Task.checkCancellation()
        guard goalCourseScope == scope,goalIsCurrent(blueprint) else{throw CancellationError()}
        if verdict.success,(readyGoal?["modeProgress"][mode].number ?? 0) < Double(GoalPractice.targets[mode] ?? 1) {throw AppError.message("The check is unavailable. Your practice is saved; try the check again.")}
        return verdict
    }
    var tutorLevels: [String] { learner.availableTutorLevels(index:tutorCurriculumIndex[learner.target] ?? [:],lessons:lessonLevels,flashcards:cardLevels) }
    func setTutorLevel(_ level: String) {
        guard tutorLevels.contains(level) else { return }
        if learner.tutorLevels == nil { learner.tutorLevels = [:] }; learner.tutorLevels?[learner.target] = level
        persist(); Task { await reloadContent() }
    }
    var lessonLevels: [String] { learner.unlockedLevels(mode:"skillTree",index:IntroTutorial.lessonCourseIndex(curriculumIndex[learner.target] ?? [:])) }
    var cardLevels: [String] { learner.unlockedLevels(mode:"flashcards",index:flashcardIndex) }
    func setLessonLevel(_ level: String) {
        guard lessonLevels.contains(level) else { return }; learner.level = level
        if learner.lessonLevels == nil { learner.lessonLevels = [:] }; learner.lessonLevels?[learner.target] = level; persist()
    }
    func setCardLevel(_ level: String) {
        guard cardLevels.contains(level) else { return }
        if learner.flashcardLevels == nil { learner.flashcardLevels = [:] }; learner.flashcardLevels?[learner.target] = level
        persist(); Task { await reloadContent() }
    }
    func place(_ placement: Placement) { learner.place(placement); persist(); Task { await reloadContent() } }
    func canComplete(_ lesson: Lesson) -> Bool {
        if lesson.isGoal == true {guard let bp=lesson.goalBlueprint,goalIsCurrent(bp) else{return false};return GoalLessonProgress.ready(learner.goalBucket,goalID:bp["goalId"].string,day:bp["dayKey"].string,lessonID:lesson.id,target:lesson.xpReward)}
        if lesson.isRepair == true {return learner.lessonWork?[learner.completionKey(lesson.id)]?.ready(goal:lesson.xpReward) == true}
        if lesson.isFinalQuiz == true { return learner.quizPassed(lesson) }
        guard !lesson.modes.contains("game") else { return false }
        if CurriculumLessonProgress.isCurriculumID(lesson.id) { return learner.lessonWork?[learner.completionKey(lesson.id)]?.ready(goal:lesson.xpReward) == true }
        return Self.modes(for: lesson).allSatisfy { learner.practicedModes.contains(learner.modeKey(lesson.id, $0.rawValue)) }
    }
    func beginLesson(_ lesson:Lesson) { if learner.beginLessonWork(lesson) { persist() } }
    func complete(_ lesson: Lesson) {
        guard canComplete(lesson),lesson.isGoal != true,!lesson.id.hasPrefix("goal-") else { return }
        if lesson.isRepair == true {
            guard let step=currentRepairStep,lesson.id == step.id else{return}
            finishRepair(step,observation:"Completed a short mixed lesson on: "+step.item["originalConcept"].string)
        } else { _ = learner.complete(lesson); persist() }
    }
    static func modes(for lesson: Lesson) -> [PracticeMode] {
        let map: [String: PracticeMode] = ["vocabulary":.vocabulary,"flashcards":.vocabulary,"grammar":.grammar,"reading":.reading,"listening":.listening,"repeat":.listening,"speaking":.speaking,"speak":.speaking,"stories":.stories,"story":.stories,"conversation":.conversation,"conversations":.conversation,"tutor":.conversation,"realtime":.conversation,"game":.game,"translate":.vocabulary]
        let mapped = lesson.modes.compactMap { map[$0.lowercased()] }
        return mapped.isEmpty ? [.vocabulary,.grammar,.reading] : Array(Set(mapped)).sorted { $0.rawValue < $1.rawValue }
    }
}

extension AppModel {
    func scheduleAutomaticTips(changes:[PracticeChange] = [],recovering:Bool = false) {
        guard signedIn,!identity.hex.isEmpty else { return }
        do { try automaticWallet.adoptSourceSupport(identity:identity,recipient:learner.settingsSnapshot["identity"].string);try automaticWallet.enqueueAutomaticTips(recovering ? learner.pendingChanges ?? [] : changes,identity:identity,resuming:recovering) } catch { return }
        guard automaticTipTask == nil,automaticWallet.hasAutomaticWork(identity:identity) else { return }
        let id=UUID(),account=identity.hex
        let task=Task { [weak self] in
            guard let self else { return };var normal=false
            defer {
                if self.automaticTipTask?.id == id { self.automaticTipTask=nil
                    if normal,self.signedIn,self.identity.hex == account,self.automaticWallet.hasAutomaticWork(identity:self.identity) { self.scheduleAutomaticTips() }
                }
            }
            do {
                while !Task.isCancelled,self.signedIn,self.identity.hex == account {
                    guard try await self.automaticWallet.processAutomaticTip(identity:self.identity) else { normal=true;return }
                    try await Task.sleep(for:.milliseconds(100))
                }
            } catch { /* Durable intent and monetary recovery data remain available for the next resume. */ }
        }
        automaticTipTask=(id,task)
    }
}

extension AppModel {
    var preservingScholarship:Bool{let scope=ScholarshipPrompt.Scope(account:identity.npub,target:learner.target);return !scholarshipSeen && (scholarship.pending == scope || scholarship.visible == scope)}
    var scholarshipSeen:Bool{learner.settingsSnapshot["tutorialBitcoinModalShown"].boolean}
    func requestScholarship(){scholarship.request(account:identity.npub,target:learner.target,seen:scholarshipSeen)}
    func dismissScholarship(){guard scholarship.dismiss(account:identity.npub,target:learner.target) else{return};updateSettings(.object(["tutorialBitcoinModalShown":.bool(true)]))}
}
