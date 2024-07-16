import std/unittest
import ../src/[geometry, scene, ray, shape, brdf, pigment, color]

from std/math import PI

#---------------------------#
#    Ray type test suite    #
#---------------------------#
suite "Ray":

    setup:
        var 
            ray1 = newRay(newPoint3D(1, 2, 3), newVec3(1, 0, 0))
            ray2 = newRay(newPoint3D(1, 2, 0), newVec3(1, 0, 0))
    
    teardown:
        discard ray1
        discard ray2


    test "newRay proc":
        #Checking newRay proc

        # First ray check
        check ray1.depth == 0.int
        check areClose(ray1.dir, newVec3(1, 0, 0))
        check areClose(ray1.origin, newPoint3D(1, 2, 3))

        # Second ray check
        check ray2.depth == 0.int
        check areClose(ray2.dir, newVec3(1, 0, 0))
        check areClose(ray2.origin, newPoint3D(1, 2, 0))
    

    test "at proc":
        # Checkin at proc, gives ray position at a certain time

        # First ray check
        check areClose(ray1.at(0), ray1.origin)
        check areClose(ray1.at(1.0), newPoint3D(2, 2, 3))
        check areClose(ray1.at(2.0), newPoint3D(3, 2, 3))

        # Second ray check
        check areClose(ray2.at(0), ray2.origin)
        check areClose(ray2.at(1.0), newPoint3D(2, 2, 0))
        check areClose(ray2.at(2.0), newPoint3D(3, 2, 0))


    test "areClose proc":
        # Checking areClose proc, which states wether two rays are similar or not

        check areClose(ray1, ray1)
        check not areClose(ray1, ray2)


    test "transform proc":
        # Checking transform proc, which transform ray in a specific frame of reference
        var 
            T1 = newTranslation(newVec3(1, 2, 3))
            T2 = newRotation(180.0, axisY)

        # First ray
        check areClose(ray1.transform(T1), newRay(newPoint3D(2, 4, 6), newVec3(1, 0, 0)))
        check areClose(ray1.transform(T2), newRay(newPoint3D(-1, 2, -3), newVec3(-1, 0, 0)), 1e-6)

        # Second ray
        check areClose(ray2.transform(T1), newRay(newPoint3D(2, 4, 3), newVec3(1, 0, 0)))
        check areClose(ray2.transform(T2), newRay(newPoint3D(-1, 2, 0), newVec3(-1, 0, 0)), 1e-6)


    test "getBoxHit proc":
        # Checking getBoxHit procedure, to compute hit time
        # with aabb in world frame reference system
        let
            aabb1 = (newPoint3D(-1,-3,-2), newPoint3D( 1, 5, 2))
            aabb2 = (newPoint3D(-2,-1,-2), newPoint3D( 1, 3, 0))

        ray1 = newRay(ORIGIN3D, eX)
        ray2 = newRay(newPoint3D(0,-4,-1), eY)

        check areClose(ray1.getBoxHit(aabb1), 1)
        check areClose(ray1.getBoxHit(aabb2), 1)

        check areClose(ray2.getBoxHit(aabb1), 1)
        check areClose(ray2.getBoxHit(aabb2), 3)



