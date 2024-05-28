import std/[unittest, math, options]
import PhotoNim

proc areClose(a, b: HitRecord): bool {.inline.} = 
    areClose(a.ray, b.ray) and areClose(a.t_hit, b.t_hit) and 
    areClose(a.world_pt, b.world_pt) and areClose(a.surface_pt, b.surface_pt) and 
    areClose(a.normal, b.normal) 


suite "HitRecord":

    setup:
        var 
            hit1 = HitRecord(ray: newRay(newPoint3D(0, 0, 0), newVec3f(0, 1, 0)), t_hit: float32(0.5), world_pt: newPoint3D(1, 2, 3), surface_pt: newPoint2D(1, 0), normal: newNormal(1, 0, 0))
            hit2 = HitRecord(ray: newRay(newPoint3D(0, 0, 2), newVec3f(1, 1, 0)), t_hit: float32(0.6), world_pt: newPoint3D(1, 0, 0), surface_pt: newPoint2D(0.5, 0.5), normal: newNormal(0, 1, 0))

    teardown:
        discard hit1; discard hit2

    test "newHitRecord":
        # Checking newHitRecord procedure
        check areClose(hit1.world_pt, newPoint3D(1, 2, 3))
        check areClose(hit1.surface_pt, newPoint2D(1, 0))
        check areClose(hit1.normal, newNormal(1, 0, 0))
        check areClose(hit1.t_hit, 0.5)
        check areClose(hit1.ray, newRay(newPoint3D(0, 0, 0), newVec3f(0, 1, 0)))


    test "areClose":
        # Checking areClose procedure for HitRecord variables
        check areClose(hit1, hit1)

        check not areClose(hit1.world_pt, hit2.world_pt)
        check not areClose(hit1.normal, hit2.normal)
        check not areClose(hit1.ray, hit2.ray)
        check not areClose(hit1.surface_pt, hit2.surface_pt)
        check not areClose(hit1.t_hit, hit2.t_hit)

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
        check sphere1.transf.transformations[0].kind == tkScaling
        check sphere1.transf.transformations[0].mat == newScaling(3.0).mat
        check sphere1.transf.transformations[1].kind == tkTranslation
        check sphere1.transf.transformations[1].mat == newTranslation(newVec3f(0, 1, 0)).mat


    test "newUnitarySphere proc":
        # Checking sphere constructor procedure

        check areClose(sphere.transf.mat, Mat4f.id)
        check areClose(sphere.transf.inv_mat, Mat4f.id)
    

    test "Surface Normal":
        # Checking sphere normal computation method
        var
            p1 = newPoint3D(1, 0 ,0)
            p2 = newPoint3D(cos(PI/3), sin(PI/3) ,0)
            d = newVec3f(-1, 2, 0)
        
        check areClose(sphere.normal(p1, d), newNormal(1, 0, 0))
        check areClose(sphere.normal(p2, d), newNormal(-cos(PI/3), -sin(PI/3), 0))

        check areClose(sphere1.normal(4.float32 * p1, d), newNormal(1, 0, 0))


    test "(u, v) mapping proc":
        # Checking (u, v) coordinates computation
        var
            p1 = newPoint3D(1, 0, 1)
            p2 = newPoint3D(cos(PI/3), sin(PI/3), 0.5)

        check areClose(sphere.uv(p1), newPoint2D(0, 0))
        check areClose(sphere.uv(p2), newPoint2D(1/6, 1/3))

    
    test "in_shape proc":
        # in_shape test
        var
            p1 = newPoint3D(1, 0, 0)
            p2 = newPoint3D(0, 0, 0.5)
            p3 = newPoint3D(0, 2, 0)

        check sphere.in_shape(p1)
        check sphere.in_shape(p2)
        check not sphere.in_shape(p3)

        check sphere1.in_shape(p1)
        check sphere1.in_shape(p2)
        check sphere1.in_shape(p3)


    test "FastIntersection":
        # Checking Fast intersection method
        var
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3f(0, 0, -1))
            ray2 = newRay(newPoint3D(-10, 0, 0), newVec3f(0, 0, -1))
        
        check sphere.fastIntersection(ray1)
        check not sphere.fastIntersection(ray2)

        check sphere1.fastIntersection(ray1)
        check not sphere1.fastIntersection(ray2)
    

    test "rayIntersection proc":
        # Checking ray intersection with sphere shape
        var
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3f(0, 0, -1))
            ray2 = newRay(newPoint3D(3, 0, 0), newVec3f(-1, 0, 0))
            ray3 = newRay(newPoint3D(0, 0, 0), newVec3f(1, 0, 0))
        
        #---------------------------------------------------#
        #           Checking with unitary sphere            #
        #---------------------------------------------------#
        var
            hit1 = sphere.rayIntersection(ray1).get
            hit2 = sphere.rayIntersection(ray2).get
            hit3 = sphere.rayIntersection(ray3).get

        check areClose(hit1.world_pt, newPoint3D(0, 0, 1))
        check areClose(hit1.normal, newNormal(0, 0, 1))
        check areClose(hit1.t_hit, 1)
        check areClose(hit1.surface_pt, newPoint2D(0, 0))

        check areClose(hit2.world_pt, newPoint3D(1, 0, 0))
        check areClose(hit2.normal, newNormal(1, 0, 0))
        check areClose(hit2.t_hit, 2)
        check areClose(hit1.surface_pt, newPoint2D(0, 0))

        check areClose(hit3.world_pt, newPoint3D(1, 0, 0))
        check areClose(hit3.normal, newNormal(-1, 0, 0))
        check areClose(hit3.t_hit, 1)
        check areClose(hit1.surface_pt, newPoint2D(0, 0))


        #---------------------------------------------------#
        #           Checking with generic sphere            #
        #---------------------------------------------------#
        ray1.origin = newPoint3D(0, 1, 2)    
        ray2.origin = newPoint3D(4, 1, 0)
        ray3.dir = newVec3f(0, 1, 0)    

        hit1 = sphere1.rayIntersection(ray1).get
        hit2 = sphere1.rayIntersection(ray2).get
        hit3 = sphere1.rayIntersection(ray3).get


        check areClose(hit1.world_pt, newPoint3D(0, 1, -3), eps = 1e-6)
        check areClose(hit1.normal, newNormal(0, 0, 1), eps = 1e-6)
        check areClose(hit1.t_hit, 5, eps = 1e-6)

        check areClose(hit2.world_pt, newPoint3D(3, 1, 0), eps = 1e-6)
        check areClose(hit2.normal, newNormal(1, 0, 0), eps = 1e-6)
        check areClose(hit2.t_hit, 1, eps = 1e-6)

        check areClose(hit3.world_pt, newPoint3D(0, 4, 0), eps = 1e-6)
        check areClose(hit3.normal, newNormal(0, -1, 0), eps = 1e-6)
        check areClose(hit3.t_hit, 4.0, eps = 1e-6)


    test "RayIntersection: with transformation":
        # Checking ray intersection procedure: we are transforming the sphere
        var
            tr = newTranslation(newVec3f( 10, 0, 0))

            ray1 = newRay(newPoint3D(10, 0, 2), newVec3f(0, 0, -1))
            ray2 = newRay(newPoint3D(13, 0, 0), newVec3f(-1, 0, 0))
            ray3 = newRay(newPoint3D(0, 0, 2), newVec3f(0, 0, -1))
            ray4 = newRay(newPoint3D(-10, 0, 0), newVec3f(0, 0, -1))
        
        sphere.transf = tr
        let 
            intersect1 = sphere.rayIntersection(ray1).get
            intersect2 = sphere.rayIntersection(ray2).get

        #---------------------------------------------------#
        #           Checking with unitary sphere            #
        #---------------------------------------------------#
        check areClose(intersect1.world_pt, newPoint3D(10, 0, 1))
        check areClose(intersect1.normal, newNormal(0, 0, 1))
        check areClose(intersect1.t_hit, 1)
        check areClose(intersect1.surface_pt, newPoint2D(0, 0))

        check areClose(intersect2.world_pt, newPoint3D(11, 0, 0))
        check areClose(intersect2.normal, newNormal(1, 0, 0))
        check areClose(intersect2.t_hit, 2)
        check areClose(intersect2.surface_pt, newPoint2D(0, 0.5))

        sphere.transf = Transformation.id
        check sphere.rayIntersection(ray3).isSome
        check not sphere.rayIntersection(ray4).isSome


    test "allRayIntersections proc":
        # Checking all ray intersection proc
        var
            appo: Option[seq[HitRecord]]

            ray1 = newRay(newPoint3D(0, -3, 0), newVec3f(0, 1, 0))
            ray2 = newRay(newPoint3D(-4, 1, 0), newVec3f(1, 0, 0))
            ray3 = newRay(newPoint3D(0, -3, 0), newVec3f(0, -1, 0))

        appo = sphere1.allRayIntersections(ray1)
        check appo.isSome

        check areClose(appo.get[0].t_hit, 1, eps = 1e-6)
        check areClose(appo.get[1].t_hit, 7, eps = 1e-6)
        check areClose(appo.get[0].world_pt, newPoint3D(0, -2, 0), eps = 1e-6)
        check areClose(appo.get[1].world_pt, newPoint3D(0, 4, 0), eps = 1e-6)
        

        appo = sphere1.allRayIntersections(ray2)
        check appo.isSome

        check areClose(appo.get[0].t_hit, 1, eps = 1e-6)
        check areClose(appo.get[1].t_hit, 7, eps = 1e-6)
        check areClose(appo.get[0].world_pt, newPoint3D(-3, 1, 0), eps = 1e-6)
        check areClose(appo.get[1].world_pt, newPoint3D(3, 1, 0), eps = 1e-6)


        appo = sphere1.allRayIntersections(ray3)
        check not appo.isSome


