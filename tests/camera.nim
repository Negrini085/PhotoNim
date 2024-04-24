import std/[unittest, math]
import PhotoNim/[transformations, common, geometry, camera]

#----------------------------------#
#          Ray type tests          #
#----------------------------------#
suite "Ray tests":

    var ray = newRay(newPoint3D(1, 2, 3), newVec3[float32](1, 0, 0))

    test "newRay":
        # Checking constructor test
        check areClose(ray.start, newPoint3D(1, 2, 3))
        check areClose(ray.dir, newVec3[float32](1, 0, 0))
    
    test "at":
        # Checking at procedure
        check areClose(ray.at(2.0), newPoint3D(3, 2, 3))

    test "areClose":
        # Checking areClose procedure
        var
            ray1 = newRay(newPoint3D(1, 2, 3), newVec3[float32](1, 0, 0))
            ray2 = newRay(newPoint3D(1, 2, 0), newVec3[float32](1, 0, 0))

        check areClose(ray, ray1)
        check not areClose(ray, ray2)
    
    test "translateRay":
        # Checking ray translation procedures
        var 
            vec = newVec3[float32](1, 2, 3)
            T = newTranslation(newVec4[float32](1, 2, 3, 0))

        check areClose(ray.translateRay(vec).start, newPoint3D(2, 4, 6))
        check areClose(translateRay(T, ray).start, newPoint3D(2, 4, 6))