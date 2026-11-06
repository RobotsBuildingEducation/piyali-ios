import Foundation

/// The source map click moves one tile toward the tap, preferring the larger
/// delta, then its other axis. Characters block movement just like solid tiles.
public enum RPGSpatial {
    public struct Move:Equatable,Sendable {public let position:RPGPoint;public let moved:Bool;public let direction:String}
    public static func step(from p:RPGPoint,toward target:RPGPoint,world:RPGWorld,npcs:[RPGNPC])->Move {
        let dx=target.x-p.x,dy=target.y-p.y,sign:(Int)->Int={$0 == 0 ? 0:($0>0 ? 1:-1)}
        let horizontal=abs(dx)>=abs(dy),a=horizontal ? RPGPoint(x:sign(dx),y:0):RPGPoint(x:0,y:sign(dy)),b=horizontal ? RPGPoint(x:0,y:sign(dy)):RPGPoint(x:sign(dx),y:0)
        for d in [a,b] where d.x != 0 || d.y != 0 {
            let next=RPGPoint(x:p.x+d.x,y:p.y+d.y)
            if world.walkable(next),!npcs.contains(where:{$0.tx == next.x && $0.ty == next.y}){return Move(position:next,moved:true,direction:d.y<0 ? "up":d.y>0 ? "down":d.x<0 ? "left":"right")}
        };return Move(position:p,moved:false,direction:"down")
    }
    public static func start(world:RPGWorld,npcs:[RPGNPC],center:Bool)->RPGPoint {
        guard center else{return world.start};let x=(world.width-1)/2,y=(world.height-1)/2;var best:RPGPoint?,distance=Int.max,tie=Double.infinity
        for row in 0..<world.height{for column in 0..<world.width{let p=RPGPoint(x:column,y:row);guard world.walkable(p),!npcs.contains(where:{$0.tx == column && $0.ty == row})else{continue};let d=abs(column-x)+abs(row-y),t=hypot(Double(column-x),Double(row-y));if d<distance || d == distance && t<tie{best=p;distance=d;tie=t}}};return best ?? world.start
    }
}
