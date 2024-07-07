import geometry, scene, bvh

from std/math import sqrt, arctan2, PI
from std/fenv import epsilon
from std/algorithm import sort, SortOrder
from std/sugar import collect


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
                
    result = if aabb.contains(ray.origin): hitSpan.max else: hitSpan.min
    if not ray.tspan.contains(result): return Inf


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

        result = if shape.aabb.contains(worldInvRay.origin): hitSpan.max else: hitSpan.min
        if not worldInvRay.tspan.contains(result): return Inf


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

        result = sol[2]

    of skSphere:
        let 
            (a, b, c) = (norm2(worldInvRay.dir), dot(worldInvRay.origin.Vec3f, worldInvRay.dir), norm2(worldInvRay.origin.Vec3f) - shape.radius * shape.radius)
            delta_4 = b * b - a * c
        
        if delta_4 < 0: return Inf

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        
        result = 
            if worldInvRay.tspan.contains(t_l): t_l 
            elif worldInvRay.tspan.contains(t_r): t_r 
            else: Inf

    of skPlane:
        if abs(worldInvRay.dir[2]) < epsilon(float32): return Inf
        result = -worldInvRay.origin.z / worldInvRay.dir[2]
        if not worldInvRay.tspan.contains(result): return Inf

    of skCylinder:
        let
            a = worldInvRay.dir[0] * worldInvRay.dir[0] + worldInvRay.dir[1] * worldInvRay.dir[1]
            b = 2 * (worldInvRay.dir[0] * worldInvRay.origin.x + worldInvRay.dir[1] * worldInvRay.origin.y)
            c = worldInvRay.origin.x * worldInvRay.origin.x + worldInvRay.origin.y * worldInvRay.origin.y - shape.R * shape.R
            delta = b * b - 4.0 * a * c

        if delta < 0.0: return Inf

        var tspan = newInterval((-b - sqrt(delta)) / (2 * a), (-b + sqrt(delta)) / (2 * a))

        if tspan.min > worldInvRay.tspan.max or tspan.max < worldInvRay.tspan.min: return Inf

        result = tspan.min
        if result < worldInvRay.tspan.min:
            if tspan.max > worldInvRay.tspan.max: return Inf
            result = tspan.max

        var hitPt = worldInvRay.at(result)
        var phi = arctan2(hitPt.y, hitPt.x)
        if phi < 0.0: phi += 2.0 * PI

        if hitPt.z < shape.zSpan.min or hitPt.z > shape.zSpan.max or phi > shape.phiMax:
            if result == tspan.max: return Inf
            result = tspan.max
            if result > worldInvRay.tspan.max: return Inf
            
            hitPt = worldInvRay.at(result)
            phi = arctan2(hitPt.y, hitPt.x)
            if phi < 0.0: phi += 2.0 * PI
            if hitPt.z < shape.zSpan.min or hitPt.z > shape.zSpan.max or phi > shape.phiMax: return Inf


type HitInfo[T] = tuple[hit: T, t: float32]

proc getClosestHit*(root: BVHNode, worldRay: Ray): HitInfo[ObjectHandler] =
    result = (nil, Inf.float32)
    if root.isNil: return result

    var nodeStack: seq[HitInfo[BVHNode]] = @[(root, root.aabb.getIntersection(worldRay))]
    while nodeStack.len > 0:

        let currentBVH = nodeStack.pop
        if currentBVH.t > result.t + 1e3: break

        case currentBVH.hit.kind
        of nkBranch: 
            let nodesHitInfos = collect:
                for node in currentBVH.hit.children:
                    if not node.isNil:
                        let tBoxHit = node.aabb.getIntersection(worldRay)
                        if tBoxHit < Inf: (node, tBoxHit)

            if nodesHitInfos.len > 0:             
                nodeStack.add nodesHitInfos
                nodeStack.sort(proc(a, b: HitInfo[BVHNode]): int = cmp(a.t, b.t), SortOrder.Descending)

        of nkLeaf:
            var handlersHitInfos = collect:
                for handler in currentBVH.hit.handlers:
                    let tBoxHit = handler.getAABB.getIntersection(worldRay)
                    if tBoxHit < Inf: (handler, tBoxHit)
            
            handlersHitInfos.sort(proc(a, b: HitInfo[ObjectHandler]): int = cmp(a.t, b.t), SortOrder.Ascending)

            for (handler, tBoxHit) in handlersHitInfos:
                if tBoxHit > result.t + 1e3: break
                
                case handler.kind
                of hkShape: 
                    let tShapeHit = handler.shape.getLocalIntersection(worldRay.transform(handler.transformation.inverse))
                    if tShapeHit < result.t: result = (handler, tShapeHit)
                    
                of hkMesh:
                    let meshHit = handler.mesh.tree.getClosestHit(worldRay)
                    if meshHit.hit.isNil: continue
                    elif meshHit.t < result.t: result = meshHit