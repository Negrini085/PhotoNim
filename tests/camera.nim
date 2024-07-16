import std/unittest
from math import sqrt, degToRad, PI
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
        check areClose(ray1.tSpan.min, 1e-5)
        check areClose(ray1.dir, newVec3f(1, 0, 0))
        check areClose(ray1.origin, newPoint3D(1, 2, 3))

        # Second ray check
        check ray2.depth == 0.int
        check ray2.tSpan.max == Inf
        check areClose(ray2.tSpan.min, 1e-5)
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
            T2 = newRotation(180.0, axisY)

        # First ray
        check areClose(ray1.transform(T1), newRay(newPoint3D(2, 4, 6), newVec3f(1, 0, 0)))
        check areClose(ray1.transform(T2), newRay(newPoint3D(-1, 2, -3), newVec3f(-1, 0, 0)), 1e-6)

        # Second ray
        check areClose(ray2.transform(T1), newRay(newPoint3D(2, 4, 3), newVec3f(1, 0, 0)))
        check areClose(ray2.transform(T2), newRay(newPoint3D(-1, 2, 0), newVec3f(-1, 0, 0)), 1e-6)



suite "Camera":

    setup:
        var 
            oCam = newOrthogonalCamera(
                newFlatRenderer(),
                viewport = (12, 10), newTranslation(newVec3f(-4, 0, 0))
            )
            pCam = newPerspectiveCamera(
                newFlatRenderer(),
                viewport = (12, 10), distance = 5, 
                newComposition(newRotation(45, axisX), newTranslation(newVec3f(-1, 0, 0)))
            )

    teardown:
        discard oCam
        discard pCam


    test "newCamera procs":
        # Checking Camera vaiables constructor

        # OrthogonalCamera
        check ocam.kind == ckOrthogonal
        check ocam.renderer.kind == rkFlat
        check ocam.viewport.width == 12
        check ocam.viewport.height == 10
        check areClose(oCam.aspect_ratio, 1.2)

        check ocam.transformation.kind == tkTranslation 
        check areClose(ocam.transformation.offset, newVec3f(-4, 0, 0)) 
    

        # Perspective Camera
        check pcam.kind == ckPerspective
        check pcam.renderer.kind == rkFlat
        check pcam.viewport.width == 12
        check pcam.viewport.height == 10
        check areClose(pCam.aspect_ratio, 1.2)

        check pcam.transformation.kind == tkComposition and pcam.transformation.transformations.len == 2
        check pcam.transformation.transformations[0].kind == tkRotation
        check pcam.transformation.transformations[0].axis == newRotation(45, axisX).axis 
        check areClose(pcam.transformation.transformations[0].cos, newRotation(45, axisX).cos) 
        check areClose(pcam.transformation.transformations[0].sin, newRotation(45, axisX).sin) 
        check pcam.transformation.transformations[1].kind == tkTranslation 
        check areClose(pcam.transformation.transformations[1].offset, newVec3f(-1, 0, 0)) 


    

    test "Orthogonal fireRay proc":
        # Checkin Orthogonal fireRay proc
        let trans = newTranslation(newVec3f(-4, 0, 0))
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
        check areClose(ray1.at(1.0), apply(trans, newPoint3D(0, 1.2, -1)))
        check areClose(ray2.at(1.0), apply(trans, newPoint3D(0, -1.2, -1)))
        check areClose(ray3.at(1.0), apply(trans, newPoint3D(0, 1.2, 1)))
        check areClose(ray4.at(1.0), apply(trans, newPoint3D(0, -1.2, 1)))
    

    test "Perspective fireRay proc":
        let trans = newComposition(newRotation(45, axisX), newTranslation(newVec3f(-1, 0, 0)))
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
        check areClose(ray1.dir, apply(trans, newVec3f(5,  1.2, -1)), eps =1e-6)
        check areClose(ray2.dir, apply(trans, newVec3f(5, -1.2, -1)), eps =1e-6)
        check areClose(ray3.dir, apply(trans, newVec3f(5,  1.2,  1)), eps =1e-6)
        check areClose(ray4.dir, apply(trans, newVec3f(5, -1.2,  1)), eps =1e-6)

        # Testing arrive point
        check areClose(ray1.at(1.0), apply(trans, newPoint3D(0, 1.2, -1)))
        check areClose(ray2.at(1.0), apply(trans, newPoint3D(0, -1.2, -1)))
        check areClose(ray3.at(1.0), apply(trans, newPoint3D(0, 1.2, 1)))
        check areClose(ray4.at(1.0), apply(trans, newPoint3D(0, -1.2, 1)))



#------------------------------------------#
#           Renderer test suite            #
#------------------------------------------#
suite "Renderer":

    setup:
        let 
            rs = newRandomSetUp(42, 54)
            rend = newPathTracer(1, 100, 101)
            camera = newPerspectiveCamera(rend, (1600, 900), 2)
        
    teardown:
        discard rs
        discard rend
        discard camera
    

    test "Furnace test":
        # Here we want to check if the path tracing algorithm we
        # implemented is actually working or not 

        var 
            col: Color
            exp: float32
            pcg = newPCG(rs)
            ray = newRay(ORIGIN3D, eX)

        let
            emiRad = pcg.rand
            refl = pcg.rand * 0.9

            sphere  = newUnitarySphere(
                    ORIGIN3D,
                    newDIffuseBRDF(newUniformPigment(WHITE * refl)),
                    newUniformPigment(WHITE * emiRad)
                )

            scene = newScene(BLACK, @[sphere], tkBinary, 1, newRandomSetUp(pcg.random, pcg.random))
        
        pcg = newPCG(newRandomSetUp(pcg.random, pcg.random))
        col = camera.sampleRay(scene, ray, pcg)
        exp = emiRad/(1 - refl)

        check areClose(exp, col.r, eps = 1e-3)
        check areClose(exp, col.g, eps = 1e-3)
        check areClose(exp, col.b, eps = 1e-3)

