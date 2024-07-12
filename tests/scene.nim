import std/unittest
import PhotoNim
from math import sin, cos, PI, sqrt, pow


#-----------------------------------#
#          AABB test suite          #
#-----------------------------------#
suite "AABox & AABB":

    setup:
        let
            p1 = ORIGIN3D
            p2 = newPoint3D(1, 2, 3)
            p3 = newPoint3D(-2, 4, -8)
            p4 = newPoint3D(-1, 2, 2)
            tr = newTranslation(eX)
            
            box1 = newBox((p1, p2), newMaterial(newDiffuseBRDF(), newUniformPigment(newColor(0.3, 0.7, 1))))
            box2 = newBox((p1, p2), newMaterial(newSpecularBRDF(), newUniformPigment(newColor(1, 223/255, 0))), tr)

    teardown:
        discard box1
        discard box2
        
        discard tr
        discard p1
        discard p2
        discard p3
        discard p4
    

    test "newBox proc":
        # Checking newBox procs

        # box1 --> No transformation given
        check areClose(box1.shape.aabb.min, ORIGIN3D)
        check areClose(box1.shape.aabb.max, newPoint3D(1, 2, 3))
        check box1.shape.material.brdf.kind == DiffuseBRDF
        check box1.shape.material.radiance.kind == pkUniform

        check box1.transformation.kind == tkIdentity


        # box2 --> giving min and max as input
        check areClose(box2.shape.aabb.min, ORIGIN3D)
        check areClose(box2.shape.aabb.max, newPoint3D(1, 2, 3))
        check box2.shape.material.brdf.kind == SpecularBRDF
        check box2.shape.material.radiance.kind == pkUniform

        check areClose(box2.transformation.mat, newTranslation(eX).mat)


    

    test "getNormal proc":
        # Checking getNormal proc
        var 
            pt1 = newPoint3D(0, 0.5, 0.5)
            pt2 = newPoint3D(1, 0.5, 0.5)
            pt3 = newPoint3D(0.5, 0, 0.5)
            pt4 = newPoint3D(0.5, 2, 0.5)
            pt5 = newPoint3D(0.5, 0.5, 0)
            pt6 = newPoint3D(0.5, 0.5, 3)
        
        # box1 --> default constructor
        check areClose(box1.shape.getNormal(pt1, newVec3f( 1, 0, 0)).Vec3f, newVec3f(-1, 0, 0))
        check areClose(box1.shape.getNormal(pt2, newVec3f(-1, 0, 0)).Vec3f, newVec3f( 1, 0, 0))
        check areClose(box1.shape.getNormal(pt3, newVec3f(0,  1, 0)).Vec3f, newVec3f(0, -1, 0))
        check areClose(box1.shape.getNormal(pt4, newVec3f(0, -1, 0)).Vec3f, newVec3f(0,  1, 0))
        check areClose(box1.shape.getNormal(pt5, newVec3f(0, 0,  1)).Vec3f, newVec3f(0, 0, -1))
        check areClose(box1.shape.getNormal(pt6, newVec3f(0, 0, -1)).Vec3f, newVec3f(0, 0,  1))

        
        # box2 --> giving min and max as input
        pt1 = newPoint3D(1, 0.5, 0.5); pt2 = newPoint3D(2, 0.5, 0.5); pt3 = newPoint3D(1.5, 0, 0.5)
        pt4 = newPoint3D(1.5, 2, 0.5); pt5 = newPoint3D(1.5, 0.5, 0); pt6 = newPoint3D(1.5, 0.5, 3)

        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt1), newVec3f( 1, 0, 0)).Vec3f, newVec3f(-1, 0, 0))
        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt2), newVec3f(-1, 0, 0)).Vec3f, newVec3f( 1, 0, 0))
        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt3), newVec3f(0,  1, 0)).Vec3f, newVec3f(0, -1, 0))
        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt4), newVec3f(0, -1, 0)).Vec3f, newVec3f(0,  1, 0))
        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt5), newVec3f(0, 0,  1)).Vec3f, newVec3f(0, 0, -1))
        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt6), newVec3f(0, 0, -1)).Vec3f, newVec3f(0, 0,  1))


    test "getUV proc":
        # Checking getUV proc test
        var 
            pt1 = newPoint3D(0.0, 0.6, 2.1)
            pt2 = newPoint3D(1.0, 0.4, 2.7)
            pt3 = newPoint3D(0.5, 0.0, 0.9)
            pt4 = newPoint3D(0.6, 2.0, 1.5)
            pt5 = newPoint3D(0.5, 0.8, 0.0)
            pt6 = newPoint3D(0.2, 1.0, 3.0)

        # box1 --> transformation is identity
        check areClose(box1.shape.getUV(pt1), newPoint2D(0.3, 0.7))
        check areClose(box1.shape.getUV(pt2), newPoint2D(0.2, 0.9))
        check areClose(box1.shape.getUV(pt3), newPoint2D(0.5, 0.3))
        check areClose(box1.shape.getUV(pt4), newPoint2D(0.6, 0.5))
        check areClose(box1.shape.getUV(pt5), newPoint2D(0.5, 0.4))
        check areClose(box1.shape.getUV(pt6), newPoint2D(0.2, 0.5))

        
        # box2 --> transformation is translation along x-axis
        pt1 = newPoint3D(1.0, 1.0, 1.5); pt2 = newPoint3D(2.0, 1.0, 1.5); pt3 = newPoint3D(1.5, 0.0, 1.5)
        pt4 = newPoint3D(1.5, 2.0, 1.5); pt5 = newPoint3D(1.5, 1.0, 0.0); pt6 = newPoint3D(1.5, 1.0, 3.0)

        check areClose(box2.shape.getUV(apply(box2.transformation.inverse, pt1)), newPoint2D(0.5, 0.5))
        check areClose(box2.shape.getUV(apply(box2.transformation.inverse, pt2)), newPoint2D(0.5, 0.5))
        check areClose(box2.shape.getUV(apply(box2.transformation.inverse, pt3)), newPoint2D(0.5, 0.5))
        check areClose(box2.shape.getUV(apply(box2.transformation.inverse, pt4)), newPoint2D(0.5, 0.5))
        check areClose(box2.shape.getUV(apply(box2.transformation.inverse, pt5)), newPoint2D(0.5, 0.5))
        check areClose(box2.shape.getUV(apply(box2.transformation.inverse, pt6)), newPoint2D(0.5, 0.5))
    
    
    test "getAABB (from AABox shape) proc":
        let 
            aabb1 = getAABB(box1)
            aabb2 = getAABB(box2)
        
        check areClose(aabb1.min, box1.shape.aabb.min)
        check areClose(aabb1.max, box1.shape.aabb.max)

        check areClose(aabb2.min, newPoint3D(1, 0, 0))
        check areClose(aabb2.max, newPoint3D(2, 2, 3))
    

    test "getVertices (from AABox shape) proc":
        var
            vert = getVertices(box1.shape.aabb)
            vertBox = getVertices(box1.shape)
        
        # box1 --> default constructor
        check vert.len == vertBox.len
        for i in 0..<vert.len:
            check areClose(vert[i], vertBox[i])
        

        # box2 --> giving min and max as input
        vert = getVertices(box2.shape.aabb)
        vertBox = getVertices(box2.shape)
        
        check vert.len == vertBox.len
        for i in 0..<vert.len:
            check areClose(vert[i], vertBox[i])


    test "newAABB (from points) proc":
        # Checking newAABB (from points) proc
        let appo = newAABB(@[p1, p2, p3, p4])

        check areClose(appo.min, newPoint3D(-2, 0, -8))
        check areClose(appo.max, newPoint3D(1, 4, 3))
    

    test "getTotalAABB (from aabb) proc":
        # Checking getTotalAABB proc
        let
            aabb1 = newAABB(@[p1, p2])
            aabb2 = newAABB(@[p3, p4])
            aabbTot = getTotalAABB(@[aabb1, aabb2])
        
        check areClose(aabb1.min, ORIGIN3D)
        check areClose(aabb1.max, p2)

        check areClose(aabb2.min, newPoint3D(-2, 2, -8))
        check areClose(aabb2.max, newPoint3D(-1, 4, 2))

        check areClose(aabbTot.min, newPoint3D(-2, 0, -8))
        check areClose(aabbTot.max, newPoint3D(1, 4, 3))


    test "getVertices (from aabb) proc":
        # Checking getVertices proc
        let 
            aabb = newAABB(@[p3, p4])
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
        let
            sphere = newSphere(ORIGIN3D, 3.0)
            usphere = newUnitarySphere(eX.Point3D, newMaterial(newSpecularBRDF(), newCheckeredPigment(BLACK, WHITE, 2, 2)))

    teardown: 
        discard usphere
        discard sphere


    test "newUnitarySphere proc":
        # Checking newUnitarySphere proc
        check usphere.shape.radius == 1.0
        check areClose(usphere.transformation.mat, newTranslation(eX).mat)

        check usphere.shape.material.brdf.kind == SpecularBRDF
        check usphere.shape.material.radiance.kind == pkCheckered 
        check usphere.shape.material.radiance.grid.nCols == 2.int
        check usphere.shape.material.radiance.grid.nRows == 2.int
        check areClose(usphere.shape.material.radiance.grid.c1, BLACK)
        check areClose(usphere.shape.material.radiance.grid.c2, WHITE)


    test "newSphere proc":
        # Checking newSphere proc
        check sphere.shape.radius == 3.0
        check sphere.transformation.kind == tkIdentity

        check sphere.shape.material.brdf.kind == DiffuseBRDF
        check sphere.shape.material.radiance.kind == pkUniform
        check areClose(sphere.shape.material.radiance.color, WHITE)

    
    test "getNormal proc":
        # Checking sphere normal computation method
        var
            pt1 = newPoint3D(1, 0 ,0)
            pt2 = newPoint3D(cos(PI/3), sin(PI/3) ,0)
            d = newVec3f(-1, 2, 0)
        
        # Unitary sphere
        check areClose(usphere.shape.getNormal(pt1, d), newNormal(1, 0, 0))
        check areClose(usphere.shape.getNormal(pt2, d), newNormal(-cos(PI/3), -sin(PI/3), 0))

        # Sphere with arbitrary radius
        check areClose(sphere.shape.getNormal((3.float32*pt1.Vec3f).Point3D, d), newNormal(1, 0, 0))
        check areClose(sphere.shape.getNormal((3.float32*pt2.Vec3f).Point3D, d), newNormal(-cos(PI/3), -sin(PI/3), 0))

    
    test "getUV proc":
        # Checking (u, v) coordinates computation
        var
            pt1 = newPoint3D(1, 0, 0)
            pt2 = newPoint3D(cos(PI/3), sin(PI/3), 0)

        # Unitary sphere
        check areClose(usphere.shape.getUV(pt1), newPoint2D(0, 0.5))
        check areClose(usphere.shape.getUV(pt2), newPoint2D(1/6, 0.5))

        # Sphere with arbitrary radius
        check areClose(sphere.shape.getUV((3.float32*pt1.Vec3f).Point3D), newPoint2D(0, 0.5))
        check areClose(sphere.shape.getUV((3.float32*pt2.Vec3f).Point3D), newPoint2D(1/6, 0.5))

    
    test "getAABB proc":
        # Checking getAABB proc, gives AABB in world
        let
            aabb1 = getAABB(usphere)
            aabb2 = getAABB(sphere)
        
        # Unitary sphere
        check areClose(aabb1.min, newPoint3D(0, -1, -1))
        check areClose(aabb1.max, newPoint3D(2,  1,  1))

        # Sphere with arbitrary radius
        check areClose(aabb2.min, newPoint3D(-3, -3, -3))
        check areClose(aabb2.max, newPoint3D( 3,  3,  3))
    

    test "getVertices proc":
        # Checking getVertices proc, gives AABB box vertices in shape local reference system
        let 
            vert1 = getVertices(usphere.shape)
            vert2 = getVertices(sphere.shape)
        
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
        let 
            tri1 =  newTriangle(
                eX.Point3D, eY.Point3D, eZ.Point3D,
                newMaterial(newSpecularBRDF(), newCheckeredPigment(WHITE, BLACK, 3, 3))
                )
        
            tri2 =  newTriangle(
                eX.Point3D, eY.Point3D, eZ.Point3D,
                newMaterial(newDiffuseBRDF(), newUniformPigment(WHITE)),
                newTranslation(newVec3f(1, 2, 3))
                )
    
    teardown:
        discard tri1
        discard tri2
    
    
    test "newTriangle proc":
        # Checking newTriangle proc
        
        # Triangle 1 --> Transformation is identity
        check areClose(tri1.shape.vertices[0], eX.Point3D)
        check areClose(tri1.shape.vertices[1], eY.Point3D)
        check areClose(tri1.shape.vertices[2], eZ.Point3D)

        check tri1.shape.material.brdf.kind == SpecularBRDF
        check tri1.shape.material.radiance.kind == pkCheckered
        check tri1.shape.material.radiance.grid.nCols == 3
        check tri1.shape.material.radiance.grid.nRows == 3
        check areClose(tri1.shape.material.radiance.grid.c1, WHITE)
        check areClose(tri1.shape.material.radiance.grid.c2, BLACK)


        # Triangle 2 --> Transformation is translation of (1, 2, 3)
        check areClose(tri2.shape.vertices[0], eX.Point3D)
        check areClose(tri2.shape.vertices[1], eY.Point3D)
        check areClose(tri2.shape.vertices[2], eZ.Point3D)

        check tri2.shape.material.brdf.kind == DiffuseBRDF
        check tri2.shape.material.radiance.kind == pkUniform
        check areClose(tri2.shape.material.radiance.color, WHITE)
    

    test "getNormal proc":
        # Checking getNormal proc
        let pt = newPoint3D(0.2, 0.2, 0.6)

        check areClose(tri1.shape.getNormal(pt, newVec3f(-1, 0, 0)).Vec3f, newVec3f(1, 1, 1).normalize)
        check areClose(tri2.shape.getNormal(pt, newVec3f(-1, 0, 0)).Vec3f, newVec3f(1, 1, 1).normalize)
    

    test "getUV proc":
        # Checking getUV proc
        let pt = newPoint3D(0.2, 0.2, 0.6)

        check areClose(tri1.shape.getUV(pt).Vec2f, newVec2f(0.2, 0.6))
        check areClose(tri2.shape.getUV(pt).Vec2f, newVec2f(0.2, 0.6))
    

    test "getAABB proc":
        # Cheking getAABB proc, gives aabb in world
        let 
            aabb1 = getAABB(tri1)
            aabb2 = getAABB(tri2)

        check areClose(aabb1.min, newPoint3D(0, 0, 0))
        check areClose(aabb1.max, newPoint3D(1, 1, 1))

        check areClose(aabb2.min, newPoint3D(1, 2, 3))
        check areClose(aabb2.max, newPoint3D(2, 3, 4))
    

    test "getVertices proc":
        # Checking getVertices proc, gives aabb vertices in local shape reference system
        var
            aabb = getAABB(tri1)
            vert1 = getVertices(tri1.shape)
            vert2 = getVertices(aabb)
        
        # First triangle -> identity
        # Triangle vertices
        check areClose(vert1[0], tri1.shape.vertices[0])
        check areClose(vert1[1], tri1.shape.vertices[1])
        check areClose(vert1[2], tri1.shape.vertices[2])

        # Triangle AABB vertices
        check areClose(vert2[0], aabb.min)
        check areClose(vert2[1], aabb.max)
        check areClose(vert2[2], newPoint3D(0, 0, 1))
        check areClose(vert2[3], newPoint3D(0, 1, 0))
        check areClose(vert2[4], newPoint3D(0, 1, 1))
        check areClose(vert2[5], newPoint3D(1, 0, 0))
        check areClose(vert2[6], newPoint3D(1, 0, 1))
        check areClose(vert2[7], newPoint3D(1, 1, 0))


        aabb = getAABB(tri2)
        vert1 = getVertices(tri2.shape)
        vert2 = getVertices(aabb)
    
        # Second triangle --> translation of (1, 2, 3)
        # Triangle vertices
        check areClose(vert1[0], tri2.shape.vertices[0])
        check areClose(vert1[1], tri2.shape.vertices[1])
        check areClose(vert1[2], tri2.shape.vertices[2])

        # Triangle AABB vertices
        check areClose(vert2[0], aabb.min)
        check areClose(vert2[1], aabb.max)
        check areClose(vert2[2], newPoint3D(1, 2, 4))
        check areClose(vert2[3], newPoint3D(1, 3, 3))
        check areClose(vert2[4], newPoint3D(1, 3, 4))
        check areClose(vert2[5], newPoint3D(2, 2, 3))
        check areClose(vert2[6], newPoint3D(2, 2, 4))
        check areClose(vert2[7], newPoint3D(2, 3, 3))



