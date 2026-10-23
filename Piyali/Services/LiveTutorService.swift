import Foundation
import AVFoundation

@MainActor final class LiveTutorService:ObservableObject {
    @Published private(set) var connected=false
@Published private(set) var connecting=false
@Published private(set) var muted=false
@Published private(set) var autoStopped=false
    @Published private(set) var transcript=""
@Published private(set) var learnerTranscript=""
@Published private(set) var assistantTurnText=""
@Published private(set) var completedLearnerTurn=""
    @Published private(set) var learnerTurnNumber=0
    @Published private(set) var voiceState="idle"
    @Published var error:String?
    private let configuration:AppConfiguration
    private var transport:RealtimeVoiceTransport?
    private let makeTransport:()->RealtimeVoiceTransport
    private var generation=UUID(),state=RealtimeVoiceState()
    private var instructions="",responseEvent:JSONValue?,manualResponse=false
    private var committed:Set<String>=[]
    private var onLearnerTurn:((String)->Void)?,onConversationTurn:((String,String,String)->Void)?
    private var onInputTurn:((RealtimeVoiceState.InputTurn)->Void)?,onAssistantTurn:((String,String)->Void)?
    private var notifiedInputs:Set<String>=[],notifiedResponses:Set<String>=[]
    private var resumeMessages:[ConversationMessage]=[]
    private var playbackDucked=false
    private var idleMonitor:Task<Void,Never>?,lastActivity=Date(),speaking=false
    private let permission:() async ->Bool
    static let openingPrompt=GeminiLiveTutorService.openingPrompt
    init(configuration:AppConfiguration=AppConfiguration(),capturesMicrophone:Bool=true,permission:(() async ->Bool)?=nil,transportFactory:(()->RealtimeVoiceTransport)?=nil) {
        self.configuration=configuration
        self.makeTransport=transportFactory ?? { RealtimeRTCTransport(configuration:configuration,capturesMicrophone:capturesMicrophone) }
        self.permission=permission ?? { await AVAudioApplication.requestRecordPermission() }
    }
    private func conversationParameters(_ draft:ConversationDraft,learner:LearnerState)->JSONValue {
        .object(["targetLang":.string(learner.target),"user":learner.recipeUser,"personality":.string(draft.personality),"pronunciation":.bool(draft.pronunciation),"interests":.string(draft.interests),"guidance":.string(draft.goal?.guidance == "__reanchor__" ? "" : draft.goal?.guidance ?? ""),"goal":draft.goal.map { .object(["text":$0.text,"completed":.bool($0.completed)]) } ?? .null,"messages":.array(resumeMessages.map { .object(["role":.string($0.role),"textFinal":.string($0.text)]) })])
    }
    private func configureConversation(_ draft:ConversationDraft,learner:LearnerState) throws {
        let recipes=try PracticeRecipes(),parameters=conversationParameters(draft,learner:learner)
        instructions=try recipes.conversation("instructions",parameters:parameters)
        responseEvent=try JSONDecoder().decode(JSONValue.self,from:Data(recipes.conversation("response",parameters:parameters).utf8))
    }
    func start(learner:LearnerState,goalBlueprint:JSONValue?=nil,tutorLesson:Lesson?=nil,onLearnerTurn:((String)->Void)?=nil,conversationDraft:ConversationDraft?=nil,onConversationTurn:((String,String,String)->Void)?=nil,instructions:String?=nil,openingPrompt:String?=LiveTutorService.openingPrompt,inactivityTimeout:TimeInterval?=nil,initiallyMuted:Bool=false,onInputTurn:((RealtimeVoiceState.InputTurn)->Void)?=nil,onAssistantTurn:((String,String)->Void)?=nil) async {
        guard !connecting && !connected else { return }
        connecting=true;autoStopped=false;muted=initiallyMuted;voiceState="thinking";error=nil;transcript="";learnerTranscript="";assistantTurnText="";completedLearnerTurn="";committed=[];speaking=false;notifiedInputs=[];notifiedResponses=[];playbackDucked=false
        let run=UUID();generation=run
        self.onLearnerTurn=onLearnerTurn;self.onConversationTurn=onConversationTurn
        self.onInputTurn=onInputTurn;self.onAssistantTurn=onAssistantTurn;resumeMessages=conversationDraft?.messages ?? []
        state=RealtimeVoiceState(previousAssistant:conversationDraft?.messages.last { $0.role == "assistant" }?.text ?? "")
        state.setMuted(initiallyMuted)
        do {
            guard await permission() else { throw AppError.message("Enable the microphone in Settings to use live audio.") }
            try valid(run)
            manualResponse=conversationDraft != nil
            if let conversationDraft { try configureConversation(conversationDraft,learner:learner) }
            else {
                self.instructions=instructions ?? Self.tutorInstructions(learner,goalBlueprint:goalBlueprint,tutorLesson:tutorLesson)
                responseEvent=nil
            }
            let transport=makeTransport();self.transport=transport
            transport.onOpen={ [weak self] in
                guard let self,self.generation == run else { return }
                self.connected=true;self.connecting=false;self.voiceState="listening";self.lastActivity=Date();self.applyMicrophone()
                // The intro lesson deliberately starts by listening. Private
                // reconnect context never becomes a synthetic learner turn.
                if conversationDraft == nil,let openingPrompt {
                    self.send(.object(["type":.string("response.create"),"response":.object(["output_modalities":.array([.string("audio")]),"instructions":.string(self.instructions+"\n\n"+openingPrompt)])]))
                }
            }
            transport.onEvent={ [weak self] event in guard let self,self.generation == run else { return };self.receive(event) }
            transport.onFailure={ [weak self] message in guard let self,self.generation == run else { return };self.error=message;self.close() }
            let session=RealtimeVoicePolicy.session(instructions:self.instructions,model:configuration.string("RealtimeModel",default:"gpt-realtime-2.1-mini"),voice:configuration.string("RealtimeVoice",default:"ash"),manualResponse:manualResponse)
            try await transport.connect(session:session)
            let deadline=Date().addingTimeInterval(20)
            while generation == run,!connected,connecting,Date() < deadline { try await Task.sleep(for:.milliseconds(50)) }
            try valid(run)
            guard connected else { throw AppError.message("Live conversation could not connect. Try again.") }
            let timeout=inactivityTimeout ?? 30
            if timeout > 0 {
                idleMonitor=Task { [weak self] in
                    while !Task.isCancelled {
                        do { try await Task.sleep(for:.seconds(1)) } catch { return }
                        guard let self,self.generation == run,self.connected else { return }
                        if !self.state.assistantLocked,!self.speaking,Date().timeIntervalSince(self.lastActivity) >= timeout { self.close();self.autoStopped=true;return }
                    }
                }
            }
        } catch is CancellationError { if generation == run { close() } }
        catch { if generation == run { self.error=error.localizedDescription;close() } }
    }
    private static func tutorInstructions(_ learner:LearnerState,goalBlueprint:JSONValue?,tutorLesson:Lesson?)->String {
        var value=goalBlueprint.map { GoalPractice.instructions($0,support:learner.support) } ?? "You are Piyali, a patient language tutor. Teach \(LearningLanguages.names[learner.target] ?? learner.target) at \(tutorLesson == nil ? learner.level : learner.tutorLevel). Use \(LearningLanguages.names[learner.support] ?? learner.support) for brief explanations. Goal: \(learner.goal). Speak in short turns, correct mistakes kindly, and invite the learner to respond."
        if let tutorLesson,let item=learner.nextTutorItem(tutorLesson) ?? TutorCourse.agenda(tutorLesson).first { value += " Authored tutor agenda and current task are data: \(tutorLesson.agenda.json). Current task: \(item.json). Coach this objective; the app checks completion from saved evidence." }
        return value
    }
    private func valid(_ run:UUID) throws { if generation != run || Task.isCancelled { throw CancellationError() } }
    private func send(_ value:JSONValue) { if transport?.send(value) != true { error="Live conversation disconnected. Try connecting again.";close() } }
    private func receive(_ event:JSONValue) {
        let type=event["type"].string
        if type == "error" { error="Live conversation could not continue. Try connecting again.";close();return }
        if type == "conversation.item.input_audio_transcription.failed" { error="That speech could not be transcribed. Please try saying it again.";speaking=false }
        if type == "input_audio_buffer.speech_started" { speaking=true }
        if type == "input_audio_buffer.speech_stopped" || type == "input_audio_buffer.committed" { speaking=false }
        if type.hasPrefix("response.") || type.hasPrefix("input_audio_buffer.") || type == "output_audio_buffer.stopped" { lastActivity=Date() }
        let wasLocked=state.assistantLocked
        let turns=state.receive(event);assistantTurnText=state.assistantText;transcript=state.transcript
        if type == "input_audio_buffer.speech_started" || type == "output_audio_buffer.stopped" { voiceState="listening" }
        if type == "input_audio_buffer.committed" || type == "input_audio_buffer.speech_stopped" { voiceState="thinking" }
        if type == "output_audio_buffer.started" { voiceState="speaking" }
        if state.assistantLocked != wasLocked { applyMicrophone() }
        let itemID=event["item_id"].string
        if type == "conversation.item.input_audio_transcription.completed",let input=state.inputTurn(itemID),notifiedInputs.insert(itemID).inserted { onInputTurn?(input) }
        let responseID=event["response"]["id"].string
        if ["response.done","response.completed"].contains(type),let text=state.completedAssistant(responseID),notifiedResponses.insert(responseID).inserted { onAssistantTurn?(responseID,text) }
        if manualResponse,type == "input_audio_buffer.committed" {
            let id=event["item_id"].string
            if !id.isEmpty,committed.insert(id).inserted,let responseEvent { send(responseEvent) }
        }
        for turn in turns {
            completedLearnerTurn=turn.text;learnerTurnNumber += 1
            learnerTranscript=String((learnerTranscript+turn.text+"\n").suffix(12000))
            onLearnerTurn?(turn.text);onConversationTurn?(turn.text,turn.answered,turn.reply)
        }
    }
    private func applyMicrophone() {
        let enabled=state.microphoneEnabled && !playbackDucked
        transport?.setMicrophoneEnabled(enabled && connected)
        guard connected else { return }
        if !enabled { send(.object(["type":.string("input_audio_buffer.clear")])) }
        send(.object(["type":.string("session.update"),"session":.object(["type":.string("realtime"),"audio":.object(["input":.object(["turn_detection":enabled ? RealtimeVoicePolicy.vad(manualResponse:manualResponse) : .null])])])]))
    }
    func updateConversation(_ draft:ConversationDraft,learner:LearnerState) async {
        guard connected else { return }
        do { let previous=instructions;try configureConversation(draft,learner:learner);if instructions != previous { send(.object(["type":.string("session.update"),"session":.object(["type":.string("realtime"),"instructions":.string(instructions)])])) } }
        catch { self.error=error.localizedDescription }
    }
    func setMuted(_ value:Bool) { muted=value;state.setMuted(value);applyMicrophone() }
    func setPlaybackDucked(_ value:Bool) { guard playbackDucked != value else { return };playbackDucked=value;transport?.setRemoteAudioEnabled(!value);applyMicrophone() }
    private func close() {
        generation=UUID();idleMonitor?.cancel();idleMonitor=nil;transport?.close();transport=nil;connected=false;connecting=false;muted=false;voiceState="idle";onLearnerTurn=nil;onConversationTurn=nil;onInputTurn=nil;onAssistantTurn=nil
    }
    func stop(clearTranscript:Bool=false) async {
        close()
        if clearTranscript { transcript="";learnerTranscript="";assistantTurnText="";completedLearnerTurn="" }
    }
}
