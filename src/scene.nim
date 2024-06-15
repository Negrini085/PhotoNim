import geometry, hdrimage, shapes

from std/sequtils import concat, foldl, toSeq, filterIt, mapIt
from std/algorithm import sorted


type ShapeHandler* = tuple[shape: Shape, transformation: Transformation]
    
proc getAABB*(handler: ShapeHandler): Interval[Point3D] {.inline.} =
    getAABB(handler.shape.getVertices.mapIt(apply(handler.transformation, it)))

proc getLocalAABB*(refSystem: ReferenceSystem, handler: ShapeHandler): Interval[Point3D] {.inline.} =
    getAABB(handler.shape.getVertices.mapIt(refSystem.project(apply(handler.transformation, it))))


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
            left*, right*: SceneNode
        of nkLeaf:
            handlers*: seq[ShapeHandler]

    Scene* = tuple[bgCol: Color, handlers: seq[ShapeHandler]]

    SubScene* = tuple[rs: ReferenceSystem, tree: SceneNode]


proc newBVHNode(shapeHandlers: seq[ShapeHandler], localAABBs: seq[Interval[Point3D]], totalAABB: Interval[Point3D], depth, maxShapesPerLeaf: int, strategy: BVHStrategy): SceneNode =   
    if shapeHandlers.len == 0: return nil
    if shapeHandlers.len <= maxShapesPerLeaf: return SceneNode(kind: nkLeaf, aabb: totalAABB, handlers: shapeHandlers)

    let   
        sortedIndexes = countup(0, shapeHandlers.len - 1).toSeq
            .sorted(proc(a, b: int): int = cmp(localAABBs[a].min.Vec3f[depth mod 3], localAABBs[b].min.Vec3f[depth mod 3]))
    
        sortedHandlers = sortedIndexes.mapIt(shapeHandlers[it])
        sortedAABBs = sortedIndexes.mapIt(localAABBs[it])

        mid = sortedIndexes.len div 2
        (handlersLeft, handlersRight) = (sortedHandlers[0..<mid], sortedHandlers[mid..<sortedIndexes.len])
        (localAABBsLeft, localAABBsRight) = (sortedAABBs[0..<mid], sortedAABBs[mid..<sortedIndexes.len])

        leftNode = newBVHNode(handlersLeft, localAABBsLeft, localAABBsLeft.getTotalAABB, maxShapesPerLeaf, depth + 1, strategy)
        rightNode = newBVHNode(handlersRight, localAABBsRight, localAABBsRight.getTotalAABB, maxShapesPerLeaf, depth + 1, strategy)
    
    SceneNode(kind: nkBranch, aabb: totalAABB, left: leftNode, right: rightNode)


proc newScene*(shapeHandlers: seq[ShapeHandler], bgCol: Color = BLACK): Scene {.inline.} = (bgCol, shapeHandlers)

proc fromObserver*(scene: Scene; refSystem: ReferenceSystem, maxShapesPerLeaf: int): SubScene =
    let localAABBs = scene.handlers.mapIt(refSystem.getLocalAABB(it))
    (refSystem, newBVHNode(scene.handlers, localAABBs, localAABBs.getTotalAABB, depth = 0, maxShapesPerLeaf, skSAH))


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

proc newBox*(aabb: Interval[Point3D], material = newMaterial(), transformation = Transformation.id): ShapeHandler {.inline.} =
    newShapeHandler(Shape(kind: skAABox, aabb: aabb, material: material), transformation)