suite "Plane":

    setup:
        var plane = newPlane(Transformation.id)

    test "PlaneConstructor":
        check plane.transf.kind == tkIdentity

    
    test "RayIntersection: no transformation":
        # Checking ray intersection procedure on plane: no trasformation is performed
        var
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3f(0, 0, -1))
            ray2 = newRay(newPoint3D(1, -2, -3), newVec3f(0, 4/5, 3/5))
            ray3 = newRay(newPoint3D(3, 0, 0), newVec3f(-1, 0, 0))

        check areClose(plane.rayIntersection(ray1).get.world_pt, newPoint3D(0, 0, 0))
        check areClose(plane.rayIntersection(ray1).get.normal, newNormal(0, 0, 1))
        check areClose(plane.rayIntersection(ray1).get.t_hit, 2)
        check areClose(plane.rayIntersection(ray1).get.surface_pt, newPoint2D(0, 0))

        check areClose(plane.rayIntersection(ray2).get.world_pt, newPoint3D(1, 2, 0))
        check areClose(plane.rayIntersection(ray2).get.normal, newNormal(0, 0, -1))
        check areClose(plane.rayIntersection(ray2).get.t_hit, 5)
        check areClose(plane.rayIntersection(ray2).get.surface_pt, newPoint2D(0, 0))

        check not plane.rayIntersection(ray3).isSome


    test "RayIntersection: with transformation":
        # Checking ray intersection procedure on plane: a translation along the z axis is performed
        var
            tr = newTranslation(newVec3(float32 0, 0, 3))
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3f(0, 0, -1))
            ray2 = newRay(newPoint3D(3, 0, 0), newVec3f(-1, 0, 0))
            ray3 = newRay(newPoint3D(1, -2, -3), newVec3f(0, 4/5, 3/5))
        
        plane.transf = tr

        check not plane.rayIntersection(ray1).isSome
        check not plane.rayIntersection(ray2).isSome

        check areClose(plane.rayIntersection(ray3).get().world_pt, newPoint3D(1, 6, 3))
        check areClose(plane.rayIntersection(ray3).get().normal, newNormal(0, 0, -1))
        check areClose(plane.rayIntersection(ray3).get().t_hit, 10)
        check areClose(plane.rayIntersection(ray3).get().surface_pt, newPoint2D(0, 0))
    

    test "FastIntersection":
        # Checking Fast intersection method
        var
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3f(0, 0, -1))
            ray2 = newRay(newPoint3D(1, 0, 1), newVec3f(0, 0, 1))
            ray3 = newRay(newPoint3D(3, 0, 0), newVec3f(-1, 0, 0))
        
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
        check fastIntersection(box, newRay(newPoint3D(0.5, 0.5, 0.5), newVec3f(0.0, 0.0, 0.0)))
        check not fastIntersection(box, newRay(newPoint3D(0.5, 0.5, 0.5), -newVec3f(0.0, 0.0, 0.0)))
        

