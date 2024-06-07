import geometry, hdrimage, shapes

from std/sequtils import concat, apply, map, foldl, toSeq
from std/algorithm import sorted
from std/math import copySign


type ReferenceSystem* = tuple[origin: Point3D, base: Mat3f]

proc newReferenceSystem*(origin: Point3D, base = Mat3f.id): ReferenceSystem {.inline.} = (origin, base)

proc newONB(normal: Normal): Mat3f = 
    let
        sign = copySign(1.0, normal.z)
        a = -1.0 / (sign + normal.z)
        b = a * normal.x * normal.y

    [
        newVec3f(1.0 + sign * a * normal.x * normal.x, sign * b, -sign * normal.x),
        newVec3f(b, sign + a * normal.y * normal.y, -normal.y), 
        normal.Vec3f
    ]

proc newReferenceSystem*(origin: Point3D, normal: Normal): ReferenceSystem {.inline.} = (origin, newONB(normal)) 

proc coeff*(refSystem: ReferenceSystem, pt: Vec3f): Vec3f {.inline.} = dot(refSystem.base, pt)
proc fromCoeff*(refSystem: ReferenceSystem, coeff: Vec3f): Vec3f {.inline.} = dot(refSystem.base.T, coeff)


type ShapeHandler* = tuple[shape: Shape, transformation: Transformation]
    
proc getAABB*(handler: ShapeHandler): Interval[Point3D] {.inline.} =
    # This assumes the handler is in the local reference system
    getAABB(handler.shape.getVertices.map(proc(v: Point3D): Point3D = apply(handler.transformation, v)))

proc getAABB*(refSystem: ReferenceSystem, handler: ShapeHandler): Interval[Point3D] {.inline.} =
    # This assumes the handler is in the global reference system and the function must return the aabb from the handler in the local reference system,
    # so we need to use the complete transformation, not just the translation!
    let transformation = newComposition(newTranslation(refSystem.origin).inverse, handler.transformation) 
    getAABB(handler.shape.getVertices.map(proc(v: Point3D): Point3D = refSystem.coeff(apply(transformation, v).Vec3f).Point3D))

proc getTotalAABB*(shapeHandlers: seq[ShapeHandler]): Interval[Point3D] =
    # This assumes the handlers are in the local reference system
    if shapeHandlers.len == 0: return (ORIGIN3D, ORIGIN3D)

    result = (min: newPoint3D(Inf, Inf, Inf), max: newPoint3D(-Inf, -Inf, -Inf))

    var aabb: Interval[Point3D]
    for i in 0..<shapeHandlers.len:
        aabb = shapeHandlers[i].getAABB
        result = newInterval(newInterval(aabb.min, result.min).min, newInterval(aabb.max, result.max).max)


type
    SceneNodeKind* = enum nkBranch, nkLeaf

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
        rs*: ReferenceSystem = newReferenceSystem(ORIGIN3D) # maybe this is not useful to store
        tree*: SceneNode = nil


proc newScene*(shapeHandlers: seq[ShapeHandler], bgCol: Color = BLACK): Scene {.inline.} = Scene(bgCol: bgCol, handlers: shapeHandlers)

proc fromObserver*(scene: Scene; refSystem: ReferenceSystem): Scene =
    let ## here we need to use the complete transformation, not just the translation!
        localTransformation = newTranslation(refSystem.origin)
        localShapeHandlers = scene.handlers.map(proc(handler: ShapeHandler): ShapeHandler = 
            (shape: handler.shape, transformation: newComposition(localTransformation.inverse, handler.transformation))
        ) # these must be local shapeHandlers! 

    Scene(bgCol: scene.bgCol, handlers: localShapeHandlers, rs: refSystem)


type BVHStrategy* = enum skMedian, skSAH

proc newBVHNode(shapeHandlers: seq[ShapeHandler], maxShapesPerLeaf, depth: int, strategy: BVHStrategy): SceneNode =   
    if shapeHandlers.len == 0: return nil

    let aabb = shapeHandlers.getTotalAABB

    if shapeHandlers.len <= maxShapesPerLeaf: return SceneNode(kind: nkLeaf, aabb: aabb, handlers: shapeHandlers)

    let 
        sortedShapes = shapeHandlers.sorted(
            proc(a, b: ShapeHandler): int =
                cmp(a.getAABB.min.Vec3f[depth mod 3], b.getAABB.min.Vec3f[depth mod 3]) # here something is wrong
        )
        leftNode = newBVHNode(sortedShapes[0..<sortedShapes.len div 2], maxShapesPerLeaf, depth + 1, strategy)
        rightNode = newBVHNode(sortedShapes[sortedShapes.len div 2..<sortedShapes.len], maxShapesPerLeaf, depth + 1, strategy)
    
    SceneNode(kind: nkBranch, aabb: aabb, left: leftNode, right: rightNode)

proc buildBVHTree*(scene: var Scene; maxShapesPerLeaf: int, strategy: BVHStrategy) {.inline.} = 
    # Scene.handlers is always referred from the local reference system
    scene.tree = newBVHNode(scene.handlers, maxShapesPerLeaf, depth = 0, strategy)


proc loadMesh*(world: Scene, source: string) = quit "to implement"
proc loadTexture*(world: Scene, source: string, shape: Shape) = quit "to implement"


proc newShapeHandler*(shape: Shape, transformation = Transformation.id): ShapeHandler {.inline.} =
    (shape: shape, transformation: transformation)

proc newSphere*(center: Point3D, radius: float32; material = newMaterial()): ShapeHandler {.inline.} =   
    newShapeHandler(newSphere(radius, material), if center != ORIGIN3D: newTranslation(center) else: Transformation.id)

proc newUnitarySphere*(center: Point3D; material = newMaterial()): ShapeHandler {.inline.} = 
    newShapeHandler(newSphere(1.0, material), if center != ORIGIN3D: newTranslation(center) else: Transformation.id)