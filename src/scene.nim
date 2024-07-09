import geometry, pcg, hdrimage, material

from std/math import sgn, floor, arccos, arctan2, PI
from std/streams import newFileStream, close, atEnd, readLine 
from std/sequtils import concat, foldl, toSeq, filterIt, mapIt
from std/strutils import isEmptyOrWhiteSpace, rsplit, splitWhitespace, parseFloat, parseInt
from std/strformat import fmt


type
    SceneNodeKind* = enum nkBranch, nkLeaf

    SceneNode* = ref object
        aabb*: Interval[Point3D]
        
        case kind*: SceneNodeKind
        of nkBranch:
            children*: seq[SceneNode]
        of nkLeaf:
            handlers*: seq[ShapeHandler]


    ShapeKind* = enum
        skAABox, skTriangle, skSphere, skPlane, skCylinder, skTriangularMesh, skEllipsoid, skCSGUnion
        
    Shape* = ref object
        material*: Material

        case kind*: ShapeKind 
        of skAABox: 
            aabb*: Interval[Point3D]

        of skTriangle: 
            vertices*: array[3, Point3D]            

        of skSphere:
            radius*: float32
        
        of skEllipsoid:
            axis*: tuple[a: float32, b: float32, c: float32]

        of skCylinder:
            R*, phiMax*: float32
            zSpan*: Interval[float32]

        of skPlane: discard

        of skTriangularMesh:
            nodes*: seq[Point3D]
            edges*: seq[int]
            tree*: SceneNode

        of skCSGUnion:
            shapes*: tuple[primary, secondary: Shape]
            shTrans*: tuple[tPrimary, tSecondary: Transformation]
        

    ShapeHandler* = ref object 
        shape*: Shape
        transformation*: Transformation


    Scene* = ref object 
        bgCol*: Color
        handlers*: seq[ShapeHandler]

    SceneTreeKind* = enum 
        tkBinary = 2, tkTernary = 3, tkQuaternary = 4, tkOctonary = 8


proc newAABB*(points: seq[Point3D]): Interval[Point3D] =
    if points.len == 1: return (points[0], points[0])

    let 
        x = points.mapIt(it.x) 
        y = points.mapIt(it.y)
        z = points.mapIt(it.z)

    (newPoint3D(x.min, y.min, z.min), newPoint3D(x.max, y.max, z.max))

proc getTotalAABB*(aabbSeq: seq[Interval[Point3D]]): Interval[Point3D] =
    if aabbSeq.len == 0: return (newPoint3D(Inf, Inf, Inf), newPoint3D(-Inf, -Inf, -Inf))
    if aabbSeq.len == 1: return aabbSeq[0]

    let
        minX = aabbSeq.mapIt(it.min.x).min
        minY = aabbSeq.mapIt(it.min.y).min
        minZ = aabbSeq.mapIt(it.min.z).min
        maxX = aabbSeq.mapIt(it.max.x).max
        maxY = aabbSeq.mapIt(it.max.y).max
        maxZ = aabbSeq.mapIt(it.max.z).max

    (newPoint3D(minX, minY, minZ), newPoint3D(maxX, maxY, maxZ))

proc getVertices*(aabb: Interval[Point3D]): array[8, Point3D] =
    return [
        aabb.min, aabb.max,
        newPoint3D(aabb.min.x, aabb.min.y, aabb.max.z),
        newPoint3D(aabb.min.x, aabb.max.y, aabb.min.z),
        newPoint3D(aabb.min.x, aabb.max.y, aabb.max.z),
        newPoint3D(aabb.max.x, aabb.min.y, aabb.min.z),
        newPoint3D(aabb.max.x, aabb.min.y, aabb.max.z),
        newPoint3D(aabb.max.x, aabb.max.y, aabb.min.z),
    ]

