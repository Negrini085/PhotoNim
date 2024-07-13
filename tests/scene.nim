import std/unittest
import PhotoNim

from std/sequtils import toSeq

suite "AABB":

    setup:
        let
            aabb1 = (min: newPoint3D(-1, 0, 3), max: newPoint3D(2, 1, 5))
            aabb2 = (min: ORIGIN3D, max: newPoint3D(5, 5, 5))
    
    teardown:
        discard aabb1
        discard aabb2

    
    test "newAABB proc":
        # Checking newAABB proc, needed to create an aabb from 
        # a sequence of Point3D, usually box vertices

        let
            pt1 = newPoint3D(-1, 3, 8)
            pt2 = newPoint3D( 1,-2, 3)
            pt3 = newPoint3D( 5, 5, 7)
        
        var aabb = newAABB(@[pt1, pt2, pt3])

        check areClose(aabb.min, newPoint3D(-1, -2, 3))
        check areClose(aabb.max, newPoint3D( 5,  5, 8))


    test "getTotalAABB proc":
        # Checking getTotalAABB proc, needed to create an aabb 
        # which contains a sequence of AABB

        let
            pt1 = newPoint3D(-1, 3, 8)
            pt2 = newPoint3D( 1,-2, 3)
            pt3 = newPoint3D( 5, 5, 7)
        
        var aabb = newAABB(@[pt1, pt2, pt3])
        aabb = getTotalAABB(@[aabb, aabb1, aabb2])

        check areClose(aabb.min, newPoint3D(-1, -2, 0))
        check areClose(aabb.max, newPoint3D( 5,  5, 8))

    
    test "getCentroid proc":
        # Checking getCentroid proc, needed in order to 
        # divide aabb into clusters

        check areClose(aabb1.getCentroid(), newVec3f(0.5, 0.5, 4))
        check areClose(aabb2.getCentroid(), newVec3f(2.5, 2.5, 2.5))


    test "getVertices proc":
        # Checking getVertices proc, needed in order to 
        # be able to map aabb from local reference system to world one

        let
            vert1 = aabb1.getVertices
            vert2 = aabb2.getVertices

        # First AABB: <min: (-1, 0, 3), max: (2, 1, 5)>
        check areClose(vert1[0], newPoint3D(-1, 0, 3))
        check areClose(vert1[1], newPoint3D( 2, 1, 5))
        check areClose(vert1[2], newPoint3D(-1, 0, 5))
        check areClose(vert1[3], newPoint3D(-1, 1, 3))
        check areClose(vert1[4], newPoint3D(-1, 1, 5))
        check areClose(vert1[5], newPoint3D( 2, 0, 3))
        check areClose(vert1[6], newPoint3D( 2, 0, 5))
        check areClose(vert1[7], newPoint3D( 2, 1, 3))

        # Second AABB: <min: (0, 0, 0), max: (5, 5, 5)>
        check areClose(vert2[0], newPoint3D( 0, 0, 0))
        check areClose(vert2[1], newPoint3D( 5, 5, 5))
        check areClose(vert2[2], newPoint3D( 0, 0, 5))
        check areClose(vert2[3], newPoint3D( 0, 5, 0))
        check areClose(vert2[4], newPoint3D( 0, 5, 5))
        check areClose(vert2[5], newPoint3D( 5, 0, 0))
        check areClose(vert2[6], newPoint3D( 5, 0, 5))
        check areClose(vert2[7], newPoint3D( 5, 5, 0))


