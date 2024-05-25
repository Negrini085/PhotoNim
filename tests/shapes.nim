import std/[unittest, math, options]
import PhotoNim

proc areClose(a, b: HitRecord): bool {.inline.} = 
    areClose(a.ray, b.ray) and areClose(a.t, b.t) and 
    areClose(a.world_pt, b.world_pt) and areClose(a.surface_pt, b.surface_pt) and 
    areClose(a.normal, b.normal) 


suite "HitRecord":

    setup:
        var 
            hit1 = HitRecord(ray: newRay(newPoint3D(0, 0, 0), newVec3(float32 0, 1, 0)), t: float32(0.5), world_pt: newPoint3D(1, 2, 3), surface_pt: newPoint2D(1, 0), normal: newNormal(1, 0, 0))
            hit2 = HitRecord(ray: newRay(newPoint3D(0, 0, 2), newVec3(float32 1, 1, 0)), t: float32(0.6), world_pt: newPoint3D(1, 0, 0), surface_pt: newPoint2D(0.5, 0.5), normal: newNormal(0, 1, 0))

    teardown:
        discard hit1; discard hit2

    test "newHitRecord":
        # Checking newHitRecord procedure
        check areClose(hit1.world_pt, newPoint3D(1, 2, 3))
        check areClose(hit1.surface_pt, newPoint2D(1, 0))
        check areClose(hit1.normal, newNormal(1, 0, 0))
        check areClose(hit1.t, 0.5)
        check areClose(hit1.ray, newRay(newPoint3D(0, 0, 0), newVec3(float32 0, 1, 0)))


    test "areClose":
        # Checking areClose procedure for HitRecord variables
        check areClose(hit1, hit1)

        check not areClose(hit1.world_pt, hit2.world_pt)
        check not areClose(hit1.normal, hit2.normal)
        check not areClose(hit1.ray, hit2.ray)
        check not areClose(hit1.surface_pt, hit2.surface_pt)
        check not areClose(hit1.t, hit2.t)

        check not areClose(hit1, hit2)



