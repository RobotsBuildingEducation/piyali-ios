import Foundation

@MainActor final class GamePreparationController:ObservableObject {
    @Published private(set) var prepared=false
    @Published private(set) var ready=false
    @Published private(set) var exploring=false
    @Published private(set) var cancelled=false
    @Published private(set) var error:String?
    let service:RPGService
    private let wait:(Double)async throws->Void,random:()->Double
    private var task:Task<Void,Never>?,revealTask:Task<Void,Never>?,token=UUID(),owner:(()->Bool)?,baseline:RPGRun?,lesson:Lesson?,revealRequested=false,tutor=false
    init(service:RPGService?=nil,random:@escaping()->Double={Double.random(in:0...1)},wait:@escaping(Double)async throws->Void={try await Task.sleep(for:.milliseconds($0))}){self.service=service ?? RPGService();self.random=random;self.wait=wait}
    var busy:Bool{task != nil || revealTask != nil}
    /// Tutorial preparation starts during earlier activities. Its exploration
    /// window starts only after reveal() makes the playable loader visible.
    func start(_ app:AppModel,lesson:Lesson,tutor:Bool=false,deferReveal:Bool=false){
        guard task == nil,revealTask == nil,(!prepared || error != nil) else{return};cancel();cancelled=false;ready=false;error=nil;self.lesson=lesson;self.tutor=tutor;revealRequested = !deferReveal
        let account=app.identity.npub,target=app.learner.target,support=app.learner.support,level=tutor ? app.learner.tutorLevel:app.learner.level,current=token
        baseline=app.learner.rpgRuns?[target]
        owner={[weak app] in guard let app else{return false};return app.identity.npub == account && app.learner.target == target && app.learner.support == support && (tutor ? app.learner.tutorLevel:app.learner.level) == level && app.subscription.hasAccess}
        guard owner?() == true else{cancelled=true;return}
        task=Task{[weak self] in
            guard let self else{return};defer{if token == current{task=nil}}
            await service.prepare(app,lesson:lesson,episode:nil,tutor:tutor,stageOnly:true)
            guard valid(current),service.stagedRun != nil else{if token == current{if owner?() == true{error=service.error ?? "This game could not be prepared. Try again."}else{cancelled=true}};return}
            prepared=true;beginReveal(current)
        }
    }
    func reveal(){revealRequested=true;beginReveal(token)}
    private func beginReveal(_ current:UUID){
        guard revealRequested,prepared,error == nil,!ready,revealTask == nil,valid(current)else{return}
        exploring=true
        revealTask=Task{[weak self] in
            guard let self else{return};defer{if token == current{revealTask=nil}}
            do{let policy=try GameLoaderPolicy(),delay=try policy.run("delay",.object(["random":.number(random())])).number;try await wait(delay)}catch is CancellationError{return}catch{if valid(current){self.error=error.localizedDescription};return}
            guard valid(current)else{if token == current{cancelled=true};return};ready=true
        }
    }
    private func valid(_ token:UUID)->Bool{self.token == token && !Task.isCancelled && owner?() == true}
    func commit(_ app:AppModel)->Bool{
        guard ready,owner?() == true,let staged=service.stagedRun,let lesson,(staged.tutor == true) == tutor else{return false}
        let latest=app.learner.rpgRuns?[staged.target]
        if latest != baseline{
            guard let latest,latest.id == staged.id,latest.lessonID == lesson.id,latest.support == staged.support,!latest.claimed else{ready=false;error="This game changed while it was preparing. Try again.";return false}
        }else{app.learner.saveRPG(staged);app.persist()}
        return true
    }
    func cancel(){cancelled=true;token=UUID();task?.cancel();revealTask?.cancel();task=nil;revealTask=nil;service.cancel();prepared=false;ready=false;exploring=false;error=nil;owner=nil;baseline=nil;lesson=nil;revealRequested=false;tutor=false}
}
