import SwiftUI

struct FocusCompanionPanel:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    let bubble:String?
    let introductory:Bool
    let onContinue:()->Void
    let onActivity:()->Void
    let onAchievements:()->Void
    @State private var customizing=false
    @State private var bubbleHeight:CGFloat=200
    private var brand:PiyaliBrand {PiyaliBrand(dark:scheme == .dark)}
    private var copy:JSONValue {FocusCopy.data(app.learner.support)}
    private var stage:JSONValue {FocusCopy.appearance(app.learner.companionHealth,dark:scheme == .dark)}
    private var dailyPercent:Double{app.learner.dailyGoal>0 ? Double(max(0,app.learner.dailyXP))/Double(app.learner.dailyGoal)*100:0}
    private var level:String {copy["level"].string+" \(app.learner.companionLevel)"}
    var body:some View {
        VStack(spacing:12) {
            HStack(alignment:.top,spacing:12) {
                VStack(spacing:6) {
                    CompanionArtwork(type:app.learner.effectiveCompanionType,health:app.learner.companionHealth).padding(1).frame(width:96,height:96).background(FocusCopy.background(stage["background"].string),in:RoundedRectangle(cornerRadius:20)).overlay{RoundedRectangle(cornerRadius:20).strokeBorder(scheme == .dark ? .white.opacity(0.16) : brand.secondary.opacity(0.12))}
                        .overlay(alignment:.topLeading) {
                            if let bubble {FocusQuestBubble(text:bubble,introductory:introductory,tailOnRight:app.learner.support == "ar",onContinue:onContinue).fixedSize(horizontal:false,vertical:true).onGeometryChange(for:CGFloat.self,of:{$0.size.height}){bubbleHeight=$0}.offset(x:app.learner.support == "ar" ? -124-bubbleX : bubbleX,y:(app.learner.effectiveCompanionType == "dog" ? -5.76 : app.learner.effectiveCompanionType == "alien" ? 4.24 : 10.24)-bubbleHeight)}
                        }.environment(\.layoutDirection,.leftToRight).zIndex(bubble == nil ? 0 : 30)
                    Text(copy["pet"][FocusCopy.stage(app.learner.companionHealth)].string.uppercased()).font(PiyaliBrand.productFont(9.92,700)).frame(height:11.88).padding(.horizontal,8).padding(.vertical,1.4).background(badgeBackground,in:RoundedRectangle(cornerRadius:6)).foregroundStyle(badgeColor).accessibilityIdentifier("focusCompanionStatus")
                }
                VStack(alignment:.leading,spacing:12) {
                    VStack(alignment:.leading,spacing:2) {
                        CompanionTitleLayout() {
                            edit
                            name
                            HStack(spacing:4){Text("|").font(PiyaliBrand.productFont(14,600));Text(level).font(PiyaliBrand.productFont(14,700))}.frame(height:15.4).foregroundStyle(scheme == .dark ? .white.opacity(0.8):brand.secondary)
                        }
                        OnboardingText(text:copy["pet"]["subtitle"].string,size:10,lineHeight:13.5).foregroundStyle(scheme == .dark ? brand.text.opacity(0.9):brand.secondary)
                    }.padding(.bottom,-4)
                    meter(copy["pet"]["health"].string,icon:"FiHeart",color:scheme == .dark ? "fbd38d" : "ce7a8c",label:"\(app.learner.companionHealth)%",percent:Double(app.learner.companionHealth),start:"60a5fa",end:"38bdf8")
                    meter(copy["pet"]["dailyXp"].string,icon:"MdShowChart",color:scheme == .dark ? "faf089" : "b7791f",label:"\(Int(dailyPercent.rounded()))%",percent:dailyPercent,start:"fbbf24",end:"f59e0b")
                    meter(level,icon:"gamepad",color:scheme == .dark ? "90cdf4" : "2563eb",label:"XP \(app.learner.xp)",percent:Double(app.learner.xp%100),start:"43e97b",end:"38f9d7",iconSize:16,valueSize:11)
                }.frame(maxWidth:.infinity,alignment:.leading)
            }
            HStack(spacing:12) {Button(copy["activity"].string,action:onActivity).accessibilityIdentifier("focusActivityOpen");Button(copy["achievements"].string,action:onAchievements).accessibilityIdentifier("focusAchievements")}.buttonStyle(FocusOutlineButtonStyle()).padding(.top,0)
        }.padding(13).background(FocusCopy.background(stage["background"].string),in:RoundedRectangle(cornerRadius:28)).overlay{RoundedRectangle(cornerRadius:28).strokeBorder(scheme == .dark ? .clear : brand.border)}.foregroundStyle(brand.text).zIndex(bubble == nil ? 0 : 30)
            .fullScreenCover(isPresented:$customizing){FocusCompanionCustomizeView().presentationBackground(.clear)}
    }
    private var bubbleX:CGFloat {app.learner.effectiveCompanionType == "dog" ? 7.84 : app.learner.effectiveCompanionType == "alien" ? -2.16 : 1.84}
    private var name:some View {Text(app.learner.companionName.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty ? copy["pet"]["title"].string : app.learner.companionName).font(PiyaliBrand.productFont(14,700)).lineLimit(2)}
    private var edit:some View {Button {customizing=true} label:{CompanionEditorIcon(name:"TbEdit",size:14).offset(y:-0.5).frame(width:20,height:20).contentShape(RoundedRectangle(cornerRadius:6))}.buttonStyle(.plain).foregroundStyle(scheme == .dark ? .white.opacity(0.8):brand.secondary).disabled(bubble != nil).accessibilityLabel(copy["customize"]["edit"].string).accessibilityIdentifier("focusCustomizeCompanion")}
    private var darkBadge:JSONValue{FocusCopy.source["panelBadges"][stage["colorScheme"].string]}
    private var badgeColor:Color{FocusCopy.color((scheme == .dark ? darkBadge["color"]:stage["badgeColor"]).string)}
    private var badgeBackground:Color{FocusCopy.color((scheme == .dark ? darkBadge["background"]:stage["badgeBg"]).string)}
    private func meter(_ title:String,icon:String,color:String,label:String,percent:Double,start:String,end:String,iconSize:CGFloat=14,valueSize:CGFloat=12)->some View {
        VStack(spacing:6) {
            HStack(spacing:8) {
                HStack(spacing:8){Image(icon == "gamepad" ? "Focus-pet-gamepad":"Session-"+icon).renderingMode(.template).resizable().scaledToFit().frame(width:iconSize,height:iconSize).foregroundStyle(PiyaliBrand.unitColor(color));Text(app.learner.support == "ar" ? "\u{202B}"+title+"\u{202C}":title).font(PiyaliBrand.productFont(12,600))}
                Spacer(minLength:4);Text(label).font(PiyaliBrand.productFont(valueSize,700))
            }.frame(minHeight:18)
            FocusWaveBar(percent:percent,start:start,end:end,background:.white.opacity(scheme == .dark ? 0.22 : 0.58),border:scheme == .dark ? .white.opacity(0.14) : brand.secondary.opacity(0.1),animateFill:true,insetBorder:true)
        }
    }
}