#----------------------------#
#    Cylinder test suite     #
#----------------------------# 
suite "Cylinder":

    setup:
        let 
            tr = newTranslation(eZ)

            cyl1 = newCylinder()
            cyl2 = newCylinder(R = 2.0, material = newMaterial(newSpecularBRDF(), newCheckeredPigment(WHITE, BLACK, 2, 2)), transformation = tr)
    
    teardown:
        discard tr
        discard cyl1
        discard cyl2
    
    
    test "newCylinder proc":
        # Checking newCylinder proc
        
        # First cylinder: default constructor
        check cyl1.shape.R == 1.0
        check areClose(cyl1.shape.phiMax, 2*PI)
        check cyl1.shape.zSpan.min == 0.0 and cyl1.shape.zSpan.max == 1.0

        check cyl1.shape.material.brdf.kind == DiffuseBRDF
        check cyl1.shape.material.radiance.kind == pkUniform
        check areClose(cyl1.shape.material.radiance.color, WHITE)

        check cyl1.transformation.kind == tkIdentity
    

        # Second cylinder: specific build
        check cyl2.shape.R == 2.0
        check areClose(cyl2.shape.phiMax, 2*PI)
        check cyl2.shape.zSpan.min == 0.0 and cyl2.shape.zSpan.max == 1.0

        check cyl2.shape.material.brdf.kind == SpecularBRDF
        check cyl2.shape.material.radiance.kind == pkCheckered
        check cyl2.shape.material.radiance.grid.nRows == 2
        check cyl2.shape.material.radiance.grid.nCols == 2
        check areClose(cyl2.shape.material.radiance.grid.c1, WHITE)
        check areClose(cyl2.shape.material.radiance.grid.c2, BLACK)

        check cyl2.transformation.kind == tkTranslation
        check areClose(cyl2.transformation.mat, newTranslation(eZ).mat)


    test "getNormal proc":
        # Checking getNormal proc
        var
            pt1 = newPoint3D(1, 0, 0.5)
            pt2 = newPoint3D(2, 0, 0.5)
        
        check areClose(cyl1.shape.getNormal(pt1, newVec3f(0, 0, -1)).Vec3f, newVec3f(1, 0, 0))
        check areClose(cyl2.shape.getNormal(pt2, newVec3f(0, 0, -1)).Vec3f, newVec3f(1, 0, 0))
    

    test "getUV proc":
        # Checking getUV proc
        var
            pt1 = newPoint3D(cos(PI/3), sin(PI/3), 0.5)
            pt2 = newPoint3D(1, 0, 0.3)
        
        # First cylinder: default constructor
        check areClose(cyl1.shape.getUV(pt1).Vec2f, newVec2f(1/6, 0.5))
        check areClose(cyl1.shape.getUV(pt2).Vec2f, newVec2f(0.0, 0.3))

        # Second cylinder: specific build
        check areClose(cyl2.shape.getUV(newPoint3D(2 * cos(PI/3), 2 * sin(PI/3), 0.5)).Vec2f, newVec2f(1/6, 0.5))
        check areClose(cyl2.shape.getUV(newPoint3D(2, 0, 0.3)).Vec2f, newVec2f(0.0, 0.3))


    test "getAABB proc":
        # Cheking getAABB proc, gives aabb in world
        let
            aabb1 = getAABB(cyl1)
            aabb2 = getAABB(cyl2)
        
        # First cylinder: default constructor
        check areClose(aabb1.min, newPoint3D(-1, -1, 0))
        check areClose(aabb1.max, newPoint3D(1, 1, 1))

        # Second cylinder: specific build
        check areClose(aabb2.min, newPoint3D(-2, -2, 1))
        check areClose(aabb2.max, newPoint3D(2, 2, 2))
    

    test "getVertices proc":
        # Checking getVertices proc, gives aabb vertices in local shape reference system
        let
            aabb1 = getAABB(cyl1)
            vert1 = getVertices(cyl1.shape)
            vert2 = getVertices(cyl2.shape)
        
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
        check areClose(vert2[0], newPoint3D(-2, -2, 0))
        check areClose(vert2[1], newPoint3D(2, 2, 1))
        check areClose(vert2[2], newPoint3D(-2, -2, 1))
        check areClose(vert2[3], newPoint3D(-2,  2, 0))
        check areClose(vert2[4], newPoint3D(-2,  2, 1))
        check areClose(vert2[5], newPoint3D( 2, -2, 0))
        check areClose(vert2[6], newPoint3D( 2, -2, 1))
        check areClose(vert2[7], newPoint3D( 2,  2, 0))



