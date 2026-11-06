import SwiftUI

/// Chakra useToast's Teams payload, including its ordinary and clipboard lifetimes.
struct TeamsNotice:Identifiable,Equatable {
    let id=UUID()
    let title:String
    var description:String?=nil
    var status="success"
    var duration:Double=5
    var closable=false
    var renderedTitle:String{CompanionSaveNotice.rendered(title)}
    var renderedDescription:String{CompanionSaveNotice.rendered(description ?? "")}
}

@MainActor final class TeamsNoticeCenter:ObservableObject {
    @Published private(set) var notices:[TeamsNotice]=[]
    @Published private(set) var confirmations:Set<UUID>=[]
    func cover(_ covered:Bool,by id:UUID){if covered{confirmations.insert(id)}else{confirmations.remove(id)}}
    private var scope="",timers:[UUID:Task<Void,Never>]=[:]
    private let wait:(Double)async throws->Void
    init(wait:@escaping(Double)async throws->Void={try await Task.sleep(for:.seconds($0))}){self.wait=wait}
    func bind(_ scope:String){guard self.scope != scope else{return};self.scope=scope;timers.values.forEach{$0.cancel()};timers=[:];notices=[];confirmations=[]}
    func show(_ notice:TeamsNotice,scope:String){
        bind(scope);guard !scope.isEmpty else{return};notices.append(notice)
        UIAccessibility.post(notification:.announcement,argument:notice.renderedTitle+". "+notice.renderedDescription)
        timers[notice.id]=Task{[weak self,wait] in
            do{try await wait(notice.duration);try Task.checkCancellation()}catch{return}
            guard let self,self.scope == scope else{return};self.dismiss(notice.id)
        }
    }
    func dismiss(_ id:UUID){notices.removeAll{$0.id == id};timers.removeValue(forKey:id)?.cancel()}
}
extension AppModel {
    var teamsNoticeScope:String{signedIn ? identity.npub+identity.sessionRevision.uuidString:""}
    func showTeamsNotice(_ notice:TeamsNotice){teamsNotices.show(notice,scope:teamsNoticeScope)}
}
struct TeamsNoticeView:View {
    let notice:TeamsNotice
    var closeLabel="Close"
    var rtl=false
    var dismiss:()->Void={}
    private var idealWidth:CGFloat{
        let title=(notice.renderedTitle as NSString).size(withAttributes:[.font:UIFont.boldSystemFont(ofSize:16)]).width+8
        let description=(notice.renderedDescription as NSString).size(withAttributes:[.font:UIFont.systemFont(ofSize:16)]).width
        return min(560,max(300,ceil(max(title,description)+80)))
    }
    // Match HTML paragraph direction even when Arabic uses English fallback copy.
    private func directed(_ text:String)->String{rtl ? "\u{200F}"+text+"\u{200F}":text}
    var body:some View{
        HStack(alignment:.top,spacing:12){
            Image(notice.status == "success" ? "Teams-NoticeSuccess":"Companion-SaveWarning").renderingMode(.template).resizable().frame(width:20,height:20).frame(height:24).accessibilityHidden(true)
            VStack(alignment:.leading,spacing:0){
                OnboardingText(text:directed(notice.renderedTitle),size:16,weight:.bold,lineHeight:24).accessibilityLabel(notice.renderedTitle).padding(.trailing,8).frame(maxWidth:.infinity,alignment:.leading).accessibilityIdentifier("teamsNoticeTitle")
                if !notice.renderedDescription.isEmpty{OnboardingText(text:directed(notice.renderedDescription),size:16,lineHeight:24).accessibilityLabel(notice.renderedDescription).frame(maxWidth:.infinity,alignment:.leading).accessibilityIdentifier("teamsNoticeDescription")}
            }
        }.padding(.leading,16).padding(.trailing,32).padding(.vertical,12).frame(idealWidth:idealWidth,maxWidth:idealWidth)
            .foregroundStyle(.white).background(PiyaliBrand.unitColor(notice.status == "error" ? "c53030":notice.status == "warning" ? "c05621":"2f855a"),in:RoundedRectangle(cornerRadius:6))
            .overlay(alignment:rtl ? .topLeading:.topTrailing){if notice.closable{Button(action:dismiss){Image("Teams-NoticeClose").renderingMode(.template).resizable().frame(width:10,height:10).foregroundStyle(.white).accessibilityHidden(true).frame(width:24,height:24)}.buttonStyle(.plain).padding(4).accessibilityLabel(closeLabel).accessibilityIdentifier("teamsNoticeClose")}}
            .compositingGroup().shadow(color:.black.opacity(0.1),radius:8,y:10).environment(\.layoutDirection,rtl ? .rightToLeft:.leftToRight).accessibilityElement(children:.contain).accessibilityIdentifier("teamsNotice")
    }
}
struct TeamsNoticeStack:View {
    let notices:[TeamsNotice]
    var closeLabel="Close"
    var rtl=false
    var dismiss:(UUID)->Void={_ in}
    var onBounds:((UUID,CGRect)->Void)?=nil
    var body:some View{VStack{Spacer(minLength:0);VStack(spacing:16){ForEach(notices){notice in TeamsNoticeView(notice:notice,closeLabel:closeLabel,rtl:rtl,dismiss:{dismiss(notice.id)}).onGeometryChange(for:CGRect.self,of:{$0.frame(in:.global)}){onBounds?(notice.id,$0)}}}.padding(8)}.frame(maxWidth:.infinity,maxHeight:.infinity)}
}
/// An app-owned, non-key portal survives drawer dismissal and stays above its editor.
struct TeamsNoticePresenter:UIViewRepresentable {
    @ObservedObject var center:TeamsNoticeCenter
    var closeLabel:String
    var rtl=false
    func makeCoordinator()->Coordinator{Coordinator()}
    func makeUIView(context:Context)->CompanionSaveNoticePresenter.Anchor{let view=CompanionSaveNoticePresenter.Anchor();view.sceneChanged={[weak c=context.coordinator] scene in c?.scene=scene;c?.render()};return view}
    func updateUIView(_ view:CompanionSaveNoticePresenter.Anchor,context:Context){context.coordinator.center=center;context.coordinator.closeLabel=closeLabel;context.coordinator.rtl=rtl;context.coordinator.render()}
    static func dismantleUIView(_ view:CompanionSaveNoticePresenter.Anchor,coordinator:Coordinator){view.sceneChanged=nil;coordinator.portal?.isHidden=true;coordinator.portal=nil}
    @MainActor final class Coordinator {
        weak var scene:UIWindowScene?
        var center:TeamsNoticeCenter?,closeLabel="Close",portal:CompanionSaveNoticePresenter.Portal?
        var rtl=false
        private var displayed:[TeamsNotice]=[],displayedRTL=false,displayedLabel=""
        func render(){
            guard let scene,let center,!center.notices.isEmpty,center.confirmations.isEmpty else{portal?.regions=[:];portal?.isHidden=true;portal?.rootViewController=nil;portal=nil;displayed=[];return}
            if portal?.windowScene === scene,portal?.isHidden == false,displayed == center.notices,displayedRTL == rtl,displayedLabel == closeLabel{return}
            if portal?.windowScene !== scene{portal?.isHidden=true;let window=CompanionSaveNoticePresenter.Portal(windowScene:scene);window.backgroundColor = .clear;window.windowLevel = .alert+2;portal=window}
            displayed=center.notices;displayedRTL=rtl;displayedLabel=closeLabel;portal?.regions=[:];let window=portal
            portal?.rootViewController=UIHostingController(rootView:TeamsNoticeStack(notices:center.notices,closeLabel:closeLabel,rtl:rtl,dismiss:{[weak center] in center?.dismiss($0)},onBounds:{[weak window] id,bounds in window?.regions[id]=bounds}))
            portal?.rootViewController?.view.backgroundColor = .clear;portal?.isHidden=false
        }
    }
}
