import Foundation

public struct RPGEnvironmentLibrary:Decodable,Sendable {
    public let version:Int
    public let lookup:[String:[String:String]],plans:[String:RPGEnvironmentPlan],pets:[String:[String:[String]]],textures:[String]
    public func plan(_ scenario:RPGScenario)->RPGEnvironmentPlan?{guard let key=lookup[scenario.worldKey]?[scenario.id] else{return nil};return plans[key]}
    public func frames(pet:String,direction:String)->[String]{pets[pet]?[direction] ?? []}
}
public struct RPGEnvironmentPlan:Decodable,Sendable {
    public struct Identity:Decodable,Sendable {public let scenario:String,map:String,environment:String,area:String,decorKinds:[String]}
    public let identity:Identity,grade:String,layers:[RPGEnvironmentLayer]
}
public struct RPGEnvironmentLayer:Decodable,Sendable {
    public struct Motion:Decodable,Sendable {public let kind:String,phase:Double;public let speed:Double?,drift:Double?,startX:Double?,startY:Double?,baseY:Double?,baseOpacity:Double?}
    public let image:String,x:Double,y:Double,width:Double,height:Double,z:Double,scaleX:Double,scaleY:Double,rotation:Double,alpha:Double,blend:String,smooth:Bool,motion:Motion?
    /// The original main-product frame equations, in its 32-unit world space.
    /// Decorations change appearance only; collision and saved tile positions
    /// remain authored data.
    public func frame(at time:Double)->RPGEnvironmentTransform {
        var result=RPGEnvironmentTransform(x:x,y:y,scaleX:scaleX,scaleY:scaleY,rotation:rotation,alpha:alpha)
        guard let m=motion else{return result};let t=time.isFinite ? max(0,time):0,p=m.phase
        switch m.kind {
        case "mote":
            let speed=m.speed ?? 0
            result.x=(m.startX ?? x)+sin(t*speed+p)*32
            result.y=(m.startY ?? y)+cos(t*speed*0.72+p)*32*0.7+sin(t*0.18+p)*(m.drift ?? 0)
            result.alpha=(m.baseOpacity ?? alpha)*(0.58+sin(t*0.9+p)*0.22)
        case "patch":
            let breath=1+sin(t*0.75+p)*0.04;result.scaleX=breath;result.scaleY=breath
            result.alpha=(m.baseOpacity ?? alpha)*(0.8+sin(t*0.62+p)*0.08)
        case "balloons":result.y=(m.baseY ?? y)+sin(t*1.05+p)*32*0.04;result.rotation=sin(t*0.7+p)*0.018
        case "fountain":result.scaleX=1;result.scaleY=1+sin(t*1.8+p)*0.012
        default:result.rotation=sin(t*0.55+p)*(m.kind == "tree" ? 0.008:0.014)
        }
        return result
    }
    public static func indicatorScale(time:Double,npcIndex:Int)->Double{1+sin(time*6+Double(npcIndex))*0.08}
}
public struct RPGEnvironmentTransform:Equatable,Sendable {
    public var x:Double,y:Double,scaleX:Double,scaleY:Double,rotation:Double,alpha:Double
}
public struct RPGPetAnimationClock:Equatable,Sendable {
    public private(set) var milliseconds=0.0,frame=0,walkCounter=0,walkFrame=0
    private var moveCooldown=0.0,idleHold=0.0
    public static let ambientTypes:Set<String>=["ghost","robot","slime","axolotl"]
    public init(){}
    @discardableResult public mutating func advance(milliseconds delta:Double,pet:String)->Int? {
        guard delta.isFinite,delta>=0 else{return nil}
        moveCooldown -= delta
        if moveCooldown<=0{idleHold=max(0,idleHold-delta);if idleHold<=0{walkFrame=0}}
        milliseconds += delta
        guard milliseconds>=130 else{return nil};milliseconds=0;frame=(frame+1)%3600
        return Self.ambientTypes.contains(pet) ? frame:nil
    }
    public mutating func walk(){walkCounter += 1;walkFrame=walkCounter%6;moveCooldown=140;idleHold=400}
    public mutating func changedCompanion(){walkFrame=0}
    public func displayedFrame(pet:String)->Int{Self.ambientTypes.contains(pet) ? frame:walkFrame}
}
