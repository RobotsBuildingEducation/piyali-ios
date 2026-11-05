import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppModel
    var body: some View {
        Group {
        if !app.signedIn { EntryView() }
        else if !app.learner.onboardingComplete { NavigationStack {BrandedOnboardingView(initial:app.learner).toolbar(.hidden,for:.navigationBar)} }
        else {
            ProductAccessView(service:app.subscription).id(app.identity.npub)
        }
        }.background(SignerAuthorizationPresenter(identity:app.identity)).background(CompanionSaveNoticePresenter())
    }
}
private struct ProductAccessView:View {
    @ObservedObject var service:SubscriptionService
    var body:some View {ProductAccessGate(service:service){TimelineView(.periodic(from:.now,by:60)){clock in ProductShellView(now:clock.date)}}}
}
/// Retain a mounted practice surface when the trial ends. Its earned completion
/// can finish saving; the subscription surface covers further access afterward.
struct ProductAccessGate<Content:View>:View {
    @EnvironmentObject var app:AppModel
    @ObservedObject var service:SubscriptionService
    @State private var mounted=false
    let content:Content
    init(service:SubscriptionService,@ViewBuilder content:()->Content){self.service=service;self.content=content()}
    private var allowed:Bool {service.hasAccess || app.preservingEarnedPractice || app.preservingScholarship}
    var body:some View {
        ZStack {
            if mounted || allowed {content.opacity(allowed ? 1:0).allowsHitTesting(allowed).accessibilityHidden(!allowed)}
            if !allowed {NavigationStack{SubscriptionView(service:service)}}
        }.onAppear{if allowed{mounted=true}}.onChange(of:allowed){_,allowed in if allowed{mounted=true}}
    }
}
struct LanguagePicker: View {
    let title: String
    @Binding var selection: String
    let codes: [String]
    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(Array(Set(codes + [selection])).sorted(), id: \.self) { code in Text(LearningLanguages.names[code] ?? code).tag(code) }
        }
    }
}
