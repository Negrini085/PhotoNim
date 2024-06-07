import std/unittest
import PhotoNim


suite "RefSystem":

    setup:
        let
            rs1 = newReferenceSystem(newPoint3D(0, 0, 0))
            rs2 = newReferenceSystem(newPoint3D(1, 3, 3), [eY, eX, eZ])
    
    teardown:
        discard rs1
        discard rs2

    # test "newRefSystem proc":
        
    #     var
    #         colSeq: seq[Vec3f]
    #         e1, e2, e3: Vec3f


    #     colSeq = columns(rs1.base).toSeq()
    #     (e1, e2, e3) = (colSeq[0], colSeq[1], colSeq[2])   
        
    #     check areClose(rs1.origin, newPoint3D(0, 0, 0))
    #     check areClose(e1, newVec3f(1, 0, 0))
    #     check areClose(e2, newVec3f(0, 1, 0))
    #     check areClose(e3, newVec3f(0, 0, 1))


    #     colSeq = columns(rs2.base).toSeq()
    #     (e1, e2, e3) = (colSeq[0], colSeq[1], colSeq[2])   

    #     check areClose(rs2.origin, newPoint3D(1, 3, 3))
    #     check areClose(e1, newVec3f(0, 1, 0))
    #     check areClose(e2, newVec3f(1, 0, 0))
    #     check areClose(e3, newVec3f(0, 0, 1))



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

# =======
#         check areClose(worldAABB1.min, newPoint3D(0, -2, 0))
#         check areClose(worldAABB1.max, newPoint3D(2, 3, 1))

#         check areClose(worldAABB2.min, newPoint3D(0, -2, 0))
#         check areClose(worldAABB2.max, newPoint3D(2, 3, 1))

#         check areClose(firstAABB.min, newPoint3D(3, -2, -1))
#         check areClose(firstAABB.max, newPoint3D(5, 3, 0))

#         check areClose(secondAABB.min, newPoint3D(-5, -2, 0))
#         check areClose(secondAABB.max, newPoint3D(-3, 3, 1))
        

#     test "getAABB proc":
#         let 
#             handler1 = (newTriangle(newPoint3D(0, -2, 0), newPoint3D(2, 1, 1), newPoint3D(0, 3, 0)), newTranslation([float32 1, 1, -2]))
#             handler2 = (newTriangle(newPoint3D(0, -2, 0), newPoint3D(2, 1, 1), newPoint3D(0, 3, 0)), IDENTITY)
#             worldRefSystem = newReferenceSystem(ORIGIN3D, stdONB)
#             firstRefSystem = newReferenceSystem(newPoint3D(5.0, 0.0, 0.0), newONB(-eX, eY, -eZ))
        
#             worldRefAABB = worldRefSystem.getAABB(@[handler1, handler2])
#             firstRefAABB = firstRefSystem.getAABB(@[handler1, handler2])

#         check areClose(worldRefAABB.min.Vec3f, newVec3f(0, -2, -2))
#         check areClose(worldRefAABB.max.Vec3f, newVec3f(3, 4, 1))

#         check areClose(firstRefAABB.min.Vec3f, newVec3f(2, -2, -1))
#         check areClose(firstRefAABB.max.Vec3f, newVec3f(5, 4, 2))
# >>>>>>> 7494311a94fe161f921b1250bd5afa995aa1844f
