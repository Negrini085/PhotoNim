import std/unittest
import ../src/[shape, scene, geometry, color, material]

from math import sin, cos, PI, sqrt


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

            mat1 = newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(newColor(0.3, 0.7, 1))), newUniformPigment(newColor(0.3, 0.7, 1)))
            mat2 = newEmissiveMaterial(newSpecularBRDF(newUniformPigment(newColor(1, 223/255, 0))), newUniformPigment(newColor(1, 223/255, 0)))
            
            box1 = newBox((p1, p2), mat1)
            box2 = newBox((p3, p4), mat2, tr)

    teardown:
        discard tr
        discard p1
        discard p2
        discard p3
        discard p4
        discard mat1
        discard mat2
        discard box1
        discard box2
    

    test "newBox proc":
        # Checking newBox procs

        # box1 --> No transformation given
        check areClose(box1.shape.aabb.min, ORIGIN3D)
        check areClose(box1.shape.aabb.max, newPoint3D(1, 2, 3))
        check box1.material.kind == mkEmissive
        check box1.material.brdf.kind == DiffuseBRDF
        check box1.material.eRadiance.kind == pkUniform

        check box1.transformation.kind == tkIdentity


        # box2 --> giving min and max as input
        check areClose(box2.shape.aabb.min, newPoint3D(-2, 2,-8))
        check areClose(box2.shape.aabb.max, newPoint3D(-1, 4, 2))
        check box1.material.kind == mkEmissive
        check box2.material.brdf.kind == SpecularBRDF
        check box2.material.eRadiance.kind == pkUniform

        check box2.transformation.kind == tkTranslation
        check areClose(box2.transformation.offset, eX)

    test "getNormal proc":
        # Checking getNormal proc
        var 
            pt1 = newPoint3D(0.0, 0.5, 0.5)
            pt2 = newPoint3D(1.0, 0.5, 0.5)
            pt3 = newPoint3D(0.5, 0.0, 0.5)
            pt4 = newPoint3D(0.5, 2.0, 0.5)
            pt5 = newPoint3D(0.5, 0.5, 0.0)
            pt6 = newPoint3D(0.5, 0.5, 3.0)
        
        # box1 --> default constructor
        check areClose(box1.shape.getNormal(pt1, newVec3( 1, 0, 0)), newNormal(-1, 0, 0))
        check areClose(box1.shape.getNormal(pt2, newVec3(-1, 0, 0)), newNormal( 1, 0, 0))
        check areClose(box1.shape.getNormal(pt3, newVec3(0,  1, 0)), newNormal(0, -1, 0))
        check areClose(box1.shape.getNormal(pt4, newVec3(0, -1, 0)), newNormal(0,  1, 0))
        check areClose(box1.shape.getNormal(pt5, newVec3(0, 0,  1)), newNormal(0, 0, -1))
        check areClose(box1.shape.getNormal(pt6, newVec3(0, 0, -1)), newNormal(0, 0,  1))

        
        # box2 --> giving min and max as input
        pt1 = newPoint3D(-1.0, 3.0,-3.0); pt2 = newPoint3D( 0.0, 3.0,-3.0); pt3 = newPoint3D(-0.5, 2.0,-3.0)
        pt4 = newPoint3D(-0.5, 4.0,-3.0); pt5 = newPoint3D(-0.5, 3.0,-8.0); pt6 = newPoint3D(-0.5, 3.0, 2.0)

        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt1), newVec3( 1, 0, 0)), newNormal(-1, 0, 0))
        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt2), newVec3(-1, 0, 0)), newNormal( 1, 0, 0))
        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt3), newVec3(0,  1, 0)), newNormal(0, -1, 0))
        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt4), newVec3(0, -1, 0)), newNormal(0,  1, 0))
        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt5), newVec3(0, 0,  1)), newNormal(0, 0, -1))
        check areClose(box2.shape.getNormal(apply(box2.transformation.inverse, pt6), newVec3(0, 0, -1)), newNormal(0, 0,  1))


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
            mat1 = newMaterial(newSpecularBRDF(newUniformPigment(WHITE)))
            mat2 = newEmissiveMaterial(newSpecularBRDF(newCheckeredPigment(BLACK, WHITE, 2, 2)), newCheckeredPigment(BLACK, WHITE, 2, 2))

            sphere = newSphere(ORIGIN3D, 3.0, mat1)
            usphere = newUnitarySphere(eX.Point3D, mat2)

    teardown: 
        discard mat1
        discard mat2
        discard sphere
        discard usphere


    test "newUnitarySphere proc":
        # Checking newUnitarySphere proc
        check usphere.shape.radius == 1.0
        check usphere.transformation.kind == tkTranslation
        check areClose(usphere.transformation.offset, eX)

        check usphere.material.brdf.kind == SpecularBRDF
        check usphere.material.eRadiance.kind == pkCheckered 
        check usphere.material.eRadiance.grid.nCols == 2.int
        check usphere.material.eRadiance.grid.nRows == 2.int
        check areClose(usphere.material.eRadiance.grid.c1, BLACK)
        check areClose(usphere.material.eRadiance.grid.c2, WHITE)


    test "newSphere proc":
        # Checking newSphere proc
        check sphere.shape.radius == 3.0
        check sphere.transformation.kind == tkIdentity

        check sphere.material.kind == mkNonEmissive
        check sphere.material.brdf.kind == SpecularBRDF

    
    test "getNormal proc":
        # Checking sphere normal computation method
        var
            pt1 = newPoint3D(1, 0 ,0)
            pt2 = newPoint3D(cos(PI/3), sin(PI/3) ,0)
            d = newVec3(-1, 2, 0)
        
        # Unitary sphere
        check areClose(usphere.shape.getNormal(pt1, d), newNormal(1, 0, 0))
        check areClose(usphere.shape.getNormal(pt2, d), newNormal(-cos(PI/3), -sin(PI/3), 0))

        # Sphere with arbitrary radius
        check areClose(sphere.shape.getNormal((3.float32*pt1.Vec3).Point3D, d), newNormal(1, 0, 0))
        check areClose(sphere.shape.getNormal((3.float32*pt2.Vec3).Point3D, d), newNormal(-cos(PI/3), -sin(PI/3), 0))

    
    test "getUV proc":
        # Checking (u, v) coordinates computation
        var
            pt1 = newPoint3D(1, 0, 0)
            pt2 = newPoint3D(cos(PI/3), sin(PI/3), 0)

        # Unitary sphere
        check areClose(usphere.shape.getUV(pt1), newPoint2D(0.0, 0.5))
        check areClose(usphere.shape.getUV(pt2), newPoint2D(1/6, 0.5))

        # Sphere with arbitrary radius
        check areClose(sphere.shape.getUV((3.float32*pt1.Vec3).Point3D), newPoint2D(0.0, 0.5))
        check areClose(sphere.shape.getUV((3.float32*pt2.Vec3).Point3D), newPoint2D(1/6, 0.5))


    test "getAABB (Local) proc":
        # Checking getAABB proc, gives AABB in sphere local reference system
        let
            aabb1 = getAABB(usphere.shape)
            aabb2 = getAABB(sphere.shape)
        
        # Unitary
        check areClose(aabb1.min, newPoint3D(-1,-1,-1))
        check areClose(aabb1.max, newPoint3D( 1, 1, 1))

        # Arbitrary radius
        check areClose(aabb2.min, newPoint3D(-3, -3, -3))
        check areClose(aabb2.max, newPoint3D( 3,  3,  3))


    test "getVertices (Local) proc":
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


    test "getAABB (World) proc":
        # Checking getAABB proc, gives AABB in world reference system
        let
            aabb1 = usphere.aabb
            aabb2 = sphere.aabb
        
        # Unitary
        check areClose(aabb1.min, newPoint3D( 0,-1,-1))
        check areClose(aabb1.max, newPoint3D( 2, 1, 1))

        # Arbitrary radius
        check areClose(aabb2.min, newPoint3D(-3, -3, -3))
        check areClose(aabb2.max, newPoint3D( 3,  3,  3))
    

