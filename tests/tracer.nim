import std/unittest
import PhotoNim
from math import exp, pow

#------------------------------------------#
#         Image Tracer type tests          #
#------------------------------------------#
suite "ImageTracer":

    setup:
        var tracer = newImageTracer(5, 5, newOrthogonalCamera(1.2, Transformation.id))

    test "ImageTracer index":
        # Checking image tracer type, we will have to open an issue
        var
            ray1 = tracer.fire_ray(0, 0, newPoint2D(2.5, 1.5))
            ray2 = tracer.fire_ray(2, 1, newPoint2D(0.5, 0.5))

        check areClose(ray1.origin, ray2.origin)


    test "Camera Orientation":

        var
            ray1 = tracer.fire_ray(0, 0, newPoint2D(0, 0))   # Ray direct to top left corner
            ray2 = tracer.fire_ray(4, 4, newPoint2D(1, 1))   # Ray direct to bottom right corner
        
        check areClose(ray1.at(1.0), newPoint3D(0, 1.2, 1))
        check areClose(ray2.at(1.0), newPoint3D(0, -1.2, -1))


#--------------------------------------------#
#         Renderer kinds test suite          #
#--------------------------------------------#

suite "Renderer":

    setup:
        var 
            world = newWorld(@[
                newSphere(newPoint3D(1, 0, 0), 0.5),
                newSphere(newPoint3D(1, 2, -1), 0.2)
            ])
            oftrace = newOnOffRenderer(world, newColor(1, 2, 3), newColor(3, 2, 1))
    
    teardown:
        discard world
        discard oftrace

    test "constructor proc":

        # On-Off Renderer
        check oftrace.kind == OnOffRenderer

        check areClose(oftrace.world.shapes[0].radius, 0.5)
        check areClose(oftrace.world.shapes[1].radius, 0.2)
        check areClose(oftrace.world.shapes[0].center, newPoint3D(1, 0, 0))
        check areClose(oftrace.world.shapes[1].center, newPoint3D(1, 2, -1))

        check areClose(oftrace.back_col, newColor(1, 2, 3))
        check areClose(oftrace.hit_col, newColor(3, 2, 1))


    test "call proc":

        var
            ray1 = newRay(newPoint3D(-2, 0, 0), newVec3f(1, 0, 0))
            ray2 = newRay(newPoint3D(-2, 0, 0), newVec3f(-1, 0, 0))

        # On-Off Renderer
        check areClose(oftrace.call(ray1), newColor(3, 2, 1))
        check areClose(oftrace.call(ray2), newColor(1, 2, 3))