#----------------------------#
#    Ellipsoid test suite    #
#----------------------------# 
suite "Ellipsoid":

    setup:
        let 
            tr = newTranslation(eZ)
            comp = newComposition(newRotX(45), newTranslation(eY))

            ell1 = newEllipsoid(1, 2, 3, tr)
            ell2 = newEllipsoid(3.0, 2.0, 1.0, comp)
    
    teardown:
        discard tr
        discard comp
        discard ell1
        discard ell2
    
    
    test "newEllipsoid proc":
        # Checking newEllipsoid proc
        
        # First Ellipsoid
        check ell1.shape.kind == skEllipsoid
        check areClose(ell1.shape.axis.a, 1.0)
        check areClose(ell1.shape.axis.b, 2.0)
        check areClose(ell1.shape.axis.c, 3.0)

        check ell1.transformation.kind == tkTranslation
        check areClose(ell1.transformation.mat, newTranslation(eZ).mat)
    
        # Second Ellipsoid
        check ell2.shape.kind == skEllipsoid
        check areClose(ell2.shape.axis.a, 3.0)
        check areClose(ell2.shape.axis.b, 2.0)
        check areClose(ell2.shape.axis.c, 1.0)

        check ell2.transformation.kind == tkComposition
        check ell2.transformation.transformations.len == 2
        check areClose(ell2.transformation.transformations[1].mat, newTranslation(eY).mat)
        check areClose(ell2.transformation.transformations[0].mat, newRotX(45).mat, eps = 1e-6)


    test "getNormal proc":
        # Checking ellipsoid normal computation method
        var
            dir: Vec3f
            pt: Point3D
        
        # First ellipsoid
        dir = newVec3f(-1, 0, 0)
        pt = newPoint3D(ell1.shape.axis.a, 0, 0)
        check areClose(ell1.shape.getNormal(pt, dir), newNormal(1, 0, 0))

        dir = newVec3f(0, -1, 0)
        pt = newPoint3D(ell1.shape.axis.a * cos(PI/3), ell1.shape.axis.b * sin(PI/3), 0)
        check areClose(ell1.shape.getNormal(pt, dir), newNormal(1/2, sqrt(3.0)/4, 0), eps = 1e-6)
    
        # First ellipsoid
        dir = newVec3f(-1, 0, 0)
        pt = newPoint3D(ell2.shape.axis.a, 0, 0)
        check areClose(ell2.shape.getNormal(pt, dir), newNormal(1, 0, 0))

        dir = newVec3f(0, -1, 0)
        pt = newPoint3D(ell2.shape.axis.a * cos(PI/3), ell2.shape.axis.b * sin(PI/3), 0)
        check areClose(ell2.shape.getNormal(pt, dir), newNormal(1/6, sqrt(3.0)/4, 0), eps = 1e-6)


    test "getUV proc":
        # Checking (u, v) coordinates computation
        var pt1, pt2: Point3D

        # Unitary sphere
        pt1 = newPoint3D(ell1.shape.axis.a, 0, 0)
        pt2 = newPoint3D(ell1.shape.axis.a * cos(PI/3), ell1.shape.axis.b * sin(PI/3), 0)
        check areClose(ell1.shape.getUV(pt1), newPoint2D(0, 0.5))
        check areClose(ell1.shape.getUV(pt2), newPoint2D(1/6, 0.5))

        # Sphere with arbitrary radius
        pt1 = newPoint3D(ell2.shape.axis.a, 0, 0)
        pt2 = newPoint3D(ell2.shape.axis.a * cos(PI/3), ell2.shape.axis.b * sin(PI/3), 0)
        check areClose(ell2.shape.getUV(pt1), newPoint2D(0, 0.5))
        check areClose(ell2.shape.getUV(pt2), newPoint2D(1/6, 0.5))


    test "getAABB proc":
        # Cheking getAABB proc for ellipsoid shape, gives aabb in local reference system
        let
            aabb1 = getAABB(ell1.shape)
            aabb2 = getAABB(ell2.shape)
        
        # First ellipsoid
        check areClose(aabb1.min, newPoint3D(-1, -2, -3))
        check areClose(aabb1.max, newPoint3D( 1,  2,  3))

        # Second ellipsoid
        check areClose(aabb2.min, newPoint3D(-3, -2, -1))
        check areClose(aabb2.max, newPoint3D( 3,  2,  1))


    test "getVertices proc":
        # Checking getVertices proc, gives aabb vertices in local shape reference system
        let
            aabb1 = getAABB(ell1.shape)
            aabb2 = getAABB(ell2.shape)
        
            vert1 = getVertices(ell1.shape)
            vert2 = getVertices(ell2.shape)
        
        # First ellipsoid
        check areClose(vert1[0], aabb1.min)
        check areClose(vert1[1], aabb1.max)
        check areClose(vert1[2], newPoint3D(-1, -2,  3))
        check areClose(vert1[3], newPoint3D(-1,  2, -3))
        check areClose(vert1[4], newPoint3D(-1,  2,  3))
        check areClose(vert1[5], newPoint3D( 1, -2, -3))
        check areClose(vert1[6], newPoint3D( 1, -2,  3))
        check areClose(vert1[7], newPoint3D( 1,  2, -3))

        # Second ellipsoid
        check areClose(vert2[0], aabb2.min)
        check areClose(vert2[1], aabb2.max)
        check areClose(vert2[2], newPoint3D(-3, -2,  1))
        check areClose(vert2[3], newPoint3D(-3,  2, -1))
        check areClose(vert2[4], newPoint3D(-3,  2,  1))
        check areClose(vert2[5], newPoint3D( 3, -2, -1))
        check areClose(vert2[6], newPoint3D( 3, -2,  1))
        check areClose(vert2[7], newPoint3D( 3,  2, -1))


    test "getAABB proc":
        # Cheking getAABB proc, gives aabb in world
        let
            aabb1 = getAABB(ell1)
            aabb2 = getAABB(ell2)
        
        # First ellipsoid
        check areClose(aabb1.min, newPoint3D(-1, -2, -2))
        check areClose(aabb1.max, newPoint3D(1, 2, 4))

        # Second ellipsoid
        check areClose(aabb2.min, newPoint3D(-3, -sqrt(2.0), -sqrt(2.0)), eps = 1e-6)
        check areClose(aabb2.max, newPoint3D(3, 2 * sqrt(2.0), 2 * sqrt(2.0)), eps = 1e-6)


