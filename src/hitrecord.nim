import geometry, shapes, scene, camera

import std/options
from std/fenv import epsilon
from std/math import sqrt, arctan2, PI
from std/sequtils import concat, foldl, mapIt, filterIt
from std/algorithm import sorted


proc checkIntersection*(aabb: Interval[Point3D], ray: Ray): bool {.inline.} =
    # this is done in the same reference system
    let 
        (min, max) = (aabb.min - ray.origin, aabb.max - ray.origin)
        txSpan = newInterval(min.x / ray.dir[0], max.x / ray.dir[0])
        tySpan = newInterval(min.y / ray.dir[1], max.y / ray.dir[1])

    if txSpan.min > tySpan.max or tySpan.min > txSpan.max: return false

    let tzSpan = newInterval(min.z / ray.dir[2], max.z / ray.dir[2])
    
    var hitSpan = newInterval(max(txSpan.min, tySpan.min), min(txSpan.max, tySpan.max))
    if hitSpan.min > tzSpan.max or tzSpan.min > hitSpan.max: return false

    return true


proc getHitLeafs*(subScene: SubScene; ray: Ray): Option[seq[SceneNode]] =
    if subScene.tree.isNil: return none seq[SceneNode]
    if not checkIntersection(subScene.tree.aabb, ray): return none seq[SceneNode]

    var sceneNodes: seq[SceneNode]
    case subScene.tree.kind
    of nkLeaf: 
        sceneNodes.add subScene.tree
    of nkBranch:
        for node in [subScene.tree.left, subScene.tree.right]:
            if node != nil:
                let hits = getHitLeafs((subScene.rs, node), ray)
                if hits.isSome: sceneNodes = concat(sceneNodes, hits.get)

        if sceneNodes.len == 0: return none seq[SceneNode]

    some sceneNodes


type HitPayload* = object
    handler*: ShapeHandler
    ray*: Ray
    t*: float32
    