#-----------------------------#
#       Plane test suite      #
#-----------------------------#
suite "Plane":

    setup:
        let
            mat1 = newMaterial(newSpecularBRDF(newUniformPigment(WHITE)))
            mat2 = newEmissiveMaterial(newDiffuseBRDF(newCheckeredPigment(BLACK, WHITE, 2, 2)), newCheckeredPigment(BLACK, WHITE, 2, 2))

            pl1 = newPlane(mat1)
            pl2 = newPlane(mat2, newRotation(30, axisX))

    teardown: 
        discard pl1
        discard pl2
        discard mat1
        discard mat2


    test "newPlane proc":
        # Checking newPlane proc

        # FIRST PLANE
        check pl1.kind == hkShape
        check pl1.shape.kind == skPlane
        check pl1.transformation.kind == tkIdentity

        check pl1.material.kind == mkNonEmissive
        check pl1.material.brdf.kind == SpecularBRDF
        check pl1.material.brdf.pigment.kind == pkUniform
        check areClose(pl1.material.brdf.pigment.getColor(newPoint2D(0, 0)), WHITE)

        # SECOND PLANE
        check pl2.kind == hkShape
        check pl2.shape.kind == skPlane
        check pl2.transformation.kind == tkRotation
        
        check pl2.transformation.axis == axisX
        check areClose(pl2.transformation.sin, sin(PI/6), eps = 1e-6) 
        check areClose(pl2.transformation.cos, cos(PI/6), eps = 1e-6)

        check pl2.material.kind == mkEmissive
        check pl2.material.brdf.kind == DiffuseBRDF
        check pl2.material.brdf.pigment.kind == pkCheckered


    test "getNormal proc":
        # Checking plane normal computation method
        var
            pt1 = ORIGIN3D
            pt2 = newPoint3D(-100, 30, 0)
            d = newVec3(-1, 2, -1)
        
        # FIRST PLANE
        check areClose(pl1.shape.getNormal(pt1, d), eZ.Normal)
        check areClose(pl1.shape.getNormal(pt2, d), ez.Normal)

        # SECOND PLANE
        check areClose(pl2.shape.getNormal(pt1, d), eZ.Normal)
        check areClose(pl2.shape.getNormal(pt2, d), ez.Normal)

    
    test "getUV proc":
        # Checking (u, v) coordinates computation
        var
            pt1 = newPoint3D(1.5, 0.5, 0)
            pt2 = newPoint3D(0.5, 0.5, 0)

        # FIRST PLANE
        check areClose(pl1.shape.getUV(pt1), newPoint2D(0.5, 0.5))
        check areClose(pl1.shape.getUV(pt2), newPoint2D(0.5, 0.5))

        # SECOND PLANE
        check areClose(pl2.shape.getUV(pt1), newPoint2D(0.5, 0.5))
        check areClose(pl2.shape.getUV(pt2), newPoint2D(0.5, 0.5))


    test "getAABB (Local) proc":
        # Checking getAABB proc, gives AABB in plane local reference system
        let
            aabb1 = getAABB(pl1.shape)
            aabb2 = getAABB(pl2.shape)
        
        # FIRST PLANE
        check aabb1.min.x == -Inf and aabb1.min.y == -Inf and aabb1.min.z == -Inf
        check aabb1.max.x ==  Inf and aabb1.max.y ==  Inf and aabb1.max.z == 0
        
        # SECOND PLANE
        check aabb2.min.x == -Inf and aabb2.min.y == -Inf and aabb2.min.z == -Inf
        check aabb2.max.x ==  Inf and aabb2.max.y ==  Inf and aabb2.max.z == 0


    test "getWorldAABB proc":
        # Checking getWorldAABB proc, gives AABB in world reference system
        let
            aabb1 = pl1.aabb
            aabb2 = pl2.aabb
        
        # FIRST PLANE
        check aabb1.min.x == -Inf and aabb1.min.y == -Inf and aabb1.min.z == -Inf
        check aabb1.max.x ==  Inf and aabb1.max.y ==  Inf and aabb1.max.z == 0
        
        # SECOND PLANE
        check aabb2.min.x == -Inf and aabb2.min.y == -Inf and aabb2.min.z == -Inf
        check aabb2.max.x ==  Inf and aabb2.max.y ==  Inf and aabb2.max.z ==  Inf



