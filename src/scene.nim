import geometry, hdrimage, camera

import std/options
from std/strformat import fmt
from std/sequtils import concat, apply, map, foldl, toSeq
from std/algorithm import sorted
from std/math import sgn, floor, sqrt, arccos, arctan2, PI


type 
    AABB* = Interval[Point3D]

    ShapeKind* = enum
        skAABox, skTriangle, skSphere, skPlane, skCylinder
        
    Shape* = object
        transform*: Transformation # this should be a ref or ptr

        material*: Material

        case kind*: ShapeKind 
        of skAABox: 
            aabb*: AABB

        of skTriangle: 
            vertices*: array[3, Point3D]            

        of skSphere:
            radius*: float32

        of skCylinder:
            R*, zMin*, zMax*, phiMax*: float32

        of skPlane: discard


    MeshKind* = enum
        mkTriangular, mkSquared

    Mesh* = object
        kind*: MeshKind
        nodes*: seq[Point3D]
        edges*: seq[int]


    Scene* = object
        bgCol*: Color
        shapes*: ptr seq[Shape]
        transhapes*: ptr seq[Transformation]
        meshes*: ptr seq[Mesh]
        transmeshes*: ptr seq[Transformation]


    SceneNodeKind* = enum
        nkLeaf, nkRoot

    SceneNode* = ref object
        aabb*: AABB
        
        case kind*: SceneNodeKind
        of nkLeaf:
            shapes*: seq[Shape]
        of nkRoot:
            left*, right*: SceneNode


    SceneTreeKind* = enum
        stkBVH, stkKD

    SceneTree* = object
        kind*: SceneTreeKind
        root*: SceneNode

# Need to be tested
proc newScene*(shapes: ptr seq[Shape], tShapes: ptr seq[Transformation], meshes: ptr seq[Mesh], tMeshes: ptr seq[Transformation], bgCol = BLACK, tScene: Transformation): Scene = 
    
    # Checking wether we need to transform shape or not
    if not areClose(tScene.mat, IDENTITY.mat):
        for i in 0..<shapes[].len:
            tShapes[i] = tShapes[i] @ tScene.inverse
        for i in 0..<meshes[].len:
            tMeshes[i] = tMeshes[i] @ tScene.inverse

    return Scene(
            bgCol: bgCol,
            shapes: shapes,
            transhapes: tShapes,
            meshes: meshes, 
            transmeshes: tMeshes
        )

proc newAABB*(points: openArray[Point3D]): AABB =
    if points.len == 1: return (points[0], points[0])

    let 
        x = points.map(proc(pt: Point3D): float32 = pt.x) 
        y = points.map(proc(pt: Point3D): float32 = pt.y)
        z = points.map(proc(pt: Point3D): float32 = pt.z)

    (newPoint3D(x.min, y.min, z.min), newPoint3D(x.max, y.max, z.max))

proc getVertices*(aabb: AABB): array[8, Point3D] =
    return [
        aabb.min, aabb.max,
        newPoint3D(aabb.min.x, aabb.min.y, aabb.max.z),
        newPoint3D(aabb.min.x, aabb.max.y, aabb.min.z),
        newPoint3D(aabb.min.x, aabb.max.y, aabb.max.z),
        newPoint3D(aabb.max.x, aabb.min.y, aabb.min.z),
        newPoint3D(aabb.max.x, aabb.min.y, aabb.max.z),
        newPoint3D(aabb.max.x, aabb.max.y, aabb.min.z),
    ]

proc getLocalAABB(shape: Shape): AABB {.inline.} =
    case shape.kind
    of skAABox: return shape.aabb
    of skTriangle: return newAABB(shape.vertices)
    of skSphere: return (newPoint3D(-shape.radius, -shape.radius, -shape.radius), newPoint3D(shape.radius, shape.radius, shape.radius))
    of skCylinder: return (newPoint3D(-shape.R, -shape.R, shape.zMin), newPoint3D(shape.R, shape.R, shape.zMax))
    of skPlane: return (newPoint3D(-Inf, -Inf, -Inf), newPoint3D(Inf, Inf, 0))

