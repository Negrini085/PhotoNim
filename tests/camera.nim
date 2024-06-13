import std/[unittest, math]
import PhotoNim

#---------------------------#
#    Ray type test suite    #
#---------------------------#
suite "Ray":

    setup:
        var 
            ray1 = newRay(newPoint3D(1, 2, 3), newVec3f(1, 0, 0))
            ray2 = newRay(newPoint3D(1, 2, 0), newVec3f(1, 0, 0))
    
    teardown:
        discard ray1
        discard ray2


    test "newRay proc":
        #Checking newRay proc

        # First ray check
        check ray1.depth == 0.int
        check ray1.tSpan.max == Inf
        check areClose(ray1.tSpan.min, 1.0)
        check areClose(ray1.dir, newVec3f(1, 0, 0))
        check areClose(ray1.origin, newPoint3D(1, 2, 3))

        # Second ray check
        check ray2.depth == 0.int
        check ray2.tSpan.max == Inf
        check areClose(ray2.tSpan.min, 1.0)
        check areClose(ray2.dir, newVec3f(1, 0, 0))
        check areClose(ray2.origin, newPoint3D(1, 2, 0))
    

    test "at proc":
        # Checkin at proc, gives ray position at a certain time

        # First ray check
        check areClose(ray1.at(0), ray1.origin)
        check areClose(ray1.at(1.0), newPoint3D(2, 2, 3))
        check areClose(ray1.at(2.0), newPoint3D(3, 2, 3))

        # Second ray check
        check areClose(ray2.at(0), ray2.origin)
        check areClose(ray2.at(1.0), newPoint3D(2, 2, 0))
        check areClose(ray2.at(2.0), newPoint3D(3, 2, 0))


    test "areClose proc":
        # Checking areClose proc, which states wether two rays are similar or not

        check areClose(ray1, ray1)
        check not areClose(ray1, ray2)


    test "transform proc":
        # Checking transform proc, which transform ray in a specific frame of reference
        var 
            T1 = newTranslation(newVec3f(1, 2, 3))
            T2 = newRotY(180.0)

        # First ray
        check areClose(ray1.transform(T1), newRay(newPoint3D(2, 4, 6), newVec3f(1, 0, 0)))
        check areClose(ray1.transform(T2), newRay(newPoint3D(-1, 2, -3), newVec3f(-1, 0, 0)), 1e-6)

        # Second ray
        check areClose(ray2.transform(T1), newRay(newPoint3D(2, 4, 3), newVec3f(1, 0, 0)))
        check areClose(ray2.transform(T2), newRay(newPoint3D(-1, 2, 0), newVec3f(-1, 0, 0)), 1e-6)


#suite "Camera":
#
#    setup:
#        var 
#            rs = newReferenceSystem(newPoint3D(-1, 0, 0), [eX, -eZ, eY])
#            oCam = newOrthogonalCamera(viewport = (12, 10))
#            pCam = newPerspectiveCamera(rs, viewport = (12, 10), distance = 5, newTranslation([float32 -1, 0, 0]))
#
#    teardown:
#        discard rs
#        discard oCam
#        discard pCam
#
#
#    test "newOrthogonalCamera proc":
#        # Checking newOrthogonalCamera proc
#
#        check areClose(oCam.aspect_ratio, 1.2)
#        check oCam.rs.origin == ORIGIN3D 
#        check oCam.rs.base == Mat3f.id
#    
#    test "newPerspectiveCamera proc":       
#        check areClose(pCam.aspect_ratio, 1.2)
#        check pCam.rs.origin == newPoint3D(-1, 0, 0) 
#        check areClose(pCam.rs.base[0], eX)
#        check areClose(pCam.rs.base[1], eZ)
#        check areClose(pCam.rs.base[2], -eY)
#    
#
##    test "Orthogonal fireRay proc":
##        var 
##            ray1 = oCam.fireRay(newPoint2D(0, 0))
##            ray2 = oCam.fireRay(newPoint2D(1, 0))
##            ray3 = oCam.fireRay(newPoint2D(0, 1))
#            ray4 = oCam.fireRay(newPoint2D(1, 1))
#        
#        # Testing ray parallelism
#        check areClose(0.0, cross(ray1.dir, ray2.dir).norm)
#        check areClose(0.0, cross(ray1.dir, ray3.dir).norm)
#        check areClose(0.0, cross(ray1.dir, ray4.dir).norm)
#
#        # Testing direction
#        check areClose(ray1.dir, eX)
#        check areClose(ray2.dir, eX)
#        check areClose(ray3.dir, eX)
#        check areClose(ray4.dir, eX)
#
#        # Testing arrive point
#        check areClose(ray1.at(1.0), newPoint3D(0, 1.2, -1))
#        check areClose(ray2.at(1.0), newPoint3D(0, -1.2, -1))
#        check areClose(ray3.at(1.0), newPoint3D(0, 1.2, 1))
#        check areClose(ray4.at(1.0), newPoint3D(0, -1.2, 1))
#    
#
#    test "Perspective fireRay proc":
#        var 
#            ray1 = pCam.fireRay(newPoint2D(0, 0))
#            ray2 = pCam.fireRay(newPoint2D(1, 0))
#            ray3 = pCam.fireRay(newPoint2D(0, 1))
#            ray4 = pCam.fireRay(newPoint2D(1, 1))
#
#        # # Checking wether all rays share the same origin
#        check areClose(ray1.origin, ray2.origin)
#        check areClose(ray1.origin, ray3.origin)
#        check areClose(ray1.origin, ray4.origin)
#        
#        # # Checking directions
#        check areClose(ray1.dir, newVec3f(5,  1.2, -1))
#        check areClose(ray2.dir, newVec3f(5, -1.2, -1))
#        check areClose(ray3.dir, newVec3f(5,  1.2,  1))
#        check areClose(ray4.dir, newVec3f(5, -1.2,  1))
#
#        # Testing arrive point
#        check areClose(ray1.at(1.0), newPoint3D(0, 1.2, -1))
#        check areClose(ray2.at(1.0), newPoint3D(0, -1.2, -1))
#        check areClose(ray3.at(1.0), newPoint3D(0, 1.2, 1))
#        check areClose(ray4.at(1.0), newPoint3D(0, -1.2, 1))
#
#
#    test "checkIntersection proc":
#        let scene = newScene(@[newSphere(newPoint3D(2, 0, 0), 0.5)])
#
#        var cameraScene = scene.fromObserver(pCam.rs)
#        check cameraScene.handlers[0].shape == scene.handlers[0].shape
#        check cameraScene.handlers[0].transformation != scene.handlers[0].transformation
#        
#        check checkIntersection(cameraScene.handlers[0], pCam.fireRay(newPoint2D(0.5, 0.5)))
#
#        # check checkIntersection(cameraScene.handlers[0].getAABB, pCam.fireRay(newPoint2D(0.5, 0.5)))
#        check checkIntersection(newShapeHandler(newAABox(cameraScene.handlers[0].getAABB)), pCam.fireRay(newPoint2D(0.5, 0.5)))
#
#        cameraScene.buildBVHTree(1, skSAH)
#
#        check checkIntersection(cameraScene.tree, pCam.fireRay(newPoint2D(0.5, 0.5)))
#
#