#-------------------------------#
#      Triangle test suite      #
#-------------------------------#
suite "Triangle":
    
    setup:
        let 
            mat1 = newEmissiveMaterial(newSpecularBRDF(newCheckeredPigment(WHITE, BLACK, 3, 3)), newCheckeredPigment(WHITE, BLACK, 3, 3))
            mat2 = newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(WHITE)), newUniformPigment(WHITE))

            tri1 =  newTriangle([eX.Point3D, eY.Point3D, eZ.Point3D], mat1)
            tri2 =  newTriangle([eX.Point3D, eY.Point3D, eZ.Point3D], mat2, newTranslation(newVec3(1, 2, 3)))
    
    teardown:
        discard tri1
        discard tri2
        discard mat1
        discard mat2

    
    test "newTriangle proc":
        # Checking newTriangle proc
        
        # Triangle 1 --> Transformation is identity
        check areClose(tri1.shape.vertices[0], eX.Point3D)
        check areClose(tri1.shape.vertices[1], eY.Point3D)
        check areClose(tri1.shape.vertices[2], eZ.Point3D)

        check tri1.material.brdf.kind == SpecularBRDF
        check tri1.material.eRadiance.kind == pkCheckered
        check tri1.material.eRadiance.grid.nCols == 3
        check tri1.material.eRadiance.grid.nRows == 3
        check areClose(tri1.material.eRadiance.grid.c1, WHITE)
        check areClose(tri1.material.eRadiance.grid.c2, BLACK)


        # Triangle 2 --> Transformation is translation of (1, 2, 3)
        check areClose(tri2.shape.vertices[0], eX.Point3D)
        check areClose(tri2.shape.vertices[1], eY.Point3D)
        check areClose(tri2.shape.vertices[2], eZ.Point3D)

        check tri2.material.brdf.kind == DiffuseBRDF
        check tri2.material.eRadiance.kind == pkUniform
        check areClose(tri2.material.eRadiance.color, WHITE)
    

    test "getNormal proc":
        # Checking getNormal proc
        let pt = newPoint3D(0.2, 0.2, 0.6)

        check areClose(tri1.shape.getNormal(pt, newVec3(-1, 0, 0)).Vec3, newVec3(1, 1, 1).normalize)
        check areClose(tri2.shape.getNormal(pt, newVec3(-1, 0, 0)).Vec3, newVec3(1, 1, 1).normalize)
    

    test "getUV proc":
        # Checking getUV proc
        let pt = newPoint3D(0.2, 0.2, 0.6)

        check areClose(tri1.shape.getUV(pt), newPoint2D(0.2, 0.6))
        check areClose(tri2.shape.getUV(pt), newPoint2D(0.2, 0.6))


    test "getAABB (Local) proc":
        # Cheking getAABB proc, gives aabb in local reference system
        let 
            aabb1 = getAABB(tri1.shape)
            aabb2 = getAABB(tri2.shape)

        check areClose(aabb1.min, newPoint3D(0, 0, 0))
        check areClose(aabb1.max, newPoint3D(1, 1, 1))

        check areClose(aabb2.min, newPoint3D(0, 0, 0))
        check areClose(aabb2.max, newPoint3D(1, 1, 1))
    

    test "getVertices (Local) proc":
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


    test "getAABB (World) proc":
        # Cheking getAABB proc, gives aabb in world reference system
        let 
            aabb1 = tri1.aabb
            aabb2 = tri2.aabb

        check areClose(aabb1.min, newPoint3D(0, 0, 0))
        check areClose(aabb1.max, newPoint3D(1, 1, 1))

        check areClose(aabb2.min, newPoint3D(1, 2, 3))
        check areClose(aabb2.max, newPoint3D(2, 3, 4))



