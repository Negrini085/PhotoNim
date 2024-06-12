import geometry, hdrimage, shapes

from std/sequtils import concat, apply, map, foldl, toSeq
from std/algorithm import sorted


type ShapeHandler* = tuple[shape: Shape, transformation: Transformation]
    
proc getAABB*(handler: ShapeHandler): Interval[Point3D] {.inline.} =
    getAABB(handler.shape.getVertices.map(proc(v: Point3D): Point3D = apply(handler.transformation, v)))

proc getAABB*(refSystem: ReferenceSystem, handler: ShapeHandler): Interval[Point3D] {.inline.} =
    let 
        localTransformation = newComposition(handler.transformation, newTranslation(refSystem.origin).inverse)
    getAABB(handler.shape.getVertices.
                map(proc(v: Point3D): Point3D = apply(localTransformation, v)).
                map(proc(v: Point3D): Point3D = refSystem.coeff(v.Vec3f).Point3D)
            )


type
    SceneNodeKind* = enum nkBranch, nkLeaf
    BVHStrategy* = enum skMedian, skSAH

    SceneNode* = ref object
        aabb*: Interval[Point3D]
        
        case kind*: SceneNodeKind
        of nkBranch:
            left*, right*: SceneNode
        of nkLeaf:
            handlers*: seq[ShapeHandler]

    Scene* = object
        bgCol*: Color
        handlers*: seq[ShapeHandler]
        tree*: SceneNode = nil


proc newBVHNode(refSystem: ReferenceSystem, shapeHandlers: seq[ShapeHandler], maxShapesPerLeaf, depth: int, strategy: BVHStrategy): SceneNode =   
    if shapeHandlers.len == 0: return nil

    var aabb = (min: newPoint3D(Inf, Inf, Inf), max: newPoint3D(-Inf, -Inf, -Inf))
    let handlersAABB = shapeHandlers.map(proc(handler: ShapeHandler): Interval[Point3D] = refSystem.getAABB(handler))
    for box in handlersAABB.items: aabb = newInterval(newInterval(box.min, aabb.min).min, newInterval(box.max, aabb.max).max)

    if shapeHandlers.len <= maxShapesPerLeaf: return SceneNode(kind: nkLeaf, aabb: aabb, handlers: shapeHandlers)

    let
        sortedShapes = shapeHandlers.sorted(proc(a, b: ShapeHandler): int = cmp(a.getAABB.min.x, b.getAABB.min.x))
        leftNode = refSystem.newBVHNode(sortedShapes[0..<sortedShapes.len div 2], maxShapesPerLeaf, depth + 1, strategy)
        rightNode = refSystem.newBVHNode(sortedShapes[sortedShapes.len div 2..<sortedShapes.len], maxShapesPerLeaf, depth + 1, strategy)
    
    SceneNode(kind: nkBranch, aabb: aabb, left: leftNode, right: rightNode)


proc newScene*(shapeHandlers: seq[ShapeHandler], bgCol: Color = BLACK): Scene {.inline.} = 
    Scene(bgCol: bgCol, handlers: shapeHandlers)

proc fromObserver*(scene: Scene; refSystem: ReferenceSystem, maxShapesPerLeaf: int): Scene =

    Scene(
        bgCol: scene.bgCol, 
        handlers: scene.handlers,
        tree: newBVHNode(refSystem, scene.handlers, maxShapesPerLeaf, depth = 0, skSAH)
    )


proc loadMesh*(world: Scene, source: string) = quit "to implement"
proc loadTexture*(world: Scene, source: string, shape: Shape) = quit "to implement"


proc newShapeHandler*(shape: Shape, transformation = Transformation.id): ShapeHandler {.inline.} =
    (shape: shape, transformation: transformation)

proc newSphere*(center: Point3D, radius: float32; material = newMaterial()): ShapeHandler {.inline.} =   
    newShapeHandler(newSphere(radius, material), if center != ORIGIN3D: newTranslation(center) else: Transformation.id)

proc newUnitarySphere*(center: Point3D; material = newMaterial()): ShapeHandler {.inline.} = 
    newShapeHandler(newSphere(1.0, material), if center != ORIGIN3D: newTranslation(center) else: Transformation.id)

proc newPlane*(material = newMaterial(), transformation = Transformation.id): ShapeHandler {.inline.} = 
    newShapeHandler(Shape(kind: skPlane, material: material), transformation)