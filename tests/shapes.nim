import std/unittest
import PhotoNim/[shapes, geometry, camera, common]

suite "HitRecord":

    setup:
        var intersezione = newHitRecord(newPoint3D(1, 2, 3), newVec2[float32](1, 0), newNormal(1, 0, 0), 0.5, newRay(newPoint3D(0, 0, 0), newVec3[float32](0, 1, 0)))

    test "newHitRecord":
        # Checking newHitRecord procedure
        check areClose(toVec3(intersezione.world_point), newVec3[float32](1, 2, 3))
        check areClose(intersezione.uv, newVec2[float32](1, 0))
        check areClose(intersezione.normal, newNormal(1, 0, 0))
        check areClose(intersezione.t, 0.5)
        check areClose(intersezione.ray, newRay(newPoint3D(0, 0, 0), newVec3[float32](0, 1, 0)))