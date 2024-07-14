import PhotoNim
import std/[unittest, options]

from std/sequtils import toSeq
from std/math import PI


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



#--------------------------------------#
#     LocalIntersection test suite     #
#--------------------------------------#
suite "LocalIntersection":
    # LocalIntersection test suite, here we want to make sure that
    # everything is good in intersection evaluation between a ray and a shape

    setup:
        var
            t: float32

    teardown:
        discard t


    test "Sphere":
        # Checking getLocalIntersection for a ray-sphere intersection.
        # Here we need to assure that time computation is indeed correct.
        
        let 
            usphere = newUnitarySphere(
                    ORIGIN3D, 
                    newDiffuseBRDF(newUniformPigment(WHITE))
                )
            sphere = newSphere(
                    newPoint3D(0, 1, 0), 3.0, 
                    newDiffuseBRDF(newUniformPigment(WHITE))
                )

        var
            ray1 = newRay(newPoint3D(0, 0, 2), -eZ)
            ray2 = newRay(newPoint3D(3, 0, 0), -eX)
            ray3 = newRay(ORIGIN3D, eX)

        
        # Unitary sphere
        t = usphere.shape.getLocalIntersection(ray1.transform(usphere.transformation.inverse))
        check areClose(t, 1)

        t = usphere.shape.getLocalIntersection(ray2.transform(usphere.transformation.inverse))
        check areClose(t, 2)

        t = usphere.shape.getLocalIntersection(ray3.transform(usphere.transformation.inverse))
        check areClose(t, 1)    

        # Generic sphere
        ray1.origin = newPoint3D(0, 1, 5)
        ray2.origin = newPoint3D(4, 1, 0)
        ray3.origin = newPoint3D(1, 1, 0)

        t = sphere.shape.getLocalIntersection(ray1.transform(sphere.transformation.inverse))
        check areClose(t, 2)

        t = sphere.shape.getLocalIntersection(ray2.transform(sphere.transformation.inverse))
        check areClose(t, 1)

        t = sphere.shape.getLocalIntersection(ray3.transform(sphere.transformation.inverse))
        check areClose(t, 2)    


    test "Plane":
        # Checking getLocalIntersection for a ray-plane intersection.
        # Here we need to assure that time computation is indeed correct.

        let plane = newPlane(newDiffuseBRDF(newUniformPigment(WHITE)))

        var
            ray1 = newRay(newPoint3D(0, 0, 2), -eZ)
            ray2 = newRay(newPoint3D(1,-2,-3), newVec3f(0, 4/5, 3/5))
            ray3 = newRay(newPoint3D(3, 0, 0), -eX)

        
        t = plane.shape.getLocalIntersection(ray1.transform(plane.transformation.inverse))
        check areClose(t, 2)

        t = plane.shape.getLocalIntersection(ray2.transform(plane.transformation.inverse))
        check areClose(t, 5)

        t = plane.shape.getLocalIntersection(ray3.transform(plane.transformation.inverse))
        check t == Inf


    test "Box":
        # Checking getLocalIntersection for a ray-box intersection.
        # Here we need to assure that time computation is indeed correct.

        let box = newBox(
            (newPoint3D(-1, 0, 1), newPoint3D(3, 2, 5)),
            newDiffuseBRDF(newUniformPigment(BLACK))
            )

        var
            ray1 = newRay(newPoint3D(-5, 1, 2), eX)
            ray2 = newRay(newPoint3D(1, -2, 3), eY)
            ray3 = newRay(newPoint3D(4, 1, 0), newVec3f(-1, 0, 0))

          
        t = box.shape.getLocalIntersection(ray1.transform(box.transformation.inverse))
        check areClose(t, 4)

        t = box.shape.getLocalIntersection(ray2.transform(box.transformation.inverse))
        check areClose(t, 2)

        t = box.shape.getLocalIntersection(ray3.transform(box.transformation.inverse)) 
        check t == Inf


    test "Triangle":
        # Checking getLocalIntersection for a ray-triangle intersection.
        # Here we need to assure that time computation is indeed correct.

        let triangle = newTriangle(
                [newPoint3D(3, 0, 0), newPoint3D(-2, 0, 0), newPoint3D(0.5, 2, 0)],
                newDiffuseBRDF(newUniformPigment(WHITE))
            )

        var
            ray1 = newRay(newPoint3D(0, 1, -2), eZ)
            ray2 = newRay(newPoint3D(0, 1, -2), eX)

        t = triangle.shape.getLocalIntersection(ray1.transform(triangle.transformation.inverse))
        check areClose(t, 2)

        t = triangle.shape.getLocalIntersection(ray2.transform(triangle.transformation.inverse))
        check t == Inf


    test "Cylinder":
        # Checking getLocalIntersection for a ray-cylinder intersection.
        # Here we need to assure that time computation is indeed correct.

        let cylinder = newCylinder(
                2, -2, 2, 2 * PI,
                newDiffuseBRDF(newUniformPigment(WHITE))
            )

        var
            ray1 = newRay(ORIGIN3D, eX)
            ray2 = newRay(newPoint3D(4, 0, 0), -eX)
            ray3 = newRay(newPoint3D(0, 0, -4), eZ)
            ray4 = newRay(newPoint3D(2, 3, 1), eY)

        t = cylinder.shape.getLocalIntersection(ray1.transform(cylinder.transformation.inverse))
        check areClose(t, 2)

        t = cylinder.shape.getLocalIntersection(ray2.transform(cylinder.transformation.inverse))
        check areClose(t, 2)
        
        t = cylinder.shape.getLocalIntersection(ray3.transform(cylinder.transformation.inverse))
        # check areClose(t, 2)                   

        t = cylinder.shape.getLocalIntersection(ray4.transform(cylinder.transformation.inverse))
        check t == Inf


