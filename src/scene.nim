import geometry, pcg, hdrimage, material

from std/sequtils import newSeqWith, toSeq, filterIt, map, mapIt


type    
    Scene* = object 
        bgColor*: Color
        tree*: BVHTree
        handlers*: seq[ObjectHandler]


    TreeKind* = enum tkBinary = 2, tkTernary = 3, tkQuaternary = 4, tkOctonary = 8
    BVHTree* = tuple[kind: TreeKind, mspl: int, root: BVHNode]


    BVHNodeKind* = enum nkBranch, nkLeaf
    BVHNode* = ref object
        aabb*: Interval[Point3D]
        
        case kind*: BVHNodeKind
        of nkBranch: children*: seq[BVHNode]
        of nkLeaf: indexes*: seq[int]


    ObjectHandlerKind* = enum hkShape, hkMesh
    ObjectHandler* = ref object
        transformation*: Transformation
        pigment*: Pigment
        brdf*: BRDF

        case kind*: ObjectHandlerKind
        of hkShape: shape*: Shape 
        of hkMesh: mesh*: Mesh


    ShapeKind* = enum skPoint, skAABox, skTriangle, skSphere, skPlane, skCylinder
    Shape* = ref object
        case kind*: ShapeKind 
        of skPoint, skPlane: discard
        of skAABox: aabb*: Interval[Point3D]
        of skTriangle: vertices*: seq[Point3D]            
        of skSphere: radius*: float32
        of skCylinder:
            R*, phiMax*: float32
            zSpan*: Interval[float32]


    Mesh* = object
        tree*: BVHTree
        shapes*: seq[ObjectHandler]


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


proc getAABB*(shape: Shape): Interval[Point3D] {.inline.} =
    case shape.kind
    of skPoint: (ORIGIN3D, ORIGIN3D)
    of skAABox: shape.aabb
    of skTriangle: newAABB(shape.vertices)
    of skSphere: (newPoint3D(-shape.radius, -shape.radius, -shape.radius), newPoint3D(shape.radius, shape.radius, shape.radius))
    of skCylinder: (newPoint3D(-shape.R, -shape.R, shape.zSpan.min), newPoint3D(shape.R, shape.R, shape.zSpan.max))
    of skPlane: (newPoint3D(-Inf, -Inf, -Inf), newPoint3D(Inf, Inf, 0))
    

proc getVertices(aabb: Interval[Point3D]): seq[Point3D] {.inline.} =
    @[
        aabb.min, aabb.max,
        newPoint3D(aabb.min.x, aabb.min.y, aabb.max.z),
        newPoint3D(aabb.min.x, aabb.max.y, aabb.min.z),
        newPoint3D(aabb.min.x, aabb.max.y, aabb.max.z),
        newPoint3D(aabb.max.x, aabb.min.y, aabb.min.z),
        newPoint3D(aabb.max.x, aabb.min.y, aabb.max.z),
        newPoint3D(aabb.max.x, aabb.max.y, aabb.min.z),
    ]

proc getVertices(shape: Shape): seq[Point3D] {.inline.} = 
    case shape.kind
    of skPoint: @[ORIGIN3D]
    of skAABox: shape.aabb.getVertices
    of skTriangle: shape.vertices
    else: shape.getAABB.getVertices


proc getAABB*(handler: ObjectHandler): Interval[Point3D] {.inline.} =
    case handler.kind
    # of hkPoint: (apply(handler.transformation, ORIGIN3D), apply(handler.transformation, ORIGIN3D))
    of hkShape: newAABB handler.shape.getVertices.mapIt(apply(handler.transformation, it))
    of hkMesh: newAABB handler.mesh.tree.root.aabb.getVertices.mapIt(apply(handler.transformation, it))


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



proc newBVHNode*(handlers: seq[tuple[key: int, val: ObjectHandler]], kClusters, maxShapesPerLeaf: int, rgSetUp: RandomSetUp): BVHNode =
    if handlers.len == 0: return nil

    let handlersAABBs = handlers.mapIt(it.val.getAABB)
    
    if handlers.len <= maxShapesPerLeaf:
        return BVHNode(
            kind: nkLeaf, 
            aabb: handlersAABBs.getTotalAABB, 
            indexes: handlers.mapIt(it.key)
        )
    
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


proc newPointLight*(color: Color, position: Point3D): ObjectHandler {.inline.} =
    ObjectHandler(
        kind: hkShape,
        transformation: newTranslation(position), 
        brdf: nil, 
        pigment: newUniformPigment(color),
        shape: Shape(kind: skPoint)
    )

proc newSurfaceLight*(color: Color, surface: Shape, transformation = Transformation.id): ObjectHandler {.inline.} =
    ObjectHandler(
        kind: hkShape, 
        transformation: transformation, 
        brdf: nil, 
        pigment: newUniformPigment(color),
        shape: surface
    )

proc newSurfaceLight*(color: Color, surface: Mesh, transformation = Transformation.id): ObjectHandler {.inline.} =
    ObjectHandler(
        kind: hkMesh, 
        transformation: transformation, 
        brdf: nil, 
        pigment: newUniformPigment(color),
        mesh: surface
    )

proc newScene*(bgColor: Color, handlers: seq[ObjectHandler], rgSetUp: RandomSetUp, treeKind: TreeKind, maxShapesPerLeaf: int = 1): Scene {.inline.} =
    assert handlers.len > 0, "Error! Cannot create a Scene from an empty sequence of ObjectHandlers."
    Scene(
        bgColor: bgColor,
        handlers: handlers,
        tree: (treeKind, maxShapesPerLeaf, newBVHNode(handlers.pairs.toSeq, treeKind.int, maxShapesPerLeaf, rgSetUp))
    )