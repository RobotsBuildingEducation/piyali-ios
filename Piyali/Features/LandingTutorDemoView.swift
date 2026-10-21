import SwiftUI

struct LandingTutorDemoView:View {
    let language:String
    @State private var target:String
    @StateObject private var demo=LandingDemoService()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme
    init(language:String) { self.language=language;_target=State(initialValue:EntryCopy.landingTarget(language)) }
    private func t(_ key:String)->String { EntryCopy.text(language,key,section:"tutor") }
    private var brand:PiyaliBrand { PiyaliBrand(dark:scheme == .dark) }
    private var samples:[JSONValue] { LandingDemoService.course["samples"][target].array }
    var body:some View {
        VStack(spacing:16) {
            VStack(alignment:.leading,spacing:8) { Text(t("language")).font(PiyaliBrand.font(11));Menu { ForEach(["de","en","es","fr","it","nl","pt","el","ga","ja","pl","ru"],id:\.self) { code in Button(EntryCopy.text(language,"language_"+code)) { target=code;Task { await demo.stop(reset:true) } } } } label:{ HStack { Text(EntryCopy.flags[target] ?? "");Text(EntryCopy.text(language,"language_"+target));Spacer();Image(systemName:"chevron.down") }.font(PiyaliBrand.font(13,600)).frame(minHeight:44).padding(.horizontal,12).background(brand.surface,in:RoundedRectangle(cornerRadius:12)) }.disabled(demo.active).accessibilityIdentifier("landingDemoLanguage") }
            Text(demo.status == "idle" ? samples.first?.string ?? "" : demo.tutorText.isEmpty ? t("emptyTutor") : demo.tutorText).font(PiyaliBrand.font(13)).foregroundStyle(brand.text).frame(maxWidth:.infinity,minHeight:68,alignment:.leading).padding(14).background(brand.surface,in:RoundedRectangle(cornerRadius:16)).accessibilityIdentifier("landingDemoTutor")
            BrandArtwork(name:"piyali-orb.png").frame(width:116,height:116).scaleEffect(demo.status == "speaking" ? 1.05 : 1).animation(.easeInOut(duration:0.5),value:demo.status)
            Image(systemName:demo.status == "listening" ? "waveform" : "waveform.path").font(.system(size:28)).foregroundStyle(PiyaliBrand.teal).accessibilityHidden(true)
            Text(demo.status == "idle" ? (samples.count > 1 ? samples[1].string : "") : demo.learnerText.isEmpty ? t("emptyLearner") : demo.learnerText).font(PiyaliBrand.font(13)).foregroundStyle(brand.secondary).frame(maxWidth:.infinity,minHeight:36)
            if demo.status != "idle" { Text(t(demo.status == "error" ? demo.errorCode : demo.status)).font(PiyaliBrand.font(12)).foregroundStyle(demo.status == "error" ? Color.red : brand.secondary).accessibilityIdentifier("landingDemoStatus") }
            Button { Task { if demo.active { await demo.stop() } else { await demo.start(target:target,support:language) } } } label:{ Label(t(demo.active ? (demo.status == "connecting" ? "cancel" : "stop") : demo.status == "idle" ? "start" : "retry"),systemImage:demo.active ? "stop.fill" : "mic.fill").font(PiyaliBrand.font(14,600)).frame(maxWidth:.infinity,minHeight:48).foregroundStyle(.white).background(Color(red:0.075,green:0.48,blue:0.41),in:Capsule()) }.accessibilityIdentifier("landingDemoStart")
        }.background { GeometryReader { geometry in Color.clear.preference(key:LandingDemoViewport.self,value:geometry.frame(in:.global)) } }
            .onPreferenceChange(LandingDemoViewport.self) { frame in if demo.active,!frame.intersects(UIScreen.main.bounds) { Task { await demo.stop() } } }
            .onDisappear { Task { await demo.stop() } }.onChange(of:scenePhase) { _,phase in if phase != .active { Task { await demo.stop() } } }
    }
}
private struct LandingDemoViewport:PreferenceKey {
    static var defaultValue:CGRect = .zero
    static func reduce(value:inout CGRect,nextValue:()->CGRect) { value=nextValue() }
}
