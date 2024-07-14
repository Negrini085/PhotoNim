import std/unittest
import PhotoNim
from math import sin, cos, PI


#-----------------------------------#
#          AABB test suite          #
#-----------------------------------#
suite "AABox & AABB":

    setup:
        let
            p1 = ORIGIN3D
            p2 = newPoint3D(1, 2, 3)
            p3 = newPoint3D(-2, 2, -8)
            p4 = newPoint3D(-1, 4, 2)
            tr = newTranslation(eX)
            
            box1 = newBox((p1, p2), newDiffuseBRDF(newUniformPigment(newColor(0.3, 0.7, 1))), newUniformPigment(newColor(0.3, 0.7, 1)))
            box2 = newBox((p3, p4), newSpecularBRDF(newUniformPigment(newColor(1, 223/255, 0))), newUniformPigment(newColor(1, 223/255, 0)), tr)

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
        check box1.brdf.kind == DiffuseBRDF
        check box1.emittedRadiance.kind == pkUniform

        check box1.transformation.kind == tkIdentity


        # box2 --> giving min and max as input
        check areClose(box2.shape.aabb.min, newPoint3D(-2, 2,-8))
        check areClose(box2.shape.aabb.max, newPoint3D(-1, 4, 2))
        check box2.brdf.kind == SpecularBRDF
        check box2.emittedRadiance.kind == pkUniform

        check box2.transformation.kind == tkTranslation
        check areClose(box2.transformation.offset, eX)

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
        check areClose(box1.shape.getNormal(pt1, newVec3f( 1, 0, 0)), newNormal(-1, 0, 0))
        check areClose(box1.shape.getNormal(pt2, newVec3f(-1, 0, 0)), newNormal( 1, 0, 0))
        check areClose(box1.shape.getNormal(pt3, newVec3f(0,  1, 0)), newNormal(0, -1, 0))
        check areClose(box1.shape.getNormal(pt4, newVec3f(0, -1, 0)), newNormal(0,  1, 0))
        check areClose(box1.shape.getNormal(pt5, newVec3f(0, 0,  1)), newNormal(0, 0, -1))
        check areClose(box1.shape.getNormal(pt6, newVec3f(0, 0, -1)), newNormal(0, 0,  1))

        
        # box2 --> giving min and max as input
        pt1 = newPoint3D(-1.0, 3.0,-3.0); pt2 = newPoint3D( 0.0, 3.0,-3.0); pt3 = newPoint3D(-0.5, 2.0,-3.0)
        pt4 = newPoint3D(-0.5, 4.0,-3.0); pt5 = newPoint3D(-0.5, 3.0,-8.0); pt6 = newPoint3D(-0.5, 3.0, 2.0)

        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt1), newVec3f( 1, 0, 0)), newNormal(-1, 0, 0))
        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt2), newVec3f(-1, 0, 0)), newNormal( 1, 0, 0))
        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt3), newVec3f(0,  1, 0)), newNormal(0, -1, 0))
        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt4), newVec3f(0, -1, 0)), newNormal(0,  1, 0))
        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt5), newVec3f(0, 0,  1)), newNormal(0, 0, -1))
        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt6), newVec3f(0, 0, -1)), newNormal(0, 0,  1))


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
        pt1 = newPoint3D(-1.0, 3.0,-3.0); pt2 = newPoint3D( 0.0, 3.0,-3.0); pt3 = newPoint3D(-0.5, 2.0,-3.0)
        pt4 = newPoint3D(-0.5, 4.0,-3.0); pt5 = newPoint3D(-0.5, 3.0,-8.0); pt6 = newPoint3D(-0.5, 3.0, 2.0)

        check areClose(box2.shape.getUV(apply(box2.transformation.inverse, pt1)), newPoint2D(0.5, 0.5))
        check areClose(box2.shape.getUV(apply(box2.transformation.inverse, pt2)), newPoint2D(0.5, 0.5))
        check areClose(box2.shape.getUV(apply(box2.transformation.inverse, pt3)), newPoint2D(0.5, 0.5))
        check areClose(box2.shape.getUV(apply(box2.transformation.inverse, pt4)), newPoint2D(0.5, 0.5))
        check areClose(box2.shape.getUV(apply(box2.transformation.inverse, pt5)), newPoint2D(0.5, 0.5))
        check areClose(box2.shape.getUV(apply(box2.transformation.inverse, pt6)), newPoint2D(0.5, 0.5))


    test "getAABB (Box) proc":
        # Checking getAABB proc for box.shape
        # Gives AABB in shape local reference system
        let
            aabb1 = getAABB(box1.shape)
            aabb2 = getAABB(box2.shape)
        
        # First Box --> <min: (0, 0, 0), max: (1, 2, 3)>
        check areClose(aabb1.min, ORIGIN3D) 
        check areClose(aabb1.max, newPoint3D(1, 2, 3))

        # Second Box --> < min: (-2, 2, -8), max: (-1, 4, 2) > 
        check areClose(aabb2.min, newPoint3D(-2, 2,-8)) 
        check areClose(aabb2.max, newPoint3D(-1, 4, 2))


    test "getVertices (from AABox shape) proc":
        # Checking getVertices procedure to give aabb vertices locally for AABox
        let
            aabb1 = getAABB(box1.shape)
            aabb2 = getAABB(box2.shape)

            vert1 = getVertices(aabb1)
            vert2 = getVertices(aabb2)
        
        # Box 1 --> <min: (0, 0, 0), max: (1, 2, 3)>
        check areClose(vert1[0], newPoint3D( 0, 0, 0))
        check areClose(vert1[1], newPoint3D( 1, 2, 3))
        check areClose(vert1[2], newPoint3D( 0, 0, 3))
        check areClose(vert1[3], newPoint3D( 0, 2, 0))
        check areClose(vert1[4], newPoint3D( 0, 2, 3))
        check areClose(vert1[5], newPoint3D( 1, 0, 0))
        check areClose(vert1[6], newPoint3D( 1, 0, 3))
        check areClose(vert1[7], newPoint3D( 1, 2, 0))


        # Box 2 --> <min: (-2, 2, -8), max: (-1, 4, 2)>
        check areClose(vert2[0], newPoint3D(-2, 2,-8))
        check areClose(vert2[1], newPoint3D(-1, 4, 2))
        check areClose(vert2[2], newPoint3D(-2, 2, 2))
        check areClose(vert2[3], newPoint3D(-2, 4,-8))
        check areClose(vert2[4], newPoint3D(-2, 4, 2))
        check areClose(vert2[5], newPoint3D(-1, 2,-8))
        check areClose(vert2[6], newPoint3D(-1, 2, 2))
        check areClose(vert2[7], newPoint3D(-1, 4,-8))



