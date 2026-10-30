import Foundation
import Combine

@MainActor final class SettingsPersonaController:ObservableObject {
    @Published private(set) var draft=""
    @Published private(set) var saved=false
    private var account="",dirty=false,focused=false
    private var task:Task<Void,Never>?,clear:Task<Void,Never>?
    func load(_ app:AppModel){task?.cancel();account=app.identity.npub;dirty=false;saved=false;draft=SettingsUI.effective(app.learner)["progress"]["tutorVoicePersona"].string}
    func change(_ value:String,_ app:AppModel){draft=GoalText.limit(value,units:240);dirty=true;saved=false;clear?.cancel();task?.cancel();task=Task{[weak self,weak app] in do{try await Task.sleep(for:.milliseconds(400));guard let self,let app,!Task.isCancelled else{return};self.flush(app)}catch{}}}
    func focus(_ value:Bool,_ app:AppModel){focused=value;if !value{flush(app)}}
    func flush(_ app:AppModel){task?.cancel();task=nil;guard dirty,account == app.identity.npub else{return};dirty=false;app.updateSettings(.object(["tutorVoicePersona":.string(draft)]));saved=true;clear?.cancel();clear=Task{[weak self] in try? await Task.sleep(for:.seconds(3));guard !Task.isCancelled else{return};self?.saved=false}}
    func receive(_ app:AppModel){guard account == app.identity.npub,!dirty,!focused else{return};draft=SettingsUI.effective(app.learner)["progress"]["tutorVoicePersona"].string}
    func close(_ app:AppModel){flush(app);task?.cancel();clear?.cancel()}
    deinit{task?.cancel();clear?.cancel()}
}
