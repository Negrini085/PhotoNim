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

    
    test "getAABB proc":
        # Checking getAABB proc, gives AABB in shape local reference system
        let
            aabb1 = getAABB(usphere)
            aabb2 = getAABB(sphere)
        
        # Unitary sphere
        check areClose(aabb1.min, newPoint3D(-1, -1, -1))
        check areClose(aabb1.max, newPoint3D( 1,  1,  1))

        # Sphere with arbitrary radius
        check areClose(aabb2.min, newPoint3D(-3, -3, -3))
        check areClose(aabb2.max, newPoint3D( 3,  3,  3))
    

    test "getVertices proc":
        # Checking getVertices proc, gives AABB box vertices in shape local reference system
        let 
            vert1 = getVertices(usphere)
            vert2 = getVertices(sphere)
        
        # Unitary sphere        
        check areClose(vert1[0], newPoint3D(-1, -1, -1))
        check areClose(vert1[1], newPoint3D( 1,  1,  1))
        check areClose(vert1[2], newPoint3D(-1, -1,  1))
        check areClose(vert1[3], newPoint3D(-1,  1, -1))
        check areClose(vert1[4], newPoint3D(-1,  1,  1))
        check areClose(vert1[5], newPoint3D( 1, -1, -1))
        check areClose(vert1[6], newPoint3D( 1, -1,  1))
        check areClose(vert1[7], newPoint3D( 1,  1, -1))

        # Sphere with arbitrary radius       
        check areClose(vert2[0], newPoint3D(-3, -3, -3))
        check areClose(vert2[1], newPoint3D( 3,  3,  3))
        check areClose(vert2[2], newPoint3D(-3, -3,  3))
        check areClose(vert2[3], newPoint3D(-3,  3, -3))
        check areClose(vert2[4], newPoint3D(-3,  3,  3))
        check areClose(vert2[5], newPoint3D( 3, -3, -3))
        check areClose(vert2[6], newPoint3D( 3, -3,  3))
        check areClose(vert2[7], newPoint3D( 3,  3, -3))



#-------------------------------#
#      Triangle test suite      #
#-------------------------------#
suite "Triangle":
    
    setup:
        let tri =  newTriangle(
            eX.Point3D, eY.Point3D, eZ.Point3D,
            newMaterial(newSpecularBRDF(), newCheckeredPigment(WHITE, BLACK, 3))
            )
    
    teardown:
        discard tri
    
    
    test "newTriangle proc":
        # Checking newTriangle proc
        
        check areClose(tri.vertices[0], eX.Point3D)
        check areClose(tri.vertices[1], eY.Point3D)
        check areClose(tri.vertices[2], eZ.Point3D)

        check tri.material.brdf.kind == SpecularBRDF
        check tri.material.radiance.kind == pkCheckered
        check tri.material.radiance.grid.nsteps == 3
        check areClose(tri.material.radiance.grid.color1, WHITE)
        check areClose(tri.material.radiance.grid.color2, BLACK)
    

    test "getNormal proc":
        # Checking getNormal proc
        let pt = newPoint3D(0.2, 0.2, 0.6)

        check areClose(tri.getNormal(pt, newVec3f(-1, 0, 0)).Vec3f, newVec3f(1, 1, 1).normalize)
    

    test "getUV proc":
        # Checking getUV proc
        let pt = newPoint3D(0.2, 0.2, 0.6)

        check areClose(tri.getUV(pt).Vec2f, newVec2f(0.2, 0.6))
    

    test "getAABB proc":
        # Cheking getAABB proc, gives aabb in local shape reference system
        let aabb = getAABB(tri)

        check areClose(aabb.min, newPoint3D(0, 0, 0))
        check areClose(aabb.max, newPoint3D(1, 1, 1))
    

    test "getVertices proc":
        # Checking getVertices proc, gives aabb vertices in local shape reference system
        let
            aabb = getAABB(tri)
            vert1 = getVertices(tri)
            vert2 = getVertices(aabb)
        
        # Triangle vertices
        check areClose(vert1[0], tri.vertices[0])
        check areClose(vert1[1], tri.vertices[1])
        check areClose(vert1[2], tri.vertices[2])

        # Triangle AABB vertices
        check areClose(vert2[0], aabb.min)
        check areClose(vert2[1], aabb.max)
        check areClose(vert2[2], newPoint3D(0, 0, 1))
        check areClose(vert2[3], newPoint3D(0, 1, 0))
        check areClose(vert2[4], newPoint3D(0, 1, 1))
        check areClose(vert2[5], newPoint3D(1, 0, 0))
        check areClose(vert2[6], newPoint3D(1, 0, 1))
        check areClose(vert2[7], newPoint3D(1, 1, 0))



