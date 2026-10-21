import SwiftUI

struct ShufflePracticeView:View {
    @EnvironmentObject var app:AppModel
    private static let modes:[PracticeMode]=[.speaking,.stories,.grammar,.vocabulary,.reading]
    @State private var mode=Self.modes.randomElement()!
    @State private var round=UUID()
    var body:some View {
        VStack {
            Button("Shuffle activity") { mode=Self.modes.randomElement()!;round=UUID() }.padding(.top)
            Group {
                switch mode {
                case .stories:StoryView(lesson:app.selectedLesson)
                case .reading:ReadingView(lesson:app.selectedLesson)
                default:ExerciseView(mode:mode,lesson:app.selectedLesson)
                }
            }.id(round)
        }.navigationTitle("Surprise practice")
    }
}
