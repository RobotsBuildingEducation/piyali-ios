import SwiftUI

struct RPGLibraryView: View {
    @EnvironmentObject var app:AppModel
    @StateObject private var service=RPGService()
    var body: some View {
        List {
            Section("Exploration worlds") {
                NavigationLink("Explore connected rooms") { ExplorationView() }.accessibilityIdentifier("explorationLink")
                Text("Travel through rooms, search objects, collect items and help the characters with their quest.").font(.footnote)
            }
            Text("Explore an authored episode, talk to its characters and finish six tasks plus a finale. Unit Game Reviews award lesson XP; free adventures are practice.")
            if let library=service.library {
                Section("Episodes · "+app.learner.level) {
                    ForEach(library.scenarios(level:app.learner.level,support:app.learner.support),id:\.authoredEpisode.id) { scenario in
                        NavigationLink(scenario.emoji+" "+scenario.name.localized(app.learner.support)) { RPGView(lesson:nil,episode:scenario.authoredEpisode.id) }
                    }
                }
                Section("Unit reviews") {
                    ForEach(app.units) { unit in
                        if let lesson=unit.lessons.first(where:{ $0.modes.contains("game") }) {
                            NavigationLink(unit.title.localized(app.learner.support)) { RPGView(lesson:lesson,episode:nil) }.accessibilityIdentifier("rpgReview-"+lesson.id)
                        }
                    }
                }
            }
            if service.busy { ProgressView("Loading authored episodes…") }
            if let error=service.error { Text(error).foregroundStyle(.red) }
        }.navigationTitle("Adventure").task(id:app.learner.target) { await service.load(target:app.learner.target) }.onDisappear { service.cancel() }
    }
}
struct RPGView: View {
    @EnvironmentObject var app:AppModel
    @Environment(\.scenePhase) private var phase
    @Environment(\.dismiss) private var dismiss
    let lesson:Lesson?
    let episode:String?
    var onTutorialComplete:(()->Void)? = nil
    var embedded=false
    @StateObject private var service=RPGService()
    @StateObject private var speech=SpeechService()
    @State private var answer=""
    @State private var talking=false
    @State private var showSupport=true
    @State private var showExample=false
    @FocusState private var focused:Bool
    var run:RPGRun? { guard let run=app.learner.rpgRuns?[app.learner.target],run.support == app.learner.support,run.lessonID == lesson?.id,episode == nil || run.scenario.authoredEpisode.id == episode else { return nil };return run }
    private var scope:String { [app.identity.npub,app.learner.target,app.learner.support,app.learner.level].joined(separator:":") }
    var body: some View {
        Form {
            if let run {
                overview(run)
                if run.completed { recap(run) }
                else { exploration(run);if talking,let node=run.node { dialogue(run,node:node) } }
                Button("New run") { stop();talking=false;answer="";Task { await service.prepare(app,lesson:lesson,episode:episode,fresh:true) } }.disabled(service.busy)
                if !app.subscription.hasAccess { Text("Authored local play is available offline. A subscription enables a connected AI story and NPC roleplay replies.").font(.footnote) }
            } else if !service.busy { Button("Retry adventure") { Task { await service.prepare(app,lesson:lesson,episode:episode) } } }
            if service.busy { ProgressView("Preparing your adventure…") }
            if let error=service.error { Text(error).foregroundStyle(.red) }
            if let error=speech.error { Text(error).foregroundStyle(.red) }
        }.navigationTitle("Adventure")
            .toolbar { ToolbarItemGroup(placement:.keyboard) { Spacer();Button("Done") { focused=false } } }
            .task(id:scope) { stop();talking=false;await service.prepare(app,lesson:lesson,episode:episode) }
            .onChange(of:speech.transcript) { _,text in answer=text }
            .onChange(of:app.subscription.hasAccess) { _,allowed in if !allowed { stop() } }
            .onChange(of:phase) { _,p in if p != .active { stop() } }
            .onDisappear { stop() }
    }
    @ViewBuilder private func overview(_ run:RPGRun) -> some View {
        Section(run.scenario.storyTitle?.isEmpty == false ? run.scenario.storyTitle! : run.scenario.name.localized(app.learner.support)) {
            Text(run.scenario.storyIntro?["target"].string.isEmpty == false ? run.scenario.storyIntro!["target"].string : run.scenario.quest.storySeed)
            if showSupport { Text(run.scenario.quest.intro).font(.footnote) }
            Text("Task \(min(7,run.stepIndex+1)) / 7 · \(run.score) / 800 points").accessibilityIdentifier("rpgStatus")
            Toggle("Show support language",isOn:$showSupport)
        }
    }
    @ViewBuilder private func recap(_ run:RPGRun) -> some View {
        Section("Episode complete · "+String(repeating:"★",count:run.stars)) {
            Text("\(run.score * 100 / 800)% · \(run.stars) stars")
            if let epilogue=run.scenario.storyEpilogue { Text(epilogue["target"].string);if showSupport { Text(epilogue["support"].string).font(.footnote) } }
            if run.tutorial == true { Button("Continue introduction") { onTutorialComplete?();if !embedded { dismiss() } }.disabled(onTutorialComplete == nil) }
            else if let lessonID=run.lessonID {
                let saved=run.claimed || app.learner.completed.contains(app.learner.completionKey(lessonID))
                Button(saved ? "Review completion saved" : "Finish unit review (+\(run.reward) XP)") { _=app.learner.completeRPG(run);app.persist() }.accessibilityIdentifier("rpgComplete").disabled(saved)
            } else { Text("Free adventure completed. No lesson XP is awarded.") }
            ForEach(run.misses,id:\.beatID) { miss in VStack(alignment:.leading) { Text(miss.concept);Text("Your answer: "+miss.answer).font(.footnote);Text("Review example: "+miss.expected).font(.footnote) } }
            Button("Save episode dialogue to notes") { app.learner.notes.insert(Note(title:run.scenario.quest.title,body:run.dialogue.joined(separator:"\n")),at:0);app.persist() }
        }
    }
    @ViewBuilder private func exploration(_ run:RPGRun) -> some View {
        Section("Explore") {
            RPGMap(run:run).frame(height:220)
            HStack { Spacer();Button("↑") { change { _=$0.move(dx:0,dy:-1) } }.accessibilityLabel("Move up");Spacer() }
            HStack { Button("←") { change { _=$0.move(dx:-1,dy:0) } }.accessibilityLabel("Move left");Spacer();Text("\(run.position.x), \(run.position.y)");Spacer();Button("→") { change { _=$0.move(dx:1,dy:0) } }.accessibilityLabel("Move right") }
            HStack { Spacer();Button("↓") { change { _=$0.move(dx:0,dy:1) } }.accessibilityLabel("Move down");Spacer() }
            if let npc=run.npc { Button("Walk to "+npc.name+" and talk") { change { if $0.approachNPC() { talking=true } };speech.stopAll() }.accessibilityIdentifier("rpgTalk") }
            ForEach(Array(run.scenario.npcs.enumerated()),id:\.offset) { index,npc in Text(npc.name+" · "+npc.role+(run.step?.npcIdx == index ? " · Next task" : "")).font(.caption) }
        }.buttonStyle(.borderless).disabled(service.busy)
    }
    @ViewBuilder private func dialogue(_ run:RPGRun,node:RPGNode) -> some View {
        Section(run.npc?.name ?? "Character") {
            if let scene=node.sceneLine,!scene.isEmpty { Text(scene).font(.footnote) }
            Text(node.npcLine).accessibilityIdentifier("rpgPrompt")
            Button("Listen to character") { speech.speak(RPGDialogue.split(node.npcLine).spoken,language:run.target) }
            if showSupport,!node.supportLine.isEmpty { Text(node.supportLine).font(.footnote) }
            if !run.resolved {
                if node.responseMode == "choice" { ForEach(Array(node.choices.enumerated()),id:\.offset) { index,choice in Button(choice.text) { speech.stopAll();change { $0.choose(index) } }.accessibilityIdentifier("rpgChoice-\(index)") } }
                else {
                    Text(node.speechGoal ?? "Answer in your practice language.").font(.footnote)
                    if showExample { Text(node.speechExample ?? node.speechTarget ?? node.expectedAnswer).font(.footnote) }
                    Button(showExample ? "Hide example" : "Show example") { showExample.toggle() }
                    TextField("Your reply",text:$answer,axis:.vertical).focused($focused).accessibilityIdentifier("rpgReply")
                    Button(speech.recording ? "Stop dictation" : "Answer aloud") { if speech.recording { speech.stop() } else { Task { await speech.start(language:run.target) } } }
                    Button("Send reply") { speech.stop();focused=false;Task { await service.speak(answer,app:app) } }.accessibilityIdentifier("rpgSend").disabled(answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                }
            }
            if !run.feedback.isEmpty { Text(run.feedback).accessibilityIdentifier("rpgFeedback");Button("Listen to reply") { speech.speak(RPGDialogue.split(run.feedback).spoken,language:run.target) } }
            if !run.tip.isEmpty { Text(run.tip).font(.footnote) }
            if run.resolved { Button("Continue") { speech.stopAll();change { $0.advance() };talking=false;answer="";showExample=false }.accessibilityIdentifier("rpgContinue") }
        }.disabled(service.busy)
    }
    private func stop() { service.cancel();speech.stopAll() }
    private func change(_ action:(inout RPGRun)->Void) { guard var run,!service.busy else { return };action(&run);app.learner.saveRPG(run);app.persist() }
}
private struct RPGMap: View {
    let run:RPGRun
    var body: some View {
        Canvas { context,size in
            let world=run.world,unit=min(size.width/Double(world.width),size.height/Double(world.height))
            for y in 0..<world.height { for x in 0..<world.width {
                let rect=CGRect(x:Double(x)*unit,y:Double(y)*unit,width:unit-1,height:unit-1)
                context.fill(Path(rect),with:.color(world.walkable(RPGPoint(x:x,y:y)) ? .gray.opacity(0.12) : .gray.opacity(0.55)))
            } }
            for (index,npc) in run.scenario.npcs.enumerated() { context.draw(Text(String(index+1)).font(.caption).foregroundStyle(run.step?.npcIdx == index ? Color.orange : Color.secondary),at:CGPoint(x:(Double(npc.tx)+0.5)*unit,y:(Double(npc.ty)+0.5)*unit)) }
            context.draw(Text("●").foregroundStyle(.blue),at:CGPoint(x:(Double(run.position.x)+0.5)*unit,y:(Double(run.position.y)+0.5)*unit))
        }.accessibilityLabel("Episode map. Your position \(run.position.x), \(run.position.y). Use movement buttons or walk to the next character.")
    }
}
