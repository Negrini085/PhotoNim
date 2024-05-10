import std/[unittest, math, options]
import PhotoNim/[shapes, geometry, camera]


#---------------------------------------#
#         Hit Record type tests         #
#---------------------------------------#
suite "HitRecord":

    setup:
        var 
            hit1 = newHitRecord(newRay(newPoint3D(0, 0, 0), newVec3[float32](0, 1, 0)), float32(0.5), newPoint3D(1, 2, 3), newPoint2D(1, 0), newNormal(1, 0, 0))
            hit2 = newHitRecord(newRay(newPoint3D(0, 0, 2), newVec3[float32](1, 1, 0)), float32(0.6), newPoint3D(1, 0, 0), newPoint2D(0.5, 0.5), newNormal(0, 1, 0))


    test "newHitRecord":
        # Checking newHitRecord procedure
        check areClose(hit1.world_point, newPoint3D(1, 2, 3))
        check areClose(hit1.map_pt, newPoint2D(1, 0))
        check areClose(hit1.normal, newNormal(1, 0, 0))
        check areClose(hit1.t, 0.5)
        check areClose(hit1.ray, newRay(newPoint3D(0, 0, 0), newVec3[float32](0, 1, 0)))


    test "areClose":
        # Checking areClose procedure for HitRecord variables
        check areClose(hit1, hit1)

        check not areClose(hit1.world_point, hit2.world_point)
        check not areClose(hit1.normal, hit2.normal)
        check not areClose(hit1.ray, hit2.ray)
        check not areClose(hit1.map_pt, hit2.map_pt)
        check not areClose(hit1.t, hit2.t)

        check not areClose(hit1, hit2)



#---------------------------------------#
#          Sphere type tests            #
#---------------------------------------#
suite "Sphere":

    setup:
        var sphere = newSphere(Transformation.id)

    test "SphereConstructor":
        # Checking sphere constructor procedure

        check areClose(sphere.transf.mat, Mat4f.id)
        check areClose(sphere.transf.inv_mat, Mat4f.id)
    

    test "Surface Normal":
        # Checking sphere normal computation method
        var
            p1 = newPoint3D(1, 0 ,0)
            p2 = newPoint3D(cos(PI/3), sin(PI/3) ,0)
            d = newVec3[float32](-1, 2, 0)
        
        check areClose(normalOnSphere(p1, d), newNormal(1, 0, 0))
        check areClose(normalOnSphere(p2, d), newNormal(-cos(PI/3), -sin(PI/3), 0))

    
    test "(u, v) coordinates":
        # Checking (u, v) coordinates computation
        var
            p1 = newPoint3D(1, 0, 1)
            p2 = newPoint3D(cos(PI/3), sin(PI/3), 0.5)

        check areClose(sphere_uv(p1), newPoint2D(0, 0))
        check areClose(sphere_uv(p2), newPoint2D(1/6, 1/3))
    

    test "RayIntersection: no transformation":
        # Checking ray intersection procedure on unitary shperical surface: no traslation is performed on sphere
        var
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3[float32](0, 0, -1))
            ray2 = newRay(newPoint3D(3, 0, 0), newVec3[float32](-1, 0, 0))
            ray3 = newRay(newPoint3D(0, 0, 0), newVec3[float32](1, 0, 0))

        check areClose(sphere.rayIntersection(ray1).get().world_point, newPoint3D(0, 0, 1))
        check areClose(sphere.rayIntersection(ray1).get().normal, newNormal(0, 0, 1))
        check areClose(sphere.rayIntersection(ray1).get().t, 1)
        check areClose(sphere.rayIntersection(ray1).get().map_pt, newPoint2D(0, 0))

        check areClose(sphere.rayIntersection(ray2).get().world_point, newPoint3D(1, 0, 0))
        check areClose(sphere.rayIntersection(ray2).get().normal, newNormal(1, 0, 0))
        check areClose(sphere.rayIntersection(ray2).get().t, 2)
        check areClose(sphere.rayIntersection(ray1).get().map_pt, newPoint2D(0, 0))

        check areClose(sphere.rayIntersection(ray3).get().world_point, newPoint3D(1, 0, 0))
        check areClose(sphere.rayIntersection(ray3).get().normal, newNormal(-1, 0, 0))
        check areClose(sphere.rayIntersection(ray3).get().t, 1)
        check areClose(sphere.rayIntersection(ray1).get().map_pt, newPoint2D(0, 0))
    

    test "RayIntersection: with transformation":
        # Checking ray intersection procedure: we are transforming the sphere
        var
            tr = newTranslation(newVec3[float32](10, 0, 0))

            ray1 = newRay(newPoint3D(10, 0, 2), newVec3[float32](0, 0, -1))
            ray2 = newRay(newPoint3D(13, 0, 0), newVec3[float32](-1, 0, 0))
            ray3 = newRay(newPoint3D(0, 0, 2), newVec3[float32](0, 0, -1))
            ray4 = newRay(newPoint3D(-10, 0, 0), newVec3[float32](0, 0, -1))
        
        sphere.transf = tr

        check areClose(sphere.rayIntersection(ray1).get().world_point, newPoint3D(10, 0, 1))
        check areClose(sphere.rayIntersection(ray1).get().normal, newNormal(0, 0, 1))
        check areClose(sphere.rayIntersection(ray1).get().t, 1)
        check areClose(sphere.rayIntersection(ray1).get().map_pt, newPoint2D(0, 0))

        check areClose(sphere.rayIntersection(ray2).get().world_point, newPoint3D(11, 0, 0))
        check areClose(sphere.rayIntersection(ray2).get().normal, newNormal(1, 0, 0))
        check areClose(sphere.rayIntersection(ray2).get().t, 2)
        check areClose(sphere.rayIntersection(ray2).get().map_pt, newPoint2D(0, 0.5))

        sphere.transf = Transformation.id
        check sphere.rayIntersection(ray3).isSome
        check not sphere.rayIntersection(ray4).isSome
    

    test "FastIntersection":
        # Checking Fast intersection method
        var
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3[float32](0, 0, -1))
            ray2 = newRay(newPoint3D(-10, 0, 0), newVec3[float32](0, 0, -1))
        
        check sphere.fastIntersection(ray1)
        check not sphere.fastIntersection(ray2)



