import std/[unittest, math, options]
import ../src/[shapes, geometry, camera, hdrimage]



suite "Material":

    setup:
        let
            mat1 = newMaterial(newSpecularBRDF(), newCheckeredPigment(WHITE, BLACK, 2))
            mat2 = newMaterial(newDiffuseBRDF(), newUniformPigment(newColor(0.3, 0.7, 1)))

    teardown:
        discard mat1
        discard mat2 

    test "newMaterial proc":
        # Checking newMaterial proc
        check mat1.brdf.kind == SpecularBRDF
        check mat1.radiance.kind == pkCheckered
        check areClose(mat1.radiance.getColor(newPoint2D(0.3, 0.2)), WHITE)
        check areClose(mat1.radiance.getColor(newPoint2D(0.8, 0.7)), WHITE)
        check areClose(mat1.radiance.getColor(newPoint2D(0.8, 0.2)), BLACK)
        check areClose(mat1.radiance.getColor(newPoint2D(0.3, 0.7)), BLACK)
        check areClose(mat1.brdf.eval(eZ.Normal, newVec3f(0, 1, -1).normalize, newVec3f(0, 1, 1).normalize, newPoint2D(0.5, 0.5)), 
                    BLACK)


        check mat2.brdf.kind == DiffuseBRDF
        check mat2.radiance.kind == pkUniform
        check areClose(mat2.radiance.getColor(newPoint2D(0.5, 0.5)), newColor(0.3, 0.7, 1))
        check areClose(mat2.brdf.eval(eZ.Normal, newVec3f(0, 1, -1).normalize, newVec3f(0, 1, 1).normalize, newPoint2D(0.5, 0.5)), 
                    newColor(1, 1, 1)/PI)



