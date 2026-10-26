import SwiftUI

@main struct PiyaliApp: App {
    @StateObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    init() {EntryFixture.configurePreferences();FirebaseService.configure(); _model = StateObject(wrappedValue: AppModel()) }
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(model)
                .task { model.subscription.setApplicationActive(scenePhase == .active);await model.boot() }
                .onChange(of: scenePhase) { _, phase in
                    model.subscription.setApplicationActive(phase == .active)
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
}
