import geometry, scene

from std/math import pow, sqrt, arctan2, PI
from std/fenv import epsilon
from std/algorithm import sort, sorted, SortOrder
from std/sequtils import concat, mapIt, filterIt, keepItIf


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


proc newHitInfo(hit: BVHNode, ray: Ray): HitInfo[BVHNode] {.inline.} = (hit, hit.aabb.getIntersection(ray))
proc newHitInfo(hit: ObjectHandler, ray: Ray): HitInfo[ObjectHandler] {.inline.} = (hit, hit.aabb.getIntersection(ray))

proc `<`[T](a, b: HitInfo[T]): bool {.inline.} = a.t < b.t


proc newHitPayload(hit: ObjectHandler, ray: Ray, t: float32): HitPayload {.inline.} =
    let hitPt = ray.at(t)
    HitPayload(info: (hit, t), pt: hitPt, rayDir: ray.dir)


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


proc splitted[T](inSeq: seq[T], condition: proc(t: T): bool): (seq[T], seq[T]) =
    for element in inSeq:
        if condition(element): result[0].add element
        else: result[1].add element


proc getClosestHit*(tree: BVHTree, worldRay: Ray): HitPayload =
    result = HitPayload(info: (nil, Inf.float32), pt: worldRay.origin, rayDir: worldRay.dir)

    let tRootHit = tree.root.aabb.getIntersection(worldRay)
    if tRootHit == Inf: return result

    var nodesHitStack = newSeqOfCap[HitInfo[BVHNode]](tree.kind.int * tree.kind.int * tree.kind.int)
    nodesHitStack.add (tree.root, tRootHit) 


    proc updateClosestHit(tCurrentHit: float32, handler: ObjectHandler, invRay: Ray): HitPayload =
        case handler.kind
        of hkShape: 
            let tShapeHit = handler.shape.getLocalIntersection(invRay)
            return if tShapeHit >= tCurrentHit: nil else: newHitPayload(handler, invRay, tShapeHit)
            
        of hkMesh:
            let meshHit = handler.mesh.getClosestHit(invRay)
            if meshHit.info.hit.isNil or meshHit.info.t >= tCurrentHit: return nil
            result = meshHit; result.pt = apply(handler.transformation, meshHit.pt)


    while nodesHitStack.len > 0:
        var handlersHitStack = newSeqOfCap[HitInfo[ObjectHandler]](tree.mspl)
    
        let currentNodeHitInfo = nodesHitStack.pop    
        case currentNodeHitInfo.hit.kind
        of nkLeaf:

            let (firstHandlersToVisit, secondHandlersToVisit) = currentNodeHitInfo.hit.indexes
                .mapIt(newHitInfo(tree.handlers[it], worldRay))
                .splitted(proc(info: HitInfo[ObjectHandler]): bool = info.hit.aabb.contains(worldRay.origin))

            handlersHitStack.add secondHandlersToVisit.filterIt(it.t < result.info.t).sorted(SortOrder.Descending)
            handlersHitStack.add firstHandlersToVisit.sorted(SortOrder.Descending)

            while handlersHitStack.len > 0:
                let 
                    currentHandlerInfo = handlersHitStack.pop  
                    invRay = worldRay.transform(currentHandlerInfo.hit.transformation.inverse) 
                    updatedHit = updateClosestHit(result.info.t, currentHandlerInfo.hit, invRay)
                
                if not updatedHit.isNil: 
                    result = updatedHit
                    handlersHitStack.keepItIf(it.t < result.info.t)

        of nkBranch: 

            let (firstNodesToVisit, secondNodesToVisit) = currentNodeHitInfo.hit.children
                .filterIt(not it.isNil)
                .mapIt(newHitInfo(it, worldRay))
                .splitted(proc(info: HitInfo[BVHNode]): bool = info.hit.aabb.contains(worldRay.origin))

            if firstNodesToVisit.len > 0:
                let (leafsToVisit, branchesToVisit) = 
                    firstNodesToVisit.splitted(proc(node: HitInfo[BVHNode]): bool = node.hit.kind == nkLeaf)
                
                handlersHitStack.add leafsToVisit
                    .mapIt(it.hit.indexes).concat
                    .mapIt(newHitInfo(tree.handlers[it], worldRay))
                    .filterIt(it.t < result.info.t)

                handlersHitStack.sort(SortOrder.Descending)
                while handlersHitStack.len > 0:
                    let 
                        currentHandlerInfo = handlersHitStack.pop
                        invRay = worldRay.transform(currentHandlerInfo.hit.transformation.inverse) 
                        updatedHit = updateClosestHit(result.info.t, currentHandlerInfo.hit, invRay)
                    
                    if not updatedHit.isNil: 
                        result = updatedHit
                        handlersHitStack.keepItIf(it.t < result.info.t)

                nodesHitStack.add branchesToVisit
                    .sorted(SortOrder.Descending)
                    .mapIt((hit: it.hit, t: -1.0.float32))

            nodesHitStack.add secondNodesToVisit.filterIt(it.t < result.info.t)


        nodesHitStack.keepItIf(it.t < result.info.t)
        nodesHitStack.sort(SortOrder.Descending)