#---------------------------------------#
#           Plane type tests            #
#---------------------------------------#
suite "Plane":

    setup:
        var plane = newPlane(Transformation.id)

    test "PlaneConstructor":
        # Checking plane constructor procedure

        check areClose(plane.transf.mat, Mat4f.id)
        check areClose(plane.transf.inv_mat, Mat4f.id)

    
    test "RayIntersection: no transformation":
        # Checking ray intersection procedure on plane: no trasformation is performed
        var
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3[float32](0, 0, -1))
            ray2 = newRay(newPoint3D(1, -2, -3), newVec3[float32](0, 4/5, 3/5))
            ray3 = newRay(newPoint3D(3, 0, 0), newVec3[float32](-1, 0, 0))

        check areClose(plane.rayIntersection(ray1).get().world_point, newPoint3D(0, 0, 0))
        check areClose(plane.rayIntersection(ray1).get().normal, newNormal(0, 0, 1))
        check areClose(plane.rayIntersection(ray1).get().t, 2)
        check areClose(plane.rayIntersection(ray1).get().map_pt, newPoint2D(0, 0))

        check areClose(plane.rayIntersection(ray2).get().world_point, newPoint3D(1, 2, 0))
        check areClose(plane.rayIntersection(ray2).get().normal, newNormal(0, 0, -1))
        check areClose(plane.rayIntersection(ray2).get().t, 5)
        check areClose(plane.rayIntersection(ray2).get().map_pt, newPoint2D(0, 0))

        check not plane.rayIntersection(ray3).isSome


    test "RayIntersection: with transformation":
        # Checking ray intersection procedure on plane: a translation along the z axis is performed
        var
            tr = newTranslation(newVec3[float32](0, 0, 3))
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3[float32](0, 0, -1))
            ray2 = newRay(newPoint3D(3, 0, 0), newVec3[float32](-1, 0, 0))
            ray3 = newRay(newPoint3D(1, -2, -3), newVec3[float32](0, 4/5, 3/5))
        
        plane.transf = tr

        check not plane.rayIntersection(ray1).isSome
        check not plane.rayIntersection(ray2).isSome

        check areClose(plane.rayIntersection(ray3).get().world_point, newPoint3D(1, 6, 3))
        check areClose(plane.rayIntersection(ray3).get().normal, newNormal(0, 0, -1))
        check areClose(plane.rayIntersection(ray3).get().t, 10)
        check areClose(plane.rayIntersection(ray3).get().map_pt, newPoint2D(0, 0))
    

    test "FastIntersection":
        # Checking Fast intersection method
        var
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3[float32](0, 0, -1))
            ray2 = newRay(newPoint3D(1, 0, 1), newVec3[float32](0, 0, 1))
            ray3 = newRay(newPoint3D(3, 0, 0), newVec3[float32](-1, 0, 0))
        
        check plane.fastIntersection(ray1)
        check not plane.fastIntersection(ray2)
        check not plane.fastIntersection(ray3)




#---------------------------------------#
#           World type tests            #
#---------------------------------------#
suite "World":
    
    setup:
        var 
            scenary = newWorld()
            sphere = newSphere(Transformation.id)
    
    test "add proc":
        # Checking world add procedure

        scenary.add(sphere)
        check areClose(scenary.shapes[0].transf.mat, Mat4f.id)
        check areClose(scenary.shapes[0].transf.inv_mat, Mat4f.id)

    test "get proc":
        # Checking world get procedure

        scenary.add(sphere)
        check areClose(scenary.get(0).transf.mat, Mat4f.id)
        check areClose(scenary.get(0).transf.inv_mat, Mat4f.id)