#----------------------------#
#    Cylinder test suite     #
#----------------------------# 
suite "Cylinder":

    setup:
        let 
            cyl1 = newCylinder()
            cyl2 = newCylinder(R = 2.0, material = newMaterial(newSpecularBRDF(), newCheckeredPigment(WHITE, BLACK, 2)))
    
    teardown:
        discard cyl1
        discard cyl2
    
    
    test "newCylinder proc":
        # Checking newTriangle proc
        
        # First cylinder: default constructor
        check cyl1.R == 1.0
        check areClose(cyl1.phiMax, 2*PI)
        check cyl1.zSpan.min == 0.0 and cyl1.zSpan.max == 1.0

        check cyl1.material.brdf.kind == DiffuseBRDF
        check cyl1.material.radiance.kind == pkUniform
        check areClose(cyl1.material.radiance.color, WHITE)
    

        # Second cylinder: specific build
        check cyl2.R == 2.0
        check areClose(cyl2.phiMax, 2*PI)
        check cyl2.zSpan.min == 0.0 and cyl1.zSpan.max == 1.0

        check cyl2.material.brdf.kind == SpecularBRDF
        check cyl2.material.radiance.kind == pkCheckered
        check cyl2.material.radiance.grid.nsteps == 2
        check areClose(cyl2.material.radiance.grid.color1, WHITE)
        check areClose(cyl2.material.radiance.grid.color2, BLACK)


    test "getNormal proc":
        # Checking getNormal proc
        var
            pt1 = newPoint3D(1, 0, 0.5)
            pt2 = newPoint3D(2, 0, 0.5)
        
        check areClose(cyl1.getNormal(pt1, newVec3f(0, 0, -1)).Vec3f, newVec3f(1, 0, 0))
        check areClose(cyl2.getNormal(pt2, newVec3f(0, 0, -1)).Vec3f, newVec3f(1, 0, 0))
    

    test "getUV proc":
        # Checking getUV proc
        var
            pt1 = newPoint3D(cos(PI/3), sin(PI/3), 0.5)
            pt2 = newPoint3D(1, 0, 0.3)
        
        # First cylinder: default constructor
        check areClose(cyl1.getUV(pt1).Vec2f, newVec2f(1/6, 0.5))
        check areClose(cyl1.getUV(pt2).Vec2f, newVec2f(0.0, 0.3))

        # Second cylinder: specific build
        check areClose(cyl1.getUV((2.float32*pt1.Vec3f).Point3D).Vec2f, newVec2f(1/6, 1))
        check areClose(cyl1.getUV((2.float32*pt2.VEc3f).Point3D).Vec2f, newVec2f(0.0, 0.6))


    test "getAABB proc":
        # Cheking getAABB proc, gives aabb in local shape reference system
        let
            aabb1 = getAABB(cyl1)
            aabb2 = getAABB(cyl2)
        
        # First cylinder: default constructor
        check areClose(aabb1.min, newPoint3D(-1, -1, 0))
        check areClose(aabb1.max, newPoint3D(1, 1, 1))

        # Second cylinder: specific build
        check areClose(aabb2.min, newPoint3D(-2, -2, 0))
        check areClose(aabb2.max, newPoint3D(2, 2, 1))
    

    test "getVertices proc":
        # Checking getVertices proc, gives aabb vertices in local shape reference system
        let
            aabb1 = getAABB(cyl1)
            aabb2 = getAABB(cyl2)
            vert1 = getVertices(cyl1)
            vert2 = getVertices(cyl2)
        
        # First cylinder: default constructor
        check areClose(vert1[0], aabb1.min)
        check areClose(vert1[1], aabb1.max)
        check areClose(vert1[2], newPoint3D(-1, -1, 1))
        check areClose(vert1[3], newPoint3D(-1,  1, 0))
        check areClose(vert1[4], newPoint3D(-1,  1, 1))
        check areClose(vert1[5], newPoint3D( 1, -1, 0))
        check areClose(vert1[6], newPoint3D( 1, -1, 1))
        check areClose(vert1[7], newPoint3D( 1,  1, 0))

        # Second cylinder: specific build
        check areClose(vert2[0], aabb2.min)
        check areClose(vert2[1], aabb2.max)
        check areClose(vert2[2], newPoint3D(-2, -2, 1))
        check areClose(vert2[3], newPoint3D(-2,  2, 0))
        check areClose(vert2[4], newPoint3D(-2,  2, 1))
        check areClose(vert2[5], newPoint3D( 2, -2, 0))
        check areClose(vert2[6], newPoint3D( 2, -2, 1))
        check areClose(vert2[7], newPoint3D( 2,  2, 0))
