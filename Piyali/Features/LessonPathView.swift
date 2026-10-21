import SwiftUI

struct LessonPathView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @State private var preview:LessonPreviewRequest?
    @State private var sessionLesson:Lesson?
    @State private var openSession=false
    private var brand:PiyaliBrand { PiyaliBrand(dark:scheme == .dark) }
    var body:some View {
        ScrollView {
            VStack(spacing:24) {
                HStack { Menu { ForEach(app.lessonLevels,id:\.self) { level in Button(level) { app.setLessonLevel(level);Task { await app.reloadContent() } } } } label:{ Label(app.learner.level,systemImage:"chevron.down").font(PiyaliBrand.font(16,600)) }.accessibilityIdentifier("lessonCourseLevel");Spacer();NavigationLink { PlacementView() } label:{ Image(systemName:"slider.horizontal.3").frame(width:44,height:44) }.accessibilityLabel("Choose your starting level") }
                if app.loadingContent { ProgressView() }
                if let intro=app.introLesson,let unit=app.introLibrary?.units[app.learner.level],app.learner.needsIntro {
                    Button { showPreview(intro,unit:unit) } label:{ lessonNode(intro,status:app.learner.completed.contains(app.learner.completionKey(intro.id)) ? .completed : .available) }.buttonStyle(.plain).accessibilityIdentifier("introLink")
                }
                ForEach(app.units) { unit in VStack(spacing:0) {
                    VStack(spacing:9) { Text(unit.title.localized(app.learner.support)).font(PiyaliBrand.font(20,700));Text(unit.description.localized(app.learner.support)).font(PiyaliBrand.font(13)).foregroundStyle(brand.secondary).multilineTextAlignment(.center) }.padding(20).frame(maxWidth:.infinity).background(brand.surface.opacity(0.7),in:RoundedRectangle(cornerRadius:20)).overlay { RoundedRectangle(cornerRadius:20).stroke(brand.border) }.padding(.bottom,20)
                    ForEach(Array(unit.lessons.enumerated()),id:\.element.id) { index,lesson in
                        let status=app.learner.lessonAccess(lesson,units:app.units)
                        Button { showPreview(lesson,unit:unit) } label:{ lessonNode(lesson,status:status) }.buttonStyle(.plain).disabled(!status.canOpen).accessibilityIdentifier("lessonNode-"+lesson.id).accessibilityValue(status.rawValue).offset(x:index.isMultiple(of:2) ? -35 : 35).frame(height:140)
                    }
                } }
            }.padding(.horizontal,24).padding(.bottom,24).frame(maxWidth:560).frame(maxWidth:.infinity)
        }.background(BrandBackground()).navigationTitle(ProductMode.path.title(app.learner.support)).task(id:app.learner.target+":"+app.learner.level) { await app.reloadContent() }
            .sheet(item:$preview,onDismiss:{ if sessionLesson != nil { openSession=true } }) { request in
                LessonPreviewView(request:request) {
                    guard request.target == app.learner.target else { preview=nil;return }
                    if request.lesson.id != IntroTutorial.lessonID { app.beginLesson(request.lesson) }
                    sessionLesson=request.lesson;preview=nil
                }
            }
            .navigationDestination(isPresented:$openSession) {
                if let lesson=sessionLesson { if lesson.id == IntroTutorial.lessonID { IntroTutorialView(lesson:lesson) } else { LessonView(lesson:lesson) } }
            }
    }
    private func showPreview(_ lesson:Lesson,unit:LearningUnit) { sessionLesson=nil;preview = .init(lesson:lesson,unit:unit,target:app.learner.target) }
    private func lessonNode(_ lesson:Lesson,status:LessonAccessStatus)->some View {
        VStack(spacing:10) {
            Image(systemName:status == .locked ? "lock.fill" : status == .completed ? "checkmark" : lesson.isFinalQuiz == true ? "trophy" : "book.fill").font(.system(size:25)).foregroundStyle(status == .locked ? brand.muted : .white).frame(width:64,height:64).background(status == .locked ? brand.border.opacity(0.4) : PiyaliBrand.teal,in:Circle()).overlay { Circle().stroke(brand.border,lineWidth:2) }.shadow(color:brand.border,radius:0,y:4)
            Text(lesson.title.localized(app.learner.support)).font(PiyaliBrand.font(13,600)).foregroundStyle(status == .locked ? brand.muted : brand.text).multilineTextAlignment(.center).frame(width:210)
        }
    }
}