#-------------------------------#
#       Pigment test suite      #
#-------------------------------#
suite "Pigment":

    setup: 
        let
            color1 = newColor(1.0, 2.0, 3.0)
            color2 = newColor(2.0, 3.0, 1.0)
            color3 = newColor(2.0, 1.0, 3.0)
            color4 = newColor(3.0, 2.0, 1.0)

    teardown:
        discard color1
        discard color2
        discard color3
        discard color4


    test "color * proc":
        # Checking color tensor product proc
        var appo: Color

        appo = color1 * color2
        check areClose(appo.r, 2.0)
        check areClose(appo.g, 6.0)
        check areClose(appo.b, 3.0)


    test "newUniformPigment proc":
        # Checking newUniformPigment proc 
        let pigment = newUniformPigment(color1)

        check areClose(pigment.getColor(newPoint2D(0.0, 0.0)), color1)
        check areClose(pigment.getColor(newPoint2D(1.0, 0.0)), color1)
        check areClose(pigment.getColor(newPoint2D(0.0, 1.0)), color1)
        check areClose(pigment.getColor(newPoint2D(1.0, 1.0)), color1)
    

    test "newTexturePigment proc":
        # Checking newTexturePigment proc
        var image = newHDRImage(2, 2)
        image.setPixel(0, 0, color1); image.setPixel(1, 0, color2)
        image.setPixel(0, 1, color3); image.setPixel(1, 1, color4)

        let pigment = newTexturePigment(image)
        check areClose(pigment.getColor(newPoint2D(0.0, 0.0)), color1)
        check areClose(pigment.getColor(newPoint2D(1.0, 0.0)), newColor(2.0, 3.0, 1.0))
        check areClose(pigment.getColor(newPoint2D(0.0, 1.0)), newColor(2.0, 1.0, 3.0))
        check areClose(pigment.getColor(newPoint2D(1.0, 1.0)), newColor(3.0, 2.0, 1.0))
    

    test "newCheckeredPigment proc":
        # Checking newCheckeredPigment proc
        let pigment = newCheckeredPigment(color1, color2, 2)

        check areClose(pigment.getColor(newPoint2D(0.25, 0.25)), color1)
        check areClose(pigment.getColor(newPoint2D(0.75, 0.25)), color2)
        check areClose(pigment.getColor(newPoint2D(0.25, 0.75)), color2)
        check areClose(pigment.getColor(newPoint2D(0.75, 0.75)), color1)



#-----------------------------------#
#          BRDF test suite          #
#-----------------------------------#
suite "BRDF":

    setup:
        var
            dif = newDiffuseBRDF(newUniformPigment(newColor(1, 2, 3)), 0.2)
            spe = newSpecularBRDF(newUniformPigment(newColor(1, 2, 3)), 110)

    teardown:
        discard dif
        discard spe


    test "newBRDF proc":
        # Checking constructor procedures

        check areClose(dif.pigment.color.r, 1)
        check areClose(dif.pigment.color.g, 2)
        check areClose(dif.pigment.color.b, 3)
        check areClose(dif.reflectance, 0.2)

        check areClose(spe.pigment.color.r, 1)
        check areClose(spe.pigment.color.g, 2)
        check areClose(spe.pigment.color.b, 3)
        check areClose(spe.threshold_angle, 0.1 * degToRad(110.0).float32)
    

    test "eval proc":
        # Checking brdf evaluation
        var
            norm = newNormal(1, 0, 0)
            in_dir = newVec3f(1, 2, -1)
            out_dir = newVec3f(1, 2, 1)
            uv = newPoint2D(0.3, 0.5)
            appo: Color
        
        appo = dif.eval(norm, in_dir, out_dir, uv)
        check areClose(appo.r, 1 * 0.2/PI)
        check areClose(appo.g, 2 * 0.2/PI)
        check areClose(appo.b, 3 * 0.2/PI)

        appo = spe.eval(norm, in_dir, out_dir, uv)
        check areClose(appo.r, 1)
        check areClose(appo.g, 2)
        check areClose(appo.b, 3)
