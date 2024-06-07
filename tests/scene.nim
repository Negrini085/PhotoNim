import std/[unittest, sequtils]
import PhotoNim

suite "Scene unittest":
    setup:
        let 
            triangle = newTriangle(newPoint3D(0, -2, 0), newPoint3D(2, 1, 1), newPoint3D(0, 3, 0))
            scene = newScene(@[newShapeHandler(triangle), newShapeHandler(triangle, newTranslation([float32 1, 1, -2]))])

    test "newScene proc":
        check scene.bgCol == BLACK

        check scene.handlers.len == 2
        check scene.handlers[0].shape.kind == skTriangle
        check scene.handlers[1].shape.kind == skTriangle

        check scene.tree.isNil

    test "getTotalAABB proc":
        let aabb = scene.handlers.getTotalAABB

        check aabb.min == newPoint3D(0, -2, -2)
        check aabb.max == newPoint3D(3, 4, 1)
        
    test "fromObserver proc":
        var subScene = scene.fromObserver(newReferenceSystem(newPoint3D(5.0, 0.0, 0.0), [-eX, eY, -eZ]))

        check subScene.bgCol == BLACK

        check subScene.handlers.len == 2
        check scene.handlers[0].shape.kind == skTriangle
        check scene.handlers[1].shape.kind == skTriangle

    
    test "buildBVHTree proc":
        var subScene = scene.fromObserver(newReferenceSystem(newPoint3D(5.0, 0.0, 0.0), [-eX, eY, -eZ]))

        check subScene.tree.isNil
        subScene.buildBVHTree(maxShapesPerLeaf = 4, skSAH)
        check not subScene.tree.isNil

        check subScene.tree.aabb.min == newPoint3D(2, -2, -1)
        check subScene.tree.aabb.max == newPoint3D(5, 4, 2)