import SwiftUI

struct MemoryNoteDetails: View {
    let note: MemoryNote
    var body: some View {
        VStack(alignment:.leading,spacing:8) {
            Text("\(note.text("cefrLevel")) · \(note.text("sourceMode")) · Priority \(note.severity)/3").font(.caption)
            if !note.text("userAnswer").isEmpty { Text("Your answer: " + note.text("userAnswer")).accessibilityIdentifier("memoryAnswer") }
            if !note.text("correction").isEmpty { Text("Correction: " + note.text("correction")) }
            if !note.text("mistake").isEmpty { Text(note.text("mistake")) }
            if !note.text("tip").isEmpty { Text(note.text("tip")) }
            Text("Feedback language: " + (LearningLanguages.names[note.text("supportLang")] ?? note.text("supportLang"))).font(.caption).foregroundStyle(.secondary)
        }.textSelection(.enabled)
    }
}
struct CompanionMemoryView: View {
    @EnvironmentObject var app: AppModel
    var body: some View {
        List {
            Text("Useful mistakes are kept through the following day for focused repair. Repeated slips strengthen one memory; completing its repair retires it.").font(.footnote)
            if app.learner.activeMemories.isEmpty { Text("No active memories for this practice language.") }
            ForEach(app.learner.activeMemories) { note in
                Section(note.text("concept")) { MemoryNoteDetails(note:note) }
            }
            NavigationLink("Practice repairs") { RepairPracticeView() }
        }.navigationTitle("Companion memory")
    }
}
