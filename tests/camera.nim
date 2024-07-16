import std/unittest
from math import sqrt, degToRad, PI
import PhotoNim

suite "Camera":

    setup:
        var 
            oCam = newOrthogonalCamera(
                newFlatRenderer(),
                viewport = (12, 10), newTranslation(newVec3(-4, 0, 0))
            )
            pCam = newPerspectiveCamera(
                newFlatRenderer(),
                viewport = (12, 10), distance = 5, 
                newComposition(newRotation(45, axisX), newTranslation(newVec3(-1, 0, 0)))
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
        check areClose(ocam.transformation.offset, newVec3(-4, 0, 0)) 
    

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
        check areClose(pcam.transformation.transformations[1].offset, newVec3(-1, 0, 0)) 


    

    test "Orthogonal fireRay proc":
        # Checkin Orthogonal fireRay proc
        let trans = newTranslation(newVec3(-4, 0, 0))
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
        check areClose(ray1.at(1.0), apply(trans, newPoint3D(0.0, 1.2,-1.0)))
        check areClose(ray2.at(1.0), apply(trans, newPoint3D(0.0,-1.2,-1.0)))
        check areClose(ray3.at(1.0), apply(trans, newPoint3D(0.0, 1.2, 1.0)))
        check areClose(ray4.at(1.0), apply(trans, newPoint3D(0.0,-1.2, 1.0)))
    

    test "Perspective fireRay proc":
        let trans = newComposition(newRotation(45, axisX), newTranslation(newVec3(-1, 0, 0)))
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
        check areClose(ray1.dir, apply(trans, newVec3(5.0,  1.2, -1.0)), eps =1e-6)
        check areClose(ray2.dir, apply(trans, newVec3(5.0, -1.2, -1.0)), eps =1e-6)
        check areClose(ray3.dir, apply(trans, newVec3(5.0,  1.2,  1.0)), eps =1e-6)
        check areClose(ray4.dir, apply(trans, newVec3(5.0, -1.2,  1.0)), eps =1e-6)

        # Testing arrive point
        check areClose(ray1.at(1.0), apply(trans, newPoint3D(0.0, 1.2,-1.0)))
        check areClose(ray2.at(1.0), apply(trans, newPoint3D(0.0,-1.2,-1.0)))
        check areClose(ray3.at(1.0), apply(trans, newPoint3D(0.0, 1.2, 1.0)))
        check areClose(ray4.at(1.0), apply(trans, newPoint3D(0.0,-1.2, 1.0)))



#------------------------------------------#
#           Renderer test suite            #
#------------------------------------------#
suite "Renderer":

    setup:
        let rs = newRandomSetUp(42, 54)
        
        var 
            rend = newPathTracer(1, 100, 101)
            camera = newPerspectiveCamera(rend, (1600, 900), 2)
        
    teardown:
        discard rs
        discard rend
        discard camera


    test "OnOffRenderer test":
        # Here we want to check if the OnOffRenderer algorithm we
        # implemented is actually working or not 

        var pcg = newPCG(rs)

        let
            sph = newSphere(ORIGIN3D, 0.2,
                newDiffuseBRDF(newUniformPigment(WHITE))
            )

            scene = newScene(BLACK, @[sph], tkBinary, 1, newRandomSetUp(pcg.random, pcg.random))
        
        rend = newOnOffRenderer()
        camera.renderer = rend
        camera.viewport = (3, 3)

        let image = camera.sample(scene, newRandomSetUp(pcg.random, pcg.random))

        check areClose(image.getPixel(0, 0), BLACK)
        check areClose(image.getPixel(1, 0), BLACK)
        check areClose(image.getPixel(2, 0), BLACK)
    
        check areClose(image.getPixel(0, 1), BLACK)
        check areClose(image.getPixel(1, 1), WHITE)
        check areClose(image.getPixel(1, 2), BLACK)

        check areClose(image.getPixel(0, 2), BLACK)
        check areClose(image.getPixel(1, 2), BLACK)
        check areClose(image.getPixel(2, 2), BLACK)


    test "FlatRenderer test":
        # Here we want to check if the FlatRenderer algorithm we
        # implemented is actually working or not 

        var pcg = newPCG(rs)

        let
            sph = newSphere(ORIGIN3D, 0.2,
                newDiffuseBRDF(newUniformPigment(newColor(0.2, 0.3, 0.5))),
                newUniformPigment(newColor(0.2, 0.3, 0.5)) 
            )

            scene = newScene(BLACK, @[sph], tkBinary, 1, newRandomSetUp(pcg.random, pcg.random))
        
        rend = newFlatRenderer()
        camera.renderer = rend
        camera.viewport = (3, 3)

        let image = camera.sample(scene, newRandomSetUp(pcg.random, pcg.random))

        check areClose(image.getPixel(0, 0), BLACK)
        check areClose(image.getPixel(1, 0), BLACK)
        check areClose(image.getPixel(2, 0), BLACK)
    
        check areClose(image.getPixel(0, 1), BLACK)
        check areClose(image.getPixel(1, 1), newColor(0.2, 0.3, 0.5))
        check areClose(image.getPixel(1, 2), BLACK)

        check areClose(image.getPixel(0, 2), BLACK)
        check areClose(image.getPixel(1, 2), BLACK)
        check areClose(image.getPixel(2, 2), BLACK)


    test "Furnace test":
        # Here we want to check if the path tracing algorithm we
        # implemented is actually working or not 

        var 
            col: Color
            exp: float32
            pcg = newPCG(rs)
            ray = newRay(ORIGIN3D, eX)

        for _ in 0..500:
                
            let
                emiRad = pcg.rand
                refl = pcg.rand * 0.9

                sphere = newUnitarySphere(
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