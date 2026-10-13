import SwiftUI

struct IntroTutorialView:View {
    @EnvironmentObject var app:AppModel
    private let initialLesson:Lesson
    init(lesson:Lesson) { initialLesson=lesson }
    private var lesson:Lesson { app.introLesson ?? initialLesson }
    private let names=["vocabulary":"Vocabulary","grammar":"Grammar","reading":"Reading","stories":"Stories","realtime":"Conversation","game":"Adventure"]
    private var scope:String { app.identity.npub+":"+app.learner.target+":"+app.learner.level }
    var body:some View {
        let capturedScope=scope
        Form {
            Section(lesson.title.localized(app.learner.support)) {
                Text(lesson.description.localized(app.learner.support))
                Text("Explore the six lesson activities in order. You can try each activity or continue the introduction. Practice answers are graded separately.").font(.footnote)
                Text("\(app.learner.introSession.visited.count) / 6 activities visited").accessibilityIdentifier("introProgress")
            }
            if let mode=app.learner.introSession.next {
                Section(names[mode] ?? mode) {
                    Text(lesson.content[mode]["tutorialDescription"].localized(app.learner.support))
                    ForEach(Array(lesson.agenda["items"].array.filter { $0["modes"].array.contains(.string(mode)) }.enumerated()),id:\.offset) { _,item in Text(item["goal"].localized(app.learner.support)) }
                    if mode == "game" {
                        NavigationLink("Play introductory adventure") { RPGView(lesson:lesson,episode:nil,onTutorialComplete:{ advance(mode,scope:capturedScope) }) }
                    } else if let practice=AppModel.modes(for:lesson).first(where:{ $0.rawValue == names[mode] }) {
                        NavigationLink("Try "+(names[mode] ?? mode)) { ExerciseView(mode:practice,lesson:lesson) }
                    }
                    Button(mode == "game" ? "Skip adventure and finish introduction" : "Next activity") { advance(mode,scope:capturedScope) }.accessibilityIdentifier("introNext")
                }
            } else {
                Section("Introduction complete") {
                    let saved=app.learner.completed.contains(app.learner.completionKey(lesson.id))
                    Text("The introduction reward is separate from exercise and unit-review rewards.").font(.footnote)
                    Button(saved ? "Introduction completion saved" : "Finish Getting Started (+\(lesson.xpReward) XP)") { _=app.learner.completeIntro(lesson);app.persist() }.disabled(saved).accessibilityIdentifier("introFinish")
                    NavigationLink("Continue learning") { if let next=app.units.flatMap(\.lessons).first(where:{ !app.learner.completed.contains(app.learner.completionKey($0.id)) }) { LessonView(lesson:next) } }
                }
            }
        }.navigationTitle("Getting Started").id(capturedScope).disabled(app.loadingContent || app.introLibrary?.target != app.learner.target)
    }
    private func advance(_ mode:String,scope:String) {
        guard scope == self.scope else { return };_=app.learner.visitIntro(mode,expectedLevel:app.learner.level);app.persist()
    }
}