#---------------------------#
#    CSGUnion test suite    #
#---------------------------# 
suite "CSGUnion":

    setup:
        let 
            comp = newComposition(newRotX(90), newTranslation(eY))
            
            spSh1 = newSphere(newPoint3D(1, 2, 3), 2)
            spSh2 = newSphere(newPoint3D(-1, -2, -3), 2)
            triSh = newTriangle(eX.Point3D, eY.Point3D, eZ.Point3D, transformation = comp)
            csgUnion1 = newCSGUnion(spSh1, triSh, newTranslation(eX))
            csgUnion2 = newCSGUnion(csgUnion1, spSh2)
    
    teardown:
        discard comp
        discard spSh1
        discard spSh2
        discard triSh
        discard csgUnion1
        discard csgUnion2
    
    
    test "newCSGUnion proc":
        # Checking newCSGUnion proc

        #------------------------------------#
        #          First CSGUnion            #
        #------------------------------------#        
        # Checking first shape
        check csgUnion1.shape.shapes.primary.kind == skSphere
        check csgUnion1.shape.shapes.primary.radius == 2
        check csgUnion1.shape.shTrans.tPrimary.kind == tkTranslation
        check areClose(csgUnion1.shape.shTrans.tPrimary.mat, newTranslation(newVec3f(1, 2, 3)).mat)

        # Checking second shape
        check csgUnion1.shape.shapes.secondary.kind == skTriangle
        check csgUnion1.shape.shapes.secondary.vertices[0] == eX.Point3D
        check csgUnion1.shape.shapes.secondary.vertices[1] == eY.Point3D
        check csgUnion1.shape.shapes.secondary.vertices[2] == eZ.Point3D
        check csgUnion1.shape.shTrans.tSecondary.kind == tkComposition
        check areClose(csgUnion1.shape.shTrans.tSecondary.transformations[0].mat, newRotX(90).mat, eps = 1e-6)
        check areClose(csgUnion1.shape.shTrans.tSecondary.transformations[1].mat, newTranslation(eY).mat)

        # Checking transformation
        check areClose(csgUnion1.transformation.mat, newTranslation(eX).mat)

        #-------------------------------------#
        #          Second CSGUnion            #
        #-------------------------------------#
        # Checking first shape
        check csgUnion2.shape.shapes.primary.kind == skCSGUnion
        check csgUnion2.shape.shapes.primary.shapes.primary.kind == skSphere
        check csgUnion2.shape.shapes.primary.shapes.secondary.kind == skTriangle
        check areClose(csgUnion2.shape.shapes.primary.shTrans.tPrimary.mat, newTranslation(newVec3f(1, 2, 3)).mat)  
        check areClose(csgUnion2.shape.shapes.primary.shTrans.tSecondary.transformations[1].mat, newTranslation(eY).mat)  
        
        check csgUnion2.shape.shTrans.tPrimary.kind == tkTranslation
        check areClose(csgUnion2.shape.shTrans.tPrimary.mat, newTranslation(eX).mat)  

        # Checking second shape
        check csgUnion2.shape.shapes.secondary.kind == skSphere
        check csgUnion2.shape.shapes.primary.shapes.primary.kind == skSphere
        check csgUnion2.shape.shapes.primary.shapes.secondary.kind == skTriangle

        check csgUnion2.shape.shTrans.tSecondary.kind == tkTranslation
        check areClose(csgUnion2.shape.shTrans.tSecondary.mat, newTranslation(newVec3f(-1, -2, -3)).mat)  


    test "getVertices proc":
        # Gives vertices for all aabb being a part of CSGUnion shape, in "shape reference system".
        # We are not accounting for handler transformation
        let     
            vert1 = getVertices(csgUnion1.shape)
            vert2 = getVertices(csgUnion2.shape)
    
        # First CSGUnion
        check areClose(vert1[0], newPoint3D(-1,  0,  1))
        check areClose(vert1[1], newPoint3D( 3,  4,  5))
        check areClose(vert1[2], newPoint3D(-1,  0,  5))
        check areClose(vert1[3], newPoint3D(-1,  4,  1))
        check areClose(vert1[4], newPoint3D(-1,  4,  5))
        check areClose(vert1[5], newPoint3D( 3,  0,  1))
        check areClose(vert1[6], newPoint3D( 3,  0,  5))
        check areClose(vert1[7], newPoint3D( 3,  4,  1))
        check areClose(vert1[8], newPoint3D( 1,  0,  1))
        check areClose(vert1[9], newPoint3D( 0,  0,  2))
        check areClose(vert1[10], newPoint3D( 0, -1,  1))

        # Second CSGUnion
        check areClose(vert2[0], newPoint3D( 0,  0,  1))
        check areClose(vert2[1], newPoint3D( 4,  4,  5))
        check areClose(vert2[2], newPoint3D( 0,  0,  5))
        check areClose(vert2[3], newPoint3D( 0,  4,  1))
        check areClose(vert2[4], newPoint3D( 0,  4,  5))
        check areClose(vert2[5], newPoint3D( 4,  0,  1))
        check areClose(vert2[6], newPoint3D( 4,  0,  5))
        check areClose(vert2[7], newPoint3D( 4,  4,  1))
        check areClose(vert2[8], newPoint3D( 2,  0,  1))
        check areClose(vert2[9], newPoint3D( 1,  0,  2))
        check areClose(vert2[10], newPoint3D( 1, -1,  1))
        check areClose(vert2[11], newPoint3D(-3, -4, -5))
        check areClose(vert2[12], newPoint3D( 1,  0, -1))
        check areClose(vert2[13], newPoint3D(-3, -4, -1))
        check areClose(vert2[14], newPoint3D(-3,  0, -5))
        check areClose(vert2[15], newPoint3D(-3,  0, -1))
        check areClose(vert2[16], newPoint3D( 1, -4, -5))
        check areClose(vert2[17], newPoint3D( 1, -4, -1))
        check areClose(vert2[18], newPoint3D( 1,  0, -5))
    

    test "getAABB proc":
        # Gives aabb for a csgUnion shape in world reference system
        var aabb: Interval[Point3D]

        aabb = csgUnion1.getAABB
        check areClose(aabb.min, newPoint3D(0, -1, 1), eps = 1e-6)
        check areClose(aabb.max, newPoint3D(4, 4, 5), eps = 1e-6)

        aabb = csgUnion2.getAABB
        check areClose(aabb.min, newPoint3D(-3, -4, -5), eps = 1e-6)
        check areClose(aabb.max, newPoint3D(4, 4, 5), eps = 1e-6)



