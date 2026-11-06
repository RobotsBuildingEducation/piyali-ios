import SwiftUI

struct PiyaliBrand {
    let dark:Bool
    var background:Color { Color(piyaliHex:dark ? 0x0b1220 : 0xf7f1e7) }
    var surface:Color { Color(piyaliHex:dark ? 0x111827 : 0xfffdf9) }
    var text:Color { Color(piyaliHex:dark ? 0xe5e7eb : 0x2f261d) }
    var secondary:Color { Color(piyaliHex:dark ? 0xcbd5e1 : 0x5b4b3a) }
    var muted:Color { Color(piyaliHex:dark ? 0xa3b4c9 : 0x8d7a67) }
    var border:Color { Color(piyaliHex:dark ? 0x94a3b8 : 0x604d38).opacity(dark ? 0.2 : 0.16) }
    static let teal=Color(piyaliHex:0x14b8a6)
    static func unitColor(_ hex:String)->Color { let value=hex.trimmingCharacters(in:CharacterSet(charactersIn:"#"));guard value.count == 6,let code=UInt32(value,radix:16) else { return Color(piyaliHex:0x6366f1) };return Color(piyaliHex:code) }
    var questionChoice:Color { Color(piyaliHex:dark ? 0xa78bfa : 0x7c3aed) }
    var questionChoiceBackground:Color { questionChoice.opacity(dark ? 0.18 : 0.10) }
    var questionChip:Color { Color(piyaliHex:dark ? 0xc4b5fd : 0x7c3aed) }
    var questionChipBackground:Color { Color(piyaliHex:dark ? 0xa78bfa : 0x7c3aed).opacity(dark ? 0.16 : 0.10) }
    var questionTool:Color { Color(piyaliHex:dark ? 0x7dd3fc : 0x1d4ed8) }
    var questionSuccess:Color { Color(piyaliHex:dark ? 0x4ade80 : 0x16a34a) }
    var questionError:Color { Color(piyaliHex:dark ? 0xf87171 : 0xdc2626) }
    static func font(_ size:CGFloat,_ weight:Int=400) -> Font { .custom(weight == 700 ? "DMSans-Bold" : weight == 600 ? "DMSans-SemiBold" : weight == 500 ? "DMSans-Medium" : "DMSans-Regular",size:size) }
    static func productFont(_ size:CGFloat,_ weight:Int=400)->Font { .system(size:size,weight:weight >= 800 ? .heavy : weight >= 700 ? .bold : weight >= 600 ? .semibold : weight >= 500 ? .medium : .regular) }
}
struct QuestionPrimaryButtonStyle:ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration:Configuration)->some View {
        configuration.label.font(PiyaliBrand.productFont(16,600)).frame(maxWidth:.infinity,minHeight:52).foregroundStyle(.white).background(Color(piyaliHex:0x805ad5),in:RoundedRectangle(cornerRadius:16)).opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.45)
    }
}
private extension Color {
    init(piyaliHex:UInt32) { self.init(.sRGB,red:Double((piyaliHex>>16)&255)/255,green:Double((piyaliHex>>8)&255)/255,blue:Double(piyaliHex&255)/255,opacity:1) }
}
struct BrandBackground:View {
    @Environment(\.colorScheme) private var scheme
    var body:some View {
        let brand=PiyaliBrand(dark:scheme == .dark)
        GeometryReader { geometry in
            ZStack {
                brand.background
                RadialGradient(colors:[Color.orange.opacity(scheme == .dark ? 0.03 : 0.045),.clear],center:.topTrailing,startRadius:0,endRadius:420)
                RadialGradient(colors:[PiyaliBrand.teal.opacity(0.04),.clear],center:.bottomLeading,startRadius:0,endRadius:500)
                Path { path in
                    for x in stride(from:CGFloat(0),through:geometry.size.width,by:60) { path.move(to:CGPoint(x:x,y:0));path.addLine(to:CGPoint(x:x,y:geometry.size.height)) }
                    for y in stride(from:CGFloat(0),through:geometry.size.height,by:60) { path.move(to:CGPoint(x:0,y:y));path.addLine(to:CGPoint(x:geometry.size.width,y:y)) }
                }.stroke(brand.border.opacity(0.18),lineWidth:0.5)
            }
        }.ignoresSafeArea()
    }
}
struct BrandButtonStyle:ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var enabled
    var primary=true
    var large=false
    func makeBody(configuration:Configuration) -> some View {
        let brand=PiyaliBrand(dark:scheme == .dark)
        configuration.label.font(PiyaliBrand.font(large ? 18 : 16,600)).frame(maxWidth:.infinity,minHeight:large ? 64 : 52)
            .foregroundStyle(primary ? Color.white : brand.text)
            .background { if primary { RoundedRectangle(cornerRadius:20,style:.continuous).fill(LinearGradient(colors:[PiyaliBrand.teal,Color(red:0.051,green:0.58,blue:0.533)],startPoint:.topLeading,endPoint:.bottomTrailing)) } }
            .overlay { if !primary { RoundedRectangle(cornerRadius:20,style:.continuous).stroke(PiyaliBrand.teal.opacity(0.3)) } }
            .shadow(color:primary ? PiyaliBrand.teal.opacity(enabled ? 0.2 : 0.1) : .clear,radius:12,y:4)
            .opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.5)
    }
}
struct BrandInput:View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.layoutDirection) private var direction
    let placeholder:String
    @Binding var text:String
    var secure=false
    var highlighted=false
    var body:some View {
        let brand=PiyaliBrand(dark:scheme == .dark)
        Group { if secure { SecureField(placeholder,text:$text,prompt:Text(placeholder).foregroundStyle(brand.muted)) } else { TextField(placeholder,text:$text,prompt:Text(placeholder).foregroundStyle(brand.muted)) } }
            .multilineTextAlignment(direction == .rightToLeft ? .trailing : .leading).environment(\.layoutDirection,.leftToRight)
            .font(PiyaliBrand.font(16)).padding(.horizontal,21).frame(height:59.6).background(PiyaliBrand.unitColor(scheme == .dark ? "0b1220" : "fff9f2").opacity(scheme == .dark ? 0.12 : 0.88),in:EntryCornerShape()).overlay {EntryCornerShape().stroke(highlighted ? PiyaliBrand.teal : brand.border)}.background {if highlighted {EntryCornerShape().stroke(PiyaliBrand.teal.opacity(0.1),lineWidth:6)}}
            .textInputAutocapitalization(.never).autocorrectionDisabled()
    }
}
struct EntryCopy {
    static let entries=(try? ContentLibrary.load([String:JSONValue].self,name:"entry-copy")) ?? [:]
    static let interface=(try? ContentLibrary.load([String:JSONValue].self,name:"app-copy")) ?? [:]
    static let timezones=(try? ContentLibrary.load([String:JSONValue].self,name:"language-timezones")) ?? [:]
    static let names=["en":"English","es":"Español","pt":"Português","fr":"Français","it":"Italiano","de":"Deutsch","ja":"日本語","hi":"हिन्दी","ar":"العربية","zh":"中文"]
    static let flags=["en":"🇺🇸","es":"🇲🇽","pt":"🇧🇷","fr":"🇫🇷","it":"🇮🇹","de":"🇩🇪","ja":"🇯🇵","hi":"🇮🇳","ar":"🇪🇬","zh":"🇨🇳","nl":"🇳🇱","el":"🇬🇷","ga":"🇮🇪","pl":"🇵🇱","ru":"🇷🇺"]
    static var initialLanguage:String { let code=Locale.current.language.languageCode?.identifier ?? "en";return LearningLanguages.support.contains(code) ? code : "en" }
    static func landingTarget(_ language:String)->String { language == "es" || Locale.preferredLanguages.first?.hasPrefix("es") == true || timezones["es"]?.array.contains(.string(TimeZone.current.identifier)) == true ? "en" : "es" }
    static func data(_ language:String) -> JSONValue { entries[language] ?? entries["en"] ?? .object([:]) }
    static func text(_ language:String,_ key:String,section:String="copy") -> String { let value=data(language)[section][key].string;return value.isEmpty ? data("en")[section][key].string : value }
    static func ui(_ language:String,_ key:String) -> String { let value=interface[language]?[key].string ?? "";return value.isEmpty ? interface["en"]?[key].string ?? key : value }
}

struct BrandArtwork:View {
    let name:String
    var body:some View {
        if let url=Bundle.main.url(forResource:name,withExtension:nil),let image=UIImage(contentsOfFile:url.path) { Image(uiImage:image).renderingMode(.original).resizable().scaledToFit() }
    }
}
