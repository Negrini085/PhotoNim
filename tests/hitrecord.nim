import PhotoNim
import std/[unittest, options]

from std/sequtils import toSeq


#----------------------------------#
#       HitPayload test suite      #
#----------------------------------#


suite "HitPayload":

    setup:
        let 
            sph = newSphere(newPoint3D(1, 2, 3), 3, newDiffuseBRDF(newUniformPigment(WHITE)))
            ray1 = newRay(ORIGIN3D, eX)
            ray2 = newRay(newPoint3D(0,-4,-1), eY)

            rs = newRandomSetUp(42, 1)
            node = newBVHNode(@[sph].pairs.toSeq, 2, 1, rs)

            hitInfoNode = newHitInfo(node, ray1)
            hitInfoHandler = newHitInfo(sph, ray1)
            hitPayload = newHitPayload(sph, ray1, 4.23)

    teardown:
        discard rs
        discard sph
        discard ray1
        discard ray2
        discard node
        discard hitPayload
        discard hitInfoNode
        discard hitInfoHandler


    test "getIntersection proc":
        # Checking getIntersection procedure, to compute hit time
        # with aabb in world frame reference system

        let
            aabb1 = (newPoint3D(-1,-3,-2), newPoint3D( 1, 5, 2))
            aabb2 = (newPoint3D(-2,-1,-2), newPoint3D( 1, 3, 0))

        check areClose(aabb1.getIntersection(ray1), 1)
        check areClose(aabb2.getIntersection(ray1), 1)

        check areClose(aabb1.getIntersection(ray2), 1)
        check areClose(aabb2.getIntersection(ray2), 3)


    test "newHitInfo (ObjectHandler) proc":
        # Checking newHitInfo procedure for ObjectHandler kind

        check hitInfoHandler.hit.kind == hkShape
        check hitInfoHandler.hit.transformation.kind == tkTranslation
        check areClose(hitInfoHandler.hit.transformation.offset, newVec3f(1, 2, 3))
        check areClose(hitInfoHandler.hit.aabb.min, newPoint3D(-2,-1, 0))
        check areClose(hitInfoHandler.hit.aabb.max, newPoint3D( 4, 5, 6))

        check hitInfoHandler.hit.shape.kind == skSphere
        check areClose(hitInfoHandler.hit.shape.radius, 3)

        check areClose(hitInfoHandler.t, 4)


    test "newHitPayload (BVHNode) proc":
        # Checking newHitPayload procedure for BVHNode kind

        check areClose(hitInfoHandler.hit.aabb.min, newPoint3D(-2,-1, 0))
        check areClose(hitInfoHandler.hit.aabb.max, newPoint3D( 4, 5, 6))

        check areClose(hitInfoHandler.t, 4)


    test "newHitPayload proc":
        # Checking newHitPayload proc

        # Checking HitPayload.info
        check hitPayload.info.hit.kind == hkShape
        check hitPayload.info.hit.transformation.kind == tkTranslation
        check areClose(hitPayload.info.hit.transformation.offset, newVec3f(1, 2, 3))
        check areClose(hitPayload.info.hit.aabb.min, newPoint3D(-2,-1, 0))
        check areClose(hitPayload.info.hit.aabb.max, newPoint3D( 4, 5, 6))

        check hitPayload.info.hit.shape.kind == skSphere
        check areClose(hitPayload.info.hit.shape.radius, 3)
        
        check areClose(hitPayload.info.t, 4.23)

        # Checking HitPayload.pt
        check areClose(hitPayload.pt, ray1.at(4.23))

        # Checking HitPayload.rayDir
        check areClose(hitPayload.rayDir, eX)
