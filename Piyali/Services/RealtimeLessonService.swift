import Foundation

@MainActor final class RealtimeLessonService:ObservableObject {
    @Published var busy=false
    @Published var error:String?
    private var generation=UUID()
    private var recipes:PracticeRecipes?
    private var processing=false
    private var pending:[(utterance:String,reply:String,id:UUID,runID:UUID)]=[]
    private func engine() throws ->PracticeRecipes { if let recipes { return recipes };let value=try PracticeRecipes();recipes=value;return value }
    func cancel() { generation=UUID();busy=false;processing=false;pending=[] }
    static func lessonJSON(_ lesson:Lesson) throws ->JSONValue { try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(lesson)) }
    func parameters(_ app:AppModel,lesson:Lesson,run:RealtimeLessonRun?=nil)->JSONValue {
        let state=app.learner,level=run?.questionLevel ?? ((lesson.id == IntroTutorial.lessonID || lesson.isFinalQuiz == true || lesson.id.hasPrefix("goal-") || lesson.id.hasPrefix("repair-")) ? lesson.cefrLevel ?? state.level : PerformanceScore.level(score:state.score))
        return .object(["lesson":(try? Self.lessonJSON(lesson)) ?? .null,"lessonContent":lesson.content["realtime"],"targetLang":.string(state.target),"supportLang":.string(state.support),"user":state.recipeUser,"cefrLevel":.string(level),"curriculumCefrLevel":.string(lesson.cefrLevel ?? state.level),"goal":run?.goal ?? .object([:]),"pronunciation":.bool(run?.pronunciation ?? false),"helpRequest":.string(run?.helpRequest ?? ""),"options":.object(["cefrLevel":.string(level),"curriculumCefrLevel":.string(lesson.cefrLevel ?? state.level),"previousScenario":.string(run?.title ?? "")])])
    }
    func prepare(_ app:AppModel,lesson:Lesson,fresh:Bool=false) async {
        let account=app.identity.npub,state=app.learner,key=RealtimeLessonRun.key(target:state.target,lesson:lesson.id),previous=state.realtimeLessonRuns?[key]
        guard app.subscription.hasAccess,!busy else { return }
        if !fresh,let previous,previous.support == state.support { return }
        let token=UUID();generation=token;busy=true;error=nil;defer { if generation == token { busy=false } }
        do {
            let recipes=try engine(),p=parameters(app,lesson:lesson,run:previous);let goal:JSONValue
            if lesson.content["realtime"]["topic"].string == "tutorial" {
                goal=try JSONDecoder().decode(JSONValue.self,from:Data(recipes.realtime("tutorialGoal",parameters:p).utf8))
            } else {
                let prompt=try recipes.realtime("goal",parameters:p)
                let title=try await app.ai.text(prompt).trimmingCharacters(in:.whitespacesAndNewlines).trimmingCharacters(in:CharacterSet(charactersIn:"\""))
                guard !title.isEmpty,title.count <= 600 else { throw AppError.message("A conversation goal could not be prepared. Please try again.") }
                goal = .object(["title_"+state.support:.string(title),"rubric_"+state.support:.string(title),"scenario":.string(title),"lessonScenario":.string(title),"successCriteria":.string(title),"roleplayPrompt":.string("Help the learner to: \(title). Create a realistic scenario and guide them.")])
            }
            try Task.checkCancellation();guard token == generation,app.identity.npub == account,app.learner.target == state.target,app.learner.support == state.support else { return }
            app.learner.saveRealtimeLesson(.init(target:state.target,support:state.support,lessonID:lesson.id,lessonLevel:lesson.cefrLevel ?? state.level,questionLevel:p["cefrLevel"].string,goal:goal));app.persist()
        } catch is CancellationError { } catch { if generation == token { self.error=error.localizedDescription } }
    }
    func instructions(_ app:AppModel,lesson:Lesson,run:RealtimeLessonRun) throws ->String {
        let recipes=try engine(),base=try recipes.realtime("instructions",parameters:parameters(app,lesson:lesson,run:run))
        if run.messages.isEmpty { return base }
        let history:JSONValue = .object(["messages":.array(run.messages.map { .object(["role":.string($0.role),"textFinal":.string($0.text)]) })])
        return base+"\n\n"+(try recipes.realtime("resume",parameters:history))
    }
    func judgePrompt(_ app:AppModel,lesson:Lesson,run:RealtimeLessonRun,utterance:String) throws ->String { try engine().realtime("judge",parameters:parameters(app,lesson:lesson,run:run).setting("utterance",.string(utterance))) }
    func receive(_ utterance:String,reply:String,turnID:UUID,app:AppModel,lesson:Lesson,runID:UUID) async {
        let key=RealtimeLessonRun.key(target:app.learner.target,lesson:lesson.id)
        guard app.subscription.hasAccess,(!busy || processing),let initial=app.learner.realtimeLessonRuns?[key],initial.id == runID,!initial.completed,!utterance.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return }
        app.learner.captureRealtimeTranscript(key:key,runID:runID,turnID:turnID,utterance:utterance,reply:reply);app.persist()
        pending.append((utterance,reply,turnID,runID));guard !processing else { return }
        let token=generation,account=app.identity.npub;processing=true;busy=true;error=nil;defer { if generation == token { busy=false;processing=false } }
        while !pending.isEmpty,token == generation {
            let turn=pending.removeFirst()
            guard let run=app.learner.realtimeLessonRuns?[key],run.id == turn.runID,!run.completed else { continue }
            do {
                let output=try await app.ai.responsesText(judgePrompt(app,lesson:lesson,run:run,utterance:turn.utterance),json:true)
                let object=try GenerationObjects.parse(output).first ?? .null
                let verdict=try JSONDecoder().decode(RealtimeLessonVerdict.self,from:Data(object.json.utf8))
                try Task.checkCancellation();guard token == generation,app.identity.npub == account,app.learner.target == run.target,app.learner.support == run.support,app.subscription.hasAccess else { return }
                _=app.learner.answerRealtimeLesson(key:key,runID:turn.runID,turnID:turn.id,utterance:turn.utterance,reply:turn.reply,verdict:verdict);app.persist()
            } catch is CancellationError { return } catch { if generation == token { self.error=error.localizedDescription } }
        }
    }
    func starter(_ app:AppModel,lesson:Lesson,run:RealtimeLessonRun) async {
        guard !busy,app.subscription.hasAccess,run.starter == nil,!run.completed else { return }
        let token=generation,account=app.identity.npub;busy=true;error=nil;defer { if generation == token { busy=false } }
        do {
            let targetName=LearningLanguages.names[run.target] ?? run.target,supportName=LearningLanguages.names[run.support] ?? run.support,last=run.messages.last(where:{$0.role == "assistant"})?.text ?? ""
            let prompt="A \(run.questionLevel) beginner is practicing spoken \(targetName) conversation. Their current goal: \"\(run.title)\"."+(last.isEmpty ? "" : "\nThe conversation partner just said: \"\(last)\". The phrase must work as a natural spoken reply to that.")+"\nWrite ONE starter phrase in \(targetName) the learner can say out loud to complete the goal: about 3-8 words, \(run.questionLevel)-appropriate high-frequency chunks only, natural and friendly. If a personal detail belongs in it (their name, a family member, a thing they like), put \"___\" in that spot — at most one blank. Also give its \(supportName) translation (keep \"___\" as \"___\").\nRespond with ONLY a JSON object: {\"target\":\"phrase in \(targetName)\",\"support\":\"translation in \(supportName)\"}"
            let output=try await app.ai.text(prompt,json:true),phrase=try GenerationObjects.parse(output).first ?? .null
            guard !phrase["target"].string.isEmpty else { throw AppError.message("A starter phrase could not be prepared.") }
            try Task.checkCancellation();guard token == generation,app.identity.npub == account,app.learner.target == run.target,app.learner.support == run.support,var next=app.learner.realtimeLessonRuns?[run.key],next.id == run.id else { return }
            next.starter=phrase;app.learner.saveRealtimeLesson(next);app.persist()
        } catch is CancellationError { } catch { if generation == token { self.error=error.localizedDescription } }
    }
}
