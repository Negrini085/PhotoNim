import std/unittest
import PhotoNim

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
