import std/[unittest, math, options]
import ../src/[shapes, geometry, camera, hdrimage]



#-----------------------------------#
#        Material test suite        #
#-----------------------------------#
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



#-----------------------------------#
#          AABB test suite          #
#-----------------------------------#
suite "AABox & AABB":

    setup:
        let
            box1 = newAABox()
            box2 = newAABox(newPoint3D(-1, -2, -3), newPoint3D(3, 4, 1), newMaterial(newSpecularBRDF(), newUniformPigment(WHITE)))
            box3 = newAABox(box2.aabb, newMaterial(newDiffuseBRDF(), newUniformPigment(newColor(0.3, 0.7, 1))))

            p1 = ORIGIN3D
            p2 = newPoint3D(1, 2, 3)
            p3 = newPoint3D(-2, 4, -8)
            p4 = newPoint3D(-1, 2, 2)
    
    teardown:
        discard box1
        discard box2
        discard box3
        discard p1
        discard p2
        discard p3
        discard p4

    
    test "newAABox proc":
        # Checking newAABox procs

        # box1 --> default constructor
        check areClose(box1.aabb.min, ORIGIN3D)
        check areClose(box1.aabb.max, newPoint3D(1, 1, 1))
        check box1.material.brdf.kind == DiffuseBRDF
        check box1.material.radiance.kind == pkUniform
        check areClose(box1.material.radiance.getColor(newPoint2D(0.5, 0.5)), WHITE)

        # box2 --> giving min and max as input
        check areClose(box2.aabb.min, newPoint3D(-1, -2, -3))
        check areClose(box2.aabb.max, newPoint3D(3, 4, 1))
        check box2.material.brdf.kind == SpecularBRDF
        check box2.material.radiance.kind == pkUniform
        check areClose(box2.material.radiance.getColor(newPoint2D(0.5, 0.5)), WHITE)


        # box3 --> giving aabb as input
        check areClose(box3.aabb.min, newPoint3D(-1, -2, -3))
        check areClose(box3.aabb.max, newPoint3D(3, 4, 1))
        check box3.material.brdf.kind == DiffuseBRDF
        check box3.material.radiance.kind == pkUniform 
        check areClose(box3.material.radiance.getColor(newPoint2D(0.5, 0.5)), newColor(0.3, 0.7, 1))


    test "getAABB (from points) proc":
        # Checking getAABB (from points) proc
        let appo = getAABB(@[p1, p2, p3, p4])

        check areClose(appo.min, newPoint3D(-2, 0, -8))
        check areClose(appo.max, newPoint3D(1, 4, 3))
    

    test "getTotalAABB proc":
        # Checking getTotalAABB proc
        let
            aabb1 = getAABB(@[p1, p2])
            aabb2 = getAABB(@[p3, p4])
            aabbTot = getTotalAABB(@[aabb1, aabb2])
        
        check areClose(aabb1.min, ORIGIN3D)
        check areClose(aabb1.max, p2)

        check areClose(aabb2.min, newPoint3D(-2, 2, -8))
        check areClose(aabb2.max, newPoint3D(-1, 4, 2))

        check areClose(aabbTot.min, newPoint3D(-2, 0, -8))
        check areClose(aabbTot.max, newPoint3D(1, 4, 3))


    test "getVertices proc":
        # Checking getVertices proc
        let 
            aabb = getAABB(@[p3, p4])
            appo = aabb.getVertices()

        check areClose(appo[0], aabb.min)
        check areClose(appo[1], aabb.max)
        check areClose(appo[2], newPoint3D(-2, 2, 2))
        check areClose(appo[3], newPoint3D(-2, 4, -8))
        check areClose(appo[4], newPoint3D(-2, 4, 2))
        check areClose(appo[5], newPoint3D(-1, 2, -8))
        check areClose(appo[6], newPoint3D(-1, 2, 2))
        check areClose(appo[7], newPoint3D(-1, 4, -8))



#------------------------------#
#       Sphere test suite      #
#------------------------------#
suite "Sphere":

    setup:
        var 
            usphere = newUnitarySphere(newMaterial(newSpecularBRDF(), newCheckeredPigment(BLACK, WHITE, 2)))
            sphere = newSphere(3.0)

    teardown: 
        discard usphere
        discard sphere


    test "newUnitarySphere proc":
        # Checking newUnitarySphere proc
        check usphere.radius == 1.0

        check usphere.material.brdf.kind == SpecularBRDF
        check usphere.material.radiance.kind == pkCheckered 
        check usphere.material.radiance.grid.nsteps == 2.int
        check areClose(usphere.material.radiance.grid.color1, BLACK)
        check areClose(usphere.material.radiance.grid.color2, WHITE)


    test "newSphere proc":
        # Checking newSphere proc
        check sphere.radius == 3.0

        check sphere.material.brdf.kind == DiffuseBRDF
        check sphere.material.radiance.kind == pkUniform
        check areClose(sphere.material.radiance.color, WHITE)

    
    test "getNormal proc":
        # Checking sphere normal computation method
        var
            pt1 = newPoint3D(1, 0 ,0)
            pt2 = newPoint3D(cos(PI/3), sin(PI/3) ,0)
            d = newVec3f(-1, 2, 0)
        
        # Unitary sphere
        check areClose(usphere.getNormal(pt1, d), newNormal(1, 0, 0))
        check areClose(usphere.getNormal(pt2, d), newNormal(-cos(PI/3), -sin(PI/3), 0))

        # Sphere with arbitrary radius
        check areClose(sphere.getNormal((3.float32*pt1.Vec3f).Point3D, d), newNormal(1, 0, 0))
        check areClose(sphere.getNormal((3.float32*pt2.Vec3f).Point3D, d), newNormal(-cos(PI/3), -sin(PI/3), 0))

    
    test "getUV proc":
        # Checking (u, v) coordinates computation
        var
            pt1 = newPoint3D(1, 0, 0)
            pt2 = newPoint3D(cos(PI/3), sin(PI/3), 0)

        # Unitary sphere
        check areClose(usphere.getUV(pt1), newPoint2D(0, 0.5))
        check areClose(usphere.getUV(pt2), newPoint2D(1/6, 0.5))

        # Sphere with arbitrary radius
        check areClose(sphere.getUV((3.float32*pt1.Vec3f).Point3D), newPoint2D(0, 0.5))
        check areClose(sphere.getUV((3.float32*pt2.Vec3f).Point3D), newPoint2D(1/6, 0.5))


    

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