import Foundation
import FirebaseAILogic

@MainActor final class ReadingService:ObservableObject {
    @Published var busy=false
    @Published var error:String?
    @Published private(set) var generating=false
    @Published private(set) var draft:ReadingStreamDraft?
    @Published private(set) var suppressedPrevious=false
    @Published private(set) var translationPreview:[String]?
    @Published private(set) var translationLoading=false
    private var translationRequest:UUID?
    private var translationResult:(runID:UUID,visible:Bool)?
    @Published private(set) var questionGenerating=false
    @Published private(set) var questionFailed=false
    private var attemptedQuestions=Set<UUID>()
    private var questionTask:Task<ReadingQuestion,Error>?
    private var translationOwner:UUID?
    private var generation=UUID()
    private var speechReview:Task<ReadingSpeechFeedback,Error>?
    private var writing:Task<JSONValue,Error>?
    private var translating:Task<String,Error>?
    // Like the web's component-local lectures, this is not restored across mounts.
    private var lastGeneration:(account:String,runID:UUID,createdAt:Date)?
    #if DEBUG
    private var fixtureGenerations=0
    private var fixtureTranslations=0
    #endif
    private let now:@MainActor ()->Date
    private let passageWriter:(@MainActor (@escaping @MainActor (String)->Void) async throws->JSONValue)?
    private let translationWriter:(@MainActor (String,@escaping @MainActor (String)->Void) async throws->String)?
    private let speechGrader:(@MainActor (ReadingRun,String) async throws->ReadingSpeechFeedback)?
    init(speechGrader:(@MainActor (ReadingRun,String) async throws->ReadingSpeechFeedback)?=nil,now:@escaping @MainActor ()->Date={Date()},passageWriter:(@MainActor (@escaping @MainActor (String)->Void) async throws->JSONValue)?=nil,translationWriter:(@MainActor (String,@escaping @MainActor (String)->Void) async throws->String)?=nil) { self.speechGrader=speechGrader;self.now=now;self.passageWriter=passageWriter;self.translationWriter=translationWriter }
    static var fixture:Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1" && UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil && ProcessInfo.processInfo.environment["PIYALI_READING_FIXTURE"] == "1"
        #else
        return false
        #endif
    }
    func cancel() { generation=UUID();questionTask?.cancel();questionTask=nil;questionGenerating=false;writing?.cancel();writing=nil;translating?.cancel();translating=nil;translationPreview=nil;translationOwner=nil;translationRequest=nil;translationResult=nil;translationLoading=false;speechReview?.cancel();speechReview=nil;busy=false;generating=false;draft=nil }
    func prepare(_ app:AppModel,lesson:Lesson?,fresh:Bool) async {
        writing?.cancel();writing=nil;translating?.cancel();translating=nil;translationPreview=nil;translationOwner=nil;translationRequest=nil;translationResult=nil;translationLoading=false;speechReview?.cancel();speechReview=nil
        let state=app.learner,account=app.identity.npub,target=state.target,support=state.support
        let authoredLevel=lesson?.cefrLevel ?? (lesson?.agenda["cefrLevel"].string.isEmpty == false ? lesson!.agenda["cefrLevel"].string : state.level)
        let fixed=lesson?.id == IntroTutorial.lessonID || lesson?.id.hasPrefix("goal-") == true || lesson?.id.hasPrefix("repair-") == true || lesson?.isFinalQuiz == true
        let level=fixed ? authoredLevel : PerformanceScore.level(score:state.score)
        if !fresh,let run=state.reading,run.support == support,run.lessonID == lesson?.id,run.level == level { suppressedPrevious=false;return }
        guard app.subscription.hasAccess || Self.fixture else { return }
        questionTask?.cancel();questionTask=nil;questionGenerating=false;questionFailed=false
        let token=UUID();generation=token;busy=true;generating=true;suppressedPrevious=true;draft=nil;error=nil;defer { if generation == token { busy=false;generating=false;draft=nil;writing=nil } }
        do {
            let recipes=try PracticeRecipes(),unit=app.units.first { $0.lessons.contains { $0.id == lesson?.id } } ?? (lesson?.id == IntroTutorial.lessonID ? app.introLibrary?.units[state.level] : nil)
            let curriculum=try PracticeCurriculum.context(lesson:lesson,unit:unit,target:target,recipes:recipes)
            let content=lesson?.content["reading"] ?? .null,tutorial=content["topic"].string == "tutorial",recent=state.readingHistory?[target] ?? []
            let selection=Reading.select(content:content,level:level,recent:recent,lesson:lesson?.id ?? "free",roll:Double.random(in:0..<1))
            draft=nil
            let task=Task { @MainActor [weak self] () throws ->JSONValue in
                guard let self else{throw CancellationError()}
                let publish:@MainActor (String)->Void = { [weak self] snapshot in
                    guard let self,self.generation == token,app.identity.npub == account,app.learner.target == target,app.learner.support == support else{return}
                    let next=ReadingStreamDraft.parse(snapshot,target:target,support:support);if next != self.draft {self.draft=next}
                }
                if let writer=self.passageWriter {return try await writer(publish)}
                if Self.fixture {
                    let payload:JSONValue=try ContentLibrary.load(JSONValue.self,name:"reading-test-passage")
                    #if DEBUG
                    if ProcessInfo.processInfo.environment["PIYALI_READING_GENERATION_FAILURE_FIXTURE"] == "1" {
                        self.fixtureGenerations += 1
                        if self.fixtureGenerations == 1 {throw ReadingFailure.invalid}
                    }
                    if ProcessInfo.processInfo.environment["PIYALI_READING_MISSING_QUESTION_FIXTURE"] == "1" {
                        let records=[JSONValue.object(["type":.string("title"),"text":payload["title"]]),.object(["type":.string("target"),"text":payload["target"]]),.object(["type":.string("takeaway"),"text":payload["takeaways"].array[0]])]
                        guard let partial=ReadingStreamDraft.sourcePayload(records.map(\.json).joined(separator:"\n"),target:target,support:support,questionType:"mc") else{throw ReadingFailure.invalid};return partial
                    }
                    if ProcessInfo.processInfo.environment["PIYALI_READING_STREAM_FIXTURE"] == "1" {
                        let lines=[JSONValue.object(["type":.string("title"),"text":payload["title"]]),.object(["type":.string("target"),"text":payload["target"]])]
                        var snapshot=""
                        for line in lines {
                            try Task.checkCancellation();guard self.generation == token,app.identity.npub == account,app.learner.target == target,app.learner.support == support else{throw CancellationError()}
                            snapshot += line.json+"\n";self.draft=ReadingStreamDraft.parse(snapshot,target:target,support:support)
                            try await Task.sleep(for:.seconds(8))
                        }
                    }
                    #endif
                    return payload
                }
                return try await app.ai.readingPayload(state:state,lesson:lesson,level:level,selection:selection,recent:recent,tutorial:tutorial,repair:false,curriculum:curriculum,onChunk:publish)
            }
            writing=task
            let payload=try await withTaskCancellationHandler(operation:{try await task.value},onCancel:{task.cancel()})
            try Task.checkCancellation();guard generation == token,app.identity.npub == account,app.learner.target == target,app.learner.support == support else{return}
            if generation == token {writing=nil}
            var run=try ReadingRun(payload:payload,target:target,support:support,level:level,lessonID:lesson?.id,selection:selection,worth:.null,roll:Double.random(in:0..<1),method:Self.fixture ? (ProcessInfo.processInfo.environment["PIYALI_READING_SPEECH_FIXTURE"] == "1" ? "speech" : "question") : Bool.random() ? "question" : "speech",tutorial:Self.fixture ? false : tutorial,recent:Self.fixture ? [] : recent)
            run.lessonLevel=authoredLevel
            run.worth=Self.fixture ? try GeneratedQuestionWorth.fallback(level:level,learner:state,recipes:recipes) : try await GeneratedQuestionWorth.assess(question:.object(["passage":payload["target"],"reviewQuestion":payload["rawReviewQuestion"] == .null ? payload["reviewQuestion"] : payload["rawReviewQuestion"],"task":.string("Answer the review question about the passage")]),level:level,mode:"reading",learner:state,recipes:recipes,ai:app.ai)
            try Task.checkCancellation()
            guard generation == token,app.identity.npub == account,app.learner.target == target,app.learner.support == support else { return }
            let createdAt=now()
            if let previous=lastGeneration,previous.account == account,let current=app.learner.reading,current.id == previous.runID,current.support == support,current.lessonID == lesson?.id,current.level == level,
               Reading.isDuplicateOfLast(title:run.title,target:run.text,last:.object(["title":.string(current.title),"target":.string(current.text),"createdAtClient":.number(previous.createdAt.timeIntervalSince1970*1000)]),now:createdAt) {
                suppressedPrevious=false;return
            }
            lastGeneration=(account,run.id,createdAt)
            app.learner.saveReading(run);suppressedPrevious=false
            if app.learner.readingHistory == nil { app.learner.readingHistory=[:] }
            app.learner.readingHistory?[target]=Array(([run.historyEntry]+recent).prefix(30))
            while app.learner.readingHistory!.count > 1,(app.learner.readingHistory!.count > 3 || (try? JSONEncoder().encode(app.learner.readingHistory).count) ?? 0 > 96_000) { let old=app.learner.readingHistory!.keys.sorted().first { $0 != target }!;app.learner.readingHistory?.removeValue(forKey:old) }
            while (try? JSONEncoder().encode(app.learner.readingHistory).count) ?? 0 > 96_000,(app.learner.readingHistory?[target]?.count ?? 0) > 1 { app.learner.readingHistory?[target]?.removeLast() }
            app.persist()
        } catch is CancellationError { } catch { if generation == token,app.identity.npub == account,app.learner.target == target,app.learner.support == support { self.error=Reading.generationFailure(support:support) } }
    }
    func ensureReviewQuestion(_ app:AppModel,run:ReadingRun,retry:Bool=false) async {
        guard let type=run.pendingQuestionType,!run.text.isEmpty,!questionGenerating,(retry || !attemptedQuestions.contains(run.id)),app.learner.reading?.id == run.id,app.learner.target == run.target,app.learner.support == run.support,app.subscription.hasAccess || Self.fixture else{return}
        attemptedQuestions.insert(run.id);questionGenerating=true;questionFailed=false;let token=generation,account=app.identity.npub
        defer{if token == generation{questionGenerating=false;questionTask=nil}}
        do {
            let task=Task { @MainActor () throws ->ReadingQuestion in
                if Self.fixture {
                    if ProcessInfo.processInfo.environment["PIYALI_READING_QUESTION_FALLBACK_FAILURE"] == "1" {throw ReadingFailure.invalid}
                    if ProcessInfo.processInfo.environment["PIYALI_READING_MISSING_QUESTION_FIXTURE"] == "1" {try await Task.sleep(for:.seconds(2))}
                    let fixture=try ContentLibrary.load(JSONValue.self,name:"reading-test-passage")["reviewQuestion"]
                    guard let value=ReadingQuestion(fixture,expectedType:type) else{throw ReadingFailure.invalid};return value
                }
                let raw=try await app.ai.text(Reading.reviewPrompt(type:type,text:run.text,target:run.target,support:run.support))
                guard let object=try GenerationObjects.parse(raw).first,let value=ReadingQuestion(object,expectedType:type) else{throw ReadingFailure.invalid};return value
            };questionTask=task
            let question=try await withTaskCancellationHandler(operation:{try await task.value},onCancel:{task.cancel()});try Task.checkCancellation()
            guard generation == token,app.identity.npub == account,app.learner.target == run.target,app.learner.support == run.support,let current=app.learner.reading,current.id == run.id,current.pendingQuestionType == type else{return}
            let recipes=try PracticeRecipes(),value=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(question))
            let worth=Self.fixture ? try GeneratedQuestionWorth.fallback(level:run.level,learner:app.learner,recipes:recipes) : try await GeneratedQuestionWorth.assess(question:.object(["passage":.string(run.text),"reviewQuestion":value]),level:run.level,mode:"reading_review",learner:app.learner,recipes:recipes,ai:app.ai)
            try Task.checkCancellation();guard generation == token,app.identity.npub == account,app.learner.target == run.target,app.learner.support == run.support,var latest=app.learner.reading,latest.id == run.id,latest.pendingQuestionType == type else{return}
            latest.question=question;latest.pendingQuestionType=nil;latest.worth=worth;app.learner.saveReading(latest);app.persist()
        } catch is CancellationError {attemptedQuestions.remove(run.id)} catch {if generation == token,app.identity.npub == account,app.learner.reading?.id == run.id{questionFailed=true}}
    }
    func check(_ app:AppModel,run:ReadingRun,answer:String,speech:Bool,lesson:Lesson?=nil) async {
        guard app.goalPracticeIsCurrent(lesson),!busy,!run.awarded,(speech || run.pendingQuestionType == nil),app.learner.reading?.id == run.id,app.learner.reading?.awarded == false,app.learner.target == run.target,app.learner.support == run.support,!answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,app.subscription.hasAccess || Self.fixture else { return }
        let token=generation,account=app.identity.npub,identitySession=app.identity.sessionRevision;busy=true;error=nil;defer { if token == generation { busy=false;speechReview=nil } }
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
            try Task.checkCancellation();guard app.goalPracticeIsCurrent(lesson),app.identity.sessionRevision == identitySession,generation == token,app.identity.npub == account,app.learner.target == run.target,app.learner.support == run.support,app.learner.reading?.id == run.id else { return }
            _=app.learner.reviewReading(answer:answer,correct:correct,feedback:feedback,speech:speech,speechFeedback:speechFeedback,goalFocus:app.goalMemoryFocus(lesson));app.persist()
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
    func translationLines(for id:UUID)->[String]? {translationOwner == id ? translationPreview:nil}
    func translationVisibility(for id:UUID)->Bool? {translationResult?.runID == id ? translationResult?.visible:nil}
    @discardableResult func translate(_ app:AppModel,run:ReadingRun) async ->Bool {
        guard app.learner.target == run.target,app.learner.support == run.support,app.learner.reading?.id == run.id else{return false}
        if run.translation != nil || run.lineTranslations != nil {return true}
        let sentences=Reading.displaySentences(run.text)
        guard !translationLoading,!sentences.isEmpty,app.subscription.hasAccess || Self.fixture else{return false}
        let token=generation,account=app.identity.npub,request=UUID()
        translationRequest=request;translationLoading=true;translationOwner=run.id;translationPreview=[];translationResult=nil
        defer {if token == generation,translationRequest == request {translationLoading=false;translating=nil;translationPreview=nil;translationOwner=nil;translationRequest=nil}}
        func ownsRequest()->Bool {token == generation && translationRequest == request && account == app.identity.npub && app.learner.target == run.target && app.learner.support == run.support && app.learner.reading?.id == run.id}
        do {
            let prompt=try PracticeRecipes().reading("translate",parameters:.object(["targetLang":.string(run.target),"supportLang":.string(run.support),"sentences":.array(sentences.map(JSONValue.string))]))
            let task=Task { @MainActor [weak self] () throws ->String in
                guard let self else{throw CancellationError()}
                let publish:@MainActor (String)->Void = {[weak self] snapshot in
                    guard let self,ownsRequest() else{return}
                    let next=ReadingTranslationStream.lines(snapshot,limit:sentences.count);if next != self.translationPreview {self.translationPreview=next}
                }
                if let writer=self.translationWriter {return try await writer(prompt,publish)}
                if Self.fixture {
                    let lines=(try ContentLibrary.load(JSONValue.self,name:"reading-test-passage"))["translations"].array.map(\.string)
                    #if DEBUG
                    let failure=ProcessInfo.processInfo.environment["PIYALI_READING_TRANSLATION_FAILURE_FIXTURE"] ?? ""
                    if ["throw","incomplete"].contains(failure) {
                        self.fixtureTranslations += 1
                        if self.fixtureTranslations == 1 {
                            let snapshot=lines[0]+"\n";publish(snapshot);try await Task.sleep(for:.seconds(4))
                            if failure == "incomplete" {return snapshot};throw ReadingFailure.invalid
                        }
                    }
                    if ProcessInfo.processInfo.environment["PIYALI_READING_TRANSLATION_STREAM_FIXTURE"] == "1" {
                        var snapshot=""
                        for line in lines {
                            try Task.checkCancellation();guard ownsRequest() else{throw CancellationError()}
                            snapshot += line+"\n";publish(snapshot)
                            try await Task.sleep(for:.milliseconds(500))
                        }
                    }
                    #endif
                    return lines.joined(separator:"\n")
                }
                return try await app.ai.readingStreamText(prompt,onChunk:publish)
            }
            translating=task
            let output=try await withTaskCancellationHandler(operation:{try await task.value},onCancel:{task.cancel()})
            try Task.checkCancellation();guard ownsRequest(),var current=app.learner.reading else{return false}
            let resolution=ReadingTranslationStream.resolve(output,limit:sentences.count,failed:false)
            translationResult=(run.id,resolution.visible)
            guard let lines=resolution.lines else{return false}
            current.lineTranslations=lines;app.learner.saveReading(current);app.persist();return true
        } catch is CancellationError {return false} catch {
            if ownsRequest(){translationResult=(run.id,ReadingTranslationStream.resolve("",limit:sentences.count,failed:true).visible)}
            return false
        }
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
    func readingPayload(state:LearnerState,lesson:Lesson?,level:String,selection:JSONValue,recent:[JSONValue],tutorial:Bool,repair:Bool,curriculum:JSONValue = .null,onChunk:@escaping @MainActor(String)->Void = {_ in}) async throws -> JSONValue {
        let recipes=try PracticeRecipes(),type=["text","fill","mc"].randomElement()!
        var content=PracticeCurriculum.content(lesson,mode:"reading",context:curriculum)
        if tutorial { content=content.setting("topic",.string("tutorial")) }
        let titles=recent.compactMap { $0["title"].string.isEmpty ? nil : $0["title"].string }
        let parameters:JSONValue = .object(["targetLang":.string(state.target),"supportLang":.string(state.support),"cefrLevel":.string(level),"lessonContent":content,"reviewQuestionType":.string(type),"previousTitles":.array(titles.map(JSONValue.string)),"isFirst":.bool(titles.isEmpty),"user":state.recipeUser])
        var prompt=try recipes.reading("passage",parameters:parameters)
        if repair { prompt += "\nPrevious generation failed validation. Return a fresh, complete passage and valid grounded question using the specified protocol." }
        var fallbackAttempts=1
        do {
            let output=try await readingStreamText(ReadingRules.data["writer"].string+"\n"+prompt,onChunk:onChunk)
            try Task.checkCancellation()
            onChunk(output+"\n") // Include a complete final record without a trailing newline.
            if let payload=ReadingStreamDraft.sourcePayload(output,target:state.target,support:state.support,questionType:type) {return payload}
            fallbackAttempts=2 // The source catch retries a failed no-reveal backend request.
        } catch is CancellationError {throw CancellationError()} catch {try Task.checkCancellation()}
        // A failed or empty stream uses the source's JSON backend prompt, rather
        // than asking a second provider for another NDJSON stream.
        let backendPrompt=ReadingRules.data["writer"].string+"\n"+(try recipes.reading("backendPassage",parameters:parameters))
        for attempt in 0..<fallbackAttempts {
            do {
                let raw:String
                #if DEBUG
                if let override=readingBackendOverride {raw=try await override(backendPrompt)}
                else {raw=try await text(backendPrompt)}
                #else
                raw=try await text(backendPrompt)
                #endif
                try Task.checkCancellation()
                guard let object=try GenerationObjects.parse(raw).first,let payload=ReadingStreamDraft.backendPayload(object,target:state.target,support:state.support,questionType:type) else{throw ReadingFailure.invalid};return payload
            } catch is CancellationError {throw CancellationError()} catch {
                try Task.checkCancellation();if attempt+1 == fallbackAttempts {throw error}
            }
        }
        throw ReadingFailure.invalid
    }
}


extension AIService {
    /// One provider stream. Callers own completion and failure policy; a normal
    /// empty end stays distinct from a thrown request. No hidden provider retry.
    func readingStreamText(_ prompt:String,onChunk:@escaping @MainActor(String)->Void) async throws ->String {
        #if DEBUG
        if let override=readingStreamOverride {return try await override(prompt,onChunk)}
        #endif
        if configuration.string("AIProvider") == "gemini",FirebaseService.shared.configured {
            let model=FirebaseAI.firebaseAI(backend:configuration.geminiBackend()).generativeModel(modelName:configuration.string("GeminiModel"),generationConfig:GenerationConfig(temperature:0.7,maxOutputTokens:4096))
            var output=""
            for try await chunk in try model.generateContentStream(prompt) {
                try Task.checkCancellation()
                output += chunk.text ?? ""
                guard output.utf8.count <= 100_000 else{throw ReadingFailure.invalid}
                onChunk(output)
            }
            return output
        }
        return try await responsesStream(prompt,onChunk:onChunk)
    }
}
