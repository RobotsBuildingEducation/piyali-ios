import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppModel
    var body: some View {
        Group {
        if !app.signedIn { EntryView() }
        else if !app.learner.onboardingComplete { BrandedOnboardingView() }
        else {
            ProductAccessView(service:app.subscription).id(app.identity.npub)
        }
        }.background(SignerAuthorizationPresenter(identity:app.identity))
    }
}
private struct ProductAccessView:View {
    @ObservedObject var service:SubscriptionService
    var body:some View { if service.hasAccess { ProductShellView() } else { NavigationStack { SubscriptionView(service:service) } } }
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
