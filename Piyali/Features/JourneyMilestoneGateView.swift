import SwiftUI

/// Mirrors the web gate: wait for a quiet 1.5 seconds after the existing modal chain.
struct JourneyMilestoneGateView:View {
    @EnvironmentObject var app:AppModel
    @StateObject private var journey=VoiceJourneyController()
    @State private var seen:Set<String>=[]
    let canPresent:Bool
    let onPresent:(VoiceJourneyController,Int)->Void
    private var scope:String {app.identity.npub+":"+app.learner.target}
    private var milestone:Int? {VoiceJourneyModel.pending(journey.data)}
    private var readyKey:String {scope+":"+String(milestone ?? 0)+":"+String(canPresent)+":"+String(journey.loading || journey.failed)}
    var body:some View {
        Color.clear.frame(height:0).accessibilityHidden(true)
            .task(id:scope){await journey.bind(app)}
            .task(id:readyKey){
                guard canPresent,!journey.loading,!journey.failed,let n=milestone else{return}
                let key=scope+":"+String(n),account=app.identity.npub,target=app.learner.target
                guard !seen.contains(key) else{return}
                do {try await Task.sleep(for:.milliseconds(1500))}catch{return}
                guard !Task.isCancelled,app.identity.npub == account,app.learner.target == target,VoiceJourneyModel.pending(journey.data) == n else{return}
                seen.insert(key);onPresent(journey,n)
                // The source presents immediately and treats acknowledgment failure as recoverable.
                Task{await journey.acknowledge(n,app)}
            }
            .onDisappear{journey.close()}
    }
}
