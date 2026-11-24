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
        guard center else { return world.start }
        return centeredStart(world:world,occupied:Set(npcs.map { RPGPoint(x:$0.tx,y:$0.ty) }))
    }

    static func centeredStart(world:RPGWorld,occupied:Set<RPGPoint>)->RPGPoint {
        let centerX=(world.width-1)/2,centerY=(world.height-1)/2
        var best=world.start,distance=Int.max,tie=Double.infinity
        for row in 0..<world.height {
            for column in 0..<world.width {
                let tile=RPGPoint(x:column,y:row)
                guard world.walkable(tile),!occupied.contains(tile) else { continue }
                let dx=column-centerX,dy=row-centerY
                let score=abs(dx)+abs(dy),diagonal=hypot(Double(dx),Double(dy))
                if score < distance || score == distance && diagonal < tie {
                    best=tile
                    distance=score
                    tie=diagonal
                }
            }
        }
        return best
    }
}
