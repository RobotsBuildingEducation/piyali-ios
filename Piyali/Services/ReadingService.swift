import Foundation
import FirebaseAILogic

@MainActor final class ReadingService:ObservableObject {
    @Published var busy=false
    @Published var error:String?
    private var generation=UUID()
    private var speechReview:Task<ReadingSpeechFeedback,Error>?
    private let speechGrader:(@MainActor (ReadingRun,String) async throws->ReadingSpeechFeedback)?
    init(speechGrader:(@MainActor (ReadingRun,String) async throws->ReadingSpeechFeedback)?=nil) { self.speechGrader=speechGrader }
    static var fixture:Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1" && UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil && ProcessInfo.processInfo.environment["PIYALI_READING_FIXTURE"] == "1"
        #else
        return false
        #endif
    }
    func cancel() { generation=UUID();speechReview?.cancel();speechReview=nil;busy=false }
    func prepare(_ app:AppModel,lesson:Lesson?,fresh:Bool) async {
        speechReview?.cancel();speechReview=nil
        let state=app.learner,account=app.identity.npub,target=state.target,support=state.support
        let authoredLevel=lesson?.cefrLevel ?? (lesson?.agenda["cefrLevel"].string.isEmpty == false ? lesson!.agenda["cefrLevel"].string : state.level)
        let fixed=lesson?.id == IntroTutorial.lessonID || lesson?.id.hasPrefix("goal-") == true || lesson?.id.hasPrefix("repair-") == true || lesson?.isFinalQuiz == true
        let level=fixed ? authoredLevel : PerformanceScore.level(score:state.score)
        if !fresh,let run=state.reading,run.support == support,run.lessonID == lesson?.id,run.level == level { return }
        guard app.subscription.hasAccess || Self.fixture else { return }
        let token=UUID();generation=token;busy=true;error=nil;defer { if generation == token { busy=false } }
        do {
            let recipes=try PracticeRecipes(),unit=app.units.first { $0.lessons.contains { $0.id == lesson?.id } } ?? (lesson?.id == IntroTutorial.lessonID ? app.introLibrary?.units[state.level] : nil)
            let curriculum=try PracticeCurriculum.context(lesson:lesson,unit:unit,target:target,recipes:recipes)
            let content=lesson?.content["reading"] ?? .null,tutorial=content["topic"].string == "tutorial",recent=state.readingHistory?[target] ?? []
            let selection=Reading.select(content:content,level:level,recent:recent,lesson:lesson?.id ?? "free",roll:Double.random(in:0..<1))
            var prepared:ReadingRun?;var failure:Error=ReadingFailure.invalid
            for attempt in 0..<(Self.fixture ? 1 : 3) {
                try Task.checkCancellation()
                do {
                    let payload:JSONValue
                    if Self.fixture { payload=try ContentLibrary.load(JSONValue.self,name:"reading-test-passage") }
                    else { payload=try await app.ai.readingPayload(state:state,lesson:lesson,level:level,selection:selection,recent:recent,tutorial:tutorial,repair:attempt > 0,curriculum:curriculum) }
                    var candidate=try ReadingRun(payload:payload,target:target,support:support,level:level,lessonID:lesson?.id,selection:selection,worth:.null,roll:Double.random(in:0..<1),method:Self.fixture ? (ProcessInfo.processInfo.environment["PIYALI_READING_SPEECH_FIXTURE"] == "1" ? "speech" : "question") : Bool.random() ? "question" : "speech",tutorial:Self.fixture ? false : tutorial,recent:Self.fixture ? [] : recent)
                    candidate.lessonLevel=authoredLevel
                    candidate.worth=Self.fixture ? try GeneratedQuestionWorth.fallback(level:level,learner:state,recipes:recipes) : try await GeneratedQuestionWorth.assess(question:.object(["passage":payload["target"],"reviewQuestion":payload["rawReviewQuestion"] == .null ? payload["reviewQuestion"] : payload["rawReviewQuestion"],"task":.string("Answer the review question about the passage")]),level:level,mode:"reading",learner:state,recipes:recipes,ai:app.ai)
                    prepared=candidate;break
                } catch { failure=error }
            }
            guard let run=prepared else { throw failure };try Task.checkCancellation()
            guard generation == token,app.identity.npub == account,app.learner.target == target,app.learner.support == support else { return }
            app.learner.saveReading(run)
            if app.learner.readingHistory == nil { app.learner.readingHistory=[:] }
            app.learner.readingHistory?[target]=Array(([run.historyEntry]+recent).prefix(30))
            while app.learner.readingHistory!.count > 1,(app.learner.readingHistory!.count > 3 || (try? JSONEncoder().encode(app.learner.readingHistory).count) ?? 0 > 96_000) { let old=app.learner.readingHistory!.keys.sorted().first { $0 != target }!;app.learner.readingHistory?.removeValue(forKey:old) }
            while (try? JSONEncoder().encode(app.learner.readingHistory).count) ?? 0 > 96_000,(app.learner.readingHistory?[target]?.count ?? 0) > 1 { app.learner.readingHistory?[target]?.removeLast() }
            app.persist()
        } catch is CancellationError { } catch { if generation == token { self.error=error.localizedDescription } }
    }
    func check(_ app:AppModel,run:ReadingRun,answer:String,speech:Bool) async {
        guard !busy,!run.awarded,app.learner.reading?.id == run.id,app.learner.reading?.awarded == false,app.learner.target == run.target,app.learner.support == run.support,!answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,app.subscription.hasAccess || Self.fixture else { return }
        let token=generation,account=app.identity.npub;busy=true;error=nil;defer { if token == generation { busy=false;speechReview=nil } }
        var correct=false,feedback="",speechFeedback:ReadingSpeechFeedback?
        do {
            if speech {
                let grader=speechGrader,task=Task { @MainActor in
                    if let grader { return try await grader(run,answer) }
                    if Self.fixture {
                        if ProcessInfo.processInfo.environment["PIYALI_READING_SPEECH_FAILURE"] == "1" { throw ReadingFailure.invalid }
                        return ReadingSpeechFeedback(try ContentLibrary.load(JSONValue.self,name:"reading-test-passage")["speechFeedback"]) ?? .unavailable(support:run.support)
                    }
                    return try await app.ai.readingSpeechFeedback(run:run,transcript:answer)
                };speechReview=task
                do { speechFeedback=try await withTaskCancellationHandler(operation:{ try await task.value },onCancel:{ task.cancel() }) }
                catch { try Task.checkCancellation();if task.isCancelled { throw CancellationError() };speechFeedback = .unavailable(support:run.support) }
                correct=true;feedback=speechFeedback?.summary ?? ""
            } else if run.question.type == "mc" || Self.fixture { correct=Reading.comparison(answer) == Reading.comparison(run.question.answer);feedback=EntryCopy.ui(run.support,correct ? "history_correct" : "history_not_quite") }
            else {
                let p:JSONValue = .object(["passage":.string(run.text),"reviewQuestion":.object(["question":.string(run.question.question),"answer":.string(run.question.answer)]),"answer":.string(String(answer.prefix(4000)))])
                do {
                    let response=try await app.ai.text(try PracticeRecipes().reading("judge",parameters:p),json:true)
                    let result=try GenerationObjects.parse(response).first ?? .null;guard case .bool(let passed)=result["correct"] else { throw ReadingFailure.invalid };correct=passed
                } catch { try Task.checkCancellation();correct=Reading.comparison(answer) == Reading.comparison(run.question.answer) }
                feedback=EntryCopy.ui(run.support,correct ? "history_correct" : "history_not_quite")
            }
            try Task.checkCancellation();guard generation == token,app.identity.npub == account,app.learner.target == run.target,app.learner.support == run.support,app.learner.reading?.id == run.id else { return }
            _=app.learner.reviewReading(answer:answer,correct:correct,feedback:feedback,speech:speech,speechFeedback:speechFeedback);app.persist()
        } catch is CancellationError { } catch { if generation == token { self.error=error.localizedDescription } }
    }
    func explain(_ app:AppModel,run:ReadingRun) async {
        guard !busy,run.correct != nil,run.explanation == nil,app.subscription.hasAccess || Self.fixture else { return }
        let token=generation,account=app.identity.npub;busy=true;error=nil;defer { if generation == token { busy=false } }
        do {
            let parameters:JSONValue = .object(["targetLang":.string(run.target),"supportLang":.string(run.support),"reviewQuestion":.object(["question":.string(run.question.question),"answer":.string(run.question.answer)]),"answer":.string(run.answer)])
            let output=Self.fixture ? "The notebook is left on the table to remember the plan with the narrator's sister. The passage says they want to draw another plant tomorrow." : try await app.ai.text(try PracticeRecipes().reading("explain",parameters:parameters))
            try Task.checkCancellation();guard token == generation,account == app.identity.npub,app.learner.target == run.target,app.learner.support == run.support,var current=app.learner.reading,current.id == run.id else { return }
            current.explanation=String(output.prefix(6000));app.learner.saveReading(current);app.persist()
        } catch is CancellationError { } catch { if generation == token { self.error=error.localizedDescription } }
    }
    func translate(_ app:AppModel,run:ReadingRun) async {
        guard !busy,run.translation == nil,run.lineTranslations == nil,app.subscription.hasAccess || Self.fixture else { return }
        let token=generation,account=app.identity.npub;busy=true;error=nil;defer { if generation == token { busy=false } }
        do {
            let sentences=Reading.displaySentences(run.text)
            let prompt=try PracticeRecipes().reading("translate",parameters:.object(["targetLang":.string(run.target),"supportLang":.string(run.support),"sentences":.array(sentences.map(JSONValue.string))]))
            let output=Self.fixture ? (try ContentLibrary.load(JSONValue.self,name:"reading-test-passage"))["translations"].array.map(\.string).joined(separator:"\n") : try await app.ai.text(prompt)
            let lines=output.components(separatedBy:.newlines).map { $0.replacingOccurrences(of:"^\\s*\\d+[\\).:-]\\s*",with:"",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines) }.filter { !$0.isEmpty }
            guard lines.count == sentences.count else { throw AppError.message(EntryCopy.ui(run.support,"try_again")) }
            try Task.checkCancellation();guard token == generation,account == app.identity.npub,app.learner.target == run.target,app.learner.support == run.support,var current=app.learner.reading,current.id == run.id else { return }
            current.lineTranslations=lines;app.learner.saveReading(current);app.persist()
        } catch is CancellationError { } catch { if generation == token { self.error=error.localizedDescription } }
    }
}
extension AIService {
    func readingSpeechFeedback(run:ReadingRun,transcript:String) async throws->ReadingSpeechFeedback {
        let prompt=try PracticeRecipes().reading("speech",parameters:.object(["passage":.string(run.text),"answer":.string(ReadingSpeechCapture.boundedTranscript(transcript)),"targetLang":.string(run.target),"supportLang":.string(run.support)]))
        let raw:String
        if configuration.string("AIProvider") == "gemini",FirebaseService.shared.configured {
            let model=FirebaseAI.firebaseAI(backend:configuration.geminiBackend()).generativeModel(modelName:configuration.string("GeminiModel"),generationConfig:GenerationConfig(maxOutputTokens:4096,responseMIMEType:"application/json",thinkingConfig:ThinkingConfig(thinkingBudget:1024)))
            raw=try await model.generateContent(prompt).text ?? ""
        } else { raw=try await responsesText(prompt,json:true) }
        try Task.checkCancellation()
        guard let object=try GenerationObjects.parse(raw).first,let feedback=ReadingSpeechFeedback(object) else { throw ReadingFailure.invalid };return feedback
    }
    func readingPayload(state:LearnerState,lesson:Lesson?,level:String,selection:JSONValue,recent:[JSONValue],tutorial:Bool,repair:Bool,curriculum:JSONValue = .null) async throws -> JSONValue {
        let recipes=try PracticeRecipes(),type=["text","fill","mc"].randomElement()!
        var content=PracticeCurriculum.content(lesson,mode:"reading",context:curriculum)
        if tutorial { content=content.setting("topic",.string("tutorial")) }
        let titles=recent.compactMap { $0["title"].string.isEmpty ? nil : $0["title"].string }
        let parameters:JSONValue = .object(["targetLang":.string(state.target),"supportLang":.string(state.support),"cefrLevel":.string(level),"lessonContent":content,"reviewQuestionType":.string(type),"previousTitles":.array(titles.map(JSONValue.string)),"isFirst":.bool(titles.isEmpty),"user":state.recipeUser])
        var prompt=try recipes.reading("passage",parameters:parameters)
        // The native parser consumes the source NDJSON protocol after completion.
        if repair { prompt += "\nPrevious generation failed validation. Return a fresh, complete passage and valid grounded question using the specified protocol." }
        return try Reading.protocolPayload(try await text(ReadingRules.data["writer"].string+"\n"+prompt),questionType:type)
    }
}
