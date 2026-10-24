import SwiftUI

struct LandingAtlasView:View {
    let language:String
    @Environment(\.colorScheme) private var scheme
    @State private var selected:String
    private static let postcards=(try? ContentLibrary.load([String:JSONValue].self,name:"landing-postcards")) ?? [:]
    init(language:String) { self.language=language;_selected=State(initialValue:EntryCopy.landingTarget(language)) }
    private var brand:PiyaliBrand { PiyaliBrand(dark:scheme == .dark) }
    private var postcard:JSONValue { Self.postcards[selected] ?? .object([:]) }
    private func name(_ code:String) -> String { EntryCopy.text(language,"language_"+code) }
    private var languages:[String] {
        let compare:(String,String)->Bool={ name($0).compare(name($1),locale:Locale(identifier:language)) == .orderedAscending }
        return ["de","en","es","fr","it","nl","pt"].sorted(by:compare)+["el","ga","ja","pl","ru"].sorted(by:compare)
    }
    private var paper:Color { scheme == .dark ? Color(red:0.2,green:0.24,blue:0.22) : postcard["tone"].string == "mint" ? Color(red:0.88,green:0.92,blue:0.85) : postcard["tone"].string == "lilac" ? Color(red:0.92,green:0.88,blue:0.95) : Color(red:0.96,green:0.87,blue:0.79) }
    var body:some View {
        VStack(alignment:.leading,spacing:0) {
            Text(EntryCopy.text(language,"languages_label").capitalized).font(PiyaliBrand.font(11)).foregroundStyle(Color(red:0.27,green:0.46,blue:0.42)).padding(.bottom,34)
            Text(EntryCopy.text(language,"title",section:"atlas")).font(PiyaliBrand.font(37.6,600)).tracking(-1.8).fixedSize(horizontal:false,vertical:true)
            Text(EntryCopy.text(language,"intro",section:"atlas")).font(PiyaliBrand.font(12.8)).foregroundStyle(brand.secondary).lineSpacing(6).frame(maxWidth:280,alignment:.leading).padding(.top,17)
            VStack(alignment:.leading,spacing:16) {
                HStack { Image(systemName:"paperplane").font(.system(size:26));Spacer();Text("PIYALI").font(PiyaliBrand.font(9,600)).tracking(2) }.foregroundStyle(brand.secondary)
                VStack(alignment:.leading,spacing:4) {
                    Text(postcard["greeting"].string).font(PiyaliBrand.font(42,600)).minimumScaleFactor(0.5).lineLimit(1).accessibilityIdentifier("landingGreeting")
                    Text(EntryCopy.data(language)["atlas"]["meanings"][postcard["greetingMeaning"].string].string).font(PiyaliBrand.font(13)).foregroundStyle(brand.secondary)
                }.frame(minHeight:90,alignment:.leading)
                HStack { Text(EntryCopy.flags[selected] ?? "🌐");Text(name(selected));Spacer();Text(postcard["native"].string).foregroundStyle(brand.secondary) }.font(PiyaliBrand.font(12,600)).padding(.bottom,16)
            }.padding(.horizontal,25).padding(.top,21).background(paper).overlay { Rectangle().stroke(brand.border) }.shadow(color:.black.opacity(0.08),radius:14,y:12).rotationEffect(.degrees(-3)).frame(maxWidth:310).frame(maxWidth:.infinity).padding(.top,27).padding(.bottom,22)
            ZStack {
                Image("LandingGlobe").resizable().scaledToFit().opacity(0.6).accessibilityHidden(true)
                LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:10),count:3),spacing:17) {
                    ForEach(languages,id:\.self) { code in
                        let data=Self.postcards[code] ?? .object([:])
                        Button { selected=code } label: {
                            VStack(spacing:12) {
                                Text(data["greeting"].string).font(PiyaliBrand.font(code == "ja" ? 11.6 : 16)).minimumScaleFactor(0.6).lineLimit(1)
                                HStack(spacing:4) { Text(EntryCopy.flags[code] ?? "🌐");Text(name(code)).lineLimit(1).minimumScaleFactor(0.7) }.font(PiyaliBrand.font(9,600))
                            }.foregroundStyle(brand.text).frame(maxWidth:.infinity,minHeight:89).padding(.horizontal,8).background(brand.surface.opacity(0.9),in:RoundedRectangle(cornerRadius:5)).overlay { RoundedRectangle(cornerRadius:5).stroke(selected == code ? PiyaliBrand.teal : brand.border,lineWidth:selected == code ? 2 : 1) }
                        }.buttonStyle(.plain).accessibilityIdentifier("landingLanguage-"+code).accessibilityLabel(name(code)).accessibilityAddTraits(selected == code ? .isSelected : [])
                    }
                }
            }.padding(.vertical,22)
        }.padding(.horizontal,18).padding(.top,60).padding(.bottom,45).foregroundStyle(brand.text)
    }
}
