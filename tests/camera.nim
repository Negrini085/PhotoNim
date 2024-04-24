import std/[unittest, math]
import PhotoNim/[transformations, common, geometry, camera]

#import PhotoNim/[transformations, common, geometry, camera]

#----------------------------------#
#          Ray type tests          #
#----------------------------------#
suite "Ray tests":

    var ray = newRay(newPoint3D(1, 2, 3), newVec3[float32](1, 0, 0))

    test "Ray constructor":
        # Checking constructor test
        check areClose(ray.start, newPoint3D(1, 2, 3))
        check areClose(ray.dir, newVec3[float32](1, 0, 0))
