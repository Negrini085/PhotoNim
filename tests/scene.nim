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


        