#-------------------------#
#    CSGInt test suite    #
#-------------------------# 
suite "CSGInt":

    setup:
        let 
            comp = newComposition(newRotX(90), newTranslation(eY))
            
            spSh1 = newSphere(newPoint3D(1, 2, 3), 2)
            spSh2 = newSphere(newPoint3D(-1, -2, -3), 2)
            triSh = newTriangle(eX.Point3D, eY.Point3D, eZ.Point3D, transformation = comp)
            csgInt1 = newCSGInt(spSh1, triSh, newTranslation(eX))
            csgInt2 = newCSGInt(csgInt1, spSh2)
    
    teardown:
        discard comp
        discard spSh1
        discard spSh2
        discard triSh
        discard csgInt1
        discard csgInt2
    
    
    test "newCSGInt proc":
        # Checking newCSGInt proc

        #----------------------------------#
        #          First CSGInt            #
        #----------------------------------#        
        # Checking first shape
        check csgInt1.shape.shapes.primary.kind == skSphere
        check csgInt1.shape.shapes.primary.radius == 2
        check csgInt1.shape.shTrans.tPrimary.kind == tkTranslation
        check areClose(csgInt1.shape.shTrans.tPrimary.mat, newTranslation(newVec3f(1, 2, 3)).mat)

        # Checking second shape
        check csgInt1.shape.shapes.secondary.kind == skTriangle
        check csgInt1.shape.shapes.secondary.vertices[0] == eX.Point3D
        check csgInt1.shape.shapes.secondary.vertices[1] == eY.Point3D
        check csgInt1.shape.shapes.secondary.vertices[2] == eZ.Point3D
        check csgInt1.shape.shTrans.tSecondary.kind == tkComposition
        check areClose(csgInt1.shape.shTrans.tSecondary.transformations[0].mat, newRotX(90).mat, eps = 1e-6)
        check areClose(csgInt1.shape.shTrans.tSecondary.transformations[1].mat, newTranslation(eY).mat)

        # Checking transformation
        check areClose(csgInt1.transformation.mat, newTranslation(eX).mat)


        #-----------------------------------#
        #          Second CSGInt            #
        #-----------------------------------#
        # Checking first shape
        check csgInt2.shape.shapes.primary.kind == skCSGInt
        check csgInt2.shape.shapes.primary.shapes.primary.kind == skSphere
        check csgInt2.shape.shapes.primary.shapes.secondary.kind == skTriangle
        check areClose(csgInt2.shape.shapes.primary.shTrans.tPrimary.mat, newTranslation(newVec3f(1, 2, 3)).mat)  
        check areClose(csgInt2.shape.shapes.primary.shTrans.tSecondary.transformations[1].mat, newTranslation(eY).mat)  
        
        check csgInt2.shape.shTrans.tPrimary.kind == tkTranslation
        check areClose(csgInt2.shape.shTrans.tPrimary.mat, newTranslation(eX).mat)  

        # Checking second shape
        check csgInt2.shape.shapes.secondary.kind == skSphere
        check csgInt2.shape.shapes.primary.shapes.primary.kind == skSphere
        check csgInt2.shape.shapes.primary.shapes.secondary.kind == skTriangle

        check csgInt2.shape.shTrans.tSecondary.kind == tkTranslation
        check areClose(csgInt2.shape.shTrans.tSecondary.mat, newTranslation(newVec3f(-1, -2, -3)).mat)  


    test "getVertices proc":
        # Gives vertices for all aabb being a part of CSGInt shape, in "shape reference system".
        # We are not accounting for handler transformation
        let     
            vert1 = getVertices(csgInt1.shape)
            vert2 = getVertices(csgInt2.shape)
    
        # First CSGInt
        check areClose(vert1[0], newPoint3D(-1,  0,  1))
        check areClose(vert1[1], newPoint3D( 3,  4,  5))
        check areClose(vert1[2], newPoint3D(-1,  0,  5))
        check areClose(vert1[3], newPoint3D(-1,  4,  1))
        check areClose(vert1[4], newPoint3D(-1,  4,  5))
        check areClose(vert1[5], newPoint3D( 3,  0,  1))
        check areClose(vert1[6], newPoint3D( 3,  0,  5))
        check areClose(vert1[7], newPoint3D( 3,  4,  1))
        check areClose(vert1[8], newPoint3D( 1,  0,  1))
        check areClose(vert1[9], newPoint3D( 0,  0,  2))
        check areClose(vert1[10], newPoint3D( 0, -1,  1))

        # Second CSGInt
        check areClose(vert2[0], newPoint3D( 0,  0,  1))
        check areClose(vert2[1], newPoint3D( 4,  4,  5))
        check areClose(vert2[2], newPoint3D( 0,  0,  5))
        check areClose(vert2[3], newPoint3D( 0,  4,  1))
        check areClose(vert2[4], newPoint3D( 0,  4,  5))
        check areClose(vert2[5], newPoint3D( 4,  0,  1))
        check areClose(vert2[6], newPoint3D( 4,  0,  5))
        check areClose(vert2[7], newPoint3D( 4,  4,  1))
        check areClose(vert2[8], newPoint3D( 2,  0,  1))
        check areClose(vert2[9], newPoint3D( 1,  0,  2))
        check areClose(vert2[10], newPoint3D( 1, -1,  1))
        check areClose(vert2[11], newPoint3D(-3, -4, -5))
        check areClose(vert2[12], newPoint3D( 1,  0, -1))
        check areClose(vert2[13], newPoint3D(-3, -4, -1))
        check areClose(vert2[14], newPoint3D(-3,  0, -5))
        check areClose(vert2[15], newPoint3D(-3,  0, -1))
        check areClose(vert2[16], newPoint3D( 1, -4, -5))
        check areClose(vert2[17], newPoint3D( 1, -4, -1))
        check areClose(vert2[18], newPoint3D( 1,  0, -5))


    test "getAABB proc":
        # Gives aabb for a csgInt shape in world reference system
        var aabb: Interval[Point3D]

        aabb = csgInt1.getAABB
        check areClose(aabb.min, newPoint3D(0, -1, 1), eps = 1e-6)
        check areClose(aabb.max, newPoint3D(4, 4, 5), eps = 1e-6)

        aabb = csgInt2.getAABB
        check areClose(aabb.min, newPoint3D(-3, -4, -5), eps = 1e-6)
        check areClose(aabb.max, newPoint3D(4, 4, 5), eps = 1e-6)



