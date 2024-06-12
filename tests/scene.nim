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
        check areClose(appo.min, newPoint3D(-1, 0, -1), eps = 1e-6)
        check areClose(appo.max, newPoint3D(0, 1, 0), eps = 1e-6)
        
        appo = sdr2.getAABB(usphand)
        check areClose(appo.min, newPoint3D(-1, -1, -1), eps = 1e-6)
        check areClose(appo.max, newPoint3D(1, 1, 1), eps = 1e-6)
        
        appo = sdr2.getAABB(sphand)
        check areClose(appo.min, newPoint3D(-3, -5, -2), eps = 1e-6)
        check areClose(appo.max, newPoint3D(3, 1, 4), eps = 1e-6)

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



#---------------------------------------#
#           Scene test suite            #
#---------------------------------------#
suite "Scene":

    setup:
        let 
            triangle = newTriangle(newPoint3D(0, -2, 0), newPoint3D(2, 1, 1), newPoint3D(0, 3, 0))
            sc1 = newScene(@[newShapeHandler(triangle), newShapeHandler(triangle, newTranslation([float32 1, 1, -2]))])
            sc2 = newScene(@[newSphere(ORIGIN3D, 3), newUnitarySphere(newPoint3D(4, 4, 4))], newColor(1, 0.3, 0.7))
            sc3 = newScene(@[newUnitarySphere(newPoint3D(3, 3, 3)), newShapeHandler(triangle)])
    
    teardown:
        discard triangle
        discard sc1
        discard sc2

    
    test "newScene proc":
        # Checking newScene proc

        # First scene --> only triangles
        check sc1.bgCol == BLACK
        check sc1.handlers.len == 2
        check sc1.handlers[0].shape.kind == skTriangle and sc1.handlers[1].shape.kind == skTriangle
        check areClose(sc1.handlers[0].shape.vertices[0], newPoint3D(0, -2, 0))
        check areClose(apply(sc1.handlers[1].transformation, sc1.handlers[1].shape.vertices[0]), newPoint3D(1, -1, -2))
        check sc1.tree.isNil

        # Second scene --> only Spheres
        check sc2.bgCol == newColor(1, 0.3, 0.7)
        check sc2.handlers.len == 2
        check sc2.handlers[0].shape.kind == skSphere and sc2.handlers[1].shape.kind == skSphere
        check areClose(sc2.handlers[0].shape.radius, 3)
        check areClose(sc2.handlers[1].shape.radius, 1)
        check areClose(apply(sc2.handlers[0].transformation, ORIGIN3D), ORIGIN3D)
        check areClose(apply(sc2.handlers[1].transformation, ORIGIN3D), newPoint3D(4, 4, 4))
        check sc2.tree.isNil

        # Third scene --> one Sphere and one Triangle
        # Checking newScene proc
        check sc3.bgCol == BLACK
        check sc3.handlers.len == 2
        check sc3.handlers[0].shape.kind == skSphere and sc3.handlers[1].shape.kind == skTriangle
        check areClose(sc3.handlers[0].shape.radius, 1)
        check areClose(apply(sc3.handlers[0].transformation, ORIGIN3D), newPoint3D(3, 3, 3))
        check areClose(sc3.handlers[1].shape.vertices[0], newPoint3D(0, -2, 0))
        check sc3.tree.isNil


    test "fromObserver proc":
        var 
            rs = newReferenceSystem(newPoint3D(5, 3, 1), [-eX, eY, -eZ])
            subScene: Scene

        # First scene, only triangles
        subScene = sc1.fromObserver(rs, maxShapesPerLeaf = 2)
        
        check subScene.bgCol == BLACK
        check not subScene.tree.isNil

        check areClose(subScene.tree.aabb.min, newPoint3D(2, -5, 0))
        check areClose(subScene.tree.aabb.max, newPoint3D(5, 1, 3))


        # Second scene, only spheres
        subscene = sc2.fromObserver(rs, maxShapesPerLeaf = 2)

        check subScene.bgCol == newColor(1, 0.3, 0.7)
        check not subScene.tree.isNil

        check areClose(subScene.tree.aabb.min, newPoint3D(0, -6, -4))
        check areClose(subScene.tree.aabb.max, newPoint3D(8, 2, 4))


        # Third scene, one sphere and one triangle
        subscene = sc3.fromObserver(rs, maxShapesPerLeaf = 2)

        check subScene.bgCol == BLACK
        check not subScene.tree.isNil

        check areClose(subScene.tree.aabb.min, newPoint3D(1, -5, -3))
        check areClose(subScene.tree.aabb.max, newPoint3D(5, 1, 1))
