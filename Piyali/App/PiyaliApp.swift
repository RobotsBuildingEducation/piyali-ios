import SwiftUI

@main struct PiyaliApp: App {
    @StateObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    init() {EntryFixture.configurePreferences();FirebaseService.configure(); _model = StateObject(wrappedValue: AppModel()) }
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(model)
                .task { model.subscription.setApplicationActive(scenePhase == .active);model.setAchievementApplicationActive(scenePhase == .active);await model.boot() }
                .task(id:narrationPreparationScope) { await prepareNarration() }
                .onChange(of: scenePhase) { _, phase in
                    model.subscription.setApplicationActive(phase == .active);model.setAchievementApplicationActive(phase == .active)
                    if phase == .active, model.signedIn {
                        model.learner.rollDay(); model.subscription.checkExpiry()
                        model.scheduleAutomaticTips(recovering:true)
                        Task { await model.subscription.refresh(); await model.sync() }
                    }
                }
                .onOpenURL { url in
                    if url.scheme == "piyali", url.host == "subscription" { Task { await model.subscription.refresh(forceWeb:true) } }
                }
                .alert("Piyali", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
                    Button("OK") { model.error = nil }
                } message: { Text(model.error ?? "") }
        }
    }
    private var narrationPreparationScope:String{[model.signedIn ? model.identity.npub:"",String(describing:scenePhase),String(model.subscription.hasAccess),model.learner.target].joined(separator:"|")}
    @MainActor private func prepareNarration()async{
        let pool=NarrationConnectionPool.shared,offline=ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",account=model.signedIn ? model.identity.npub:"",enabled = !offline && scenePhase == .active && model.subscription.hasAccess
        pool.automaticRefill=enabled;pool.configure(account:account,active:enabled);guard enabled,!account.isEmpty else{return}
        // Existing boot/sync authenticates the account. Speculative audio never starts its own sign-in.
        for _ in 0..<200 where !pool.usable{if Task.isCancelled{return};try? await Task.sleep(for:.milliseconds(100))}
        guard !Task.isCancelled,pool.usable,model.identity.npub == account,let engine=model.companionQuestPolicy,let session=try? engine.run("ph_tts",.object(["language":.string(model.learner.target),"voice":.string("ash")]))else{return}
        _=await pool.warm(session:session)
    }
}
