import SwiftUI

struct EntryView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @AppStorage("piyali.interfaceLanguage") private var language=EntryCopy.initialLanguage
    @AppStorage("piyali.theme") private var theme="light"
    @FocusState private var focused:Bool
    @State private var signingIn=false
    @State private var displayName=""
    @State private var secret=""
    @State private var busy=false
    @State private var error:String?
    private var brand:PiyaliBrand { PiyaliBrand(dark:scheme == .dark) }
    private func copy(_ key:String) -> String { EntryCopy.text(language,key) }
    var body:some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment:.topTrailing) {
                    BrandBackground()
                    if signingIn { signInCard.frame(minHeight:geometry.size.height) }
                    else { landing }
                    if signingIn { themeButton.padding(20) }
                }
            }.foregroundStyle(brand.text).font(PiyaliBrand.font(16))
                .toolbar(.hidden,for:.navigationBar)
                .toolbar { ToolbarItemGroup(placement:.keyboard) { Spacer();Button("Done") { focused=false }.accessibilityIdentifier("entryKeyboardDone") } }
                .preferredColorScheme(theme == "dark" ? .dark : .light)
                .environment(\.layoutDirection,language == "ar" ? .rightToLeft : .leftToRight)
        }
    }
    private var themeButton:some View {
        Button { theme=theme == "dark" ? "light" : "dark" } label: { Image(systemName:theme == "dark" ? "sun.max.fill" : "moon.stars.fill").font(.system(size:17)).foregroundStyle(Color.orange.opacity(0.8)).frame(width:38,height:38).background(brand.surface.opacity(0.8),in:RoundedRectangle(cornerRadius:12)).overlay { RoundedRectangle(cornerRadius:12).stroke(Color.orange.opacity(0.22)) } }.accessibilityLabel(theme == "dark" ? "Switch to light mode" : "Switch to dark mode")
    }
    private var landing:some View {
        ScrollView {
            VStack(spacing:0) {
                HStack(spacing:10) { BrandArtwork(name:"piyali-orb.png").frame(width:50,height:50);Text("Piyali").font(PiyaliBrand.font(16.8,700));Spacer();themeButton }.padding(.horizontal,12)
                VStack(spacing:0) {
                    VStack(spacing:0) { Text(copy("hero_title")).foregroundStyle(brand.text).frame(height:35.2);Text(copy("hero_title_accent")).foregroundStyle(PiyaliBrand.teal).frame(height:35.2) }.font(PiyaliBrand.font(32,600)).lineSpacing(0).multilineTextAlignment(.center).padding(.bottom,24)
                    Text(EntryCopy.text(language,"heroSubtitle",section:"refresh")).font(PiyaliBrand.font(11.2)).foregroundStyle(brand.secondary).lineSpacing(5).multilineTextAlignment(.center).padding(.bottom,32)
                    VStack(spacing:16) {
                        BrandInput(placeholder:copy("placeholder_name"),text:$displayName).focused($focused).submitLabel(.done).onSubmit { focused=false }.accessibilityIdentifier("entryName")
                        if displayName.trimmingCharacters(in:.whitespacesAndNewlines).lowercased().hasPrefix("nsec1") { Text(copy("create_secret_key_detected_prefix")+copy("create_secret_key_detected_action")+copy("create_secret_key_detected_suffix")).font(PiyaliBrand.font(13)).foregroundStyle(.red) }
                        Button { create() } label: { HStack { if busy { ProgressView().tint(.white) };Text(copy("cta_start")+" →") } }.buttonStyle(BrandButtonStyle(large:true)).disabled(busy || displayName.trimmingCharacters(in:.whitespacesAndNewlines).utf16.count < 2 || displayName.trimmingCharacters(in:.whitespacesAndNewlines).lowercased().hasPrefix("nsec1")).accessibilityIdentifier("createAccount")
                        Button(copy("cta_signin")) { focused=false;signingIn=true;error=nil }.buttonStyle(BrandButtonStyle(primary:false)).accessibilityIdentifier("entrySignIn")
                        Menu { ForEach(LearningLanguages.support,id:\.self) { code in Button(EntryCopy.names[code] ?? code) { language=code } } } label: { HStack(spacing:8) { Text(EntryCopy.flags[language] ?? "🌐");Text(EntryCopy.names[language] ?? language);Image(systemName:"chevron.down").font(.system(size:11)) }.font(PiyaliBrand.font(14,600)).padding(.horizontal,16).padding(.vertical,11).background(brand.surface,in:RoundedRectangle(cornerRadius:12)).overlay { RoundedRectangle(cornerRadius:12).stroke(brand.border) } }.tint(brand.text).padding(.top,8).accessibilityIdentifier("entryLanguage")
                    }
                    if let error { Text(error).foregroundStyle(.red).padding(.top,12) }
                }.padding(.horizontal,24).padding(.top,42)
                LandingAtlasView(language:language)
                LandingSectionsView(language:language) {
                    VStack(spacing:16) {
                        BrandInput(placeholder:copy("placeholder_name"),text:$displayName).focused($focused).submitLabel(.done).onSubmit { focused=false }.accessibilityIdentifier("entryFooterName")
                        if displayName.trimmingCharacters(in:.whitespacesAndNewlines).lowercased().hasPrefix("nsec1") { Text(copy("create_secret_key_detected_prefix")+copy("create_secret_key_detected_action")+copy("create_secret_key_detected_suffix")).font(PiyaliBrand.font(13)).foregroundStyle(.red) }
                        Button { create() } label:{ Text(copy("cta_start")+" →") }.buttonStyle(BrandButtonStyle(large:true)).disabled(busy || displayName.trimmingCharacters(in:.whitespacesAndNewlines).utf16.count < 2 || displayName.trimmingCharacters(in:.whitespacesAndNewlines).lowercased().hasPrefix("nsec1")).accessibilityIdentifier("entryFooterCreate")
                        Button(copy("cta_signin")) { focused=false;signingIn=true;error=nil }.buttonStyle(BrandButtonStyle(primary:false)).accessibilityIdentifier("entryFooterSignIn")
                    }
                }
            }
        }.scrollDismissesKeyboard(.interactively)
    }
    private var signInCard:some View {
        ScrollView {
            VStack(spacing:0) {
                Text(copy("signin_title")).font(PiyaliBrand.font(32,600)).multilineTextAlignment(.center).padding(.bottom,12)
                Text(copy("signin_subtitle")).font(PiyaliBrand.font(16)).foregroundStyle(brand.secondary).multilineTextAlignment(.center).lineSpacing(7).padding(.bottom,32)
                BrandInput(placeholder:copy("signin_placeholder"),text:$secret,secure:true).focused($focused).submitLabel(.done).onSubmit { focused=false }.accessibilityIdentifier("entrySecret")
                if let error { Text(error).font(PiyaliBrand.font(14)).foregroundStyle(.red).padding(.top,12).accessibilityIdentifier("entryError") }
                Button { signIn() } label:{ HStack { if busy { ProgressView().tint(.white) };Text(copy("signin_button")+" →") } }.buttonStyle(BrandButtonStyle()).disabled(busy).padding(.top,16).accessibilityIdentifier("entrySubmitSignIn")
                Button("← "+copy("back_button")) { focused=false;signingIn=false;secret="";error=nil }.font(PiyaliBrand.font(15,600)).foregroundStyle(brand.secondary).padding(.top,40).accessibilityIdentifier("entryBack")
                NavigationLink("Connect a remote signer") { RemoteSignerView() }.font(PiyaliBrand.font(13)).foregroundStyle(brand.secondary).padding(.top,20)
            }.padding(48).frame(maxWidth:440).background(brand.surface.opacity(0.94),in:RoundedRectangle(cornerRadius:24,style:.continuous)).overlay { RoundedRectangle(cornerRadius:24,style:.continuous).stroke(brand.border) }.padding(20)
        }.defaultScrollAnchor(.center).scrollDismissesKeyboard(.interactively)
    }
    private func create() {
        guard !busy else { return };busy=true;error=nil
        Task { await app.signIn(nsec:nil,name:displayName.trimmingCharacters(in:.whitespacesAndNewlines),support:language);busy=false;if !app.signedIn { error=copy("signin_error_generic") } }
    }
    private func signIn() {
        guard !busy else { return }
        let key=secret.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        guard key.hasPrefix("nsec1") else { error=copy("signin_error_invalid_key");return }
        busy=true;error=nil
        Task { await app.signIn(nsec:key);busy=false;if !app.signedIn { app.error=nil;error=copy("signin_error_invalid_key") } else { secret="" } }
    }
}
