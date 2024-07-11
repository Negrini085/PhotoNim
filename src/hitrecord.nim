import geometry, scene, shape

from std/math import pow, sqrt, arctan2, PI
from std/fenv import epsilon
from std/algorithm import upperBound
from std/sequtils import mapIt, insert, filterIt
# from std/strformat import fmt


proc getIntersection(aabb: Interval[Point3D]; worldRay: Ray): float32 {.inline.} =
    let
        (min, max) = (aabb.min - worldRay.origin, aabb.max - worldRay.origin)
        txSpan = newInterval(min[0] / worldRay.dir[0], max[0] / worldRay.dir[0])
        tySpan = newInterval(min[1] / worldRay.dir[1], max[1] / worldRay.dir[1])

    if txSpan.min > tySpan.max or tySpan.min > txSpan.max: return Inf

    let tzSpan = newInterval(min[1] / worldRay.dir[2], max[1] / worldRay.dir[2])
    
    var hitSpan = newInterval(max(txSpan.min, tySpan.min), min(txSpan.max, tySpan.max))
    if hitSpan.min > tzSpan.max or tzSpan.min > hitSpan.max: return Inf

    if tzSpan.min > hitSpan.min: hitSpan.min = tzSpan.min
    if tzSpan.max < hitSpan.max: hitSpan.max = tzSpan.max
                
    result = if aabb.contains(worldRay.origin): hitSpan.max else: hitSpan.min
    if not worldRay.tspan.contains(result): return Inf


type HitInfo[T] = tuple[t: float32, val: T] 

type HitPayload* = ref object
    info*: HitInfo[ObjectHandler]
    pt*: Point3D 
    normal*: Normal
    dir*: Vec3f

proc `<`[T](a, b: HitInfo[T]): bool {.inline.} = b.t < a.t

proc newHitPayload(hit: ObjectHandler, ray: Ray, t: float32): HitPayload {.inline.} =
    let hitPt = ray.at(t)
    HitPayload(info: (t, hit), pt: hitPt, normal: hit.shape.getNormal(hitPt, ray.dir), dir: ray.dir)


proc getLocalIntersection(shape: Shape, worldInvRay: Ray): float32 =

    case shape.kind
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
    result = HitPayload(info: (Inf.float32, nil), pt: ORIGIN3D, normal: newNormal(0, 0, 0), dir: newVec3f(0, 0, 0))

    if tree.root.isNil: return result

    let tRootHit = tree.root.aabb.getIntersection(worldRay)
    if tRootHit == Inf: return result

    var 
        nodesStack = newSeqOfCap[HitInfo[BVHNode]](tree.kind.int * tree.kind.int * tree.kind.int * tree.kind.int)
        handlersStack = newSeqOfCap[HitInfo[ObjectHandler]](tree.mspl)
        currentHitInfo: HitInfo[BVHNode] = (tRootHit, tree.root)

    nodesStack.add currentHitInfo

    while nodesStack.len > 0:
        currentHitInfo = nodesStack.pop

        if currentHitInfo.t >= result.info.t: break
        
        case currentHitInfo.val.kind
        of nkBranch: 
            for child in currentHitInfo.val.children:
                if not child.isNil:
                    let tBoxHit = 
                        # if child.aabb.contains(worldRay.origin): min(child.aabb.getIntersection(worldRay), child.aabb.getIntersection(newRay(worldRay.origin, -worldRay.dir)))
                        # else: 
                        child.aabb.getIntersection(worldRay)

                    if tBoxHit < result.info.t: 
                        let bvhHitInfo = (tBoxHit, child)
                        nodesStack.insert(bvhHitInfo, nodesStack.upperBound(bvhHitInfo))

        of nkLeaf:
            for handler in currentHitInfo.val.indexes.mapIt(handlers[it]):
                if handler.kind == hkPoint: continue

                let tBoxHit = handler.getAABB.getIntersection(worldRay)
                if tBoxHit < result.info.t: 
                    let handlerHit = (tBoxHit, handler)
                    handlersStack.insert(handlerHit, handlersStack.upperBound(handlerHit))
            
            while handlersStack.len > 0:
                let handlerHitInfo = handlersStack.pop
                if handlerHitInfo.t >= result.info.t: break
                
                case handlerHitInfo.val.kind
                of hkShape: 
                    let 
                        invRay = worldRay.transform(handlerHitInfo.val.transformation.inverse)
                        tShapeHit = handlerHitInfo.val.shape.getLocalIntersection(invRay)

                    if tShapeHit < result.info.t: result = handlerHitInfo.val.newHitPayload(invRay, tShapeHit)
                    
                of hkMesh: 
                    let meshHit = handlerHitInfo.val.mesh.tree.getClosestHit(handlerHitInfo.val.mesh.shapes, worldRay)
                    if not meshHit.info.val.isNil and meshHit.info.t < result.info.t: result = meshHit

                of hkPoint: discard