#---------------------------------------#
#           Scene test suite            #
#---------------------------------------#
suite "Scene":

    setup:
        let
            rs = newRandomSetUp(42, 54) 

            tri1 = newTriangle(
                [newPoint3D(0, -2, 0), newPoint3D(2, 1, 1), newPoint3D(0, 3, 0)],
                brdf = newDiffuseBRDF(newUniformPigment(WHITE))
                )

            tri2 = newTriangle(
                [newPoint3D(0, -2, 0), newPoint3D(2, 1, 1), newPoint3D(0, 3, 0)], 
                brdf = newDiffuseBRDF(newUniformPigment(WHITE)), transformation = newTranslation(newVec3f(1, 1, -2))
                )

            sc1 = newScene(BLACK, @[tri1, tri2], tkBinary, 1, rs)
            sc2 = newScene( newColor(1, 0.3, 0.7), @[
                    newSphere(ORIGIN3D, 3, brdf = newDiffuseBRDF(newUniformPigment(WHITE))), 
                    newUnitarySphere(newPoint3D(4, 4, 4), brdf = newDiffuseBRDF(newUniformPigment(WHITE)))
                    ], tkBinary, 1, rs
                )

            sc3 = newScene(BLACK, @[
                    newUnitarySphere(newPoint3D(3, 3, 3), brdf = newDiffuseBRDF(newUniformPigment(WHITE))), tri1
                ], tkBinary, 1, rs)
    
    teardown:
        discard rs
        discard sc1
        discard sc2
        discard sc3
        discard tri1
        discard tri2

    
    test "newScene proc":
        # Checking newScene proc

        # First scene --> only triangles
        check sc1.bgColor == BLACK
        check sc1.tree.handlers.len == 2
        check sc1.tree.handlers[0].shape.kind == skTriangle and sc1.tree.handlers[1].shape.kind == skTriangle
        check areClose(sc1.tree.handlers[0].shape.vertices[0], newPoint3D(0, -2, 0))
        check areClose(apply(sc1.tree.handlers[1].transformation, sc1.tree.handlers[1].shape.vertices[0]), newPoint3D(1, -1, -2))

        # Second scene --> only Spheres
        check sc2.bgColor == newColor(1, 0.3, 0.7)
        check sc2.tree.handlers.len == 2
        check sc2.tree.handlers[0].shape.kind == skSphere and sc2.tree.handlers[1].shape.kind == skSphere
        check areClose(sc2.tree.handlers[0].shape.radius, 3)
        check areClose(sc2.tree.handlers[1].shape.radius, 1)
        check areClose(apply(sc2.tree.handlers[0].transformation, ORIGIN3D), ORIGIN3D)
        check areClose(apply(sc2.tree.handlers[1].transformation, ORIGIN3D), newPoint3D(4, 4, 4))

        # Third scene --> one Sphere and one Triangle
        # Checking newScene proc
        check sc3.bgColor == BLACK
        check sc3.tree.handlers.len == 2
        check sc3.tree.handlers[0].shape.kind == skSphere and sc3.tree.handlers[1].shape.kind == skTriangle
        check areClose(sc3.tree.handlers[0].shape.radius, 1)
        check areClose(apply(sc3.tree.handlers[0].transformation, ORIGIN3D), newPoint3D(3, 3, 3))
        check areClose(sc3.tree.handlers[1].shape.vertices[0], newPoint3D(0, -2, 0))


    test "newBVHNode proc":
        var sceneTree: BVHNode

        # First scene, only triangles
        sceneTree = newBVHNode(@[tri1, tri2].pairs.toSeq, 2, 1, rs)
        check areClose(sceneTree.aabb.min, newPoint3D(0, -2, -2))
        check areClose(sceneTree.aabb.max, newPoint3D(3, 4, 1))


        # Second scene, only spheres
        sceneTree = newBVHNode(@[
                newSphere(ORIGIN3D, 3, newDiffuseBRDF(newUniformPigment(WHITE))), 
                newUnitarySphere(newPoint3D(4, 4, 4), newDiffuseBRDF(newUniformPigment(WHITE)))
                ].pairs.toSeq,
            2, 1, rs
        )
        check areClose(sceneTree.aabb.min, newPoint3D(-3, -3, -3))
        check areClose(sceneTree.aabb.max, newPoint3D(5, 5, 5))


        # Third scene, one sphere and one triangle
        sceneTree = newBVHNode(
            @[newUnitarySphere(newPoint3D(3, 3, 3), newDiffuseBRDF(newUniformPigment(WHITE))), tri1].pairs.toSeq
            , 2, 1, rs
        )
        check areClose(sceneTree.aabb.min, newPoint3D(0, -2, 0))
        check areClose(sceneTree.aabb.max, newPoint3D(4, 4, 4))
