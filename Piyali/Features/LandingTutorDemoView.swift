import SwiftUI

struct LandingTutorDemoView:View {
    let language:String
    @Binding var target:String
    @ObservedObject var demo:LandingDemoService
    @State private var visible=true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme
    private func t(_ key:String)->String {EntryCopy.text(language,key,section:"tutor")}
    private var brand:PiyaliBrand {.init(dark:scheme == .dark)}
    private var green:Color {PiyaliBrand.unitColor(scheme == .dark ? "78d9bf" : "087d6b")}
    private var surface:Color {PiyaliBrand.unitColor(scheme == .dark ? "141e2a" : "fffcf6")}
    private var mint:Color {PiyaliBrand.unitColor(scheme == .dark ? "182e2b" : "e4eee4")}
    private var peach:Color {PiyaliBrand.unitColor(scheme == .dark ? "302821" : "f7e8d9")}
    private var samples:[JSONValue] {LandingDemoService.course["samples"][target].array}
    private static let languageOptions=(try? ContentLibrary.load([String:[JSONValue]].self,name:"landing-language-options")) ?? [:]
    private var languages:[JSONValue] {Self.languageOptions[language] ?? Self.languageOptions["en"] ?? []}
    private var targetLabel:String {languages.first{$0["value"].string == target}?["label"].string ?? target}
    var body:some View {
        VStack(spacing:13) {
            ViewThatFits(in:.horizontal) {
                HStack(spacing:9) {languageCaption;languagePicker}.frame(maxWidth:.infinity,alignment:.trailing)
                VStack(alignment:.trailing,spacing:9) {languageCaption;languagePicker}.frame(maxWidth:.infinity,alignment:.trailing)
            }
            bubble(demo.status == "idle" ? samples.first?.string ?? "" : demo.tutorText.isEmpty ? t("emptyTutor") : demo.tutorText,learner:false).accessibilityIdentifier("landingDemoTutor")
            PublicVoiceOrb(activeState:demo.active ? (["thinking","speaking","listening"].contains(demo.status) ? demo.status : "idle") : nil,audioLevel:demo.audioLevel,animating:visible && scenePhase == .active).frame(width:116,height:116).padding(.top,4).accessibilityIdentifier("landingDemoOrb")
            LandingVoiceWave(level:demo.audioLevel,color:green).padding(.top,-12)
            bubble(demo.status == "idle" ? (samples.count>1 ? samples[1].string : "") : demo.learnerText.isEmpty ? t("emptyLearner") : demo.learnerText,learner:true).accessibilityIdentifier("landingDemoLearner")
            Button {if demo.active {demo.cancel()} else {Task {await demo.start(target:target,support:language)}}} label:{
                Label(t(demo.active ? (demo.status == "connecting" ? "cancel" : "stop") : demo.status == "idle" ? "start" : "retry"),systemImage:demo.active ? "stop.fill" : "mic.fill").font(PiyaliBrand.font(11.52)).padding(.horizontal,15).padding(.vertical,10).frame(minHeight:40).foregroundStyle(surface).background(green,in:RoundedRectangle(cornerRadius:12))
            }.buttonStyle(.plain).padding(.top,3).accessibilityIdentifier("landingDemoStart")
            if demo.status != "idle" {Text(t(demo.status == "error" ? demo.errorCode : demo.status)).font(PiyaliBrand.font(10.4)).lineSpacing(2.5).multilineTextAlignment(.center).foregroundStyle(demo.status == "error" ? brand.text : brand.secondary).accessibilityIdentifier("landingDemoStatus")}
        }.padding(2).frame(maxWidth:.infinity)
            .background {GeometryReader {geometry in Color.clear.preference(key:LandingDemoViewport.self,value:geometry.frame(in:.global))}}
            .onPreferenceChange(LandingDemoViewport.self) {frame in visible=frame.intersects(UIScreen.main.bounds);if demo.active,!visible {demo.cancel()}}
            .onDisappear {demo.cancel()}.onChange(of:scenePhase) {_,phase in demo.sceneChanged(phase)}
    }
    private var languageCaption:some View {Text(t("language")).font(PiyaliBrand.font(9.92)).foregroundStyle(brand.secondary)}
    private var languagePicker:some View {
        Menu {ForEach(languages.indices,id:\.self) {index in let option=languages[index];Button(option["label"].string) {target=option["value"].string;demo.reset()}}} label:{
            HStack(spacing:6) {Text(targetLabel);Image(systemName:"chevron.down").font(.system(size:10))}.font(PiyaliBrand.font(9.92)).padding(.horizontal,9).padding(.vertical,7).frame(minWidth:110,minHeight:40).foregroundStyle(brand.text).background(surface,in:RoundedRectangle(cornerRadius:9)).overlay {RoundedRectangle(cornerRadius:9).stroke(brand.border)}
        }.disabled(demo.active).accessibilityIdentifier("landingDemoLanguage")
    }
    private func bubble(_ text:String,learner:Bool)->some View {
        LandingDemoBubble(text:text,language:target,identifier:learner ? "landingDemoLearner" : "landingDemoTutor",color:brand.text).background(learner ? peach : mint).clipShape(UnevenRoundedRectangle(topLeadingRadius:14,bottomLeadingRadius:learner ? 14 : 3,bottomTrailingRadius:learner ? 3 : 14,topTrailingRadius:14)).frame(maxWidth:.infinity,alignment:learner ? .trailing : .leading)
    }
}
private struct LandingDemoViewport:PreferenceKey {
    static var defaultValue:CGRect = .zero
    static func reduce(value:inout CGRect,nextValue:()->CGRect) {value=nextValue()}
}