#---------------------------------------#
#          Sphere type tests            #
#---------------------------------------#
suite "Sphere":

    setup:
        var sphere = newUnitarySphere(newPoint3D(0, 0, 0))
        var sphere1 = newSphere(newPoint3D(0, 1, 0), 3.0)

    teardown: 
        discard sphere; discard sphere1

    test "newSphere proc":
        check sphere1.radius == 3.0
        check sphere1.center == newPoint3D(0, 1, 0)

        check sphere1.transf.kind == tkComposition
        check sphere1.transf.transformations[0].mat == newTranslation(newVec3(float32 0, 1, 0)).mat
        check sphere1.transf.transformations[1].mat == newScaling(3.0).mat


    test "newUnitarySphere proc":
        # Checking sphere constructor procedure

        check areClose(sphere.transf.mat, Mat4f.id)
        check areClose(sphere.transf.inv_mat, Mat4f.id)
    

    test "Surface Normal":
        # Checking sphere normal computation method
        var
            p1 = newPoint3D(1, 0 ,0)
            p2 = newPoint3D(cos(PI/3), sin(PI/3) ,0)
            d = newVec3(float32 -1, 2, 0)
        
        check areClose(sphere.normal(p1, d), newNormal(1, 0, 0))
        check areClose(sphere.normal(p2, d), newNormal(-cos(PI/3), -sin(PI/3), 0))

    
    test "(u, v) coordinates":
        # Checking (u, v) coordinates computation
        var
            p1 = newPoint3D(1, 0, 1)
            p2 = newPoint3D(cos(PI/3), sin(PI/3), 0.5)

        check areClose(sphere.uv(p1), newPoint2D(0, 0))
        check areClose(sphere.uv(p2), newPoint2D(1/6, 1/3))
    

    test "RayIntersection: no transformation":
        # Checking ray intersection procedure on unitary shperical surface: no traslation is performed on sphere
        var
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3(float32 0, 0, -1))
            ray2 = newRay(newPoint3D(3, 0, 0), newVec3(float32 -1, 0, 0))
            ray3 = newRay(newPoint3D(0, 0, 0), newVec3(float32 1, 0, 0))

        let 
            hit1 = sphere.rayIntersection(ray1).get
            hit2 = sphere.rayIntersection(ray2).get
            hit3 = sphere.rayIntersection(ray3).get

        check areClose(hit1.world_pt, newPoint3D(0, 0, 1))
        check areClose(hit1.normal, newNormal(0, 0, 1))
        check areClose(hit1.t, 1)
        check areClose(hit1.surface_pt, newPoint2D(0, 0))

        check areClose(hit2.world_pt, newPoint3D(1, 0, 0))
        check areClose(hit2.normal, newNormal(1, 0, 0))
        check areClose(hit2.t, 2)
        check areClose(hit1.surface_pt, newPoint2D(0, 0))

        check areClose(hit3.world_pt, newPoint3D(1, 0, 0))
        check areClose(hit3.normal, newNormal(-1, 0, 0))
        check areClose(hit3.t, 1)
        check areClose(hit1.surface_pt, newPoint2D(0, 0))
    

    test "RayIntersection: with transformation":
        # Checking ray intersection procedure: we are transforming the sphere
        var
            tr = newTranslation(newVec3(float32 10, 0, 0))

            ray1 = newRay(newPoint3D(10, 0, 2), newVec3(float32 0, 0, -1))
            ray2 = newRay(newPoint3D(13, 0, 0), newVec3(float32 -1, 0, 0))
            ray3 = newRay(newPoint3D(0, 0, 2), newVec3(float32 0, 0, -1))
            ray4 = newRay(newPoint3D(-10, 0, 0), newVec3(float32 0, 0, -1))
        
        sphere.transf = tr
        let 
            intersect1 = sphere.rayIntersection(ray1).get
            intersect2 = sphere.rayIntersection(ray2).get

        check areClose(intersect1.world_pt, newPoint3D(10, 0, 1))
        check areClose(intersect1.normal, newNormal(0, 0, 1))
        check areClose(intersect1.t, 1)
        check areClose(intersect1.surface_pt, newPoint2D(0, 0))

        check areClose(intersect2.world_pt, newPoint3D(11, 0, 0))
        check areClose(intersect2.normal, newNormal(1, 0, 0))
        check areClose(intersect2.t, 2)
        check areClose(intersect2.surface_pt, newPoint2D(0, 0.5))

        sphere.transf = Transformation.id
        check sphere.rayIntersection(ray3).isSome
        check not sphere.rayIntersection(ray4).isSome
    

    test "FastIntersection":
        # Checking Fast intersection method
        var
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3(float32 0, 0, -1))
            ray2 = newRay(newPoint3D(-10, 0, 0), newVec3(float32 0, 0, -1))
        
        check sphere.fastIntersection(ray1)
        check not sphere.fastIntersection(ray2)



