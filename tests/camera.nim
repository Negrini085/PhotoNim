import std/unittest
import ../src/[camera, geometry, ray, renderer]


#---------------------------------------#
#           Camera test suite           #
#---------------------------------------#
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


    test "newOrthogonalCamera proc":
        # Checking Camera vaiables constructor

        # OrthogonalCamera
        check ocam.kind == ckOrthogonal
        check ocam.renderer.kind == rkFlat
        check ocam.viewport.width == 12
        check ocam.viewport.height == 10
        check areClose(oCam.aspect_ratio, 1.2)

        check ocam.transformation.kind == tkTranslation 
        check areClose(ocam.transformation.offset, newVec3(-4, 0, 0)) 
    

    test "newPerspectiveCamera proc":
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
