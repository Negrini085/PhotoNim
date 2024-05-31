import geometry, scene, camera

import std/options
from std/fenv import epsilon
from std/math import sqrt, arctan2, PI
from std/sequtils import concat, map, foldl, filter
from std/algorithm import sorted


proc intersect*(ray: Ray; shape: Shape): bool =
    case shape.kind
    of skAABox:
        let invRay = ray.transform(shape.transform.inverse)
        let (min, max) = (shape.aabb.min - invRay.origin, shape.aabb.max - invRay.origin)
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
            invRay = ray.transform(shape.transform.inverse)
            mat = [
                [shape.vertices[1].x - shape.vertices[0].x, shape.vertices[2].x - shape.vertices[0].x, -invRay.dir[0]], 
                [shape.vertices[1].y - shape.vertices[0].y, shape.vertices[2].y - shape.vertices[0].y, -invRay.dir[1]], 
                [shape.vertices[1].z - shape.vertices[0].z, shape.vertices[2].z - shape.vertices[0].z, -invRay.dir[2]]
            ]
            vec = [invRay.origin.x - shape.vertices[0].x, invRay.origin.y - shape.vertices[0].y, invRay.origin.z - shape.vertices[0].z]
        
        let solution = try: solve(mat, vec) except ValueError: return false

        if not invRay.tspan.contains(solution[2]): return false
        if solution[0] < 0.0 or solution[1] < 0.0 or solution[0] + solution[1] > 1.0: return false

        return true

    of skSphere: 
        let 
            invRay = ray.transform(shape.transform.inverse)
            (a, b, c) = (norm2(invRay.dir), dot(invRay.origin.Vec3f, invRay.dir), norm2(invRay.origin.Vec3f) - shape.radius * shape.radius)
            delta_4 = b * b - a * c

        if delta_4 < 0: return false
        return invRay.tspan.contains((-b - sqrt(delta_4)) / a) or invRay.tspan.contains((-b + sqrt(delta_4)) / a)

    of skPlane:
        let invRay = ray.transform(shape.transform.inverse)
        if abs(invRay.dir[2]) < epsilon(float32): return false
        if invRay.tspan.contains(-invRay.origin.z / invRay.dir[2]): return true
                    
    of skCylinder: 
        let
            invRay = ray.transform(shape.transform.inverse)
            a = invRay.dir[0] * invRay.dir[0] + invRay.dir[1] * invRay.dir[1]
            b = 2 * (invRay.dir[0] * invRay.origin.x + invRay.dir[1] * invRay.origin.y)
            c = invRay.origin.x * invRay.origin.x + invRay.origin.y * invRay.origin.y - shape.R * shape.R
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

        if hitPt.z < shape.zMin or hitPt.z > shape.zMax or phi > shape.phiMax:
            if t_hit == tspan.max: return false
            t_hit = tspan.max
            if t_hit > invRay.tspan.max: return false
            
            hitPt = invRay.at(t_hit)
            phi = arctan2(hitPt.y, hitPt.x)
            if phi < 0.0: phi += 2.0 * PI
            if hitPt.z < shape.zMin or hitPt.z > shape.zMax or phi > shape.phiMax: return false

        return true


proc intersect*(ray: Ray; node: SceneNode): bool =
    if not ray.intersect(newAABox(node.aabb)): return false
    if node.kind == nkLeaf:
        for shape in node.shapes:
            if ray.intersect(shape): return true
        return false

    if (node.left != nil and ray.intersect(node.left)) or (node.right != nil and ray.intersect(node.right)): return true
    

proc getHitLeafNodes*(node: SceneNode; ray: Ray): Option[seq[SceneNode]] =
    if not ray.intersect(newAABox(node.aabb)): return none seq[SceneNode]
    var sceneNodes: seq[SceneNode]
    case node.kind
    of nkLeaf: sceneNodes.add node

    of nkRoot:
        if node.left != nil:
            let hit = node.left.getHitLeafNodes(ray)
            if hit.isSome: sceneNodes = concat(sceneNodes, hit.get)

        if node.right != nil:
            let hit = node.right.getHitLeafNodes(ray)
            if hit.isSome: sceneNodes = concat(sceneNodes, hit.get)

    some sceneNodes


type HitPayload* = object
    shape*: ptr Shape
    ray*: Ray
    t*: float32
    
    
