import geometry, shapes, scene, camera

import std/options
from std/fenv import epsilon
from std/math import sqrt, arctan2, PI
from std/sequtils import concat, map, foldl, filter
from std/algorithm import sorted


proc checkIntersection*(handler: ShapeHandler, ray: Ray): bool =

    case handler.shape.kind
    of skAABox:
        let invRay = ray.transform(handler.transformation.inverse)
        let (min, max) = (handler.shape.aabb.min - invRay.origin, handler.shape.aabb.max - invRay.origin)
        let
            txspan = newInterval(min.x / invRay.dir[0], max.x / invRay.dir[0])
            tyspan = newInterval(min.y / invRay.dir[1], max.y / invRay.dir[1])

        if txspan.min > tyspan.max or tyspan.min > txspan.max: return false

        let tzspan = newInterval(min.z / invRay.dir[2], max.z / invRay.dir[2])
        
        var hitspan = newInterval(max(txspan.min, tyspan.min), min(txspan.max, tyspan.max))
        if hitspan.min > tzspan.max or tzspan.min > hitspan.max: return false

        return true

    of skTriangle: 
        let 
            invRay = ray.transform(handler.transformation.inverse)
            mat = [
                [handler.shape.vertices[1].x - handler.shape.vertices[0].x, handler.shape.vertices[2].x - handler.shape.vertices[0].x, -invRay.dir[0]], 
                [handler.shape.vertices[1].y - handler.shape.vertices[0].y, handler.shape.vertices[2].y - handler.shape.vertices[0].y, -invRay.dir[1]], 
                [handler.shape.vertices[1].z - handler.shape.vertices[0].z, handler.shape.vertices[2].z - handler.shape.vertices[0].z, -invRay.dir[2]]
            ]
            vec = [invRay.origin.x - handler.shape.vertices[0].x, invRay.origin.y - handler.shape.vertices[0].y, invRay.origin.z - handler.shape.vertices[0].z]
        
        let solution = try: solve(mat, vec) except ValueError: return false

        if not invRay.tspan.contains(solution[2]): return false
        if solution[0] < 0.0 or solution[1] < 0.0 or solution[0] + solution[1] > 1.0: return false

        return true

    of skSphere: 
        let 
            invRay = ray.transform(handler.transformation.inverse)
            (a, b, c) = (norm2(invRay.dir), dot(invRay.origin.Vec3f, invRay.dir), norm2(invRay.origin.Vec3f) - handler.shape.radius * handler.shape.radius)
            delta_4 = b * b - a * c

        if delta_4 < 0: return false
        return invRay.tspan.contains((-b - sqrt(delta_4)) / a) or invRay.tspan.contains((-b + sqrt(delta_4)) / a)

    of skPlane:
        let invRay = ray.transform(handler.transformation.inverse)
        if abs(invRay.dir[2]) < epsilon(float32): return false
        if invRay.tspan.contains(-invRay.origin.z / invRay.dir[2]): return true
                    
    of skCylinder: 
        let
            invRay = ray.transform(handler.transformation.inverse)
            a = invRay.dir[0] * invRay.dir[0] + invRay.dir[1] * invRay.dir[1]
            b = 2 * (invRay.dir[0] * invRay.origin.x + invRay.dir[1] * invRay.origin.y)
            c = invRay.origin.x * invRay.origin.x + invRay.origin.y * invRay.origin.y - handler.shape.R * handler.shape.R
            delta = b * b - 4.0 * a * c

        if delta < 0.0: return false

        var tspan = newInterval((-b - sqrt(delta)) / (2 * a), (-b + sqrt(delta)) / (2 * a))

        if tspan.min > invRay.tspan.max or tspan.max < invRay.tspan.min: return false

        var t_hit = tspan.min
        if t_hit < invRay.tspan.min:
            if tspan.max > invRay.tspan.max: return false
            t_hit = tspan.max

        var hitPt = invRay.at(t_hit)
        var phi = arctan2(hitPt.y, hitPt.x)
        if phi < 0.0: phi += 2.0 * PI

        if hitPt.z < handler.shape.zSpan.min or hitPt.z > handler.shape.zSpan.max or phi > handler.shape.phiMax:
            if t_hit == tspan.max: return false
            t_hit = tspan.max
            if t_hit > invRay.tspan.max: return false
            
            hitPt = invRay.at(t_hit)
            phi = arctan2(hitPt.y, hitPt.x)
            if phi < 0.0: phi += 2.0 * PI
            if hitPt.z < handler.shape.zSpan.min or hitPt.z > handler.shape.zSpan.max or phi > handler.shape.phiMax: return false

        return true


