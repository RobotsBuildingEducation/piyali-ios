import SwiftUI

struct ConversationView: View {
    @EnvironmentObject var app: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var conversation=ConversationService()
    @StateObject private var speech=SpeechService()
    @StateObject private var live=LiveTutorService()
    @State private var input=""
    @State private var readReplies=false
    @FocusState private var replyFocused: Bool
    var body: some View {
        Group {
            if conversation.fixture { content }
            else { SubscriptionRequiredView(service:app.subscription) { content } }
        }.navigationTitle("Conversation")
            .task(id:app.identity.npub+":"+app.learner.target+":"+String(app.subscription.hasAccess)) { await conversation.prepare(app) }
            .onChange(of:speech.transcript) { _,text in input=text }
            .onChange(of:app.learner.target) { _,_ in stop() }
            .onChange(of:app.identity.npub) { _,_ in stop() }
            .onChange(of:scenePhase) { _,phase in if phase == .background { stop() } }
            .onChange(of:app.subscription.hasAccess) { _,allowed in if !allowed { stop() } }
            .onDisappear { stop() }
            .toolbar { ToolbarItemGroup(placement:.keyboard) { Spacer();Button("Done") { replyFocused=false } } }
    }
    var content: some View {
        let draft=app.learner.conversation
        return Form {
            Section("Conversation goal") {
                if let goal=draft.goal {
                    Text(goal.text.localized(app.learner.support)).accessibilityIdentifier("conversationGoal")
                    Text("\(goal.questionLevel) · \(draft.turns) turns · \(draft.goalsCompleted) goals · \(draft.earnedXP) XP this session").accessibilityIdentifier("conversationStats")
                    if ["Pre-A1","A1"].contains(goal.questionLevel) {
                        Button("Need a phrase?") { Task { await live.stop();await conversation.starter(app) } }.disabled(conversation.busy)
                        if let starter=goal.starter { Text(starter);Button("Listen to starter") { speech.speak(starter,language:app.learner.target) } }
                    }
                }
                if !conversation.feedback.isEmpty { Text(conversation.feedback).accessibilityIdentifier("conversationFeedback") }
                if let error=conversation.error { Text(error).foregroundStyle(.red) }
                if conversation.busy { ProgressView("Conversation is updating…") }
                Button("New conversation") { Task { await live.stop();speech.stopAll();await conversation.prepare(app,fresh:true) } }.disabled(conversation.busy)
            }
            Section("Messages") {
                ForEach(draft.messages) { message in
                    VStack(alignment:.leading) {
                        Text(message.role == "user" ? "You" : "Piyali").font(.caption)
                        Text(message.text).textSelection(.enabled)
                        if let translated=message.translation { Text(translated).font(.footnote) }
                        HStack {
                            Button("Listen") { Task { await live.stop();speech.speak(message.text,language:app.learner.target) } }
                            Button("Translate") { Task { await conversation.translate(message,app:app) } }.disabled(conversation.busy || live.connected)
                        }.buttonStyle(.borderless)
                    }
                }
            }
            Section("Your reply") {
                TextField("Reply in your practice language",text:$input,axis:.vertical).focused($replyFocused).accessibilityIdentifier("conversationReply")
                Toggle("Read replies aloud",isOn:$readReplies)
                Button("Send reply") {
                    let text=input;input="";replyFocused=false;speech.stopAll()
                    Task { await conversation.send(text,app:app);if readReplies,let reply=app.learner.conversation.messages.last(where:{ $0.role == "assistant" })?.text { speech.speak(reply,language:app.learner.target) } }
                }.accessibilityIdentifier("conversationSend").disabled(conversation.busy || live.connected || input.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || draft.goal == nil)
                Button(speech.recording ? "Stop dictation" : "Dictate a reply") { if speech.recording { speech.stop() } else { Task { await speech.start(language:app.learner.target) } } }.disabled(conversation.busy || live.connected)
            }
            Section("Live voice") {
                Button(live.connected ? "Pause voice" : "Start voice") {
                    Task {
                        if live.connected { await live.stop() }
                        else {
                            speech.stopAll();let account=app.identity.npub,target=app.learner.target,session=draft.id
                            await live.start(learner:app.learner,conversationDraft:draft,onConversationTurn:{ text,answered,reply in
                                guard account == app.identity.npub,target == app.learner.target,session == app.learner.conversation.id,app.subscription.hasAccess else { return }
                                Task { guard account == app.identity.npub,target == app.learner.target,session == app.learner.conversation.id,app.subscription.hasAccess else { return };await conversation.voiceTurn(text,answered:answered,reply:reply,id:UUID(),app:app);guard account == app.identity.npub,target == app.learner.target,session == app.learner.conversation.id,app.subscription.hasAccess else { return };await live.updateConversation(app.learner.conversation,learner:app.learner) }
                            })
                        }
                    }
                }.disabled(live.connecting || conversation.busy || conversation.fixture || draft.goal == nil)
                if live.connecting { ProgressView("Connecting…") }
                if live.connected { Text("Microphone active · live conversation with Piyali") }
                if let error=live.error { Text(error).foregroundStyle(.red) }
            }
            Section("Settings") {
                Picker("Challenge level",selection:Binding(get:{ draft.challengeLevel ?? PerformanceScore.level(score:app.learner.score) },set:{ level in var next=app.learner.conversation;next.challengeLevel=level;app.learner.saveConversation(next);app.persist() })) { ForEach(LearningLanguages.levels,id:\.self) { Text($0).tag($0) } }
                TextField("Topics or interests",text:Binding(get:{ draft.interests },set:{ text in var next=app.learner.conversation;next.interests=String(text.prefix(600));app.learner.saveConversation(next);app.persist() }))
                TextField("Tutor personality",text:Binding(get:{ draft.personality },set:{ text in var next=app.learner.conversation;next.personality=String(text.prefix(240));app.learner.saveConversation(next);app.persist() }))
                Toggle("Coach pronunciation and natural phrasing",isOn:Binding(get:{ draft.pronunciation },set:{ value in var next=app.learner.conversation;next.pronunciation=value;app.learner.saveConversation(next);app.persist() }))
                Text("Choose New conversation to apply a new challenge level. Settings and your private draft are saved with your account.").font(.footnote)
            }
            if !draft.messages.isEmpty { Button("Save transcript to notes") { app.learner.notes.insert(Note(title:"Conversation · "+app.learner.target,body:draft.transcript),at:0);app.persist() }.accessibilityIdentifier("conversationSave") }
        }
    }
    private func stop() { conversation.cancel();speech.stopAll();Task { await live.stop() } }
}
