import Foundation

@MainActor final class RPGService: ObservableObject {
    @Published private(set) var library:RPGLibrary?
    @Published private(set) var busy=false
    @Published var error:String?
    private var loadedTarget="",pendingKey=""
    private var generation=UUID(),speechGeneration=UUID(),libraryLoadID=UUID()
    private var pending:Task<Void,Never>?,speechRequest:Task<Void,Never>?
    private let policy:RPGPreparationPolicy?,cache:RPGPreparationCache
    private let writer:((RPGPreparationPolicy.Request)async throws->String)?,speaker:((String)async throws->String)?
    init(policy:RPGPreparationPolicy?=try? RPGPreparationPolicy(),cache:RPGPreparationCache?=nil,writer:((RPGPreparationPolicy.Request)async throws->String)?=nil,speaker:((String)async throws->String)?=nil){self.policy=policy;self.cache=cache ?? RPGPreparationCache();self.writer=writer;self.speaker=speaker}
    func cancelSpeech(){speechGeneration=UUID();speechRequest?.cancel();speechRequest=nil;if pending == nil{busy=false}}
    func cancel(){generation=UUID();pending?.cancel();pending=nil;pendingKey="";cancelSpeech();busy=false;error=nil}
    func load(target:String)async {
        guard loadedTarget != target else{return};let token=generation,loadID=UUID();libraryLoadID=loadID;library=nil;loadedTarget="";busy=true;error=nil
        defer{if generation == token,libraryLoadID == loadID{busy=false}}
        do{let loaded=try await Task.detached{try ContentLibrary.load(RPGLibrary.self,name:"rpg-"+target)}.value;guard generation == token,libraryLoadID == loadID,!Task.isCancelled else{return};library=loaded;loadedTarget=target}catch{if generation == token,libraryLoadID == loadID{self.error=error.localizedDescription}}
    }
    private func valid(_ app:AppModel,account:String,target:String,support:String,token:UUID)->Bool{app.identity.npub == account && app.learner.target == target && app.learner.support == support && token == generation && !Task.isCancelled}
    private func level(_ app:AppModel,lesson:Lesson?,tutor:Bool)->String{tutor ? (lesson?.cefrLevel ?? app.learner.tutorLevel):app.learner.level}
    func prepare(_ app:AppModel,lesson:Lesson?,episode:String?,fresh:Bool=false,tutor:Bool=false)async {
        let owner=(account:app.identity.npub,target:app.learner.target,support:app.learner.support,level:level(app,lesson:lesson,tutor:tutor))
        let key=JSONValue.array([.string(app.identity.npub),.string(app.learner.target),.string(app.learner.support),.string(level(app,lesson:lesson,tutor:tutor)),.string(lesson?.id ?? ""),.string(episode ?? ""),.bool(fresh),.bool(tutor)]).canonicalJSON
        if key == pendingKey,let pending{await pending.value;return}
        cancel();let token=generation;pendingKey=key;busy=true
        let task=Task{[weak self] in guard let self else{return};await loadRun(app,lesson:lesson,episode:episode,fresh:fresh,tutor:tutor,token:token,owner:owner)};pending=task
        await withTaskCancellationHandler(operation:{await task.value},onCancel:{task.cancel()})
        if generation == token{pending=nil;pendingKey="";busy=false}
    }
    private func loadRun(_ app:AppModel,lesson:Lesson?,episode:String?,fresh:Bool,tutor:Bool,token:UUID,owner:(account:String,target:String,support:String,level:String))async {
        let account=owner.account,target=owner.target,support=owner.support,courseLevel=owner.level
        guard valid(app,account:account,target:target,support:support,token:token) else{return}
        func current()->Bool{valid(app,account:account,target:target,support:support,token:token) && level(app,lesson:lesson,tutor:tutor) == courseLevel}
        await load(target:target);guard current(),loadedTarget == target,let library else{return}
        let authoredLevel=lesson?.content["game"]["cefrLevel"].string.isEmpty == false ? lesson!.content["game"]["cefrLevel"].string:courseLevel
        if !fresh,let saved=app.learner.rpgRuns?[target],saved.support == support,!(saved.completed && saved.claimed),(saved.tutor == true) == tutor,saved.lessonID == lesson?.id,(episode == nil || saved.scenario.authoredEpisode.id == episode),saved.scenario.authoredEpisode.level == authoredLevel{return}
        let tutorial=lesson?.id == IntroTutorial.lessonID || lesson?.isTutorial == true
        let review=tutorial ? app.introLibrary.flatMap{$0.target == target ? $0.games[courseLevel]:nil}:lesson.flatMap{library.reviews[$0.id]}
        guard let original=review?.bySupport[support] ?? library.scenarios(level:courseLevel,support:support).first(where:{$0.authoredEpisode.id == episode}),let world=(tutorial ? app.introLibrary?.worlds[original.worldKey]:library.worlds[original.worldKey])else{error="This episode is not available for the selected language and level.";return}
        busy=true;var scenario=original
        if app.subscription.hasAccess,let policy {
            do{
                let sourceLesson=(try lesson.map{try RPGPreparationPolicy.value($0)} ?? .object(["id":.string("native-library-"+courseLevel),"content":.object(["game":.object(["cefrLevel":.string(courseLevel)])])])).setting("gameReviewContext",review?.context ?? .object([:]))
                let request=try policy.request(scenario:original,lesson:sourceLesson,target:target,support:support)
                if let value=cache.load(account:account,key:request.cacheKey,support:support),let prepared=try? policy.cached(value,request:request){scenario=prepared.scenario}
                else{
                    let response:String;if let writer{response=try await writer(request)}else{response=try await app.ai.rpgPreparedResponse(request.prompt)}
                    guard current(),app.subscription.hasAccess else{return}
                    if let prepared=try policy.prepare(response:response,request:request){scenario=prepared.scenario;cache.save(prepared.cacheValue,account:account,key:request.cacheKey,support:support)}
                }
            }catch{/* Source preparation failures keep the authored local deck. */}
        }
        guard current() else{return}
        let art=RPGArt.shared.data,rows=art["npcRows"].array.shuffled()
        if !rows.isEmpty{let members=scenario.npcs.indices.compactMap{index->RPGCast.Member? in let row=rows[index%rows.count],variants=art["npcs"].array.filter{$0["type"].string == row["id"].string};guard let variant=variants.randomElement()else{return nil};return RPGCast.Member(name:row["name"].string,image:variant["image"].string,kind:row["id"].string)};if let cast=try? RPGCast.applying(members,to:scenario){scenario=cast}}
        for index in scenario.npcs.indices{scenario.npcs[index].dialoguePortrait=StoryCharacterAvatar.appearance.portraitPool(scenario.npcs[index].characterKind ?? scenario.npcs[index].name).randomElement()}
        app.learner.saveRPG(RPGRun(target:target,support:support,lessonID:lesson?.id,xpReward:lesson?.xpReward ?? 30,scenario:scenario,world:world,tutorial:tutorial,tutor:tutor));app.persist()
    }
    func speak(_ answer:String,app:AppModel)async {
        guard !busy,app.subscription.hasAccess,let run=app.learner.rpgRuns?[app.learner.target],!run.resolved,let node=run.node,node.responseMode == "speech",!answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else{return}
        let token=generation,replyToken=UUID(),account=app.identity.npub;speechGeneration=replyToken;busy=true;error=nil
        let task=Task{[weak self] in
            guard let self else{return}
            let example=[node.speechExample ?? "",node.speechTarget ?? "",node.expectedAnswer].first{!$0.isEmpty} ?? "",match=RPGScoring.match(transcript:answer,target:example,lang:run.target,level:run.scenario.authoredEpisode.level)
            var turn=RPGSpeechTurn(grade:match.pass ? "full":"partial",reply:match.pass ? node.speechContinueReply ?? "":node.speechFallbackReply ?? "",tip:"")
            if app.subscription.hasAccess,let policy{do{let prompt=try policy.speechPrompt(run:run,answer:answer),response:String;if let speaker{response=try await speaker(prompt)}else{response=try await app.ai.rpgSpeechResponse(prompt)};if let generated=try policy.speechResult(response){turn=generated}}catch{/* Source matching fallback still advances nonempty roleplay. */}}
            guard valid(app,account:account,target:run.target,support:run.support,token:token),app.subscription.hasAccess,speechGeneration == replyToken,var current=app.learner.rpgRuns?[run.target],current.id == run.id,current.stepIndex == run.stepIndex,!current.resolved else{return}
            current.speak(answer,turn:turn);app.learner.saveRPG(current);app.persist()
        };speechRequest=task
        await withTaskCancellationHandler(operation:{await task.value},onCancel:{task.cancel()})
        if speechGeneration == replyToken{speechRequest=nil;busy=false}
    }
}
extension AIService {
    func rpgPreparedResponse(_ prompt:String)async throws->String{
        #if DEBUG
        if let response=try RPGPreparationFixture.preparedResponse(){return response}
        #endif
        return try await responsesText(prompt,json:true,reasoning:"low",outputProfile:"rpg_story")
    }
    func rpgSpeechResponse(_ prompt:String)async throws->String{
        #if DEBUG
        if let response=try await RPGPreparationFixture.speechResponse(){return response}
        #endif
        return try await responsesText(prompt,json:true,outputProfile:"rpg_speech")
    }
}

