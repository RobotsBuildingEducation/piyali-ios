import Foundation

@MainActor final class PracticeService:ObservableObject {
    @Published var busy=false
    @Published private(set) var preparing=false
    @Published private(set) var preparationFailed=false
    @Published var error:String?
    @Published var help=""
    private var generation=UUID()
    private var engine:PracticeRecipes?
    private let injectedJudge:((String)async throws->String)?
    init(recipes:PracticeRecipes?=nil,judge:((String)async throws->String)?=nil){engine=recipes;injectedJudge=judge}
    private func recipes() throws ->PracticeRecipes { if let engine { return engine };let value=try PracticeRecipes();engine=value;return value }
    func cancel() { generation=UUID();busy=false;preparing=false;preparationFailed=false;error=nil }
    func ensureQuiz(_ app:AppModel,lesson:Lesson,restart:Bool=false) throws ->FinalQuizRun {
        var run=app.learner.quizRuns?[app.learner.quizKey(lesson.id)] ?? FinalQuizRun(lesson:lesson,learner:app.learner)
        if restart || !run.matches(lesson,app.learner) { run=FinalQuizRun(lesson:lesson,learner:app.learner) }
        if run.typedOptions?.count != run.rules.questionsRequired {
            let recipes=try recipes();try recipes.resetOptions()
            let context:JSONValue = .object(["lesson":PracticeCurriculum.lessonData(lesson),"targetLang":.string(app.learner.target),"user":app.learner.recipeUser])
            run.typedOptions=try (0..<run.rules.questionsRequired).map { _ in try recipes.select(module:.grammar,context:context).setting("isFinalQuiz",.bool(true)) }
            run.question=nil
        }
        app.learner.saveQuiz(run);app.persist();return run
    }
    func prepare(_ app:AppModel,module:PracticeRecipeModule,lesson:Lesson?,fresh:Bool=false) async {
        let state=app.learner,account=app.identity.npub,key=PracticeRun.key(target:state.target,lesson:lesson?.id,module:module)
        let quiz:FinalQuizRun?
        do { quiz=lesson?.isFinalQuiz == true ? try ensureQuiz(app,lesson:lesson!) : nil } catch { self.preparationFailed=true;self.error=error.localizedDescription;return }
        if quiz?.outcome.completed == true { return }
        if !fresh,let run=state.practiceRuns?[key],run.question.support == state.support,(quiz == nil || run.quizRunID == quiz?.id && run.question.id == quiz?.typedQuestionID) { return }
        guard app.subscription.hasAccess else { return }
        let token=UUID();generation=token;busy=true;preparing=true;preparationFailed=false;error=nil;help="";defer { if token == generation { busy=false;preparing=false } }
        do {
            let recipes=try recipes(),user=state.recipeUser
            #if DEBUG
            if var question=PracticeTestFixtures.question(module:module,recipes:recipes,target:state.target,support:state.support) {
                if quiz != nil { question=try PracticeQuestion(module:module,kind:question.kind,payload:question.payload,options:question.options.setting("isFinalQuiz",.bool(true)).setting("cefrLevel",.string(quiz!.level)),target:state.target,support:state.support) }
                question.worth=try GeneratedQuestionWorth.fallback(level:question.level,learner:state,recipes:recipes)
                let response=question.isDelight ? try recipes.inspect("initialResponse",parameters:.object(["question":question.payload])) : .object([:])
                var run=PracticeRun(question:question,lessonID:lesson?.id,lessonLevel:lesson?.cefrLevel ?? state.level,response:response);run.quizRunID=quiz?.id
                if let quiz,!app.learner.prepareTypedQuizQuestion(question,lessonID:quiz.lessonID,runID:quiz.id) { return }
                app.learner.savePractice(run);app.persist();return
            }
            #endif
            var lessonData=try lesson.map { try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode($0)) } ?? .object(["id":.string("free"),"cefrLevel":.string(state.level),"content":.object([:])])
            if let lesson {
                lessonData=lessonData.setting("isTutorial",.bool(lesson.id == IntroTutorial.lessonID)).setting("isGoal",.bool(lesson.id.hasPrefix("goal-"))).setting("isRepair",.bool(lesson.id.hasPrefix("repair-")))
                if let level=lesson.cefrLevel ?? (LearningLanguages.levels.contains(lesson.agenda["cefrLevel"].string) ? lesson.agenda["cefrLevel"].string : nil) { lessonData=lessonData.setting("cefrLevel",.string(level)) }
            }
            let unit=app.units.first { $0.lessons.contains(where:{$0.id == lesson?.id}) } ?? (lesson?.id == IntroTutorial.lessonID ? app.introLibrary?.units[state.level] : nil)
            let curriculum=try PracticeCurriculum.context(lesson:lesson,unit:unit,target:state.target,recipes:recipes)
            let context:JSONValue = .object(["lesson":lessonData,"targetLang":.string(state.target),"user":user])
            let options:JSONValue
            if let quiz,let planned=quiz.typedOptions,planned.indices.contains(quiz.answers.count) { options=planned[quiz.answers.count] }
            else { options=try recipes.select(module:module,context:context).setting("isFinalQuiz",.bool(false)) }
            let kind=options["exerciseType"].string
            let recent=Array(state.history.filter { $0.target == state.target && $0.mode.lowercased() == module.rawValue && $0.correct }.prefix(5)).map { JSONValue.string($0.question) }
            let parameters=options.setting("targetLang",.string(state.target)).setting("supportLang",.string(state.support)).setting("appUILang",.string(state.support)).setting("showTranslations",.bool(true)).setting("lessonContent",PracticeCurriculum.content(lesson,mode:module.rawValue,context:curriculum)).setting("user",user).setting("recentGood",.array(recent)).setting("recentQuestions",.array(recent))
            let prompt=StandardChoiceRepair.prompt(try recipes.build(module:module,kind:kind,parameters:parameters))
            var question:PracticeQuestion?
            var lastError:Error=PracticeQuestionFailure.malformed
            for attempt in 0..<2 {
                do {
                    let output=try await (attempt == 0 ? app.ai.text(prompt,json:kind.hasPrefix("delight:")) : app.ai.responsesText(prompt,json:kind.hasPrefix("delight:")));try Task.checkCancellation()
                    if kind.hasPrefix("delight:") {
                        let raw=try GenerationObjects.parse(output).first ?? .null
                        let normalized=try recipes.inspect("normalize",parameters:parameters.setting("variant",.string(String(kind.dropFirst(8)))).setting("raw",raw))
                        guard normalized != .null,try recipes.inspect("languageConsistent",parameters:parameters.setting("question",normalized)).boolean else { throw PracticeQuestionFailure.malformed }
                        if kind == "delight:morphology_forge" {
                            let preflight=try recipes.build(module:module,kind:"preflightMorphology",parameters:parameters.setting("question",normalized))
                            let verdict=try await app.ai.responsesText(preflight)
                            guard verdict.trimmingCharacters(in:.whitespacesAndNewlines).uppercased().hasPrefix("YES") else { throw PracticeQuestionFailure.malformed }
                        }
                        question=try .init(module:module,kind:kind,payload:normalized,options:options,target:state.target,support:state.support)
                    } else { question=try .parse(output,module:module,kind:kind,options:options,target:state.target,support:state.support) }
                    guard let candidate=question,try PracticeCurriculum.accepts(candidate,context:curriculum,recipes:recipes) else { question=nil;throw AppError.message("The generated exercise did not use this lesson’s material. Please try again.") }
                    break
                } catch { try Task.checkCancellation();lastError=error }
            }
            guard let question else { throw lastError }
            let response=question.isDelight ? try recipes.inspect("initialResponse",parameters:.object(["question":question.payload])) : .object([:])
            var run=PracticeRun(question:question,lessonID:lesson?.id,lessonLevel:lesson?.cefrLevel ?? state.level,response:response)
            run.question.worth=try await GeneratedQuestionWorth.assess(question:run.assessmentItem,level:question.level,mode:run.difficultyMode,learner:state,recipes:recipes,ai:app.ai)
            try Task.checkCancellation();guard generation == token,app.identity.npub == account,app.learner.target == state.target,app.learner.support == state.support else { return }
            run.quizRunID=quiz?.id
            if let quiz,!app.learner.prepareTypedQuizQuestion(run.question,lessonID:quiz.lessonID,runID:quiz.id) { return }
            app.learner.savePractice(run);app.persist()
        } catch is CancellationError { } catch { if token == generation { self.preparationFailed=true;self.error=error.localizedDescription } }
    }
    func ready(_ run:PracticeRun)->Bool {
        if run.question.isDelight { return (try? recipes().inspect("ready",parameters:.object(["question":run.question.payload,"response":run.response])).boolean) == true }
        return run.question.ready(run.response)
    }
    func check(_ app:AppModel,run:PracticeRun,confidence:Double=0,audio:SpeechAudioMetrics?=nil) async {
        guard !busy,!preparationFailed,run.correct != true,ready(run),app.subscription.hasAccess else { return }
        let token=generation,account=app.identity.npub;busy=true;error=nil;defer { if token == generation { busy=false } }
        do {
            let recipes=try recipes(),q=run.question
            let result=try await verdict(run:run,recipes:recipes,confidence:confidence,audio:audio,judge:{ prompt in
                if let injectedJudge=self.injectedJudge{return try await injectedJudge(prompt)}
                #if DEBUG
                if let result=PracticeTestFixtures.verdict(run:run,prompt:prompt){return result}
                #endif
                return try await app.ai.responsesText(prompt)
            })
            let reward:Int
            if q.isDelight { reward=Int(try recipes.inspect("xp",parameters:.object(["question":q.payload,"response":run.response,"options":.object(["revealedClues":.number(Double(run.revealedClues))])])).number) }
            else { reward=result.reward ?? q.standardReward }
            try Task.checkCancellation()
            guard generation == token,app.identity.npub == account,app.learner.target == q.target,app.learner.support == q.support,app.learner.practiceRuns?[run.key]?.question.id == q.id else { return }
            _=app.learner.answerPractice(key:run.key,questionID:q.id,correct:result.correct,reward:reward);app.persist()
        } catch is CancellationError { } catch { if token == generation { self.error=error.localizedDescription } }
    }
    func verdict(run:PracticeRun,recipes:PracticeRecipes,confidence:Double=0,audio:SpeechAudioMetrics?=nil,judge:(String) async throws ->String) async throws ->(correct:Bool,reward:Int?) {
        let q=run.question,p=q.payload,r=run.response
        var parameters:JSONValue = .object(["targetLang":.string(q.target),"supportLang":.string(q.support),"cefrLevel":.string(q.level),"hint":p["hint"]])
        var kind=""
        let words=r["indices"].array.compactMap { value -> String? in let i=Int(value.number);return run.bank.indices.contains(i) ? run.bank[i] : nil }
        if q.isDelight {
            parameters=parameters.setting("question",p).setting("response",r)
            if case .bool(let passed)=try recipes.inspect("grade",parameters:parameters) { return(passed,nil) }
            kind="judgeDelight"
        } else {
            switch q.kind {
            case "fill":kind="judgeFill";parameters=parameters.setting("question",p["question"]).setting("sentence",p["question"]).setting("level",.string(q.level)).setting("userAnswer",r["text"])
            case "mc":
                if (words.first ?? "") == p["answer"].string { return(true,nil) }
                kind="judgeMC";parameters=parameters.setting("stem",p["question"]).setting("choices",p["choices"]).setting("userChoice",.string(words.first ?? ""))
            case "ma":
                if Set(words) == Set(q.strings("answers")) { return(true,nil) }
                kind="judgeMA";parameters=parameters.setting("stem",p["question"]).setting("choices",p["choices"]).setting("userSelections",.array(words.map(JSONValue.string)))
            case "match":
                let pairs=q.strings("left").indices.map { [$0,Int(r["pairs"][String($0)].number)] }
                if q.module == .grammar { return(pairs.allSatisfy { $0[1] == Int(p["map"].array[$0[0]].number) },nil) }
                kind="judgeMatch";parameters=parameters.setting("stem",p["stem"]).setting("left",p["left"]).setting("right",p["right"]).setting("userPairs",.array(pairs.map { .array($0.map { .number(Double($0)) }) }))
            case "translate","repeat":
                if words.map(normalized) == q.strings("correctWords").map(normalized) { return(true,nil) }
                kind="judgeTranslate";parameters=parameters.setting("sourceLang",.string(q.sourceLanguage)).setting("answerLang",.string(q.answerLanguage)).setting("sentence",.string(q.kind == "repeat" && q.options["isListening"].boolean ? q.audioText : p["sentence"].string)).setting("correctWords",p["correctWords"]).setting("userWords",.array(words.map(JSONValue.string)))
            case "speak":return(StorySpeech.evaluate(recognized:r["text"].string,target:p["target"].string,lang:q.target,confidence:confidence,audio:audio).pass,nil)
            case "flashcard":kind="judgeFlashcard";parameters=parameters.setting("concept",p["concept"]).setting("userAnswer",r["text"])
            default:throw PracticeQuestionFailure.malformed
            }
        }
        let prompt=try recipes.build(module:q.module,kind:kind,parameters:parameters)
        let output=try await judge(prompt).trimmingCharacters(in:.whitespacesAndNewlines).uppercased()
        guard output.hasPrefix("YES") || output.hasPrefix("NO") else { throw PracticeQuestionFailure.malformed }
        let amount=output.split(separator:"|").dropFirst().first.flatMap { part -> Int? in
            let text=part.trimmingCharacters(in:.whitespacesAndNewlines)
            guard let range=text.range(of:"^[+-]?[0-9]+",options:.regularExpression) else { return nil };return Int(text[range])
        }
        return(output.hasPrefix("YES"),q.kind == "flashcard" ? amount.flatMap { (4...7).contains($0) ? $0 : nil } ?? 5 : nil)
    }
    private func normalized(_ text:String)->String { text.folding(options:[.diacriticInsensitive,.caseInsensitive],locale:Locale(identifier:"en_US_POSIX")).components(separatedBy:CharacterSet.alphanumerics.union(.whitespaces).union(CharacterSet(charactersIn:"'")).inverted).joined().split(whereSeparator:{$0.isWhitespace}).joined(separator:" ") }

}
extension LearnerState {
    var recipeUser:JSONValue {
        let elo:JSONValue = .object(["rating":.number(rating),"scaleVersion":.number(Double(PerformanceScore.version)),"totalGraded":.number(Double(gradedByLanguage?[target] ?? 0))])
        return .object(["learningIntelligence":.object([target:goalBucket.setting("elo",elo)]),"progress":.object(["targetLang":.string(target),"supportLang":.string(support),"cefrLevel":.string(level),"showTranslations":.bool(settingsSnapshot["progress"]["showTranslations"] != .bool(false))])])
    }
}
