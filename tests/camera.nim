import std/[unittest, streams, math, sequtils]
import PhotoNim

suite "HDRImage unittest":
    
    setup:
        var img = newHDRImage(4, 2)
        
    teardown:
        discard img

    test "newHDRImage proc":
        check img.width == 4 and img.height == 2
        for i in 0..<img.height*img.width: check img.pixels[i] == BLACK

    test "set/getPixel proc":
        img.setPixel(1, 1, newColor(1.0, 2.0, 3.0))
        
        check areClose(img.getPixel(1, 0).r, 0.0)
        check areClose(img.getPixel(1, 0).g, 0.0)
        check areClose(img.getPixel(1, 0).b, 0.0)       

        check areClose(img.getPixel(1, 1).r, 1.0)
        check areClose(img.getPixel(1, 1).g, 2.0)
        check areClose(img.getPixel(1, 1).b, 3.0)

    test "avLuminosity proc":     
        # Testing Color luminosity proc
        check areClose(BLACK.luminosity, 0.0)
        check areClose(newColor(1.0, 2.0, 3.0).luminosity, 2.0)

        # Testing with blanck image and delta default value
        check areClose(log10(img.avLuminosity(1.0e-10)), -10)
        
        var newImg = newHDRImage(2, 2)
        newImg.setPixel(0, 0, newColor(1.0, 2.0, 3.0)); newImg.setPixel(0, 1, newColor(4.0, 5.0, 1.0))
        newImg.setPixel(1, 0, newColor(0.0, 1.5, 2.0)); newImg.setPixel(1, 1, newColor(2.0, 10.0, 3.0))
        check areClose(newImg.avLuminosity(0.0), pow(36, 0.25))
    
    
suite "ToneMapping test":
    setup:
        var img = newHDRImage(2, 2)
    
    test "image clamping":
        proc clamp(x: float32): float32 {.inline.} = x / (1.0 + x)
        proc clampColor(x: Color): Color = newColor(clamp(x.r), clamp(x.g), clamp(x.b))

        img.pixels.apply(clampColor)

        check areClose(img.getPixel(0, 0), BLACK)

        # Changing first pixel and testing over a non-null color
        img.setPixel(0, 0, newColor(1.0, 2.0, 3.0))
        img.pixels.apply(clampColor)

        check areclose(img.getPixel(0, 0), newColor(0.5, 2.0/3.0, 0.75))

    test "image normalization":
        img.setPixel(0, 0, newColor(1.0, 2.0, 3.0)); img.setPixel(0, 1, newColor(4.0, 51.0, 10.0))
        img.setPixel(1, 0, newColor(4.0, 13.5, 2.0)); img.setPixel(1, 1, newColor(24.0, 10.0, 3.0))
        
        let alpha = 2.0
        let factor = alpha / img.avLuminosity

        img.pixels.apply(proc(pix: Color): Color = pix * factor)

        check areClose(img.avLuminosity, alpha)
        check areClose(img.getPixel(0, 0), factor * newColor(1, 2, 3))


suite "HDRImage streaming test":

    test "write/readFloat proc":
        var stream = newFileStream("files/wpFloat.txt", fmWrite)

        stream.writeFloat(float32(1.0), bigEndian)
        stream.write "1.0"
        stream.close

        stream = openFileStream("files/wpFloat.txt", fmRead)
        check stream.readLine == "1.0"
        check stream.readFloat(bigEndian) == 1.0
        stream.close
    

    test "write/parsePFM proc":       
        var stream = newFileStream("files/wpPFM.txt", fmWrite)
        var img1 = newHDRImage(10, 15)
        
        # Changing some pixel in order to test writePFM & readPFM procedures
        img1.setPixel(3, 4, newColor(1.0, 2.0, 3.0))
        img1.setPixel(6, 3, newColor(3.4, 17.8, 128.1))
        img1.setPixel(8, 9, newColor(35.1, 18.2, 255.0))

        stream.writePFM(img1, bigEndian)
        stream.close
        
        stream = openFileStream("files/wpPFM.txt", fmRead)
        let img2 = stream.readPFM.img
        stream.close

        check areClose(img2.getPixel(3, 4), newColor(1.0, 2.0, 3.0))
        check areClose(img2.getPixel(6, 3), newColor(3.4, 17.8, 128.1))
        check areClose(img2.getPixel(8, 9), newColor(35.1, 18.2, 255.0))  
    