suite "CSG":

    setup:
        let 
            s1 = newSphere(newPoint3D(0.5, 0, 0), 0.5)
            s2 = newSphere(newPoint3D(0, 0, 0), 0.2)
            csg_un = newCSGUnion(@[s1, s2])
            csg_diff = newCSGDiff(@[s1, s2])
            csg_int = newCSGInt(@[s1, s2])
        
    teardown:
        discard s1
        discard s2
        discard csg_un
        discard csg_diff
        discard csg_int

    test "constructor proc":

        check csg_un.kind == skCSGUnion
        check csg_diff.kind == skCSGDiff
        check csg_int.kind == skCSGInt

        check areClose(csg_un.shapes[0].center, newPoint3D(0.5, 0, 0))
        check areClose(csg_diff.shapes[0].center, newPoint3D(0.5, 0, 0))
        check areClose(csg_int.shapes[0].center, newPoint3D(0.5, 0, 0))

        check areClose(csg_un.shapes[0].radius, 0.5)
        check areClose(csg_diff.shapes[0].radius, 0.5)
        check areClose(csg_int.shapes[0].radius, 0.5)

        check areClose(csg_un.shapes[1].center, newPoint3D(0, 0, 0))
        check areClose(csg_diff.shapes[1].center, newPoint3D(0, 0, 0))
        check areClose(csg_int.shapes[1].center, newPoint3D(0, 0, 0))

        check areClose(csg_un.shapes[1].radius, 0.2)
        check areClose(csg_diff.shapes[1].radius, 0.2)
        check areClose(csg_int.shapes[1].radius, 0.2)

suite "World":
    
    setup:
        var 
            scenary = newWorld()

    teardown: 
        discard scenary
            
    
    test "add/get proc":
        scenary.shapes.add newUnitarySphere(newPoint3D(0, 0, 0))
        check areClose(scenary.shapes[0].transf.mat, Mat4f.id)
        check areClose(scenary.shapes[0].transf.inv_mat, Mat4f.id)