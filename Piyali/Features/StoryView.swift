import SwiftUI

struct StoryView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service=StoryService()
    @StateObject private var speech=SpeechService()
    let lesson:Lesson?
    var onComplete:(()->Void)? = nil
    @State private var chosen=StoryMode.allCases.randomElement()!
    @State private var refresh=0
    @State private var typed=""
    @State private var transcript=false
    @State private var role:StoryRoleRequest?
    @State private var translations=Set<String>()
    @State private var playingScene:(id:UUID,part:Int,cursor:Int)?
    private var content:JSONValue { lesson?.content["stories"] ?? .null }
    private var mode:StoryMode { StoryService.fixtureMode ?? (content["topic"].string == "tutorial" ? .speaking : StoryMode(rawValue:content["storyMode"].string) ?? chosen) }
    private var scope:String { [app.identity.npub,app.learner.target,app.learner.support,app.learner.level,lesson?.id ?? "free",mode.rawValue,String(refresh)].joined(separator:"|") }
    private var run:StoryRun? { guard let run=app.learner.story,run.support == app.learner.support,run.lessonID == lesson?.id,run.mode == mode else { return nil };return run }
    var body:some View {
        Group {
            if StoryService.fixtureMode != nil { activity }
            else { SubscriptionRequiredView(service:app.subscription) { activity } }
        }.navigationTitle("Stories")
            .task(id:scope) { speech.stopAll();playingScene=nil;typed="";transcript=false;await service.prepare(app,lesson:lesson,mode:mode,fresh:refresh > 0) }
            .onDisappear { service.cancel();speech.stopAll();playingScene=nil }
            .sheet(item:$role) { request in StoryRolePracticeView(request:request,onFinish:{
                guard var current=app.learner.story,current.id == request.runID,current.index == request.part else { return }
                current.practicedRoleLines.insert(request.key);app.learner.saveStory(current);app.persist()
                if request.continuous,let playing=playingScene,playing.id == current.id,playing.part == current.index { playScene(current,start:playing.cursor) }
            }) }
    }
    private var activity:some View {
        Form {
            Section("Story mode") {
                Picker("Activity",selection:Binding(get:{ mode },set:{ chosen=$0 })) { ForEach(StoryMode.allCases,id:\.self) { Text($0.label).tag($0) } }.disabled(StoryService.fixtureMode != nil || content["topic"].string == "tutorial" || StoryMode(rawValue:content["storyMode"].string) != nil || service.busy)
                Text(mode.label).font(.footnote)
                Button("New story") { chosen=mode.next(content:content,random:Double.random(in:0..<1));refresh += 1 }.disabled(service.busy)
            }
            if service.busy { ProgressView("Writing your story…") }
            if let error=service.error { Text(error).foregroundStyle(.red);Button("Try another story") { refresh += 1 } }
            if let run,!service.busy {
                Section(run.title) {
                    Text("\(min(run.index+1,run.count)) / \(run.count) · \(run.earnedXP) XP earned").accessibilityIdentifier("storyProgress")
                    if run.completed { Text("Story complete · \(run.earnedXP) XP saved").accessibilityIdentifier("storyCompleted") }
                }
                if run.atEnd { recap(run) }
                else if run.mode == .speaking,let line=run.currentSentence { sentence(run,line:line) }
                else if let segment=run.currentSegment { scene(run,segment:segment) }
            }
            if let error=speech.error { Text(error).foregroundStyle(.red) }
        }
    }
    @ViewBuilder private func recap(_ run:StoryRun) -> some View {
        Section("Recap") {
            if run.mode == .speaking { Text("\(run.passedLines.count) / \(run.sentences.count) lines practiced successfully. Each line earns 2 XP once.") }
            else { Text("\(run.correctQuestions) / \(run.count) checkpoints correct. Finishing the episode earns 6 XP once.") }
            if !run.completed { Button("Finish story") {
                _=app.learner.finishStory();app.persist();if let onComplete { onComplete();dismiss() }
            }.accessibilityIdentifier("storyFinish") }
            Button("Save story to notes") { app.learner.notes.insert(Note(title:run.title,body:run.text),at:0);app.persist() }
        }
    }
    @ViewBuilder private func sentence(_ run:StoryRun,line:StoryTurn) -> some View {
        Section(line.speaker) {
            Text(line.target).textSelection(.enabled).accessibilityIdentifier("storyTarget")
            Button("Listen to line") { speech.speak(line.target,language:run.target) }
            translation(line,run:run,key:"sentence-"+String(run.index))
            if let result=run.speechResult { Text(result.pass ? "Words matched · \(result.score)% · +2 XP" : "Match the line's words and speak clearly. \(result.reasons.joined(separator:", "))").accessibilityIdentifier("storySpeechFeedback") }
            else {
                TextField("Type the line to practice its wording",text:$typed,axis:.vertical).accessibilityIdentifier("storyTypedAnswer")
                Button("Check typed words") { checkLine(typed,typed:true) }.disabled(typed.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty).accessibilityIdentifier("storyCheckTyped")
                Button(speech.recording ? "Stop microphone" : "Practice aloud") { if speech.recording { speech.stop() } else { Task { await speech.start(language:run.target) } } }
                if !speech.transcript.isEmpty { Text(speech.transcript);Button("Check spoken words") { speech.stop();checkLine(speech.transcript,typed:false) } }
            }
            if run.speechResult?.pass == true { Button("Next line") { advance() }.accessibilityIdentifier("storyNext") }
            else {
                if run.speechResult != nil { Button("Try line again") { update { $0.speechResult=nil;$0.lastWords="" };typed="" } }
                Button("Skip line") { advance() }.accessibilityIdentifier("storySkip")
            }
            Text("Typed practice checks wording. Spoken practice also checks the recognition and recording quality; this is not a phonetic pronunciation rating.").font(.footnote)
        }
    }
    @ViewBuilder private func scene(_ run:StoryRun,segment:StorySegment) -> some View {
        Section("Part \(run.index+1)") {
            Button("Play dialogue") {
                playScene(run,start:0)
            }
            Button("Read dialogue instead") { transcript=true;update { $0.heard.insert(run.index) } }.accessibilityIdentifier("storyRead")
            Toggle("Show dialogue",isOn:$transcript)
            ForEach(Array(segment.turns.enumerated()),id:\.offset) { index,line in
                VStack(alignment:.leading,spacing:8) {
                    Text(line.speaker).font(.headline)
                    if transcript || run.mode == .conversation || line.speaker == "You" || run.result != nil { Text(line.target);translation(line,run:run,key:"\(run.index)-\(index)") }
                    if line.speaker == "You",!run.practicedRoleLines.contains("\(run.index)-\(index)") {
                        Button("Practice your line") { speech.stopAll();playingScene=nil;role=StoryRoleRequest(runID:run.id,part:run.index,line:index,turn:line,target:run.target) }
                    }
                }
            }
            if segment.turns.contains(where:{ $0.speaker == "You" }) { Button("Continue without speaking") { update { value in for index in segment.turns.indices where segment.turns[index].speaker == "You" { value.practicedRoleLines.insert("\(value.index)-\(index)") } } } }
        }
        if run.heard.contains(run.index),segment.turns.indices.filter({ segment.turns[$0].speaker == "You" }).allSatisfy({ run.practicedRoleLines.contains("\(run.index)-\($0)") }) { checkpoint(run,question:segment.question) }
    }
    @ViewBuilder private func checkpoint(_ run:StoryRun,question:StoryQuestion) -> some View {
        Section("Checkpoint") {
            Text(question.prompt)
            if ["select_words","order_words"].contains(question.type),let index=question.audioTurn,let line=run.currentSegment?.turns[index] { Button("Listen to excerpt") { speech.speak(line.target,language:run.target) } }
            let selected=run.answers[String(run.index)] ?? []
            if question.type == "order_words",!selected.isEmpty { Text(selected.map { question.options[$0] }.joined(separator:" ")).accessibilityIdentifier("storyWordOrder") }
            ForEach(Array(question.options.enumerated()),id:\.offset) { index,option in
                Button { update { $0.select(index) } } label: { HStack { Text(option);Spacer();if selected.contains(index) { Image(systemName:"checkmark") } } }.disabled(run.result != nil).accessibilityIdentifier("storyOption-"+String(index))
            }
            if let result=run.result {
                Text(result ? "Correct" : "Try this").accessibilityIdentifier("storyFeedback")
                Text(question.explanation)
                if !result { Text("Answer: "+question.answer.map { question.options[$0] }.joined(separator:" · ")) }
                Button("Next part") { advance() }.accessibilityIdentifier("storyNext")
            } else { Button("Check answer") {
                update { $0.check() }
                guard let latest=app.learner.story,let correct=latest.result else { return }
                app.learner.history.insert(HistoryEntry(date:Date(),target:run.target,mode:"Stories",question:question.prompt,answer:selected.map { question.options[$0] }.joined(separator:" "),feedback:question.explanation,correct:correct),at:0);app.learner.history=Array(app.learner.history.prefix(500));app.persist()
            }.disabled(selected.isEmpty).accessibilityIdentifier("storyCheck") }
        }
    }
    @ViewBuilder private func translation(_ turn:StoryTurn,run:StoryRun,key:String) -> some View {
        let text=run.translations[key] ?? turn.support ?? ""
        if translations.contains(key),!text.isEmpty { Text(text).foregroundStyle(.secondary) }
        Button(translations.contains(key) ? "Hide translation" : "Translate") {
            if translations.contains(key) { translations.remove(key) }
            else {
                translations.insert(key)
                if text.isEmpty { let account=app.identity.npub;Task {
                    do { let value=try await app.ai.conversationTranslation(turn.target,support:run.support)
                        guard app.identity.npub == account,app.learner.story?.id == run.id else { return };update { $0.translations[key]=value }
                    } catch { service.error=error.localizedDescription }
                } }
            }
        }
    }
    private func update(_ change:(inout StoryRun)->Void) { guard var value=app.learner.story,value.support == app.learner.support else { return };change(&value);app.learner.saveStory(value);app.persist() }
    private func advance() { speech.stopAll();playingScene=nil;update { $0.advance() };typed="";transcript=false }
    private func playScene(_ run:StoryRun,start:Int) {
        guard let segment=run.currentSegment,start <= segment.turns.count else { return }
        speech.stopAll()
        let next=segment.turns.indices.first { $0 >= start && segment.turns[$0].speaker == "You" }
        let stop=next ?? segment.turns.count
        playingScene=(run.id,run.index,(next ?? segment.turns.count)+1)
        speech.speakSeries(Array(segment.turns[start..<stop]).map(\.target),language:run.target,onFinished:{
            guard app.learner.story?.id == run.id,app.learner.story?.index == run.index,playingScene?.id == run.id else { return }
            if let next { role=StoryRoleRequest(runID:run.id,part:run.index,line:next,turn:segment.turns[next],target:run.target,continuous:true) }
            else { playingScene=nil;update { $0.heard.insert(run.index) } }
        })
    }
    private func checkLine(_ words:String,typed:Bool) {
        speech.stop();_=app.learner.practiceStoryLine(words:words,confidence:typed ? 0 : speech.confidence,audio:typed ? nil : speech.audioMetrics,typed:typed);app.persist()
    }
}
struct StoryRoleRequest:Identifiable { let runID:UUID;let part:Int;let line:Int;let turn:StoryTurn;let target:String;var continuous=false;var key:String { "\(part)-\(line)" };var id:String { runID.uuidString+":"+key } }
struct StoryRolePracticeView:View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speech=SpeechService()
    let request:StoryRoleRequest
    let onFinish:()->Void
    @State private var typed=""
    @State private var result:StorySpeechResult?
    var body:some View {
        NavigationStack { Form {
            Text(request.turn.target);Button("Listen") { speech.speak(request.turn.target,language:request.target) }
            TextField("Practice the words",text:$typed,axis:.vertical)
            Button("Check typed words") { result=StorySpeech.evaluate(recognized:typed,target:request.turn.target,lang:request.target) }.disabled(typed.isEmpty)
            Button(speech.recording ? "Stop microphone" : "Practice aloud") { if speech.recording { speech.stop() } else { Task { await speech.start(language:request.target) } } }
            if !speech.transcript.isEmpty { Text(speech.transcript);Button("Check spoken words") { speech.stop();result=StorySpeech.evaluate(recognized:speech.transcript,target:request.turn.target,lang:request.target,confidence:speech.confidence,audio:speech.audioMetrics) } }
            if let result { Text(result.pass ? "Words matched · \(result.score)%" : "Try the line again. Match the words and speak clearly.");if result.pass { Button("Continue story") { onFinish();dismiss() } } }
            Button("Skip speaking") { onFinish();dismiss() }
            if let error=speech.error { Text(error).foregroundStyle(.red) }
        }.navigationTitle("Your line") }.onDisappear { speech.stopAll() }
    }
}
