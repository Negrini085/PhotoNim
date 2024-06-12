import std/unittest
import PhotoNim


suite "ShapeHandler":
    
    setup:
        var 
            shand = newShapeHandler(
                newTriangle(newPoint3D(1, 0, 0), newPoint3D(0, 1, 0), newPoint3D(0, 0, 1)),
                Transformation.id
                )
            usphand = newUnitarySphere(newPoint3D(1, 1, 1))
            sphand = newSphere(newPoint3D(1, 2, 3), 3)
            plhand = newPlane(transformation = newRotZ(45))

    teardown:
        discard shand
        discard usphand
        discard sphand
        discard plhand


    test "ShapeHandler constructor procs":
        # Checking different new procs
        
        # newShapeHandler proc
        check shand.shape.kind == skTriangle
        check areClose(shand.shape.vertices[0], newPoint3D(1, 0, 0))
        check areClose(shand.shape.vertices[1], newPoint3D(0, 1, 0))
        check areClose(shand.shape.vertices[2], newPoint3D(0, 0, 1))
        check shand.transformation.kind == tkIdentity

        # newUnitarySphere proc
        check usphand.shape.kind == skSphere
        check areClose(usphand.shape.radius, 1)
        check usphand.transformation.kind == tkTranslation
        check areClose(usphand.transformation.mat, newTranslation(newVec3f(1, 1, 1)).mat)

        # newSphere proc
        check sphand.shape.kind == skSphere
        check areClose(sphand.shape.radius, 3)
        check sphand.transformation.kind == tkTranslation
        check areClose(sphand.transformation.mat, newTranslation(newVec3f(1, 2, 3)).mat)

        # newPlane proc
        check plhand.shape.kind == skPlane
        check areClose(plhand.transformation.mat, newRotZ(45).mat, eps = 1e-6)


    test "getAABB proc (no ReferenceSystem)":
        # Checking AABB in World frame of reference
        var appo: Interval[Point3D]

        appo = getAABB(shand)
        check areClose(appo.min, ORIGIN3D)
        check areClose(appo.max, newPoint3D(1, 1, 1))
        
        appo = getAABB(usphand)
        check areClose(appo.min, ORIGIN3D)
        check areClose(appo.max, newPoint3D(2, 2, 2))
        
        appo = getAABB(sphand)
        check areClose(appo.min, newPoint3D(-2, -1, 0))
        check areClose(appo.max, newPoint3D(4, 5, 6))


    test "getAABB proc (with ReferenceSystem)":
        # Checking AABB in generic reference system
        var
            sdr1 = newReferenceSystem(newPoint3D(0, 0, 0), [eX, eY, eZ])
            sdr2 = newReferenceSystem(newPoint3D(1, 1, 1), [eX, -eZ, eY])
            sdr3 = newReferenceSystem(newPoint3D(1, 1, 1), [eX, eY, eZ])
            appo: Interval[Point3D]

        #----------------------------------#
        #      World reference system      #
        #----------------------------------# 
        appo = sdr1.getAABB(shand)
        check areClose(appo.min, ORIGIN3D)
        check areClose(appo.max, newPoint3D(1, 1, 1))
        
        appo = sdr1.getAABB(usphand)
        check areClose(appo.min, ORIGIN3D)
        check areClose(appo.max, newPoint3D(2, 2, 2))
        
        appo = sdr1.getAABB(sphand)
        check areClose(appo.min, newPoint3D(-2, -1, 0))
        check areClose(appo.max, newPoint3D(4, 5, 6))


        #---------------------------------#
        #    Specific reference system    #
        #---------------------------------#
        appo = sdr2.getAABB(shand)
        echo appo.min
        echo appo.max
        
        appo = sdr2.getAABB(usphand)
        echo appo.min
        echo appo.max        
        
        appo = sdr2.getAABB(sphand)
        echo appo.min
        echo appo.max


        #---------------------------------#
        #    Specific reference system    #
        #---------------------------------# 
        appo = sdr3.getAABB(shand)
        check areClose(appo.min, newPoint3D(-1, -1, -1))
        check areClose(appo.max, ORIGIN3D)
        
        appo = sdr3.getAABB(usphand)
        check areClose(appo.min, newPoint3D(-1, -1, -1))
        check areClose(appo.max, newPoint3D(1, 1, 1))
        
        appo = sdr3.getAABB(sphand)
        check areClose(appo.min, newPoint3D(-3, -2, -1))
        check areClose(appo.max, newPoint3D(3, 4, 5))



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
        check scene.handlers[0].shape.kind == skTriangle and scene.handlers[1].shape.kind == skTriangle
        check scene.tree.isNil

    # test "getTotalAABB proc":
    #     let aabb = scene.handlers.getTotalAABB

    #     check aabb.min == newPoint3D(0, -2, -2)
    #     check aabb.max == newPoint3D(3, 4, 1)
        
    test "fromObserver proc":
        var subScene = scene.fromObserver(newReferenceSystem(newPoint3D(5.0, 0.0, 0.0), [-eX, eY, -eZ]), maxShapesPerLeaf = 2)

        check subScene.bgCol == BLACK

        check subScene.handlers.len == 2
        check subScene.handlers[0].shape.kind == skTriangle and subScene.handlers[1].shape.kind == skTriangle

        check subScene.handlers[0].transformation != scene.handlers[0].transformation
        check subScene.handlers[1].transformation != scene.handlers[1].transformation

    
    test "buildBVHTree proc":
        var subScene = scene.fromObserver(newReferenceSystem(newPoint3D(5.0, 0.0, 0.0)), 1)
        check not subScene.tree.isNil

        check subScene.tree.aabb.min == newPoint3D(-5, -2, -2)
        check subScene.tree.aabb.max == newPoint3D(-2, 4, 1)

        # subScene = scene.fromObserver(newReferenceSystem(newPoint3D(5.0, 0.0, 0.0), [-eX, eY, -eZ]), 1)

        # check subScene.tree.aabb.min == newPoint3D(2, -2, -1)
        # check subScene.tree.aabb.max == newPoint3D(5, 4, 2)

        


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