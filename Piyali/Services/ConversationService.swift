import Foundation

@MainActor final class ConversationService: ObservableObject {
    @Published private(set) var busy=false
    @Published var error: String?
    @Published private(set) var feedback=""
    private var generation=UUID()
    var fixture: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1" && ProcessInfo.processInfo.environment["PIYALI_CONVERSATION_FIXTURE"] == "1" && UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil
        #else
        return false
        #endif
    }
    func cancel() { generation=UUID();busy=false;error=nil;feedback="" }
    private func valid(_ app: AppModel, account: String, target: String, session: UUID, token: UUID) -> Bool {
        app.identity.npub == account && app.learner.target == target && app.learner.conversation.id == session && generation == token && (app.subscription.hasAccess || fixture)
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
    private func goal(_ app: AppModel, draft: ConversationDraft, abandoned: Bool,contextual:Bool=false) async throws -> ConversationGoal {
        if fixture { return ConversationGoal(text:.object(["en":.string(draft.messages.isEmpty ? "Say hello and your name" : "Say one thing you like")]),questionLevel:PerformanceScore.level(score:app.learner.score),worth:ConversationPractice.worth(rating:app.learner.rating,level:PerformanceScore.level(score:app.learner.score))) }
        do { return try await app.ai.conversationGoal(learner:app.learner,draft:draft,topics:topics(app),abandoned:abandoned,contextual:contextual) }
        catch {
            let level=PerformanceScore.level(score:app.learner.score)
            let fallback=try ContentLibrary.load([String:[JSONValue]].self,name:"conversation-topics")
            guard let text=fallback[level]?.randomElement() else { throw error }
            return ConversationGoal(text:text,questionLevel:level,worth:ConversationPractice.worth(rating:app.learner.rating,level:level))
        }
    }
    func prepare(_ app: AppModel, fresh: Bool = false) async {
        guard !busy,app.subscription.hasAccess || fixture else { return };busy=true;error=nil;feedback=""
        let token=generation,account=app.identity.npub,target=app.learner.target
        var draft=app.learner.conversation
        if fresh { let old=draft;draft=ConversationDraft();draft.interests=old.interests;draft.challengeLevel=old.challengeLevel;draft.personality=old.personality;draft.pronunciation=old.pronunciation }
        app.learner.saveConversation(draft);app.persist()
        let session=draft.id
        defer { if generation == token { busy=false } }
        guard draft.goal == nil || fresh else { return }
        do {
            let next=try await goal(app,draft:draft,abandoned:false)
            guard valid(app,account:account,target:target,session:session,token:token) else { return }
            draft=app.learner.conversation;draft.goal=next
            app.learner.saveConversation(draft);app.persist()
        } catch { if generation == token { self.error=error.localizedDescription } }
    }
    func send(_ text: String, app: AppModel) async {
        guard !busy,app.subscription.hasAccess || fixture else { return }
        let draft=app.learner.conversation,answered=draft.messages.last { $0.role == "assistant" }?.text ?? ""
        await turn(text,answered:answered,voiceReply:nil,id:UUID(),app:app)
    }
    func voiceTurn(_ text: String, answered: String, reply: String, id: UUID, app: AppModel,providerID:String?=nil,beforeResponseID:String?=nil) async {
        guard app.subscription.hasAccess || fixture else { return }
        if let providerID,app.learner.conversation.messages.contains(where:{$0.providerID == providerID}) { return }
        // The reference treats a turn arriving while grading is pending as neutral practice.
        if busy { var draft=app.learner.conversation;draft.append(ConversationMessage(role:"user",text:text,providerID:providerID),beforeProviderID:beforeResponseID);if !reply.isEmpty { draft.append(ConversationMessage(role:"assistant",text:reply)) };app.learner.saveConversation(draft);_ = app.learner.conversationTurn(id:id,answer:text,verdict:nil,turnXP:fixture ? 2 : Int.random(in:1...3),goalXP:0);app.persist();return }
        await turn(text,answered:answered,voiceReply:reply,id:id,app:app,providerID:providerID,beforeResponseID:beforeResponseID)
    }
    func assistantReply(_ text:String,providerID:String,app:AppModel) {
        guard app.subscription.hasAccess || fixture,!text.isEmpty else { return }
        var draft=app.learner.conversation;draft.append(.init(role:"assistant",text:text,providerID:providerID));app.learner.saveConversation(draft);app.persist()
    }
    func shuffleTopic(_ app:AppModel) async {
        guard !busy,app.subscription.hasAccess || fixture else { return };busy=true;error=nil;feedback=""
        let token=generation,account=app.identity.npub,target=app.learner.target,draft=app.learner.conversation
        defer { if generation == token { busy=false } }
        do { let next=try await goal(app,draft:draft,abandoned:true);guard valid(app,account:account,target:target,session:draft.id,token:token) else { return };var current=app.learner.conversation;current.goal=next;app.learner.saveConversation(current);app.persist() }
        catch { if generation == token { self.error=error.localizedDescription } }
    }
    private func turn(_ text: String, answered: String, voiceReply: String?, id: UUID, app: AppModel,providerID:String?=nil,beforeResponseID:String?=nil) async {
        guard !text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return }
        busy=true;error=nil;let token=generation,account=app.identity.npub,target=app.learner.target,session=app.learner.conversation.id,captured=app.learner.conversation.goal
        defer { if generation == token { busy=false } }
        var draft=app.learner.conversation;draft.append(ConversationMessage(role:"user",text:text,providerID:providerID),beforeProviderID:beforeResponseID);if let voiceReply,!voiceReply.isEmpty { draft.append(ConversationMessage(role:"assistant",text:voiceReply)) };app.learner.saveConversation(draft);app.persist()
        var verdict:ConversationVerdict?
        if text.count >= 3,let captured,!captured.completed {
            if fixture { verdict=ConversationVerdict(completed:!text.lowercased().contains("wrong") && !text.lowercased().contains("no tv"),reason:"Use your own words to keep the conversation going.",goalStillFits:!text.lowercased().contains("no tv")) }
            else { do { verdict=try await app.ai.conversationVerdict(goal:captured,learner:app.learner,reply:text,answeredLine:answered) } catch { if generation == token { self.error="This turn could not be graded; it counts as practice." } } }
        }
        guard valid(app,account:account,target:target,session:session,token:token) else { return }
        if app.learner.conversation.goal?.id != captured?.id { verdict=nil }
        let earned=app.learner.conversationTurn(id:id,answer:text,verdict:verdict,turnXP:fixture ? 2 : Int.random(in:1...3),goalXP:fixture ? 3 : Int.random(in:2...4));app.persist()
        feedback=(verdict?.reason ?? "Practice turn saved")+(earned > 0 ? " · +\(earned) XP" : "")
        do {
            draft=app.learner.conversation
            let reply:String
            if voiceReply != nil { reply="" } else if fixture { reply="Gracias. ¿Qué te gusta?" } else { reply=try await app.ai.conversationReply(learner:app.learner,draft:draft) }
            guard valid(app,account:account,target:target,session:session,token:token) else { return }
            draft=app.learner.conversation;if !reply.isEmpty { draft.append(ConversationMessage(role:"assistant",text:reply)) };app.learner.saveConversation(draft);app.persist()
            if let current=draft.goal,ConversationPractice.nextGoal(current) {
                if current.completed { try await Task.sleep(for:.milliseconds(1500));guard valid(app,account:account,target:target,session:session,token:token) else { return };draft=app.learner.conversation }
                let next=try await goal(app,draft:draft,abandoned:!current.completed,contextual:true)
                guard valid(app,account:account,target:target,session:session,token:token),app.learner.conversation.goal?.id == current.id else { return }
                draft=app.learner.conversation;draft.goal=next;feedback="";app.learner.saveConversation(draft);app.persist()
            }
        } catch { if generation == token { self.error=error.localizedDescription } }
    }
    func starter(_ app: AppModel) async {
        guard !busy,app.subscription.hasAccess || fixture,let goal=app.learner.conversation.goal else { return };busy=true;let token=generation;defer { if generation == token { busy=false } }
        let account=app.identity.npub,target=app.learner.target,session=app.learner.conversation.id
        do { let phrase:JSONValue=fixture ? .object(["target":.string("Hola, me llamo ___."),"support":.string("Hello, my name is ___.")]) : try await app.ai.conversationStarterPhrase(learner:app.learner,draft:app.learner.conversation)
            guard valid(app,account:account,target:target,session:session,token:token),app.learner.conversation.goal?.id == goal.id else { return }
            var draft=app.learner.conversation;draft.goal?.starter=phrase["target"].string;draft.goal?.starterSupport=phrase["support"].string;app.learner.saveConversation(draft);app.persist()
        } catch { if generation == token { self.error=error.localizedDescription } }
    }
    func translate(_ message: ConversationMessage, app: AppModel) async {
        guard !busy,app.subscription.hasAccess || fixture else { return };busy=true;let token=generation;defer { if generation == token { busy=false } };let account=app.identity.npub,target=app.learner.target,support=app.learner.support,session=app.learner.conversation.id
        do { let text=fixture ? (message.text.contains("Ana") ? "Hello, Ana! What do you like doing?" : "Try greeting and saying your name.") : try await app.ai.conversationTranslation(message.text,support:support)
            guard valid(app,account:account,target:target,session:session,token:token),support == app.learner.support else { return }
            var draft=app.learner.conversation;guard let index=draft.messages.firstIndex(where:{ $0.id == message.id }) else { return };draft.messages[index].translation=text;app.learner.saveConversation(draft);app.persist()
        } catch { if generation == token { self.error=error.localizedDescription } }
    }
}
