import Foundation
import CryptoKit
import FirebaseAILogic

@MainActor final class StoryService:ObservableObject {
    @Published var busy=false
    @Published var error:String?
    @Published private(set) var activeRunID:UUID?
    @Published private(set) var provisional:StoryRun?
    private var generation=UUID()
    private var preparation:Task<Bool,Never>?
    struct Request { let mode:StoryMode;let lesson:Lesson?;let state:LearnerState;let level:String;let tutorial:Bool;let recent:[JSONValue];let unit:LearningUnit?;let account:String }
    private let writer:(@MainActor (Request) async throws->JSONValue)?
    init(writer:(@MainActor (Request) async throws->JSONValue)?=nil) { self.writer=writer }
    static func authoredLevel(_ lesson:Lesson?,learnerLevel:String)->String {
        lesson?.cefrLevel ?? (lesson?.agenda["cefrLevel"].string.isEmpty == false ? lesson!.agenda["cefrLevel"].string : learnerLevel)
    }
    static func contextID(_ lesson:Lesson?,learnerLevel:String)throws->String {
        SHA256.hash(data:try StoryRun.contextData(content:lesson?.content["stories"] ?? .null,agenda:lesson?.agenda ?? .null,level:authoredLevel(lesson,learnerLevel:learnerLevel))).map { String(format:"%02x",$0) }.joined()
    }
    static var fixtureMode:StoryMode? {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { return nil }
        return StoryMode(rawValue:ProcessInfo.processInfo.environment["PIYALI_STORY_FIXTURE"] ?? "")
        #else
        return nil
        #endif
    }
    func cancel() { generation=UUID();preparation?.cancel();preparation=nil;busy=false;provisional=nil }
    func updateProvisional(_ id:UUID,_ change:(inout StoryRun)->Void) {
        guard var run=provisional,run.id == id else{return};change(&run);provisional=run
    }
    func prepare(_ app:AppModel,lesson:Lesson?,mode:StoryMode,fresh:Bool) async ->Bool {
        preparation?.cancel()
        let request=Task { @MainActor in await load(app,lesson:lesson,mode:mode,fresh:fresh) }
        preparation=request
        return await withTaskCancellationHandler(operation:{ await request.value },onCancel:{ request.cancel() })
    }
    private static func makeProvisional(previous:StoryRun?,id:UUID,turns:[StoryTurn],state:LearnerState,level:String,lesson:Lesson?,title:String)->StoryRun {
        var run=StoryRun(provisionalID:id,turns:turns,target:state.target,support:state.support,level:level,lessonID:lesson?.id,title:title,worth:ConversationPractice.worth(rating:state.rating,level:level))
        var portraits=previous?.id == id ? (previous?.portraitIDs ?? [:]) : [:]
        for name in Set(turns.map(\.speaker)) where portraits[name] == nil {portraits[name]=StoryCharacterAvatar.appearance.portraitPool(name,learnerName:state.name).randomElement() ?? "35"}
        run.portraitIDs=portraits;if previous?.id == id {run.updatedAt=previous!.updatedAt};return run
    }
    private static func makeProvisionalEpisode(previous:StoryRun?,id:UUID,draft:StoryStreamDraft.Episode,mode:StoryMode,state:LearnerState,level:String,lesson:Lesson?)->StoryRun {
        var run=StoryRun(provisionalID:id,episode:draft.value,ready:draft.ready,mode:mode,target:state.target,support:state.support,level:level,lessonID:lesson?.id,worth:ConversationPractice.worth(rating:state.rating,level:level))
        if let previous,previous.id == id {
            run.index=previous.index;run.answers=previous.answers;run.results=previous.results;run.heard=previous.heard;run.translations=previous.translations;run.portraitIDs=previous.portraitIDs;run.updatedAt=previous.updatedAt
        }
        var portraits=run.portraitIDs ?? [:]
        for name in Set(draft.value.segments.flatMap { $0.turns.map(\.speaker) }) where portraits[name] == nil {portraits[name]=StoryCharacterAvatar.appearance.portraitPool(name,learnerName:state.name).randomElement() ?? "35"}
        run.portraitIDs=portraits;return run
    }
    private static func extends(_ previous:StoryRun,_ draft:StoryStreamDraft.Episode)->Bool {
        guard let old=previous.episode,old.segments.count <= draft.value.segments.count else{return false}
        for (index,segment) in old.segments.enumerated() {
            let next=draft.value.segments[index]
            guard next.turns.starts(with:segment.turns) else{return false}
            if previous.provisionalQuestions?.contains(index) == true,(!draft.ready.contains(index) || segment.question != next.question) {return false}
        }
        return true
    }
    static func promoteEpisode(_ draft:StoryRun,into run:inout StoryRun)->Bool {
        guard let partial=draft.episode,let final=run.episode,partial.segments.count <= final.segments.count else{return false}
        for (index,segment) in partial.segments.enumerated() {
            guard final.segments[index].turns.starts(with:segment.turns) else{return false}
            if draft.provisionalQuestions?.contains(index) == true,segment.question != final.segments[index].question {return false}
        }
        guard draft.index <= run.count else{return false}
        run.id=draft.id;run.index=draft.index;run.answers=draft.answers;run.results=draft.results;run.heard=draft.heard;run.translations=draft.translations
        return true
    }
    private func load(_ app:AppModel,lesson:Lesson?,mode:StoryMode,fresh:Bool) async ->Bool {
        guard !Task.isCancelled else { return false }
        let token=UUID();generation=token;busy=false;activeRunID=nil;provisional=nil;error=nil
        let account=app.identity.npub,target=app.learner.target,support=app.learner.support
        let authoredLevel=Self.authoredLevel(lesson,learnerLevel:app.learner.level)
        let fixed=lesson?.id == IntroTutorial.lessonID || lesson?.isFinalQuiz == true || lesson?.id.hasPrefix("goal-") == true || lesson?.id.hasPrefix("repair-") == true
        let level=mode != .speaking || fixed ? authoredLevel : PerformanceScore.level(score:app.learner.score)
        let sourceContext:String
        do { sourceContext=try Self.contextID(lesson,learnerLevel:app.learner.level) }
        catch { self.error=error.localizedDescription;return false }
        if !fresh,let run=app.learner.story,run.target == target,run.support == support,run.lessonID == lesson?.id,run.mode == mode,run.sourceContext.map({ $0 == sourceContext }) ?? ((run.lessonLevel ?? run.level) == authoredLevel),run.index >= 0,run.index <= run.count {
            if run.mode == .speaking || (try? run.episode?.validate(target:target)) != nil { activeRunID=run.id;error=nil;return true }
        }
        guard app.subscription.hasAccess || Self.fixtureMode != nil else { return false }
        busy=true
        defer { if generation == token { busy=false;provisional=nil } }
        let state=app.learner,tutorial=lesson?.id == IntroTutorial.lessonID || lesson?.content["stories"]["topic"].string == "tutorial" || !(lesson?.content["stories"]["tutorialPracticeLevel"].string ?? "").isEmpty
        do {
            var payload:JSONValue
            if Self.fixtureMode != nil {
                #if DEBUG
                if let delay=Int(ProcessInfo.processInfo.environment["PIYALI_STORY_GENERATION_DELAY_MS"] ?? ""),(1...10_000).contains(delay) { try await Task.sleep(for:.milliseconds(delay)) }
                #endif
                payload=try ContentLibrary.load(JSONValue.self,name:"story-test-episode")
                #if DEBUG
                if ProcessInfo.processInfo.environment["PIYALI_STORY_LEARNER_CAST"] == "1" { var segments=payload["segments"].array.map { segment in segment.setting("turns",.array(segment["turns"].array.map { $0["speaker"].string == "Luis" ? $0.setting("speaker",.string("You")) : $0 })) }
                    if !segments.isEmpty { segments[0]=segments[0].setting("turns",.array(segments[0]["turns"].array+[.object(["speaker":.string("Ana"),"target":.string("Vamos a visitarla."),"support":.string("Let's visit her.")])])) }
                    payload=payload.setting("segments",.array(segments)) }
                #endif
                if mode == .speaking {
                    var lines=payload["segments"].array.flatMap { $0["turns"].array }
                    #if DEBUG
                    if target == "ja",ProcessInfo.processInfo.environment["PIYALI_STORY_JAPANESE_FIXTURE"] == "1" {lines=lines.map {$0.setting("target",.string("今日は母の誕生日です"))}}
                    #endif
                    payload = .object(["title":payload["title"],"sentences":.array(tutorial ? Array(lines.prefix(2)) : Array((lines+lines).prefix(10)))])
                    if ProcessInfo.processInfo.environment["PIYALI_STORY_STREAM_FIXTURE"] == "1" {
                        let id=UUID();var available:[StoryTurn]=[]
                        for line in payload["sentences"].array.prefix(2) {
                            try Task.checkCancellation();guard generation == token,app.identity.npub == account,app.learner.target == target,app.learner.support == support else{return false}
                            let turn=try JSONDecoder().decode(StoryTurn.self,from:JSONEncoder().encode(line));available.append(turn)
                            provisional=Self.makeProvisional(previous:provisional,id:id,turns:available,state:state,level:level,lesson:lesson,title:payload["title"].string)
                            try await Task.sleep(for:.seconds(8))
                        }
                    }
                } else if ProcessInfo.processInfo.environment["PIYALI_STORY_STREAM_FIXTURE"] == "1" {
                    let episode=try StoryEpisode.parse(payload,target:target,prepare:true),id=UUID()
                    var segments=[StorySegment(turns:episode.segments[0].turns,question:episode.segments[0].question)]
                    provisional=Self.makeProvisionalEpisode(previous:nil,id:id,draft:.init(value:.init(title:episode.title,segments:segments),ready:[]),mode:mode,state:state,level:level,lesson:lesson)
                    try await Task.sleep(for:.seconds(8))
                    segments=episode.segments
                    provisional=Self.makeProvisionalEpisode(previous:provisional,id:id,draft:.init(value:.init(title:episode.title,segments:segments),ready:Set(segments.indices)),mode:mode,state:state,level:level,lesson:lesson)
                    try await Task.sleep(for:.seconds(25))
                }
            } else {
                let unit=app.units.first { $0.lessons.contains { $0.id == lesson?.id } } ?? (lesson?.id == IntroTutorial.lessonID ? app.introLibrary?.units[state.level] : nil)
                if let writer { payload=try await writer(.init(mode:mode,lesson:lesson,state:state,level:level,tutorial:tutorial,recent:state.storyHistory?[target] ?? [],unit:unit,account:account)) }
                else {
                    var id=UUID()
                    payload=try await app.ai.storyPayload(mode:mode,lesson:lesson,state:state,level:level,tutorial:tutorial,recent:state.storyHistory?[target] ?? [],repair:false,unit:unit,account:account,onSpeakingChunk:{[weak self] snapshot in
                        guard let self,self.generation == token,app.identity.npub == account,app.learner.target == target,app.learner.support == support else{return}
                        if snapshot.isEmpty {if self.provisional != nil {id=UUID()};self.provisional=nil;return}
                        if mode != .speaking {
                            guard let draft=StoryStreamDraft.episode(snapshot) else{return}
                            var previous=self.provisional
                            if let old=previous,!Self.extends(old,draft) {id=UUID();previous=nil}
                            let next=Self.makeProvisionalEpisode(previous:previous,id:id,draft:draft,mode:mode,state:state,level:level,lesson:lesson)
                            if self.provisional != next {self.provisional=next};return
                        }
                        let turns=StoryStreamDraft.speaking(snapshot)
                        guard !turns.isEmpty else {return}
                        let next=Self.makeProvisional(previous:self.provisional,id:id,turns:turns,state:state,level:level,lesson:lesson,title:lesson?.title.localized(support) ?? "Practice")
                        if self.provisional != next {self.provisional=next}
                    })
                }
            }
            try Task.checkCancellation();guard generation == token,app.identity.npub == account,app.learner.target == target,app.learner.support == support else { return false }
            var run=try StoryRun(payload:payload,mode:mode,target:target,support:support,level:level,lessonID:lesson?.id,worth:ConversationPractice.worth(rating:state.rating,level:level),tutorial:tutorial)
            if let provisional,let first=provisional.currentSentence,let final=run.currentSentence,first.speaker == final.speaker,first.target == final.target {run.id=provisional.id}
            if let provisional,mode != .speaking {_=Self.promoteEpisode(provisional,into:&run)}
            run.lessonLevel=authoredLevel;run.sourceContext=sourceContext
            let recipes=try PracticeRecipes()
            if mode == .speaking {
                if Self.fixtureMode != nil { run.sentenceWorths=try run.sentences.map { _ in try GeneratedQuestionWorth.fallback(level:level,learner:state,recipes:recipes) } }
                else { run.sentenceWorths=try await GeneratedQuestionWorth.assessMany(questions:run.sentences.map { .object(["sentence":.string($0.target),"task":.string("Understand and pronounce this sentence")]) },level:level,mode:"story",learner:app.learner,recipes:recipes,ai:app.ai) }
            }
            try Task.checkCancellation();guard generation == token,app.identity.npub == account,app.learner.target == target,app.learner.support == support else { return false }
            let names=Set(run.episode?.segments.flatMap { $0.turns.map(\.speaker) } ?? run.sentences.map(\.speaker))
            let existing=provisional?.id == run.id ? (provisional?.portraitIDs ?? [:]) : [:]
            run.portraitIDs=Dictionary(uniqueKeysWithValues:names.map { ($0,existing[$0] ?? StoryCharacterAvatar.appearance.portraitPool($0,learnerName:state.name).randomElement() ?? "35") })
            app.learner.saveStory(run)
            if payload["nativePlan"] != .null,!payload["nativePlan"]["isTutorial"].boolean {
                let plan=payload["nativePlan"]
                let history=StoryGeneration.history(app.learner.storyHistory?[target] ?? [])
                if app.learner.storyHistory == nil { app.learner.storyHistory=[:] }
                app.learner.storyHistory?[target]=Array(([StoryGeneration.historyEntry(run,plan:plan)]+history).prefix(40))
                while app.learner.storyHistory!.count > 3 { let old=app.learner.storyHistory!.keys.sorted().first { $0 != target }!;app.learner.storyHistory?.removeValue(forKey:old) }
                while (try? JSONEncoder().encode(app.learner.storyHistory).count) ?? 0 > 96_000,(app.learner.storyHistory?[target]?.count ?? 0) > 1 { app.learner.storyHistory?[target]?.removeLast() }
            }
            activeRunID=run.id;provisional=nil;app.persist();return true
        } catch is CancellationError { } catch { if generation == token { self.error=error.localizedDescription } }
        return false
    }
}
extension AIService {
    func storyPayload(mode:StoryMode,lesson:Lesson?,state:LearnerState,level:String,tutorial:Bool,recent:[JSONValue],repair:Bool,unit:LearningUnit?=nil,account:String="native",onSpeakingChunk:@escaping @MainActor(String)->Void = {_ in}) async throws ->JSONValue {
        let recipes=try PracticeRecipes()
        var parameters=try StoryGeneration.parameters(state:state,lesson:lesson,unit:unit,mode:mode,account:account,level:level,user:state.recipeUser,recipes:recipes)
        parameters=parameters.setting("history",.array(StoryGeneration.history(recent)))
        if tutorial,parameters["lessonContent"]["topic"].string != "tutorial" { parameters=parameters.setting("lessonContent",parameters["lessonContent"].setting("topic",.string("tutorial"))) }
        let plan:JSONValue,streamPrompt:String
        if mode == .speaking {
            let prepared=try recipes.story("prepareSpeak",parameters:parameters);plan=prepared["metadata"]["storyPlan"];streamPrompt=prepared["prompt"].string
        } else {
            plan=try recipes.story("plan",parameters:parameters)
            streamPrompt=try recipes.story("sessionStreamPrompt",parameters:parameters.setting("plan",plan)).string
        }
        parameters=parameters.setting("plan",plan)
        let title=parameters["lessonContent"]["title"].localized(state.support).isEmpty ? lesson?.title.localized(state.support) ?? "Practice" : parameters["lessonContent"]["title"].localized(state.support)
        func checked(_ raw:String,stream:Bool)throws->StoryRun {
            let payload=try (stream || mode == .speaking) ? StoryGeneration.payload(raw,mode:mode,target:state.target,tutorial:plan["isTutorial"].boolean,title:title,recipes:recipes) : JSONDecoder().decode(JSONValue.self,from:Data(raw.utf8))
            let run=try StoryRun(payload:payload,mode:mode,target:state.target,support:state.support,level:level,lessonID:lesson?.id,worth:.null,tutorial:plan["isTutorial"].boolean)
            if !plan["isTutorial"].boolean,try recipes.story("exactRepeat",parameters:.object(["candidate":StoryGeneration.candidate(run),"plan":plan])).boolean { throw AppError.message("The dialogue repeats a recent activity. Generate a different scene.") }
            return run
        }
        func result(_ run:StoryRun)throws->JSONValue {
            var payload=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(run))
            // StoryRun stores an episode; the writer-facing payload uses its original fields.
            if let episode=run.episode { payload=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(episode)) }
            return payload.setting("nativePlan",.object(["lessonId":plan["lessonId"],"mode":plan["mode"],"subject":plan["subject"],"purpose":plan["purpose"],"isTutorial":plan["isTutorial"]]))
        }
        if !repair {
            do { let raw=try await storyProtocol(streamPrompt,stream:true,mode:mode,onChunk:onSpeakingChunk);return try result(checked(raw,stream:true)) }
            catch { try Task.checkCancellation();onSpeakingChunk("") }
        }
        let prompt=mode == .speaking ? streamPrompt : try recipes.story("sessionPrompt",parameters:parameters).string
        let revisionParameters:JSONValue = .object(["mode":.string(mode.rawValue),"prompt":.string(prompt)])
        let run=try await StoryGenerationCoordinator.generate(prompt:prompt,mode:mode,
            generate:{ input,_ in try await self.storyProtocol(input,stream:false,mode:mode) },
            validate:{ try checked($0,stream:false) },
            issues:{ try recipes.story("novelty",parameters:.object(["candidate":StoryGeneration.candidate($0),"plan":plan])).array.map(\.string) },
            review:{ candidate in
                if plan["isTutorial"].boolean { return [] }
                let prompt=try recipes.story("reviewPrompt",parameters:.object(["candidate":StoryGeneration.candidate(candidate),"plan":plan])).string
                let raw=try await self.text(prompt,json:true)
                return try recipes.story("parseReview",parameters:.object(["raw":.string(raw)])).array.map(\.string)
            },revision:{ stage,raw,error in try recipes.story("revisionPrompt",parameters:revisionParameters.setting("stage",.string(stage)).setting("raw",.string(raw)).setting("error",.string(error))).string })
        return try result(run)
    }
    private static var storyEpisodeSchema:Schema {
        let turn=Schema.object(properties:["speaker":.string(),"target":.string(),"support":.string()],optionalProperties:["support"])
        let question=Schema.object(properties:["type":.enumeration(values:["choice","true_false","select_words","order_words","reply"]),"prompt":.string(),"options":.array(items:.string(),maxItems:8),"answer":.array(items:.integer(),maxItems:8),"explanation":.string(),"audioTurn":.integer()])
        return .object(properties:["title":.string(),"segments":.array(items:.object(properties:["turns":.array(items:turn,minItems:2,maxItems:6),"question":question]),minItems:2,maxItems:4)])
    }
    private func storyProtocol(_ prompt:String,stream:Bool,mode:StoryMode,onChunk:@escaping @MainActor(String)->Void = {_ in}) async throws->String {
        if configuration.string("AIProvider") == "gemini",FirebaseService.shared.configured {
            do {
                let model=FirebaseAI.firebaseAI(backend:configuration.geminiBackend()).generativeModel(modelName:configuration.string("GeminiModel"),generationConfig:GenerationConfig(temperature:0.7,maxOutputTokens:8192,responseMIMEType:!stream && mode != .speaking ? "application/json" : nil,responseSchema:!stream && mode != .speaking ? Self.storyEpisodeSchema : nil))
                if stream {
                    var output=""
                    for try await chunk in try model.generateContentStream(prompt) {
                        try Task.checkCancellation();guard !chunk.candidates.contains(where:{ $0.finishReason == .maxTokens }) else { throw StoryFailure.invalid }
                        output += chunk.text ?? "";guard output.utf8.count <= 100_000 else { throw StoryFailure.invalid };onChunk(output)
                    }
                    onChunk(output+"\n");return output
                }
                let response=try await model.generateContent(prompt)
                guard !response.candidates.contains(where:{ $0.finishReason == .maxTokens }),let text=response.text else { throw StoryFailure.invalid };return text
            } catch { try Task.checkCancellation();if stream {onChunk("")} }
        }
        if stream {let output=try await responsesStream(prompt,onChunk:onChunk);onChunk(output+"\n");return output}
        // NDJSON uses the existing authenticated text response route. The source's
        // validated batch episode still uses its fixed JSON schema on fallback.
        return try await responsesText(prompt,json:!stream && mode != .speaking,reasoning:"low",outputProfile:!stream && mode != .speaking ? "story_episode" : nil,maxOutputTokens:8192)
    }
}
