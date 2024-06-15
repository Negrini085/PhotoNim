import std/unittest
import PhotoNim


suite "HitLeafs":

    setup:
        let
            aabb1 = (newPoint3D(-1, -1, -1), newPoint3D(1, 1, 1))
            aabb2 = (newPoint3D(-1, 0, 1), newPoint3D(1, 2, 3))

    teardown:
        discard aabb1
        discard aabb2


    test "checkIntersection proc":
        # Checking checkIntersection proc, states wether an aabb hit occurred or not
        var
            ray1 = newRay(newPoint3D(-2, 0, 0), eX)
            ray2 = newRay(newPoint3D(0, 0.5, 2), -eZ)
            ray3 = newRay(newPoint3D(-2, -2, -2), -eX)
            ray4 = newRay(newPoint3D(0, 0, 0), -eX)

        # First aabb
        check aabb1.checkIntersection(ray1)
        check aabb1.checkIntersection(ray2)
        check not aabb1.checkIntersection(ray3)
        check aabb1.checkIntersection(ray4)

        # Second aabb
        check not aabb2.checkIntersection(ray1)
        check aabb2.checkIntersection(ray2)
        check not aabb2.checkIntersection(ray3)
        check not aabb2.checkIntersection(ray4)