import Foundation

@MainActor protocol ConversationProviding {
    func conversationGoal(learner:LearnerState,draft:ConversationDraft,topics:[String],abandoned:Bool,contextual:Bool?) async throws ->ConversationGoal
    func conversationVerdict(goal:ConversationGoal,learner:LearnerState,reply:String,answeredLine:String) async throws ->ConversationVerdict
    func conversationStarterPhrase(learner:LearnerState,draft:ConversationDraft) async throws ->JSONValue
    func conversationTranslation(_ text:String,support:String) async throws ->String
}
extension AIService:ConversationProviding {}

@MainActor final class ConversationService: ObservableObject {
    @Published private(set) var busy=false
    @Published var error: String?
    @Published private(set) var feedback=""
    @Published private(set) var orbFeedback:OrbFeedback?
    private var generation=UUID()
    private var work:Set<UUID>=[]
    private var grading:UUID?
    private var pendingNextGoals:Set<UUID>=[]
    private func begin() ->UUID { let id=UUID();work.insert(id);busy=true;return id }
    private func finish(_ id:UUID,token:UUID) { guard generation == token else { return };work.remove(id);busy = !work.isEmpty }
    private struct Scope:Equatable { let owner:String;let target:String;let support:String }
    private var scope:Scope?
    private let injectedProvider:ConversationProviding?
    init(provider:ConversationProviding?=nil) { injectedProvider=provider }
    private func provider(_ app:AppModel)->ConversationProviding { injectedProvider ?? app.ai }
    private func bind(_ app:AppModel) {
        let next=Scope(owner:app.identity.npub,target:app.learner.target,support:app.learner.support)
        if scope != next { cancel();scope=next }
    }
    var fixture: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1" && ProcessInfo.processInfo.environment["PIYALI_CONVERSATION_FIXTURE"] == "1" && UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil
        #else
        return false
        #endif
    }
    func cancel() { generation=UUID();work=[];grading=nil;pendingNextGoals=[];busy=false;error=nil;feedback="";orbFeedback=nil }
    private func valid(_ app: AppModel, account: String, target: String, support:String, session: UUID, token: UUID) -> Bool {
        app.identity.npub == account && app.learner.target == target && app.learner.support == support && app.learner.conversation.id == session && generation == token && (app.subscription.hasAccess || fixture)
    }
    private var curriculum:[String:JSONValue]=[:]
    private func topics(_ app:AppModel)->[String] {
        let target=app.learner.target
        if curriculum[target] == nil { curriculum[target]=(try? ContentLibrary.load(JSONValue.self,name:"curriculum-"+target)) ?? .null }
        let level=PerformanceScore.level(score:app.learner.score),index=LearningLanguages.levels.firstIndex(of:level) ?? 0
        var values:[String]=[]
        for current in LearningLanguages.levels.prefix(index+1) {
            for unit in curriculum[target]?[current].array ?? [] where !unit["isTutorial"].boolean {
                let title=unit["title"].localized("en");if !title.isEmpty { values.append(current+": "+title) }
                for lesson in unit["lessons"].array where !lesson["isFinalQuiz"].boolean {
                    let title=lesson["title"].localized("en");if !title.isEmpty,!title.contains("Quiz") { values.append(current+": "+title) }
                }
            }
        }
        return Array(values.shuffled().prefix(15))
    }
    private func generatedGoal(_ app: AppModel, draft: ConversationDraft, abandoned: Bool,contextual:Bool=false) async throws -> ConversationGoal {
        if fixture {
            let first=draft.messages.isEmpty,support=app.learner.support
            let copy:[String:String]=["en":first ? "Say hello and your name" : "Say one thing you like","es":first ? "Saluda y di tu nombre" : "Di algo que te guste","fr":first ? "Saluez et dites votre nom" : "Dites une chose que vous aimez"]
            let text=copy[support] ?? copy["en"]!
            return ConversationGoal(text:JSONValue.object(["en":.string(text)]).setting(support,.string(text)),questionLevel:PerformanceScore.level(score:app.learner.score),worth:ConversationPractice.worth(rating:app.learner.rating,level:PerformanceScore.level(score:app.learner.score)))
        }
        do { return try await provider(app).conversationGoal(learner:app.learner,draft:draft,topics:topics(app),abandoned:abandoned,contextual:contextual) }
        catch {
            let level=PerformanceScore.level(score:app.learner.score)
            let fallback=try ContentLibrary.load([String:[JSONValue]].self,name:"conversation-topics")
            guard let text=fallback[level]?.randomElement() else { throw error }
            return ConversationGoal(text:text,questionLevel:level,worth:ConversationPractice.worth(rating:app.learner.rating,level:level))
        }
    }
    private func goal(_ app:AppModel,draft:ConversationDraft,abandoned:Bool,contextual:Bool=false) async throws ->ConversationGoal {
        let support=app.learner.support
        var result=try await generatedGoal(app,draft:draft,abandoned:abandoned,contextual:contextual)
        result.supportLang=support;return result
    }
    func prepare(_ app: AppModel, fresh: Bool = false) async {
        bind(app)
        guard !busy,app.subscription.hasAccess || fixture else { return };let operation=begin();error=nil;feedback=""
        let token=generation,account=app.identity.npub,target=app.learner.target,support=app.learner.support
        var draft=app.learner.conversation
        draft.refreshSupport(support)
        if fresh { let old=draft;draft=ConversationDraft();draft.interests=old.interests;draft.challengeLevel=old.challengeLevel;draft.personality=old.personality;draft.pronunciation=old.pronunciation }
        app.learner.saveConversation(draft);app.persist()
        let session=draft.id
        defer { finish(operation,token:token) }
        guard draft.goal == nil || fresh || draft.goal?.completed == true else { return }
        do {
            let next=try await goal(app,draft:draft,abandoned:false,contextual:draft.goal?.completed == true)
            guard valid(app,account:account,target:target,support:support,session:session,token:token) else { return }
            draft=app.learner.conversation;draft.goal=next
            app.learner.saveConversation(draft);app.persist()
        } catch { if valid(app,account:account,target:target,support:support,session:session,token:token) { self.error=error.localizedDescription } }
    }
    func send(_ text: String, app: AppModel) async {
        bind(app)
        guard !busy,app.subscription.hasAccess || fixture else { return }
        let draft=app.learner.conversation,answered=draft.messages.last { $0.role == "assistant" }?.text ?? ""
        await turn(text,answered:answered,voiceReply:nil,id:UUID(),app:app)
    }
    func voiceTurn(_ text: String, answered: String, reply: String, id: UUID, app: AppModel,providerID:String?=nil,beforeResponseID:String?=nil) async {
        bind(app)
        guard app.subscription.hasAccess || fixture else { return }
        if let providerID,app.learner.conversation.messages.contains(where:{$0.providerID == providerID}) { return }
        // The reference treats a turn arriving while grading is pending as neutral practice.
        if grading != nil { var draft=app.learner.conversation;draft.append(ConversationMessage(role:"user",text:text,providerID:providerID),beforeProviderID:beforeResponseID);if !reply.isEmpty { draft.append(ConversationMessage(role:"assistant",text:reply)) };app.learner.saveConversation(draft);_ = app.learner.conversationTurn(id:id,answer:text,verdict:nil,turnXP:fixture ? 2 : Int.random(in:1...3),goalXP:0);app.persist();return }
        await turn(text,answered:answered,voiceReply:reply,id:id,app:app,providerID:providerID,beforeResponseID:beforeResponseID)
    }
    func assistantReply(_ text:String,providerID:String,app:AppModel) {
        bind(app)
        guard app.subscription.hasAccess || fixture,!text.isEmpty else { return }
        var draft=app.learner.conversation;draft.append(.init(role:"assistant",text:text,providerID:providerID));app.learner.saveConversation(draft);app.persist()
    }
    func shuffleTopic(_ app:AppModel) async {
        bind(app)
        guard !busy,app.subscription.hasAccess || fixture else { return };let operation=begin();error=nil;feedback=""
        let token=generation,account=app.identity.npub,target=app.learner.target,support=app.learner.support,draft=app.learner.conversation
        let session=draft.id
        defer { finish(operation,token:token) }
        do { let next=try await goal(app,draft:draft,abandoned:true);guard valid(app,account:account,target:target,support:support,session:draft.id,token:token) else { return };var current=app.learner.conversation;current.goal=next;app.learner.saveConversation(current);app.persist() }
        catch { if valid(app,account:account,target:target,support:support,session:session,token:token) { self.error=error.localizedDescription } }
    }
    private func turn(_ text: String, answered: String, voiceReply: String?, id: UUID, app: AppModel,providerID:String?=nil,beforeResponseID:String?=nil) async {
        guard !text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return }
        let operation=begin();grading=id;error=nil;let token=generation,account=app.identity.npub,target=app.learner.target,support=app.learner.support,session=app.learner.conversation.id,captured=app.learner.conversation.goal
        defer { if generation == token,grading == id { grading=nil };finish(operation,token:token) }
        var draft=app.learner.conversation;draft.append(ConversationMessage(role:"user",text:text,providerID:providerID),beforeProviderID:beforeResponseID);if let voiceReply,!voiceReply.isEmpty { draft.append(ConversationMessage(role:"assistant",text:voiceReply)) };app.learner.saveConversation(draft);app.persist()
        var verdict:ConversationVerdict?
        if text.count >= 3,let captured,!captured.completed {
            if fixture { verdict=ConversationVerdict(completed:!text.lowercased().contains("wrong") && !text.lowercased().contains("no tv"),reason:"Use your own words to keep the conversation going.",goalStillFits:!text.lowercased().contains("no tv")) }
            else { do { verdict=try await provider(app).conversationVerdict(goal:captured,learner:app.learner,reply:text,answeredLine:answered) } catch { if valid(app,account:account,target:target,support:support,session:session,token:token) { self.error="This turn could not be graded; it counts as practice." } } }
        }
        guard valid(app,account:account,target:target,support:support,session:session,token:token) else { return }
        if app.learner.conversation.goal?.id != captured?.id { verdict=nil }
        if grading == id { grading=nil }
        if let verdict,verdict.completed || verdict.goalStillFits != false { orbFeedback=OrbFeedback(correct:verdict.completed) }
        let earned=app.learner.conversationTurn(id:id,answer:text,verdict:verdict,turnXP:fixture ? 2 : Int.random(in:1...3),goalXP:fixture ? 3 : Int.random(in:2...4));app.persist()
        feedback=(verdict?.reason ?? "Practice turn saved")+(earned > 0 ? " · +\(earned) XP" : "")
        do {
            draft=app.learner.conversation
            let reply:String
            if voiceReply != nil { reply="" } else if fixture { reply="Gracias. ¿Qué te gusta?" } else { reply=try await app.ai.conversationReply(learner:app.learner,draft:draft) }
            guard valid(app,account:account,target:target,support:support,session:session,token:token) else { return }
            draft=app.learner.conversation;if !reply.isEmpty { draft.append(ConversationMessage(role:"assistant",text:reply)) };app.learner.saveConversation(draft);app.persist()
            if let current=draft.goal,ConversationPractice.nextGoal(current),pendingNextGoals.insert(current.id).inserted {
                defer { if generation == token { pendingNextGoals.remove(current.id) } }
                if current.completed { try await Task.sleep(for:.milliseconds(1500));guard valid(app,account:account,target:target,support:support,session:session,token:token) else { return };draft=app.learner.conversation }
                let next=try await goal(app,draft:draft,abandoned:!current.completed,contextual:true)
                guard valid(app,account:account,target:target,support:support,session:session,token:token),app.learner.conversation.goal?.id == current.id else { return }
                draft=app.learner.conversation;draft.goal=next;feedback="";app.learner.saveConversation(draft);app.persist()
            }
        } catch { if valid(app,account:account,target:target,support:support,session:session,token:token) { self.error=error.localizedDescription } }
    }
    private func fixtureStarter(_ goal:ConversationGoal,support:String)->JSONValue {
        let first=["Say hello and your name","Saluda y di tu nombre","Saluez et dites votre nom"].contains(goal.text.localized(support))
        let target=first ? "Hola, me llamo ___." : "Me gusta ___."
        let translation=support == "es" ? target : support == "fr" ? (first ? "Bonjour, je m’appelle ___." : "J’aime ___.") : (first ? "Hello, my name is ___." : "I like ___.")
        return .object(["target":.string(target),"support":.string(translation)])
    }
    func starter(_ app: AppModel) async {
        bind(app)
        guard !busy,app.subscription.hasAccess || fixture,let goal=app.learner.conversation.goal else { return };let operation=begin();let token=generation;defer { finish(operation,token:token) }
        let account=app.identity.npub,target=app.learner.target,support=app.learner.support,session=app.learner.conversation.id
        do { let phrase:JSONValue=fixture ? fixtureStarter(goal,support:support) : try await provider(app).conversationStarterPhrase(learner:app.learner,draft:app.learner.conversation)
            guard valid(app,account:account,target:target,support:support,session:session,token:token),app.learner.conversation.goal?.id == goal.id else { return }
            var draft=app.learner.conversation;draft.goal?.starter=phrase["target"].string;draft.goal?.starterSupport=phrase["support"].string;app.learner.saveConversation(draft);app.persist()
        } catch { if valid(app,account:account,target:target,support:support,session:session,token:token) { self.error=error.localizedDescription } }
    }
    func translate(_ message: ConversationMessage, app: AppModel) async {
        bind(app)
        guard !busy,app.subscription.hasAccess || fixture else { return };let operation=begin();let token=generation;defer { finish(operation,token:token) };let account=app.identity.npub,target=app.learner.target,support=app.learner.support,session=app.learner.conversation.id
        do { let text:String
            if target == support { text=message.text }
            else if fixture { text=support == "fr" ? "Bonjour Ana ! Qu’aimez-vous faire ?" : (message.text.contains("Ana") ? "Hello, Ana! What do you like doing?" : "Try greeting and saying your name.") }
            else { text=try await provider(app).conversationTranslation(message.text,support:support) }
            guard valid(app,account:account,target:target,support:support,session:session,token:token),support == app.learner.support else { return }
            var draft=app.learner.conversation;guard let index=draft.messages.firstIndex(where:{ $0.id == message.id }) else { return };draft.messages[index].translation=text;draft.messages[index].translationLang=support;app.learner.saveConversation(draft);app.persist()
        } catch { if valid(app,account:account,target:target,support:support,session:session,token:token) { self.error=error.localizedDescription } }
    }
}
