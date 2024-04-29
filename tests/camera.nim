import std/[unittest, math]
import PhotoNim/[transformations, common, geometry, camera]

#----------------------------------#
#          Ray type tests          #
#----------------------------------#
suite "Ray tests":

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


    test "areClose":
        # Checking areClose procedure
        var
            ray1 = newRay(newPoint3D(1, 2, 3), newVec3[float32](1, 0, 0))
            ray2 = newRay(newPoint3D(1, 2, 0), newVec3[float32](1, 0, 0))

        check areClose(ray, ray1)
        check not areClose(ray, ray2)
    

    test "translateRay":
        # Checking ray translation procedures
        var 
            vec1 = newVec3[float32](0, 0, 0)
            vec2 = newVec3[float32](1, 2, 3)

        check areClose(ray.translateRay(vec1).start, newPoint3D(1, 2, 3))
        check areClose(ray.translateRay(vec2).start, newPoint3D(2, 4, 6))
    

    test "transformRay":
        # Checking ray rotation procedures
        var 
            T1 = newTranslation(newVec4[float32](1, 2, 3, 0))
            T2 = newRotY(180)

        check areClose(transformRay(T1, ray),  newRay(newPoint3D(2, 4, 6), newVec3[float32](1, 0, 0)))
        check areClose(transformRay(T2, ray).dir, newVec3[float32](-1, 0, 0))
        #check areClose(transformRay(T2, ray),  newRay(newPoint3D(-1, 2, -3), newVec3[float32](-1, 0, 0)))



#-------------------------------------#
#          Camera type tests          #
#-------------------------------------#
suite "Camera tests":

    var 
        oCam = newCamera(1.2, newTranslation(newVec4[float32](1, 2, 3, 0)))
        pCam = newCamera(1.2, 5, newTranslation(newVec4[float32](-1, -2, -3, 0)))

    test "Orthogonal Contructor":
        # Testing ortogonal type constructor
        
        check areClose(oCam.aspect_ratio, 1.2)
        check oCam.T.is_consistent()
        check areClose(oCam.T @ newVec4[float32](0, 0, 0, 1), newVec4[float32](1, 2, 3, 1))

    
    test "Orthogonal Contructor":
        # Testing ortogonal type constructor
        
        check areClose(pCam.aspect_ratio, 1.2)
        check pCam.T.is_consistent()
        check areClose(pCam.T @ newVec4[float32](0, 0, 0, 1), newVec4[float32](-1, -2, -3, 1))
    

    test "Orthogonal Fire Ray":
        # Testing orthogonal fire_ray procedure: a ray is fired
        # Change ray transformation to identity, such ad a (0, 0, 0) vec translation
        ocam.T = newTranslation(newVec4[float32](0, 0, 0, 0))

        var 
            ray1 = oCam.fire_ray(0, 0)
            ray2 = oCam.fire_ray(1, 0)
            ray3 = oCam.fire_ray(0, 1)
            ray4 = oCam.fire_ray(1, 1)
        
        # Testing ray parallelism
        check areClose(0.0, cross(ray1.dir, ray2.dir).norm())
        check areClose(0.0, cross(ray1.dir, ray3.dir).norm())
        check areClose(0.0, cross(ray1.dir, ray4.dir).norm())

        # Testing direction
        check areClose(ray1.dir, vec_ex)
        check areClose(ray2.dir, vec_ex)
        check areClose(ray3.dir, vec_ex)
        check areClose(ray4.dir, vec_ex)

        # Testing arrive point
        check areClose(ray1.at(1.0), newPoint3D(0, 1.2, -1))
        check areClose(ray2.at(1.0), newPoint3D(0, -1.2, -1))
        check areClose(ray3.at(1.0), newPoint3D(0, 1.2, 1))
        check areClose(ray4.at(1.0), newPoint3D(0, -1.2, 1))
    

    test "Perspective Fire Ray":
        # Testing perspective fire_ray procedure: a ray is fired
        # Change ray transformation to identity, such ad a (0, 0, 0) vec translation
        pcam.T = newTranslation(newVec4[float32](0, 0, 0, 0))

        var 
            ray1 = pCam.fire_ray(0, 0)
            ray2 = pCam.fire_ray(1, 0)
            ray3 = pCam.fire_ray(0, 1)
            ray4 = pCam.fire_ray(1, 1)

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
    