#-----------------------------#
#       Shape test suite      #
#-----------------------------#
suite "Shape":

    setup:
        let
            sh = newSphere(newPoint3D(1, 2, 3), 2)
            cyl = newCylinder(2, -2, 4)
            box = newBox((min: newPoint3D(-2, -3, -4), max: newPoint3D(1, 2 ,3)))
            ell = newEllipsoid(1, 2, 3)
            plane = newPlane()
            csgUnion = newCSGUnion(sh, cyl)
            csgInt = newCSGInt(newSphere(newPoint3D(-1, 0, 0), 2), newSphere(newPoint3D(1, 0, 0), 2))
    
    teardown:
        discard sh
        discard cyl
        discard box
        discard ell
        discard plane
        discard csgUnion

    
    test "inShape proc":
        # Checking inShape proc
        var pt1, pt2, pt3: Point3D

        # Sphere shape
        pt1 = newPoint3D(2, 2, 2)
        pt2 = newPoint3D(5, 5, 6)
        check sh.shape.inShape(sh.transformation.inverse.apply(pt1))
        check not sh.shape.inShape(sh.transformation.inverse.apply(pt2))

        # Cylinder shape
        pt1 = newPoint3D(0, 2, 2)
        pt2 = newPoint3D(2, 0, 6)
        check cyl.shape.inShape(cyl.transformation.inverse.apply(pt1))
        check not cyl.shape.inShape(cyl.transformation.inverse.apply(pt2))
    
        # Box shape
        pt1 = newPoint3D(0, 2, 2)
        pt2 = newPoint3D(6, 6, 6)
        check box.shape.inShape(box.transformation.inverse.apply(pt1))
        check not box.shape.inShape(box.transformation.inverse.apply(pt2))

        # Plane shape
        pt1 = newPoint3D(0, 2, -2)
        pt2 = newPoint3D(6, 6, 6)
        check plane.shape.inShape(plane.transformation.inverse.apply(pt1))
        check not plane.shape.inShape(plane.transformation.inverse.apply(pt2))

        # Ellipsoid shape
        pt1 = newPoint3D(0.5, 1, 1.5)
        pt2 = newPoint3D(6, 6, 6)
        check ell.shape.inShape(ell.transformation.inverse.apply(pt1))
        check not ell.shape.inShape(ell.transformation.inverse.apply(pt2))

        # CSGUnion shape
        pt1 = newPoint3D(1, 2, 3)
        pt2 = newPoint3D(2, 0, 0)
        pt3 = ORIGIN3D
        check csgUnion.shape.inShape(csgUnion.transformation.inverse.apply(pt1))
        check csgUnion.shape.inShape(csgUnion.transformation.inverse.apply(pt2))
        check not csgUnion.shape.inShape(csgUnion.transformation.inverse.apply(pt3))

        # CSGInt shape
        pt1 = newPoint3D(1, 2, 3)
        pt2 = newPoint3D(2, 0, 0)
        pt3 = ORIGIN3D
        check not csgInt.shape.inShape(csgInt.transformation.inverse.apply(pt1))
        check not csgInt.shape.inShape(csgInt.transformation.inverse.apply(pt2))
        check csgInt.shape.inShape(csgInt.transformation.inverse.apply(pt3))