proc checkIntersection(node: SceneNode, ray: Ray): bool =
    let boxHandler = (shape: newAABox(node.aabb), transformation: IDENTITY)
    if not checkIntersection(boxHandler, ray): return false
    if node.kind == nkLeaf:
        for handler in node.handlers:
            if checkIntersection(handler, ray): return true
        return false

    if (node.left != nil and checkIntersection(node.left, ray)) or 
        (node.right != nil and checkIntersection(node.right, ray)): return true
    

proc getHitLeafs*(node: SceneNode; ray: Ray): Option[seq[SceneNode]] =
    let boxHandler = (shape: newAABox(node.aabb), transformation: IDENTITY)
    if not checkIntersection(boxHandler, ray): return none seq[SceneNode]

    var sceneNodes: seq[SceneNode]
    case node.kind
    of nkLeaf: sceneNodes.add node
    of nkRoot, nkBranch:
        for node in [node.left, node.right]:
            if node != nil:
                let hits = node.getHitLeafs(ray)
                if hits.isSome: sceneNodes = concat(sceneNodes, hits.get)

    some sceneNodes


type HitPayload* = object
    shape*: ptr Shape
    ray*: Ray
    t*: float32
    
proc newHitPayload*(handler: ShapeHandler, ray: Ray): Option[HitPayload] =
    let invRay = ray.transform(handler.transformation.inverse) 

    case handler.shape.kind
    of skAABox:
        let
            xSpan = newInterval((handler.shape.aabb.min.x - invRay.origin.x) / invRay.dir[0], (handler.shape.aabb.max.x - invRay.origin.x) / invRay.dir[0])
            ySpan = newInterval((handler.shape.aabb.min.y - invRay.origin.y) / invRay.dir[1], (handler.shape.aabb.max.y - invRay.origin.y) / invRay.dir[1])

        if xSpan.min > ySpan.max or ySpan.min > xSpan.max: return none HitPayload

        let zSpan = newInterval((handler.shape.aabb.min.z - invRay.origin.z) / invRay.dir[2], (handler.shape.aabb.min.z - invRay.origin.z) / invRay.dir[2])
        
        var (tHitMin, tHitMax) = (max(xSpan.min, ySpan.min), min(xSpan.max, ySpan.max))
        if tHitMin > zSpan.max or zSpan.min > tHitMax: return none HitPayload

        if zSpan.min > tHitMin: tHitMin = zSpan.min
        if zSpan.max < tHitMax: tHitMax = zSpan.max
                
        let tHit = if handler.shape.aabb.contains(invRay.origin): tHitMax else: tHitMin
        if not invRay.tspan.contains(tHit): return none HitPayload

        return some HitPayload(shape: addr handler.shape, ray: invRay, t: tHit)

    of skTriangle:
        let 
            mat = [
                [handler.shape.vertices[1].x - handler.shape.vertices[0].x, handler.shape.vertices[2].x - handler.shape.vertices[0].x, -invRay.dir[0]], 
                [handler.shape.vertices[1].y - handler.shape.vertices[0].y, handler.shape.vertices[2].y - handler.shape.vertices[0].y, -invRay.dir[1]], 
                [handler.shape.vertices[1].z - handler.shape.vertices[0].z, handler.shape.vertices[2].z - handler.shape.vertices[0].z, -invRay.dir[2]]
            ]
            vec = [invRay.origin.x - handler.shape.vertices[0].x, invRay.origin.y - handler.shape.vertices[0].y, invRay.origin.z - handler.shape.vertices[0].z]

        let sol = try: solve(mat, vec) except ValueError: return none HitPayload
        if not invRay.tspan.contains(sol[2]): return none HitPayload
        if sol[0] < 0.0 or sol[1] < 0.0 or sol[0] + sol[1] > 1.0: return none HitPayload

        return some HitPayload(shape: addr handler.shape, ray: invRay, t: sol[2])

    of skSphere:
        let (a, b, c) = (norm2(invRay.dir), dot(invRay.origin.Vec3f, invRay.dir), norm2(invRay.origin.Vec3f) - handler.shape.radius * handler.shape.radius)
        let delta_4 = b * b - a * c
        if delta_4 < 0: return none HitPayload

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        let tHit = if ray.tspan.contains(t_l): t_l elif ray.tspan.contains(t_r): t_r else: return none HitPayload

        return some HitPayload(shape: addr handler.shape, ray: invRay, t: tHit)

    of skPlane:
        if abs(invRay.dir[2]) < epsilon(float32): return none HitPayload
        let tHit = -invRay.origin.z / invRay.dir[2]
        if not ray.tspan.contains(t_hit): return none HitPayload

        return some HitPayload(shape: addr handler.shape, ray: invRay, t: tHit)

    of skCylinder:
        let
            a = invRay.dir[0] * invRay.dir[0] + invRay.dir[1] * invRay.dir[1]
            b = 2 * (invRay.dir[0] * invRay.origin.x + invRay.dir[1] * invRay.origin.y)
            c = invRay.origin.x * invRay.origin.x + invRay.origin.y * invRay.origin.y - handler.shape.R * handler.shape.R
            delta = b * b - 4.0 * a * c

        if delta < 0.0: return none HitPayload

        var tspan = newInterval((-b - sqrt(delta)) / (2 * a), (-b + sqrt(delta)) / (2 * a))

        if tspan.min > invRay.tspan.max or tspan.max < invRay.tspan.min: return none HitPayload

        var tHit = tspan.min
        if tHit < invRay.tspan.min:
            if tspan.max > invRay.tspan.max: return none HitPayload
            tHit = tspan.max

        var hitPt = invRay.at(tHit)
        var phi = arctan2(hitPt.y, hitPt.x)
        if phi < 0.0: phi += 2.0 * PI

        if hitPt.z < handler.shape.zSpan.min or hitPt.z > handler.shape.zSpan.max or phi > handler.shape.phiMax:
            if tHit == tspan.max: return none HitPayload
            tHit = tspan.max
            if tHit > invRay.tspan.max: return none HitPayload
            
            hitPt = invRay.at(tHit)
            phi = arctan2(hitPt.y, hitPt.x)
            if phi < 0.0: phi += 2.0 * PI
            if hitPt.z < handler.shape.zSpan.min or hitPt.z > handler.shape.zSpan.max or phi > handler.shape.phiMax: return none HitPayload

        return some HitPayload(shape: addr handler.shape, ray: invRay, t: tHit)


proc getHitPayloads*(node: SceneNode; ray: Ray): seq[HitPayload] =
    let hitLeafs = node.getHitLeafs(ray)

    if hitLeafs.isNone: return @[]
    hitLeafs.get
        .map(proc(node: SceneNode): Option[HitPayload] = newHitPayload(node.handlers[0], ray))
        .filter(proc(x: Option[HitPayload]): bool = x.isSome)
        .map(proc(hit: Option[HitPayload]): HitPayload = hit.get)


proc newHitRecord*(hitLeafs: seq[SceneNode], ray: Ray): Option[seq[HitPayload]] =
    let hitPayloads = hitLeafs
        .map(proc(node: SceneNode): seq[HitPayload] = node.getHitPayloads(ray))
        .filter(proc(hits: seq[HitPayload]): bool = hits.len > 0)

    if hitPayloads.len == 0: return none seq[HitPayload]
    some hitPayloads.foldl(concat(a, b)).sorted(proc(a, b: HitPayload): int = cmp(a.t, b.t))