struct FocusOutlineButtonStyle:ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration:Configuration)->some View {configuration.label.font(PiyaliBrand.productFont(14,600)).padding(.horizontal,13).frame(height:32).foregroundStyle(scheme == .dark ? .white : .black).overlay{Capsule().strokeBorder(PiyaliBrand.unitColor(scheme == .dark ? "81e6d9" : "2c7a7b"))}.contentShape(Rectangle()).opacity(configuration.isPressed ? 0.7 : 1)}
}

/// Three flex items from the source: edit, two-line name, and indivisible | level.
/// Wrapping keeps the separator. SwiftUI mirrors placed coordinates in RTL.
struct CompanionTitleLayout:Layout {
    private func plan(_ width:CGFloat,_ views:Subviews)->(CGSize,[CGRect]){
        var rows:[[(Int,CGSize)]]=[[]],used:CGFloat=0
        for (index,view) in views.enumerated(){
            let ideal=view.sizeThatFits(.unspecified),size=view.sizeThatFits(.init(width:min(width,ideal.width),height:nil))
            if used>0 && used+4+size.width>width+0.01{rows.append([]);used=0}
            rows[rows.count-1].append((index,size));used += (used>0 ? 4:0)+size.width
        }
        var frames=Array(repeating:CGRect.zero,count:views.count),y:CGFloat=0
        for row in rows where !row.isEmpty{
            let height=row.map{$0.1.height}.max() ?? 0;var x:CGFloat=0
            for(index,size)in row{frames[index]=CGRect(x:x,y:y+(height-size.height)/2,width:size.width,height:size.height);x += size.width+4}
            y += height+4
        }
        return (CGSize(width:width,height:max(0,y-4)),frames)
    }
    func sizeThatFits(proposal:ProposedViewSize,subviews:Subviews,cache:inout ())->CGSize{
        let intrinsic=subviews.reduce(CGFloat(0)){$0+$1.sizeThatFits(.unspecified).width+4},width=proposal.width.flatMap{$0.isFinite ? max(0,$0):nil} ?? intrinsic
        return plan(width,subviews).0
    }
    func placeSubviews(in bounds:CGRect,proposal:ProposedViewSize,subviews:Subviews,cache:inout ()){
        let frames=plan(bounds.width,subviews).1
        for(index,view)in subviews.enumerated(){let frame=frames[index];view.place(at:CGPoint(x:bounds.minX+frame.minX,y:bounds.minY+frame.minY),anchor:.topLeading,proposal:.init(frame.size))}
    }
}

