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
    private func topics(_ app: AppModel) -> [String] { app.units.flatMap { [$0.title.localized("en")]+$0.lessons.map { $0.title.localized("en") } }.shuffled() }
    private func goal(_ app: AppModel, draft: ConversationDraft, abandoned: Bool) async throws -> ConversationGoal {
        if fixture { return ConversationGoal(text:.object(["en":.string(draft.messages.isEmpty ? "Say hello and your name" : "Say one thing you like")]),questionLevel:draft.challengeLevel ?? "Pre-A1",worth:ConversationPractice.worth(rating:app.learner.rating,level:draft.challengeLevel ?? "Pre-A1")) }
        do { return try await app.ai.conversationGoal(learner:app.learner,draft:draft,topics:topics(app),abandoned:abandoned) }
        catch {
            let level=draft.challengeLevel ?? PerformanceScore.level(score:app.learner.score)
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
            if draft.messages.isEmpty {
                let reply=fixture ? "¡Hola! ¿Cómo te llamas?" : try await app.ai.conversationReply(learner:app.learner,draft:draft)
                guard valid(app,account:account,target:target,session:session,token:token) else { return }
                draft.append(ConversationMessage(role:"assistant",text:reply))
            }
            app.learner.saveConversation(draft);app.persist()
        } catch { if generation == token { self.error=error.localizedDescription } }
    }
    func send(_ text: String, app: AppModel) async {
        guard !busy,app.subscription.hasAccess || fixture else { return }
        let draft=app.learner.conversation,answered=draft.messages.last { $0.role == "assistant" }?.text ?? ""
        await turn(text,answered:answered,voiceReply:nil,id:UUID(),app:app)
    }
    func voiceTurn(_ text: String, answered: String, reply: String, id: UUID, app: AppModel) async {
        guard app.subscription.hasAccess || fixture else { return }
        // The reference treats a turn arriving while grading is pending as neutral practice.
        if busy { var draft=app.learner.conversation;draft.append(ConversationMessage(role:"user",text:text));if !reply.isEmpty { draft.append(ConversationMessage(role:"assistant",text:reply)) };app.learner.saveConversation(draft);_ = app.learner.conversationTurn(id:id,answer:text,verdict:nil,turnXP:Int.random(in:1...3),goalXP:0);app.persist();return }
        await turn(text,answered:answered,voiceReply:reply,id:id,app:app)
    }
    private func turn(_ text: String, answered: String, voiceReply: String?, id: UUID, app: AppModel) async {
        guard !text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return }
        busy=true;error=nil;let token=generation,account=app.identity.npub,target=app.learner.target,session=app.learner.conversation.id,captured=app.learner.conversation.goal
        defer { if generation == token { busy=false } }
        var draft=app.learner.conversation;draft.append(ConversationMessage(role:"user",text:text));if let voiceReply,!voiceReply.isEmpty { draft.append(ConversationMessage(role:"assistant",text:voiceReply)) };app.learner.saveConversation(draft);app.persist()
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
                let next=try await goal(app,draft:draft,abandoned:!current.completed)
                guard valid(app,account:account,target:target,session:session,token:token),app.learner.conversation.goal?.id == current.id else { return }
                draft=app.learner.conversation;draft.goal=next;app.learner.saveConversation(draft);app.persist()
            }
        } catch { if generation == token { self.error=error.localizedDescription } }
    }
    func starter(_ app: AppModel) async {
        guard !busy,app.subscription.hasAccess || fixture,let goal=app.learner.conversation.goal else { return };busy=true;let token=generation;defer { if generation == token { busy=false } }
        let account=app.identity.npub,target=app.learner.target,session=app.learner.conversation.id
        do { let text=fixture ? "Hola, me llamo Ana." : try await app.ai.conversationStarter(learner:app.learner,draft:app.learner.conversation)
            guard valid(app,account:account,target:target,session:session,token:token),app.learner.conversation.goal?.id == goal.id else { return }
            var draft=app.learner.conversation;draft.goal?.starter=text;app.learner.saveConversation(draft);app.persist()
        } catch { if generation == token { self.error=error.localizedDescription } }
    }
    func translate(_ message: ConversationMessage, app: AppModel) async {
        guard !busy,app.subscription.hasAccess || fixture else { return };busy=true;let token=generation;defer { if generation == token { busy=false } };let account=app.identity.npub,target=app.learner.target,support=app.learner.support,session=app.learner.conversation.id
        do { let text=fixture ? "Hello! What is your name?" : try await app.ai.conversationTranslation(message.text,support:support)
            guard valid(app,account:account,target:target,session:session,token:token),support == app.learner.support else { return }
            var draft=app.learner.conversation;guard let index=draft.messages.firstIndex(where:{ $0.id == message.id }) else { return };draft.messages[index].translation=text;app.learner.saveConversation(draft);app.persist()
        } catch { if generation == token { self.error=error.localizedDescription } }
    }
}
