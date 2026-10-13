import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppModel
    var body: some View {
        if !app.signedIn { SignInView() }
        else if !app.learner.onboardingComplete { OnboardingView() }
        else {
            TabView {
                NavigationStack { HomeView() }.id("learn:" + app.learner.target).tabItem { Label("Learn", systemImage: "book") }
                NavigationStack { PracticeLibraryView() }.id("practice:" + app.learner.target).tabItem { Label("Practice", systemImage: "rectangle.stack") }
                NavigationStack { TutorLibraryView() }.id("tutor:" + app.learner.target).tabItem { Label("Tutor", systemImage: "bubble.left.and.bubble.right") }
                NavigationStack { NotebookView() }.tabItem { Label("Notes", systemImage: "note.text") }
                NavigationStack { AccountView() }.tabItem { Label("Account", systemImage: "person") }
            }.id(app.identity.npub)
        }
    }
}
struct SignInView: View {
    @EnvironmentObject var app: AppModel
    @State private var nsec = ""
    @State private var busy = false
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Piyali").font(.largeTitle)
                    Text("Learn languages with lessons, reading, stories and a personal tutor.")
                    Button("Create an account") { signIn(nil) }.disabled(busy).accessibilityIdentifier("createAccount")
                }
                Section("Use your existing Piyali or Nostr account") {
                    SecureField("nsec private key", text: $nsec).textInputAutocapitalization(.never).autocorrectionDisabled()
                    Button("Sign in with key") { signIn(nsec) }.disabled(nsec.isEmpty || busy)
                    Text("Your private key stays in this iPhone's Keychain. Back it up from Account after signing in.").font(.footnote)
                }
                if busy { ProgressView("Opening account…") }
            }.navigationTitle("Welcome")
        }
    }
    func signIn(_ key: String?) { busy = true; Task { await app.signIn(nsec: key); nsec = ""; busy = false } }
}
struct OnboardingView: View {
    @EnvironmentObject var app: AppModel
    var body: some View {
        NavigationStack {
            Form {
                Section("Your learning plan") {
                    TextField("Your name", text: $app.learner.name)
                    LanguagePicker(title: "I want to learn", selection: $app.learner.target, codes: LearningLanguages.practice)
                    LanguagePicker(title: "Explain in", selection: $app.learner.support, codes: LearningLanguages.support)
                    Picker("Starting level", selection: $app.learner.level) { ForEach(LearningLanguages.levels, id: \.self) { Text($0).tag($0) } }.accessibilityIdentifier("onboardingLevelPicker")
                    TextField("What do you want to achieve?", text: $app.learner.goal, axis: .vertical)
                    Stepper("Daily goal: \(app.learner.dailyGoal) XP", value: $app.learner.dailyGoal, in: 10...300, step: 10)
                }
                Button("Start learning") {
                    app.finishOnboarding()
                }.accessibilityIdentifier("startLearning")
            }.navigationTitle("Set up Piyali")
        }
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