#-----------------------------#
#     ShapeHit test suite     #
#-----------------------------#
suite "ShapeHit":
    # ShapeHit test suite, here we want to make sure that
    # everything is good in intersection evaluation between a ray and a shape

    setup:
        var
            t: float32

    teardown:
        discard t


    test "Sphere":
        # Checking getShapeHit for a ray-sphere intersection.
        # Here we need to assure that time computation is indeed correct.
        
        let 
            usphere = newUnitarySphere(
                    ORIGIN3D, 
                    newDiffuseBRDF(newUniformPigment(WHITE))
                )
            sphere = newSphere(
                    newPoint3D(0, 1, 0), 3.0, 
                    newDiffuseBRDF(newUniformPigment(WHITE))
                )

        var
            ray1 = newRay(newPoint3D(0, 0, 2), -eZ)
            ray2 = newRay(newPoint3D(3, 0, 0), -eX)
            ray3 = newRay(ORIGIN3D, eX)

        
        # Unitary sphere
        t = ray1.transform(usphere.transformation.inverse).getShapeHit(usphere.shape)
        check areClose(t, 1)

        t = ray2.transform(usphere.transformation.inverse).getShapeHit(usphere.shape)
        check areClose(t, 2)

        t = ray3.transform(usphere.transformation.inverse).getShapeHit(usphere.shape)
        check areClose(t, 1)    

        # Generic sphere
        ray1.origin = newPoint3D(0, 1, 5)
        ray2.origin = newPoint3D(4, 1, 0)
        ray3.origin = newPoint3D(1, 1, 0)

        t = ray1.transform(sphere.transformation.inverse).getShapeHit(sphere.shape)
        check areClose(t, 2)

        t = ray2.transform(sphere.transformation.inverse).getShapeHit(sphere.shape)
        check areClose(t, 1)

        t = ray3.transform(sphere.transformation.inverse).getShapeHit(sphere.shape)
        check areClose(t, 2)    


    test "Plane":
        # Checking getShapeHit for a ray-plane intersection.
        # Here we need to assure that time computation is indeed correct.

        let plane = newPlane(newDiffuseBRDF(newUniformPigment(WHITE)))

        var
            ray1 = newRay(newPoint3D(0, 0, 2), -eZ)
            ray2 = newRay(newPoint3D(1,-2,-3), newVec3(0.0, 4/5, 3/5))
            ray3 = newRay(newPoint3D(3, 0, 0), -eX)

        
        t = ray1.transform(plane.transformation.inverse).getShapeHit(plane.shape)
        check areClose(t, 2)

        t = ray2.transform(plane.transformation.inverse).getShapeHit(plane.shape)
        check areClose(t, 5)

        t = ray3.transform(plane.transformation.inverse).getShapeHit(plane.shape)
        check t == Inf


    test "Box":
        # Checking getShapeHit for a ray-box intersection.
        # Here we need to assure that time computation is indeed correct.

        let box = newBox(
            (newPoint3D(-1, 0, 1), newPoint3D(3, 2, 5)),
            newDiffuseBRDF(newUniformPigment(BLACK))
            )

        var
            ray1 = newRay(newPoint3D(-5, 1, 2), eX)
            ray2 = newRay(newPoint3D(1, -2, 3), eY)
            ray3 = newRay(newPoint3D(4, 1, 0), newVec3(-1, 0, 0))

          
        t = ray1.transform(box.transformation.inverse).getShapeHit(box.shape)
        check areClose(t, 4)

        t = ray2.transform(box.transformation.inverse).getShapeHit(box.shape)
        check areClose(t, 2)

        t = ray3.transform(box.transformation.inverse).getShapeHit(box.shape) 
        check t == Inf


    test "Triangle":
        # Checking getShapeHit for a ray-triangle intersection.
        # Here we need to assure that time computation is indeed correct.

        let triangle = newTriangle(
                [newPoint3D(3, 0, 0), newPoint3D(-2, 0, 0), newPoint3D(0.5, 2, 0)],
                newDiffuseBRDF(newUniformPigment(WHITE))
            )

        var
            ray1 = newRay(newPoint3D(0, 1, -2), eZ)
            ray2 = newRay(newPoint3D(0, 1, -2), eX)

        t = ray1.transform(triangle.transformation.inverse).getShapeHit(triangle.shape)
        check areClose(t, 2)

        t = ray2.transform(triangle.transformation.inverse).getShapeHit(triangle.shape)
        check t == Inf


    test "Cylinder":
        # Checking getShapeHit for a ray-cylinder intersection.
        # Here we need to assure that time computation is indeed correct.

        let cylinder = newCylinder(
                2, -2, 2, 2 * PI,
                newDiffuseBRDF(newUniformPigment(WHITE))
            )

        var
            ray1 = newRay(ORIGIN3D, eX)
            ray2 = newRay(newPoint3D(4, 0, 0), -eX)
            ray3 = newRay(newPoint3D(0, 0, -4), eZ)
            ray4 = newRay(newPoint3D(2, 3, 1), eY)

        t = ray1.transform(cylinder.transformation.inverse).getShapeHit(cylinder.shape)
        check areClose(t, 2)

        t = ray2.transform(cylinder.transformation.inverse).getShapeHit(cylinder.shape)
        check areClose(t, 2)
        
        t = ray3.transform(cylinder.transformation.inverse).getShapeHit(cylinder.shape)
        # check areClose(t, 2)                   

        t = ray4.transform(cylinder.transformation.inverse).getShapeHit(cylinder.shape)
        check t == Inf


    test "Ellipsoid":
        # Checking getShapeHit for a ray-ellipsoid intersection.
        # Here we need to assure that time computation is indeed correct.
        let 
            ell1 = newEllipsoid(1, 2, 3, newDiffuseBRDF(newUniformPigment(WHITE)))
            ell2 = newEllipsoid(3, 2, 1, newDiffuseBRDF(newUniformPigment(WHITE)))

        var
            ray1 = newRay(newPoint3D(0, 0, 2), -eZ)
            ray2 = newRay(newPoint3D(4, 0, 0), -eX)
            ray3 = newRay(ORIGIN3D, eX)
            ray4 = newRay(newPoint3D(5, 5, 5), eX)

        
        # First ellipsoid
        t = ray1.getShapeHit(ell1.shape)
        check areClose(t, 5)

        t = ray2.getShapeHit(ell1.shape)
        check areClose(t, 3)

        t = ray3.getShapeHit(ell1.shape)
        check areClose(t, 1)

        t = ray4.getShapeHit(ell1.shape)
        check t == Inf

    
        # Second elipsoid
        t = ray1.getShapeHit(ell2.shape)
        check areClose(t, 1)

        t = ray2.getShapeHit(ell2.shape)
        check areClose(t, 1, eps = 1e-6)

        t = ray3.getShapeHit(ell2.shape)
        check areClose(t, 3, eps = 1e-6)

        t = ray4.getShapeHit(ell2.shape)
        check t == Inf
