import Foundation
import Combine
import SwiftUI

@MainActor final class AppModel: ObservableObject {
    @Published var learner = LearnerState() { didSet { subscription.updatePracticeXP(learner.subscriptionXP) } }
    let nostrAchievements=NostrAchievementsService()
    private var nostrSyncTask: Task<Void,Never>?
    @Published var signedIn = false
    @Published var tutorUnits: [LearningUnit] = []
    @Published var units: [LearningUnit] = []
    @Published var introLibrary:IntroLibrary?
    @Published var cards: [Flashcard] = []
    @Published var phonics: [PhonicsCard] = []
    var curriculumIndex: [String:[String:[String]]] = [:]
    private var phonicsLibrary: [String:[PhonicsCard]] = [:]
    var flashcardIndex: [String:[String]] = [:]
    @Published var achievements: [AchievementDefinition] = []
    @Published var error: String?
    @Published var syncStatus = "Saved on this iPhone"
    @Published var loadingContent = false
    @Published private(set) var localPracticeRevision=UUID()
    let identity = IdentityService()
    let ai = AIService()
    let subscription = SubscriptionService()
    let teams = NostrTeamsService()
    private let automaticWallet:WalletService
    private var automaticTipTask:(id:UUID,task:Task<Void,Never>)?
    private var automaticTipUpdates:AnyCancellable?
    private var lastPersisted = LearnerState()
    private var saveTask: Task<Void, Never>?
    private var goalTasks: [String:Task<Void,Error>] = [:]
    private var achievementUpdates: AnyCancellable?
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
    init(automaticWallet:WalletService? = nil) {
        self.automaticWallet=automaticWallet ?? WalletService()
        curriculumIndex = (try? ContentLibrary.load([String:[String:[String]]].self, name: "curriculum-index")) ?? [:]
        flashcardIndex = (try? ContentLibrary.load([String:[String]].self, name: "flashcard-index")) ?? [:]
        achievements = (try? ContentLibrary.load([AchievementDefinition].self, name: "achievements")) ?? []
        achievementUpdates=AchievementSyncService.shared.updates.sink { [weak self] npub,records in
            guard let self,self.signedIn,self.identity.npub == npub else { return }
            let previous=self.learner.achievementRecords
            self.learner.achievementRecords=NostrAchievementCollection.merging([.object(records),self.learner.nostrAchievementRecords ?? .object([:])]).object
            if previous != self.learner.achievementRecords,self.learner.shareNostrAchievements == true { self.scheduleNostrAchievements() }
            try? self.writeLocal()
        }
        signedIn = !identity.npub.isEmpty
        if signedIn { loadLocal(); subscription.bind(identity);subscription.updatePracticeXP(learner.subscriptionXP) }
        automaticTipUpdates=NotificationCenter.default.publisher(for:.walletAutomaticTipsChanged).sink { [weak self] notification in
            Task { @MainActor in guard let self,self.identity.hex == notification.object as? String else { return };self.scheduleAutomaticTips() }
        }
    }
    private var localURL: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Piyali", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.appendingPathComponent(identity.npub + ".json")
    }
    func loadLocal() {
        if let data = try? Data(contentsOf: localURL), let state = try? JSONDecoder().decode(LearnerState.self, from: data) { learner = state } else { learner = LearnerState() }
        learner.rollDay(); lastPersisted = learner
    }
    func signIn(nsec: String?,name:String? = nil,support:String? = nil) async {
        nostrSyncTask?.cancel();nostrAchievements.cancel()
        teams.cancel(clear:true)
        do {
            if let nsec { try identity.importKey(nsec) } else { try identity.create() }
            await activateIdentity(newProfile:nsec == nil && name != nil ? (name!,support ?? "en") : nil)
        } catch { self.error = error.localizedDescription }
    }
    private func activateIdentity(newProfile:(name:String,support:String)? = nil) async {
        automaticTipTask?.task.cancel();automaticTipTask=nil;automaticWallet.cancel(clear:true)
        saveTask?.cancel(); contentTask?.cancel()
        let account = identity.npub
        loadLocal()
        if let profile=newProfile {
            learner.name=profile.name;learner.support=LearningLanguages.support.contains(profile.support) ? profile.support : "en"
            learner.target=learner.support == "es" ? "en" : "es";learner.goal=""
        }
        signedIn = true; subscription.bind(identity);subscription.updatePracticeXP(learner.subscriptionXP)
        do {
            try await FirebaseIdentityService.shared.ensure(identity)
            if FileManager.default.fileExists(atPath:localURL.path) { await sync() }
            else if let cloud = try await FirebaseService.shared.load(npub:account) {
                guard identity.npub == account else { return }
                learner = cloud; lastPersisted = learner; try writeLocal()
            }
        } catch { syncStatus = "Saved on iPhone; cloud sync pending" }
        await reloadContent(); await subscription.refresh(); scheduleNostrAchievements()
    }
    func signInRemote(_ token:String,onConnected:@MainActor ()->Void = {}) async -> Bool {
        nostrSyncTask?.cancel();nostrAchievements.cancel();teams.cancel(clear:true)
        do { try await identity.connect(token);try Task.checkCancellation();onConnected();await activateIdentity();return true }
        catch { if !(error is CancellationError) { self.error=error.localizedDescription };return false }
    }
    func disconnectRemote() {
        do {
            try writeLocal();automaticTipTask?.task.cancel();automaticTipTask=nil;automaticWallet.cancel(clear:true);saveTask?.cancel();contentTask?.cancel();nostrSyncTask?.cancel();nostrAchievements.cancel();teams.cancel(clear:true)
            try identity.disconnect();FirebaseIdentityService.shared.clearSession();signedIn=false;subscription.bind(identity);learner=LearnerState()
        } catch { self.error=error.localizedDescription }
    }
    func boot() async { guard signedIn else { return };scheduleAutomaticTips(recovering:true); await reloadContent(); await sync(); await subscription.refresh(); scheduleNostrAchievements();scheduleAutomaticTips() }
    func finishOnboarding() {
        learner.onboardingComplete=true;learner.preferencesModifiedAt=Date();persist();Task { await reloadContent() }
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
    func setNostrAchievementSharing(_ enabled: Bool) {
        learner.shareNostrAchievements=enabled
        try? writeLocal()
        if enabled { scheduleNostrAchievements() } else { nostrSyncTask?.cancel();nostrAchievements.cancel() }
    }
    private func scheduleNostrAchievements() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1" || ProcessInfo.processInfo.environment["PIYALI_FIRESTORE_EMULATOR_TESTS"] == "1" { return }
        #endif
        guard signedIn else { return }
        nostrSyncTask?.cancel()
        let account=identity.npub
        nostrSyncTask=Task { @MainActor [weak self] in
            do { try await Task.sleep(for:.milliseconds(500));guard let self,self.identity.npub == account else { return };try await self.syncNostrAchievements(publish:self.learner.shareNostrAchievements == true) } catch { }
        }
    }
    func syncNostrAchievements(publish: Bool) async throws {
        let account=identity.npub
        _ = try await nostrAchievements.synchronize(identity:identity,publish:publish,current:{ [weak self] in
            guard let self,self.identity.npub == account else { return .object([:]) }
            return NostrAchievementCollection.merging([self.learner.nostrAchievementRecords ?? .object([:]),.object(self.learner.achievementRecords ?? [:])])
        },persist:{ [weak self] records in
            guard let self,self.identity.npub == account else { throw CancellationError() }
            self.learner.nostrAchievementRecords=records
            self.learner.achievementRecords=NostrAchievementCollection.merging([.object(self.learner.achievementRecords ?? [:]),records]).object
            try self.writeLocal()
            if FirebaseService.shared.configured {
                try await FirebaseIdentityService.shared.ensure(self.identity)
                guard self.identity.npub == account else { throw CancellationError() }
                if let saved=try await FirebaseService.shared.importAchievements(records,npub:account) {
                    guard self.identity.npub == account else { throw CancellationError() }
                    self.learner.achievementRecords=NostrAchievementCollection.merging([.object(saved),records]).object;try self.writeLocal()
                }
            }
        })
    }
    func reloadContent() async {
        contentTask?.cancel()
        if !lessonLevels.contains(learner.level) { learner.level = lessonLevels.last ?? "Pre-A1" }
        if !cardLevels.contains(learner.flashcardLevel) {
            if learner.flashcardLevels == nil { learner.flashcardLevels = [:] }; learner.flashcardLevels?[learner.target] = cardLevels.last ?? "Pre-A1"
        }
        if !tutorLevels.contains(learner.tutorLevel) {
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
                    return (curriculum[level] ?? [], cards, allPhonics["\(target):\(support):\(level)"] ?? [], allPhonics, curriculum[tutorLevel] ?? [],try ContentLibrary.load(IntroLibrary.self,name:"intro-"+target))
                }.value
                guard !Task.isCancelled else { return }
                self?.units = data.0; self?.cards = data.1; self?.phonics = data.2; self?.phonicsLibrary = data.3; self?.tutorUnits = data.4;self?.introLibrary=data.5
            } catch { if !Task.isCancelled { self?.error = error.localizedDescription } }
            if !Task.isCancelled { self?.loadingContent = false }
        }
        contentTask = task; await task.value
    }
    private func writeLocal() throws { try JSONEncoder().encode(learner).write(to:localURL,options:[.atomic,.completeFileProtection]) }
    func persist() {
        if learner.onboardingComplete && !learner.goal.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && (learner.goalBucket["activeGoal"]["id"].string.isEmpty || learner.goal != learner.goalBucket["activeGoal"]["text"].string) { learner.editGoal(learner.goal) }
        if learner.onboardingComplete { learner.preparePlate(user:identity.npub,available:availablePlateKinds); _ = learner.claimPlate(user:identity.npub) }
        if learner.name != lastPersisted.name || learner.target != lastPersisted.target || learner.support != lastPersisted.support || learner.level != lastPersisted.level || learner.dailyGoal != lastPersisted.dailyGoal || learner.companionName != lastPersisted.companionName || learner.companionType != lastPersisted.companionType || learner.onboardingComplete != lastPersisted.onboardingComplete || learner.flashcardLevels != lastPersisted.flashcardLevels || learner.lessonLevels != lastPersisted.lessonLevels || learner.tutorLevels != lastPersisted.tutorLevels { learner.preferencesModifiedAt = Date() }
        let prior=Set((lastPersisted.pendingChanges ?? []).map(\.id)),newPractice=(learner.pendingChanges ?? []).filter { !prior.contains($0.id) }
        do { try writeLocal(); lastPersisted = learner }
        catch { self.error = "Could not save progress: \(error.localizedDescription)"; return }
        if newPractice.contains(where:{ $0.amount > 0 }) { localPracticeRevision=UUID() }
        scheduleAutomaticTips(changes:newPractice)
        saveTask?.cancel()
        let state = learner, npub = identity.npub
        saveTask = Task {
            do {
                try await Task.sleep(for:.milliseconds(500))
                guard !Task.isCancelled else { return }
                try await FirebaseIdentityService.shared.ensure(identity)
                guard identity.npub == npub, !Task.isCancelled else { return }
                let acknowledged = try await FirebaseService.shared.save(state,npub:npub)
                guard identity.npub == npub, !Task.isCancelled else { return }
                if let acknowledged { try applyAcknowledgment(acknowledged,sent:state); syncStatus = synchronizedStatus }
                else { syncStatus = "Saved on this iPhone" }
            } catch is CancellationError { }
            catch { if identity.npub == npub { syncStatus = "Saved on iPhone; cloud sync pending" } }
        }
    }
    private var synchronizedStatus: String {
        (learner.pendingChanges ?? []).isEmpty && (learner.pendingImmersionChanges ?? []).isEmpty && (learner.pendingMemoryChanges ?? []).isEmpty && (learner.pendingPlacements ?? [:]).isEmpty && (learner.pendingGoalChanges ?? []).isEmpty ? "Synced with Firebase" : "Saved on iPhone; cloud sync pending"
    }
    private func applyAcknowledgment(_ cloud: LearnerState, sent: LearnerState) throws {
        let target = learner.target, support = learner.support, level = learner.level, cardLevel = learner.flashcardLevel, tutorLevel = learner.tutorLevel
        learner = LearnerState.rebased(current:learner,sent:sent,acknowledged:cloud)
        let claimed = learner.claimPlate(user:identity.npub)
        lastPersisted = learner; try writeLocal()
        if claimed { persist() }
        if target != learner.target || support != learner.support || level != learner.level || cardLevel != learner.flashcardLevel || tutorLevel != learner.tutorLevel { Task { await reloadContent() } }
    }
    func sync() async {
        let state = learner, npub = identity.npub
        do {
            try await FirebaseIdentityService.shared.ensure(identity)
            guard identity.npub == npub else { return }
            if let cloud = try await FirebaseService.shared.save(state,npub:npub) {
                guard identity.npub == npub else { return }
                try applyAcknowledgment(cloud,sent:state); syncStatus = synchronizedStatus
            } else { syncStatus = "Saved on this iPhone" }
        } catch { if identity.npub == npub { syncStatus = "Saved on iPhone; cloud sync pending" } }
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
        learner.assess(correct: grade.correct, independent: exercise.choices.isEmpty, questionLevel:lesson?.id.hasPrefix("goal-") == true ? lesson?.agenda["cefrLevel"].string : nil)
        if !grade.correct {
            let source = flashcardID != nil ? "flashcard" : mode == .speaking || mode == .stories ? "story" : mode.rawValue.lowercased()
            learner.captureMemory(mode:source,concept:exercise.question,answer:answer,expected:grade.correctedAnswer,feedback:grade.feedback,context:lesson?.id ?? "")
        }
        if let flashcardID { learner.review(cardID:flashcardID,rating:grade.correct ? .good : .again) }
        if grade.correct {
            if flashcardID == nil { learner.award(10) }
            if mode == .speaking || mode == .conversation {
                if learner.journeyDays == nil { learner.journeyDays = [] }
                learner.journeyDays?.insert(learner.target + ":" + learner.dailyKey)
            }
            if let lesson { learner.practicedModes.insert(learner.modeKey(lesson.id, mode.rawValue)) }
        }
        persist()
    }
    var readyGoal: JSONValue? {
        guard !(learner.pendingGoalChanges ?? []).contains(where:{ $0.target == learner.target && [.edit,.blueprint].contains($0.action) }) else { return nil }
        return learner.dailyGoalTask
    }
    var goalPreparationKey: String { "\(identity.npub):\(learner.target):\(learner.goal):\(learner.goalBucket["activeGoal"]["status"].string):\(CalendarDay.key(Date())):\(subscription.hasAccess)" }
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
    private func buildDailyGoal() async throws {
        let account = identity.npub, target = learner.target, day = CalendarDay.key(Date())
        if learner.goalBucket["activeGoal"]["id"].string.isEmpty { learner.editGoal(learner.goal); persist() }
        await sync()
        guard identity.npub == account, learner.target == target else { return }
        guard (learner.pendingGoalChanges ?? []).filter({ $0.target == target }).isEmpty else { throw AppError.message("Reconnect and sync to save your goal across devices.") }
        guard let goal = GoalPractice.active(learner.goalBucket) else { return }
        if readyGoal != nil { return }
        let progress = learner.goalBucket["goalProgress"], state = learner
        var raw: JSONValue = .object([:])
        do {
            raw = try await ai.goalBlueprint(learner:state,goal:goal)
        } catch { /* The web's deterministic tutor/lesson task remains usable when generation fails. */ }
        guard identity.npub == account, learner.target == target, GoalPractice.active(learner.goalBucket)?["id"] == goal["id"], CalendarDay.key(Date()) == day else { return }
        let blueprint = GoalPractice.blueprint(raw:raw,goal:goal,target:target,day:day,level:state.level,rating:state.rating,progress:progress)
        learner.applyGoal(GoalChange(action:.blueprint,target:target,payload:blueprint)); persist(); await sync()
        guard identity.npub == account, learner.target == target else { return }
        guard readyGoal != nil else { throw AppError.message("Your task is ready. Reconnect and sync to save the same task across devices.") }
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
    func recordGoalPreparation(_ blueprint: JSONValue, mode: String, card: JSONValue, success: Bool, answer: String) {
        guard goalIsCurrent(blueprint) else { return }
        let item = mode == "phonics" ? card["practiceWord"].string : card["concept"][learner.target].string
        let support = mode == "phonics" ? "modeled" : "prompted"
        let payload = blueprint.setting("mode",.string(mode)).setting("cardID",card["id"]).setting("success",.bool(success)).setting("support",.string(support)).setting("item",.string(item)).setting("transfer",.bool(card["practiceRole"].string == "transfer"))
        learner.applyGoal(GoalChange(action:.outcome,target:learner.target,payload:payload))
        learner.assess(correct:success,independent:false,questionLevel:blueprint["cefrLevel"].string)
        let observation = "\(success ? "Correct" : "Unsuccessful") \(mode == "phonics" ? "modeled practice of" : "recall of") \(item): \(answer). Preparation, not independent production."
        let evidence = payload.setting("target",.string(item)).setting("observation",.string(observation)).setting("domain",.string(mode == "phonics" ? "pronunciation" : "recall")).setting("expectedAnswer",.string(item))
        learner.applyGoal(GoalChange(action:.evidence,target:learner.target,payload:evidence))
        if mode == "phonics" {
            let artifact = goalArtifact(blueprint,mode:mode), required = Array(artifact["cards"].array.prefix(2))
            if required.count == 2 && required.allSatisfy({ artifact["outcomes"][$0["id"].string]["success"].boolean }) {
                recordGoalAttempt(blueprint,mode:mode,success:true,support:"modeled",observation:required.map { $0["practiceWord"].string + " pronounced successfully after a model" }.joined(separator:"; "),domain:"pronunciation")
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
        let payload: JSONValue = .object(["goalId":blueprint["goalId"],"dayKey":blueprint["dayKey"],"cefrLevel":blueprint["cefrLevel"],"mode":.string(mode),"success":.bool(success),"support":.string(support),"observation":.string(observation),"domain":.string(domain)])
        learner.applyGoal(GoalChange(action:.attempt,target:learner.target,payload:payload)); persist()
    }
    func checkGoal(_ blueprint: JSONValue, mode: String, response: String, context: String) async throws -> GoalVerdict {
        guard subscription.hasAccess, goalIsCurrent(blueprint) else { throw AppError.message("This daily task has changed. Open today's goal again.") }
        if (readyGoal?["modeProgress"][mode].number ?? 0) >= Double(GoalPractice.targets[mode] ?? 1) {
            return GoalVerdict(success:true,support:"prompted",feedback:"This part of today’s bundle is already complete. Continue with the next task.",observation:"Previously recorded goal evidence")
        }
        let account = identity.npub, target = learner.target, state = learner
        let verdict = try await ai.goalVerdict(blueprint:blueprint,response:response,context:context,support:state.support)
        guard identity.npub == account, learner.target == target, goalIsCurrent(blueprint), !verdict.observation.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { throw AppError.message("This check is no longer current. Open today's goal again.") }
        learner.assess(correct:verdict.success,independent:["independent","transferred"].contains(verdict.support),questionLevel:blueprint["cefrLevel"].string)
        recordGoalAttempt(blueprint,mode:mode,success:verdict.success,support:verdict.support,observation:verdict.observation,domain:"production")
        return verdict
    }
    var tutorLevels: [String] { learner.unlockedLevels(mode:"tutor",index:curriculumIndex[learner.target] ?? [:]) }
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
        if lesson.isFinalQuiz == true { return learner.quizPassed(lesson) };return !lesson.modes.contains("game") && Self.modes(for: lesson).allSatisfy { learner.practicedModes.contains(learner.modeKey(lesson.id, $0.rawValue)) }
    }
    func complete(_ lesson: Lesson) {
        guard canComplete(lesson) else { return }
        if lesson.id.hasPrefix("goal-") {
            guard let daily = readyGoal, lesson.id == GoalPractice.lesson(daily["blueprint"]).id else { return }
            learner.completed.insert(learner.completionKey(lesson.id))
            recordGoalAttempt(daily["blueprint"],mode:"lesson",success:true,support:"prompted",observation:"Completed all five goal-specific lesson skills for: " + daily["blueprint"]["objective"].string + ". This demonstrates supported practice, not independent real-world mastery.")
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
        do { try automaticWallet.enqueueAutomaticTips(recovering ? learner.pendingChanges ?? [] : changes,identity:identity,resuming:recovering) } catch { return }
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