suite "Ray unittest":

    setup:
        var ray = newRay(newPoint3D(1, 2, 3), newVec3f(1, 0, 0))

    test "newRay proc":
        check areClose(ray.origin, newPoint3D(1, 2, 3))
        check areClose(ray.dir, newVec3f(1, 0, 0))
    
    test "at proc":
        check areClose(ray.at(0), ray.origin)
        check areClose(ray.at(1.0), newPoint3D(2, 2, 3))
        check areClose(ray.at(2.0), newPoint3D(3, 2, 3))

    test "areClose proc":
        var
            ray1 = newRay(newPoint3D(1, 2, 3), newVec3f(1, 0, 0))
            ray2 = newRay(newPoint3D(1, 2, 0), newVec3f(1, 0, 0))

        check areClose(ray, ray1)
        check not areClose(ray, ray2)
    
    test "transform proc":
        var 
            T1 = newTranslation(newVec3f(1, 2, 3))
            T2 = newRotY(180.0)

        check areClose(ray.transform(T1), newRay(newPoint3D(2, 4, 6), newVec3f(1, 0, 0)), 1e-4)
        check areClose(ray.transform(T2), newRay(newPoint3D(-1, 2, -3), newVec3f(-1, 0, 0)), 1e-4)


suite "Camera unittest":

    setup:
        var 
            oCam = newOrthogonalCamera(1.2)
            pCam = newPerspectiveCamera(1.2, 5)

    teardown:
        discard oCam; discard pCam

    test "newOrthogonalCamera proc":
        check areClose(oCam.aspect_ratio, 1.2)
        check areClose(apply(oCam.transform, newVec4f(0, 0, 0, 1)), newVec4f(0, 0, 0, 1))

    
    test "newPerspectiveCamera proc":       
        check areClose(pCam.aspect_ratio, 1.2)
        check areClose(apply(pCam.transform, newVec4f(0, 0, 0, 1)), newVec4f(0, 0, 0, 1))
    

    test "Orthogonal fireRay proc":
        var 
            ray1 = oCam.fireRay(newPoint2D(0, 0))
            ray2 = oCam.fireRay(newPoint2D(1, 0))
            ray3 = oCam.fireRay(newPoint2D(0, 1))
            ray4 = oCam.fireRay(newPoint2D(1, 1))
        
        # Testing ray parallelism
        check areClose(0.0, cross(ray1.dir, ray2.dir).norm)
        check areClose(0.0, cross(ray1.dir, ray3.dir).norm)
        check areClose(0.0, cross(ray1.dir, ray4.dir).norm)

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
    

    test "Perspective fireRay proc":
        var 
            ray1 = pCam.fireRay(newPoint2D(0, 0))
            ray2 = pCam.fireRay(newPoint2D(1, 0))
            ray3 = pCam.fireRay(newPoint2D(0, 1))
            ray4 = pCam.fireRay(newPoint2D(1, 1))

        # Checking wether all rays share the same origin
        check areClose(ray1.origin, ray2.origin)
        check areClose(ray1.origin, ray3.origin)
        check areClose(ray1.origin, ray4.origin)
        
        # Checking directions
        check areClose(ray1.dir, newVec3f(5,  1.2, -1))
        check areClose(ray2.dir, newVec3f(5, -1.2, -1))
        check areClose(ray3.dir, newVec3f(5,  1.2,  1))
        check areClose(ray4.dir, newVec3f(5, -1.2,  1))

        # Testing arrive point
        check areClose(ray1.at(1.0), newPoint3D(0, 1.2, -1))
        check areClose(ray2.at(1.0), newPoint3D(0, -1.2, -1))
        check areClose(ray3.at(1.0), newPoint3D(0, 1.2, 1))
        check areClose(ray4.at(1.0), newPoint3D(0, -1.2, 1))


suite "ImageTracer unittest":

    setup:
        var tracer = newImageTracer(5, 5, newOrthogonalCamera(1.2, Transformation.id))
        
    test "newImageTrace proc":
        check tracer.image.width == 5 and tracer.image.height == 5 
        check tracer.camera.kind == ckOrthogonal

    test "fireRay proc":
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