#----------------------------#
#    Cylinder test suite     #
#----------------------------# 
suite "Cylinder":

    setup:
        let 
            tr = newTranslation(eZ)

            mat1 = newMaterial(newDiffuseBRDF(newUniformPigment(WHITE)))
            mat2 = newEmissiveMaterial(
                    newSpecularBRDF(newCheckeredPigment(WHITE, BLACK, 2, 2)),
                    newCheckeredPigment(WHITE, BLACK, 2, 2)
                )

            cyl1 = newCylinder(material = mat1)
            cyl2 = newCylinder(R = 2.0, material = mat2, transformation = tr)
    
    teardown:
        discard tr
        discard cyl1
        discard cyl2
        discard mat1
        discard mat2
    
    
    test "newCylinder proc":
        # Checking newTriangle proc
        
        # First cylinder: default constructor
        check cyl1.shape.R == 1.0
        check areClose(cyl1.shape.phiMax, 2*PI)
        check cyl1.shape.zSpan.min == 0.0 and cyl1.shape.zSpan.max == 1.0

        check cyl1.material.kind == mkNonEmissive
        check cyl1.material.brdf.kind == DiffuseBRDF
        check cyl1.transformation.kind == tkIdentity

        # Second cylinder: specific build
        check cyl2.shape.R == 2.0
        check areClose(cyl2.shape.phiMax, 2*PI)
        check cyl2.shape.zSpan.min == 0.0 and cyl2.shape.zSpan.max == 1.0

        check cyl2.material.brdf.kind == SpecularBRDF
        check cyl2.material.eRadiance.kind == pkCheckered
        check cyl2.material.eRadiance.grid.nRows == 2
        check cyl2.material.eRadiance.grid.nCols == 2
        check areClose(cyl2.material.eRadiance.grid.c1, WHITE)
        check areClose(cyl2.material.eRadiance.grid.c2, BLACK)

        check cyl2.transformation.kind == tkTranslation
        check areClose(cyl2.transformation.offset, eZ)


    test "getNormal proc":
        # Checking getNormal proc
        var
            pt1 = newPoint3D(1.0, 0.0, 0.5)
            pt2 = newPoint3D(2.0, 0.0, 0.5)
        
        check areClose(cyl1.shape.getNormal(pt1, newVec3(0, 0, -1)).Vec3, newVec3(1, 0, 0))
        check areClose(cyl2.shape.getNormal(pt2, newVec3(0, 0, -1)).Vec3, newVec3(1, 0, 0))
    

    test "getUV proc":
        # Checking getUV proc
        var
            pt1 = newPoint3D(cos(PI/3), sin(PI/3), 0.5)
            pt2 = newPoint3D(1.0, 0.0, 0.3)
        
        # First cylinder: default constructor
        check areClose(cyl1.shape.getUV(pt1), newPoint2D(1/6, 0.5))
        check areClose(cyl1.shape.getUV(pt2), newPoint2D(0.0, 0.3))

        # Second cylinder: specific build
        check areClose(cyl2.shape.getUV(newPoint3D(2 * cos(PI/3), 2 * sin(PI/3), 0.5)), newPoint2D(1/6, 0.5))
        check areClose(cyl2.shape.getUV(newPoint3D(2.0, 0.0, 0.3)), newPoint2D(0.0, 0.3))


    test "getAABB (Local) proc":
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


    test "getVertices (Local) proc":
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


    test "getAABB (World) proc":
        # Cheking getAABB proc, gives aabb in local reference system
        let
            aabb1 = cyl1.aabb
            aabb2 = cyl2.aabb
        
        # First cylinder: no transformation 
        check areClose(aabb1.min, newPoint3D(-1, -1, 0))
        check areClose(aabb1.max, newPoint3D(1, 1, 1))

        # Second cylinder: translation along z-axis
        check areClose(aabb2.min, newPoint3D(-2, -2, 1))
        check areClose(aabb2.max, newPoint3D(2, 2, 2))



