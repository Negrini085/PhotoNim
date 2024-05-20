import std/[unittest, streams, math, sequtils]
import PhotoNim

suite "HdrImageTest":
    
    setup:
        var img: HdrImage = newHdrImage(2, 2)
    
    teardown:
        discard img
    
    test "newHdrImage":
        check img.width == 2 and img.height == 2

        for i in 0..<img.height*img.width:
            check areClose(img.pixels[i].r, 0.0)
            check areClose(img.pixels[i].g, 0.0)
            check areClose(img.pixels[i].b, 0.0)

    test "set/getPixel":
        img.setPixel(1, 1, newColor(1.0, 2.0, 3.0))
        
        check areClose(img.getPixel(1, 0).r, 0.0)
        check areClose(img.getPixel(1, 0).g, 0.0)
        check areClose(img.getPixel(1, 0).b, 0.0)       

        check areClose(img.getPixel(1, 1).r, 1.0)
        check areClose(img.getPixel(1, 1).g, 2.0)
        check areClose(img.getPixel(1, 1).b, 3.0)

    test "write/readFloat":
        var stream = newFileStream("files/wpFloat.txt", fmWrite)

        stream.writeFloat(float32(1.0), bigEndian)
        stream.write("1.0")
        stream.close

        stream = openFileStream("files/wpFloat.txt", fmRead)
        check areClose(stream.readFloat(bigEndian), float32(1.0))
        check "1.0" == stream.readLine
        stream.close
    
    test "write/parsePFM":       
        var 
            stream = newFileStream("files/wpPFM.txt", fmWrite)
            img1 = newHdrImage(10, 15)
        
        # Changing some pixel in order to test writePFM & readPFM procedures
        img1.setPixel(3, 4, newColor(1.0, 2.0, 3.0))
        img1.setPixel(6, 3, newColor(3.4, 17.8, 128.1))
        img1.setPixel(8, 9, newColor(35.1, 18.2, 255.0))

        stream.writePFM(img1, bigEndian)
        stream.close
        
        stream = openFileStream("files/wpPFM.txt", fmRead)
        let img2 = stream.readPFM.img
        stream.close

        # Checking pixel values
        check areClose(img2.getPixel(3, 4).r, 1.0)
        check areClose(img2.getPixel(3, 4).g, 2.0)
        check areClose(img2.getPixel(3, 4).b, 3.0)  

        check areClose(img2.getPixel(6, 3).r, 3.4)
        check areClose(img2.getPixel(6, 3).g, 17.8)
        check areClose(img2.getPixel(6, 3).b, 128.1)  

        check areClose(img2.getPixel(8, 9).r, 35.1)
        check areClose(img2.getPixel(8, 9).g, 18.2)
        check areClose(img2.getPixel(8, 9).b, 255.0)  
    
    test "colorLuminosity":
        ## Test color luminosity calculation
        let 
            col1 = newColor(1.0, 2.0, 3.0)
            col2 = newColor(0.0, 0.0, 0.0)

        check areClose(col1.luminosity, 2.0)
        check areClose(col2.luminosity, 0.0)

    test "averageLuminosity":        
        # Testing with blanck image and delta default value
        check areClose(log10(img.averageLuminosity(1.0e-10)), -10)
        
        img.setPixel(0, 0, newColor(1.0, 2.0, 3.0)); img.setPixel(0, 1, newColor(4.0, 5.0, 1.0))
        img.setPixel(1, 0, newColor(0.0, 1.5, 2.0)); img.setPixel(1, 1, newColor(2.0, 10.0, 3.0))
        check areClose(img.averageLuminosity(0.0), pow(36, 0.25))
    
    
    test "normalizeImage":
        # Changing pixel values
        img.setPixel(0, 0, newColor(1.0, 2.0, 3.0)); img.setPixel(0, 1, newColor(4.0, 51.0, 10.0))
        img.setPixel(1, 0, newColor(4.0, 13.5, 2.0)); img.setPixel(1, 1, newColor(24.0, 10.0, 3.0))
        
        let alpha = 2.0
        let factor = alpha / img.averageLuminosity

        img.pixels.apply(proc(pix: Color): Color = pix * factor)

        check areClose(img.averageLuminosity, alpha)
        check areClose(img.getPixel(0, 0).r, 1.0 * factor)
        check areClose(img.getPixel(0, 0).g, 2.0 * factor)
        check areClose(img.getPixel(0, 0).b, 3.0 * factor)

    
    test "clampImage":
        proc clamp(x: float32): float32 {.inline.} = x / (1.0 + x)
        img.pixels.apply(proc(pix: Color): Color = newColor(clamp(pix.r), clamp(pix.g), clamp(pix.b)))

        check areClose(img.getPixel(0, 0).r, 0.0)
        check areClose(img.getPixel(0, 0).g, 0.0)
        check areClose(img.getPixel(0, 0).b, 0.0)

        #Changing first pixel and testing over a non-null color
        img.setPixel(0, 0, newColor(1.0, 2.0, 3.0))
        img.pixels.apply(proc(pix: Color): Color = newColor(clamp(pix.r), clamp(pix.g), clamp(pix.b)))

        check areclose(img.getPixel(0, 0).r, 0.5)
        check areClose(img.getPixel(0, 0).g, 2.0/3.0)
        check areClose(img.getPixel(0, 0).b, 0.75)


