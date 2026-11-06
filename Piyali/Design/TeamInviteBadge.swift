import SwiftUI

struct TeamInviteDot:View {
    @ObservedObject var startup:TeamsStartupController
    var border:Color
    var body:some View {if startup.attention.hasUnseen{Circle().fill(PiyaliBrand.unitColor("e53e3e")).overlay{Circle().strokeBorder(border,lineWidth:2)}.frame(width:9,height:9).accessibilityHidden(true)}}
}
struct TeamInviteMenuButton:View {
    @ObservedObject var startup:TeamsStartupController
    @ObservedObject var capture:MemoryCaptureController
    let scope:String,language:String,label:String
    let glyphSize:CGFloat,size:CGFloat,radius:CGFloat,background:Color,border:Color,foreground:Color,dotBorder:Color
    var standalone=false
    let action:()->Void
    var body:some View {
        MemoryCaptureMenuButton(capture:capture,scope:scope,language:language,label:label,glyphSize:glyphSize,size:size,radius:radius,background:standalone ? .clear:background,border:standalone ? .clear:border,foreground:foreground,action:action)
            .background{if standalone{SourceNavigationGlass()}}
            .overlay{TeamInviteDot(startup:startup,border:dotBorder).offset(x:glyphSize/2-0.5,y:-glyphSize/2+1.5).allowsHitTesting(false)}
            .accessibilityValue(startup.attention.hasUnseen ? pending:(capture.current(in:scope) == nil ? "":EntryCopy.ui(language,"vocab_note_saved")))
    }
    private var pending:String {let text=EntryCopy.ui(language,"teams_view_pending");return (text == "teams_view_pending" ? "Pending invitations":text)+": \(startup.attention.count)"}
}
struct TeamInviteAccessibility:ViewModifier {
    @ObservedObject var startup:TeamsStartupController
    var language:String
    var enabled:Bool
    func body(content:Content)->some View {if enabled{content.accessibilityValue(startup.attention.hasUnseen ? EntryCopy.ui(language,"teams_view_pending")+": \(startup.attention.count)":"")}else{content}}
}

/// CompactActionBar's 66-point surface uses the original mobile glass fallback.
private struct SourceNavigationGlass:View {
    @Environment(\.colorScheme) private var scheme
    private var dark:Bool{scheme == .dark}
    var body:some View {
        Circle().fill(LinearGradient(stops:[.init(color:dark ? PiyaliBrand.unitColor("0b1220").opacity(0.18):PiyaliBrand.unitColor("fffcf7").opacity(0.58),location:0),.init(color:dark ? PiyaliBrand.unitColor("0b1220").opacity(0.18):PiyaliBrand.unitColor("f2e8d9").opacity(0.34),location:1)],startPoint:.top,endPoint:.bottom))
            .overlay{Circle().fill(LinearGradient(stops:[.init(color:.white.opacity(dark ? 0.12:0.72),location:0),.init(color:.clear,location:dark ? 0.52:0.48)],startPoint:.topLeading,endPoint:.bottomTrailing))}
            .overlay{Circle().stroke(dark ? PiyaliBrand.unitColor("94a3b8").opacity(0.2):PiyaliBrand.unitColor("7e5c3b").opacity(0.2))}
            .overlay{Circle().stroke(LinearGradient(stops:[.init(color:.white.opacity(dark ? 0.08:0.72),location:0),.init(color:.clear,location:0.4)],startPoint:.top,endPoint:.bottom),lineWidth:1).padding(0.5)}
            .shadow(color:PiyaliBrand.unitColor(dark ? "020617":"755938").opacity(dark ? 0.24:0.16),radius:dark ? 25:21,y:dark ? 20:18)
    }
}
