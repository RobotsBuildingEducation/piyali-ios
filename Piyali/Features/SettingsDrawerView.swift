import SwiftUI
import StoreKit

struct SettingsDrawerView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    let onClose:()->Void
    let onPlacement:()->Void
    var initialTab="settings"
    var initialPostsInfo=false
    @State private var tab="settings"
    @State private var drag:CGFloat=0
    @State private var postsInfo=false
    @State private var gettingStarted=false
    @State private var wallet=false
    @State private var remote=false
    @State private var signOut=false
    @State private var nameOpen=false
    @State private var switchOpen=false
    @State private var name=""
    @State private var nsec=""
    @State private var switching=false
    @State private var savingName=false
    @State private var pause=1200.0
    @State private var pauseEditing=false
    @StateObject private var persona=SettingsPersonaController()
    @StateObject private var preview=SettingsFixture.preview()
    @StateObject private var backup=KeyBackupController()
    private enum AccountField:Hashable{case name,secret}
    @FocusState private var accountField:AccountField?
    @FocusState private var personaFocused:Bool
    @State private var goalFocused=false
    @State private var toast=""
    private var lang:String{app.learner.support}
    private var scope:String{app.identity.npub}
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    private var data:JSONValue{SettingsUI.effective(app.learner)}
    private var surface:Color{PiyaliBrand.unitColor(scheme == .dark ? "111827":"f1e8dc")}
    private var control:Color{PiyaliBrand.unitColor(scheme == .dark ? "1f2937":"e0d2bf")}
    private func t(_ key:String)->String{let value=EntryCopy.ui(lang,key);return value.isEmpty ? key:value}
    private func label(_ key:String)->String{key == "settings" ? t("ra_settings_title"):key == "account" ? t("app_account_title"):SettingsCopy.subscription(lang,"tab")}
    var body:some View {
        GeometryReader{g in ZStack(alignment:.bottom){
            Color.clear.contentShape(Rectangle())
            VStack(spacing:0){
                Capsule().fill(brand.muted.opacity(0.35)).frame(width:52,height:5).padding(.top,12).padding(.bottom,8).frame(maxWidth:.infinity).contentShape(Rectangle()).gesture(DragGesture().onChanged{drag=max(0,$0.translation.height)}.onEnded{if $0.translation.height>90{close()}else{drag=0}})
                ScrollView{VStack(spacing:0){
                HStack{Spacer();Button(action:close){MemoryIcon(name:"close",size:14).frame(width:32,height:32)}.accessibilityLabel(t("close")).accessibilityIdentifier("productPanelClose")}.environment(\.layoutDirection,.leftToRight).padding(.horizontal,28).padding(.bottom,-8)
                HStack(spacing:24){ForEach(["settings","account","subscription"],id:\.self){key in Button{dismissKeyboard();preview.stopAll();tab=key}label:{OnboardingText(text:label(key),size:16,weight:.semibold,lineHeight:24).padding(.top,4).padding(.bottom,12).overlay(alignment:.bottom){Capsule().fill(LinearGradient(colors:[PiyaliBrand.unitColor("76e4f7"),PiyaliBrand.unitColor("38b2ac")],startPoint:.leading,endPoint:.trailing)).frame(height:3).opacity(tab == key ? 1:0)}.fixedSize(horizontal:true,vertical:true).foregroundStyle(tab == key ? brand.text:brand.muted)}.accessibilityIdentifier("settingsTab-"+key).accessibilityAddTraits(tab == key ? .isSelected:[])}}.frame(maxWidth:.infinity).padding(.top,8).padding(.bottom,16)
                VStack(alignment:.leading,spacing:12){
                    switch tab{case "account":account;case "subscription":SettingsSubscriptionView();default:preferences}
                }.frame(maxWidth:600,alignment:.leading).frame(maxWidth:.infinity).padding(.horizontal,28).padding(.bottom,56)
                }}.scrollIndicators(.hidden)
            }.frame(height:g.size.height*0.75).frame(maxWidth:.infinity).background(scheme == .dark ? PiyaliBrand.unitColor("0b1220"):PiyaliBrand.unitColor("fbf7f0"),in:MemoryDrawerShape(radius:48)).overlay{MemoryDrawerShape(radius:48).stroke(PiyaliBrand.unitColor(scheme == .dark ? "94a3b8":"604d38").opacity(scheme == .dark ? 0.42:0.3),lineWidth:3).padding(1.5).padding(.bottom,-3).allowsHitTesting(false)}.overlay(alignment:.topLeading){if personaFocused || goalFocused || accountField != nil{Button("Done"){dismissKeyboard()}.font(PiyaliBrand.productFont(16,600)).frame(height:32).padding(.leading,28).padding(.top,25).accessibilityIdentifier("settingsKeyboardDone")}}.offset(y:drag).blur(radius:postsInfo ? 4:0).allowsHitTesting(!postsInfo && !gettingStarted).disabled(postsInfo || gettingStarted).accessibilityElement(children:.contain).accessibilityHidden(postsInfo || gettingStarted)
            if postsInfo{SettingsPostsInfoView(onClose:{postsInfo=false})}
            if gettingStarted{ZStack{PiyaliBrand.unitColor("020617").opacity(0.82).ignoresSafeArea();GettingStartedView{gettingStarted=false;app.learner.gettingStartedModalShown=true;app.persist()}}}
            if !toast.isEmpty{Text(toast).font(PiyaliBrand.productFont(14)).padding(12).background(surface,in:Capsule()).frame(maxHeight:.infinity,alignment:.top).padding(.top,64).accessibilityIdentifier("settingsToast").allowsHitTesting(false)}
        }.frame(width:g.size.width,height:g.size.height)}.ignoresSafeArea(.container).foregroundStyle(brand.text).buttonStyle(.plain).environment(\.layoutDirection,lang == "ar" ? .rightToLeft:.leftToRight).accessibilityElement(children:.contain).accessibilityIdentifier("settingsDrawer")
            .onAppear{tab=initialTab;postsInfo=initialPostsInfo;name=app.learner.name;pause=Double(app.learner.tutorPauseMilliseconds);persona.load(app)}
            .onChange(of:backup.state){_,state in if state == .copied{notify(t("toast_secret_copied"))}}
            .onChange(of:personaFocused){_,value in persona.focus(value,app)}
            .onChange(of:app.learner.userSettings){_,_ in persona.receive(app)}
            .onChange(of:app.learner.tutorPauseMilliseconds){_,value in if !pauseEditing{pause=Double(value)}}
            .onChange(of:lang){_,_ in persona.receive(app)}
            .onChange(of:scope){_,_ in preview.stopAll();persona.load(app);name=app.learner.name;nsec=""}
            .onDisappear{persona.close(app);preview.stopAll();backup.cancel()}
            .sheet(isPresented:$wallet){NavigationStack{WalletView().toolbar{ToolbarItem(placement:.confirmationAction){Button(t("close")){wallet=false}}}}}
            .sheet(isPresented:$remote){NavigationStack{RemoteSignerView().toolbar{ToolbarItem(placement:.confirmationAction){Button(t("close")){remote=false}}}}}
            .alert(t("app_sign_out_confirm_title"),isPresented:$signOut){Button(t("common_cancel"),role:.cancel){};Button(t("app_sign_out_confirm"),role:.destructive){persona.flush(app);app.flushGoalEditor();app.signOut()}}message:{Text(t("app_sign_out_confirm_body"))}

    }
    private var preferences:some View {
        VStack(alignment:.leading,spacing:12){
            VStack(spacing:16){languagePicker(support:true);languagePicker(support:false)}.frame(maxWidth:320).frame(maxWidth:.infinity)
            Button{personaFocused=false;persona.flush(app);app.flushGoalEditor();onPlacement()}label:{Label(SettingsCopy.inline(lang,"Change proficiency level"),systemImage:"checkmark.seal").font(PiyaliBrand.productFont(14,600)).frame(maxWidth:.infinity,minHeight:50).padding(.horizontal,24).background(scheme == .dark ? PiyaliBrand.unitColor("111827"):PiyaliBrand.unitColor("fffdf9"),in:Capsule()).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "9decf9":"086f83")).overlay{Capsule().stroke(PiyaliBrand.unitColor("00a3c4"))}}.padding(.top,16).accessibilityIdentifier("settingsProficiency")
            LearningGoalEditorView(onFocusChange:{goalFocused=$0})
            VStack(alignment:.leading,spacing:16){
                OnboardingText(text:t("onboarding_section_voice_persona"),size:14,weight:.semibold,lineHeight:21)
                VStack(alignment:.leading,spacing:4){OnboardingText(text:t("settings_voice") == "settings_voice" ? t("onboarding_voice_title"):t("settings_voice"),size:12,weight:.semibold,lineHeight:18).foregroundStyle(brand.muted)
                    let voices=SettingsUI.run("voices",.object(["provider":.string("openai"),"voice":data["progress"]["tutorVoice"]])),selected=voices["selected"]
                    Menu{ForEach(voices["options"].array,id:\.canonicalJSON){voice in Button{persona.flush(app);app.updateSettings(.object(["tutorVoice":voice["value"],"tutorVoicePersona":.string(persona.draft)]));playPreview(voice["value"].string)}label:{Label(voiceLabel(voice),systemImage:voice["type"].string == "girl" ? "person.fill":"person.fill")}.accessibilityIdentifier("settingsVoice-"+voice["value"].string)}}label:{HStack(spacing:8){if preview.loading{ProgressView().scaleEffect(0.7)}else{Image(systemName:"person.fill").foregroundStyle(selected["type"].string == "girl" ? Color.pink:Color.cyan)};Text(voiceLabel(selected));Spacer();Image(systemName:"chevron.down").font(.system(size:12))}.font(PiyaliBrand.productFont(14,600)).padding(.horizontal,20).frame(minHeight:42).background(surface,in:Capsule()).overlay{Capsule().stroke(brand.border)}}.accessibilityIdentifier("settingsVoice")
                }
                VStack(alignment:.leading,spacing:0){OnboardingText(text:t("ra_persona_label"),size:14,lineHeight:21).padding(.bottom,8);TextEditor(text:Binding(get:{persona.draft},set:{persona.change($0,app)})).font(PiyaliBrand.productFont(16)).scrollContentBackground(.hidden).padding(8).frame(height:84).background(control,in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(personaFocused ? .blue:brand.border)}.focused($personaFocused).accessibilityIdentifier("settingsPersona");HStack{Spacer();if persona.saved{Text(app.goalText("saved")).font(PiyaliBrand.productFont(12)).foregroundStyle(brand.muted).accessibilityIdentifier("settingsPersonaSaved")}}.frame(minHeight:18).padding(.top,4)}
                if let error=preview.error{Text(error).font(PiyaliBrand.productFont(12)).foregroundStyle(.red)}
            }.settingsCard(surface)
            VStack(alignment:.leading,spacing:8){HStack(alignment:.top){OnboardingText(text:t("ra_vad_label"),size:14,lineHeight:21);Spacer();Text((pause/1000).formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier:lang)))+" "+SettingsCopy.inline(lang,"seconds")).font(PiyaliBrand.productFont(14)).opacity(0.8).fixedSize()};Slider(value:$pause,in:200...4000,step:100,onEditingChanged:{editing in pauseEditing=editing;if !editing{app.updateSettings(.object(["pauseMs":.number(pause)]))}}).tint(PiyaliBrand.unitColor("3cb371")).accessibilityIdentifier("settingsPause")}.settingsCard(surface)
            switchCard(t("sound_effects_label"),detail:t(app.learner.soundEffectsEnabled ? "sound_effects_enabled":"sound_effects_disabled"),value:app.learner.soundEffectsEnabled,id:"settingsSound"){app.updateSettings(.object(["soundEnabled":.bool($0)]))}
            VStack(alignment:.leading,spacing:8){HStack{Text(t("teams_feed_allow_label")).font(PiyaliBrand.productFont(14));Button{dismissKeyboard();postsInfo=true}label:{Image(systemName:"info.circle").font(.system(size:14)).foregroundStyle(brand.muted).frame(width:24,height:24)}.accessibilityLabel(t("allow_posts_info_aria")).accessibilityIdentifier("settingsPostsInfo");Spacer();Toggle("",isOn:Binding(get:{app.learner.automaticPostsEnabled},set:{app.updateSettings(.object(["allowPosts":.bool($0)]))})).labelsHidden().tint(PiyaliBrand.teal).accessibilityLabel(t("teams_feed_allow_label")).accessibilityIdentifier("settingsPosts")};OnboardingText(text:t(app.learner.automaticPostsEnabled ? "teams_feed_allow_enabled":"teams_feed_allow_disabled"),size:12,lineHeight:18).opacity(0.6)}.settingsCard(surface)
            SettingsThemeField(onChange:{personaFocused=false;app.updateSettings(.object(["themeMode":.string($0)]))})
        }
    }
    private func switchCard(_ title:String,detail:String,value:Bool,id:String,onChange:@escaping(Bool)->Void)->some View{VStack(alignment:.leading,spacing:8){Toggle(title,isOn:Binding(get:{value},set:onChange)).font(PiyaliBrand.productFont(14)).tint(PiyaliBrand.teal).accessibilityIdentifier(id);OnboardingText(text:detail,size:12,lineHeight:18).opacity(0.6)}.settingsCard(surface)}
    private func languagePicker(support:Bool)->some View{
        let options=SettingsUI.options[lang]?[support ? "support":"practice"].array ?? [],code=support ? lang:app.learner.target
        return VStack(alignment:.leading,spacing:4){OnboardingText(text:t(support ? "onboarding_support_menu_label":"onboarding_practice_menu_label"),size:12,weight:.semibold,lineHeight:18).foregroundStyle(brand.muted)
            Menu{ForEach(options,id:\.canonicalJSON){option in Button(option["label"].string){personaFocused=false;persona.flush(app);app.flushGoalEditor();preview.stopAll();if support{app.settingsSupportLanguage(option["value"].string)}else{app.setPracticeLanguage(option["value"].string)}}.accessibilityIdentifier("settingsLanguage-"+(support ? "support-":"practice-")+option["value"].string)}}label:{HStack(spacing:8){Image("LanguageFlag-"+code).resizable().scaledToFit().frame(width:24,height:24);Text(options.first{$0["value"].string == code}?["label"].string ?? code);Spacer();Image(systemName:"chevron.down").font(.system(size:12))}.font(PiyaliBrand.productFont(14,600)).padding(.horizontal,20).frame(minHeight:42).background(surface,in:Capsule()).overlay{Capsule().stroke(brand.border)}}.tint(brand.text).accessibilityIdentifier(support ? "supportLanguagePicker":"practiceLanguagePicker")
        }
    }
    private func voiceLabel(_ voice:JSONValue)->String {let key="onboarding_voice_"+voice["value"].string,value=t(key);return !voice["label"].string.isEmpty ? voice["label"].string:value == key ? voice["value"].string.capitalized:value}
    private func playPreview(_ voice:String){let p=SettingsUI.run("preview",.object(["voice":.string(voice),"language":.string(lang),"persona":.string(persona.draft),"target":.string(app.learner.target),"provider":.string("openai")]));preview.play(p["text"].string,language:p["language"].string,engine:app.companionQuestPolicy,voice:voice,sessionOverride:p["session"],startupMilliseconds:9000)}
    private func dismissKeyboard(){personaFocused=false;goalFocused=false;accountField=nil;UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),to:nil,from:nil,for:nil);persona.flush(app);app.flushGoalEditor()}
    private func close(){dismissKeyboard();persona.flush(app);app.flushGoalEditor();preview.stopAll();onClose()}
    private func notify(_ message:String){toast=message;Task{try? await Task.sleep(for:.milliseconds(1400));if toast == message{toast=""}}}
    private var account:some View{
        VStack(alignment:.leading,spacing:12){
            HStack(spacing:12){Button(t("app_copy_id")){UIPasteboard.general.string=app.identity.npub;notify(t("toast_id_copied"))}.buttonStyle(SettingsActionStyle(color:"319795"));Button(t("app_copy_secret")){Task{await backup.copy(identity:app.identity,reason:t("app_copy_secret"))}}.buttonStyle(SettingsActionStyle(color:"dd6b20")).disabled(app.identity.isRemote || backup.state == .working).accessibilityIdentifier("settingsCopySecret")}.frame(maxWidth:.infinity)
            if backup.state == .failed{Text(FirstRunCopy.text(lang,3)).font(PiyaliBrand.productFont(12)).foregroundStyle(.red)}
            accordion(SettingsCopy.inline(lang,"Change display name"),open:$nameOpen,id:"settingsNameAccordion"){
                TextField(SettingsCopy.inline(lang,"Enter a display name"),text:$name).focused($accountField,equals:.name).textFieldStyle(.plain).padding(12).background(control,in:RoundedRectangle(cornerRadius:6)).accessibilityIdentifier("settingsDisplayName")
                HStack{Spacer();Button(SettingsCopy.inline(lang,"Save")){let value=name.trimmingCharacters(in:.whitespacesAndNewlines);guard !value.isEmpty else{notify(SettingsCopy.inline(lang,"Enter a display name"));return};savingName=true;Task{let saved=await app.settingsSaveDisplayName(value);savingName=false;if saved{notify(SettingsCopy.inline(lang,"Display name updated"))}}}.buttonStyle(SettingsActionStyle(color:"319795")).disabled(savingName).accessibilityIdentifier("settingsNameSave")}
            }
            accordion(t("app_switch_account"),open:$switchOpen,id:"settingsSwitchAccordion"){
                OnboardingText(text:t("app_switch_note"),size:12,lineHeight:18).foregroundStyle(brand.secondary)
                SecureField(t("app_nsec_placeholder"),text:$nsec).focused($accountField,equals:.secret).textInputAutocapitalization(.never).autocorrectionDisabled().padding(12).background(control,in:RoundedRectangle(cornerRadius:6)).accessibilityIdentifier("settingsSwitchKey")
                HStack{Button(EntryCopy.text(lang,"login_extension_button")){remote=true}.font(PiyaliBrand.productFont(12));Spacer();Button(t(switching ? "app_switching":"app_switch")){persona.flush(app);app.flushGoalEditor();switching=true;Task{let changed=await app.settingsSwitchAccount(nsec);switching=false;if changed{nsec="";close()}}}.buttonStyle(SettingsActionStyle(color:"319795")).disabled(switching || nsec.isEmpty).accessibilityIdentifier("settingsSwitchAccount")}
            }
            Button{wallet=true}label:{HStack{Text(SettingsCopy.inline(lang,"Bitcoin wallet")).font(PiyaliBrand.productFont(16,600));Spacer();Image(systemName:"chevron.down")}.padding(.horizontal,16).padding(.vertical,12).background(scheme == .dark ? PiyaliBrand.unitColor("1f2937"):PiyaliBrand.unitColor("fbf7f0"),in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(brand.border)}}.accessibilityIdentifier("walletLink")
            VStack(alignment:.leading,spacing:12){OnboardingText(text:t("app_install_title"),size:16,weight:.semibold,lineHeight:24);Button{gettingStarted=true}label:{HStack{Image(systemName:"checkmark.seal");Text(t("app_install_step5"));Spacer();Image(systemName:"chevron.right")}.font(PiyaliBrand.productFont(14)).padding(12).background(scheme == .dark ? PiyaliBrand.unitColor("1f2937"):PiyaliBrand.unitColor("fbf7f0"),in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(brand.border)}}.accessibilityIdentifier("accountGettingStarted")}.padding(.top,24)
            HStack{Spacer();Button{signOut=true}label:{Label(t("app_sign_out"),systemImage:"rectangle.portrait.and.arrow.right").font(PiyaliBrand.productFont(14,600)).padding(.horizontal,24).frame(minHeight:48).foregroundStyle(PiyaliBrand.unitColor("e53e3e")).overlay{Capsule().stroke(PiyaliBrand.unitColor("e53e3e"))}}.padding(.top,24).accessibilityIdentifier("settingsSignOut")}
        }
    }
    private func accordion<Content:View>(_ title:String,open:Binding<Bool>,id:String,@ViewBuilder content:()->Content)->some View {VStack(spacing:0){Button{open.wrappedValue.toggle()}label:{HStack{OnboardingText(text:title,size:16,weight:.semibold,lineHeight:24);Spacer();Image(systemName:open.wrappedValue ? "chevron.up":"chevron.down").font(.system(size:14))}.padding(.horizontal,16).padding(.vertical,12).contentShape(Rectangle())}.accessibilityIdentifier(id);if open.wrappedValue{VStack(alignment:.leading,spacing:8,content:content).padding(12).background(control.opacity(0.4),in:RoundedRectangle(cornerRadius:6)).padding(12)}}.background(scheme == .dark ? PiyaliBrand.unitColor("1f2937"):PiyaliBrand.unitColor("fbf7f0"),in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(brand.border)}.accessibilityElement(children:.contain)}
}
struct SettingsActionStyle:ButtonStyle {let color:String;func makeBody(configuration:Configuration)->some View{configuration.label.font(PiyaliBrand.productFont(14,600)).padding(.horizontal,24).frame(minHeight:42).foregroundStyle(.white).background(PiyaliBrand.unitColor(color),in:Capsule()).background(Capsule().fill(PiyaliBrand.unitColor(color == "dd6b20" ? "7b341e":color == "805ad5" ? "553c9a":"205b5b")).offset(y:configuration.isPressed ? 0:4)).offset(y:configuration.isPressed ? 4:0).padding(.bottom,4)}}
private struct SettingsCard:ViewModifier {let color:Color;func body(content:Content)->some View{content.frame(maxWidth:.infinity,alignment:.leading).padding(12).background(color,in:RoundedRectangle(cornerRadius:6))}}
extension View {func settingsCard(_ color:Color)->some View{modifier(SettingsCard(color:color))}}
