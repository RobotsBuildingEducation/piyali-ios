import SwiftUI
struct VoiceJourneyView: View {
    @EnvironmentObject var app: AppModel
    @StateObject private var recorder = JourneyRecorder()
    @State private var recordingMilestone: Int?
    let milestones = [1,5,15,30,45,60,90,120,150]
    var count: Int { app.learner.journeyQuestCounts?[app.learner.target] ?? 0 }
    var body: some View {
        List {
            Text("\(count) completed daily quests. Clear every course in the daily plate to count a session. Each day counts once per language.")
            Text("Record up to 45 seconds at an unlocked milestone to hear how your voice develops. Recordings stay on this iPhone.").font(.footnote)
            ForEach(milestones,id:\.self) { milestone in
                let key = "\(app.learner.target):\(milestone)"
                Section("\(milestone) quest sessions") {
                    if let file = app.learner.journeyRecordings?[key] {
                        Button("Listen to recording") { recorder.play(account:app.identity.npub,file:file) }
                    } else if count >= milestone {
                        Text("Introduce yourself and describe your learning goal in your practice language.")
                        Button(recorder.recording && recordingMilestone == milestone ? "Finish recording" : "Record milestone") {
                            recordingMilestone = milestone
                            if recorder.recording { recorder.stop() } else { Task { await recorder.record(account:app.identity.npub,milestone:milestone,language:app.learner.target) } }
                        }.disabled(recorder.recording && recordingMilestone != milestone)
                    } else { Text("Unlocks after \(milestone) quest sessions").foregroundStyle(.secondary) }
                }
            }
            if let error = recorder.error { Text(error).foregroundStyle(.red) }
        }.navigationTitle("Voice journey")
            .onChange(of:recorder.savedFile) { _, file in
                guard let file, let milestone = recordingMilestone else { return }
                if app.learner.journeyRecordings == nil { app.learner.journeyRecordings = [:] }
                app.learner.journeyRecordings?["\(app.learner.target):\(milestone)"] = file; app.persist()
            }
            .onDisappear { recorder.stopAll() }
    }
}
