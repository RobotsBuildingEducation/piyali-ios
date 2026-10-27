import SwiftUI

struct GamePreparationView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var phase
    @ObservedObject var preparation:GamePreparationController
    let onCancel:()->Void
    var embedded=false
    var messageIndex:Int?
    var freezeAnimation=false
    @State private var sounds=PracticeSoundPlayer()
    @StateObject private var model:GameLoaderModel
    @State private var started=Date()
    init(preparation:GamePreparationController,support:String,pet:String,seed:Double?=nil,model:GameLoaderModel?=nil,embedded:Bool=false,messageIndex:Int?=nil,freezeAnimation:Bool=false,onCancel:@escaping()->Void){self.preparation=preparation;self.onCancel=onCancel;self.embedded=embedded;self.messageIndex=messageIndex;self.freezeAnimation=freezeAnimation;_model=StateObject(wrappedValue:model ?? GameLoaderModel(seed:seed ?? Self.fixtureSeed ?? Date().timeIntervalSince1970*1000,support:support,pet:pet))}
    private var light:Bool{scheme != .dark}
    private var panel:Color{PiyaliBrand.unitColor(light ? "fffaf1":"faf4e8").opacity(light ? 0.98:0.96)}
    private var border:Color{PiyaliBrand.unitColor(light ? "e0b474":"fbd38d").opacity(light ? 0.9:1)}
    private var ink:Color{PiyaliBrand.unitColor(light ? "5b4430":"1a202c")}
    private var topInset:CGFloat{embedded ? 0:(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.flatMap(\.windows).first{$0.isKeyWindow}?.safeAreaInsets.top ?? 0)}
    var body:some View{
        GeometryReader{geometry in
            ZStack{
                GameLoaderCanvas(model:model,paused:freezeAnimation || phase != .active)
                if let name=model.roomName{GameLoaderMonoText(text:name,size:16,bold:true,fillWidth:false,color:ink).padding(.horizontal,20).padding(.vertical,8).padding(2).background(panel,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(border,lineWidth:2)}.shadow(color:light ? PiyaliBrand.unitColor("543e24").opacity(0.16):.black.opacity(0.52),radius:light ? 12:19,y:light ? 12:18).allowsHitTesting(false).accessibilityIdentifier("gamePreparationRoom")}
                if let message=model.message{VStack{Spacer();GameLoaderMonoText(text:message,color:ink).frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,16).padding(.vertical,12).padding(2).background(panel,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(border,lineWidth:2)}.padding(12)}.allowsHitTesting(false).accessibilityIdentifier("gamePreparationMessage")}
                VStack{TimelineView(.periodic(from:started,by:1.5)){context in
                    let messages=(try? model.policy?.run("copy",.object(["language":.string(app.learner.support)])))?.array.map(\.string) ?? []
                    HStack(spacing:12){GameLoaderMonoText(text:messages.isEmpty ? "" : messages[(messageIndex ?? max(0,Int(context.date.timeIntervalSince(started)/1.5)))%messages.count],color:PiyaliBrand.unitColor("bee3f8")).frame(maxWidth:.infinity,minHeight:24,alignment:.leading).accessibilityIdentifier("gamePreparationStatus")
                        Button(EntryCopy.ui(app.learner.support,"common_cancel"),action:onCancel).font(PiyaliBrand.font(14,600)).foregroundStyle(light ? PiyaliBrand.unitColor("2f261d"):.white.opacity(0.92)).padding(.horizontal,12).frame(height:32).accessibilityIdentifier("cancelGamePreparation")
                    }.padding(12).padding(.top,topInset).background(LinearGradient(colors:[Color(red:10/255,green:13/255,blue:27/255).opacity(0.96),Color(red:10/255,green:13/255,blue:27/255).opacity(0.72),.clear],startPoint:.top,endPoint:.bottom))
                };Spacer()}.allowsHitTesting(true)
            }.ignoresSafeArea().background(PiyaliBrand.unitColor("08142b")).statusBarHidden().interactiveDismissDisabled()
        }.ignoresSafeArea(.container)
            .onChange(of:app.learner.effectiveCompanionType){_,pet in _=try? model.policy?.run("pet",.object(["pet":.string(pet)]))}
            .onAppear{model.onSound={sounds.play($0,enabled:app.learner.soundEffectsEnabled,volume:app.learner.settingsSnapshot["soundVolume"] == .null ? 100:app.learner.settingsSnapshot["soundVolume"].number)}}
            .onDisappear{model.onSound=nil;sounds.stop();if !preparation.ready,preparation.error == nil{preparation.cancel()}}
    }
    private static var fixtureSeed:Double?{
        #if DEBUG
        let e=ProcessInfo.processInfo.environment
        if e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_LIVE_API_TESTS"] != "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,let seed=Double(e["PIYALI_GAME_LOADER_SEED"] ?? ""){return seed}
        #endif
        return nil
    }
}
