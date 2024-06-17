import geometry, hdrimage, shapes, pcg

from std/sequtils import concat, foldl, toSeq, filterIt, mapIt
from std/math import sqrt, floor
from std/strformat import fmt

type ShapeHandler* = ref object 
    shape*: Shape
    transformation*: Transformation

proc getAABB*(handler: ShapeHandler): Interval[Point3D] {.inline.} =
    newAABB handler.shape.getVertices.mapIt(apply(handler.transformation, it))

proc getLocalAABB*(refSystem: ReferenceSystem; handler: ShapeHandler): Interval[Point3D] {.inline.} =
    newAABB handler.shape.getVertices.mapIt(
        refSystem.project(
            apply(newComposition(handler.transformation, newTranslation(refSystem.origin).inverse), it).Vec3f
        ).Point3D    
    )


type
    SceneNodeKind* = enum 
        nkBranch, nkLeaf

    # BranchNodeKind* = enum 
    #     bkBinary, bkTernary, bkQuaternary, bkOctonary

    BVHStrategy* = enum skMedian, skSAH

    SceneNode* = ref object
        aabb*: Interval[Point3D]
        
        case kind*: SceneNodeKind
        of nkBranch:
            children*: seq[SceneNode]
        of nkLeaf:
            handlers*: seq[ShapeHandler]

    Scene* = ref object 
        bgCol*: Color
        handlers*: seq[ShapeHandler]

    
proc getCentroid(aabb: Interval[Point3D]): Vec3f {.inline.} =
    newVec3f((aabb.min.x + aabb.max.x) / 2.0, (aabb.min.y + aabb.max.y) / 2.0, (aabb.min.z + aabb.max.z) / 2.0)


proc nearestClusterCentroid(point: Vec3f, clusterCentroids: seq[Vec3f]): tuple[index: int, sqDist: float32] =
    result = (index: 0, sqDist: Inf.float32)

    for i, center in clusterCentroids.pairs:
        let d = dist2(center, point)
        if result.sqDist > d: result = (i, d)
        # if d > 0 and result.sqDist > d: result = (i, d)


proc updateCentroids(data: seq[Vec3f], clusters: seq[int], k: int): seq[Vec3f] =
    var counts = newSeq[int](k)
        
    result = newSeq[Vec3f](k)
    for i, point in data.pairs:
        result[clusters[i]] += point
        counts[clusters[i]] += 1

    for i in 0..<k:
        if counts[i] > 0: result[i] /= counts[i].float32


proc kmeans(data: seq[Vec3f], k: int, rgState, rgSeq: uint64, maxIter: int = 20): tuple[clusters: seq[int], centroids: seq[Vec3f]] =
    if data.len == k: return (countup(0, k - 1).toSeq, data)

    var 
        iter = 0
        converged = false
        rg = newPCG(rgState, rgSeq)
        tmpCentroids = newSeq[Vec3f](k)
    
    result.centroids = newSeq[Vec3f](k)
    var a1, a2: int

    for i in 0..<k: 
        if i == 0: 
            a1 = rg.rand(0.float32, data.len.float32).int
            while a1 >= data.len:
                a1 = rg.rand(0.float32, data.len.float32).int

            result.centroids[0] = data[a1]
        else:
            a2 = (rg.rand(0.float32, data.len.float32) - 1e-2).int
            while (a1 == a2) or a2 >= data.len:
                a2 = rg.rand(0.float32, data.len.float32 - 1e-2).int
            result.centroids[1] = data[a2]

        # result.centroids[i] = data[(rg.rand * data.len.float32).int]

    while iter < maxIter and not converged:
        result.clusters = data.mapIt(it.nearestClusterCentroid(result.centroids).index)
        tmpCentroids = updateCentroids(data, result.clusters, k)

        converged = true
        for i in 0..<k:
            if not areClose(result.centroids[i], tmpCentroids[i], 1.0e-3):
                converged = false
                break

        result.centroids = tmpCentroids

        iter += 1


proc newBVHNode*(shapeHandlers: seq[ShapeHandler], localAABBs: seq[Interval[Point3D]], depth, maxShapesPerLeaf: int, rgState, rgSeq: uint64): SceneNode =
    if shapeHandlers.len == 0: return nil

    if shapeHandlers.len <= maxShapesPerLeaf:
        return SceneNode(kind: nkLeaf, aabb: localAABBs.getTotalAABB, handlers: shapeHandlers)
    
    let 
        sqLen = sqrt(shapeHandlers.len.float32)
        k = max(2, min(16, sqLen.int))
        clusters = kmeans(localAABBs.mapIt(it.getCentroid), k, rgState, rgSeq).clusters.pairs.toSeq
    
    var childNodes = newSeq[SceneNode](k)
    for i in 0..<k: 
        let cluster = clusters.filterIt(it.val == i)
        let handlers = cluster.mapIt(shapeHandlers[it.key])
        let boxes = cluster.mapIt(localAABBs[it.key])

        childNodes[i] = newBVHNode(handlers, boxes, depth + 1, maxShapesPerLeaf, rgState, rgSeq)
    
    SceneNode(kind: nkBranch, aabb: localAABBs.getTotalAABB, children: childNodes)


proc newScene*(shapeHandlers: seq[ShapeHandler], bgCol: Color = BLACK): Scene {.inline.} = 
    Scene(bgCol: bgCol, handlers: shapeHandlers)

proc getSceneTree*(refSystem: ReferenceSystem; scene: Scene, maxShapesPerLeaf: int, rgState, rgSeq: uint64): SceneNode {.inline.} = 
    let localAABBs = scene.handlers.mapIt(refSystem.getLocalAABB(it))
    newBVHNode(scene.handlers, localAABBs, depth = 0, maxShapesPerLeaf, rgState, rgSeq)


proc loadMesh*(world: Scene, source: string) = quit "to implement"
proc loadTexture*(world: Scene, source: string, shape: Shape) = quit "to implement"


proc newShapeHandler*(shape: Shape, transformation = Transformation.id): ShapeHandler {.inline.} =
    ShapeHandler(shape: shape, transformation: transformation)

proc newSphere*(center: Point3D, radius: float32; material = newMaterial()): ShapeHandler {.inline.} =   
    newShapeHandler(newSphere(radius, material), if center != ORIGIN3D: newTranslation(center) else: Transformation.id)

proc newUnitarySphere*(center: Point3D; material = newMaterial()): ShapeHandler {.inline.} = 
    newShapeHandler(newSphere(1.0, material), if center != ORIGIN3D: newTranslation(center) else: Transformation.id)

proc newPlane*(material = newMaterial(), transformation = Transformation.id): ShapeHandler {.inline.} = 
    newShapeHandler(Shape(kind: skPlane, material: material), transformation)

proc newBox*(aabb: Interval[Point3D], material = newMaterial(), transformation = Transformation.id): ShapeHandler {.inline.} =
    newShapeHandler(Shape(kind: skAABox, aabb: aabb, material: material), transformation)