proc newHitPayload*(shape: Shape, ray: Ray): Option[HitPayload] =
    let invRay = ray.transform(shape.transform.inverse) 

    case shape.kind
    of skAABox:
        let
            xSpan = newInterval((shape.aabb.min.x - invRay.origin.x) / invRay.dir[0], (shape.aabb.max.x - invRay.origin.x) / invRay.dir[0])
            ySpan = newInterval((shape.aabb.min.y - invRay.origin.y) / invRay.dir[1], (shape.aabb.max.y - invRay.origin.y) / invRay.dir[1])

        if xSpan.min > ySpan.max or ySpan.min > xSpan.max: return none HitPayload

        let zSpan = newInterval((shape.aabb.min.z - invRay.origin.z) / invRay.dir[2], (shape.aabb.min.z - invRay.origin.z) / invRay.dir[2])
        
        var (tHitMin, tHitMax) = (max(xSpan.min, ySpan.min), min(xSpan.max, ySpan.max))
        if tHitMin > zSpan.max or zSpan.min > tHitMax: return none HitPayload

        if zSpan.min > tHitMin: tHitMin = zSpan.min
        if zSpan.max < tHitMax: tHitMax = zSpan.max
                
        let tHit = if shape.aabb.contains(invRay.origin): tHitMax else: tHitMin
        if not invRay.tspan.contains(tHit): return none HitPayload

        return some HitPayload(shape: addr shape, ray: invRay, t: tHit)

    of skTriangle:
        let 
            mat = [
                [shape.vertices[1].x - shape.vertices[0].x, shape.vertices[2].x - shape.vertices[0].x, -invRay.dir[0]], 
                [shape.vertices[1].y - shape.vertices[0].y, shape.vertices[2].y - shape.vertices[0].y, -invRay.dir[1]], 
                [shape.vertices[1].z - shape.vertices[0].z, shape.vertices[2].z - shape.vertices[0].z, -invRay.dir[2]]
            ]
            vec = [invRay.origin.x - shape.vertices[0].x, invRay.origin.y - shape.vertices[0].y, invRay.origin.z - shape.vertices[0].z]

        let sol = try: solve(mat, vec) except ValueError: return none HitPayload
        if not invRay.tspan.contains(sol[2]): return none HitPayload
        if sol[0] < 0.0 or sol[1] < 0.0 or sol[0] + sol[1] > 1.0: return none HitPayload

        return some HitPayload(shape: addr shape, ray: invRay, t: sol[2])

    of skSphere:
        let (a, b, c) = (norm2(invRay.dir), dot(invRay.origin.Vec3f, invRay.dir), norm2(invRay.origin.Vec3f) - shape.radius * shape.radius)
        let delta_4 = b * b - a * c
        if delta_4 < 0: return none HitPayload

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        let tHit = if ray.tspan.contains(t_l): t_l elif ray.tspan.contains(t_r): t_r else: return none HitPayload

        return some HitPayload(shape: addr shape, ray: invRay, t: tHit)

    of skPlane:
        if abs(invRay.dir[2]) < epsilon(float32): return none HitPayload
        let tHit = -invRay.origin.z / invRay.dir[2]
        if not ray.tspan.contains(t_hit): return none HitPayload

        return some HitPayload(shape: addr shape, ray: invRay, t: tHit)

    of skCylinder:
        let
            a = invRay.dir[0] * invRay.dir[0] + invRay.dir[1] * invRay.dir[1]
            b = 2 * (invRay.dir[0] * invRay.origin.x + invRay.dir[1] * invRay.origin.y)
            c = invRay.origin.x * invRay.origin.x + invRay.origin.y * invRay.origin.y - shape.R * shape.R
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

        if hitPt.z < shape.zMin or hitPt.z > shape.zMax or phi > shape.phiMax:
            if tHit == tspan.max: return none HitPayload
            tHit = tspan.max
            if tHit > invRay.tspan.max: return none HitPayload
            
            hitPt = invRay.at(tHit)
            phi = arctan2(hitPt.y, hitPt.x)
            if phi < 0.0: phi += 2.0 * PI
            if hitPt.z < shape.zMin or hitPt.z > shape.zMax or phi > shape.phiMax: return none HitPayload

        return some HitPayload(shape: addr shape, ray: invRay, t: tHit)


proc getHitPayloads(nodes: seq[SceneNode], ray: Ray): seq[HitPayload] = discard
    nodes
        .map(proc(node: SceneNode): SceneTree = newSceneTree(node.shapes, IDENTITY, 1))
        .map(proc(tree: SceneTree): seq[SceneNode] = tree.root.getHitLeafNodes(ray).get).foldl(concat(a, b))
        .map(proc(node: SceneNode): Option[HitPayload] = newHitPayload(node.shapes[0], ray))
        .filter(proc(x: Option[HitPayload]): bool = x.isSome)
        .map(proc(hit: Option[HitPayload]): HitPayload = hit.get)


proc newHitRecord*(scene: ptr Scene, ray: Ray): Option[seq[HitPayload]] =
    var hitNodes = newSceneTree(scene, newTranslation(ray.origin.Vec3f), 4).root.getHitLeafNodes(ray)
    if hitNodes.isNone: return none seq[HitPayload]
    let hitPayloads = hitNodes.get.getHitPayloads(ray)
    if hitPayloads.len == 0: return none seq[HitPayload]
    some hitPayloads.sorted(proc(a, b: HitPayload): int = cmp(a.t, b.t))       


proc allHitTimes*(shape: Shape, ray: Ray): Option[seq[float32]] =
    let invRay = if shape.transform.kind != tkIdentity: ray.transform(shape.transform.inverse) else: ray

    case shape.kind
    of skTriangle: discard

    of skAABox: discard

    of skSphere:
        let (a, b, c) = (norm2(invRay.dir), dot(invRay.origin.Vec3f, invRay.dir), norm2(invRay.origin.Vec3f) - 1)
        let delta_4 = b * b - a * c
        if delta_4 < 0: return none(seq[float32])

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        if t_l > ray.tspan.min and t_l < ray.tspan.max and t_r > ray.tspan.min and t_r < ray.tspan.max: return some(@[t_l, t_r])
        elif t_l > ray.tspan.min and t_l < ray.tspan.max: return some(@[t_l])
        elif t_r > ray.tspan.min and t_r < ray.tspan.max: return some(@[t_r])
        
        return none(seq[float32])

    of skPlane:
        if abs(invRay.dir[2]) < epsilon(float32): return none(seq[float32])
        let t_hit = -invRay.origin.z / invRay.dir[2]
        if t_hit < ray.tspan.min or t_hit > ray.tspan.max: return none(seq[float32])

        return some(@[t_hit, Inf])

    of skCylinder: discard