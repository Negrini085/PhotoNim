import std/unittest
from std/math import exp, pow
import PhotoNim/[geometry, camera, hdrimage, shapes, tracer]



#------------------------------------------#
#         Image Tracer type tests          #
#------------------------------------------#
suite "ImageTracer":

    setup:
        var 
            image: HdrImage = newHdrImage(5, 5)
            cam: OrthogonalCamera = newOrthogonalCamera(1.2, Transformation.id)
            im_tr = newImageTracer(image, cam)

    test "ImageTracer index":
        # Checking image tracer type, we will have to open an issue
        var
            ray1 = im_tr.fire_ray(0, 0, newPoint2D(2.5, 1.5))
            ray2 = im_tr.fire_ray(1, 2, newPoint2D(0.5, 0.5))

        check areClose(ray1.start, ray2.start)


    test "Camera Orientation":

        var
            ray1 = im_tr.fire_ray(0, 0, newPoint2D(0, 0))   # Ray direct to top left corner
            ray2 = im_tr.fire_ray(4, 4, newPoint2D(1, 1))   # Ray direct to bottom right corner
        
        check areClose(ray1.at(1.0), newPoint3D(0, 1.2, 1))
        check areClose(ray2.at(1.0), newPoint3D(0, -1.2, -1))


    test "ImageTracer fire_all_rays":

        im_tr.fire_all_rays()

        for row in 0..<im_tr.image.height:
            for col in 0..<im_tr.image.width:
                let 
                    col1 = (1 - exp(-float32(col + row)))
                    col2 = row/im_tr.image.height
                    col3 = pow((1 - col/im_tr.image.width), 2.5)
                check areClose(im_tr.image.getPixel(row, col), newColor(col1, col2, col3))
    