suite "Tree traverse":

    setup:
        var 
            scene: Scene
            hitPayload: HitPayload
            rs = newRandomSetUp(42, 54)

    teardown:
        discard rs
        discard scene
        discard hitPayload
    

    test "getClosestHit proc":
        # Checking getClosestHit procedure, we need to check
        # if the hit handler is the correct one

        let
            shsp1 = newSphere(
                    ORIGIN3D, 2,
                    newDiffuseBRDF(newUniformPigment(WHITE))
                )

            shsp2 = newSphere(
                    newPoint3D(5, 0, 0), 2, 
                    newDiffuseBRDF(newUniformPigment(WHITE))
                )

            shsp3 = newUnitarySphere(
                    newPoint3D(5, 5, 5),
                    newDiffuseBRDF(newUniformPigment(WHITE))
                )

            box = newBox(
                    (newPoint3D(-6, -6, -6), newPoint3D(-4, -4, -4)),
                    newDiffuseBRDF(newUniformPigment(WHITE))
                )
        
            ray1 = newRay(newPoint3D(-3, 0, 0), eX)
            ray2 = newRay(newPoint3D(-5,-5,-8), eZ)
            ray3 = newRay(newPoint3D(-9, 0, 0),-eX)

        scene = newScene(BLACK, @[shsp1, shsp2, shsp3, box], tkBinary, 1, rs)


        # First ray --> Origin: (-3, 0, 0), Dir: (1, 0, 0)
        hitPayload = scene.tree.getClosestHit(ray1)

        check (hitPayload.info.hit.shape.kind == skSphere) and (hitPayload.info.hit.shape.radius == 2)
        check areClose(hitPayload.info.t, 1)
        check areClose(hitPayload.pt, newPoint3D(-2, 0, 0))
        check areClose(hitPayload.rayDir, eX)

        # Second ray --> Origin: (-5,-5,-8), Dir: (0, 0, 1)
        hitPayload = scene.tree.getClosestHit(ray2)

        check hitPayload.info.hit.shape.kind == skAABox
        check areClose(hitPayload.info.hit.shape.aabb.min, newPoint3D(-6,-6,-6))
        check areClose(hitPayload.info.hit.shape.aabb.max, newPoint3D(-4,-4,-4))
        check areClose(hitPayload.info.t, 2)
        check areClose(hitPayload.pt, newPoint3D(-5,-5,-6))
        check areClose(hitPayload.rayDir, eZ)

        # Third ray --> Origin: (-9, 0, 0), Dir: (-1, 0, 0)
        check scene.tree.getClosestHit(ray3).info.hit.isNil

    
    test "no hits (random testing)":
        # Checking getClosestHit by means of random testing, 
        # we don't want to have an hit

        let ray = newRay(newPoint3D(30, 30, 30), eX)

        var 
            rg = newPCG(rs)
            rsSeq = newSeq[RandomSetUp](5)
            handlSeq = newSeq[ObjectHandler](500)


        # I'm gonna test it five times
        for i in 0..<5:

            rsSeq[i] = newRandomSetUp(rg.random, rg.random)

            for j in 0..<500:
                handlSeq[j] = newSphere(
                    newPoint3D(rg.rand(0, 15), rg.rand(0, 15), rg.rand(0, 15)), rg.rand(0, 10),
                    newDiffuseBRDF(newUniformPigment(newColor(rg.rand, rg.rand, rg.rand)))
                )

            scene = newScene(BLACK, handlSeq, tkBinary, 2, rsSeq[i])
            hitPayload = scene.tree.getClosestHit(ray)
            check hitPayload.info.hit.isNil

            handlSeq = newSeq[ObjectHandler](500)
