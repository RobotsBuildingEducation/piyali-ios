import Foundation
import Combine

@MainActor final class GoalEditorController:ObservableObject {
    let id=UUID()
    @Published private(set) var draft=""
    @Published private(set) var saved=false
    private var account="",target=""
    private var dirty=false,focused=false
    private var pendingText:String?
    private var debounce:Task<Void,Never>?,savedTimer:Task<Void,Never>?
    func load(_ app:AppModel) {
        if !account.isEmpty {flush(app)}
        debounce?.cancel();savedTimer?.cancel();saved=false;pendingText=nil;dirty=false;focused=false
        account=app.identity.npub;target=app.learner.target;draft=app.learner.goalIntelligence?[target]?["activeGoal"]["text"].string ?? ""
        app.registerGoalEditor(id:id){[weak self,weak app] in if let self,let app {self.flush(app)}}
    }
    func change(_ text:String,app:AppModel){
        app.registerGoalEditor(id:id){[weak self,weak app] in if let self,let app {self.flush(app)}}
        draft=GoalText.limit(text,units:600);dirty=true;saved=false;savedTimer?.cancel();debounce?.cancel()
        debounce=Task{[weak self,weak app] in do{try await Task.sleep(for:.milliseconds(400));guard let self,let app,!Task.isCancelled else{return};self.flush(app)}catch{}}
    }
    func focus(_ value:Bool,app:AppModel){focused=value;if !value {flush(app);receive(app)}}
    func flush(_ app:AppModel){
        debounce?.cancel();debounce=nil
        guard dirty,!account.isEmpty,account == app.identity.npub else{return};dirty=false
        let text=draft.trimmingCharacters(in:.whitespacesAndNewlines),existing=app.learner.goalIntelligence?[target]?["activeGoal"]["text"].string ?? ""
        guard text != existing.trimmingCharacters(in:.whitespacesAndNewlines) else{return}
        if app.learner.target == target {app.learner.goal=text}
        app.learner.applyGoal(GoalChange(action:.edit,target:target,payload:.object(["id":.string(UUID().uuidString.lowercased()),"text":.string(text),"status":.string("active")])))
        pendingText=text;app.persist()
    }
    func receive(_ app:AppModel){
        guard account == app.identity.npub,target == app.learner.target else{return}
        let remote=app.learner.goalIntelligence?[target]?["activeGoal"]["text"].string ?? ""
        if !focused,!dirty,draft.trimmingCharacters(in:.whitespacesAndNewlines) != remote {draft=remote}
        if let pendingText,pendingText == remote,!(app.learner.pendingGoalChanges ?? []).contains(where:{$0.target == target && $0.action == .edit}){
            self.pendingText=nil;saved=true;savedTimer?.cancel()
            savedTimer=Task{[weak self] in do{try await Task.sleep(for:.milliseconds(3000));guard !Task.isCancelled else{return};self?.saved=false}catch{}}
        }
    }
    func close(_ app:AppModel){flush(app);debounce?.cancel();savedTimer?.cancel();app.unregisterGoalEditor(id:id)}
    deinit{debounce?.cancel();savedTimer?.cancel()}
}