#suite "Sphere":
#
#    setup:
#        var sphere = newUnitarySphere(ORIGIN3D)
#        var sphere1 = newSphere(newPoint3D(0, 1, 0), 3.0)
#
#    teardown: 
#        discard sphere; discard sphere1
#
#    test "newUnitarySphere proc":
#        check sphere.transform.kind == tkIdentity
#        check sphere.radius == 1.0
#
#    test "newSphere proc":
#        check sphere1.radius == 3.0
#        check areClose(apply(sphere1.transform, ORIGIN3D), newPoint3D(0, 1, 0))
#
#        check areClose(sphere1.transform.mat, newTranslation(newVec3f(0, 1, 0)).mat)
#
#
#    test "Surface Normal":
#        # Checking sphere normal computation method
#        var
#            p1 = newPoint3D(1, 0 ,0)
#            p2 = newPoint3D(cos(PI/3), sin(PI/3) ,0)
#            d = newVec3f(-1, 2, 0)
#        
#        check areClose(sphere.normal(p1, d), newNormal(1, 0, 0))
#        check areClose(sphere.normal(p2, d), newNormal(-cos(PI/3), -sin(PI/3), 0))
#
#    
#    test "(u, v) coordinates":
#        # Checking (u, v) coordinates computation
#        var
#            p1 = newPoint3D(1, 0, 1)
#            p2 = newPoint3D(cos(PI/3), sin(PI/3), 0.5)
#
#        check areClose(sphere.uv(p1), newPoint2D(0, 0))
#        check areClose(sphere.uv(p2), newPoint2D(1/6, 1/3))
#    
#
#    test "RayIntersection: no transformation":
#        # Checking ray intersection procedure on unitary shperical surface: no traslation is performed on sphere
#        var
#            ray1 = newRay(newPoint3D(0, 0, 2), newVec3f(0, 0, -1))
#            ray2 = newRay(newPoint3D(3, 0, 0), newVec3f(-1, 0, 0))
#            ray3 = newRay(ORIGIN3D, newVec3f(1, 0, 0))
#
#        let 
#            hit1 = sphere.rayIntersection(ray1).get
#            hit2 = sphere.rayIntersection(ray2).get
#            hit3 = sphere.rayIntersection(ray3).get
#
#        check areClose(hit1.world_pt, newPoint3D(0, 0, 1))
#        check areClose(hit1.normal, newNormal(0, 0, 1))
#        check areClose(hit1.t, 1)
#        check areClose(hit1.surface_pt, newPoint2D(0, 0))
#
#        check areClose(hit2.world_pt, newPoint3D(1, 0, 0))
#        check areClose(hit2.normal, newNormal(1, 0, 0))
#        check areClose(hit2.t, 2)
#        check areClose(hit1.surface_pt, newPoint2D(0, 0))
#
#        check areClose(hit3.world_pt, newPoint3D(1, 0, 0))
#        check areClose(hit3.normal, newNormal(-1, 0, 0))
#        check areClose(hit3.t, 1)
#        check areClose(hit1.surface_pt, newPoint2D(0, 0))
#    
#
#    test "RayIntersection: with transformation":
#        # Checking ray intersection procedure: we are transforming the sphere
#        var
#            tr = newTranslation(newVec3f(10, 0, 0))
#
#            ray1 = newRay(newPoint3D(10, 0, 2), newVec3f(0, 0, -1))
#            ray2 = newRay(newPoint3D(13, 0, 0), newVec3f(-1, 0, 0))
#            ray3 = newRay(newPoint3D(0, 0, 2), newVec3f(0, 0, -1))
#            ray4 = newRay(newPoint3D(-10, 0, 0), newVec3f(0, 0, -1))
#        
#        sphere.transform = tr
#        let 
#            intersect1 = sphere.rayIntersection(ray1).get
#            intersect2 = sphere.rayIntersection(ray2).get
#
#        check areClose(intersect1.world_pt, newPoint3D(10, 0, 1))
#        check areClose(intersect1.normal, newNormal(0, 0, 1))
#        check areClose(intersect1.t, 1)
#        check areClose(intersect1.surface_pt, newPoint2D(0, 0))
#
#        check areClose(intersect2.world_pt, newPoint3D(11, 0, 0))
#        check areClose(intersect2.normal, newNormal(1, 0, 0))
#        check areClose(intersect2.t, 2)
#        check areClose(intersect2.surface_pt, newPoint2D(0, 0.5))
#
#        sphere.transform = Transformation.id
#        check sphere.rayIntersection(ray3).isSome
#        check not sphere.rayIntersection(ray4).isSome
#    
#
#    test "FastIntersection proc":
#        # Checking Fast intersection method
#        var
#            ray1 = newRay(newPoint3D(0, 0, 2), newVec3f(0, 0, -1))
#            ray2 = newRay(newPoint3D(-10, 0, 0), newVec3f(0, 0, -1))
#        
#        check sphere.fastIntersection(ray1)
#        check not sphere.fastIntersection(ray2)
#    
#    test "allHitTimes proc":
#        # Checking all hit times procedure
#
#        var
#            ray1 = newRay(newPoint3D(2, 0, 0), newVec3f(-1, 0 ,0))
#            ray2 = newRay(newPoint3D(0, -3, 0), newVec3f(0, 1, 0))
#            ray3 = newRay(newPoint3D(0, -3, 0), newVec3f(1, 0, 0))
#            appo: Option[seq[float32]]
#        
#
#        #----------------------------#
#        #       Unitary sphere       #
#        #----------------------------#  
#        appo = allHitTimes(sphere, ray1)
#        check appo.isSome
#        check areClose(appo.get[0], 1.0)
#        check areClose(appo.get[1], 3.0)
#
#        appo = allHitTimes(sphere, ray2)
#        check appo.isSome
#        check areClose(appo.get[0], 2.0)
#        check areClose(appo.get[1], 4.0)
#
#        appo = allHitTimes(sphere, ray3)
#        check not appo.isSome
#
#
#        #----------------------------#
#        #      Ordinary sphere       #
#        #----------------------------#
#        ray1.origin = newPoint3D(4, 1, 0)
#        appo = allHitTimes(sphere1, ray1)
#        check appo.isSome
#        echo appo.get[0]
#        check areClose(appo.get[0], 1.0, eps = 1e-6)
#        check areClose(appo.get[1], 7.0, eps = 1e-6)
#
#        appo = allHitTimes(sphere1, ray2)
#        check appo.isSome
#        check areClose(appo.get[0], 1.0, eps = 1e-6)
#        check areClose(appo.get[1], 7.0, eps = 1e-6)
#
#        appo = allHitTimes(sphere1, ray3)
#        check not appo.isSome
#
#
#
#suite "Plane":
#
#    setup:
#        var plane = newPlane(Transformation.id)
#
#    test "PlaneConstructor":
#        check plane.transform.kind == tkIdentity
#
#    
#    test "RayIntersection: no transformation":
#        # Checking ray intersection procedure on plane: no trasformation is performed
#        var
#            ray1 = newRay(newPoint3D(0, 0, 2), newVec3f(0, 0, -1))
#            ray2 = newRay(newPoint3D(1, -2, -3), newVec3f(0, 4/5, 3/5))
#            ray3 = newRay(newPoint3D(3, 0, 0), newVec3f(-1, 0, 0))
#
#        check areClose(plane.rayIntersection(ray1).get.world_pt, ORIGIN3D)
#        check areClose(plane.rayIntersection(ray1).get.normal, newNormal(0, 0, 1))
#        check areClose(plane.rayIntersection(ray1).get.t, 2)
#        check areClose(plane.rayIntersection(ray1).get.surface_pt, newPoint2D(0, 0))
#
#        check areClose(plane.rayIntersection(ray2).get.world_pt, newPoint3D(1, 2, 0))
#        check areClose(plane.rayIntersection(ray2).get.normal, newNormal(0, 0, -1))
#        check areClose(plane.rayIntersection(ray2).get.t, 5)
#        check areClose(plane.rayIntersection(ray2).get.surface_pt, newPoint2D(0, 0))
#
#        check not plane.rayIntersection(ray3).isSome
#
#
#    test "RayIntersection: with transformation":
#        # Checking ray intersection procedure on plane: a translation along the z axis is performed
#        var
#            tr = newTranslation(newVec3f(0, 0, 3))
#            ray1 = newRay(newPoint3D(0, 0, 2), newVec3f(0, 0, -1))
#            ray2 = newRay(newPoint3D(3, 0, 0), newVec3f(-1, 0, 0))
#            ray3 = newRay(newPoint3D(1, -2, -3), newVec3f(0, 4/5, 3/5))
#        
#        plane.transform = tr
#
#        check not plane.rayIntersection(ray1).isSome
#        check not plane.rayIntersection(ray2).isSome
#
#        check areClose(plane.rayIntersection(ray3).get().world_pt, newPoint3D(1, 6, 3))
#        check areClose(plane.rayIntersection(ray3).get().normal, newNormal(0, 0, -1))
#        check areClose(plane.rayIntersection(ray3).get().t, 10)
#        check areClose(plane.rayIntersection(ray3).get().surface_pt, newPoint2D(0, 0))
#    
#
#    test "FastIntersection":
#        # Checking Fast intersection method
#        var
#            ray1 = newRay(newPoint3D(0, 0, 2), newVec3f(0, 0, -1))
#            ray2 = newRay(newPoint3D(1, 0, 1), newVec3f(0, 0, 1))
#            ray3 = newRay(newPoint3D(3, 0, 0), newVec3f(-1, 0, 0))
#        
#        check plane.fastIntersection(ray1)
#        check not plane.fastIntersection(ray2)
#        check not plane.fastIntersection(ray3)
#
#
#suite "AABox":
#
#    setup: 
#        let box = newAABox()
#
#    teardown:
#        discard box
#
#    test "fastIntersection": 
#        check fastIntersection(box, newRay(newPoint3D(0.0, 0.0, 0.0), eX))
#        check not fastIntersection(box, newRay(newPoint3D(0.0, 0.0, 2.0), eX))
#
#        check fastIntersection(box, newRay(newPoint3D(0.0, 2.0, 0.0), -eY))
#        check not fastIntersection(box, newRay(newPoint3D(0.0, -2.0, 0.0), -eY))
#
#        check fastIntersection(box, newRay(newPoint3D(0.0, 0.0, -1.5), eZ))
#        check not fastIntersection(box, newRay(newPoint3D(0.0, 0.0, 1.5), eZ))
#
##-----------------------------------------#
##            World type test              #
##-----------------------------------------#
#
#suite "World":
#    
#    setup:
#        var 
#            s1 = newSphere(newPoint3D(1, 1, 0), 1)
#            s2 = newSphere(newPoint3D(1, 0, 1), 0.5)
#            scenery = newWorld(@[s1, s2])
#
#    teardown: 
#        discard scenary
#            
#    
#    test "add/get proc":
#        # Testing add/get procedure
#
#        scenery.shapes.add newUnitarySphere(newPoint3D(0, 0, 0))
#        check areClose(scenery.shapes[2].transf.mat, Mat4f.id)
#        check areClose(scenery.shapes[2].transf.inv_mat, Mat4f.id)
#
#
#    test "fastIntersection proc":
#        # Testing fastIntersection procedure on world scenery
#
#        var
#            ray1 = newRay(newPoint3D(1, -2, 0), newVec3f(0, 1, 0))
#            ray2 = newRay(newPoint3D(1, 3, 0), newVec3f(0, 1, 0))
#        
#        check fastIntersection(scenery, ray1)
#        check not fastIntersection(scenery, ray2)
#    
#
#    test "rayIntersection proc":
#
#        var
#            ray1 = newRay(newPoint3D(1, -2, 0), newVec3f(0, 1, 0))
#            ray2 = newRay(newPoint3D(1, 3, 0), newVec3f(0, 1, 0))
#            hit: Option[HitRecord]
#        
#        scenery.shapes = @[s1, s2]
#        
#        # Intersection with first ray, we expect to have hit
#        # in (1, 0, 0) at time t = 2
#        hit = rayIntersection(scenery, ray1)
#        check hit.isSome
#        check areClose(hit.get.world_pt, newPoint3D(1, 0, 0))
#        check areClose(hit.get.t, 2)
#        check areClose(hit.get.normal.toVec3, newVec3f(0, -1, 0))
#        check areClose(hit.get.surface_pt, newPoint2D(0.75, 0.5))
#
#        # Intersection with second ray, we expect not to have a hit
#        hit = rayIntersection(scenery, ray2)
#        check hit.isNone
#