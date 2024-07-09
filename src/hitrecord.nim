import geometry, scene

from std/options import Option, none, some, isNone, isSome, get
from std/math import sqrt, arctan2, PI, pow
from std/fenv import epsilon
from std/algorithm import sorted
from std/sequtils import concat, foldl, mapIt, filterIt


proc checkIntersection*(aabb: Interval[Point3D], ray: Ray): bool {.inline.} =
    let
        (min, max) = (aabb.min - ray.origin, aabb.max - ray.origin)
        txSpan = newInterval(min.x / ray.dir[0], max.x / ray.dir[0])
        tySpan = newInterval(min.y / ray.dir[1], max.y / ray.dir[1])

    if txSpan.min > tySpan.max or tySpan.min > txSpan.max: return false

    let tzSpan = newInterval(min.z / ray.dir[2], max.z / ray.dir[2])
    var hitSpan = newInterval(max(txSpan.min, tySpan.min), min(txSpan.max, tySpan.max))
    
    if hitSpan.min > tzSpan.max or tzSpan.min > hitSpan.max: return false

    if tzSpan.min > hitSpan.min: hitSpan.min = tzSpan.min
    if tzSpan.max < hitSpan.max: hitSpan.max = tzSpan.max
                
    let tHit = if aabb.contains(ray.origin): hitSpan.max else: hitSpan.min
    if not ray.tspan.contains(tHit): return false

    return true


