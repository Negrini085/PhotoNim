import geometry, shapes

from std/algorithm import sorted


type
    SceneNode* = ref object
        aabb*: AABB
        left*, right*: SceneNode
        shapes*: seq[Shape]
        isLeaf*: bool

    SceneTree* = object
        root*: SceneNode


proc newBVHNode(shapes: seq[Shape], maxShapesPerLeaf: int, depth: int): SceneNode =   
    if shapes.len == 0: return nil

    new(result)
    result.aabb = newAABB(shapes)

    if shapes.len <= maxShapesPerLeaf:
        result.shapes = shapes
        result.isLeaf = true
    else:
        let sortedShapes = shapes.sorted(proc(a, b: Shape): int = cmp(a.getWorldAABB.min.Vec3f[depth mod 3], b.getWorldAABB.min.Vec3f[depth mod 3]))
        result.left = newBVHNode(sortedShapes[0..<shapes.len div 2], maxShapesPerLeaf, depth + 1)
        result.right = newBVHNode(sortedShapes[shapes.len div 2..<shapes.len], maxShapesPerLeaf, depth + 1)
        result.isLeaf = false


proc newSceneTree*(shapes: seq[Shape], mspl: int = 4): SceneTree {.inline.} =
    SceneTree(root: newBVHNode(shapes, maxShapesPerLeaf = mspl, depth = 0))