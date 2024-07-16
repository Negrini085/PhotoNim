import std/unittest

import ../src/[geometry, scene, shape, csg, ray, material, pigment, color, brdf, pcg, hitrecord]

from std/sequtils import toSeq

#----------------------------------#
#       HitPayload test suite      #
#----------------------------------#
suite "HitPayload":
    # Here we just want to check that HitPayload creation isNil
    # working as we espect

    setup:
        let 
            mat = newMaterial(newDiffuseBRDF(newUniformPigment(WHITE)))
            sph = newSphere(newPoint3D(1, 2, 3), 3, mat)

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
        discard mat
        discard ray1
        discard ray2
        discard node
        discard hitPayload
        discard hitInfoNode
        discard hitInfoHandler


    test "newHitInfo (ObjectHandler) proc":
        # Checking newHitInfo procedure for ObjectHandler kind

        check hitInfoHandler.hit.kind == hkShape
        check hitInfoHandler.hit.transformation.kind == tkTranslation
        check areClose(hitInfoHandler.hit.transformation.offset, newVec3(1, 2, 3))
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
        check areClose(hitPayload.info.hit.transformation.offset, newVec3(1, 2, 3))
        check areClose(hitPayload.info.hit.aabb.min, newPoint3D(-2,-1, 0))
        check areClose(hitPayload.info.hit.aabb.max, newPoint3D( 4, 5, 6))

        check hitPayload.info.hit.shape.kind == skSphere
        check areClose(hitPayload.info.hit.shape.radius, 3)
        
        check areClose(hitPayload.info.t, 4.23)

        # Checking HitPayload.pt
        check areClose(hitPayload.pt, ray1.at(4.23))

        # Checking HitPayload.rayDir
        check areClose(hitPayload.rayDir, eX)



