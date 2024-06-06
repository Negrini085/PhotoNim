import geometry, hdrimage, camera, shapes

import std/options
from std/strformat import fmt
from std/sequtils import concat, apply, map, foldl, toSeq
from std/algorithm import sorted

type ReferenceSystem* = ref object
    origin*: Point3D
    base*: ONB

proc newReferenceSystem*(origin = ORIGIN3D, base = stdONB): ReferenceSystem {.inline.} = 
    ReferenceSystem(origin: origin, base: base)


type 
    ShapeHandler* = tuple[shape: Shape, transformation: Transformation]
    
    SceneNodeKind* = enum
        nkRoot, nkBranch, nkLeaf

    SceneNode* = ref object
        aabb*: Interval[Point3D]
        
        case kind*: SceneNodeKind
        of nkRoot, nkBranch:
            left*, right*: SceneNode
        of nkLeaf:
            handlers*: seq[ShapeHandler]

    Scene* = object
        bgCol*: Color
        handlers*: seq[ShapeHandler]


proc getWorldAABB*(handler: ShapeHandler): Interval[Point3D] {.inline.} =
    getAABB(handler.shape.getVertices.map(proc(vertex: Point3D): Point3D = apply(handler.transformation, vertex)))


proc getAABB*(refSystem: ReferenceSystem; handler: ShapeHandler): Interval[Point3D] {.inline.} =
    let localTransformation = newComposition(newTranslation(refSystem.origin.Vec3f).inverse, handler.transformation) 
    getAABB(
        handler.shape.getVertices
            .map(proc(vertex: Point3D): Point3D = 
                refSystem.base.getComponents(
                    apply(localTransformation, vertex).Vec3f
                ).Point3D
            )
    )         

proc getAABB*(refSystem: ReferenceSystem; shapeHandlers: seq[ShapeHandler]): Interval[Point3D] =
    if shapeHandlers.len == 0: return (refSystem.origin, refSystem.origin)

    result = (min: newPoint3D(Inf, Inf, Inf), max: newPoint3D(-Inf, -Inf, -Inf))
    for i in 0..<shapeHandlers.len:
        let aabb = refSystem.getAABB(shapeHandlers[i])
        result = newInterval(newInterval(aabb.min, result.min).min, newInterval(aabb.max, result.max).max)


proc newBVHNode(refSystem: ReferenceSystem, shapeHandlers: seq[ShapeHandler], maxShapesPerLeaf, depth: int): SceneNode =   
    if shapeHandlers.len == 0: return nil

    let aabb = refSystem.getAABB(shapeHandlers)

    if shapeHandlers.len <= maxShapesPerLeaf: 
        return SceneNode(kind: nkLeaf, aabb: aabb, handlers: shapeHandlers)

    let 
        sortedShapes = shapeHandlers.sorted(proc(a, b: ShapeHandler): int = cmp(refSystem.getAABB(a).min.x, refSystem.getAABB(b).min.x))
        leftNode =  newBVHNode(refSystem, sortedShapes[0..<sortedShapes.len div 2], maxShapesPerLeaf, depth + 1)
        rightNode = newBVHNode(refSystem, sortedShapes[sortedShapes.len div 2..<sortedShapes.len], maxShapesPerLeaf, depth + 1)
    
    SceneNode(
        kind: nkBranch,
        aabb: aabb, 
        left: leftNode, 
        right: rightNode
    )


proc buildSceneTree*(refSystem: ReferenceSystem; scene: Scene, maxShapesPerLeaf: int): SceneNode =  
    result = newBVHNode(refSystem, scene.handlers.map(), maxShapesPerLeaf, depth = 0)
    result.kind = nkRoot

proc newScene*(shapeHandlers: seq[ShapeHandler], bgCol: Color = BLACK): Scene {.inline.} = 
    Scene(bgCol: bgCol, handlers: shapeHandlers)


proc loadMesh*(world: Scene, source: string) = quit "to implement"
proc loadTexture*(world: Scene, source: string, shape: Shape) = quit "to implement"


proc newSphere*(center: Point3D, radius: float32; material = newMaterial()): ShapeHandler {.inline.} =   
    (shape: newSphere(radius, material), transformation: if center != ORIGIN3D: newTranslation(center.Vec3f) else: IDENTITY)

proc newUnitarySphere*(center: Point3D; material = newMaterial()): ShapeHandler {.inline.} = 
    (shape: newSphere(1.0, material), transformation: if center != ORIGIN3D: newTranslation(center.Vec3f) else: IDENTITY)