extension RPGService {
    /// Same plain-line translation contract as the source dialogue toggle.
    func translate(run:RPGRun,app:AppModel)async->[String]? {
        guard let node=run.node else{return nil};let token=generation,account=app.identity.npub
        let spoken=RPGDialogue.split(run.feedback.isEmpty ? node.npcLine:run.feedback).spoken,entries=[spoken]+(node.responseMode == "choice" ? node.choices.map(\.text):[])
        var seen:Set<String>=[];let names=run.scenario.npcs.map(\.name).filter{seen.insert($0).inserted},roster=["Assigned character roster: \(names.joined(separator:", ")).","Only use those exact names when referring to people in this scene.","Do not invent, translate, swap, or mention any other person names.","Prefer pronouns or second-person phrasing unless a roster name is truly necessary."].joined(separator:"\n")
        let prompt=["Translate each entry below into \(LearningLanguages.names[run.support] ?? run.support).",roster,"Preserve every character name exactly as written.","Output plain text only.","Return exactly \(entries.count) line\(entries.count>1 ? "s":"").","Each line must be only the translation for the matching entry index.","No numbering, labels, markdown, or commentary.","","Entries:"]+entries.enumerated().map{"\($0.offset+1). \($0.element)"}
        do{let raw=try await app.ai.text(prompt.joined(separator:"\n"));guard valid(app,account:account,target:run.target,support:run.support,token:token)else{return nil};return Array(raw.components(separatedBy:.newlines).map{$0.replacingOccurrences(of:"^\\s*\\d+[).:-]\\s*",with:"",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines)}.filter{!$0.isEmpty}.prefix(entries.count))}catch{return nil}
    }
}
