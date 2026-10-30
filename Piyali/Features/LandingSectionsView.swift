import SwiftUI

struct LandingSectionsView<Signup:View>:View {
    let language:String
    @ViewBuilder var signup:()->Signup
    @Environment(\.colorScheme) private var scheme
    @Environment(\.entryHeaderBounds) private var headerBounds
    @State private var tab="speak"
    @State private var companion=0
    @State private var toolkitOpen=false
    @State private var openFAQs:Set<Int>=[]
    @State private var privacyOpen=false
    @State private var showcaseFrame:CGRect = .zero
    @State private var demoTarget:String
    @StateObject private var publicDemo=LandingDemoFixture.service()
    init(language:String,@ViewBuilder signup:@escaping()->Signup) {self.language=language;self.signup=signup;_demoTarget=State(initialValue:EntryCopy.landingTarget(language))}
    private let companions=["ghost","alien","robot","slime","dog","axolotl"]
    private var brand:PiyaliBrand { PiyaliBrand(dark:scheme == .dark) }
    private var green:Color { scheme == .dark ? Color(red:0.47,green:0.85,blue:0.75) : Color(red:0.03,green:0.49,blue:0.42) }
    private var mint:Color { scheme == .dark ? Color(red:0.09,green:0.18,blue:0.17) : Color(red:0.89,green:0.93,blue:0.89) }
    private var lilac:Color { scheme == .dark ? Color(red:0.149,green:0.149,blue:0.227) : Color(red:0.922,green:0.906,blue:0.945) }
    private var peach:Color { scheme == .dark ? Color(red:0.188,green:0.157,blue:0.129) : Color(red:0.969,green:0.91,blue:0.851) }
    private func c(_ key:String)->String { EntryCopy.text(language,key) }
    private func w(_ key:String)->String { let v=EntryCopy.text(language,key,section:"capabilities");return v.isEmpty ? EntryCopy.text(language,key,section:"refresh") : v }
    private func e(_ key:String)->String { EntryCopy.text(language,key,section:"ethos") }
    var body:some View {
        VStack(spacing:0) {
            showcase.padding(.top,58)
            companionCard.padding(.top,12)
            featureCard(title:w("connectedTitle"),detail:w("connectedDesc"),symbol:"person.2",color:.purple)
            featureCard(title:c("feature_immersion"),detail:w("immersionDesc"),symbol:"safari",color:green)
            toolkit.padding(.top,28)
            ethos.padding(.top,60)
            mission.padding(.vertical,45)
            faq.padding(.vertical,48)
            VStack(alignment:.leading,spacing:24) {
                heading(c("cta_final_title"));if !c("cta_final_accent").isEmpty { heading(c("cta_final_accent")) }
                paragraph(w("signupIntro"))
                HStack { Text("hola.");Text("hello.").foregroundStyle(green);Text("こんにちは。").font(PiyaliBrand.font(16)) }.font(PiyaliBrand.font(24,600)).rotationEffect(.degrees(-3)).accessibilityHidden(true)
                signup()
            }.padding(26).background(mint,in:RoundedRectangle(cornerRadius:22))
            Button(privacyTitle) { privacyOpen=true }.font(PiyaliBrand.font(14)).underline().padding(.vertical,24).accessibilityIdentifier("landingPrivacy")
        }.foregroundStyle(brand.text).padding(.horizontal,18).padding(.bottom,28)
            .sheet(isPresented:$privacyOpen) { privacy }
            .onChange(of:language) {_,_ in demoTarget=EntryCopy.landingTarget(language);publicDemo.reset()}
    }
    private func heading(_ text:String)->some View { Text(text).font(PiyaliBrand.font(32,500)).tracking(-1.3).fixedSize(horizontal:false,vertical:true) }
    private func paragraph(_ text:String,size:CGFloat=13.6)->some View { Text(text).font(PiyaliBrand.font(size)).foregroundStyle(brand.secondary).lineSpacing(size*0.5).fixedSize(horizontal:false,vertical:true) }
    private func eyebrow(_ text:String)->some View { Text(text).font(PiyaliBrand.font(11.5)).foregroundStyle(green) }
    private var showcase:some View {
        VStack(spacing:28) {
            VStack(spacing:17) { eyebrow(c("features_label").localizedCapitalized);heading(w("title"));paragraph(w("intro")) }.multilineTextAlignment(.center)
            VStack(spacing:15) {
                GeometryReader {g in
                    let rect=g.frame(in:.global),offset=max(0,min(headerBounds.maxY+10-rect.minY,showcaseFrame.maxY-rect.maxY))
                    capabilityTabs.frame(maxWidth:.infinity).offset(y:offset)
                }.frame(height:52).zIndex(30)
                VStack(spacing:0) {
                    Group {
                        if tab == "speak" { LandingTutorDemoView(language:language,target:$demoTarget,demo:publicDemo).id(language) }
                        else if tab == "remember" { memoryPreview }
                        else { proficiencyPreview }
                    }.padding(tab == "remember" ? 0 : 18).frame(maxWidth:.infinity,minHeight:345).background(PiyaliBrand.unitColor(scheme == .dark ? "141e2a" : "fffcf6"),in:RoundedRectangle(cornerRadius:18)).overlay { RoundedRectangle(cornerRadius:18).stroke(brand.border) }.padding([.horizontal,.top],18)
                    VStack(alignment:.leading,spacing:16) {
                        Image(systemName:tab == "speak" ? "bubble.left" : tab == "remember" ? "bookmark" : "chart.line.uptrend.xyaxis").font(.system(size:25,weight:.light)).foregroundStyle(green).frame(width:43,height:43).background(mint,in:RoundedRectangle(cornerRadius:12))
                        Text(tab == "speak" ? c("feature_tutor") : w(tab == "remember" ? "memoryTitle" : "proficiencyTitle")).font(PiyaliBrand.font(27.2,600))
                        paragraph(tab == "speak" ? c("feature_tutor_desc") : w(tab == "remember" ? "memoryDesc" : "proficiencyDesc"))
                        HStack(alignment:.top,spacing:10) { Circle().fill(green).frame(width:5,height:5).padding(.top,7);paragraph(tab == "speak" ? c("feature_conversations_desc") : w(tab == "remember" ? "memoryDetail" : "proficiencyDetail"),size:12.8) }
                    }.frame(maxWidth:.infinity,alignment:.leading).padding(28)
                }.background(tab == "speak" ? mint : tab == "remember" ? lilac : peach,in:RoundedRectangle(cornerRadius:22)).overlay { RoundedRectangle(cornerRadius:22).stroke(brand.border) }
            }.background {GeometryReader {g in Color.clear.preference(key:LandingShowcaseFrame.self,value:g.frame(in:.global))}}.onPreferenceChange(LandingShowcaseFrame.self){showcaseFrame=$0}
        }
    }
    private var capabilityTabs:some View {
        HStack(spacing:2) {ForEach(["speak","remember","grow"],id:\.self) {mode in
            Button {tab=mode} label:{Label(w(mode),systemImage:mode == "speak" ? "bubble.left" : mode == "remember" ? "bookmark" : "chart.line.uptrend.xyaxis").font(PiyaliBrand.font(12.3)).padding(.horizontal,12).frame(minHeight:44).foregroundStyle(tab == mode ? Color.white : brand.secondary).background(tab == mode ? PiyaliBrand.unitColor("137a68") : .clear,in:Capsule())}.buttonStyle(.plain).accessibilityIdentifier("landingTab-"+mode).accessibilityAddTraits(tab == mode ? .isSelected : [])
        }}.padding(4).background(PiyaliBrand.unitColor(scheme == .dark ? "141e2a" : "fffcf6"),in:Capsule()).overlay {Capsule().stroke(brand.border)}
    }
    private var memoryPreview:some View {
        VStack(alignment:.leading,spacing:10) {
            VStack(alignment:.leading,spacing:5) { Text(w("memoryGoalLabel")).font(PiyaliBrand.font(9.9)).foregroundStyle(brand.secondary);Text(w("memoryGoal")).font(PiyaliBrand.font(13.4)) }.padding(.bottom,14).frame(maxWidth:.infinity,alignment:.leading).overlay(alignment:.bottom) { Rectangle().fill(brand.border).frame(height:1) }.padding(.bottom,8)
            VStack(alignment:.leading,spacing:4) { Text(w("before")).font(PiyaliBrand.font(9.3)).foregroundStyle(brand.secondary);(Text(language == "es" ? "Yesterday I " : "Ayer ")+Text(language == "es" ? "go" : "voy").strikethrough(color:Color(red:0.69,green:0.39,blue:0.39))+Text(language == "es" ? " to the park." : " al parque.")).font(PiyaliBrand.font(13.6)) }.frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,18).padding(.vertical,14).background(lilac,in:RoundedRectangle(cornerRadius:12))
            VStack(alignment:.leading,spacing:4) { Label(w("after"),systemImage:"checkmark").font(PiyaliBrand.font(9.3)).foregroundStyle(brand.secondary);(Text(language == "es" ? "Yesterday I " : "Ayer ")+Text(language == "es" ? "went" : "fui").font(PiyaliBrand.font(13.6,700)).foregroundColor(green)+Text(language == "es" ? " to the park." : " al parque.")).font(PiyaliBrand.font(13.6)) }.frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,18).padding(.vertical,14).background(mint,in:RoundedRectangle(cornerRadius:12))
            Text(w("memoryTomorrow")).font(PiyaliBrand.font(9.9)).foregroundStyle(brand.secondary).padding(.top,18)
            HStack(spacing:8) { ForEach([("memoryLesson",1),("memoryTutorSession",1),("memoryFlashcards",5)],id:\.0) { row in VStack(alignment:.leading,spacing:4) { Text(row.1,format:.number).font(PiyaliBrand.font(16.8)).foregroundStyle(green);Text(w(row.0)).font(PiyaliBrand.font(9.4)).foregroundStyle(brand.secondary) }.frame(maxWidth:.infinity,minHeight:44,alignment:.leading).padding(.horizontal,12).padding(.vertical,10).overlay { RoundedRectangle(cornerRadius:10).stroke(brand.border) } } }
        }.frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,28).padding(.vertical,22)
    }
    private var proficiencyPreview:some View {
        let data=(try? ContentLibrary.load(JSONValue.self,name:"landing-proficiency")) ?? .object([:])
        let stats=data["stats"]
        return VStack(spacing:20) {
            LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:10) { ForEach(["modules","lessonReviews","modes","vocabularyCards"],id:\.self) { key in VStack(alignment:.leading,spacing:5) { Text(Int(stats[key].number),format:.number).font(PiyaliBrand.font(24.8,500));Text(w(key)).font(PiyaliBrand.font(9.4)).foregroundStyle(brand.secondary) }.frame(maxWidth:.infinity,alignment:.leading).padding(12).background(key == "lessonReviews" ? peach : key == "vocabularyCards" ? lilac : mint,in:RoundedRectangle(cornerRadius:12)).overlay { RoundedRectangle(cornerRadius:12).stroke(brand.border) } } }
            ViewThatFits(in:.horizontal) {
                HStack(spacing:5) { ForEach(EntryCopy.data(language)["capabilities"]["modeNames"].array.map(\.string),id:\.self) { name in Text(name).font(PiyaliBrand.font(8.3)).padding(.horizontal,7).padding(.vertical,4).overlay { RoundedRectangle(cornerRadius:6).stroke(brand.border) } } }
                LazyVGrid(columns:[GridItem(.adaptive(minimum:52))],spacing:5) { ForEach(EntryCopy.data(language)["capabilities"]["modeNames"].array.map(\.string),id:\.self) { name in Text(name).font(PiyaliBrand.font(8.3)).padding(.vertical,4).frame(maxWidth:.infinity).overlay { RoundedRectangle(cornerRadius:6).stroke(brand.border) } } }
            }.foregroundStyle(brand.secondary)
            HStack(spacing:4) { ForEach(data["levels"].array.map(\.string),id:\.self) { Text($0).font(PiyaliBrand.font(8.8)).foregroundStyle(green).frame(maxWidth:.infinity) } }.padding(.bottom,10).overlay(alignment:.bottom) { Rectangle().fill(brand.border).frame(height:1) }
            HStack { Text(w("scoreLabel"));Spacer();Text("0–100").bold() }.font(PiyaliBrand.font(13))
            Capsule().fill(LinearGradient(colors:[green.opacity(0.2),green],startPoint:.leading,endPoint:.trailing)).frame(height:6)
        }.accessibilityIdentifier("landingProficiencyPreview")
    }
    private var companionCard:some View {
        VStack(spacing:0) {
            VStack(spacing:8) {
                HStack { Button { companion=(companion+5)%6 } label:{ Image(systemName:"chevron.left").frame(width:44,height:44) }.accessibilityLabel(w("previousCompanion"));Spacer();CompanionArtwork(type:companions[companion]).frame(width:96,height:96);Spacer();Button { companion=(companion+1)%6 } label:{ Image(systemName:"chevron.right").frame(width:44,height:44) }.accessibilityLabel(w("nextCompanion")) }
                Text(EntryCopy.data(language)["companionNames"][companions[companion]].string).font(PiyaliBrand.font(13)).accessibilityIdentifier("landingCompanionName")
            }.padding(20).background(Color.orange.opacity(scheme == .dark ? 0.08 : 0.1))
            VStack(alignment:.leading,spacing:10) { Image(systemName:"heart").foregroundStyle(green);Text(c("feature_companion")).font(PiyaliBrand.font(16,600));paragraph(w("companionDesc"),size:12) }.frame(maxWidth:.infinity,alignment:.leading).padding(22)
        }.background(brand.surface,in:RoundedRectangle(cornerRadius:18)).clipShape(RoundedRectangle(cornerRadius:18)).overlay { RoundedRectangle(cornerRadius:18).stroke(brand.border) }
    }
    private func featureCard(title:String,detail:String,symbol:String,color:Color)->some View {
        HStack(spacing:0) { VStack(spacing:10) { if symbol == "person.2" { Image(systemName:"person.2");Image(systemName:"globe").font(.system(size:34,weight:.light));Image(systemName:"wallet.bifold") } else { Image(systemName:symbol).font(.system(size:52,weight:.ultraLight));Image(systemName:"checkmark.circle") } }.foregroundStyle(green).frame(width:110).frame(maxHeight:.infinity).background(color.opacity(0.09))
            VStack(alignment:.leading,spacing:10) { Image(systemName:symbol).foregroundStyle(green);Text(title).font(PiyaliBrand.font(16,600));paragraph(detail,size:12) }.frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,22).padding(.horizontal,20)
        }.background(brand.surface,in:RoundedRectangle(cornerRadius:18)).clipShape(RoundedRectangle(cornerRadius:18)).overlay { RoundedRectangle(cornerRadius:18).stroke(brand.border) }.padding(.top,12)
    }
    private let tools:[(String,String)] = [("tutor","book"),("memory","bookmark"),("score","chart.line.uptrend.xyaxis"),("daily_quests","calendar"),("companion","pawprint"),("conversations","bubble.left.and.bubble.right"),("phonics","speaker.wave.2"),("assistant","person.crop.circle"),("immersion","safari"),("journey","point.topleft.down.to.point.bottomright.curvepath"),("achievements","trophy"),("teams","person.2"),("global_feed","globe"),("proficiency_test","mic"),("stories","book.pages"),("reading","book.closed"),("grammar","flask"),("flashcards","pencil"),("flashcards_spaced","square.stack"),("notes","note.text"),("skilltree","map"),("goals","target"),("game_review","gamecontroller")]
    private var toolkit:some View {
        VStack(spacing:24) {
            Button { withAnimation(.easeInOut(duration:0.2)) { toolkitOpen.toggle() } } label:{ HStack { Text(w(toolkitOpen ? "close" : "browse"));Spacer();Text(tools.count,format:.number);Image(systemName:toolkitOpen ? "chevron.up" : "chevron.down") }.font(PiyaliBrand.font(14,600)).frame(minHeight:44) }.accessibilityIdentifier("landingToolkit")
            if toolkitOpen { ForEach(tools,id:\.0) { tool in HStack(alignment:.top,spacing:16) { Image(systemName:tool.1).foregroundStyle(green).frame(width:24);VStack(alignment:.leading,spacing:7) { Text(c("feature_"+tool.0)).font(PiyaliBrand.font(14,600));paragraph(c("feature_"+tool.0+"_desc"),size:12.8) } }.frame(maxWidth:.infinity,alignment:.leading) } }
        }.padding(.vertical,12).overlay(alignment:.top) { Rectangle().fill(brand.border).frame(height:1) }.overlay(alignment:.bottom) { Rectangle().fill(brand.border).frame(height:1) }
    }
    private var ethos:some View {
        VStack(alignment:.leading,spacing:30) {
            VStack(alignment:.leading,spacing:17) { eyebrow(e("label"));heading(e("title")) }
            ForEach(Array(EntryCopy.data(language)["ethos"]["principles"].array.enumerated()),id:\.offset) { index,principle in VStack(alignment:.leading,spacing:16) {
                HStack(spacing:24) { Image(["LandingHuman","LandingCommunity","LandingTechnology"][index]).resizable().scaledToFit().frame(width:128,height:112);Text(principle["title"].string).font(PiyaliBrand.font(21,600)) }
                paragraph(principle["lead"].string);paragraph(principle["body"].string)
            }.padding(.vertical,20).overlay(alignment:.top) { Rectangle().fill(brand.border).frame(height:1) } }
        }
    }
    private var mission:some View {
        VStack(alignment:.leading,spacing:18) { Image("LandingMission").resizable().scaledToFit().frame(maxWidth:280).frame(maxWidth:.infinity);eyebrow(c("scholarship_label"));VStack(alignment:.leading,spacing:0) { heading(c("scholarship_title"));heading(c("scholarship_title_accent")).foregroundStyle(green) };paragraph(c("scholarship_desc"),size:13.9);paragraph(c("scholarship_note"),size:13.9) }.padding(.horizontal,8)
    }
    private var faq:some View {
        let items=[(c("faq_q1"),c("faq_a1")),(e("bitcoinQuestion"),e("bitcoinAnswer")),(w("costQuestion"),w("costAnswer"))]
        return VStack(alignment:.leading,spacing:27) { VStack(alignment:.leading,spacing:17) { eyebrow(c("faq_label"));heading(c("faq_title")) };VStack(spacing:0) { ForEach(Array(items.enumerated()),id:\.offset) { index,item in VStack(alignment:.leading,spacing:0) { Button { if openFAQs.contains(index) { openFAQs.remove(index) } else { openFAQs.insert(index) } } label:{ HStack { Text(item.0).multilineTextAlignment(.leading);Spacer();Image(systemName:openFAQs.contains(index) ? "chevron.up" : "chevron.down") }.font(PiyaliBrand.font(13.3,600)).padding(.vertical,20) }.accessibilityIdentifier("landingFAQ-\(index)");if openFAQs.contains(index) { paragraph(item.1,size:12.8).padding(.bottom,20).accessibilityIdentifier("landingFAQAnswer-\(index)") } }.overlay(alignment:.top) { Rectangle().fill(brand.border).frame(height:1) } } } }.padding(.horizontal,4)
    }
    private var privacyTitle:String { ["en":"Privacy policy","es":"Política de privacidad","pt":"Política de privacidade","fr":"Politique de confidentialité","it":"Informativa sulla privacy","de":"Datenschutzrichtlinie","ja":"プライバシーポリシー","hi":"गोपनीयता नीति","ar":"سياسة الخصوصية","zh":"隐私政策"][language] ?? "Privacy policy" }
    private var privacy:some View {
        NavigationStack { ScrollView { VStack(alignment:.leading,spacing:16) { ForEach(Array(policy.components(separatedBy:"\n\n").enumerated()),id:\.offset) { _,block in Text((try? AttributedString(markdown:block)) ?? AttributedString(block)).font(PiyaliBrand.font(15)).frame(maxWidth:.infinity,alignment:.leading) } }.padding(24) }.background(brand.surface).foregroundStyle(brand.text).navigationTitle(privacyTitle).navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement:.confirmationAction) { Button(EntryCopy.ui(language,"close")) { privacyOpen=false } } }.environment(\.layoutDirection,.leftToRight) }
    }
    private var policy:String { Bundle.main.url(forResource:"privacy-policy",withExtension:"md").flatMap { try? String(contentsOf:$0,encoding:.utf8) } ?? "" }
}
private struct LandingShowcaseFrame:PreferenceKey {
    static var defaultValue:CGRect = .zero
    static func reduce(value:inout CGRect,nextValue:()->CGRect){let next=nextValue();if next.height>0 {value=next}}
}