#----------------------------#
#    Ellipsoid test suite    #
#----------------------------# 
suite "Ellipsoid":

    setup:
        let 
            tr = newTranslation(eZ)
            comp = newComposition(newRotation(45, axisX), newTranslation(eY))

            mat = newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(WHITE)), newUniformPigment(WHITE))

            ell1 = newEllipsoid(1, 2, 3, mat, tr)
            ell2 = newEllipsoid(3.0, 2.0, 1.0, mat, comp)
    
    teardown:
        discard tr
        discard mat
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
        check areClose(ell1.transformation.offset, eZ)
    
        # Second Ellipsoid
        check ell2.shape.kind == skEllipsoid
        check areClose(ell2.shape.axis.a, 3.0)
        check areClose(ell2.shape.axis.b, 2.0)
        check areClose(ell2.shape.axis.c, 1.0)

        check ell2.transformation.kind == tkComposition
        check ell2.transformation.transformations.len == 2
        check ell2.transformation.transformations[0].kind == tkRotation
        check ell2.transformation.transformations[1].kind == tkTranslation
        check ell2.transformation.transformations[0].axis == axisX
        check areClose(ell2.transformation.transformations[0].cos, newRotation(45, axisX).cos, eps = 1e-6)
        check areClose(ell2.transformation.transformations[0].sin, newRotation(45, axisX).sin, eps = 1e-6)
        check areClose(ell2.transformation.transformations[1].offset, eY)


    test "getNormal proc":
        # Checking ellipsoid normal computation method
        var
            dir: Vec3
            pt: Point3D
        
        # First ellipsoid
        dir = newVec3(-1, 0, 0)
        pt = newPoint3D(ell1.shape.axis.a, 0, 0)
        check areClose(ell1.shape.getNormal(pt, dir), newNormal(1, 0, 0))

        dir = newVec3(0, -1, 0)
        pt = newPoint3D(ell1.shape.axis.a * cos(PI/3), ell1.shape.axis.b * sin(PI/3), 0)
        check areClose(ell1.shape.getNormal(pt, dir), newNormal(1/2, sqrt(3.0)/4, 0), eps = 1e-6)
    
        # First ellipsoid
        dir = newVec3(-1, 0, 0)
        pt = newPoint3D(ell2.shape.axis.a, 0, 0)
        check areClose(ell2.shape.getNormal(pt, dir), newNormal(1, 0, 0))

        dir = newVec3(0, -1, 0)
        pt = newPoint3D(ell2.shape.axis.a * cos(PI/3), ell2.shape.axis.b * sin(PI/3), 0)
        check areClose(ell2.shape.getNormal(pt, dir), newNormal(1/6, sqrt(3.0)/4, 0), eps = 1e-6)


    test "getUV proc":
        # Checking (u, v) coordinates computation
        var pt1, pt2: Point3D

        # Unitary sphere
        pt1 = newPoint3D(ell1.shape.axis.a, 0, 0)
        pt2 = newPoint3D(ell1.shape.axis.a * cos(PI/3), ell1.shape.axis.b * sin(PI/3), 0)
        check areClose(ell1.shape.getUV(pt1), newPoint2D(0.0, 0.5))
        check areClose(ell1.shape.getUV(pt2), newPoint2D(1/6, 0.5))

        # Sphere with arbitrary radius
        pt1 = newPoint3D(ell2.shape.axis.a, 0, 0)
        pt2 = newPoint3D(ell2.shape.axis.a * cos(PI/3), ell2.shape.axis.b * sin(PI/3), 0)
        check areClose(ell2.shape.getUV(pt1), newPoint2D(0.0, 0.5))
        check areClose(ell2.shape.getUV(pt2), newPoint2D(1/6, 0.5))


    test "getAABB (Local) proc":
        # Cheking getAABB proc, gives aabb in local reference system
        let
            aabb1 = getAABB(ell1.shape)
            aabb2 = getAABB(ell2.shape)
        
        # First ellipsoid
        check areClose(aabb1.min, newPoint3D(-1, -2, -3))
        check areClose(aabb1.max, newPoint3D( 1,  2,  3))

        # Second ellipsoid
        check areClose(aabb2.min, newPoint3D(-3, -2, -1))
        check areClose(aabb2.max, newPoint3D( 3,  2,  1))


    test "getVertices (Local) proc":
        # Checking getVertices proc, gives aabb vertices in local shape reference system
        let
            aabb1 = getAABB(ell1.shape)
            aabb2 = getAABB(ell2.shape)
        
            vert1 = getVertices(aabb1)
            vert2 = getVertices(aabb2)
        
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


    test "getAABB (World) proc":
        # Cheking getAABB proc, gives aabb in world
        let
            aabb1 = ell1.aabb
            aabb2 = ell2.aabb
        
        # First ellipsoid
        check areClose(aabb1.min, newPoint3D(-1, -2, -2))
        check areClose(aabb1.max, newPoint3D(1, 2, 4))

        # Second ellipsoid
        check areClose(aabb2.min, newPoint3D(-3.0, -sqrt(2.0), -sqrt(2.0)), eps = 1e-6)
        check areClose(aabb2.max, newPoint3D(3.0, 2 * sqrt(2.0), 2 * sqrt(2.0)), eps = 1e-6)
