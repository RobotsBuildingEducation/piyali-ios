import SwiftUI

struct ReadingView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service=ReadingService()
    @StateObject private var speech=SpeechService()
    let lesson:Lesson?
    var onComplete:(()->Void)? = nil
    var embedded=false
    var startsFresh=false
    @State private var appeared=false
    @State private var refresh=0
    @State private var answer=""
    @State private var showTranslation=false
    private var scope:String { [app.identity.npub,app.learner.target,app.learner.support,app.learner.level,lesson?.id ?? "free",String(refresh)].joined(separator:"|") }
    private var run:ReadingRun? { guard let run=app.learner.reading,run.support == app.learner.support,run.lessonID == lesson?.id else { return nil };return run }
    var body:some View {
        Group { if ReadingService.fixture { activity } else { SubscriptionRequiredView(service:app.subscription) { activity } } }
            .navigationTitle(embedded ? lesson?.title.localized(app.learner.support) ?? "Reading" : "Reading")
            .task(id:scope) { speech.stopAll();answer="";showTranslation=false;let fresh=refresh > 0 || startsFresh && !appeared;appeared=true;await service.prepare(app,lesson:lesson,fresh:fresh);answer=run?.answer ?? "" }
            .onDisappear { service.cancel();speech.stopAll() }
    }
    private var activity:some View {
        Form {
            Button("New passage") { service.cancel();refresh += 1 }.disabled(service.busy).accessibilityIdentifier("readingNew")
            if service.busy { ProgressView("Working on your reading…") }
            if let error=service.error { Text(error).foregroundStyle(.red);Button("Try again") { refresh += 1 } }
            if let run {
                passage(run)
                if run.awarded {
                    Section("Review complete") {
                        Text("+\(run.reward) XP saved").accessibilityIdentifier("readingCompleted")
                        Text(run.feedback)
                        if let onComplete { Button(embedded ? EntryCopy.ui(app.learner.support,"grammar_next") : "Continue guide") { onComplete();if !embedded { dismiss() } } }
                    }
                } else { review(run) }
            }
            if let error=speech.error { Text(error).foregroundStyle(.red) }
        }
    }
    @ViewBuilder private func passage(_ run:ReadingRun) -> some View {
        Section(run.title) {
            Text(run.text).textSelection(.enabled).accessibilityIdentifier("readingPassage")
            Button("Listen to passage") { speech.speak(run.text,language:run.target) }
            Button("Stop audio") { speech.stopAll() }
            Button(showTranslation ? "Hide translation" : "Show translation") { showTranslation.toggle();if showTranslation { Task { await service.translate(app,run:run) } } }.disabled(service.busy)
            if showTranslation,let translation=run.translation { Text(translation).textSelection(.enabled) }
            Button("Save passage to notes") { app.learner.notes.insert(Note(title:run.title,body:run.text),at:0);app.persist() }
        }
        Section("Key ideas") { ForEach(Array(run.takeaways.enumerated()),id:\.offset) { _,value in Text(value) } }
    }
    @ViewBuilder private func review(_ run:ReadingRun) -> some View {
        Section("Review") {
            Picker("Review method",selection:Binding(get:{ run.method },set:{ value in speech.stopAll();answer="";update { $0.method=value;$0.correct=nil;$0.feedback="" } })) { Text("Comprehension").tag("question");Text("Read aloud").tag("speech") }.disabled(service.busy).accessibilityIdentifier("readingMethod")
            if run.method == "question" {
                Text(run.question.question).accessibilityIdentifier("readingQuestion")
                if run.question.type == "mc" {
                    ForEach(Array(run.question.options.enumerated()),id:\.offset) { index,option in
                        Button { answer=option;update { $0.answer=option } } label: { Label(option,systemImage:answer == option || (answer.isEmpty && run.answer == option) ? "checkmark.circle.fill" : "circle") }.accessibilityIdentifier("readingOption-\(index)")
                    }
                } else { TextField("Your answer",text:Binding(get:{ answer },set:{ value in answer=value;update { $0.answer=value } }),axis:.vertical).accessibilityIdentifier("readingAnswer") }
                Button("Check answer") { speech.stopAll();let value=answer.isEmpty ? run.answer : answer;Task { await service.check(app,run:run,answer:value,speech:false) } }.disabled(service.busy || (answer.isEmpty && run.answer.isEmpty)).accessibilityIdentifier("readingCheck")
            } else {
                Text("Read the passage into the microphone. Review the recognized words before submitting. Completing this review earns the passage reward once.")
                Button(speech.recording ? "Stop microphone" : "Start reading aloud") { if speech.recording { speech.stop() } else { Task { await speech.start(language:run.target) } } }.disabled(service.busy)
                if !speech.transcript.isEmpty {
                    Text(speech.transcript)
                    Button("Review recorded reading") { speech.stop();let words=speech.transcript;Task { await service.check(app,run:run,answer:words,speech:true) } }.disabled(service.busy)
                }
                Text("Feedback compares recognized words with the passage. It does not rate phonetic pronunciation.").font(.footnote)
            }
            if !run.feedback.isEmpty { Text(run.feedback).accessibilityIdentifier("readingFeedback") }
        }
    }
    private func update(_ action:(inout ReadingRun)->Void) { guard var current=app.learner.reading,current.id == run?.id else { return };action(&current);app.learner.saveReading(current);app.persist() }
}