proc getLocalVertices(shape: Shape): seq[Point3D] {.inline.} = 
    case shape.kind
    of skTriangle: return shape.vertices.toSeq
    of skAABox: return shape.aabb.getVertices.toSeq
    else: return shape.getLocalAABB.getVertices.toSeq

proc getVertices*(shape: Shape, transform: Transformation = IDENTITY): seq[Point3D] {.inline.} = 
    if transform.kind == tkIdentity: shape.getLocalVertices
    else: shape.getLocalVertices.map(proc(pt: Point3D): Point3D = apply(transform, pt))
    
proc getAABB*(shape: Shape, transform: Transformation = IDENTITY): AABB {.inline.} =
    if transform.kind == tkIdentity: return shape.getLocalAABB

    case shape.kind
    of skAABox, skTriangle, skCylinder: return newAABB(shape.getVertices(transform))

    of skSphere: 
        let center = apply(transform, ORIGIN3D)
        let radiusPt = newVec3f(shape.radius, shape.radius, shape.radius)
        return newInterval(center - radiusPt, center + radiusPt)

    of skPlane: return newInterval(apply(transform, newPoint3D(-Inf, -Inf, -Inf)), apply(transform, newPoint3D(Inf, Inf, 0)))


proc newAABox*(min = ORIGIN3D, max = newPoint3D(1, 1, 1); 
                material = newMaterial(), transformation = IDENTITY): Shape {.inline.} =
    Shape(kind: skAABox, material: material, aabb: newInterval(min, max), transform: transformation)

proc newAABox*(aabb: AABB; material = newMaterial(), transformation = IDENTITY): Shape {.inline.} =
    Shape(kind: skAABox, material: material, aabb: aabb, transform: transformation)

proc newSphere*(center: Point3D, radius: float32; material = newMaterial()): Shape {.inline.} =   
    Shape(kind: skSphere, transform: if center != ORIGIN3D: newTranslation(center.Vec3f) else: IDENTITY, material: material, radius: radius)

proc newUnitarySphere*(center: Point3D; material = newMaterial()): Shape {.inline.} = 
    Shape(kind: skSphere, transform: if center != ORIGIN3D: newTranslation(center.Vec3f) else: IDENTITY, material: material, radius: 1.0)

proc newTriangle*(a, b, c: Point3D; transformation = IDENTITY, material = newMaterial()): Shape {.inline.} = 
    Shape(kind: skTriangle, transform: transformation, material: material, vertices: [a, b, c])

proc newTriangle*(vertices: array[3, Point3D]; transformation = IDENTITY, material = newMaterial()): Shape {.inline.} = 
    Shape(kind: skTriangle, transform: transformation, material: material, vertices: vertices)

proc newPlane*(transformation = IDENTITY, material = newMaterial()): Shape {.inline.} = 
    Shape(kind: skPlane, transform: transformation, material: material)

proc newCylinder*(r: float32 = 1.0, z_min: float32 = 0.0, z_max: float32 = 1.0, phi_max: float32 = 2.0 * PI; 
                    transformation = IDENTITY, material = newMaterial()): Shape {.inline.} =
    Shape(kind: skCylinder, transform: transformation, material: material, R: r, zMin: z_min, zMax: z_max, phiMax: phi_max)


proc newMesh*(kind: MeshKind, nodes: seq[Point3D], edges: seq[int]; transformation = IDENTITY): Mesh {.inline.} = 
    Mesh(kind: kind, nodes: if transformation.kind == tkIdentity: nodes else: nodes.map(proc(pt: Point3D): Point3D = apply(transformation, pt)), edges: edges)

iterator items*(mesh: Mesh): Shape =
    case mesh.kind
    of mkTriangular: 
        for i in 0..<(mesh.edges.len div 3): 
            yield newTriangle(mesh.nodes[mesh.edges[i * 3]], mesh.nodes[mesh.edges[i * 3 + 1]], mesh.nodes[mesh.edges[i * 3 + 2]])    

    of mkSquared: discard

