import SwiftUI

struct CompanionSaveNotice:Equatable,Identifiable {
    let id=UUID()
    let account:String,title:String,description:String
    static func rendered(_ text:String)->String{text.replacingOccurrences(of:"[\\t\\n\\r\\u000C ]+",with:" ",options:.regularExpression).trimmingCharacters(in:CharacterSet(charactersIn:" "))}
    var renderedTitle:String{Self.rendered(title)}
    var renderedDescription:String{Self.rendered(description)}
}
struct CompanionSaveNoticeView:View {
    let notice:CompanionSaveNotice
    private var idealWidth:CGFloat{let title=(notice.renderedTitle as NSString).size(withAttributes:[.font:UIFont.boldSystemFont(ofSize:16)]).width+8,description=notice.renderedDescription.components(separatedBy:"\n").map{($0 as NSString).size(withAttributes:[.font:UIFont.systemFont(ofSize:16)]).width}.max() ?? 0;return min(560,max(300,ceil(max(title,description)+80)))}
    var body:some View {
        HStack(alignment:.top,spacing:12){Image("Companion-SaveWarning").renderingMode(.template).resizable().frame(width:20,height:20).frame(height:24).accessibilityHidden(true)
            VStack(alignment:.leading,spacing:0){OnboardingText(text:notice.renderedTitle,size:16,weight:.bold,lineHeight:24).frame(maxWidth:.infinity,alignment:.leading).accessibilityIdentifier("companionSaveNoticeTitle");OnboardingText(text:notice.renderedDescription,size:16,lineHeight:24).frame(maxWidth:.infinity,alignment:.leading).accessibilityIdentifier("companionSaveNoticeDescription")}
        }.padding(.leading,16).padding(.trailing,32).padding(.vertical,12).frame(minWidth:300,idealWidth:idealWidth,maxWidth:idealWidth).foregroundStyle(.white).background(PiyaliBrand.unitColor("c53030"),in:RoundedRectangle(cornerRadius:6)).compositingGroup().shadow(color:.black.opacity(0.1),radius:8,y:10).environment(\.layoutDirection,.leftToRight).accessibilityElement(children:.contain).accessibilityIdentifier("companionSaveNotice")
    }
}
/// Separate non-key portal keeps feedback above nested SwiftUI covers while
/// leaving the current editor, goal dialog, keyboard and activity interactive.
struct CompanionSaveNoticePresenter:UIViewRepresentable {
    @EnvironmentObject var app:AppModel
    func makeCoordinator()->Coordinator{Coordinator()}
    func makeUIView(context:Context)->Anchor{let view=Anchor();view.sceneChanged={ [weak c=context.coordinator] scene in c?.scene=scene;c?.render() };return view}
    func updateUIView(_ view:Anchor,context:Context){context.coordinator.notices=app.companionSaveNotices;context.coordinator.render()}
    static func dismantleUIView(_ view:Anchor,coordinator:Coordinator){view.sceneChanged=nil;coordinator.portal?.isHidden=true;coordinator.portal=nil}
    final class Anchor:UIView{var sceneChanged:((UIWindowScene?)->Void)?;override func didMoveToWindow(){super.didMoveToWindow();if let scene=window?.windowScene{sceneChanged?(scene)}}}
    @MainActor final class Coordinator {
        weak var scene:UIWindowScene?
        var notices:[CompanionSaveNotice]=[],displayed:[CompanionSaveNotice]=[],portal:Portal?
        func render(){guard let scene,!notices.isEmpty else{portal?.regions=[:];portal?.isHidden=true;return};if portal?.windowScene === scene,portal?.isHidden == false,displayed == notices{return};if portal?.windowScene !== scene{portal?.isHidden=true;let window=Portal(windowScene:scene);window.backgroundColor = .clear;window.windowLevel = .alert+1;portal=window}
            displayed=notices;portal?.regions=[:];let window=portal;portal?.rootViewController=UIHostingController(rootView:CompanionSaveNoticeStack(notices:notices,onBounds:{[weak window] id,bounds in window?.regions[id]=bounds}));portal?.rootViewController?.view.backgroundColor = .clear;portal?.isHidden=false
        }
    }
    final class Portal:UIWindow{
        var regions:[UUID:CGRect]=[:]
        override var canBecomeKey:Bool{false}
        override func hitTest(_ point:CGPoint,with event:UIEvent?)->UIView?{guard regions.values.contains(where:{$0.contains(point)}) else{return nil};return super.hitTest(point,with:event) ?? rootViewController?.view}
    }
}
struct CompanionSaveNoticeStack:View {
    let notices:[CompanionSaveNotice]
    var onBounds:((UUID,CGRect)->Void)?=nil
    var body:some View{VStack{Spacer(minLength:0);VStack(spacing:16){ForEach(notices){notice in CompanionSaveNoticeView(notice:notice).onGeometryChange(for:CGRect.self,of:{$0.frame(in:.global)}){onBounds?(notice.id,$0)}}}.padding(8)}.frame(maxWidth:.infinity,maxHeight:.infinity)}
}
