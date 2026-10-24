import SwiftUI

struct LearningGoalEditorView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @StateObject private var editor=GoalEditorController()
    @FocusState private var focused:Bool
    private struct Observation:Equatable {let account:String,target:String;let goal:JSONValue;let pending:[UUID]}
    private var scope:String {app.identity.npub+":"+app.learner.target}
    private var observed:Observation {.init(account:app.identity.npub,target:app.learner.target,goal:app.learner.goalBucket["activeGoal"],pending:(app.learner.pendingGoalChanges ?? []).filter{$0.target == app.learner.target && $0.action == .edit}.map(\.id))}
    var body:some View {
        let brand=PiyaliBrand(dark:scheme == .dark)
        VStack(alignment:.leading,spacing:0){
            OnboardingText(text:app.goalText("label"),size:14,weight:.semibold,lineHeight:21).padding(.bottom,8)
            ZStack(alignment:.topLeading){
                if editor.draft.isEmpty {Text(app.goalText("example")).font(PiyaliBrand.productFont(16)).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "879bb4":"9b8875")).padding(12).allowsHitTesting(false)}
                TextEditor(text:Binding(get:{editor.draft},set:{editor.change($0,app:app)})).font(PiyaliBrand.productFont(16)).lineSpacing(max(0,26-UIFont.systemFont(ofSize:16).lineHeight)).scrollContentBackground(.hidden).padding(.horizontal,7).padding(.vertical,4).frame(height:130).focused($focused).accessibilityLabel(app.goalText("label")).accessibilityIdentifier("learningGoalField")
            }.background(PiyaliBrand.unitColor(scheme == .dark ? "1f2937":"e0d2bf"),in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(focused ? PiyaliBrand.unitColor("63b3ed"):PiyaliBrand.unitColor(scheme == .dark ? "cbd5e1":"433528"),lineWidth:focused ? 2:1)}
            HStack {Spacer();if editor.saved {Text(app.goalText("saved")).font(PiyaliBrand.productFont(12)).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "a3b4c9":"786654")).accessibilityIdentifier("learningGoalSaved")}}.frame(minHeight:18).padding(.top,4)
        }.foregroundStyle(brand.text).padding(12).background(PiyaliBrand.unitColor(scheme == .dark ? "111827":"f1e8dc"),in:RoundedRectangle(cornerRadius:6))
            .task(id:scope){editor.load(app)}
            .onChange(of:focused){_,value in editor.focus(value,app:app)}
            .onChange(of:observed){_,_ in editor.receive(app)}
            .onDisappear{editor.close(app)}
    }
}
