import SwiftUI

struct LessonPathView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    private var brand:PiyaliBrand { PiyaliBrand(dark:scheme == .dark) }
    var body:some View {
        ScrollView {
            VStack(spacing:24) {
                HStack { Menu { ForEach(app.lessonLevels,id:\.self) { level in Button(level) { app.setLessonLevel(level);Task { await app.reloadContent() } } } } label:{ Label(app.learner.level,systemImage:"chevron.down").font(PiyaliBrand.font(16,600)) }.accessibilityIdentifier("lessonCourseLevel");Spacer();NavigationLink { PlacementView() } label:{ Image(systemName:"slider.horizontal.3").frame(width:44,height:44) }.accessibilityLabel("Choose your starting level") }
                if app.loadingContent { ProgressView() }
                if let intro=app.introLesson,app.learner.needsIntro {
                    NavigationLink { IntroTutorialView(lesson:intro) } label:{ lessonNode(intro,status:app.learner.completed.contains(app.learner.completionKey(intro.id)) ? .completed : .available) }.accessibilityIdentifier("introLink")
                }
                ForEach(app.units) { unit in VStack(spacing:0) {
                    VStack(spacing:9) { Text(unit.title.localized(app.learner.support)).font(PiyaliBrand.font(20,700));Text(unit.description.localized(app.learner.support)).font(PiyaliBrand.font(13)).foregroundStyle(brand.secondary).multilineTextAlignment(.center) }.padding(20).frame(maxWidth:.infinity).background(brand.surface.opacity(0.7),in:RoundedRectangle(cornerRadius:20)).overlay { RoundedRectangle(cornerRadius:20).stroke(brand.border) }.padding(.bottom,20)
                    ForEach(Array(unit.lessons.enumerated()),id:\.element.id) { index,lesson in
                        let status=app.learner.lessonAccess(lesson,units:app.units)
                        NavigationLink { LessonView(lesson:lesson) } label:{ lessonNode(lesson,status:status) }.disabled(!status.canOpen).accessibilityIdentifier("lessonNode-"+lesson.id).accessibilityValue(status.rawValue).offset(x:index.isMultiple(of:2) ? -35 : 35).frame(height:140)
                    }
                } }
            }.padding(.horizontal,24).padding(.bottom,24).frame(maxWidth:560).frame(maxWidth:.infinity)
        }.background(BrandBackground()).navigationTitle(ProductMode.path.title(app.learner.support)).task(id:app.learner.target+":"+app.learner.level) { await app.reloadContent() }
    }
    private func lessonNode(_ lesson:Lesson,status:LessonAccessStatus)->some View {
        VStack(spacing:10) {
            Image(systemName:status == .locked ? "lock.fill" : status == .completed ? "checkmark" : lesson.isFinalQuiz == true ? "trophy" : "book.fill").font(.system(size:25)).foregroundStyle(status == .locked ? brand.muted : .white).frame(width:64,height:64).background(status == .locked ? brand.border.opacity(0.4) : PiyaliBrand.teal,in:Circle()).overlay { Circle().stroke(brand.border,lineWidth:2) }.shadow(color:brand.border,radius:0,y:4)
            Text(lesson.title.localized(app.learner.support)).font(PiyaliBrand.font(13,600)).foregroundStyle(status == .locked ? brand.muted : brand.text).multilineTextAlignment(.center).frame(width:210)
        }
    }
}
