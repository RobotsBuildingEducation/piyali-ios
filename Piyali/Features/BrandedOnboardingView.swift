import SwiftUI

struct BrandedOnboardingView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @AppStorage("piyali.interfaceLanguage") private var language=EntryCopy.initialLanguage
    @AppStorage("piyali.theme") private var theme="light"
    @FocusState private var editingGoal:Bool
    @State private var draft:OnboardingDraft
    init(initial:LearnerState) {_draft=State(initialValue:OnboardingDraft(support:initial.support,target:initial.target))}
    private static let options=(try? ContentLibrary.load([String:JSONValue].self,name:"onboarding-options")) ?? [:]
    private var brand:PiyaliBrand {PiyaliBrand(dark:scheme == .dark)}
    private var surface:Color {PiyaliBrand.unitColor(scheme == .dark ? "0b1220" : "fdf9f2")}
    private var card:Color {PiyaliBrand.unitColor(scheme == .dark ? "111827" : "f1e8dc")}
    private var controlBorder:Color {PiyaliBrand.unitColor(scheme == .dark ? "1f2937" : "e0d2bf")}
    private func copy(_ key:String)->String {EntryCopy.ui(draft.support,key)}
    private var words:JSONValue {EntryCopy.data(draft.support)["onboarding"]}
    var body:some View {
        VStack(spacing:0) {
            ScrollView {
                VStack(alignment:.leading,spacing:0) {
                    HStack(spacing:10) {
                        BrandArtwork(name:"onboarding-character.webp").frame(width:50,height:50).frame(height:100).accessibilityHidden(true)
                        OnboardingText(text:copy("onboarding_title"),size:24,weight:.bold,lineHeight:26.4).accessibilityAddTraits(.isHeader).accessibilityIdentifier("onboardingTitle")
                        Spacer(minLength:0)
                    }
                    OnboardingText(text:copy("onboarding_subtitle"),size:14).opacity(0.85).padding(.top,4).padding(.bottom,16)
                    VStack(spacing:16) {
                        languageCard(support:true)
                        languageCard(support:false)
                        goalCard
                    }.padding(.bottom,16)
                }.frame(maxWidth:600).padding(.horizontal,28).padding(.top,28).padding(.bottom,16).frame(maxWidth:.infinity)
            }.scrollDismissesKeyboard(.interactively)
            Button {editingGoal=false;language=draft.support;app.finishOnboarding(draft)} label:{Text(copy("onboarding_cta_start"))}.buttonStyle(OnboardingStartStyle()).padding(.horizontal,24).padding(.top,16).padding(.bottom,24).accessibilityIdentifier("startLearning")
        }.background(surface).clipShape(OnboardingDrawerShape()).overlay {OnboardingDrawerShape(closed:false).stroke(PiyaliBrand.unitColor(scheme == .dark ? "94a3b8" : "604d38").opacity(scheme == .dark ? 0.42 : 0.3),lineWidth:3).padding(1.5).allowsHitTesting(false)}.background(brand.background.ignoresSafeArea()).foregroundStyle(brand.text)
            .preferredColorScheme(theme == "dark" ? .dark : .light).environment(\.layoutDirection,draft.support == "ar" ? .rightToLeft : .leftToRight)
            .onChange(of:app.learner.support) {_,value in draft.resolveSupport(value)}
            .toolbar {ToolbarItemGroup(placement:.keyboard) {Spacer();Button("Done"){editingGoal=false}.accessibilityIdentifier("onboardingKeyboardDone")}}
    }
    private func languageCard(support:Bool)->some View {
        VStack(alignment:.leading,spacing:0) {
            OnboardingText(text:copy(support ? "onboarding_support_language_title" : "onboarding_practice_language_title"),size:14,weight:.semibold).padding(.bottom,4)
            OnboardingText(text:copy(support ? "onboarding_support_language_desc" : "onboarding_practice_language_desc"),size:12).opacity(0.7).padding(.bottom,12)
            languageMenu(support:support)
        }.frame(maxWidth:.infinity,alignment:.leading).padding(12).background(card,in:RoundedRectangle(cornerRadius:6))
    }
    private var goalCard:some View {
        VStack(alignment:.leading,spacing:0) {
            OnboardingText(text:words["goalField"]["label"].string,size:14,weight:.semibold).padding(.bottom,4)
            OnboardingText(text:words["goal"]["description"].string,size:12).opacity(0.7).padding(.bottom,12)
            ZStack(alignment:.topLeading) {
                TextEditor(text:$draft.goal).font(PiyaliBrand.productFont(16)).lineSpacing(max(0,26-UIFont.systemFont(ofSize:16).lineHeight)).scrollContentBackground(.hidden).padding(.horizontal,7).padding(.vertical,4).frame(height:104).focused($editingGoal).accessibilityLabel(words["goalField"]["label"].string).accessibilityIdentifier("onboardingGoal")
                if draft.goal.isEmpty {OnboardingText(text:words["goalField"]["example"].string,size:16,lineHeight:26).foregroundStyle(brand.muted).padding(13).allowsHitTesting(false).accessibilityHidden(true)}
            }.background(controlBorder,in:RoundedRectangle(cornerRadius:6)).overlay {RoundedRectangle(cornerRadius:6).stroke(editingGoal ? Color.blue : PiyaliBrand.unitColor(scheme == .dark ? "cbd5e1" : "433528"),lineWidth:1)}
            OnboardingText(text:words["goal"]["hint"].string.replacingOccurrences(of:"{settingsIcon}",with:"⚙︎"),size:12,lineHeight:19.5).foregroundStyle(brand.secondary).opacity(0.88).padding(.top,8).accessibilityIdentifier("onboardingGoalHint")
        }.frame(maxWidth:.infinity,alignment:.leading).padding(12).background(card,in:RoundedRectangle(cornerRadius:6))
    }
    private func languageMenu(support:Bool)->some View {
        let code=support ? draft.support : draft.target,choices=Self.options[draft.support]?[support ? "support" : "practice"].array ?? []
        return Menu {
            ForEach(choices.indices,id:\.self) {index in let option=choices[index];Button(option["label"].string) {editingGoal=false;if support {draft.chooseSupport(option["value"].string);language=draft.support} else {draft.choosePractice(option["value"].string)}}.accessibilityIdentifier("onboardingOption-"+(support ? "support-" : "practice-")+option["value"].string)}
        } label:{HStack(spacing:8) {Image("LanguageFlag-"+code).resizable().scaledToFit().frame(width:24,height:24).accessibilityHidden(true);Text(choices.first{$0["value"].string == code}?["label"].string ?? EntryCopy.text(draft.support,"language_"+code));Spacer();Image(systemName:"chevron.down").font(.system(size:10))}.font(PiyaliBrand.productFont(14,600)).padding(.horizontal,20).frame(minHeight:42).background(card,in:EntryCornerShape()).overlay {EntryCornerShape().stroke(controlBorder)}}.tint(brand.text).accessibilityIdentifier(support ? "onboardingSupport" : "onboardingPractice")
    }
}

