import geometry, pcg, scene, shape

from std/sequtils import toSeq, filterIt, map, mapIt


proc getAABB*(handler: ObjectHandler): Interval[Point3D] {.inline.} =
    case handler.kind
    of hkShape: newAABB handler.shape.getVertices.mapIt(apply(handler.transformation, it))
    of hkMesh: newAABB handler.mesh.tree.aabb.getVertices.mapIt(apply(handler.transformation, it))


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
        result[clusters[i]] += point
        counts[clusters[i]] += 1

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
            if cumulativeDist >= target:
                result[i] = data[j]
                break


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



proc newBVHNode*(handlers: seq[ObjectHandler], kClusters, maxShapesPerLeaf, depth: int, rg: var PCG): BVHNode =
    if handlers.len == 0: return nil

    let handlersAABBs = handlers.mapIt(it.getAABB)
    
    if handlers.len <= maxShapesPerLeaf:
        return BVHNode(
            kind: nkLeaf, 
            aabb: handlersAABBs.getTotalAABB, 
            handlers: handlers
        )
    
    let clusters = kMeans(handlersAABBs.mapIt(it.getCentroid), kClusters, rg).pairs.toSeq

    var childNodes = newSeq[BVHNode](kClusters)
    for i in 0..<kClusters: 
        childNodes[i] = newBVHNode(clusters.filterIt(it.val == i).mapIt(handlers[it.key]), kClusters, maxShapesPerLeaf, depth + 1, rg)

    BVHNode(
        kind: nkBranch, 
        aabb: handlersAABBs.getTotalAABB, 
        children: childNodes
    )



type TreeKind* = enum 
    tkBinary = 2, tkTernary = 3, tkQuaternary = 4, tkOctonary = 8

proc getBVHTree*(scene: Scene; kind: TreeKind, maxShapesPerLeaf: int = 4, rg: var PCG): BVHNode {.inline.} =
    newBVHNode(scene.handlers, kind.int, maxShapesPerLeaf, depth = 0, rg)