proc getHitPayload*(handler: ShapeHandler, worldInvRay: Ray): Option[HitPayload] =

    case handler.shape.kind
    of skAABox:
        let
            xSpan = newInterval((handler.shape.aabb.min.x - worldinvRay.origin.x) / worldinvRay.dir[0], (handler.shape.aabb.max.x - worldinvRay.origin.x) / worldinvRay.dir[0])
            ySpan = newInterval((handler.shape.aabb.min.y - worldinvRay.origin.y) / worldinvRay.dir[1], (handler.shape.aabb.max.y - worldinvRay.origin.y) / worldinvRay.dir[1])

        if xSpan.min > ySpan.max or ySpan.min > xSpan.max: return none HitPayload

        let zSpan = newInterval((handler.shape.aabb.min.z - worldinvRay.origin.z) / worldinvRay.dir[2], (handler.shape.aabb.min.z - worldinvRay.origin.z) / worldinvRay.dir[2])
        
        var (tHitMin, tHitMax) = (max(xSpan.min, ySpan.min), min(xSpan.max, ySpan.max))
        if tHitMin > zSpan.max or zSpan.min > tHitMax: return none HitPayload

        if zSpan.min > tHitMin: tHitMin = zSpan.min
        if zSpan.max < tHitMax: tHitMax = zSpan.max
                
        let tHit = if handler.shape.aabb.contains(worldinvRay.origin): tHitMax else: tHitMin
        if not worldinvRay.tspan.contains(tHit): return none HitPayload

        return some HitPayload(handler: handler, ray: worldinvRay, t: tHit)

    of skTriangle:
        let 
            mat = [
                [handler.shape.vertices[1].x - handler.shape.vertices[0].x, handler.shape.vertices[2].x - handler.shape.vertices[0].x, -worldInvRay.dir[0]], 
                [handler.shape.vertices[1].y - handler.shape.vertices[0].y, handler.shape.vertices[2].y - handler.shape.vertices[0].y, -worldInvRay.dir[1]], 
                [handler.shape.vertices[1].z - handler.shape.vertices[0].z, handler.shape.vertices[2].z - handler.shape.vertices[0].z, -worldInvRay.dir[2]]
            ]
            vec = [worldInvRay.origin.x - handler.shape.vertices[0].x, worldInvRay.origin.y - handler.shape.vertices[0].y, worldInvRay.origin.z - handler.shape.vertices[0].z]

        let sol = try: solve(mat, vec) except ValueError: return none HitPayload
        if not worldInvRay.tspan.contains(sol[2]): return none HitPayload
        if sol[0] < 0.0 or sol[1] < 0.0 or sol[0] + sol[1] > 1.0: return none HitPayload

        return some HitPayload(handler: handler, ray: worldInvRay, t: sol[2])

    of skSphere:
        let (a, b, c) = (norm2(worldInvRay.dir), dot(worldInvRay.origin.Vec3f, worldInvRay.dir), norm2(worldInvRay.origin.Vec3f) - handler.shape.radius * handler.shape.radius)
        let delta_4 = b * b - a * c
        if delta_4 < 0: return none HitPayload

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        let tHit = 
            if worldInvRay.tspan.contains(t_l): t_l 
            elif worldInvRay.tspan.contains(t_r): t_r 
            else: return none HitPayload

        return some HitPayload(handler: handler, ray: worldInvRay, t: tHit)

    of skPlane:
        if abs(worldInvRay.dir[2]) < epsilon(float32): return none HitPayload
        let tHit = -worldInvRay.origin.z / worldInvRay.dir[2]
        if not worldInvRay.tspan.contains(t_hit): return none HitPayload

        return some HitPayload(handler: handler, ray: worldInvRay, t: tHit)

    of skCylinder:
        let
            a = worldInvRay.dir[0] * worldInvRay.dir[0] + worldInvRay.dir[1] * worldInvRay.dir[1]
            b = 2 * (worldInvRay.dir[0] * worldInvRay.origin.x + worldInvRay.dir[1] * worldInvRay.origin.y)
            c = worldInvRay.origin.x * worldInvRay.origin.x + worldInvRay.origin.y * worldInvRay.origin.y - handler.shape.R * handler.shape.R
            delta = b * b - 4.0 * a * c

        if delta < 0.0: return none HitPayload

        var tspan = newInterval((-b - sqrt(delta)) / (2 * a), (-b + sqrt(delta)) / (2 * a))

        if tspan.min > worldInvRay.tspan.max or tspan.max < worldInvRay.tspan.min: return none HitPayload

        var tHit = tspan.min
        if tHit < worldInvRay.tspan.min:
            if tspan.max > worldInvRay.tspan.max: return none HitPayload
            tHit = tspan.max

        var hitPt = worldInvRay.at(tHit)
        var phi = arctan2(hitPt.y, hitPt.x)
        if phi < 0.0: phi += 2.0 * PI

        if hitPt.z < handler.shape.zSpan.min or hitPt.z > handler.shape.zSpan.max or phi > handler.shape.phiMax:
            if tHit == tspan.max: return none HitPayload
            tHit = tspan.max
            if tHit > worldInvRay.tspan.max: return none HitPayload
            
            hitPt = worldInvRay.at(tHit)
            phi = arctan2(hitPt.y, hitPt.x)
            if phi < 0.0: phi += 2.0 * PI
            if hitPt.z < handler.shape.zSpan.min or hitPt.z > handler.shape.zSpan.max or phi > handler.shape.phiMax: return none HitPayload

        return some HitPayload(handler: handler, ray: worldInvRay, t: tHit)


proc getHitPayloads(subScene: SubScene; localRay: Ray): seq[HitPayload] =
    var hittedHandlers: seq[ShapeHandler]
    for handler in subScene.tree.handlers:
        if checkIntersection(subScene.rs.getLocalAABB(handler), localRay): 
            hittedHandlers.add handler

    if hittedHandlers.len == 0: return @[]

    let worldRay = newRay(apply(newTranslation(subScene.rs.origin), localRay.origin), subScene.rs.compose(localRay.dir))
    hittedHandlers
        .mapIt(it.getHitPayload(worldRay.transform(it.transformation.inverse)))
        .filterIt(it.isSome)
        .mapIt(it.get)

proc getHitRecord*(refSystem: ReferenceSystem, localRay: Ray, hitLeafs: seq[SceneNode]): Option[seq[HitPayload]] =
    let hitPayloads = hitLeafs
        .mapIt((refSystem, it).getHitPayloads(localRay))
        .filterIt(it.len > 0)

    if hitPayloads.len == 0: return none seq[HitPayload]
    
    some hitPayloads
        .foldl(concat(a, b))
        .sorted(proc(a, b: HitPayload): int = cmp(a.t, b.t))