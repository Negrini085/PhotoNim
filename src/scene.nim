import pcg, geometry, color, pigment, brdf

from std/sequtils import newSeqWith, toSeq, mapIt, keepItIf


type    
    Scene* = object 
        bgColor*: Color
        tree*: BVHTree


    TreeKind* = enum 
        tkBinary = 2, tkTernary = 3, tkQuaternary = 4, tkOctonary = 8

    BVHTree* = object 
        kind*: TreeKind 
        mspl*: int 
        root*: BVHNode 
        handlers*: seq[ObjectHandler]


    NodeKind* = enum nkBranch, nkLeaf
    BVHNode* = ref object
        aabb*: Interval[Point3D]
        
        case kind*: NodeKind
        of nkBranch: children*: seq[BVHNode]
        of nkLeaf: indexes*: seq[int]


    HandlerKind* = enum hkShape, hkMesh, hkCSG
    ObjectHandler* = ref object
        aabb*: Interval[Point3D] 
        transformation*: Transformation

        case kind*: HandlerKind
        of hkShape: 
            shape*: Shape 
            material*: tuple[brdf: BRDF, eRadiance: Pigment]

        of hkMesh: mesh*: BVHTree
        of hkCSG: csg*: CSG
    
    ShapeKind* = enum skPlane, skSphere, skAABox, skTriangle, skCylinder, skEllipsoid
    Shape* = object
        case kind*: ShapeKind 
        of skPlane: discard
        of skSphere: radius*: float32
        of skAABox: aabb*: Interval[Point3D]
        of skTriangle: vertices*: seq[Point3D]
        of skCylinder:
            R*, phiMax*: float32
            zSpan*: Interval[float32]

        of skEllipsoid: axis*: tuple[a, b, c: float32]

    CSGKind* = enum csgkUnion
    CSG* = object
        case kind*: CSGKind
        of csgkUnion:
            tree*: BVHTree


proc nearestCentroid(point: Point3D, clusterCentroids: seq[Point3D]): tuple[index: int, dist2: float32] =   
    result = (index: 0, dist2: Inf.float32)

    var tmp: float32
    for i, center in clusterCentroids.pairs:
        tmp = dist2(center, point)
        if result.dist2 > tmp: result = (i, tmp)


proc updateCentroids(data: seq[Point3D], clusters: seq[int], k: int): seq[Point3D] =
    result = newSeq[Point3D](k)

    var 
        tmp = newSeq[Vec3](k)
        counts = newSeq[int](k)
    for i, point in data.pairs: tmp[clusters[i]] += Vec3(point); counts[clusters[i]] += 1
    for i in 0..<k: result[i] = if counts[i] > 0: Point3D(tmp[i] / counts[i]) else: Point3D(tmp[i])


proc kMeansPlusPlusInit(data: seq[Point3D], k: int, rg: var PCG): seq[Point3D] =
    result = newSeq[Point3D](k)
    result[0] = data[rg.rand(0.float32, data.len.float32 - 1).int]

    var distances = newSeq[float32](data.len)
    for i in 1..<k:
        var totalDist: float32
        for j, point in data.pairs:
            distances[j] = nearestCentroid(point, result[0..<i]).dist2
            totalDist += distances[j]

        let target = rg.rand(0.0, totalDist)
        var cumulativeDist: float32
        for j, dist in distances.pairs:
            cumulativeDist += dist
            if cumulativeDist >= target: result[i] = data[j]; break


proc kMeans(data: seq[Point3D], k: int, rg: var PCG): seq[int] =
    if data.len == k: return countup(0, k - 1).toSeq

    result = newSeq[int](data.len)

    var 
        centroids = kMeansPlusPlusInit(data, k, rg)
        tmpCentroids = newSeq[Point3D](k)
        converged = false

    while not converged:
        result = data.mapIt(it.nearestCentroid(centroids).index)
        tmpCentroids = updateCentroids(data, result, k)
        converged = true
        for i in 0..<k:
            if not areClose(centroids[i], tmpCentroids[i], 1.0e-3):
                converged = false
                break

        centroids = tmpCentroids


proc newBVHNode*(handlers: seq[tuple[key: int, val: ObjectHandler]], kClusters, maxShapesPerLeaf: int, rgSetUp: RandomSetUp): BVHNode =
    if handlers.len == 0: return nil

    let handlersAABBs = handlers.mapIt(it.val.aabb)
    
    if handlers.len <= maxShapesPerLeaf:
        return BVHNode(kind: nkLeaf, aabb: handlersAABBs.getTotalAABB, indexes: handlers.mapIt(it.key))
    
    var 
        rg = newPCG(rgSetUp)
        clusters = newSeqWith[seq[int]](kClusters, newSeqOfCap[int](handlers.len div kClusters))

    for handlerIdx, clusterIdx in kMeans(handlersAABBs.mapIt(it.getCentroid), kClusters, rg).pairs: 
        clusters[clusterIdx].add handlerIdx

    clusters.keepItIf(it.len > 0)
    
    BVHNode(
        kind: nkBranch, 
        aabb: handlersAABBs.getTotalAABB,
        children: clusters.mapIt(
            newBVHNode(
                it.mapIt(handlers[it]), 
                kClusters, maxShapesPerLeaf, 
                newRandomSetUp(rg.random, rg.random)
            )
        )      
    )


proc newBVHTree*(handlers: seq[ObjectHandler], treeKind: TreeKind, maxShapesPerLeaf: int, rgSetUp: RandomSetUp): BVHTree {.inline.} =
    BVHTree(
        kind: treeKind, 
        mspl: maxShapesPerLeaf, 
        root: newBVHNode(handlers.pairs.toSeq, treeKind.int, maxShapesPerLeaf, rgSetUp), 
        handlers: handlers
    )

proc newScene*(bgColor: Color, handlers: seq[ObjectHandler], treeKind: TreeKind, maxShapesPerLeaf: int, rgSetUp: RandomSetUp): Scene {.inline.} =
    assert handlers.len > 0, "Error! Cannot create a Scene from an empty sequence of ObjectHandlers."
    Scene(bgColor: bgColor, tree: newBVHTree(handlers, treeKind, maxShapesPerLeaf, rgSetUp))