proc getCentroid(aabb: Interval[Point3D]): Vec3f {.inline.} =
    newVec3f((aabb.min.x + aabb.max.x) / 2.0, (aabb.min.y + aabb.max.y) / 2.0, (aabb.min.z + aabb.max.z) / 2.0)


proc getAABB*(shape: Shape): Interval[Point3D] {.inline.} =
    case shape.kind
    of skAABox: return shape.aabb
    of skTriangle: return newAABB(shape.vertices.toSeq)
    of skSphere: return (newPoint3D(-shape.radius, -shape.radius, -shape.radius), newPoint3D(shape.radius, shape.radius, shape.radius))
    of skCylinder: return (newPoint3D(-shape.R, -shape.R, shape.zSpan.min), newPoint3D(shape.R, shape.R, shape.zSpan.max))
    of skPlane: return (newPoint3D(-Inf, -Inf, -Inf), newPoint3D(Inf, Inf, 0))
    of skTriangularMesh: return shape.tree.aabb
    of skEllipsoid: return (newPoint3D(-shape.axis.a, -shape.axis.b, -shape.axis.c), newPoint3D(shape.axis.a, shape.axis.b, shape.axis.c))
    of skCSGUnion: discard
    
proc getVertices*(shape: Shape): seq[Point3D] {.inline.} = 
    case shape.kind
    of skTriangle: return shape.vertices.toSeq
    of skAABox: return shape.aabb.getVertices.toSeq
    else: return shape.getAABB.getVertices.toSeq
    

proc getAABB*(handler: ShapeHandler): Interval[Point3D] {.inline.} =
    newAABB handler.shape.getVertices.mapIt(apply(handler.transformation, it))


proc getUV*(shape: Shape; pt: Point3D): Point2D = 
    case shape.kind
    of skAABox:
        if pt.x == shape.aabb.min.x: 
            return newPoint2D((pt.y - shape.aabb.min.y) / (shape.aabb.max.y - shape.aabb.min.y), (pt.z - shape.aabb.min.z) / (shape.aabb.max.z - shape.aabb.min.z))
        elif pt.x == shape.aabb.max.x: 
            return newPoint2D((pt.y - shape.aabb.min.y) / (shape.aabb.max.y - shape.aabb.min.y), (pt.z - shape.aabb.min.z) / (shape.aabb.max.z - shape.aabb.min.z))
        elif pt.y == shape.aabb.min.y: 
            return newPoint2D((pt.x - shape.aabb.min.x) / (shape.aabb.max.x - shape.aabb.min.x), (pt.z - shape.aabb.min.z) / (shape.aabb.max.z - shape.aabb.min.z))
        elif pt.y == shape.aabb.max.y: 
            return newPoint2D((pt.x - shape.aabb.min.x) / (shape.aabb.max.x - shape.aabb.min.x), (pt.z - shape.aabb.min.z) / (shape.aabb.max.z - shape.aabb.min.z))
        elif pt.z == shape.aabb.min.z: 
            return newPoint2D((pt.x - shape.aabb.min.x) / (shape.aabb.max.x - shape.aabb.min.x), (pt.y - shape.aabb.min.y) / (shape.aabb.max.y - shape.aabb.min.y))
        elif pt.z == shape.aabb.max.z: 
            return newPoint2D((pt.x - shape.aabb.min.x) / (shape.aabb.max.x - shape.aabb.min.x), (pt.y - shape.aabb.min.y) / (shape.aabb.max.y - shape.aabb.min.y))
        else:
            return newPoint2D(0, 0)

    of skTriangle:
        let 
            (x_ptA, x_BA, x_CA) = ((pt.x - shape.vertices[0].x), (shape.vertices[1].x - shape.vertices[0].x), (shape.vertices[2].x - shape.vertices[0].x))
            (y_ptA, y_BA, y_CA) = ((pt.y - shape.vertices[0].y), (shape.vertices[1].y - shape.vertices[0].y), (shape.vertices[2].y - shape.vertices[0].y))
            (u_num, u_den) = (x_ptA * y_CA - y_ptA * x_CA, xBA * y_CA - y_BA * x_CA)
            (v_num, v_den) = (x_ptA * y_BA - y_ptA * xBA, x_CA * y_BA - y_CA * xBA)
        return newPoint2D(u_num / u_den, v_num / v_den)
        
    of skSphere:
        var u = arctan2(pt.y, pt.x) / (2 * PI)
        if u < 0.0: u += 1.0
        return newPoint2D(u, arccos(pt.z) / PI)

    of skCylinder:
        var phi = arctan2(pt.y, pt.x)
        if phi < 0.0: phi += 2.0 * PI
        return newPoint2D(phi / shape.phiMax, (pt.z - shape.zSpan.min) / (shape.zSpan.max - shape.zSpan.min))

    of skPlane: 
        return newPoint2D(pt.x - floor(pt.x), pt.y - floor(pt.y))

    of skTriangularMesh: quit "This should not be used"
    
    of skEllipsoid: 
        let scal = newScaling(newVec3f(1/shape.axis.a, 1/shape.axis.b, 1/shape.axis.c))
        return getUV(Shape(kind: skSphere, radius: 1), apply(scal, pt))

    of skCSGUnion: discard


