import SwiftUI

struct PlacementView: View {
    @EnvironmentObject var app: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<String> = []
    var estimate: Placement? { PlacementAssessment.estimate(selected) }
    var body: some View {
        Form {
            Section(LearningLanguages.names[app.learner.target] ?? app.learner.target) {
                Text("Choose the statements that describe you. Your starting level unlocks courses without awarding completion or XP.")
                if let placement = app.learner.placements?[app.learner.target] { Text("Current starting level: \(placement.level)") }
                Button("I'm completely new") {
                    app.place(Placement(level:"Pre-A1",score:0,source:"completely_new",selectedIDs:[],updatedAt:Date())); dismiss()
                }
            }
            Section("My experience") {
                ForEach(PlacementAssessment.options) { option in
                    Toggle(option.label, isOn:Binding(get:{ selected.contains(option.id) },set:{ if $0 { selected.insert(option.id) } else { selected.remove(option.id) } }))
                }
            }
            if let estimate {
                Section("Suggested starting point") {
                    Text("\(estimate.level) · starting Score \(estimate.score)/100")
                    Text("Once you've practiced, changing your starting point preserves your earned Score.").font(.footnote)
                    Button("Start at \(estimate.level)") { app.place(estimate); dismiss() }
                }
            }
        }.navigationTitle("Starting level")
    }
}
