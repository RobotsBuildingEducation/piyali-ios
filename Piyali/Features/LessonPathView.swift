import SwiftUI

struct LessonPathView:View {
    var loadsContent=true
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @State private var preview:LessonPreviewRequest?
    @State private var sessionLesson:Lesson?
    @State private var openSession=false
    private var brand:PiyaliBrand { PiyaliBrand(dark:scheme == .dark) }
    var body:some View {
        ScrollViewReader { scroll in
            ScrollView {
                VStack(spacing:0) {
                    CourseLevelNavigator(navigation:navigation,language:app.learner.support,complete:levelComplete) { level in app.setLessonLevel(level) }
                    CoursePathProgressHeader(xp:app.learner.xp,level:app.learner.level,percentage:completion,language:app.learner.support)
                    if app.loadingContent { ProgressView() }
                    LazyVStack(spacing:0) {
                        ForEach(Array(pathUnits.enumerated()),id:\.element.id) { index,unit in
                            CourseUnitPath(unit:unit,language:app.learner.support,statuses:statuses,percentages:percentages,hasNext:index < pathUnits.count-1) { showPreview($0,unit:unit) }
                        }
                    }
                }.padding(.horizontal,12).padding(.top,12).padding(.bottom,24).frame(maxWidth:1024).frame(maxWidth:.infinity)
            }.background(brand.background).toolbar(.hidden,for:.navigationBar)
                .task(id:app.learner.target+":"+app.learner.level) { if loadsContent { await app.reloadContent() } }
        }.environment(\.layoutDirection,.leftToRight)
            .sheet(item:$preview,onDismiss:{ if sessionLesson != nil { openSession=true } }) { request in
                LessonPreviewView(request:request) {
                    guard request.target == app.learner.target else { preview=nil;return }
                    if request.lesson.id != IntroTutorial.lessonID { app.beginLesson(request.lesson) }
                    sessionLesson=request.lesson;preview=nil
                }
            }
            .navigationDestination(isPresented:$openSession) {
                if let lesson=sessionLesson { if lesson.id == IntroTutorial.lessonID { IntroTutorialView(lesson:lesson).toolbar(.visible,for:.navigationBar) } else if lesson.modes.contains("game") { LessonView(lesson:lesson) } else { LessonView(lesson:lesson).toolbar(.visible,for:.navigationBar) } }
            }
    }
    private func showPreview(_ lesson:Lesson,unit:LearningUnit) { sessionLesson=nil;preview = .init(lesson:lesson,unit:unit,target:app.learner.target) }
    private var pathUnits:[LearningUnit] {
        if let intro=app.introLibrary?.units[app.learner.level],app.learner.needsIntro {return ([intro]+app.units).map{CoursePathSource.unit($0,target:app.learner.target)}}
        return app.units.map{CoursePathSource.unit($0,target:app.learner.target)}
    }
    private var statuses:[String:LessonAccessStatus] {
        var result=Dictionary(uniqueKeysWithValues:app.units.flatMap(\.lessons).map{($0.id,app.learner.lessonAccess($0,units:app.units))})
        if let intro=app.introLesson,app.learner.needsIntro {
            let key=app.learner.completionKey(intro.id)
            result[intro.id]=app.learner.completed.contains(key) ? .completed:app.learner.lessonWork?[key]?.status ?? .available
        }
        return result
    }
    private var percentages:[String:Double] {Dictionary(uniqueKeysWithValues:pathUnits.flatMap(\.lessons).map { ($0.id,(app.learner.lessonWork?[app.learner.completionKey($0.id)]?.fraction(goal:$0.xpReward) ?? 0)*100) })}
    private var levelComplete:Bool {app.learner.level == app.lessonLevels.last && !pathUnits.isEmpty && pathUnits.flatMap(\.lessons).allSatisfy{statuses[$0.id] == .completed}}
    private var navigation:JSONValue {CoursePathSource.run("navigation",.object(["currentLevel":.string(app.lessonLevels.last ?? "Pre-A1"),"activeCEFRLevel":.string(app.learner.level),"language":.string(app.learner.support)]))}
    private var completion:Double {
        let prefix=app.learner.target+":"
        let completed=Dictionary(uniqueKeysWithValues:app.learner.completed.filter{$0.hasPrefix(prefix)}.map{(String($0.dropFirst(prefix.count)),JSONValue.object(["status":.string("completed")]))})
        let summary=app.learner.courseSummaries?[app.learner.target] ?? .null
        return CoursePathSource.run("completion",.object(["level":.string(app.learner.level),"target":.string(app.learner.target),"progress":.object(["lessons":.object(completed),"courseSummary":summary])])).number
    }
}
