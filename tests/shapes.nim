import std/unittest
import PhotoNim/[shapes, geometry, camera, common]

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