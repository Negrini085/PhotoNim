import geometry, scene, ray

from std/algorithm import sort, sorted, SortOrder
from std/sequtils import concat, mapIt, filterIt, keepItIf


type 
    HitInfo[T] = tuple[hit: T, t: float32] 

    HitPayload* = ref object
        info*: HitInfo[ObjectHandler]
        pt*: Point3D 
        rayDir*: Vec3


proc newHitInfo(hit: BVHNode, ray: Ray): HitInfo[BVHNode] {.inline.} = (hit, ray.getBoxHit(hit.aabb))
proc newHitInfo(hit: ObjectHandler, ray: Ray): HitInfo[ObjectHandler] {.inline.} = (hit, ray.getBoxHit(hit.aabb))

proc `<`[T](a, b: HitInfo[T]): bool {.inline.} = a.t < b.t


proc newHitPayload(hit: ObjectHandler, ray: Ray, t: float32): HitPayload {.inline.} =
    HitPayload(info: (hit, t), pt: ray.at(t), rayDir: ray.dir)


proc splitted[T](inSeq: seq[T], condition: proc(t: T): bool): (seq[T], seq[T]) =
    for element in inSeq:
        if condition(element): result[0].add element
        else: result[1].add element


proc getClosestHit*(tree: BVHTree, worldRay: Ray): HitPayload =
    result = HitPayload(info: (nil, Inf.float32), pt: worldRay.origin, rayDir: worldRay.dir)

    let tRootHit = worldRay.getBoxHit(tree.root.aabb)
    if tRootHit == Inf: return result

    var nodesHitStack = newSeqOfCap[HitInfo[BVHNode]](tree.kind.int * tree.kind.int * tree.kind.int)
    nodesHitStack.add (tree.root, tRootHit) 


    proc updateClosestHit(tCurrentHit: float32, handler: ObjectHandler, worldRay: Ray): HitPayload =
        let invRay = worldRay.transform(handler.transformation.inverse) 

        case handler.kind
        of hkShape: 
            let tShapeHit = invRay.getShapeHit(handler.shape)
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
                    updatedHit = updateClosestHit(result.info.t, currentHandlerInfo.hit, worldRay)
                
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
                        updatedHit = updateClosestHit(result.info.t, currentHandlerInfo.hit, worldRay)
                    
                    if not updatedHit.isNil: 
                        result = updatedHit
                        handlersHitStack.keepItIf(it.t < result.info.t)

                nodesHitStack.add branchesToVisit
                    .sorted(SortOrder.Descending)
                    .mapIt((hit: it.hit, t: -1.0.float32))

            nodesHitStack.add secondNodesToVisit.filterIt(it.t < result.info.t)


        nodesHitStack.keepItIf(it.t < result.info.t)
        nodesHitStack.sort(SortOrder.Descending)