suite "Plane":

    setup:
        var plane = newPlane(Transformation.id)

    test "PlaneConstructor":
        check plane.transf.kind == tkIdentity

    
    test "RayIntersection: no transformation":
        # Checking ray intersection procedure on plane: no trasformation is performed
        var
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3(float32 0, 0, -1))
            ray2 = newRay(newPoint3D(1, -2, -3), newVec3(float32 0, 4/5, 3/5))
            ray3 = newRay(newPoint3D(3, 0, 0), newVec3(float32 -1, 0, 0))

        check areClose(plane.rayIntersection(ray1).get.world_pt, newPoint3D(0, 0, 0))
        check areClose(plane.rayIntersection(ray1).get.normal, newNormal(0, 0, 1))
        check areClose(plane.rayIntersection(ray1).get.t, 2)
        check areClose(plane.rayIntersection(ray1).get.surface_pt, newPoint2D(0, 0))

        check areClose(plane.rayIntersection(ray2).get.world_pt, newPoint3D(1, 2, 0))
        check areClose(plane.rayIntersection(ray2).get.normal, newNormal(0, 0, -1))
        check areClose(plane.rayIntersection(ray2).get.t, 5)
        check areClose(plane.rayIntersection(ray2).get.surface_pt, newPoint2D(0, 0))

        check not plane.rayIntersection(ray3).isSome


    test "RayIntersection: with transformation":
        # Checking ray intersection procedure on plane: a translation along the z axis is performed
        var
            tr = newTranslation(newVec3(float32 0, 0, 3))
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3(float32 0, 0, -1))
            ray2 = newRay(newPoint3D(3, 0, 0), newVec3(float32 -1, 0, 0))
            ray3 = newRay(newPoint3D(1, -2, -3), newVec3(float32 0, 4/5, 3/5))
        
        plane.transf = tr

        check not plane.rayIntersection(ray1).isSome
        check not plane.rayIntersection(ray2).isSome

        check areClose(plane.rayIntersection(ray3).get().world_pt, newPoint3D(1, 6, 3))
        check areClose(plane.rayIntersection(ray3).get().normal, newNormal(0, 0, -1))
        check areClose(plane.rayIntersection(ray3).get().t, 10)
        check areClose(plane.rayIntersection(ray3).get().surface_pt, newPoint2D(0, 0))
    

    test "FastIntersection":
        # Checking Fast intersection method
        var
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3(float32 0, 0, -1))
            ray2 = newRay(newPoint3D(1, 0, 1), newVec3(float32 0, 0, 1))
            ray3 = newRay(newPoint3D(3, 0, 0), newVec3(float32 -1, 0, 0))
        
        check plane.fastIntersection(ray1)
        check not plane.fastIntersection(ray2)
        check not plane.fastIntersection(ray3)


suite "AABB":
    test "AABB constructor": 
        let 
            box = newAABox()
            sphere = newUnitarySphere(newPoint3D(0, 0, 0))
            plane = newPlane()

        check box.aabb.isSome
        check sphere.aabb.isNone and plane.aabb.isNone


suite "AABox":

    setup: 
        let box = newAABox()

    teardown:
        discard box

    test "fastIntersection": 
        check fastIntersection(box, newRay(newPoint3D(0.5, 0.5, 0.5), newVec3(float32 0.0, 0.0, 0.0)))
        check not fastIntersection(box, newRay(newPoint3D(0.5, 0.5, 0.5), -newVec3(float32 0.0, 0.0, 0.0)))
        

#-----------------------------------------#
#            World type test              #
#-----------------------------------------#

suite "World":
    
    setup:
        var 
            s1 = newSphere(newPoint3D(1, 1, 0), 1)
            s2 = newSphere(newPoint3D(1, 0, 1), 0.5)
            scenery = newWorld(@[s1, s2])

    teardown: 
        discard scenery
            
    
    test "add/get proc":
        # Testing add/get procedure

        scenery.shapes.add newUnitarySphere(newPoint3D(0, 0, 0))
        check areClose(scenery.shapes[2].transf.mat, Mat4f.id)
        check areClose(scenery.shapes[2].transf.inv_mat, Mat4f.id)


    test "fastIntersection proc":
        # Testing fastIntersection procedure on world scenery

        var
            ray1 = newRay(newPoint3D(1, -2, 0), newVec3f(0, 1, 0))
            ray2 = newRay(newPoint3D(1, 3, 0), newVec3f(0, 1, 0))
        
        check fastIntersection(scenery, ray1)
        check not fastIntersection(scenery, ray2)
    

    test "rayIntersection proc":
        # Testing rayIntersection procedure on world scenery

        var
            ray1 = newRay(newPoint3D(1, -2, 0), newVec3f(0, 1, 0))
            ray2 = newRay(newPoint3D(1, 3, 0), newVec3f(0, 1, 0))
            hit: Option[HitRecord]
        
        scenery.shapes = @[s1, s2]
        
        # Intersection with first ray, we expect to have hit
        # in (1, 0, 0) at time t = 2
        hit = rayIntersection(scenery, ray1)
        check hit.isSome
        check areClose(hit.get.world_pt, newPoint3D(1, 0, 0))
        check areClose(hit.get.t, 2)
        check areClose(hit.get.normal.toVec3, newVec3f(0, -1, 0))
        check areClose(hit.get.surface_pt, newPoint2D(0.75, 0.5))

        # Intersection with second ray, we expect not to have a hit
        hit = rayIntersection(scenery, ray2)
        check hit.isNone