#----------------------------------#
#          Ray type tests          #
#----------------------------------#
suite "Ray tests":

    setup:
        var ray = newRay(newPoint3D(1, 2, 3), newVec3[float32](1, 0, 0))

    test "newRay":
        # Checking constructor test
        check areClose(ray.origin, newPoint3D(1, 2, 3))
        check areClose(ray.dir, newVec3[float32](1, 0, 0))
    

    test "at":
        # Checking at procedure
        check areClose(ray.at(0), ray.origin)
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

        check areClose(ray.translate(vec1).origin, newPoint3D(1, 2, 3))
        check areClose(ray.translate(vec2).origin, newPoint3D(2, 4, 6))
    

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
        check areClose(ray1.origin, ray2.origin)
        check areClose(ray1.origin, ray3.origin)
        check areClose(ray1.origin, ray4.origin)
        
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
suite "ImageTracer unittest":

    setup:
        var 
            image = newHdrImage(5, 5)
            cam = newOrthogonalCamera(1.2, Transformation.id)
            im_tr = ImageTracer(image: image, camera: cam)

    test "ImageTracer index":
        # Checking image tracer type, we will have to open an issue
        var
            ray1 = im_tr.fire_ray(0, 0, newPoint2D(2.5, 1.5))
            ray2 = im_tr.fire_ray(2, 1, newPoint2D(0.5, 0.5))

        check areClose(ray1.origin, ray2.origin)


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
    


suite "Pigment unittest":

    setup: 
        let
            color1 = newColor(1.0, 2.0, 3.0)
            color2 = newColor(2.0, 3.0, 1.0)
            color3 = newColor(2.0, 1.0, 3.0)
            color4 = newColor(3.0, 2.0, 1.0)

    teardown:
        discard color1; discard color2; discard color3; discard color4

    test "newUniformPigment proc":
        let pigment = newUniformPigment(color1)
        check areClose(pigment.getColor(newPoint2D(0.0, 0.0)), color1)
        check areClose(pigment.getColor(newPoint2D(1.0, 0.0)), color1)
        check areClose(pigment.getColor(newPoint2D(0.0, 1.0)), color1)
        check areClose(pigment.getColor(newPoint2D(1.0, 1.0)), color1)
    
    test "newTexturePigment proc":
        var image = newHDRImage(2, 2)
        image.setPixel(0, 0, color1); image.setPixel(1, 0, color2)
        image.setPixel(0, 1, color3); image.setPixel(1, 1, color4)

        let pigment = newTexturePigment(image)
        check areClose(pigment.getColor(newPoint2D(0.0, 0.0)), color1)
        check areClose(pigment.getColor(newPoint2D(1.0, 0.0)), newColor(2.0, 3.0, 1.0))
        check areClose(pigment.getColor(newPoint2D(0.0, 1.0)), newColor(2.0, 1.0, 3.0))
        check areClose(pigment.getColor(newPoint2D(1.0, 1.0)), newColor(3.0, 2.0, 1.0))
    
    test "newCheckeredPigment proc":
        let pigment = newCheckeredPigment(color1, color2, 2)
        check areClose(pigment.getColor(newPoint2D(0.25, 0.25)), color1)
        check areClose(pigment.getColor(newPoint2D(0.75, 0.25)), color2)
        check areClose(pigment.getColor(newPoint2D(0.25, 0.75)), color2)
        check areClose(pigment.getColor(newPoint2D(0.75, 0.75)), color1)