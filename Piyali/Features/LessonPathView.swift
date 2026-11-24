import SwiftUI

struct LessonPathView:View {
    var loadsContent=true
    var scrollRequest:UUID?
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var preview:LessonPreviewRequest?
    @State private var sessionLesson:Lesson?
    @State private var openSession=false
    @State private var sessionWasCompleted=false
    @State private var returnRequest:UUID?
    @State private var handledRequest:UUID?
    @State private var mountedUnits:Set<String>=[]
    private struct Jump:Hashable {
        let request:UUID
        let course,unit,lesson:String
    }
    private struct JumpStage:Hashable {
        let jump:Jump
        let unitMounted:Bool
    }
    private var brand:PiyaliBrand { PiyaliBrand(dark:scheme == .dark) }
    var body:some View {
        let units=pathUnits,access=statuses,progress=percentages(in:units)
        let stage=jump(in:units,access:access).map { JumpStage(jump:$0,unitMounted:mountedUnits.contains($0.unit)) }
        ScrollViewReader { scroll in
            ScrollView {
                VStack(spacing:0) {
                    CourseLevelNavigator(navigation:navigation,language:app.learner.support,complete:levelComplete) { level in app.setLessonLevel(level) }
                    CoursePathProgressHeader(xp:app.learner.xp,level:app.learner.level,percentage:completion,language:app.learner.support)
                    if app.loadingContent { ProgressView() }
                    LazyVStack(spacing:0) {
                        ForEach(Array(units.enumerated()),id:\.element.id) { index,unit in
                            CourseUnitPath(unit:unit,language:app.learner.support,statuses:access,percentages:progress,hasNext:index < units.count-1) { showPreview($0,unit:unit) }
                                .id(unit.id)
                                .onAppear { mountedUnits.insert(unit.id) }
                                .onDisappear { mountedUnits.remove(unit.id) }
                        }
                    }
                }.padding(.horizontal,12).padding(.top,12).padding(.bottom,24).frame(maxWidth:1024).frame(maxWidth:.infinity)
            }.background(brand.background).toolbar(.hidden,for:.navigationBar)
                .task(id:app.lessonCourseKey) { if loadsContent { await app.reloadContent() } }
                .task(id:stage) {
                    guard let stage else {return}
                    if !stage.unitMounted {
                        // Materialize the distant lazy unit before scrolling to a node inside it.
                        scroll.scrollTo(stage.jump.unit,anchor:.top)
                        return
                    }
                    do {try await Task.sleep(for:.milliseconds(300))} catch {return}
                    guard app.lessonCourseKey == stage.jump.course,app.hasLoadedLessonCourse else {return}
                    if reduceMotion {scroll.scrollTo(stage.jump.lesson,anchor:.center)}
                    else {withAnimation(.easeInOut(duration:0.32)) {scroll.scrollTo(stage.jump.lesson,anchor:.center)}}
                    handledRequest=stage.jump.request
                }
        }.environment(\.layoutDirection,.leftToRight)
            .onChange(of:scrollRequest) {_,_ in returnRequest=nil}
            .onChange(of:openSession) {wasOpen,isOpen in
                guard wasOpen,!isOpen,!sessionWasCompleted,let lesson=sessionLesson,
                      app.learner.completed.contains(app.learner.completionKey(lesson.id)) else {return}
                returnRequest=UUID()
            }
            .sheet(item:$preview,onDismiss:{ if sessionLesson != nil { openSession=true } }) { request in
                LessonPreviewView(request:request) {
                    guard request.target == app.learner.target else { preview=nil;return }
                    sessionWasCompleted=app.learner.completed.contains(app.learner.completionKey(request.lesson.id))
                    if request.lesson.id != IntroTutorial.lessonID { app.beginLesson(request.lesson) }
                    sessionLesson=request.lesson;preview=nil
                }
            }
            .navigationDestination(isPresented:$openSession) {
                if let lesson=sessionLesson { if lesson.id == IntroTutorial.lessonID { IntroTutorialView(lesson:lesson).toolbar(.visible,for:.navigationBar) } else if lesson.modes.contains("game") { LessonView(lesson:lesson) } else { LessonView(lesson:lesson).toolbar(.visible,for:.navigationBar) } }
            }
    }
    private func jump(in units:[LearningUnit],access:[String:LessonAccessStatus])->Jump? {
        guard let request=returnRequest ?? scrollRequest,request != handledRequest,app.hasLoadedLessonCourse,
              !openSession,preview == nil,let lesson=app.selectedLesson,lesson.id != IntroTutorial.lessonID,
              access[lesson.id] == .available || access[lesson.id] == .inProgress,
              let unit=units.first(where:{$0.lessons.contains(where:{$0.id == lesson.id})}) else {return nil}
        return Jump(request:request,course:app.lessonCourseKey,unit:unit.id,lesson:lesson.id)
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
    private func percentages(in units:[LearningUnit])->[String:Double] {Dictionary(uniqueKeysWithValues:units.flatMap(\.lessons).map { ($0.id,(app.learner.lessonWork?[app.learner.completionKey($0.id)]?.fraction(goal:$0.xpReward) ?? 0)*100) })}
    private var levelComplete:Bool {app.learner.level == app.lessonLevels.last && !pathUnits.isEmpty && pathUnits.flatMap(\.lessons).allSatisfy{statuses[$0.id] == .completed}}
    private var navigation:JSONValue {CoursePathSource.run("navigation",.object(["currentLevel":.string(app.lessonLevels.last ?? "Pre-A1"),"activeCEFRLevel":.string(app.learner.level),"language":.string(app.learner.support)]))}
    private var completion:Double {
        let prefix=app.learner.target+":"
        let completed=Dictionary(uniqueKeysWithValues:app.learner.completed.filter{$0.hasPrefix(prefix)}.map{(String($0.dropFirst(prefix.count)),JSONValue.object(["status":.string("completed")]))})
        let summary=app.learner.courseSummaries?[app.learner.target] ?? .null
        return CoursePathSource.run("completion",.object(["level":.string(app.learner.level),"target":.string(app.learner.target),"progress":.object(["lessons":.object(completed),"courseSummary":summary])])).number
    }
}
