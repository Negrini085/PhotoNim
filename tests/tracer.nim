import std/unittest
import PhotoNim

suite "ImageTracer":

    setup:
        var tracer = newImageTracer(5, 5, newOrthogonalCamera(1.2, Transformation.id))

    test "ImageTracer index":
        # Checking image tracer type, we will have to open an issue
        var
            ray1 = tracer.fireRay(0, 0, newPoint2D(2.5, 1.5))
            ray2 = tracer.fireRay(2, 1, newPoint2D(0.5, 0.5))

        check areClose(ray1.origin, ray2.origin)


    test "Camera Orientation":

        var
            ray1 = tracer.fireRay(0, 0, newPoint2D(0, 0))   # Ray direct to top left corner
            ray2 = tracer.fireRay(4, 4, newPoint2D(1, 1))   # Ray direct to bottom right corner
        
        check areClose(ray1.at(1.0), newPoint3D(0, 1.2, 1))
        check areClose(ray2.at(1.0), newPoint3D(0, -1.2, -1))


    # test "ImageTracer fire_all_rays":

    #     tracer.fire_all_rays()

    #     for y in 0..<tracer.image.height:
    #         for x in 0..<tracer.image.width:
    #             let 
    #                 r = (1 - exp(-float32(x + y)))
    #                 g = y/tracer.image.height
    #                 b = pow((1 - x/tracer.image.width), 2.5)
    #             check areClose(tracer.image.getPixel(x, y), newColor(r, g, b))
    