proc getNormal*(shape: Shape; pt: Point3D, dir: Vec3f): Normal = 
    case shape.kind
    of skAABox:
        if   areClose(pt.x, shape.aabb.min.x, 1e-6) or areClose(pt.x, shape.aabb.max.x, 1e-6): result = newNormal(1, 0, 0)
        elif areClose(pt.y, shape.aabb.min.y, 1e-6) or areClose(pt.y, shape.aabb.max.y, 1e-6): result = newNormal(0, 1, 0)
        elif areClose(pt.z, shape.aabb.min.z, 1e-6) or areClose(pt.z, shape.aabb.max.z, 1e-6): result = newNormal(0, 0, 1)
        else: quit "Something went wrong in calculating the normal for an AABox."
        return sgn(-dot(result.Vec3f, dir)).float32 * result

    of skTriangle:
        let cross = cross((shape.vertices[1] - shape.vertices[0]).Vec3f, (shape.vertices[2] - shape.vertices[0]).Vec3f)
        return sgn(-dot(cross, dir)).float32 * cross.toNormal
        
    of skSphere: 
        return sgn(-dot(pt.Vec3f, dir)).float32 * newNormal(pt.x, pt.y, pt.z)

    of skCylinder:
        return newNormal(pt.x, pt.y, 0.0)

    of skPlane: 
        return newNormal(0, 0, sgn(-dir[2]).float32)
    
    of skTriangularMesh: quit "This should not be used"

    of skEllipsoid: 
        let 
            scal = newScaling(newVec3f(1/shape.axis.a, 1/shape.axis.b, 1/shape.axis.c))
            nSp = getNormal(Shape(kind: skSphere, radius: 1), apply(scal, pt), apply(scal, dir).normalize)

        return apply(scal.inverse, nSp).normalize

    of skCSGUnion: discard


proc nearestCentroid(point: Vec3f, clusterCentroids: seq[Vec3f]): tuple[index: int, sqDist: float32] =
    result = (index: 0, sqDist: Inf.float32)

    for i, center in clusterCentroids.pairs:
        let d = dist2(center, point)
        if result.sqDist > d: result = (i, d)

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

    # Choose the first centroid randomly
    result[0] = data[rg.rand(0.float32, data.len.float32 - 1).int]

    var distances = newSeq[float32](data.len)
    for i in 1..<k:
        var totalDist: float32

        # Calculate the distance to the nearest existing centroid
        for j, point in data.pairs:
            let nearest = nearestCentroid(point, result[0..<i])
            distances[j] = nearest.sqDist
            totalDist += distances[j]

        # Choose a new centroid with weighted probability
        let target = rg.rand(0.0, totalDist.float32)
        var cumulativeDist: float32
        for j, dist in distances.pairs:
            cumulativeDist += dist
            if cumulativeDist >= target:
                result[i] = data[j]
                break

