import SwiftUI

struct LessonPreviewRequest:Identifiable {
    let id=UUID()
    let lesson:Lesson
    let unit:LearningUnit
    let target:String
}
struct LessonPreviewView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    let request:LessonPreviewRequest
    let onStart:()->Void
    @State private var expanded=false
    @State private var gameLoading=false
    @StateObject private var gamePreparation=GamePreparationController()
    private static let appearance=(try? ContentLibrary.load(JSONValue.self,name:"lesson-appearance")) ?? .null
    private var brand:PiyaliBrand { .init(dark:scheme == .dark) }
    private var lesson:Lesson { request.lesson }
    private var tutorial:Bool { lesson.id == IntroTutorial.lessonID }
    private var game:Bool { !tutorial && lesson.modes.contains("game") }
    private var color:Color { PiyaliBrand.unitColor(Self.appearance["units"][request.target][request.unit.id]["color"].string) }
    private var goalColor:Color { PiyaliBrand.unitColor(tutorial ? "#2b6cb0" : game ? "#2c7a7b" : lesson.isFinalQuiz == true ? "#6b46c1" : "#b7791f") }
    private var items:[JSONValue] {
        if [IntroTutorial.lessonID,"lesson-tutorial-a1"].contains(lesson.id) {
            let translations=Self.appearance["starter"][request.target],selected=translations[app.learner.support].array
            return selected.isEmpty ? translations["en"].array : selected
        }
        return lesson.agenda["items"].array
    }
    private func copy(_ key:String)->String { EntryCopy.ui(app.learner.support,key) }
    var body:some View {
        preparedContent
            .fullScreenCover(isPresented:$gameLoading,onDismiss:finishGamePreparation){gameLoader}

    }
    private var gameLoader:some View {GamePreparationView(preparation:gamePreparation,support:app.learner.support,pet:app.learner.effectiveCompanionType,onCancel:cancelGamePreparation).environmentObject(app)}
    private func cancelGamePreparation(){gamePreparation.cancel();gameLoading=false}
    private var preparationScope:String{[app.identity.npub,app.learner.target,app.learner.support,app.learner.level].joined(separator:":")}
    private var preparedContent:some View {
        previewContent
            .onChange(of:gamePreparation.cancelled){_,cancelled in if cancelled{gameLoading=false}}
            .onChange(of:app.subscription.hasAccess){_,allowed in if !allowed,gameLoading{gamePreparation.cancel();gameLoading=false}}
            .onChange(of:gamePreparation.ready){_,ready in if ready{gameLoading=false}}
            .onChange(of:gamePreparation.error){_,error in if error != nil{gameLoading=false}}
            .onChange(of:preparationScope){_,_ in if gameLoading{gamePreparation.cancel();gameLoading=false}}
    }
    private var previewContent:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:0) {
                HStack(alignment:.top,spacing:14) {
                    Circle().fill(color).frame(width:14,height:14).shadow(color:color.opacity(0.5),radius:8).padding(.top,7)
                    VStack(alignment:.leading,spacing:9) {
                        Text(lesson.title.localized(app.learner.support)).font(PiyaliBrand.productFont(20,700))
                        Text(request.unit.title.localized(app.learner.support)).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary)
                    }
                    Spacer(minLength:0)
                    Button { dismiss() } label:{ Image(systemName:"xmark").font(.system(size:16,weight:.medium)).foregroundStyle(brand.muted).frame(width:32,height:32) }.buttonStyle(.plain).accessibilityLabel("Close").accessibilityIdentifier("closeLessonPreview")
                }.padding(26)
                Rectangle().fill(brand.border).frame(height:1)
                VStack(alignment:.leading,spacing:24) {
                    Text(lesson.description.localized(app.learner.support)).font(PiyaliBrand.productFont(16)).foregroundStyle(brand.secondary).lineSpacing(5)
                    PracticeFlowLayout(spacing:8) {
                        ForEach(lesson.modes,id:\.self) { mode in
                            Label(copy("mode_"+mode),systemImage:Self.icon(mode)).font(PiyaliBrand.productFont(12,700)).foregroundStyle(.white).padding(.horizontal,12).padding(.vertical,8).background(color,in:RoundedRectangle(cornerRadius:11)).overlay { RoundedRectangle(cornerRadius:11).stroke(Color.white.opacity(0.3)) }
                        }
                    }
                    if !items.isEmpty {
                        VStack(spacing:0) {
                            Button { withAnimation(.easeInOut(duration:0.2)) { expanded.toggle() } } label:{
                                HStack {
                                    let label=Self.appearance["objectives"][app.learner.support].string
                                    Text(label.isEmpty ? Self.appearance["objectives"]["en"].string : label).font(PiyaliBrand.productFont(14,700))
                                    Spacer()
                                    Text(String(items.count)).font(PiyaliBrand.productFont(12,700)).padding(.horizontal,7).padding(.vertical,3).background(brand.border,in:Capsule())
                                    Image(systemName:expanded ? "chevron.up" : "chevron.down").foregroundStyle(color).font(.system(size:13,weight:.bold))
                                }.padding(20).foregroundStyle(brand.text).contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityIdentifier("lessonPreviewObjectives")
                            if expanded {
                                ScrollView {
                                    VStack(alignment:.leading,spacing:16) {
                                        ForEach(Array(items.enumerated()),id:\.offset) { _,item in
                                            HStack(alignment:.top,spacing:12) {
                                                Image(systemName:"checkmark.circle").foregroundStyle(color)
                                                Text(item["label"].localized(app.learner.support).isEmpty ? item["targetConcept"].string : item["label"].localized(app.learner.support)).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary).frame(maxWidth:.infinity,alignment:.leading)
                                            }
                                        }
                                    }.padding(.horizontal,20).padding(.bottom,20)
                                }.frame(height:min(220,CGFloat(items.count)*42))
                            }
                        }.background(brand.border.opacity(scheme == .dark ? 0.2 : 0.35),in:RoundedRectangle(cornerRadius:12)).overlay { RoundedRectangle(cornerRadius:12).stroke(brand.border) }
                    }
                    HStack(spacing:14) {
                        Image(systemName:tutorial || lesson.isFinalQuiz == true ? "trophy" : game ? "gamecontroller" : "chart.bar.xaxis").font(.system(size:24)).foregroundStyle(goalColor).frame(width:42,height:42).background(goalColor.opacity(0.1),in:RoundedRectangle(cornerRadius:11))
                        Text(copy(tutorial ? "skill_tree_tutorial_goal" : game ? "skill_tree_game_reward" : lesson.isFinalQuiz == true ? "skill_tree_passing_score" : "skill_tree_xp_reward")).font(PiyaliBrand.productFont(16,700))
                        Spacer(minLength:4)
                        Text(goal).font(PiyaliBrand.productFont(tutorial ? 12 : 20,700)).multilineTextAlignment(.trailing).frame(maxWidth:150,alignment:.trailing)
                    }.padding(20).overlay { RoundedRectangle(cornerRadius:14).stroke(goalColor.opacity(0.7)) }.shadow(color:goalColor.opacity(0.12),radius:10,y:3)
                    Button(action:start) { Text(copy("skill_tree_start_lesson")).font(PiyaliBrand.productFont(18,700)).foregroundStyle(.white).frame(maxWidth:.infinity,minHeight:60).background(LinearGradient(colors:[color,color.opacity(0.87)],startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:14)) }.buttonStyle(.plain).shadow(color:color.opacity(0.25),radius:12,y:6).accessibilityIdentifier("startLessonFromPreview")
                }.padding(26)
            }
        }.background(brand.background.overlay(alignment:.top) { LinearGradient(colors:[color.opacity(0.09),.clear],startPoint:.topLeading,endPoint:.bottomTrailing).frame(height:200).allowsHitTesting(false) }).foregroundStyle(brand.text).presentationDetents([.large]).presentationCornerRadius(28)

    }
    private func start(){if game{gameLoading=true;gamePreparation.start(app,lesson:lesson)}else{onStart()}}
    private func finishGamePreparation(){if gamePreparation.ready,gamePreparation.commit(app){onStart()}else if gamePreparation.error == nil{dismiss()}}
    private var goal:String {
        if tutorial { return copy("skill_tree_tutorial_activities") }
        if lesson.isFinalQuiz == true { let rules=QuizRules(lesson.quizConfig ?? .null);return "\(Int((Double(rules.passingScore)/Double(max(1,rules.questionsRequired))*100).rounded()))%" }
        return "+\(lesson.xpReward) XP"
    }
    static func icon(_ mode:String)->String { ["vocabulary":"book.closed","grammar":"pencil","reading":"book","stories":"theatermasks","realtime":"mic","game":"gamecontroller"][mode] ?? "star" }
}