#------------------------------#
#       Sphere test suite      #
#------------------------------#
suite "Sphere":

    setup:
        let
            sphere = newSphere(ORIGIN3D, 3.0, newSpecularBRDF(newUniformPigment(WHITE)))
            usphere = newUnitarySphere(eX.Point3D, newSpecularBRDF(newCheckeredPigment(BLACK, WHITE, 2, 2)), newCheckeredPigment(BLACK, WHITE, 2, 2))

    teardown: 
        discard usphere
        discard sphere


    test "newUnitarySphere proc":
        # Checking newUnitarySphere proc
        check usphere.shape.radius == 1.0
        check usphere.transformation.kind == tkTranslation
        check areClose(usphere.transformation.offset, eX)

        check usphere.brdf.kind == SpecularBRDF
        check usphere.emittedRadiance.kind == pkCheckered 
        check usphere.emittedRadiance.grid.nCols == 2.int
        check usphere.emittedRadiance.grid.nRows == 2.int
        check areClose(usphere.emittedRadiance.grid.c1, BLACK)
        check areClose(usphere.emittedRadiance.grid.c2, WHITE)


    test "newSphere proc":
        # Checking newSphere proc
        check sphere.shape.radius == 3.0
        check sphere.transformation.kind == tkIdentity

        check sphere.brdf.kind == SpecularBRDF
        check sphere.emittedRadiance.kind == pkUniform
        check areClose(sphere.emittedRadiance.color, BLACK)

    
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


    test "getAABB (Sphere) proc":
        # Checking getAABB proc, gives AABB in sphere local reference system
        let
            aabb1 = getAABB(usphere.shape)
            aabb2 = getAABB(sphere.shape)
        
        # Unitary sphere
        check areClose(aabb1.min, newPoint3D(-1,-1,-1))
        check areClose(aabb1.max, newPoint3D( 1, 1, 1))

        # Sphere with arbitrary radius
        check areClose(aabb2.min, newPoint3D(-3, -3, -3))
        check areClose(aabb2.max, newPoint3D( 3,  3,  3))


    test "getVertices (Sphere) proc":
        # Checking getVertices proc, gives AABB box vertices in shape local reference system
        let 
            aabb1 = getAABB(usphere.shape) 
            aabb2 = getAABB(sphere.shape) 

            vert1 = getVertices(aabb1)
            vert2 = getVertices(aabb2)
        
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
                [eX.Point3D, eY.Point3D, eZ.Point3D],
                newSpecularBRDF(newCheckeredPigment(WHITE, BLACK, 3, 3)), newCheckeredPigment(WHITE, BLACK, 3, 3)
                )
        
            tri2 =  newTriangle(
                [eX.Point3D, eY.Point3D, eZ.Point3D],
                newDiffuseBRDF(newUniformPigment(WHITE)), newUniformPigment(WHITE),
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

        check tri1.brdf.kind == SpecularBRDF
        check tri1.emittedRadiance.kind == pkCheckered
        check tri1.emittedRadiance.grid.nCols == 3
        check tri1.emittedRadiance.grid.nRows == 3
        check areClose(tri1.emittedRadiance.grid.c1, WHITE)
        check areClose(tri1.emittedRadiance.grid.c2, BLACK)


        # Triangle 2 --> Transformation is translation of (1, 2, 3)
        check areClose(tri2.shape.vertices[0], eX.Point3D)
        check areClose(tri2.shape.vertices[1], eY.Point3D)
        check areClose(tri2.shape.vertices[2], eZ.Point3D)

        check tri2.brdf.kind == DiffuseBRDF
        check tri2.emittedRadiance.kind == pkUniform
        check areClose(tri2.emittedRadiance.color, WHITE)
    

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


    test "getAABB (Triangle) proc":
        # Cheking getAABB proc, gives aabb in local reference system
        let 
            aabb1 = getAABB(tri1.shape)
            aabb2 = getAABB(tri2.shape)

        check areClose(aabb1.min, newPoint3D(0, 0, 0))
        check areClose(aabb1.max, newPoint3D(1, 1, 1))

        check areClose(aabb2.min, newPoint3D(0, 0, 0))
        check areClose(aabb2.max, newPoint3D(1, 1, 1))
    

    test "getVertices (Triangle) proc":
        # Checking getVertices proc, gives aabb vertices in local shape reference system
        var
            vert1 = getVertices(tri1.aabb)
            vert2 = getVertices(tri2.aabb)
        
        # First triangle -> identity transformation
        check areClose(vert1[0], tri1.aabb.min)
        check areClose(vert1[1], tri1.aabb.max)
        check areClose(vert1[2], newPoint3D(0, 0, 1))
        check areClose(vert1[3], newPoint3D(0, 1, 0))
        check areClose(vert1[4], newPoint3D(0, 1, 1))
        check areClose(vert1[5], newPoint3D(1, 0, 0))
        check areClose(vert1[6], newPoint3D(1, 0, 1))
        check areClose(vert1[7], newPoint3D(1, 1, 0))
    
        # Second triangle --> translation of (1, 2, 3)
        # Triangle AABB vertices
        check areClose(vert2[0], tri2.aabb.min)
        check areClose(vert2[1], tri2.aabb.max)
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

            cyl1 = newCylinder(brdf = newDiffuseBRDF(newUniformPigment(WHITE)))
            cyl2 = newCylinder(
                R = 2.0, brdf = newSpecularBRDF(newCheckeredPigment(WHITE, BLACK, 2, 2)),
                emittedRadiance = newCheckeredPigment(WHITE, BLACK, 2, 2), transformation = tr
                )
    
    teardown:
        discard tr
        discard cyl1
        discard cyl2
    
    
    test "newCylinder proc":
        # Checking newTriangle proc
        
        # First cylinder: default constructor
        check cyl1.shape.R == 1.0
        check areClose(cyl1.shape.phiMax, 2*PI)
        check cyl1.shape.zSpan.min == 0.0 and cyl1.shape.zSpan.max == 1.0

        check cyl1.brdf.kind == DiffuseBRDF
        check cyl1.emittedRadiance.kind == pkUniform
        # check areClose(cyl1.emittedRadiance.color, WHITE)

        check cyl1.transformation.kind == tkIdentity
    

        # Second cylinder: specific build
        check cyl2.shape.R == 2.0
        check areClose(cyl2.shape.phiMax, 2*PI)
        check cyl2.shape.zSpan.min == 0.0 and cyl2.shape.zSpan.max == 1.0

        check cyl2.brdf.kind == SpecularBRDF
        check cyl2.emittedRadiance.kind == pkCheckered
        check cyl2.emittedRadiance.grid.nRows == 2
        check cyl2.emittedRadiance.grid.nCols == 2
        check areClose(cyl2.emittedRadiance.grid.c1, WHITE)
        check areClose(cyl2.emittedRadiance.grid.c2, BLACK)

        check cyl2.transformation.kind == tkTranslation
        check areClose(cyl2.transformation.offset, eZ)


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


    test "getAABB (Cylinder) proc":
        # Cheking getAABB proc, gives aabb in local reference system
        let
            aabb1 = getAABB(cyl1.shape)
            aabb2 = getAABB(cyl2.shape)
        
        # First cylinder: default constructor
        check areClose(aabb1.min, newPoint3D(-1, -1, 0))
        check areClose(aabb1.max, newPoint3D(1, 1, 1))

        # Second cylinder: specific build
        check areClose(aabb2.min, newPoint3D(-2, -2, 0))
        check areClose(aabb2.max, newPoint3D(2, 2, 1))


    test "getVertices (Cylinder) proc":
        # Checking getVertices proc, gives aabb vertices in local shape reference system
        let
            aabb1 = getAABB(cyl1.shape)
            aabb2 = getAABB(cyl2.shape)

            vert1 = getVertices(aabb1)
            vert2 = getVertices(aabb2)
        
        # First cylinder
        check areClose(vert1[0], cyl1.aabb.min)
        check areClose(vert1[1], cyl1.aabb.max)
        check areClose(vert1[2], newPoint3D(-1, -1, 1))
        check areClose(vert1[3], newPoint3D(-1,  1, 0))
        check areClose(vert1[4], newPoint3D(-1,  1, 1))
        check areClose(vert1[5], newPoint3D( 1, -1, 0))
        check areClose(vert1[6], newPoint3D( 1, -1, 1))
        check areClose(vert1[7], newPoint3D( 1,  1, 0))

        # Second cylinder  
        check areClose(vert2[0], newPoint3D(-2, -2, 0))
        check areClose(vert2[1], newPoint3D( 2,  2, 1))
        check areClose(vert2[2], newPoint3D(-2, -2, 1))
        check areClose(vert2[3], newPoint3D(-2,  2, 0))
        check areClose(vert2[4], newPoint3D(-2,  2, 1))
        check areClose(vert2[5], newPoint3D( 2, -2, 0))
        check areClose(vert2[6], newPoint3D( 2, -2, 1))
        check areClose(vert2[7], newPoint3D( 2,  2, 0))
