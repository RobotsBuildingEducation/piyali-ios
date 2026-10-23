import SwiftUI

struct EntryView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("piyali.interfaceLanguage") private var language=EntryCopy.initialLanguage
    @AppStorage("piyali.theme") private var theme="light"
    private enum Field:Hashable {case heroName,footerName,secret}
    @FocusState private var focused:Field?
    @State private var signingIn=false
    @State private var displayName=""
    @State private var secret=""
    @State private var busy=false
    @State private var error:String?
    @State private var heroRect:CGRect?
    @State private var headerRect:CGRect = .zero
    private static let supportOptions=(try? ContentLibrary.load([String:[JSONValue]].self,name:"entry-support-options")) ?? [:]
    private var options:[JSONValue] {Self.supportOptions[language] ?? Self.supportOptions["en"] ?? []}
    private var brand:PiyaliBrand {PiyaliBrand(dark:scheme == .dark)}
    private var header:EntryPolicy.Header {EntryPolicy.header(scrollY:heroRect.map{Double(headerRect.minY-$0.minY)} ?? 0,heroBottom:headerRect.height>0 ? heroRect.map{Double($0.maxY-headerRect.minY)} : nil)}
    private var canCreate:Bool {EntryPolicy.registrationName(displayName,busy:busy) != nil}
    private var secretInName:Bool {displayName.trimmingCharacters(in:.whitespacesAndNewlines).lowercased().hasPrefix("nsec1")}
    private func copy(_ key:String)->String {EntryCopy.text(language,key)}
    var body:some View {
        NavigationStack {
            GeometryReader {geometry in
                ZStack(alignment:.top) {
                    EntryBackground()
                    if signingIn {
                        signInCard(height:geometry.size.height)
                        HStack {Spacer();EntryThemeButton(mode:$theme)}.padding(.trailing,20).padding(.top,18).environment(\.layoutDirection,.leftToRight)
                    } else {
                        landing.environment(\.entryHeaderBounds,headerRect)
                        landingHeader
                    }
                }
            }.foregroundStyle(brand.text).font(PiyaliBrand.font(16))
                .toolbar(.hidden,for:.navigationBar)
                .toolbar {ToolbarItemGroup(placement:.keyboard) {Spacer();Button("Done") {focused=nil}.accessibilityIdentifier("entryKeyboardDone")}}
                .preferredColorScheme(theme == "dark" ? .dark : .light)
                .environment(\.layoutDirection,language == "ar" ? .rightToLeft : .leftToRight)
        }
    }
    private var landingHeader:some View {
        HStack(spacing:8) {
            HStack(spacing:10) {PublicVoiceOrb(animating:scenePhase == .active,size:50,showShadow:false).frame(width:50,height:50).accessibilityIdentifier("entryHeaderOrb");Text("Piyali").font(PiyaliBrand.font(16.8,700)).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "f8fafc" : "2a2119")).fixedSize()}
            Spacer(minLength:0)
            HStack(spacing:6) {
                if header.actions {
                    Button {create(instant:true)} label:{if busy {ProgressView().tint(.white)} else {Text(copy("cta_start"))}}.buttonStyle(EntryButtonStyle(compact:true,fullWidth:false)).disabled(busy).accessibilityIdentifier("entryHeaderCreate")
                    Button(copy("nav_signin"),action:openSignIn).buttonStyle(EntryButtonStyle(variant:.secondary,compact:true,fullWidth:false)).accessibilityIdentifier("entryHeaderSignIn")
                }
                EntryThemeButton(mode:$theme,compact:true)
            }
        }.padding(.horizontal,10).padding(.vertical,8).background {if header.scrolled {PiyaliBrand.unitColor(scheme == .dark ? "060a16" : "fcf8f0").ignoresSafeArea(edges:.top).shadow(color:scheme == .dark ? .black.opacity(0.28) : .clear,radius:15,y:10)}}.background {GeometryReader {g in Color.clear.preference(key:EntryHeaderFrame.self,value:g.frame(in:.global))}}.onPreferenceChange(EntryHeaderFrame.self){headerRect=$0}.accessibilityElement(children:.contain).accessibilityIdentifier("entryHeader")
    }
    private var landing:some View {
        ScrollView {
            VStack(spacing:0) {
                hero.background {GeometryReader {g in Color.clear.preference(key:EntryHeroFrame.self,value:g.frame(in:.global))}}
                LandingAtlasView(language:language)
                LandingSectionsView(language:language) {
                    VStack(spacing:16) {
                        BrandInput(placeholder:copy("placeholder_name"),text:$displayName,highlighted:focused == .footerName).focused($focused,equals:.footerName).submitLabel(.done).onSubmit {focused=nil}.accessibilityIdentifier("entryFooterName")
                        if secretInName {nameWarning}
                        Button {create()} label:{Text(copy("cta_start")+" →")}.buttonStyle(EntryButtonStyle(large:true)).disabled(!canCreate).accessibilityIdentifier("entryFooterCreate")
                        Button(copy("cta_signin"),action:openSignIn).buttonStyle(EntryButtonStyle(variant:.secondary)).accessibilityIdentifier("entryFooterSignIn")
                    }
                }
            }
        }.onPreferenceChange(EntryHeroFrame.self){heroRect=$0}.scrollDismissesKeyboard(.interactively)
    }
    private var hero:some View {
        VStack(spacing:0) {
            EntryHeroTitle(title:copy("hero_title"),accent:copy("hero_title_accent"),language:language,color:brand.text).padding(.bottom,24).accessibilityIdentifier("entryHeroTitle")
            EntryLineText(text:EntryCopy.text(language,"heroSubtitle",section:"refresh"),size:11.2).foregroundStyle(brand.secondary).multilineTextAlignment(.center).padding(.bottom,32).accessibilityIdentifier("entryHeroSubtitle")
            VStack(spacing:16) {
                BrandInput(placeholder:copy("placeholder_name"),text:$displayName,highlighted:focused == .heroName).focused($focused,equals:.heroName).submitLabel(.done).onSubmit {focused=nil}.accessibilityIdentifier("entryName")
                if secretInName {nameWarning}
                Button {create()} label:{if busy {ProgressView().tint(.white)} else {Text(copy("cta_start")+" →")}}.buttonStyle(EntryButtonStyle(large:true)).disabled(!canCreate).accessibilityIdentifier("createAccount")
                Button(copy("cta_signin"),action:openSignIn).buttonStyle(EntryButtonStyle(variant:.secondary)).accessibilityIdentifier("entrySignIn")
                languageMenu
            }
            if let error {EntryLineText(text:error,size:14).foregroundStyle(PiyaliBrand.unitColor("f87171")).padding(.top,12).accessibilityIdentifier("entryCreationError")}
        }.frame(maxWidth:800).padding(.horizontal,24).padding(.top,92).frame(maxWidth:.infinity).background {EntryFloatingGreetings(active:scenePhase == .active && (heroRect?.maxY ?? 1)>0)}
    }
    private var nameWarning:some View {EntryLineText(text:copy("create_secret_key_detected_prefix")+copy("create_secret_key_detected_action")+copy("create_secret_key_detected_suffix"),size:14,lineHeight:21).foregroundStyle(PiyaliBrand.unitColor("f87171")).multilineTextAlignment(.center).accessibilityIdentifier("entryNameWarning")}
    private var languageMenu:some View {
        Menu {ForEach(options.indices,id:\.self) {index in let option=options[index];Button(option["label"].string){language=option["value"].string}.accessibilityIdentifier("entrySupportOption-"+option["value"].string)}} label:{HStack(spacing:8) {Text(EntryCopy.flags[language] ?? "🌐");Text(options.first{$0["value"].string == language}?["label"].string ?? language);Image(systemName:"chevron.down").font(.system(size:11))}.font(PiyaliBrand.font(14,600)).padding(.horizontal,16).frame(minWidth:150,minHeight:42).background(PiyaliBrand.unitColor(scheme == .dark ? "0b1220" : "fffcf7").opacity(scheme == .dark ? 0.66 : 0.94),in:EntryCornerShape()).overlay {EntryCornerShape().stroke(brand.border)}}.tint(brand.text).padding(.top,8).accessibilityIdentifier("entryLanguage")
    }
    private func signInCard(height:CGFloat)->some View {
        ScrollView {
            VStack(spacing:0) {
                EntryLineText(text:copy("signin_title"),size:32,weight:600).multilineTextAlignment(.center).padding(.bottom,12)
                EntryLineText(text:copy("signin_subtitle")).foregroundStyle(brand.secondary).multilineTextAlignment(.center).padding(.bottom,32)
                VStack(spacing:16) {
                    BrandInput(placeholder:copy("signin_placeholder"),text:$secret,secure:true,highlighted:focused == .secret).focused($focused,equals:.secret).submitLabel(.done).onSubmit {focused=nil}.accessibilityIdentifier("entrySecret")
                    if let error {EntryLineText(text:error,size:14).foregroundStyle(PiyaliBrand.unitColor("f87171")).multilineTextAlignment(.center).accessibilityIdentifier("entryError")}
                    Button {signIn()} label:{if busy {ProgressView().tint(.white)} else {Text(copy("signin_button")+" →")}}.buttonStyle(EntryButtonStyle()).disabled(busy).accessibilityIdentifier("entrySubmitSignIn")
                    HStack(spacing:16) {Rectangle().fill(brand.border).frame(height:1);Text(copy("signin_or")).font(PiyaliBrand.font(14)).foregroundStyle(brand.muted);Rectangle().fill(brand.border).frame(height:1)}.padding(.vertical,8)
                    NavigationLink {RemoteSignerView().toolbar(.visible,for:.navigationBar).navigationBarTitleDisplayMode(.inline)} label:{Text(remoteSignerLabel)}.buttonStyle(EntryButtonStyle(variant:.secondary)).accessibilityIdentifier("entryRemoteSigner")
                    Button("← "+copy("back_button")) {focused=nil;signingIn=false;secret="";error=nil}.buttonStyle(EntryButtonStyle(variant:.ghost)).padding(.top,8).accessibilityIdentifier("entryBack")
                }
            }.padding(49).frame(maxWidth:440).background(PiyaliBrand.unitColor(scheme == .dark ? "0b1220" : "fffcf7").opacity(scheme == .dark ? 0.66 : 0.94),in:EntryCornerShape(radius:32)).overlay {EntryCornerShape(radius:32).stroke(brand.border)}.padding(20).frame(maxWidth:.infinity,minHeight:height)
        }.scrollDismissesKeyboard(.interactively)
    }
    private var remoteSignerLabel:String { ["en":"Connect a remote signer","es":"Conectar un firmante remoto","pt":"Conectar um assinador remoto","fr":"Connecter un signataire distant","it":"Collega un firmatario remoto","de":"Mit Remote-Signer verbinden","ja":"リモート署名者に接続","hi":"रिमोट साइनर जोड़ें","ar":"ربط موقّع عن بُعد","zh":"连接远程签名器"][language] ?? "Connect a remote signer" }
    private func openSignIn() {focused=nil;error=nil;signingIn=true}
    private func create(instant:Bool=false) {
        guard let name=EntryPolicy.registrationName(displayName,instant:instant,busy:busy) else{return};focused=nil;busy=true;error=nil
        Task {await app.signIn(nsec:nil,name:name,support:language);busy=false;if !app.signedIn {app.error=nil;error=copy("signin_error_generic")}}
    }
    private func signIn() {
        guard !busy else{return};let key=secret.trimmingCharacters(in:.whitespacesAndNewlines);guard !key.isEmpty else{return}
        guard key.hasPrefix("nsec1") else {error=copy("signin_error_invalid_key");return};busy=true;error=nil
        Task {await app.signIn(nsec:key);busy=false;if !app.signedIn {let code=EntryPolicy.signInError(app.error ?? "");app.error=nil;error=copy(code)} else {secret=""}}
    }
}
private struct EntryHeroFrame:PreferenceKey {
    static var defaultValue:CGRect?=nil
    static func reduce(value:inout CGRect?,nextValue:()->CGRect?){value=nextValue() ?? value}
}
private struct EntryHeaderFrame:PreferenceKey {
    static var defaultValue:CGRect = .zero
    static func reduce(value:inout CGRect,nextValue:()->CGRect){let next=nextValue();if next.height>0 {value=next}}
}
