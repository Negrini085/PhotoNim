import geometry, scene

from std/math import pow, sqrt, arctan2, PI
from std/fenv import epsilon
from std/algorithm import sort, SortOrder, upperBound
from std/sequtils import mapIt, insert, filterIt
# from std/strformat import fmt


proc getIntersection(aabb: Interval[Point3D]; worldRay: Ray): float32 {.inline.} =
    let
        (min, max) = (aabb.min - worldRay.origin, aabb.max - worldRay.origin)
        txSpan = newInterval(min[0] / worldRay.dir[0], max[0] / worldRay.dir[0])
        tySpan = newInterval(min[1] / worldRay.dir[1], max[1] / worldRay.dir[1])

    if txSpan.min > tySpan.max or tySpan.min > txSpan.max: return Inf

    let tzSpan = newInterval(min[2] / worldRay.dir[2], max[2] / worldRay.dir[2])
    
    var hitSpan = newInterval(max(txSpan.min, tySpan.min), min(txSpan.max, tySpan.max))
    if hitSpan.min > tzSpan.max or tzSpan.min > hitSpan.max: return Inf

    if tzSpan.min > hitSpan.min: hitSpan.min = tzSpan.min
    if tzSpan.max < hitSpan.max: hitSpan.max = tzSpan.max
                
    result = if aabb.contains(worldRay.origin): hitSpan.max else: hitSpan.min
    if not worldRay.tspan.contains(result): return Inf


type HitInfo[T] = tuple[hit: T, t: float32] 

type HitPayload* = ref object
    info*: HitInfo[ObjectHandler]
    pt*: Point3D 
    rayDir*: Vec3f

proc newHitPayload(hit: ObjectHandler, ray: Ray, t: float32): HitPayload {.inline.} =
    let hitPt = ray.at(t)
    HitPayload(info: (hit, t), pt: hitPt, rayDir: ray.dir)


proc getLocalIntersection(shape: Shape, worldInvRay: Ray): float32 =
    case shape.kind
    of skPoint: discard
    of skAABox:
        let
            (min, max) = (shape.aabb.min - worldInvRay.origin, shape.aabb.max - worldInvRay.origin)
            txSpan = newInterval(min[0] / worldInvRay.dir[0], max[0] / worldInvRay.dir[0])
            tySpan = newInterval(min[1] / worldInvRay.dir[1], max[1] / worldInvRay.dir[1])

        if txSpan.min > tySpan.max or tySpan.min > txSpan.max: return Inf

        let tzSpan = newInterval(min[2] / worldInvRay.dir[2], max[2] / worldInvRay.dir[2])
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


proc getClosestHit*(tree: BVHTree, handlers: seq[ObjectHandler], worldRay: Ray): HitPayload =
    result = HitPayload(info: (nil, Inf.float32), pt: worldRay.origin, rayDir: worldRay.dir)

    let tRootHit = tree.root.aabb.getIntersection(worldRay)
    if tRootHit == Inf: return result

    var 
        currentNodeHitInfo: HitInfo[BVHNode] = (tree.root, tRootHit)
        nodesStack = @[currentNodeHitInfo] 

        handlersStack = newSeqOfCap[HitInfo[ObjectHandler]](tree.mspl)

    while nodesStack.len > 0:
        currentNodeHitInfo = nodesStack.pop
        # if currentNodeHitInfo.t >= result.info.t: break
        
        case currentNodeHitInfo.hit.kind
        of nkBranch: 
            for child in currentNodeHitInfo.hit.children:
                # if not child.isNil and not child.aabb.contains(worldRay.origin):
                if not child.isNil:
                    let tBoxHit = child.aabb.getIntersection(worldRay)
                    if tBoxHit < result.info.t: nodesStack.add((child, tBoxHit))
            
            nodesStack.sort(proc(a, b: HitInfo[BVHNode]): int = cmp(a.t, b.t), SortOrder.Descending)

        of nkLeaf:
            for handler in currentNodeHitInfo.hit.indexes.mapIt(handlers[it]):
                if handler.brdf.isNil: continue
                let tBoxHit = handler.getAABB.getIntersection(worldRay)
                if tBoxHit < result.info.t: handlersStack.add((handler, tBoxHit))
            
            handlersStack.sort(proc(a, b: HitInfo[ObjectHandler]): int = cmp(a.t, b.t), SortOrder.Descending)

            while handlersStack.len > 0:
                let handlerHitInfo = handlersStack.pop
                if handlerHitInfo.t >= result.info.t: break
                
                case handlerHitInfo.hit.kind
                of hkShape: 
                    let 
                        invRay = worldRay.transform(handlerHitInfo.hit.transformation.inverse)
                        tShapeHit = handlerHitInfo.hit.shape.getLocalIntersection(invRay)

                    if tShapeHit < result.info.t: result = handlerHitInfo.hit.newHitPayload(invRay, tShapeHit)
                    
                of hkMesh:
                    let meshHit = handlerHitInfo.hit.mesh.tree.getClosestHit(handlerHitInfo.hit.mesh.shapes, worldRay)
                    if not meshHit.info.hit.isNil and meshHit.info.t < result.info.t: result = meshHit