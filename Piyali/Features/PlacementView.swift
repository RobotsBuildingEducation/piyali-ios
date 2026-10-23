import SwiftUI

/// Source choice → two pages of self-report rows → starting-level result.
struct PlacementView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    var overlay=false
    var onClose:(()->Void)?=nil
    @State private var headerHeight:CGFloat=125
    @State private var bodyHeight:CGFloat=220
    @State private var scene=0
    @State private var selected:Set<String>=[]
    @State private var saving=false
    private var estimate:Placement? { PlacementAssessment.estimate(selected) }
    private var brand:PiyaliBrand { .init(dark:scheme == .dark) }
    private static let data=(try? ContentLibrary.load(JSONValue.self,name:"placement-copy")) ?? .null
    private var language:String { EntryCopy.ui(app.learner.support,"language_"+app.learner.target) }
    private func t(_ key:String,_ vars:[String:String]=[:])->String {
        let copy=Self.data["translations"][app.learner.support][key].string
        var text=copy.isEmpty ? Self.data["translations"]["en"][key].string : copy
        for (key,value) in vars.merging(["language":language],uniquingKeysWith:{first,_ in first}) { text=text.replacingOccurrences(of:"{"+key+"}",with:value) };return text
    }
    var body:some View {
        GeometryReader { geometry in
            VStack { Spacer(minLength:12)
                VStack(spacing:0) {
                    header.onGeometryChange(for:CGFloat.self,of:{$0.size.height}){headerHeight=$0}
                    ScrollView {
                        VStack(spacing:16) {
                            if scene == 0 { choice }
                            else if scene == 1 || scene == 2 { options }
                            else if let estimate { result(estimate) }
                        }.padding(.horizontal,28).padding(.top,16).padding(.bottom,28).onGeometryChange(for:CGFloat.self,of:{$0.size.height}){bodyHeight=$0}
                    }
                }.frame(maxWidth:450).frame(height:min(geometry.size.height-24,headerHeight+bodyHeight)).background(PiyaliBrand.unitColor(scheme == .dark ? "0b1220" : "fffdf9"),in:EntryCornerShape(radius:48)).clipShape(EntryCornerShape(radius:48)).overlay {EntryCornerShape(radius:48).stroke(PiyaliBrand.unitColor(scheme == .dark ? "94a3b8" : "604d38").opacity(scheme == .dark ? 0.42 : 0.3),lineWidth:3).padding(1.5)}.padding(.horizontal,12)
                Spacer(minLength:12)
            }.frame(maxWidth:.infinity,maxHeight:.infinity).background(overlay ? Color.clear : brand.background)
        }.font(PiyaliBrand.productFont(15)).foregroundStyle(brand.text).toolbar(.hidden,for:.navigationBar).disabled(saving)
    }
    private var header:some View {
        ZStack(alignment:.topTrailing) {
            VStack(spacing:6) {
                BrandArtwork(name:"placement-dog.webp").frame(width:88,height:88).frame(height:42,alignment:.bottom).clipped().accessibilityHidden(true)
                OnboardingText(text:t(scene == 3 ? "proficiency_modal_result_title" : "proficiency_modal_choose_start"),size:16,weight:.bold,lineHeight:20.8).multilineTextAlignment(.center).foregroundStyle(.white)
            }.frame(maxWidth:.infinity).padding(.horizontal,32).padding(.vertical,28)
            Button { close() } label:{ Image(systemName:"xmark").font(.system(size:14,weight:.semibold)).foregroundStyle(.white).frame(width:44,height:44).contentShape(Rectangle()) }.padding(14).accessibilityLabel(EntryCopy.ui(app.learner.support,"app_close")).accessibilityIdentifier("placementClose")
        }.background(LinearGradient(colors:[Color(red:11/255,green:197/255,blue:234/255),Color(red:0,green:181/255,blue:216/255)],startPoint:.leading,endPoint:.trailing))
    }
    private var choice:some View {
        VStack(spacing:14) {
            OnboardingText(text:t("proficiency_modal_choice_description"),size:14,lineHeight:19.6).foregroundStyle(brand.secondary).multilineTextAlignment(.center).padding(.bottom,4)
            Button(t("proficiency_modal_completely_new")) { start(.init(level:"Pre-A1",score:0,source:"completely_new",selectedIDs:[],updatedAt:Date())) }.buttonStyle(PlacementChoiceStyle()).accessibilityIdentifier("placementNew")
            Button(t("proficiency_modal_find_level")) { scene=1 }.buttonStyle(PlacementChoiceStyle()).accessibilityIdentifier("placementFindLevel")
        }
    }
    private var options:some View {
        VStack(spacing:8) {
            VStack(spacing:4) { Text(t("proficiency_modal_select_all")).font(PiyaliBrand.productFont(13,500));Text(t("proficiency_modal_part",["part":String(scene)])).font(PiyaliBrand.productFont(12,700)) }.foregroundStyle(brand.secondary)
            ForEach(Array(PlacementAssessment.options.dropFirst((scene-1)*5).prefix(5))) { option in
                let checked=selected.contains(option.id)
                Button { if checked { selected.remove(option.id) } else { selected.insert(option.id) } } label:{
                    HStack(spacing:12) {
                        Image(systemName:checked ? "checkmark.circle.fill" : "circle").font(.system(size:22)).foregroundStyle(checked ? Color(red:14/255,green:128/255,blue:149/255) : brand.muted)
                        OnboardingText(text:t("proficiency_self_"+option.id),size:13.5,weight:checked ? .semibold : .medium,lineHeight:17.55).multilineTextAlignment(.leading);Spacer(minLength:0)
                    }.padding(.horizontal,14).padding(.vertical,10).frame(maxWidth:.infinity,minHeight:46,alignment:.leading).background(checked ? (scheme == .dark ? PiyaliBrand.unitColor("22d3ee").opacity(0.12) : PiyaliBrand.unitColor("e6f8fa")) : PiyaliBrand.unitColor(scheme == .dark ? "182031" : "fffdf9"),in:RoundedRectangle(cornerRadius:16)).overlay { RoundedRectangle(cornerRadius:16).stroke(checked ? PiyaliBrand.unitColor(scheme == .dark ? "22d3ee" : "0e8095") : brand.border,lineWidth:1.5) }.contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityIdentifier("placementOption-"+option.id).accessibilityValue(checked ? "Selected" : "Not selected").accessibilityAddTraits(checked ? .isSelected : [])
            }
            HStack(spacing:12) {
                Button(t("proficiency_modal_back")) { scene -= 1 }.buttonStyle(PlacementChoiceStyle(height:44))
                Button(t(scene == 1 ? "proficiency_modal_next" : "proficiency_modal_done")) { scene += 1 }.buttonStyle(PlacementChoiceStyle(primary:true,height:44)).disabled(scene == 2 && estimate == nil).accessibilityIdentifier("placementNext")
            }.padding(.top,8)
        }
    }
    private func result(_ estimate:Placement)->some View {
        let level=Self.data["levels"][estimate.level]
        return VStack(spacing:16) {
            OnboardingText(text:t("proficiency_modal_result_description"),size:14,lineHeight:19.6).foregroundStyle(brand.secondary)
            VStack(spacing:0) {
                OnboardingText(text:estimate.level,size:24,weight:.black,lineHeight:36).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "9decf9" : "155d70"))
                OnboardingText(text:level["name"].localized(app.learner.support),size:16,weight:.bold).padding(.top,2)
                OnboardingText(text:level["description"].localized(app.learner.support),size:14,lineHeight:19.6).foregroundStyle(brand.secondary).padding(.top,4)
                OnboardingText(text:t("proficiency_modal_starting_elo",["score":String(estimate.score)]),size:12,weight:.medium).foregroundStyle(scheme == .dark ? brand.muted : brand.secondary).padding(.top,10)
            }.padding(.vertical,14).padding(.horizontal,16).frame(maxWidth:.infinity).background(scheme == .dark ? Color.white.opacity(0.08) : PiyaliBrand.unitColor("f1fafb"),in:RoundedRectangle(cornerRadius:18)).overlay {RoundedRectangle(cornerRadius:18).stroke(PiyaliBrand.unitColor(scheme == .dark ? "00b5d8" : "46b9cd"),lineWidth:1.5).padding(0.75)}
            Button(t("proficiency_modal_start_level",["level":estimate.level])) {start(estimate)}.buttonStyle(PlacementChoiceStyle(height:50)).accessibilityIdentifier("placementStart")
            Link(t("proficiency_modal_take_test_now"),destination:AppConfiguration().web.appendingPathComponent("proficiency")).buttonStyle(PlacementChoiceStyle(height:50)).accessibilityIdentifier("placementWebTest")
            Button(t("proficiency_modal_back")) {scene=2}.font(PiyaliBrand.productFont(14,600)).frame(minHeight:32)
        }.multilineTextAlignment(.center)
    }
    private func close() {if let onClose {onClose()} else {dismiss()}}
    private func start(_ placement:Placement) { saving=true;app.place(placement);close() }
}
private struct PlacementChoiceStyle:ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var enabled
    var primary=false
    var height:CGFloat=52
    func makeBody(configuration:Configuration)->some View {
        let brand=PiyaliBrand(dark:scheme == .dark)
        configuration.label.font(PiyaliBrand.productFont(15,700)).multilineTextAlignment(.center).frame(maxWidth:.infinity,minHeight:height).padding(.horizontal,12).foregroundStyle(primary ? .white : brand.text)
            .background { EntryCornerShape(radius:18).fill(primary ? Color(red:0,green:181/255,blue:216/255) : PiyaliBrand.unitColor(scheme == .dark ? "111827" : "fffdf9")).shadow(color:primary ? Color(red:8/255,green:111/255,blue:131/255) : PiyaliBrand.unitColor(scheme == .dark ? "0b3154" : "e8e4de"),radius:0,y:configuration.isPressed ? 0 : 4) }
            .overlay { EntryCornerShape(radius:18).stroke(primary ? Color.clear : brand.border).padding(0.5) }.opacity(enabled ? 1 : 0.45)
    }
}
