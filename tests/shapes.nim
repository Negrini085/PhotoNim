import std/[unittest, math, options]
import PhotoNim/[shapes, geometry, camera, common, transformations]

#---------------------------------------#
#         Hit Record type tests         #
#---------------------------------------#

suite "HitRecord":

    setup:
        var 
            hit1 = newHitRecord(newPoint3D(1, 2, 3), newNormal(1, 0, 0), newVec2[float32](1, 0), 0.5, newRay(newPoint3D(0, 0, 0), newVec3[float32](0, 1, 0)))
            hit2 = newHitRecord(newPoint3D(1, 0, 0), newNormal(0, 1, 0), newVec2[float32](0.5, 0.5), 0.6, newRay(newPoint3D(0, 0, 2), newVec3[float32](1, 1, 0)))


    test "newHitRecord":
        # Checking newHitRecord procedure
        check areClose(hit1.world_point, newPoint3D(1, 2, 3))
        check areClose(hit1.uv, newVec2[float32](1, 0))
        check areClose(hit1.normal, newNormal(1, 0, 0))
        check areClose(hit1.t, 0.5)
        check areClose(hit1.ray, newRay(newPoint3D(0, 0, 0), newVec3[float32](0, 1, 0)))


    test "areClose":
        # Checking areClose procedure for HitRecord variables
        check areClose(hit1, hit1)

        check not areClose(hit1.world_point, hit2.world_point)
        check not areClose(hit1.normal, hit2.normal)
        check not areClose(hit1.ray, hit2.ray)
        check not areClose(hit1.uv, hit2.uv)
        check not areClose(hit1.t, hit2.t)

        check not areClose(hit1, hit2)



#---------------------------------------#
#          Sphere type tests            #
#---------------------------------------#
suite "Sphere":

    setup:
        var sphere = newSphere(Transformation.id)

    test "SphereConstructor":
        # Checking sphere constructor procedure

        check areClose(sphere.T.mat, Mat4f.id)
        check areClose(sphere.T.inv_mat, Mat4f.id)
    

    test "Surface Normal":
        # Checking sphere normal computation method
        var
            p1 = newPoint3D(1, 0 ,0)
            p2 = newPoint3D(cos(PI/3), sin(PI/3) ,0)
            d = newVec3[float32](-1, 2, 0)
        
        check areClose(sphereNorm(p1, d), newNormal(1, 0, 0))
        check areClose(sphereNorm(p2, d), newNormal(-cos(PI/3), -sin(PI/3), 0))

    
    test "(u, v) coordinates":
        # Checking (u, v) coordinates computation
        var
            p1 = newPoint3D(1, 0, 1)
            p2 = newPoint3D(cos(PI/3), sin(PI/3), 0.5)

        check areClose(sphere_uv(p1), newVec2[float32](0, 0))
        check areClose(sphere_uv(p2), newVec2[float32](1/6, 1/3))
    

    test "RayIntersection: module 1":
        # Checking ray intersection procedure
        var
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3[float32](0, 0, -1))
            ray2 = newRay(newPoint3D(3, 0, 0), newVec3[float32](-1, 0, 0))
            ray3 = newRay(newPoint3D(0, 0, 0), newVec3[float32](1, 0, 0))

        check areClose(sphere.intersectionRay(ray1).get().world_point, newPoint3D(0, 0, 1))
        check areClose(sphere.intersectionRay(ray1).get().normal, newNormal(0, 0, 1))
        check areClose(sphere.intersectionRay(ray1).get().t, 1)
        check areClose(sphere.intersectionRay(ray1).get().uv, newVec2[float32](0, 0))

        check areClose(sphere.intersectionRay(ray2).get().world_point, newPoint3D(1, 0, 0))
        check areClose(sphere.intersectionRay(ray2).get().normal, newNormal(1, 0, 0))
        check areClose(sphere.intersectionRay(ray2).get().t, 2)
        check areClose(sphere.intersectionRay(ray1).get().uv, newVec2[float32](0, 0))

        check areClose(sphere.intersectionRay(ray3).get().world_point, newPoint3D(1, 0, 0))
        check areClose(sphere.intersectionRay(ray3).get().normal, newNormal(-1, 0, 0))
        check areClose(sphere.intersectionRay(ray3).get().t, 1)
        check areClose(sphere.intersectionRay(ray1).get().uv, newVec2[float32](0, 0))