proc getHitLeafs*(sceneTree: SceneNode; ray: Ray): Option[seq[SceneNode]] =
    if sceneTree.isNil: return none seq[SceneNode]

    if not checkIntersection(sceneTree.aabb, ray): return none seq[SceneNode]

    var sceneNodes: seq[SceneNode]
    case sceneTree.kind
    of nkLeaf: sceneNodes.add sceneTree
    
    of nkBranch:
        for childNode in sceneTree.children:
            let hits = childNode.getHitLeafs(ray)
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
            (min, max) = (handler.shape.aabb.min - worldInvRay.origin, handler.shape.aabb.max - worldInvRay.origin)
            txSpan = newInterval(min.x / worldInvRay.dir[0], max.x / worldInvRay.dir[0])
            tySpan = newInterval(min.y / worldInvRay.dir[1], max.y / worldInvRay.dir[1])

        if txSpan.min > tySpan.max or tySpan.min > txSpan.max: return none HitPayload

        let tzSpan = newInterval(min.z / worldInvRay.dir[2], max.z / worldInvRay.dir[2])
        var hitSpan = newInterval(max(txSpan.min, tySpan.min), min(txSpan.max, tySpan.max))

        if hitSpan.min > tzSpan.max or tzSpan.min > hitSpan.max: return none HitPayload

        if tzSpan.min > hitSpan.min: hitSpan.min = tzSpan.min
        if tzSpan.max < hitSpan.max: hitSpan.max = tzSpan.max

        let tHit = if handler.shape.aabb.contains(worldInvRay.origin): hitSpan.max else: hitSpan.min
        if not worldInvRay.tspan.contains(tHit): return none HitPayload

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

        if areClose(worldInvRay.dir[0], 0) and areClose(worldInvRay.dir[1], 0) and worldInvRay.dir[2] != 0:
            if not areClose(pow(worldInvRay.origin.x, 2) + pow(worldInvRay.origin.y, 2), pow(handler.shape.R, 2)):
                return none HitPayload

        if hitPt.z < handler.shape.zSpan.min or hitPt.z > handler.shape.zSpan.max or phi > handler.shape.phiMax:
            if tHit == tspan.max: return none HitPayload
            tHit = tspan.max
            if tHit > worldInvRay.tspan.max: return none HitPayload
            
            hitPt = worldInvRay.at(tHit)
            phi = arctan2(hitPt.y, hitPt.x)
            if phi < 0.0: phi += 2.0 * PI
            if hitPt.z < handler.shape.zSpan.min or hitPt.z > handler.shape.zSpan.max or phi > handler.shape.phiMax: return none HitPayload

        return some HitPayload(handler: handler, ray: worldInvRay, t: tHit)

    of skTriangularMesh: 
        let localHitLeafNodes = handler.shape.tree.getHitLeafs(worldInvRay)
        if localHitLeafNodes.isNone: return none HitPayload
        
        proc localHitPayloads(sceneTree: SceneNode; worldInvRay: Ray): seq[HitPayload] =
            var hittedHandlers: seq[ShapeHandler]
            for handler in sceneTree.handlers:
                if checkIntersection(handler.getAABB, worldInvRay): hittedHandlers.add handler

            if hittedHandlers.len == 0: return @[]

            hittedHandlers
                .mapIt(it.getHitPayload(worldInvRay))
                .filterIt(it.isSome)
                .mapIt(it.get)

        proc localHitRecord(hitLeafs: seq[SceneNode]; worldInvRay: Ray): Option[seq[HitPayload]] =
            let hitPayloads = hitLeafs
                .mapIt(it.localHitPayloads(worldInvRay))
                .filterIt(it.len > 0)

            if hitPayloads.len == 0: return none seq[HitPayload]
            
            some hitPayloads.foldl(concat(a, b))
                
        let hitRecord = localHitLeafNodes.get.localHitRecord(worldInvRay)
        if hitRecord.isNone: return none HitPayload
        
        some hitRecord.get.sorted(proc(a, b: HitPayload): int = cmp(a.t, b.t))[0]

    of skEllipsoid: 
        var 
            hit: Option[HitPayload]
            scal = newScaling(newVec3f(1/handler.shape.axis.a, 1/handler.shape.axis.b, 1/handler.shape.axis.c))
        
        hit = getHitPayload(
            ShapeHandler(shape: Shape(kind: skSphere, radius: 1), transformation: handler.transformation),
            worldInvRay.transform(scal)
            )
        
        if hit.isNone: return none HitPayload

        some HitPayload(handler: handler, ray: worldInvRay, t: hit.get.t)
    
    of skCSGUnion: 
        var 
            hitS: seq[Option[HitPayload]]
            appo: seq[HitPayload]

        hitS.add getHitPayload(
            ShapeHandler(shape: handler.shape.shapes.primary, transformation: handler.shape.shTrans.tPrimary),
            worldInvRay.transform(handler.shape.shTrans.tPrimary.inverse)
            )
        
        hitS.add getHitPayload(
            ShapeHandler(shape: handler.shape.shapes.secondary, transformation: handler.shape.shTrans.tSecondary),
            worldInvRay.transform(handler.shape.shTrans.tSecondary.inverse)
            )
        
        appo = hitS.filterIt(it.isSome).mapIt(it.get)
        if appo.len == 0: return none HitPayload

        appo = appo.sorted(proc(a, b: HitPayload): int = cmp(a.t, b.t))
        return some HitPayload(
            handler: ShapeHandler(shape: appo[0].handler.shape, transformation: handler.transformation @ appo[0].handler.transformation),
            ray: worldInvRay, t: appo[0].t
        )
        

proc getHitPayloads*(sceneTree: SceneNode; worldRay: Ray): seq[HitPayload] =
    var hittedHandlers: seq[ShapeHandler]
    for handler in sceneTree.handlers:
        if checkIntersection(handler.getAABB, worldRay): hittedHandlers.add handler

    if hittedHandlers.len == 0: return @[]

    hittedHandlers
        .mapIt(it.getHitPayload(worldRay.transform(it.transformation.inverse)))
        .filterIt(it.isSome)
        .mapIt(it.get)


proc getHitRecord*(hitLeafs: seq[SceneNode]; worldRay: Ray): Option[seq[HitPayload]] =
    let hitPayloads = hitLeafs
        .mapIt(it.getHitPayloads(worldRay))
        .filterIt(it.len > 0)

    if hitPayloads.len == 0: return none seq[HitPayload]
    
    some hitPayloads.foldl(concat(a, b))