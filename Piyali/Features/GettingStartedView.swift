import SwiftUI

struct GettingStartedView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    let onClose:()->Void
    @StateObject private var backup=KeyBackupController()
    @State private var webSteps=false
    @State private var headerHeight:CGFloat=140
    @State private var bodyHeight:CGFloat=240
    private var language:String {app.learner.support}
    private var brand:PiyaliBrand {PiyaliBrand(dark:scheme == .dark)}
    private var surface:Color {PiyaliBrand.unitColor(scheme == .dark ? "0b1220" : "fffdf9")}
    private var mutedSurface:Color {PiyaliBrand.unitColor(scheme == .dark ? "111827" : "efe4d5")}
    private func t(_ key:String)->String {EntryCopy.ui(language,key)}
    var body:some View {
        GeometryReader {g in
            VStack(spacing:0) {
                header.onGeometryChange(for:CGFloat.self,of:{$0.size.height}){headerHeight=$0}
                ScrollView {
                    VStack(spacing:8) {
                        LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:8) {
                            tile(icon:"checkmark.seal",text:t("app_install_step5"))
                            if !app.identity.isRemote {
                                Button {Task {await backup.copy(identity:app.identity,reason:t("app_copy_secret"))}} label:{tile(icon:"key",text:t("app_install_step6"))}.buttonStyle(.plain).disabled(backup.state == .working).accessibilityIdentifier("gettingStartedCopy")
                            } else {tile(icon:"key",text:FirstRunCopy.text(language,4))}
                        }
                        OnboardingText(text:t("app_secret_note"),size:10,lineHeight:14.5).foregroundStyle(brand.secondary).multilineTextAlignment(.center)
                        if backup.state == .working {ProgressView().accessibilityLabel(t("app_copy_secret"))}
                        if backup.state == .copied {OnboardingText(text:t("app_install_copied"),size:12,weight:.semibold).foregroundStyle(PiyaliBrand.teal).accessibilityIdentifier("gettingStartedCopied")}
                        if backup.state == .failed {OnboardingText(text:FirstRunCopy.text(language,3),size:12).foregroundStyle(brand.questionError).accessibilityIdentifier("gettingStartedBackupError")}
                        DisclosureGroup(isExpanded:$webSteps) {
                            LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:8) {
                                ForEach(1...5,id:\.self) {i in tile(icon:["ellipsis","arrow.up.right.square","square.and.arrow.up","plus.app","checkmark.seal"][i-1],text:"\(i). "+t("app_install_step\(i)").replacingOccurrences(of:"{home}",with:"⊞").replacingOccurrences(of:"{app}",with:"▣"))}
                            }.padding(.top,8).accessibilityIdentifier("gettingStartedWebSteps")
                            Link(destination:AppConfiguration().web) {Label(t("app_install_step2"),systemImage:"arrow.up.right.square")}.font(PiyaliBrand.productFont(12,600)).padding(.top,8).accessibilityIdentifier("gettingStartedWebLink")
                        } label:{Text(FirstRunCopy.text(language,2)).font(PiyaliBrand.productFont(12,600))}.tint(brand.text)
                        Button(t("app_install_got_it"),action:onClose).buttonStyle(GettingStartedActionStyle()).accessibilityIdentifier("gettingStartedGotIt")
                        OnboardingText(text:t("app_install_footer_note")+" ⚙︎ "+t("app_install_footer_icon_label"),size:10,lineHeight:14.5).foregroundStyle(brand.muted).multilineTextAlignment(.center)
                    }.padding(.horizontal,16).padding(.vertical,12).onGeometryChange(for:CGFloat.self,of:{$0.size.height}){bodyHeight=$0}
                }
            }.frame(width:min(g.size.width*0.9,448),height:min(g.size.height-24,headerHeight+bodyHeight)).background(surface,in:EntryCornerShape(radius:24)).clipShape(EntryCornerShape(radius:24)).overlay {EntryCornerShape(radius:24).stroke(PiyaliBrand.unitColor(scheme == .dark ? "94a3b8" : "604d38").opacity(scheme == .dark ? 0.42 : 0.3),lineWidth:3).padding(1.5)}.frame(maxWidth:.infinity,maxHeight:.infinity)
        }.foregroundStyle(brand.text).onDisappear {backup.cancel()}.onChange(of:app.identity.npub){_,_ in backup.cancel()}.onChange(of:scenePhase){_,phase in if phase == .background {backup.cancel()}}.accessibilityElement(children:.contain).accessibilityIdentifier("gettingStartedDialog")
    }
    private var header:some View {
        VStack(spacing:4) {
            BrandArtwork(name:"getting-started-character.webp").frame(width:40,height:40).frame(height:52).accessibilityHidden(true)
            OnboardingText(text:FirstRunCopy.text(language,0),size:14,weight:.bold).accessibilityAddTraits(.isHeader).accessibilityIdentifier("gettingStartedTitle")
            OnboardingText(text:FirstRunCopy.text(language,1),size:10,weight:.medium,lineHeight:13.5).opacity(0.92)
        }.multilineTextAlignment(.center).foregroundStyle(.white).frame(maxWidth:.infinity).padding(.horizontal,16).padding(.vertical,12).background(LinearGradient(colors:[PiyaliBrand.unitColor("6366f1"),PiyaliBrand.unitColor("8b5cf6")],startPoint:.leading,endPoint:.trailing))
    }
    private func tile(icon:String,text:String)->some View {
        VStack(spacing:4) {Image(systemName:icon).font(.system(size:22)).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "81e6d9" : "3d9e95")).accessibilityHidden(true);OnboardingText(text:text,size:10,weight:.medium,lineHeight:13.5).multilineTextAlignment(.center)}.frame(maxWidth:.infinity,minHeight:60).padding(8).background(mutedSurface,in:RoundedRectangle(cornerRadius:6)).overlay {RoundedRectangle(cornerRadius:6).stroke(brand.border)}.contentShape(Rectangle())
    }
}
private struct GettingStartedActionStyle:ButtonStyle {
    func makeBody(configuration:Configuration)->some View {configuration.label.font(PiyaliBrand.productFont(16,700)).foregroundStyle(.white).frame(maxWidth:.infinity,minHeight:44).background {EntryCornerShape().fill(PiyaliBrand.unitColor("805ad5")).shadow(color:PiyaliBrand.unitColor("44337a"),radius:0,y:configuration.isPressed ? 0 : 4)}.offset(y:configuration.isPressed ? 3 : 0)}
}