proc kMeans(data: seq[Vec3f], k: int, rg: var PCG): tuple[clusters: seq[int], centroids: seq[Vec3f]] =
    if data.len == k:
        return (countup(0, k - 1).toSeq, data)

    result.centroids = kMeansPlusPlusInit(data, k, rg)
    result.clusters = newSeq[int](data.len)

    var converged = false
    while not converged:
        result.clusters = data.mapIt(it.nearestCentroid(result.centroids).index)
        let newCentroids = updateCentroids(data, result.clusters, k)

        converged = true
        for i in 0..<k:
            if not areClose(result.centroids[i], newCentroids[i], 1.0e-3):
                converged = false
                break

        result.centroids = newCentroids


proc newBVHNode*(shapeHandlers: seq[ShapeHandler], depth, kClusters, maxShapesPerLeaf: int, rg: var PCG): SceneNode =
    if shapeHandlers.len == 0: return nil

    let shapeHandlersAABBs = shapeHandlers.mapIt(it.getAABB)

    if shapeHandlers.len <= maxShapesPerLeaf:
        return SceneNode(kind: nkLeaf, aabb: shapeHandlersAABBs.getTotalAABB, handlers: shapeHandlers)
    
    let clusters = kMeans(shapeHandlersAABBs.mapIt(it.getCentroid), kClusters, rg).clusters.pairs.toSeq
    
    var childNodes = newSeq[SceneNode](kClusters)
    for i in 0..<kClusters: 
        let cluster = clusters.filterIt(it.val == i)
        childNodes[i] = newBVHNode(cluster.mapIt(shapeHandlers[it.key]), depth + 1, kClusters, maxShapesPerLeaf, rg)
    
    SceneNode(kind: nkBranch, aabb: shapeHandlersAABBs.getTotalAABB, children: childNodes)


proc newScene*(shapeHandlers: seq[ShapeHandler], bgCol: Color = BLACK): Scene {.inline.} = 
    Scene(bgCol: bgCol, handlers: shapeHandlers)
    
proc getBVHTree*(scene: Scene; kind: SceneTreeKind, maxShapesPerLeaf: int = 4, rg: var PCG): SceneNode {.inline.} =
    newBVHNode(scene.handlers, depth = 0, kind.int, maxShapesPerLeaf, rg)


proc loadMesh*(source: string): tuple[nodes: seq[Point3D], edges: seq[int]] = 
    var istream = newFileStream(source, fmRead)

    if istream.isNil: quit fmt"Error! Cannot open file {source}."

    while not istream.atEnd:

        var line = 
            try: istream.readLine 
            except: quit fmt"Error! Some failing happend while reading {source}."

        # I want to do further check only if we actually got something
        if not line.isEmptyOrWhitespace:
            let items = line.splitWhitespace.toSeq
            
            if items[0] == "v": result.nodes.add newPoint3D(items[1].parseFloat, items[2].parseFloat, items[3].parseFloat)
            elif items[0] == "f": 
                # We have only three indeces, so that we are defining only one triangular face
                if items.len == 4: 
                    # We want to have infos only regarding faces (we are going to discard normals and additional stuff)
                    result.edges.add items[1].rsplit('/')[0].parseInt - 1 
                    result.edges.add items[2].rsplit('/')[0].parseInt - 1
                    result.edges.add items[3].rsplit('/')[0].parseInt - 1

                else:
                    # Here we are triangulating non triangular meshes
                    for i in 0..items.len-4:
                        result.edges.add items[1].rsplit('/')[0].parseInt - 1 
                        result.edges.add items[2+i].rsplit('/')[0].parseInt - 1
                        result.edges.add items[3+i].rsplit('/')[0].parseInt - 1
    

proc loadTexture*(world: Scene, source: string, shape: Shape) = quit "to implement"


