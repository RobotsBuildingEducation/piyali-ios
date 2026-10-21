import SwiftUI

/// Source choice → two pages of self-report rows → starting-level result.
struct PlacementView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
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
                    header
                    ScrollView {
                        VStack(spacing:16) {
                            if scene == 0 { choice }
                            else if scene == 1 || scene == 2 { options }
                            else if let estimate { result(estimate) }
                        }.padding(16)
                    }
                }.frame(maxWidth:450).frame(height:min(geometry.size.height-24,scene == 0 ? 310 : scene == 3 ? 555 : 560)).background(brand.surface,in:RoundedRectangle(cornerRadius:24)).clipShape(RoundedRectangle(cornerRadius:24)).overlay { RoundedRectangle(cornerRadius:24).stroke(brand.border) }.padding(.horizontal,12)
                Spacer(minLength:12)
            }.frame(maxWidth:.infinity,maxHeight:.infinity).background(brand.background)
        }.font(PiyaliBrand.productFont(15)).foregroundStyle(brand.text).toolbar(.hidden,for:.navigationBar).disabled(saving)
    }
    private var header:some View {
        ZStack(alignment:.topTrailing) {
            VStack(spacing:6) {
                BrandArtwork(name:"placement-dog.webp").frame(width:88,height:88).frame(height:42,alignment:.bottom).clipped().accessibilityHidden(true)
                Text(t(scene == 3 ? "proficiency_modal_result_title" : "proficiency_modal_choose_start")).font(PiyaliBrand.productFont(16,700)).multilineTextAlignment(.center).foregroundStyle(.white)
            }.frame(maxWidth:.infinity).padding(.horizontal,44).padding(.vertical,12)
            Button { dismiss() } label:{ Image(systemName:"xmark").font(.system(size:14,weight:.semibold)).foregroundStyle(.white).frame(width:36,height:36).contentShape(Rectangle()) }.padding(8).accessibilityLabel(EntryCopy.ui(app.learner.support,"app_close")).accessibilityIdentifier("placementClose")
        }.background(LinearGradient(colors:[Color(red:11/255,green:197/255,blue:234/255),Color(red:0,green:181/255,blue:216/255)],startPoint:.leading,endPoint:.trailing))
    }
    private var choice:some View {
        VStack(spacing:16) {
            Text(t("proficiency_modal_choice_description")).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary).multilineTextAlignment(.center)
            Button(t("proficiency_modal_completely_new")) { start(.init(level:"Pre-A1",score:0,source:"completely_new",selectedIDs:[],updatedAt:Date())) }.buttonStyle(PlacementChoiceStyle()).accessibilityIdentifier("placementNew")
            Button(t("proficiency_modal_find_level")) { scene=1 }.buttonStyle(PlacementChoiceStyle()).accessibilityIdentifier("placementFindLevel")
        }
    }
    private var options:some View {
        VStack(spacing:10) {
            VStack(spacing:4) { Text(t("proficiency_modal_select_all")).font(PiyaliBrand.productFont(13,500));Text(t("proficiency_modal_part",["part":String(scene)])).font(PiyaliBrand.productFont(12,700)) }.foregroundStyle(brand.secondary)
            ForEach(Array(PlacementAssessment.options.dropFirst((scene-1)*5).prefix(5))) { option in
                let checked=selected.contains(option.id)
                Button { if checked { selected.remove(option.id) } else { selected.insert(option.id) } } label:{
                    HStack(spacing:12) {
                        Image(systemName:checked ? "checkmark.circle.fill" : "circle").font(.system(size:22)).foregroundStyle(checked ? Color(red:14/255,green:128/255,blue:149/255) : brand.muted)
                        Text(t("proficiency_self_"+option.id)).font(PiyaliBrand.productFont(14,checked ? 600 : 500)).multilineTextAlignment(.leading);Spacer(minLength:0)
                    }.padding(.horizontal,14).padding(.vertical,11).frame(maxWidth:.infinity,minHeight:46,alignment:.leading).background(checked ? Color(red:14/255,green:128/255,blue:149/255).opacity(scheme == .dark ? 0.16 : 0.08) : brand.surface,in:RoundedRectangle(cornerRadius:16)).overlay { RoundedRectangle(cornerRadius:16).stroke(checked ? Color(red:14/255,green:128/255,blue:149/255) : brand.border,lineWidth:1.5) }.contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityIdentifier("placementOption-"+option.id).accessibilityValue(checked ? "Selected" : "Not selected").accessibilityAddTraits(checked ? .isSelected : [])
            }
            HStack(spacing:12) {
                Button(t("proficiency_modal_back")) { scene -= 1 }.buttonStyle(PlacementChoiceStyle())
                Button(t(scene == 1 ? "proficiency_modal_next" : "proficiency_modal_done")) { scene += 1 }.buttonStyle(PlacementChoiceStyle(primary:true)).disabled(scene == 2 && estimate == nil).accessibilityIdentifier("placementNext")
            }.padding(.top,8)
        }
    }
    private func result(_ estimate:Placement)->some View {
        let level=Self.data["levels"][estimate.level]
        return VStack(spacing:18) {
            Text(t("proficiency_modal_result_description")).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary).multilineTextAlignment(.center)
            VStack(spacing:8) {
                Text(estimate.level).font(PiyaliBrand.productFont(28,800)).foregroundStyle(scheme == .dark ? Color(red:157/255,green:236/255,blue:249/255) : Color(red:21/255,green:93/255,blue:112/255))
                Text(level["name"].localized(app.learner.support)).font(PiyaliBrand.productFont(18,700))
                Text(level["description"].localized(app.learner.support)).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary).multilineTextAlignment(.center)
                Text(t("proficiency_modal_starting_elo",["score":String(estimate.score)])).font(PiyaliBrand.productFont(12,500)).foregroundStyle(brand.muted)
            }.padding(16).frame(maxWidth:.infinity).background(Color(red:14/255,green:128/255,blue:149/255).opacity(0.07),in:RoundedRectangle(cornerRadius:18)).overlay { RoundedRectangle(cornerRadius:18).stroke(Color(red:70/255,green:185/255,blue:205/255),lineWidth:1.5) }
            Button(t("proficiency_modal_start_level",["level":estimate.level])) { start(estimate) }.buttonStyle(PlacementChoiceStyle()).accessibilityIdentifier("placementStart")
            Link(t("proficiency_modal_take_test_now"),destination:AppConfiguration().web.appendingPathComponent("proficiency")).buttonStyle(PlacementChoiceStyle()).accessibilityIdentifier("placementWebTest")
            Button(t("proficiency_modal_back")) { scene=2 }.font(PiyaliBrand.productFont(14,600))
        }
    }
    private func start(_ placement:Placement) { saving=true;app.place(placement);dismiss() }
}
private struct PlacementChoiceStyle:ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var enabled
    var primary=false
    func makeBody(configuration:Configuration)->some View {
        let brand=PiyaliBrand(dark:scheme == .dark)
        configuration.label.font(PiyaliBrand.productFont(15,700)).multilineTextAlignment(.center).frame(maxWidth:.infinity,minHeight:48).padding(.horizontal,12).foregroundStyle(primary ? .white : brand.text)
            .background { RoundedRectangle(cornerRadius:18).fill(primary ? Color(red:0,green:181/255,blue:216/255) : brand.surface).shadow(color:primary ? Color(red:8/255,green:111/255,blue:131/255) : brand.border,radius:0,y:configuration.isPressed ? 0 : 4) }
            .overlay { RoundedRectangle(cornerRadius:18).stroke(primary ? Color.clear : brand.border) }.opacity(enabled ? 1 : 0.45)
    }
}