#---------------------------------------#
#           Scene test suite            #
#---------------------------------------#
suite "Scene":

    setup:
        let 
            tri1 = newTriangle(newPoint3D(0, -2, 0), newPoint3D(2, 1, 1), newPoint3D(0, 3, 0))
            tri2 = newTriangle(newPoint3D(0, -2, 0), newPoint3D(2, 1, 1), newPoint3D(0, 3, 0), transformation = newTranslation([float32 1, 1, -2]))
            sc1 = newScene(@[tri1, tri2])
            sc2 = newScene(@[newSphere(ORIGIN3D, 3), newUnitarySphere(newPoint3D(4, 4, 4))], newColor(1, 0.3, 0.7))
            sc3 = newScene(@[newUnitarySphere(newPoint3D(3, 3, 3)), tri1])
    
    teardown:
        discard tri1
        discard tri2
        discard sc1
        discard sc2

    
    test "newScene proc":
        # Checking newScene proc

        # First scene --> only triangles
        check sc1.bgCol == BLACK
        check sc1.handlers.len == 2
        check sc1.handlers[0].shape.kind == skTriangle and sc1.handlers[1].shape.kind == skTriangle
        check areClose(sc1.handlers[0].shape.vertices[0], newPoint3D(0, -2, 0))
        check areClose(apply(sc1.handlers[1].transformation, sc1.handlers[1].shape.vertices[0]), newPoint3D(1, -1, -2))

        # Second scene --> only Spheres
        check sc2.bgCol == newColor(1, 0.3, 0.7)
        check sc2.handlers.len == 2
        check sc2.handlers[0].shape.kind == skSphere and sc2.handlers[1].shape.kind == skSphere
        check areClose(sc2.handlers[0].shape.radius, 3)
        check areClose(sc2.handlers[1].shape.radius, 1)
        check areClose(apply(sc2.handlers[0].transformation, ORIGIN3D), ORIGIN3D)
        check areClose(apply(sc2.handlers[1].transformation, ORIGIN3D), newPoint3D(4, 4, 4))

        # Third scene --> one Sphere and one Triangle
        # Checking newScene proc
        check sc3.bgCol == BLACK
        check sc3.handlers.len == 2
        check sc3.handlers[0].shape.kind == skSphere and sc3.handlers[1].shape.kind == skTriangle
        check areClose(sc3.handlers[0].shape.radius, 1)
        check areClose(apply(sc3.handlers[0].transformation, ORIGIN3D), newPoint3D(3, 3, 3))
        check areClose(sc3.handlers[1].shape.vertices[0], newPoint3D(0, -2, 0))


    test "getBVHTree proc":
        var 
            sceneTree: SceneNode
            rg = newPCG()

        # First scene, only triangles
        sceneTree = getBVHTree(scene = sc1, kind = tkBinary, rg = rg)
        check areClose(sceneTree.aabb.min, newPoint3D(0, -2, -2))
        check areClose(sceneTree.aabb.max, newPoint3D(3, 4, 1))


        # Second scene, only spheres
        sceneTree = getBVHTree(scene = sc2, kind = tkBinary, rg = rg)
        check areClose(sceneTree.aabb.min, newPoint3D(-3, -3, -3))
        check areClose(sceneTree.aabb.max, newPoint3D(5, 5, 5))


        # Third scene, one sphere and one triangle
        sceneTree = getBVHTree(scene = sc3, kind = tkBinary, rg = rg)
        check areClose(sceneTree.aabb.min, newPoint3D(0, -2, 0))
        check areClose(sceneTree.aabb.max, newPoint3D(4, 4, 4))