proc newShapeHandler(shape: Shape, transformation = Transformation.id): ShapeHandler {.inline.} =
    ShapeHandler(shape: shape, transformation: transformation)

proc newSphere*(center: Point3D, radius: float32; material = newMaterial()): ShapeHandler {.inline.} =   
    newShapeHandler(Shape(kind: skSphere, material: material, radius: radius), if center != ORIGIN3D: newTranslation(center) else: Transformation.id)

proc newUnitarySphere*(center: Point3D; material = newMaterial()): ShapeHandler {.inline.} = 
    newShapeHandler(Shape(kind: skSphere, material: material, radius: 1.0), if center != ORIGIN3D: newTranslation(center) else: Transformation.id)

proc newPlane*(material = newMaterial(), transformation = Transformation.id): ShapeHandler {.inline.} = 
    newShapeHandler(Shape(kind: skPlane, material: material), transformation)

proc newBox*(aabb: Interval[Point3D], material = newMaterial(), transformation = Transformation.id): ShapeHandler {.inline.} =
    newShapeHandler(Shape(kind: skAABox, aabb: aabb, material: material), transformation)

proc newTriangle*(a, b, c: Point3D; material = newMaterial(), transformation = Transformation.id): ShapeHandler {.inline.} = 
    newShapeHandler(Shape(kind: skTriangle, material: material, vertices: [a, b, c]), transformation)

proc newTriangle*(vertices: array[3, Point3D]; material = newMaterial(), transformation = Transformation.id): ShapeHandler {.inline.} = 
    newShapeHandler(Shape(kind: skTriangle, material: material, vertices: vertices), transformation)

proc newCylinder*(R = 1.0, zMin = 0.0, zMax = 1.0, phiMax = 2.0 * PI; material = newMaterial(), transformation = Transformation.id): ShapeHandler {.inline.} =
    newShapeHandler(Shape(kind: skCylinder, material: material, R: R, zSpan: (zMin.float32, zMax.float32), phiMax: phiMax), transformation)

proc newMesh*(source: string; transformation = Transformation.id, treeKind: SceneTreeKind, maxShapesPerLeaf: int, rgState, rgSeq: uint64): ShapeHandler = 
    let (nodes, edges) = loadMesh(source)
    assert edges.len mod 3 == 0, fmt"Error in creating a skTriangularMesh! The length of the edges sequence must be a multiple of 3."
    var triangles = newSeq[ShapeHandler](edges.len div 3)
    for i in 0..<edges.len div 3: 
        triangles[i] = newTriangle(nodes[edges[i * 3]], nodes[edges[i * 3 + 1]], nodes[edges[i * 3 + 2]])    

    var rg = newPCG(rgState, rgSeq)
    newShapeHandler(
        Shape(
            kind: skTriangularMesh, 
            nodes: nodes, edges: edges, 
            tree: newBVHNode(triangles, depth = 0, treeKind.int, maxShapesPerLeaf, rg), 
        ), transformation
    )


proc newEllipsoid*(a, b, c: SomeNumber, transformation = Transformation.id): ShapeHandler = 
    # Procedure to create a new Ellipsoid ShapeHandler
    newShapeHandler(
        Shape(
            kind: skEllipsoid,
            axis: (
                a: when a is float32: a else: a.float32, 
                b: when b is float32: b else: b.float32, 
                c: when c is float32: c else: c.float32
                )
        ),
        transformation
    )


proc newCSGUnion*(sh1, sh2: ShapeHandler, transformation = Transformation.id): ShapeHandler = 
    # Procedure to create a newCSGUnion ShapeHandler
    newShapeHandler(
        Shape(
            kind: skCSGUnion,
            shapes:(
                primary: sh1.shape,
                secondary: sh2.shape
                ),
            shTrans:(
                tPrimary: sh1.transformation,
                tSecondary: sh2.transformation
            )
        ),
        transformation
    )    
