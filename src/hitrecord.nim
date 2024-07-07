import geometry, scene, bvh

from std/options import Option, none, some, isNone, isSome, get
from std/math import sqrt, arctan2, PI
from std/fenv import epsilon
from std/algorithm import sorted
from std/sequtils import mapIt, filterIt, apply


proc getIntersection(aabb: Interval[Point3D]; ray: Ray): float32 {.inline.} =
    let
        (min, max) = (aabb.min - ray.origin, aabb.max - ray.origin)
        txSpan = newInterval(min.x / ray.dir[0], max.x / ray.dir[0])
        tySpan = newInterval(min.y / ray.dir[1], max.y / ray.dir[1])

    if txSpan.min > tySpan.max or tySpan.min > txSpan.max: return Inf

    let tzSpan = newInterval(min.z / ray.dir[2], max.z / ray.dir[2])
    var hitSpan = newInterval(max(txSpan.min, tySpan.min), min(txSpan.max, tySpan.max))
    
    if hitSpan.min > tzSpan.max or tzSpan.min > hitSpan.max: return Inf

    if tzSpan.min > hitSpan.min: hitSpan.min = tzSpan.min
    if tzSpan.max < hitSpan.max: hitSpan.max = tzSpan.max
                
    let tHit = if aabb.contains(ray.origin): hitSpan.max else: hitSpan.min
    if not ray.tspan.contains(tHit): return tHit


proc getLocalIntersection(shape: Shape, worldInvRay: Ray): float32 =
    case shape.kind
    of skAABox:
        let
            (min, max) = (shape.aabb.min - worldInvRay.origin, shape.aabb.max - worldInvRay.origin)
            txSpan = newInterval(min.x / worldInvRay.dir[0], max.x / worldInvRay.dir[0])
            tySpan = newInterval(min.y / worldInvRay.dir[1], max.y / worldInvRay.dir[1])

        if txSpan.min > tySpan.max or tySpan.min > txSpan.max: return Inf

        let tzSpan = newInterval(min.z / worldInvRay.dir[2], max.z / worldInvRay.dir[2])
        var hitSpan = newInterval(max(txSpan.min, tySpan.min), min(txSpan.max, tySpan.max))

        if hitSpan.min > tzSpan.max or tzSpan.min > hitSpan.max: return Inf

        if tzSpan.min > hitSpan.min: hitSpan.min = tzSpan.min
        if tzSpan.max < hitSpan.max: hitSpan.max = tzSpan.max

        let tHit = if shape.aabb.contains(worldInvRay.origin): hitSpan.max else: hitSpan.min
        if not worldInvRay.tspan.contains(tHit): return Inf

        return tHit

    of skTriangle:
        let 
            mat = [
                [shape.vertices[1].x - shape.vertices[0].x, shape.vertices[2].x - shape.vertices[0].x, -worldInvRay.dir[0]], 
                [shape.vertices[1].y - shape.vertices[0].y, shape.vertices[2].y - shape.vertices[0].y, -worldInvRay.dir[1]], 
                [shape.vertices[1].z - shape.vertices[0].z, shape.vertices[2].z - shape.vertices[0].z, -worldInvRay.dir[2]]
            ]
            vec = [worldInvRay.origin.x - shape.vertices[0].x, worldInvRay.origin.y - shape.vertices[0].y, worldInvRay.origin.z - shape.vertices[0].z]

        let sol = try: solve(mat, vec) except ValueError: return Inf
        if not worldInvRay.tspan.contains(sol[2]): return Inf
        if sol[0] < 0.0 or sol[1] < 0.0 or sol[0] + sol[1] > 1.0: return Inf

        return sol[2]

    of skSphere:
        let (a, b, c) = (norm2(worldInvRay.dir), dot(worldInvRay.origin.Vec3f, worldInvRay.dir), norm2(worldInvRay.origin.Vec3f) - shape.radius * shape.radius)
        let delta_4 = b * b - a * c
        if delta_4 < 0: return Inf

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        let tHit = 
            if worldInvRay.tspan.contains(t_l): t_l 
            elif worldInvRay.tspan.contains(t_r): t_r 
            else: return Inf

        return tHit

    of skPlane:
        if abs(worldInvRay.dir[2]) < epsilon(float32): return Inf
        let tHit = -worldInvRay.origin.z / worldInvRay.dir[2]
        if not worldInvRay.tspan.contains(t_hit): return Inf

        return tHit

    of skCylinder:
        let
            a = worldInvRay.dir[0] * worldInvRay.dir[0] + worldInvRay.dir[1] * worldInvRay.dir[1]
            b = 2 * (worldInvRay.dir[0] * worldInvRay.origin.x + worldInvRay.dir[1] * worldInvRay.origin.y)
            c = worldInvRay.origin.x * worldInvRay.origin.x + worldInvRay.origin.y * worldInvRay.origin.y - shape.R * shape.R
            delta = b * b - 4.0 * a * c

        if delta < 0.0: return Inf

        var tspan = newInterval((-b - sqrt(delta)) / (2 * a), (-b + sqrt(delta)) / (2 * a))

        if tspan.min > worldInvRay.tspan.max or tspan.max < worldInvRay.tspan.min: return Inf

        var tHit: float32 = tspan.min
        if tHit < worldInvRay.tspan.min:
            if tspan.max > worldInvRay.tspan.max: return Inf
            tHit = tspan.max

        var hitPt = worldInvRay.at(tHit)
        var phi = arctan2(hitPt.y, hitPt.x)
        if phi < 0.0: phi += 2.0 * PI

        if hitPt.z < shape.zSpan.min or hitPt.z > shape.zSpan.max or phi > shape.phiMax:
            if tHit == tspan.max: return Inf
            tHit = tspan.max
            if tHit > worldInvRay.tspan.max: return Inf
            
            hitPt = worldInvRay.at(tHit)
            phi = arctan2(hitPt.y, hitPt.x)
            if phi < 0.0: phi += 2.0 * PI
            if hitPt.z < shape.zSpan.min or hitPt.z > shape.zSpan.max or phi > shape.phiMax: return Inf

        return tHit


