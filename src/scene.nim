import geometry, shapes, camera

import std/options
from std/strformat import fmt
from std/sequtils import concat, apply, map, foldl, toSeq
from std/algorithm import sorted

type 
    MeshKind* = enum
        mkTriangular, mkSquared

    Mesh* = object
        kind*: MeshKind
        nodes*: seq[Point3D]
        edges*: seq[int]

proc newMesh*(kind: MeshKind, nodes: seq[Point3D], edges: seq[int]; transformation = IDENTITY): Mesh {.inline.} = 
    Mesh(kind: kind, nodes: if transformation.kind == tkIdentity: nodes else: nodes.map(proc(pt: Point3D): Point3D = apply(transformation, pt)), edges: edges)

proc newTriangularMesh*(nodes: seq[Point3D], edges: seq[int]; transformation = IDENTITY): Mesh {.inline.} = 
    assert edges.len mod 3 == 0, fmt"Error in creating a triangular Mesh! The length of the edges sequence must be a multiple of 3."
    newMesh(mkTriangular, nodes, edges, transformation)


iterator items*(mesh: Mesh): Shape =
    case mesh.kind
    of mkTriangular: 
        for i in 0..<(mesh.edges.len div 3): 
            yield newTriangle(mesh.nodes[mesh.edges[i * 3]], mesh.nodes[mesh.edges[i * 3 + 1]], mesh.nodes[mesh.edges[i * 3 + 2]])    

    of mkSquared: discard



type
    NodeKind* = enum
        nkLeaf, nkRoot

    SceneNode* = ref object
        aabb*: Interval[Point3D]
        
        case kind*: NodeKind
        of nkLeaf:
            shapes*: seq[Shape]
        of nkRoot:
            left*, right*: SceneNode

    SceneTreeKind* = enum
        stkBVH, stkKD

    SceneTree* = object
        kind*: SceneTreeKind
        root*: SceneNode

    Scene* = object
        shapes*: seq[Shape]
        meshes*: seq[Mesh]
        tree*: SceneTree
        bgCol*: Color

proc newScene*(shapes: seq[Shape] = @[], meshes: seq[Mesh] = @[], bgCol: Color = BLACK): Scene {.inline.} =
    Scene(shapes: shapes, meshes: meshes, bgCol: bgCol)


proc newBVHLeaf*(aabb: Interval[Point3D], shapes: seq[Shape]): SceneNode {.inline.} =
    SceneNode(kind: nkLeaf, aabb: aabb, shapes: shapes)

proc newBVHRoot*(aabb: Interval[Point3D], left, right: Option[SceneNode]): SceneNode {.inline.} =
    SceneNode(
        kind: nkRoot,
        aabb: aabb, 
        left: if left.isSome: left.get else: nil, 
        right: if right.isSome: right.get else: nil
    )


proc getWorldAABB*(shape: Shape): Interval[Point3D] {.inline.} =
    case shape.kind
    of skAABox, skTriangle, skCylinder: 
        return newAABB(shape.getTransformedVertices)

    of skSphere: 
        let center = apply(shape.transform, ORIGIN3D)
        let radiusPt = newVec3f(shape.radius, shape.radius, shape.radius)
        return newInterval(center - radiusPt, center + radiusPt)

    of skPlane: return newInterval(apply(shape.transform, newPoint3D(-Inf, -Inf, -Inf)), apply(shape.transform, newPoint3D(Inf, Inf, 0)))


proc getAABB*(shapes: openArray[Shape]): Interval[Point3D] =
    if shapes.len == 0: return (ORIGIN3D, ORIGIN3D)
    result = (min: newPoint3D(Inf, Inf, Inf), max: newPoint3D(-Inf, -Inf, -Inf))
    
    for shape in shapes:
        let aabb = shape.getWorldAABB
        result = newInterval(newInterval(aabb.min, result.min).min, newInterval(aabb.max, result.max).max)

proc getWorldAABox*(shape: Shape): Shape {.inline.} = newAABox(shape.getWorldAABB)


proc newBVHNode*(shapes: seq[Shape], maxShapesPerLeaf: int, depth: int): Option[SceneNode] =   
    if shapes.len == 0: return none SceneNode

    var node: SceneNode
    if shapes.len <= maxShapesPerLeaf: 
        node = newBVHLeaf(shapes.getAABB, shapes)
    else: 
        let 
            sortedShapes = shapes.sorted(proc(a, b: Shape): int = cmp(a.getWorldAABB.min.Vec3f[depth mod 3], b.getWorldAABB.min.Vec3f[depth mod 3]))
            leftNode =  newBVHNode(sortedShapes[0..<shapes.len div 2], maxShapesPerLeaf, depth + 1)
            rightNode = newBVHNode(sortedShapes[shapes.len div 2..<shapes.len], maxShapesPerLeaf, depth + 1)

        if leftNode.isNone and rightNode.isNone: return none SceneNode
        node = newBVHRoot(shapes.getAABB, leftNode, rightNode)

    some node


proc newBVHTree*(shapes: seq[Shape], mspl: int): SceneTree {.inline.} =
    SceneTree(kind: stkBVH, root: newBVHNode(shapes, maxShapesPerLeaf = mspl, depth = 0).get)


proc buildTree*(scene: var Scene, transform: Transformation, mspl: int = 4) =
    assert scene.shapes.len != 0 or scene.meshes.len != 0, fmt"Cannot build a SceneTree for an empty Scene."

    var totalShapes: seq[Shape]
    if scene.meshes.len == 0:
        totalShapes = scene.shapes 
    elif scene.shapes.len == 0:
        totalShapes = scene.meshes.map(proc(mesh: Mesh): seq[Shape] = mesh.items.toSeq).foldl(concat(a, b))
    else: 
        totalShapes = concat(scene.shapes, scene.meshes.map(proc(mesh: Mesh): seq[Shape] = mesh.items.toSeq).foldl(concat(a, b)))
    
    if transform.kind != tkIdentity:
        totalShapes.apply(proc(shape: Shape): Shape =
            result = shape; 
            # result.transform = newComposition(transform.inverse, shape.transform)
        )

    scene.tree = newBVHTree(totalShapes, mspl)


proc loadMesh*(world: Scene, source: string) = quit "to implement"
proc loadTexture*(world: Scene, source: string, shape: Shape) = quit "to implement"