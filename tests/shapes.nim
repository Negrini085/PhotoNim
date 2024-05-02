import std/unittest
import PhotoNim/[shapes, geometry, camera, common]

suite "HitRecord":

    setup:
        var 
            hit1 = newHitRecord(newPoint3D(1, 2, 3), newVec2[float32](1, 0), newNormal(1, 0, 0), 0.5, newRay(newPoint3D(0, 0, 0), newVec3[float32](0, 1, 0)))
            hit2 = newHitRecord(newPoint3D(1, 0, 0), newVec2[float32](0.5, 0.5), newNormal(0, 1, 0), 0.6, newRay(newPoint3D(0, 0, 2), newVec3[float32](1, 1, 0)))

    test "newHitRecord":
        # Checking newHitRecord procedure
        check areClose(hit1.world_point, newPoint3D(1, 2, 3))
        check areClose(hit1.uv, newVec2[float32](1, 0))
        check areClose(hit1.normal, newNormal(1, 0, 0))
        check areClose(hit1.t, 0.5)
        check areClose(hit1.ray, newRay(newPoint3D(0, 0, 0), newVec3[float32](0, 1, 0)))