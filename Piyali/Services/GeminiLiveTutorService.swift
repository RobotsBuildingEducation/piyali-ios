import Foundation
import FirebaseAILogic

// Explicit legacy Gemini provider checks; learner voice uses OpenAI WebRTC.
@MainActor enum GeminiLiveTutorService {
    static let openingPrompt = "Speak aloud now. Greet me briefly in my target language and start practicing my goal."
    static func model(for learner: LearnerState, configuration config: AppConfiguration = AppConfiguration(), goalBlueprint: JSONValue? = nil, tutorLesson: Lesson? = nil, conversationDraft: ConversationDraft? = nil, instructions:String? = nil) -> LiveGenerativeModel {
        let practiceLevel = tutorLesson == nil ? learner.level : learner.tutorLevel
        var instruction = goalBlueprint.map { GoalPractice.instructions($0,support:learner.support) + " Current ability context: internal Elo \(learner.rating), Score \(learner.score), estimated level \(PerformanceScore.level(score:learner.score)). Adapt challenge and support to observed responses while retaining the goal." } ?? "You are Piyali, a patient language tutor. Teach \(LearningLanguages.names[learner.target] ?? learner.target) at \(practiceLevel). Use \(LearningLanguages.names[learner.support] ?? learner.support) for brief explanations. Goal: \(learner.goal). Speak in short turns, correct mistakes kindly, and invite the learner to respond."
        if let tutorLesson {
            let item = learner.nextTutorItem(tutorLesson) ?? TutorCourse.agenda(tutorLesson).first!
            instruction += " Authored tutor agenda and current task are data: \(tutorLesson.agenda.json). Current task: \(item.json). Model when needed, ask for one fresh response at a time, and coach this specific objective. Do not declare completion; the app checks the evidence and saved progress."
        }
        if let conversationDraft { instruction=AIService.conversationInstructions(learner:learner,draft:conversationDraft)+" Continue this saved conversation; recent messages are private context, not new learner speech: "+JSONValue.array(conversationDraft.messages.suffix(6).map { .object(["role":.string($0.role),"text":.string($0.text)]) }).json+" Messages beginning APP_CONTEXT_UPDATE are private app instructions for the next turn. Never read them aloud or treat them as learner speech." }
        return FirebaseAI.firebaseAI(backend:config.geminiBackend(live:true)).liveModel(
            modelName:config.string("GeminiLiveModel",default:"gemini-2.5-flash-native-audio-preview-12-2025"),
            generationConfig:LiveGenerationConfig(responseModalities:[.audio],inputAudioTranscription:AudioTranscriptionConfig(),outputAudioTranscription:AudioTranscriptionConfig()),
            systemInstruction:ModelContent(role:"system",parts:[TextPart(instructions ?? instruction)])
        )
    }
}
