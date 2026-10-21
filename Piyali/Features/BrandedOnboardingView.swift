import SwiftUI

struct BrandedOnboardingView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @AppStorage("piyali.interfaceLanguage") private var language=EntryCopy.initialLanguage
    @AppStorage("piyali.theme") private var theme="light"
    @State private var goals:[String:String]=[:]
    private var brand:PiyaliBrand { PiyaliBrand(dark:scheme == .dark) }
    private func copy(_ key:String) -> String { EntryCopy.ui(app.learner.support,key) }
    private var words:JSONValue { EntryCopy.data(app.learner.support)["onboarding"] }
    private var goal:Binding<String> { Binding(get:{ goals[app.learner.target] ?? app.learner.goal },set:{ goals[app.learner.target]=$0;app.learner.goal=$0 }) }
    var body:some View {
        VStack(spacing:0) {
            ScrollView {
                VStack(alignment:.leading,spacing:24) {
                    VStack(alignment:.leading,spacing:6) {
                        HStack(spacing:10) { BrandArtwork(name:"onboarding-character.webp").frame(width:40,height:40);Text(copy("onboarding_title")).font(PiyaliBrand.font(24,700)).accessibilityIdentifier("onboardingTitle") }
                        Text(copy("onboarding_subtitle")).font(PiyaliBrand.font(14)).foregroundStyle(brand.secondary)
                    }
                    VStack(alignment:.leading,spacing:12) {
                        Text(copy("onboarding_support_language_title")).font(PiyaliBrand.font(16,600))
                        Text(copy("onboarding_support_language_desc")).font(PiyaliBrand.font(13)).foregroundStyle(brand.secondary)
                        languageMenu(support:true)
                    }
                    VStack(alignment:.leading,spacing:12) {
                        Text(copy("onboarding_practice_language_title")).font(PiyaliBrand.font(16,600))
                        Text(copy("onboarding_practice_language_desc")).font(PiyaliBrand.font(13)).foregroundStyle(brand.secondary)
                        languageMenu(support:false)
                    }
                    VStack(alignment:.leading,spacing:8) {
                        Text(words["goalField"]["label"].string).font(PiyaliBrand.font(14,600))
                        Text(words["goal"]["description"].string).font(PiyaliBrand.font(13)).foregroundStyle(brand.secondary)
                        ZStack(alignment:.topLeading) {
                            TextEditor(text:goal).font(PiyaliBrand.font(15)).scrollContentBackground(.hidden).frame(minHeight:100).padding(10).accessibilityIdentifier("onboardingGoal")
                            if goal.wrappedValue.isEmpty { Text(words["goalField"]["example"].string).font(PiyaliBrand.font(15)).foregroundStyle(brand.muted).padding(.horizontal,15).padding(.top,18).allowsHitTesting(false).accessibilityHidden(true) }
                        }.background(brand.background,in:RoundedRectangle(cornerRadius:12)).overlay { RoundedRectangle(cornerRadius:12).stroke(brand.border) }
                        Text(words["goal"]["hint"].string.replacingOccurrences(of:"{settingsIcon}",with:"⚙")).font(PiyaliBrand.font(12)).foregroundStyle(brand.secondary).lineSpacing(5)
                    }
                }.padding(.horizontal,24).padding(.top,24).padding(.bottom,20)
            }.scrollDismissesKeyboard(.interactively)
            Button { language=app.learner.support;app.finishOnboarding() } label: { Text(copy("onboarding_cta_start")) }.buttonStyle(BrandButtonStyle()).padding(.horizontal,24).padding(.top,16).padding(.bottom,24).accessibilityIdentifier("startLearning")
        }.background(brand.surface).foregroundStyle(brand.text).font(PiyaliBrand.font(16)).preferredColorScheme(theme == "dark" ? .dark : .light).environment(\.layoutDirection,app.learner.support == "ar" ? .rightToLeft : .leftToRight)
    }
    private func languageMenu(support:Bool) -> some View {
        let code=support ? app.learner.support : app.learner.target
        return Menu {
            ForEach(support ? LearningLanguages.support : LearningLanguages.practice,id:\.self) { next in
                Button(EntryCopy.text(app.learner.support,"language_"+next)) {
                    if support { app.learner.support=next;language=next }
                    else { let prior=app.learner.target;goals[prior]=app.learner.goal;app.learner.target=next;app.learner.goal=goals[next] ?? "" }
                }
            }
        } label: {
            HStack { Text(EntryCopy.flags[code] ?? "🌐");Text(EntryCopy.text(app.learner.support,"language_"+code));Spacer();Image(systemName:"chevron.down").font(.system(size:12)) }.font(PiyaliBrand.font(15,600)).padding(.horizontal,16).frame(height:48).background(brand.background,in:RoundedRectangle(cornerRadius:14)).overlay { RoundedRectangle(cornerRadius:14).stroke(brand.border) }
        }.tint(brand.text).accessibilityIdentifier(support ? "onboardingSupport" : "onboardingPractice")
    }
}