type HitInfo[T] = tuple[hit: T, t: float32]

proc getClosestHit*(root: BVHNode, worldRay: Ray): Option[HitInfo[ObjectHandler]] =
    var 
        nodeStack: seq[BVHNode] = @[root]
        closestHitInfo: HitInfo[ObjectHandler] = (nil, Inf.float32)
        currentBVH = root

    while nodeStack.len > 0:
        if currentBVH.isNil: 
            currentBVH = nodeStack.pop; continue
        if currentBVH.aabb.getIntersection(worldRay) == Inf:
            currentBVH = nodeStack.pop; continue

        case currentBVH.kind
        of nkLeaf:
            let handlersHitInfos = 
                currentBVH.handlers
                    .mapIt((hit: it, t: it.getAABB.getIntersection(worldRay)))
                    .sorted(proc(a, b: HitInfo[ObjectHandler]): int = cmp(a.t, b.t))
            
            for (handler, tHit) in handlersHitInfos:
                if tHit > closestHitInfo.t: break
                
                case handler.kind
                of hkShape: 
                    let tHit = handler.shape.getLocalIntersection(worldRay.transform(handler.transformation.inverse))
                    if tHit < closestHitInfo.t: closestHitInfo = (handler, tHit)
                    
                of hkMesh:
                    let meshHit = handler.mesh.tree.getClosestHit(worldRay)
                    if meshHit.isSome and meshHit.get.t < closestHitInfo.t: closestHitInfo = meshHit.get
                
        of nkBranch: 
            currentBVH.children
                .filterIt(not it.isNil)
                .mapIt((hit: it, t: it.aabb.getIntersection(worldRay)))
                .filterIt(it.t < closestHitInfo.t)
                .sorted(proc(a, b: HitInfo[BVHNode]): int = cmp(a.t, b.t))
                .apply(proc(a: HitInfo[BVHNode]) = nodeStack.add a.hit)

        currentBVH = nodeStack.pop


    if closestHitInfo.hit.isNil: return none HitInfo[ObjectHandler] 
    
    some closestHitInfo