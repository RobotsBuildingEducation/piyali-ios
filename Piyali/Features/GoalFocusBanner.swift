import SwiftUI

@MainActor final class GoalCheckDraft:ObservableObject {
    @Published var response=""
    @Published var feedback=""
    @Published var busy=false
}
struct GoalCheckPresentation:Identifiable,Equatable {
    let id=UUID()
    let scope:GoalCourseScope
    let blueprint:JSONValue
    var draft:GoalCheckDraft?=nil
    static func ==(lhs:Self,rhs:Self)->Bool {lhs.id == rhs.id && lhs.scope == rhs.scope && lhs.blueprint == rhs.blueprint}
}
struct GoalFocusBanner:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    let blueprint:JSONValue
    @StateObject private var draft=GoalCheckDraft()
    var body:some View {
        let brand=PiyaliBrand(dark:scheme == .dark)
        Button {
            guard app.goalIsCurrent(blueprint) else{return}
            app.goalCheck = .init(scope:app.goalCourseScope,blueprint:blueprint,draft:draft)
        }label:{Text((app.readyGoal?["completed"].boolean == true ? app.goalText("complete"):app.goalText("title"))+" · "+blueprint["objective"].string).font(PiyaliBrand.productFont(14,600)).lineLimit(1).padding(.horizontal,12).frame(minHeight:32).foregroundStyle(brand.text).background(brand.surface,in:Capsule()).overlay{Capsule().stroke(brand.border)}}
            .buttonStyle(.plain).frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,12).padding(.vertical,8).frame(maxWidth:760).frame(maxWidth:.infinity).accessibilityIdentifier("goalFocusSummary").onChange(of:app.goalCourseScope){_,_ in draft.response="";draft.feedback=""}
    }
}
struct GoalCheckDialog:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    let presentation:GoalCheckPresentation
    @StateObject private var draft:GoalCheckDraft
    @State private var contentHeight:CGFloat=300
    @State private var headerHeight:CGFloat=86
    init(presentation:GoalCheckPresentation){self.presentation=presentation;_draft=StateObject(wrappedValue:presentation.draft ?? GoalCheckDraft())}
    @FocusState private var editing:Bool
    private var brand:PiyaliBrand {.init(dark:scheme == .dark)}
    private var done:Bool {app.readyGoal?["completed"].boolean == true}
    var body:some View {
        GeometryReader { geometry in ZStack {
            Color.black.opacity(0.48).ignoresSafeArea().onTapGesture{close()}
            VStack(spacing:0){
                OnboardingText(text:app.goalText("title")+" · "+presentation.blueprint["objective"].string,size:20,weight:.semibold,lineHeight:30).frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,32).padding(.vertical,28).onGeometryChange(for:CGFloat.self,of:{$0.size.height}){headerHeight=$0}
                ScrollView {
                    VStack(alignment:.leading,spacing:12){
                        OnboardingText(text:presentation.blueprint["scenario"].string,size:16,lineHeight:24)
                        OnboardingText(text:GoalPractice.list(presentation.blueprint["supports"]).joined(separator:" · "),size:14,lineHeight:21)
                        OnboardingText(text:GoalPractice.list(presentation.blueprint["successCriteria"]).joined(separator:" · "),size:14,lineHeight:21)
                        if done {Text(app.goalText("complete")).accessibilityIdentifier("goalCheckCompleted")}
                        else if ["lesson","flashcards"].contains(presentation.blueprint["mode"].string) {
                            ZStack(alignment:.topLeading){
                                if draft.response.isEmpty {Text(app.goalText("attempt")).font(PiyaliBrand.productFont(16)).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "879bb4":"9b8875")).padding(.horizontal,16).padding(.vertical,8).allowsHitTesting(false)}
                                TextEditor(text:Binding(get:{draft.response},set:{draft.response=GoalText.limit($0,units:2000)})).font(PiyaliBrand.productFont(16)).scrollContentBackground(.hidden).padding(.horizontal,11).frame(height:80).focused($editing).accessibilityLabel(app.goalText("attempt")).accessibilityIdentifier("goalAttempt")
                            }.overlay{RoundedRectangle(cornerRadius:6).stroke(editing ? PiyaliBrand.unitColor("3182ce"):PiyaliBrand.unitColor(scheme == .dark ? "cbd5e1":"433528"))}
                            Button {startCheck()}label:{HStack(spacing:8){if draft.busy{ProgressView().tint(.white)};Text(app.goalText("check"))}}.buttonStyle(GoalResponseButtonStyle()).disabled(draft.busy || draft.response.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty).accessibilityIdentifier("checkGoalAttempt")
                        }
                        if !draft.feedback.isEmpty {Text(draft.feedback).accessibilityIdentifier("goalAttemptFeedback")}
                    }.frame(maxWidth:.infinity,alignment:.leading).padding(28).onGeometryChange(for:CGFloat.self,of:{$0.size.height}){contentHeight=$0}
                }.frame(height:min(contentHeight,max(80,geometry.size.height-headerHeight-48)))
            }.foregroundStyle(brand.text).background(brand.surface,in:EntryCornerShape(radius:64)).overlay{EntryCornerShape(radius:64).stroke(PiyaliBrand.unitColor(scheme == .dark ? "94a3b8":"604d38").opacity(scheme == .dark ? 0.42:0.3),lineWidth:3).padding(1.5)}.overlay{GeometryReader{geometry in Button(action:close){Image(systemName:"xmark").font(.system(size:17,weight:.regular)).frame(width:32,height:32)}.buttonStyle(.plain).accessibilityLabel(EntryCopy.text(app.learner.support,"close_button")).accessibilityIdentifier("closeGoalCheck").position(x:geometry.size.width-36,y:36)}.environment(\.layoutDirection,.leftToRight)}.frame(maxWidth:512).padding(.horizontal,16).padding(.vertical,24)
        }.frame(width:geometry.size.width,height:geometry.size.height)
        }.ignoresSafeArea(.container).accessibilityElement(children:.contain)
    }
    private func close(){editing=false;if app.goalCheck?.id == presentation.id {app.goalCheck=nil}}
    private func startCheck(){
        guard !draft.busy else{return};draft.busy=true
        Task {defer{draft.busy=false};do{let verdict=try await app.checkGoal(presentation.blueprint,mode:presentation.blueprint["mode"].string,response:draft.response,context:"Focused written production check after practice. Model/hints were available; do not infer pronunciation or independent speech from text.");guard app.goalCourseScope == presentation.scope else{return};draft.feedback=verdict.feedback}catch is CancellationError{}catch{if app.goalCourseScope == presentation.scope {draft.feedback=error.localizedDescription}}}
    }
}

private struct GoalResponseButtonStyle:ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration:Configuration)->some View {
        configuration.label.font(PiyaliBrand.productFont(14,600)).padding(.horizontal,12).frame(minHeight:32).foregroundStyle(.white).background{Capsule().fill(PiyaliBrand.unitColor("319795")).shadow(color:enabled ? PiyaliBrand.unitColor("234e52"):.clear,radius:0,y:configuration.isPressed ? 0:4)}.opacity(enabled ? 1:0.6).offset(y:configuration.isPressed ? 4:0)
    }
}