enum CompanionCustomizeHost {case plate,goal}
struct FocusCompanionCustomizeView:View {
    var host:CompanionCustomizeHost = .plate
    var animatedCharacters=true
    @EnvironmentObject var app:AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var name=""
    @State private var type="ghost"
    @State private var cardHeight:CGFloat=700
    private var copy:JSONValue {FocusCopy.data(app.learner.support)["customize"]}
    private var brand:PiyaliBrand {PiyaliBrand(dark:scheme == .dark)}
    private var liveKey:String {app.learner.companionName+":"+app.learner.effectiveCompanionType}
    var body:some View {
        GeometryReader {geometry in
            ZStack {
                (scheme == .dark ? PiyaliBrand.unitColor("020617").opacity(0.92) : PiyaliBrand.unitColor("1c140c").opacity(0.82)).ignoresSafeArea().onTapGesture{dismiss()}
                ScrollView {card.onGeometryChange(for:CGFloat.self,of:{$0.size.height}){cardHeight=$0}}
                    .scrollBounceBehavior(.basedOnSize).scrollDismissesKeyboard(.interactively)
                    .frame(width:min(384,max(0,geometry.size.width-32)),height:min(cardHeight,geometry.size.height))
            }.frame(maxWidth:.infinity,maxHeight:.infinity)
        }.ignoresSafeArea(.container).foregroundStyle(brand.text).onAppear(perform:resetDraft)
            .onChange(of:liveKey){_,_ in if host == .goal{resetDraft()}}
            .onChange(of:app.identity.npub){_,_ in dismiss()}
            // The source Chakra portal does not inherit its parent's dir.
            .environment(\.layoutDirection,.leftToRight).interactiveDismissDisabled()
            .accessibilityElement(children:.contain).accessibilityIdentifier("companionCustomizeDialog")
    }
    private func resetDraft(){name=CompanionCustomization.name(app.learner.companionName);type=app.learner.effectiveCompanionType}
    private var card:some View {
        VStack(alignment:.leading,spacing:0) {
            OnboardingText(text:copy["edit"].string,size:16,weight:.bold,lineHeight:24).frame(height:24,alignment:.leading).frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,32).padding(.top,28).padding(.bottom,host == .plate ? 8:28)
            VStack(alignment:.leading,spacing:16){
                VStack(alignment:.leading,spacing:6) {
                    OnboardingText(text:copy["name"].string,size:12,weight:.bold,lineHeight:18).frame(height:18).foregroundStyle(brand.secondary)
                    TextField(FocusCopy.data(app.learner.support)["pet"]["title"].string,text:$name).font(PiyaliBrand.productFont(16)).padding(.horizontal,16).frame(height:40).background(brand.surface,in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).strokeBorder(scheme == .dark ? PiyaliBrand.unitColor("cbd5e1"):PiyaliBrand.unitColor("604d38").opacity(0.24))}.accessibilityIdentifier("companionNameDraft").onChange(of:name){_,value in if value.utf16.count>24{name=CompanionCustomization.draft(value)}}.onSubmit{save()}
                }
                VStack(alignment:.leading,spacing:6) {
                    OnboardingText(text:copy["companion"].string,size:12,weight:.bold,lineHeight:18).frame(height:18).foregroundStyle(brand.secondary)
                    LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:8) {ForEach(CompanionTypes.ordered,id:\.self){pet in option(pet)}}
                }
            }.padding(.horizontal,28).padding(.top,host == .plate ? 8:28).padding(.bottom,8)
            HStack(spacing:12){Spacer(minLength:0);Button(copy["cancel"].string){dismiss()}.buttonStyle(CompanionEditorActionStyle(primary:false)).accessibilityIdentifier("companionCancel");Button(copy["save"].string){save()}.buttonStyle(CompanionEditorActionStyle(primary:true)).accessibilityIdentifier("companionSave")}.padding(.horizontal,28).padding(.top,16).padding(.bottom,28)
        }.background(scheme == .dark ? brand.background:brand.surface,in:RoundedRectangle(cornerRadius:48))
            .overlay{RoundedRectangle(cornerRadius:48).strokeBorder(PiyaliBrand.unitColor(scheme == .dark ? "94a3b8":"604d38").opacity(scheme == .dark ? 0.42:0.3),lineWidth:3).allowsHitTesting(false)}
    }
    private func option(_ pet:String)->some View {
        let unlock=CompanionTypes.unlocks[pet,default:1],enabled=unlock <= app.learner.companionLevel,selected=type == pet
        let activeColor=scheme == .dark ? "99f6e4":"0d9488",unlockedColor=scheme == .dark ? "5eead4":"0f766e"
        let titleColor=enabled ? (selected ? activeColor:unlockedColor):(scheme == .dark ? "cbd5e1":"5b4b3a")
        let levelColor=enabled ? (selected ? activeColor:unlockedColor):(scheme == .dark ? "fefcbf":"8a6b32")
        let levelLabel=unlock <= 1 ? copy["starter"].string:copy["unlockLevel"].string.replacingOccurrences(of:"{level}",with:String(unlock))
        return Button {type=pet} label:{
            VStack(spacing:6) {
                CompanionArtwork(type:pet,health:app.learner.companionHealth,animated:animatedCharacters).frame(width:68,height:68)
                Text(copy[pet].string).font(PiyaliBrand.productFont(12,600)).frame(height:12).foregroundStyle(PiyaliBrand.unitColor(titleColor))
                HStack(spacing:4){if !enabled {CompanionEditorIcon(name:"FiLock",size:10)};Text(levelLabel).font(PiyaliBrand.productFont(10,700)).frame(height:10)}.frame(height:14).foregroundStyle(PiyaliBrand.unitColor(levelColor))
            }.frame(maxWidth:.infinity).frame(height:116).contentShape(RoundedRectangle(cornerRadius:12))
                .background(selected ? (scheme == .dark ? Color.white.opacity(0.06):PiyaliBrand.unitColor("3f9f9b").opacity(0.12)):.clear,in:RoundedRectangle(cornerRadius:12))
                .overlay{RoundedRectangle(cornerRadius:12).strokeBorder(selected ? PiyaliBrand.unitColor(scheme == .dark ? "5eead4":"3f9f9b"):.clear,lineWidth:2)}
        }.buttonStyle(CompanionOptionStyle()).disabled(!enabled).opacity(enabled ? 1:scheme == .dark ? 0.48:0.62)
            .accessibilityLabel(copy[pet].string+", "+(enabled ? "":copy["locked"].string+", ")+levelLabel)
            .accessibilityAddTraits(selected ? .isSelected:[]).accessibilityIdentifier("companionOption-"+pet)
    }
    private func save(){app.customizeCompanion(name:name,type:type);dismiss()}
}
private struct CompanionOptionStyle:ButtonStyle {
    func makeBody(configuration:Configuration)->some View{configuration.label.opacity(configuration.isPressed ? 0.85:1)}
}
private struct CompanionEditorActionStyle:ButtonStyle {
    let primary:Bool
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration:Configuration)->some View{
        configuration.label.font(PiyaliBrand.productFont(16,600)).fixedSize().foregroundStyle(primary ? .white:scheme == .dark ? PiyaliBrand.unitColor("cbd5e1"):PiyaliBrand(dark:false).secondary).padding(.horizontal,17).frame(height:40).contentShape(Capsule())
            .background{if primary{Capsule().fill(PiyaliBrand.unitColor(scheme == .dark ? "319795":"3f9f9b")).shadow(color:PiyaliBrand.unitColor("008080"),radius:0,y:configuration.isPressed ? 0:4)}}.offset(y:primary && configuration.isPressed ? 4:0)
    }
}

struct CompanionEditorIcon:View {let name:String;var size:CGFloat=14;var body:some View{Image("Companion-"+name).renderingMode(.template).resizable().scaledToFit().frame(width:size,height:size).accessibilityHidden(true)}}
