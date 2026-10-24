import Foundation

/// Source eye outlines and animation policy, independent of the native renderer.
public enum OrbVisuals {
    public static let data=(try? ContentLibrary.load(JSONValue.self,name:"orb-visuals")) ?? .null
    public static func expression(_ mood:String,data:JSONValue=OrbVisuals.data)->[Double] { let value=data["expressions"][mood];return (value == .null ? data["expressions"]["neutral"] : value).array.map(\.number) }
    public static func duration(_ kind:String,data:JSONValue=OrbVisuals.data)->Double { data["durations"][kind].number }
    public static func clamp(_ x:Double,_ lo:Double=0,_ hi:Double=1)->Double { min(hi,max(lo,x)) }
    public struct Pose:Equatable,Sendable {
        public var y=0.0,x=0.0,squash=0.0,roll=0.0,turn=0.0,pitch=0.0,burst=0.0
        public init() {}
    }
    public static func reaction(_ kind:String,elapsed t:Double,amount:Double,data:JSONValue=OrbVisuals.data)->Pose {
        var p=Pose();let d=duration(kind,data:data)
        guard d > 0,t >= 0,t < d else { return p }
        let envelope=pow(sin(.pi*t/d),2),tail=clamp((t-d+0.65)/0.65),settle=1-pow(tail,3)*(tail*(tail*6-15)+10)
        switch kind {
        case "boop":p.squash=sin(t*15)*exp(-t*4.2)*0.24;p.pitch = -sin(t*7)*exp(-t*3)*0.18;p.roll=sin(t*13)*exp(-t*4)*0.09
        case "wave":p.roll=sin(t*9)*envelope*0.26;p.x=sin(t*4.5)*envelope*0.12;p.y=envelope*0.1
        case "bounce":
            if t < 0.22 { p.squash=sin(t/0.22 * .pi)*0.23 }
            else { let b=t-0.22;p.y=abs(sin(b*5.5))*exp(-b*1.6);p.squash = -sin(b*11)*exp(-b*1.7)*0.16;p.roll=sin(b*5.5)*exp(-b*1.7)*0.12 }
        case "spin":let s=clamp((t-0.2)/1.8);p.turn = .pi*2*s*s*(3-2*s);p.squash=sin(t*6)*envelope*0.1;p.y=envelope*0.26;p.roll=envelope*0.16
        case "celebrate":p.y=abs(sin(t*6))*envelope*0.43;p.roll=sin(t*8)*envelope*0.25;p.x=sin(t*4)*envelope*0.17;p.squash=sin(t*12)*envelope*0.11;p.burst=envelope
        default:break
        }
        let scale=clamp(amount,0,1.5)*settle
        p.x *= scale;p.y *= scale;p.squash *= scale;p.roll *= scale;p.pitch *= scale;p.burst *= scale;p.turn *= amount > 0 ? 1 : 0
        return p
    }
    public struct Eyes:Sendable {
        public private(set) var values:[Double]
        public private(set) var velocity:[Double]
        public private(set) var changed=true
        private let data:JSONValue
        public init(mood:String,data:JSONValue=OrbVisuals.data) { self.data=data;values=OrbVisuals.expression(mood,data:data);velocity=Array(repeating:0,count:values.count) }
        public mutating func advance(mood:String,state:String,time:Double,dt:Double,immediate:Bool=false) {
            let target=OrbVisuals.expression(mood,data:data),gaze=mood == "curious" && state == "thinking" ? sin(time*0.9)*7 : 0,step=max(0,dt),decay=exp(-14*step)
            changed=false
            for i in target.indices {
                let destination=target[i]+(i < 256 && i%2 == 0 ? gaze : 0)
                if immediate { values[i]=destination;velocity[i]=0;changed=true;continue }
                let offset=values[i]-destination,v=velocity[i],impulse=v+14*offset,next=destination+(offset+impulse*step)*decay,nextV=(v-14*impulse*step)*decay
                if abs(next-values[i]) > 0.01 || abs(nextV) > 0.05 { changed=true }
                values[i]=next;velocity[i]=nextV
            }
        }
    }
}

/// The original visual-only voice envelope. It never changes audio or VAD.
public struct TutorVoiceEnvelope:Sendable {
    public private(set) var level=0.0
    private var noiseFloor=0.002,open:Bool,onset=0.0,quiet=0.0
    private let microphone:Bool
    public init(microphone:Bool) { self.microphone=microphone;open = !microphone }
    public mutating func sample(_ amplitude:Double,elapsedMs:Double)->Double {
        let rms=amplitude.isFinite ? max(0,amplitude) : 0,dt=min(100,max(0,elapsedMs)),opening=max(0.008,noiseFloor*3),closing=max(0.004,noiseFloor*1.8)
        if microphone {
            if !open {
                if rms < opening { noiseFloor += (min(rms,0.006)-noiseFloor)*(1-exp(-dt/1500)) }
                onset=rms >= opening ? onset+dt : 0
                if onset >= 65 {open=true;quiet=0}
            } else {quiet=rms < closing ? quiet+dt : 0;if quiet >= 140 {open=false;onset=0}}
        }
        let floor=microphone ? closing : 0.002,target=open ? sqrt(min(1,max(0,rms-floor)/0.12)) : 0,duration=target > level ? 110.0 : 280.0
        level += (target-level)*(1-exp(-dt/duration));if target == 0,level < 0.001 {level=0};return level
    }
}

public struct OrbDisplayPersonality:Equatable,Sendable {
    public let mood:String,state:String,reaction:String
    public init(mood:String,state:String,reaction:String){self.mood=mood;self.state=state;self.reaction=reaction}
    public static func random(excludeThinking:Bool=false,data:JSONValue=OrbVisuals.data,random:()->Double={Double.random(in:0..<1)})->Self {
        func choose(_ list:[String])->String {guard !list.isEmpty else{return "idle"};return list[min(list.count-1,max(0,Int(floor(random()*Double(list.count)))))]}
        let states=data["states"].array.map(\.string).filter{!excludeThinking || $0 != "thinking"}
        return .init(mood:choose(data["displayMoods"].array.map(\.string)),state:choose(states),reaction:choose(data["displayReactions"].array.map(\.string)))
    }
}
extension OrbVisuals {
    /// Conversations deliberately swaps its visual listening/speaking patterns.
    public static func conversationState(_ state:String,data:JSONValue=OrbVisuals.data)->String {let value=data["conversationStates"][state].string;return value.isEmpty ? state : value}
}
