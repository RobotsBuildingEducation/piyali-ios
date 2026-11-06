import Foundation
import Combine

/// Silent completion-time warming. It never selects a game or changes progress.
@MainActor final class UpcomingGameReviewController {
    private let service:RPGService,policy:UpcomingGameReviewPolicy?
    private var task:Task<Void,Never>?,token=UUID(),applicationActive=true
    private weak var app:AppModel?
    private let observer=UUID()
    private var subscription:AnyCancellable?,owner:(()->Bool)?
    private(set) var lastWarmedLessonID:String?
    var busy:Bool{task != nil}
    init(service:RPGService,policy:UpcomingGameReviewPolicy?=nil){self.service=service;self.policy=policy ?? (try? UpcomingGameReviewPolicy())}
    func setApplicationActive(_ active:Bool){applicationActive=active;if !active{cancel()}}
    func revalidate(){if task != nil,owner?() != true{cancel()}}
    func completed(_ lesson:Lesson,app:AppModel){
        guard applicationActive,app.signedIn,app.subscription.hasAccess,!app.identity.npub.isEmpty,lesson.isRepair != true,lesson.isGoal != true,let policy,let selectedLevel=try? policy.level(after:lesson)else{return}
        cancel();lastWarmedLessonID=nil;self.app=app
        let current=token,account=app.identity.npub,target=app.learner.target,support=app.learner.support,level=app.learner.level
        owner={[weak self,weak app] in guard let self,let app else{return false};return self.applicationActive && app.signedIn && app.identity.npub == account && app.learner.target == target && app.learner.support == support && app.learner.level == level && app.subscription.hasAccess}
        app.observePractice(owner:observer){[weak self] in self?.revalidate()}
        subscription=app.subscription.objectWillChange.sink{[weak self] _ in Task{@MainActor in self?.revalidate()}}
        task=Task{[weak self,weak app] in
            guard let self,let app else{return};defer{if token == current{task=nil;service.cancel();detach()}}
            guard let units=try? await Task.detached(priority:.utility,operation:{try ContentLibrary.load([String:[LearningUnit]].self,name:"curriculum-"+target)[selectedLevel] ?? []}).value,valid(current),let candidate=try? policy.candidate(after:lesson,units:units),let review=units.flatMap(\.lessons).first(where:{$0.id == candidate.lessonID})else{return}
            await service.prepare(app,lesson:review,episode:nil,stageOnly:true)
            guard valid(current),service.stagedRun != nil else{return};lastWarmedLessonID=review.id
        }
    }
    private func valid(_ token:UUID)->Bool{self.token == token && !Task.isCancelled && owner?() == true}
    private func detach(){app?.stopObservingPractice(owner:observer);subscription?.cancel();subscription=nil;app=nil;owner=nil}
    func cancel(){lastWarmedLessonID=nil;token=UUID();task?.cancel();task=nil;service.cancel();detach()}
}