/// Chakra's system-font line boxes, separate from the landing DM Sans styles.
struct OnboardingText:View {
    let text:String
    var size:CGFloat=14,weight:Font.Weight = .regular,lineHeight:CGFloat?=nil
    @ScaledMetric private var scale:CGFloat=1000
    var body:some View {let actual=size*scale/1000,leading=max(0,(lineHeight ?? size*1.5)*scale/1000-UIFont.systemFont(ofSize:actual).lineHeight);Text(text).font(.system(size:actual,weight:weight)).lineSpacing(leading).padding(.vertical,leading/2).fixedSize(horizontal:false,vertical:true)}
}
private struct OnboardingStartStyle:ButtonStyle {
    func makeBody(configuration:Configuration)->some View {configuration.label.font(PiyaliBrand.productFont(18,600)).frame(maxWidth:.infinity,minHeight:48).foregroundStyle(.white).background {EntryCornerShape().fill(PiyaliBrand.unitColor(configuration.isPressed ? "2c7a7b" : "319795")).shadow(color:PiyaliBrand.unitColor("214f54"),radius:0,y:configuration.isPressed ? 0 : 4)}.offset(y:configuration.isPressed ? 4 : 0)}
}
private struct OnboardingDrawerShape:Shape {
    var closed=true
    func path(in rect:CGRect)->Path {let r=min(48,rect.width/2);var p=Path();p.move(to:CGPoint(x:rect.minX,y:rect.maxY));p.addLine(to:CGPoint(x:rect.minX,y:rect.minY+r));for i in 0...24 {let a=Double.pi+Double(i)/24*Double.pi/2;p.addLine(to:CGPoint(x:rect.minX+r+r*CGFloat(-sqrt(abs(cos(a)))),y:rect.minY+r+r*CGFloat(-sqrt(abs(sin(a))))))};p.addLine(to:CGPoint(x:rect.maxX-r,y:rect.minY));for i in 0...24 {let a = -Double.pi/2+Double(i)/24*Double.pi/2;p.addLine(to:CGPoint(x:rect.maxX-r+r*CGFloat(sqrt(abs(cos(a)))),y:rect.minY+r+r*CGFloat(-sqrt(abs(sin(a))))))};p.addLine(to:CGPoint(x:rect.maxX,y:rect.maxY));if closed {p.closeSubpath()};return p}
}
