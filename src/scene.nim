import geometry, pcg, hdrimage, pigment, brdf

from std/sequtils import newSeqWith, toSeq, filterIt, map, mapIt


type    
    Scene* = ref object 
        bgColor*: Color
        tree*: BVHTree


    TreeKind* = enum tkBinary = 2, tkTernary = 3, tkQuaternary = 4, tkOctonary = 8
    BVHTree* = tuple[kind: TreeKind, mspl: int, root: BVHNode, handlers: seq[ObjectHandler]]


    NodeKind* = enum nkBranch, nkLeaf
    BVHNode* = ref object
        aabb*: Interval[Point3D]
        
        case kind*: NodeKind
        of nkBranch: children*: seq[BVHNode]
        of nkLeaf: indexes*: seq[int]


    HandlerKind* = enum hkShape, hkMesh
    ObjectHandler* = ref object
        emittedRadiance*: Pigment
        brdf*: BRDF
        
        transformation*: Transformation

        case kind*: HandlerKind
        of hkShape: 
            aabb*: Interval[Point3D] 
            shape*: Shape 

        of hkMesh: mesh*: BVHTree


    ShapeKind* = enum skPlane, skSphere, skAABox, skTriangle, skCylinder
    Shape* = object
        case kind*: ShapeKind 
        of skPlane: discard
        of skSphere: radius*: float32
        of skAABox: aabb*: Interval[Point3D]
        of skTriangle: vertices*: seq[Point3D]            
        of skCylinder:
            R*, phiMax*: float32
            zSpan*: Interval[float32]


proc newAABB*(points: seq[Point3D]): Interval[Point3D] =
    if points.len == 1: return (points[0], points[0])

    let 
        x = points.mapIt(it.x) 
        y = points.mapIt(it.y)
        z = points.mapIt(it.z)

    (newPoint3D(x.min, y.min, z.min), newPoint3D(x.max, y.max, z.max))


proc getTotalAABB*(boxes: seq[Interval[Point3D]]): Interval[Point3D] =
    if boxes.len == 0: return (newPoint3D(Inf, Inf, Inf), newPoint3D(-Inf, -Inf, -Inf))
    elif boxes.len == 1: return boxes[0]

    let
        (minX, maxX) = (boxes.mapIt(it.min.x).min, boxes.mapIt(it.max.x).max)
        (minY, maxY) = (boxes.mapIt(it.min.y).min, boxes.mapIt(it.max.y).max)
        (minZ, maxZ) = (boxes.mapIt(it.min.z).min, boxes.mapIt(it.max.z).max)

    (newPoint3D(minX, minY, minZ), newPoint3D(maxX, maxY, maxZ))


proc getCentroid*(aabb: Interval[Point3D]): Vec3f {.inline.} =
    newVec3f((aabb.min.x + aabb.max.x) / 2.0, (aabb.min.y + aabb.max.y) / 2.0, (aabb.min.z + aabb.max.z) / 2.0)


proc getVertices*(aabb: Interval[Point3D]): seq[Point3D] {.inline.} =
    result = newSeqOfCap[Point3D](8)
    result.add aabb.min; result.add aabb.max
    result.add newPoint3D(aabb.min.x, aabb.min.y, aabb.max.z)
    result.add newPoint3D(aabb.min.x, aabb.max.y, aabb.min.z)
    result.add newPoint3D(aabb.min.x, aabb.max.y, aabb.max.z)
    result.add newPoint3D(aabb.max.x, aabb.min.y, aabb.min.z)
    result.add newPoint3D(aabb.max.x, aabb.min.y, aabb.max.z)
    result.add newPoint3D(aabb.max.x, aabb.max.y, aabb.min.z)


proc getAABB*(handler: ObjectHandler): Interval[Point3D] {.inline.} =
    case handler.kind
    of hkShape: handler.aabb
    of hkMesh: handler.mesh.root.aabb


proc nearestCentroid(point: Vec3f, clusterCentroids: seq[Vec3f]): tuple[index: int, sqDist: float32] =   
    result = (index: 0, sqDist: Inf.float32)

    var tmp: float32
    for i, center in clusterCentroids.pairs:
        tmp = dist2(center, point)
        if result.sqDist > tmp: result = (i, tmp)


proc updateCentroids(data: seq[Vec3f], clusters: seq[int], k: int): seq[Vec3f] =
    result = newSeq[Vec3f](k)

    var counts = newSeq[int](k)
    for i, point in data.pairs: 
        result[clusters[i]] += point; counts[clusters[i]] += 1

    for i in 0..<k:
        if counts[i] > 0: result[i] /= counts[i].float32


proc kMeansPlusPlusInit(data: seq[Vec3f], k: int, rg: var PCG): seq[Vec3f] =
    result = newSeq[Vec3f](k)
    result[0] = data[rg.rand(0.float32, data.len.float32 - 1).int]

    var distances = newSeq[float32](data.len)
    for i in 1..<k:
        var totalDist: float32
        for j, point in data.pairs:
            distances[j] = nearestCentroid(point, result[0..<i]).sqDist
            totalDist += distances[j]

        let target = rg.rand(0.0, totalDist)
        var cumulativeDist: float32
        for j, dist in distances.pairs:
            cumulativeDist += dist
            if cumulativeDist >= target: result[i] = data[j]; break


proc kMeans(data: seq[Vec3f], k: int, rg: var PCG): seq[int] =
    if data.len == k: return countup(0, k - 1).toSeq

    result = newSeq[int](data.len)

    var 
        centroids = kMeansPlusPlusInit(data, k, rg)
        tmpCentroids = newSeq[Vec3f](k)
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

    let handlersAABBs = handlers.mapIt(it.val.getAABB)
    
    if handlers.len <= maxShapesPerLeaf:
        return BVHNode(kind: nkLeaf, aabb: handlersAABBs.getTotalAABB, indexes: handlers.mapIt(it.key))
    
    var 
        rg = newPCG(rgSetUp)
        clusters = newSeqWith[seq[int]](kClusters, newSeqOfCap[int](handlers.len div kClusters))

    for handlerIdx, clusterIdx in kMeans(handlersAABBs.mapIt(it.getCentroid), kClusters, rg).pairs: 
        clusters[clusterIdx].add handlerIdx

    var childNodes = newSeq[BVHNode](kClusters)
    for i in 0..<kClusters:         
        childNodes[i] = 
            if clusters[i].len == 0: nil
            else: newBVHNode(clusters[i].mapIt(handlers[it]), kClusters, maxShapesPerLeaf, newRandomSetUp(rg.random, rg.random))

    BVHNode(
        kind: nkBranch, 
        aabb: handlersAABBs.getTotalAABB,
        children: childNodes
    )


proc newBVHTree(treeKind: TreeKind, maxShapesPerLeaf: int, handlers: seq[ObjectHandler], rgSetUp: RandomSetUp): BVHTree {.inline.} =
    let root = newBVHNode(handlers.pairs.toSeq, treeKind.int, maxShapesPerLeaf, rgSetUp)
    (treeKind, maxShapesPerLeaf, root, handlers)

proc newScene*(bgColor: Color, handlers: seq[ObjectHandler], treeKind: TreeKind, maxShapesPerLeaf: int, rgSetUp: RandomSetUp): Scene {.inline.} =
    assert handlers.len > 0, "Error! Cannot create a Scene from an empty sequence of ObjectHandlers."
    Scene(bgColor: bgColor, tree: newBVHTree(treeKind, maxShapesPerLeaf, handlers, rgSetUp))