#---------------------------------------#
#       Tree traverse test suite        #
#---------------------------------------#
suite "Tree traverse":
    # Here we want to check how hit are actually computed
    # Thanks to BVH and time sorting, we can check it way faster than looping over shapes

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
            mat = newMaterial(newDiffuseBRDF(newUniformPigment(WHITE)))

            shsp1 = newSphere(ORIGIN3D, 2, mat)
            shsp2 = newSphere(newPoint3D(5, 0, 0), 2, mat)
            shsp3 = newUnitarySphere(newPoint3D(5, 5, 5), mat)
            box = newBox((newPoint3D(-6, -6, -6), newPoint3D(-4, -4, -4)), mat)
        
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
            mat: Material
            rg = newPCG(rs)
            rsSeq = newSeq[RandomSetUp](5)
            handlSeq = newSeq[ObjectHandler](500)


        # I'm gonna test it five times
        for i in 0..<5:

            rsSeq[i] = newRandomSetUp(rg.random, rg.random)

            for j in 0..<500:
                mat = newMaterial(newDiffuseBRDF(newUniformPigment(newColor(rg.rand, rg.rand, rg.rand))))
                handlSeq[j] = newSphere(newPoint3D(rg.rand(0, 15), rg.rand(0, 15), rg.rand(0, 15)), rg.rand(0, 10), mat)

            scene = newScene(BLACK, handlSeq, tkBinary, 2, rsSeq[i])

            # Ray --> Origin: (30, 30, 30), Dir: (1, 0, 0)
            # We should not have an hit
            hitPayload = scene.tree.getClosestHit(ray)
            check hitPayload.info.hit.isNil

            handlSeq = newSeq[ObjectHandler](500)


    test "hits (random testing)":
        # Checking getClosestHit by means of random testing, 
        # we are creating a bunch of shape and then one we are sure of hitting

        let 
            ray1 = newRay(newPoint3D(35, 0, 0), -eX)
            ray2 = newRay(newPoint3D(35, 5, 0),-eY)
            ray3 = newRay(newPoint3D(30, 30, 30), eX)

        var 
            mat: Material
            rg = newPCG(rs)
            rsSeq = newSeq[RandomSetUp](5)
            handlSeq = newSeq[ObjectHandler](500)


        # I'm gonna test it five times
        for i in 0..<5:

            rsSeq[i] = newRandomSetUp(rg.random, rg.random)

            for j in 0..<499:
                mat = newMaterial(newDiffuseBRDF(newUniformPigment(newColor(rg.rand, rg.rand, rg.rand))))
                handlSeq[j] = newSphere(newPoint3D(rg.rand(0, 15), rg.rand(0, 15), rg.rand(0, 15)), rg.rand(0, 10), mat)

            handlSeq[499] = newSphere(newPoint3D(35, 0, 0), 2, mat)

            scene = newScene(BLACK, handlSeq, tkBinary, 2, rsSeq[i])

            # First ray --> Origin: (35, 0, 0), Dir: (-1, 0, 0)
            # We should get hit in (32, 0, 0) in world reference system
            hitPayload = scene.tree.getClosestHit(ray1)

            check hitPayload.info.hit.shape.kind == skSphere
            check areClose(hitPayload.info.hit.aabb.min, newPoint3D(33,-2,-2))
            check areClose(hitPayload.info.hit.aabb.max, newPoint3D(37, 2, 2))
            check areClose(hitPayload.info.t, 2)
            check areClose(hitPayload.pt, newPoint3D(-2, 0, 0))
            check areClose(hitPayload.rayDir,-eX)

            # Second ray --> Origin: (35, 5, 0), Dir: (0,-1, 0)
            # We should get hit in (35, 2, 0) in world reference system
            hitPayload = scene.tree.getClosestHit(ray2)

            check hitPayload.info.hit.shape.kind == skSphere
            check areClose(hitPayload.info.hit.aabb.min, newPoint3D(33,-2,-2))
            check areClose(hitPayload.info.hit.aabb.max, newPoint3D(37, 2, 2))
            check areClose(hitPayload.info.t, 3)
            check areClose(hitPayload.pt, newPoint3D(0, 2, 0))
            check areClose(hitPayload.rayDir, -eY)

            # Third ray --> Origin: (30, 30, 30), Dir: (1, 0, 0)
            hitPayload = scene.tree.getClosestHit(ray3)
            check scene.tree.getClosestHit(ray3).info.hit.isNil


            handlSeq = newSeq[ObjectHandler](500)
   

    test "hits (in shape - random testing)":
        # Checking if tree traversing algorithm gives correct result
        # when we are actually being inside of a shape

        let 
            ray1 = newRay(newPoint3D( 0, 0, 0),-eX)
            ray2 = newRay(newPoint3D( 0, 1, 0),-eY)
            ray3 = newRay(newPoint3D( 0, 0,-1), eZ)

        var 
            mat: Material
            sign: float32
            rg = newPCG(rs)
            rsSeq = newSeq[RandomSetUp](5)
            handlSeq = newSeq[ObjectHandler](500)


        # I'm gonna test it five times
        for i in 0..<5:

            rsSeq[i] = newRandomSetUp(rg.random, rg.random)

            for j in 0..<499:
                mat = newMaterial(newDiffuseBRDF(newUniformPigment(newColor(rg.rand, rg.rand, rg.rand))))

                if rg.rand >= 0.5: sign = 1
                else: sign = -1

                handlSeq[j] = newSphere(newPoint3D(sign * rg.rand(8, 20), rg.rand(8, 20), rg.rand(8, 20)), rg.rand(0, 5), mat)

            handlSeq[499] = newSphere(newPoint3D(0, 0, 0), 2, mat)

            scene = newScene(BLACK, handlSeq, tkBinary, 2, rsSeq[i])

            # First ray --> Origin: (0, 0, 0), Dir: (-1, 0, 0)
            # We should get hit in (-2, 0, 0) in world reference system
            hitPayload = scene.tree.getClosestHit(ray1)

            check hitPayload.info.hit.shape.kind == skSphere
            check areClose(hitPayload.info.hit.aabb.min, newPoint3D(-2,-2,-2))
            check areClose(hitPayload.info.hit.aabb.max, newPoint3D(2, 2, 2))
            check areClose(hitPayload.info.t, 2)
            check areClose(hitPayload.pt, newPoint3D(-2, 0, 0))
            check areClose(hitPayload.rayDir,-eX)

            # Second ray --> Origin: (0, 1, 0), Dir: (0,-1, 0)
            # We should get hit in (0,-2, 0) in world reference system
            hitPayload = scene.tree.getClosestHit(ray2)

            check hitPayload.info.hit.shape.kind == skSphere
            check areClose(hitPayload.info.hit.aabb.min, newPoint3D(-2,-2,-2))
            check areClose(hitPayload.info.hit.aabb.max, newPoint3D( 2, 2, 2))
            check areClose(hitPayload.info.t, 3)
            check areClose(hitPayload.pt, newPoint3D(0,-2, 0))
            check areClose(hitPayload.rayDir, -eY)

            # Third ray --> Origin: (0, 0,-1), Dir: (0, 0, 1)
            # We should get hit in (0, 0, 2) in world reference system
            hitPayload = scene.tree.getClosestHit(ray3)

            check hitPayload.info.hit.shape.kind == skSphere
            check areClose(hitPayload.info.hit.aabb.min, newPoint3D(-2,-2,-2))
            check areClose(hitPayload.info.hit.aabb.max, newPoint3D( 2, 2, 2))
            check areClose(hitPayload.info.t, 3)
            check areClose(hitPayload.pt, newPoint3D(0, 0, 2))
            check areClose(hitPayload.rayDir, eZ)


            handlSeq = newSeq[ObjectHandler](500)


    test "CSGUnion":
        # Checking getClosestHit for a ray-csgUnion intersection.
        # Here we need to assure that time computation is indeed correct.

        let
            mat1 = newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(newColor(1, 0, 0))), newUniformPigment(newColor(1, 0, 0)))
            mat2 = newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(newColor(0, 1, 0))), newUniformPigment(newColor(0, 1, 0)))
            mat3 = newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(newColor(0, 0, 1))), newUniformPigment(newColor(0, 0, 1)))

            sh1 = newSphere(newPoint3D(1, 2, 3), 2, mat1)
            sh2 = newSphere(newPoint3D(-5, 0, 0), 2, mat2)
            sh3 = newUnitarySphere(newPoint3D(0, 0, 3), mat3)
            
            csgUnion = newCSGUnion(@[sh1, sh2, sh3], tkBinary, 1, newRandomSetUp(42, 1))
        
        var
            ray1 = newRay(newPoint3D(1, 2, 2),-eZ)
            ray2 = newRay(newPoint3D(4, 0, 0),-eX)
            ray3 = newRay(newPoint3D(0, 0, 0), eZ)
            ray4 = newRay(newPoint3D(5, 5, 5), eZ)
        
        scene = newScene(BLACK, @[csgUnion], tkBinary, 1, rs)

        # First ray --> Origin: (1, 2, 2), Dir: (0, 0,-1)
        # In world, we should get intersection in (1, 2, 1)
        hitPayload = scene.tree.getClosestHit(ray1)
        check hitPayload.info.hit.shape.kind == skSphere
        check areClose(hitPayload.info.hit.aabb.min, newPoint3D(-1, 0, 1))
        check areClose(hitPayload.info.hit.aabb.max, newPoint3D( 3, 4, 5))
        check areClose(hitPayload.info.t, 1)
        check areClose(hitPayload.pt, newPoint3D(0, 0,-2))
        check areClose(hitPayload.rayDir, -eZ)

        # Second ray --> Origin: (4, 0, 0), Dir: (-1, 0, 0)
        # In world, we should get intersection in (-3, 0, 0)
        hitPayload = scene.tree.getClosestHit(ray2)
        check hitPayload.info.hit.shape.kind == skSphere
        check areClose(hitPayload.info.hit.aabb.min, newPoint3D(-7,-2,-2))
        check areClose(hitPayload.info.hit.aabb.max, newPoint3D(-3, 2, 2))
        check areClose(hitPayload.info.t, 7)
        check areClose(hitPayload.pt, newPoint3D(2, 0, 0))
        check areClose(hitPayload.rayDir, -eX)

        # Third ray --> Origin: (0, 0, 0), Dir: ( 0, 0, 1)
        # In world, we should get intersection in (0, 0, 2)
        hitPayload = scene.tree.getClosestHit(ray3)
        check hitPayload.info.hit.shape.kind == skSphere
        check areClose(hitPayload.info.hit.aabb.min, newPoint3D(-1,-1, 2))
        check areClose(hitPayload.info.hit.aabb.max, newPoint3D( 1, 1, 4))
        check areClose(hitPayload.info.t, 2)
        check areClose(hitPayload.pt, newPoint3D(0, 0,-1))
        check areClose(hitPayload.rayDir, eZ)

        # Fourth ray --> Origin: (0, 0, 0), Dir: ( 0, 0, 1)
        # In world, we should get no intersections at all
        check scene.tree.getClosestHit(ray4).info.hit.isNil