proc newTriangularMesh*(nodes: seq[Point3D], edges: seq[int]; transformation = IDENTITY): Mesh {.inline.} = 
    assert edges.len mod 3 == 0, fmt"Error in creating a triangular Mesh! The length of the edges sequence must be a multiple of 3."
    newMesh(mkTriangular, nodes, edges, transformation)


proc getAllShapes*(scene: Scene): seq[Shape] {.inline.} =
    if scene.meshes[].len == 0: return scene.shapes[]
    elif scene.shapes[].len == 0: return scene.meshes[].map(proc(mesh: Mesh): seq[Shape] = mesh.items.toSeq).foldl(concat(a, b))
    else: return concat(scene.shapes[], scene.meshes[].map(proc(mesh: Mesh): seq[Shape] = mesh.items.toSeq).foldl(concat(a, b)))


proc getTotalAABB*(shapes: openArray[Shape], transform: Transformation = IDENTITY): AABB =
    if shapes.len == 0: 
        let observerPt = apply(transform, ORIGIN3D)
        return (observerPt, observerPt)

    result = (min: newPoint3D(Inf, Inf, Inf), max: newPoint3D(-Inf, -Inf, -Inf))
    for shape in shapes:
        let aabb = shape.getAABB(if transform.kind != tkComposition: newComposition(transform.inverse, shape.transform) else: shape.transform)
        result = newInterval(newInterval(aabb.min, result.min).min, newInterval(aabb.max, result.max).max)


proc newBVHLeaf*(aabb: AABB, shapes: seq[Shape]): SceneNode {.inline.} =
    SceneNode(kind: nkLeaf, aabb: aabb, shapes: shapes)

proc newBVHRoot*(aabb: AABB, left, right: Option[SceneNode]): SceneNode {.inline.} =
    SceneNode(kind: nkRoot, aabb: aabb, left: if left.isSome: left.get else: nil, right: if right.isSome: right.get else: nil)

proc newBVHNode*(shapes: seq[Shape], transform: Transformation, maxShapesPerLeaf: int, depth: int): Option[SceneNode] =   
    if shapes.len == 0: return none SceneNode

    if shapes.len <= maxShapesPerLeaf: return some newBVHLeaf(shapes.getTotalAABB(transform), shapes)
    let 
        sortedShapes = shapes.sorted(proc(a, b: Shape): int = cmp(a.getAABB(transform).min.x, b.getAABB(transform).min.x))
        leftNode =  newBVHNode(sortedShapes[0..<shapes.len div 2], transform, maxShapesPerLeaf, depth + 1)
        rightNode = newBVHNode(sortedShapes[shapes.len div 2..<shapes.len], transform, maxShapesPerLeaf, depth + 1)

    if leftNode.isNone and rightNode.isNone: return none SceneNode # maybe not useful
    some newBVHRoot(shapes.getTotalAABB(transform), leftNode, rightNode)
 

proc newSceneTree*(shapes: seq[Shape], transform: Transformation = IDENTITY, maxShapesPerLeaf: int): SceneTree =  
    SceneTree(kind: stkBVH, root: newBVHNode(shapes, transform, maxShapesPerLeaf, depth = 0).get)

proc newSceneTree*(scene: ptr Scene, transform: Transformation = IDENTITY, maxShapesPerLeaf: int): SceneTree =       
    SceneTree(kind: stkBVH, root: newBVHNode(scene[].getAllShapes, transform, maxShapesPerLeaf, depth = 0).get)


proc loadMesh*(world: Scene, source: string) = quit "to implement"
proc loadTexture*(world: Scene, source: string, shape: Shape) = quit "to implement"


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
        return newPoint2D(phi / shape.phiMax, (pt.z - shape.zMin) / (shape.zMax - shape.zMin))

    of skPlane: 
        return newPoint2D(pt.x - floor(pt.x), pt.y - floor(pt.y))


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