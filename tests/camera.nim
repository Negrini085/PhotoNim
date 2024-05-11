import std/unittest
from std/math import exp, pow
import PhotoNim/[geometry, camera, hdrimage]

#----------------------------------#
#          Ray type tests          #
#----------------------------------#
suite "Ray tests":

    setup:
        var ray = newRay(newPoint3D(1, 2, 3), newVec3[float32](1, 0, 0))

    test "newRay":
        # Checking constructor test
        check areClose(ray.start, newPoint3D(1, 2, 3))
        check areClose(ray.dir, newVec3[float32](1, 0, 0))
    

    test "at":
        # Checking at procedure
        check areClose(ray.at(0), ray.start)
        check areClose(ray.at(1.0), newPoint3D(2, 2, 3))
        check areClose(ray.at(2.0), newPoint3D(3, 2, 3))


    test "areClose proc":
        # Checking areClose procedure
        var
            ray1 = newRay(newPoint3D(1, 2, 3), newVec3[float32](1, 0, 0))
            ray2 = newRay(newPoint3D(1, 2, 0), newVec3[float32](1, 0, 0))

        check areClose(ray, ray1)
        check not areClose(ray, ray2)
    

    test "translate proc":
        # Checking ray translation procedures
        var 
            vec1 = newVec3[float32](0, 0, 0)
            vec2 = newVec3[float32](1, 2, 3)

        check areClose(ray.translate(vec1).start, newPoint3D(1, 2, 3))
        check areClose(ray.translate(vec2).start, newPoint3D(2, 4, 6))
    

    test "apply proc":
        # Checking ray rotation procedures
        var 
            T1 = newTranslation(newVec3[float32](1, 2, 3))
            T2 = newRotY(180)

        check areClose(apply(T1, ray),  newRay(newPoint3D(2, 4, 6), newVec3[float32](1, 0, 0)))
        check areClose(apply(T2, ray).dir, newVec3[float32](-1, 0, 0))
        #check areClose(transformRay(T2, ray),  newRay(newPoint3D(-1, 2, -3), newVec3[float32](-1, 0, 0)))



#-------------------------------------#
#          Camera type tests          #
#-------------------------------------#
suite "Camera tests":

    setup:
        var 
            oCam = newOrthogonalCamera(1.2)
            pCam = newPerspectiveCamera(1.2, 5)

    test "Orthogonal Contructor":
        # Testing ortogonal type constructor
        
        check areClose(oCam.aspect_ratio, 1.2)
        check areClose(apply(oCam.transf, newVec4[float32](0, 0, 0, 1)), newVec4[float32](0, 0, 0, 1))

    
    test "Orthogonal Contructor":
        # Testing ortogonal type constructor
        
        check areClose(pCam.aspect_ratio, 1.2)
        check areClose(apply(pCam.transf, newVec4[float32](0, 0, 0, 1)), newVec4[float32](0, 0, 0, 1))
    

    test "Orthogonal Fire Ray":
        # Testing orthogonal fire_ray procedure: a ray is fired

        var 
            ray1 = oCam.fire_ray(newPoint2D(0, 0))
            ray2 = oCam.fire_ray(newPoint2D(1, 0))
            ray3 = oCam.fire_ray(newPoint2D(0, 1))
            ray4 = oCam.fire_ray(newPoint2D(1, 1))
        
        # Testing ray parallelism
        check areClose(0.0, cross(ray1.dir, ray2.dir).norm())
        check areClose(0.0, cross(ray1.dir, ray3.dir).norm())
        check areClose(0.0, cross(ray1.dir, ray4.dir).norm())

        # Testing direction
        check areClose(ray1.dir, eX)
        check areClose(ray2.dir, eX)
        check areClose(ray3.dir, eX)
        check areClose(ray4.dir, eX)

        # Testing arrive point
        check areClose(ray1.at(1.0), newPoint3D(0, 1.2, -1))
        check areClose(ray2.at(1.0), newPoint3D(0, -1.2, -1))
        check areClose(ray3.at(1.0), newPoint3D(0, 1.2, 1))
        check areClose(ray4.at(1.0), newPoint3D(0, -1.2, 1))
    

    test "Perspective Fire Ray":
        # Testing perspective fire_ray procedure: a ray is fired

        var 
            ray1 = pCam.fire_ray(newPoint2D(0, 0))
            ray2 = pCam.fire_ray(newPoint2D(1, 0))
            ray3 = pCam.fire_ray(newPoint2D(0, 1))
            ray4 = pCam.fire_ray(newPoint2D(1, 1))


        # Checking wether all rays share the same origin
        check areClose(ray1.start, ray2.start)
        check areClose(ray1.start, ray3.start)
        check areClose(ray1.start, ray4.start)
        
        # Checking directions
        check areClose(ray1.dir, newVec3[float32](5,  1.2, -1))
        check areClose(ray2.dir, newVec3[float32](5, -1.2, -1))
        check areClose(ray3.dir, newVec3[float32](5,  1.2,  1))
        check areClose(ray4.dir, newVec3[float32](5, -1.2,  1))

        # Testing arrive point
        check areClose(ray1.at(1.0), newPoint3D(0, 1.2, -1))
        check areClose(ray2.at(1.0), newPoint3D(0, -1.2, -1))
        check areClose(ray3.at(1.0), newPoint3D(0, 1.2, 1))
        check areClose(ray4.at(1.0), newPoint3D(0, -1.2, 1))



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
            ray2 = im_tr.fire_ray(2, 1, newPoint2D(0.5, 0.5))

        check areClose(ray1.start, ray2.start)


    test "Camera Orientation":

        var
            ray1 = im_tr.fire_ray(0, 0, newPoint2D(0, 0))   # Ray direct to top left corner
            ray2 = im_tr.fire_ray(4, 4, newPoint2D(1, 1))   # Ray direct to bottom right corner
        
        check areClose(ray1.at(1.0), newPoint3D(0, 1.2, 1))
        check areClose(ray2.at(1.0), newPoint3D(0, -1.2, -1))


    test "ImageTracer fire_all_rays":

        im_tr.fire_all_rays()

        for y in 0..<im_tr.image.height:
            for x in 0..<im_tr.image.width:
                let 
                    r = (1 - exp(-float32(x + y)))
                    g = y/im_tr.image.height
                    b = pow((1 - x/im_tr.image.width), 2.5)
                check areClose(im_tr.image.getPixel(x, y), newColor(r, g, b))
    