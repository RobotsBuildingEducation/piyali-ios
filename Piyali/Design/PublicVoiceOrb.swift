import SwiftUI

/// Display personality and boop/drag behavior from VoiceOrbNext; active lessons
/// switch to the tutor state without adding any controls to the public demo.
struct PublicVoiceOrb:View {
    var activeState:String?
    var audioLevel=0.0
    var animating=true
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var personality:OrbDisplayPersonality
    @State private var reaction:OrbDisplayReaction?
    @GestureState private var drag=CGSize.zero
    init(activeState:String?=nil,audioLevel:Double=0,animating:Bool=true) {
        self.activeState=activeState;self.audioLevel=audioLevel;self.animating=animating
        let initial=OrbDisplayPersonality.random();_personality=State(initialValue:initial);_reaction=State(initialValue:.init(kind:initial.reaction))
    }
    private var display:Bool {activeState == nil}
    private func boop(){if display {reaction = .init(kind:"boop")}}
    var body:some View {
        VoiceOrbView(state:activeState ?? personality.state,callActive:!display,personality:display ? personality : nil,displayReaction:display ? reaction : nil,dragging:display && drag != .zero,dragTurn:Double(drag.width)*0.009,audioLevel:audioLevel,dark:scheme == .dark,reducedMotion:reduceMotion,animating:animating)
            .contentShape(Circle().inset(by:18)).onTapGesture(perform:boop)
            .simultaneousGesture(DragGesture(minimumDistance:6).updating($drag){value,state,_ in if display {state=value.translation}})
            .accessibilityElement(children:.ignore).accessibilityLabel(display ? "Pet the orb" : "Tutor orb").accessibilityValue(display && reaction?.kind == "boop" ? "Loving reaction" : display ? personality.mood : activeState ?? "idle").accessibilityAddTraits(display ? .isButton : [])
            .task(id:display ? reaction?.id : nil) {
                guard display,let id=reaction?.id,let kind=reaction?.kind else{return}
                do {try await Task.sleep(for:.seconds(OrbVisuals.duration(kind)+0.65))} catch {return}
                if reaction?.id == id {reaction=nil}
            }
            .task(id:display && animating) {
                guard display,animating else{return}
                while !Task.isCancelled {
                    do {try await Task.sleep(for:.milliseconds(6500))} catch {return}
                    personality=OrbDisplayPersonality.random();reaction = .init(kind:personality.reaction)
                }
            }
    }
}
