import std/[unittest, options]
import PhotoNim


#---------------------------------#
#       HitLeafs test suite       #
#---------------------------------#
suite "HitLeafs":

    setup:
        let
            aabb1 = (newPoint3D(-1, -1, -1), newPoint3D(1, 1, 1))
            aabb2 = (newPoint3D(-1, 0, 1), newPoint3D(1, 2, 3))

    teardown:
        discard aabb1
        discard aabb2


    test "checkIntersection proc":
        # Checking checkIntersection proc, states wether an aabb hit occurred or not
        var
            ray1 = newRay(newPoint3D(-2, 0, 0), eX)
            ray2 = newRay(newPoint3D(0, 0.5, 2), -eZ)
            ray3 = newRay(newPoint3D(-2, -2, -2), -eX)
            ray4 = newRay(newPoint3D(0, 0, 0), -eX)
            ray5 = newRay(newPoint3D(-2, 0, 0), -eX)

        # First aabb
        check aabb1.checkIntersection(ray1)
        check aabb1.checkIntersection(ray2)
        check not aabb1.checkIntersection(ray3)
        check aabb1.checkIntersection(ray4)
        check not aabb1.checkIntersection(ray5)


        # Second aabb
        check not aabb2.checkIntersection(ray1)
        check aabb2.checkIntersection(ray2)
        check not aabb2.checkIntersection(ray3)
        check not aabb2.checkIntersection(ray4)
        check not aabb2.checkIntersection(ray5)
  

    test "getHitLeafs proc":
        # Checking getHitLeafs proc
        let scene = newScene(@[newSphere(ORIGIN3D, 2), newUnitarySphere(newPoint3D(4, 4, 4))])
            
        var
            ray1 = newRay(newPoint3D(-3, 0, 0), newVec3f(1, 0, 0))
            ray2 = newRay(newPoint3D(-4, 4, 4), newVec3f(1, 0, 0))
            ray3 = newRay(newPoint3D(-4, 4, 4), newVec3f(-1, 0, 0))
        
            rs = newReferenceSystem(ORIGIN3D, [eX, eY, eZ])
            toCheck = rs.getSceneTree(scene, 1)
            appo: Option[seq[SceneNode]]
        
        #------------------------------------------------------------#
        #       Checking getHitLeafs in world reference system       #
        #------------------------------------------------------------#
        appo = rs.getHitLeafs(toCheck, ray1); check appo.isSome
        check appo.get[0].handlers[0].shape.radius == 2

        appo = rs.getHitLeafs(toCheck, ray2); check appo.isSome
        check appo.get[0].handlers[0].shape.radius == 1

        check not rs.getHitLeafs(toCheck, ray3).isSome

        
        #-------------------------------------------------------------#
        #       Checking getHitLeafs in specific reference system     #
        #-------------------------------------------------------------#
        rs = newReferenceSystem(newPoint3D(1, 0, 0), [eX, eZ, -eY])
        toCheck = rs.getSceneTree(scene, 1)

        appo = rs.getHitLeafs(toCheck, ray1); check appo.isSome
        check appo.get[0].handlers[0].shape.radius == 2

        check not rs.getHitLeafs(toCheck, ray2).isSome
        check not rs.getHitLeafs(toCheck, ray3).isSome
        
        # Changing ray origin
        ray2.origin = newPoint3D(-4, 4, -4);
        ray3.origin = newPoint3D(6, 4, -4)

        appo = rs.getHitLeafs(toCheck, ray2); check appo.isSome
        check appo.get[0].handlers[0].shape.radius == 1

        appo = rs.getHitLeafs(toCheck, ray3); check appo.isSome
        check appo.get[0].handlers[0].shape.radius == 1

    
    test "getHitLeafs proc (multiple hits, single ray)":
        # Checking getHitLeafs proc when you have more than one hit

        let scene = newScene(@[newSphere(ORIGIN3D, 2), newSphere(newPoint3D(5, 0, 0), 2)])

        var
            ray1 = newRay(newPoint3D(-3, 0, 0), eX)
            ray2 = newRay(newPoint3D(0, 3, 0), -eY)
            ray3 = newRay(newPoint3D(5, 0, 4), -eZ)
        
            rs = newReferenceSystem(ORIGIN3D, [eX, eY, eZ])
            toCheck = rs.getSceneTree(scene, 1)
            appo: Option[seq[SceneNode]]
        
        appo = rs.getHitLeafs(toCheck, ray1)
        check appo.isSome
        check appo.get.len == 2
        check appo.get[0].handlers[0].shape.kind == skSphere and appo.get[0].handlers[0].shape.radius == 2
        check appo.get[1].handlers[0].shape.kind == skSphere and appo.get[1].handlers[0].shape.radius == 2


        appo = rs.getHitLeafs(toCheck, ray2)
        check appo.isSome and (appo.get.len == 1)
        check appo.get[0].handlers[0].shape.kind == skSphere and appo.get[0].handlers[0].shape.radius == 2

        appo = rs.getHitLeafs(toCheck, ray3)
        check appo.isSome and (appo.get.len == 1)
        check appo.get[0].handlers[0].shape.kind == skSphere and appo.get[0].handlers[0].shape.radius == 2


#-------------------------------------------#
#           HitPayload test suite           #
#-------------------------------------------#    
suite "HitPayload":

    setup:
        let
            stdRS = newReferenceSystem(ORIGIN3D, [eX, eY, eZ])
            speRS = newReferenceSystem(newPoint3D(1, 2, 3), [eX, eZ, -eY])

        var
            scene: Scene
            sceneTree: SceneNode

            hitPayload: Option[HitPayload]
            hitPayloads: seq[HitPayload]
    
    teardown:
        discard hitPayloads
        discard hitPayload
        discard sceneTree
        discard stdRS
        discard speRS
        discard scene


    #----------------------------------#
    #     getHitPayload proc tests     #
    #----------------------------------#
    echo ""
    echo "     Testing getHitPayload procedure: "

    test "getHitPayload proc (Sphere)":
        # Checking getHitPayload for a Sphere-Ray intersection
        let 
            usphere = newUnitarySphere(ORIGIN3D)
            sphere = newSphere(newPoint3D(0, 1, 0), 3.0)

        var
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3(float32 0, 0, -1))
            ray2 = newRay(newPoint3D(3, 0, 0), newVec3(float32 -1, 0, 0))
            ray3 = newRay(ORIGIN3D, newVec3(float32 1, 0, 0))

        
        #------------------------------------#
        #           Unitary sphere           #
        #------------------------------------#
        hitPayload = getHitPayload(usphere, ray1)
        check hitPayload.isSome
        check hitPayload.get.t == 1
        check hitPayload.get.handler.shape.kind == skSphere and hitPayload.get.handler.shape.radius == 1
        check areClose(hitPayload.get.ray.dir, -eZ)
        check areClose(hitPayload.get.ray.origin, newPoint3D(0, 0, 2))

        hitPayload = getHitPayload(usphere, ray2)
        check hitPayload.isSome
        check hitPayload.get.t == 2
        check hitPayload.get.handler.shape.kind == skSphere and hitPayload.get.handler.shape.radius == 1
        check areClose(hitPayload.get.ray.dir, -eX)
        check areClose(hitPayload.get.ray.origin, newPoint3D(3, 0, 0))

        hitPayload = getHitPayload(usphere, ray3)
        check hitPayload.isSome
        check hitPayload.get.t == 1
        check hitPayload.get.handler.shape.kind == skSphere and hitPayload.get.handler.shape.radius == 1
        check areClose(hitPayload.get.ray.dir, eX)
        check areClose(hitPayload.get.ray.origin, ORIGIN3D)
    

        #-------------------------------------#
        #           Generic sphere            #
        #-------------------------------------#
        ray1.origin = newPoint3D(0, 0, 5)
        ray2.origin = newPoint3D(4, 0, 0)

        hitPayload = getHitPayload(sphere, ray1)
        check hitPayload.isSome
        check hitPayload.get.t == 2
        check hitPayload.get.handler.shape.kind == skSphere and hitPayload.get.handler.shape.radius == 3
        check areClose(hitPayload.get.ray.dir, -eZ)
        check areClose(hitPayload.get.ray.origin, newPoint3D(0, 0, 5))

        hitPayload = getHitPayload(sphere, ray2)
        check hitPayload.isSome
        check hitPayload.get.t == 1
        check hitPayload.get.handler.shape.kind == skSphere and hitPayload.get.handler.shape.radius == 3
        check areClose(hitPayload.get.ray.dir, -eX)
        check areClose(hitPayload.get.ray.origin, newPoint3D(4, 0, 0))

        hitPayload = getHitPayload(sphere, ray3)
        check hitPayload.isSome
        check hitPayload.get.t == 3
        check hitPayload.get.handler.shape.kind == skSphere and hitPayload.get.handler.shape.radius == 3
        check areClose(hitPayload.get.ray.dir, eX)
        check areClose(hitPayload.get.ray.origin, ORIGIN3D)


    test "getHitPayload proc (Plane)":
        # Checking getHitPayloads on Planes
        var
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3f(0, 0, -1))
            ray2 = newRay(newPoint3D(1, -2, -3), newVec3f(0, 4/5, 3/5))
            ray3 = newRay(newPoint3D(3, 0, 0), newVec3f(-1, 0, 0))

            plane = newPlane()
        
        hitPayload = getHitPayload(plane, ray1)
        check hitPayload.isSome
        check hitPayload.get.t == 2
        check hitPayload.get.handler.shape.kind == skPlane
        check areClose(hitPayload.get.ray.dir, -eZ)
        check areClose(hitPayload.get.ray.origin, newPoint3D(0, 0, 2))

        hitPayload = getHitPayload(plane, ray2)
        check hitPayload.isSome
        check hitPayload.get.t == 5
        check hitPayload.get.handler.shape.kind == skPlane
        check areClose(hitPayload.get.ray.dir, newVec3f(0, 4/5, 3/5))
        check areClose(hitPayload.get.ray.origin, newPoint3D(1, -2, -3))

        check not getHitPayload(plane, ray3).isSome


    test "getHitPayload proc (AABox)":
        # Checking getHitPayloads on Planes
        var
            ray1 = newRay(newPoint3D(-5, 1, 2), eX)
            ray2 = newRay(newPoint3D(1, -2, 3), eY)
            ray3 = newRay(newPoint3D(4, 1, 0), newVec3f(-1, 0, 0))

            box = newBox((newPoint3D(-1, 0, 1), newPoint3D(3, 2, 5)))
          
        hitPayload = getHitPayload(box, ray1)
        check hitPayload.isSome
        check hitPayload.get.t == 4
        check hitPayload.get.handler.shape.kind == skAABox
        check areClose(hitPayload.get.ray.dir, eX)
        check areClose(hitPayload.get.ray.origin, newPoint3D(-5, 1, 2))

        hitPayload = getHitPayload(box, ray2)
        check hitPayload.isSome
        check hitPayload.get.t == 2
        check hitPayload.get.handler.shape.kind == skAABox
        check areClose(hitPayload.get.ray.dir, eY)
        check areClose(hitPayload.get.ray.origin, newPoint3D(1, -2, 3))

        check not getHitPayload(box, ray3).isSome


    test "getHitPayload (Triangle)":
        # Checking getHitPayload on triangle shape
        var
            triangle = newTriangle(newPoint3D(3, 0, 0), newPoint3D(-2, 0, 0), newPoint3D(0.5, 2, 0))
            shTriangle = newShapeHandler(triangle)

            ray1 = newRay(newPoint3D(0, 1, -2), eZ)
            ray2 = newRay(newPoint3D(0, 1, -2), eX)

        hitPayload = getHitPayload(shTriangle, ray1)
        check hitPayload.isSome
        check hitPayload.get.t == 2
        check hitPayload.get.handler.shape.kind == skTriangle
        check areClose(hitPayload.get.ray.dir, eZ)
        check areClose(hitPayload.get.ray.origin, newPoint3D(0, 1, -2))

        check not getHitPayload(shTriangle, ray2).isSome


    test "getHitPayload (Cylinder)":
        # Checking getHitPayload on cylinder shape
        var
            cylinder = newCylinder(2, -2, 2)
            shCylinder = newShapeHandler(cylinder)

            ray1 = newRay(ORIGIN3D, eX)
            ray2 = newRay(newPoint3D(4, 0, 0), -eX)
            ray3 = newRay(newPoint3D(0, 0, -4), eZ)
            ray4 = newRay(newPoint3D(2, 3, 1), eY)

        hitPayload = getHitPayload(shCylinder, ray1)
        check hitPayload.isSome
        check hitPayload.get.t == 2
        check hitPayload.get.handler.shape.kind == skCylinder
        check areClose(hitPayload.get.ray.dir, eX)
        check areClose(hitPayload.get.ray.origin, ORIGIN3D)

        hitPayload = getHitPayload(shCylinder, ray2)
        check hitPayload.isSome
        check hitPayload.get.t == 2
        check hitPayload.get.handler.shape.kind == skCylinder
        check areClose(hitPayload.get.ray.dir, -eX)
        check areClose(hitPayload.get.ray.origin, newPoint3D(4, 0, 0))
        
        hitPayload = getHitPayload(shCylinder, ray3)
        check hitPayload.isSome
        # check hitPayload.get.t == 2                   # It's nan, found another bug
        check hitPayload.get.handler.shape.kind == skCylinder
        check areClose(hitPayload.get.ray.dir, eZ)
        check areClose(hitPayload.get.ray.origin, newPoint3D(0, 0, -4))

        check not getHitPayload(shCylinder, ray4).isSome


    #-----------------------------------#
    #     getHitPayloads proc tests     #
    #-----------------------------------#
    echo ""
    echo "     Testing getHitPayloads procedure:"
    
    test "getHitPayloads (Standard Reference System)":
        # Checking getHitPayloads in standard reference system
        let
            shsp1 = newSphere(ORIGIN3D, 2)
            shsp2 = newSphere(newPoint3D(5, 0, 0), 2)
            shsp3 = newUnitarySphere(newPoint3D(5, 5, 5))
            box = newBox((newPoint3D(-6, -6, -6), newPoint3D(-4, -4, -4)))
        
            ray1 = newRay(newPoint3D(-3, 0, 0), eX)
            ray2 = newRay(newPoint3D(0, 5, 4.5), eX)
            ray3 = newRay(newPoint3D(-5, -5, -8), eZ)
            ray4 = newRay(ORIGIN3D, -eX)
            ray5 = newRay(newPoint3D(-3, 1.9, 1.9), eX)

        var appo: HitPayload

        # Creating scene and sceneTree
        scene = newScene(@[shsp1, shsp2, shsp3, box])
        sceneTree = stdRS.getSceneTree(scene, 1)


        #--------------------------#
        #         First ray        #
        #--------------------------#
        check stdRS.getHitLeafs(sceneTree, ray1).isSome
        check stdRS.getHitLeafs(sceneTree, ray1).get.len == 2

        hitPayloads = stdRS.getHitPayloads(stdRS.getHitLeafs(sceneTree, ray1).get[0], ray1)
        check hitPayloads.len == 1; appo = hitPayloads[0]
        check appo.t == 1
        check (appo.handler.shape.kind == skSphere) and (appo.handler.shape.radius == 2)
        check areClose(appo.ray.origin, newPoint3D(-3, 0, 0))
        check areClose(appo.ray.dir, eX)

        hitPayloads = stdRS.getHitPayloads(stdRS.getHitLeafs(sceneTree, ray1).get[1], ray1)
        check hitPayloads.len == 1; appo = hitPayloads[0]
        check appo.t == 6
        check (appo.handler.shape.kind == skSphere) and (appo.handler.shape.radius == 2)
        check areClose(appo.ray.origin, newPoint3D(-8, 0, 0))       # That's why we are giving ray in shape frame of reference
        check areClose(appo.ray.dir, eX)

        #--------------------------#
        #        Second ray        #
        #--------------------------#
        check stdRS.getHitLeafs(sceneTree, ray2).isSome
        check stdRS.getHitLeafs(sceneTree, ray2).get.len == 1

        hitPayloads = stdRS.getHitPayloads(stdRS.getHitLeafs(sceneTree, ray2).get[0], ray2)
        check hitPayloads.len == 1; appo = hitPayloads[0]
        check (appo.handler.shape.kind == skSphere) and (appo.handler.shape.radius == 1)
        check areClose(appo.ray.origin, newPoint3D(-5, 0, -0.5))
        check areClose(appo.ray.dir, eX)

        #-------------------------#
        #        Third ray        #
        #-------------------------#
        check stdRS.getHitLeafs(sceneTree, ray3).isSome
        check stdRS.getHitLeafs(sceneTree, ray3).get.len == 1

        hitPayloads = stdRS.getHitPayloads(stdRS.getHitLeafs(sceneTree, ray3).get[0], ray3)
        check hitPayloads.len == 1; appo = hitPayloads[0]
        check appo.t == 2
        check (appo.handler.shape.kind == skAABox)
        check areClose(appo.handler.shape.aabb.min, newPoint3D(-6, -6, -6))
        check areClose(appo.handler.shape.aabb.max, newPoint3D(-4, -4, -4))
        check areClose(appo.ray.origin, newPoint3D(-5, -5, -8))     # Box has not a specific reference system
        check areClose(appo.ray.dir, eZ)

        #--------------------------#
        #        Fourth ray        #
        #--------------------------#
        check stdRS.getHitLeafs(sceneTree, ray4).isSome
        check stdRS.getHitLeafs(sceneTree, ray4).get.len == 1

        hitPayloads = stdRS.getHitPayloads(stdRS.getHitLeafs(sceneTree, ray4).get[0], ray4)
        check hitPayloads.len == 1; appo = hitPayloads[0]
        check appo.t == 2
        check (appo.handler.shape.kind == skSphere) and (appo.handler.shape.radius == 2) 
        check areClose(appo.ray.origin, ORIGIN3D)     # We are exactly in shape frame of reference
        check areClose(appo.ray.dir, -eX)

        #------------------------#
        #        Fifth ray       #
        #------------------------#
        check stdRS.getHitLeafs(sceneTree, ray5).isSome
        check stdRS.getHitLeafs(sceneTree, ray5).get.len == 2
        check stdRS.getHitPayloads(stdRS.getHitLeafs(sceneTree, ray5).get[0], ray5).len == 0
        check stdRS.getHitPayloads(stdRS.getHitLeafs(sceneTree, ray5).get[1], ray5).len == 0


    test "getHitPayloads (Specific Reference System)":
        # Checking getHitPayloads in specific reference system
        let
            shsp1 = newSphere(ORIGIN3D, 2)
            shsp2 = newSphere(newPoint3D(5, 0, 0), 2)
            shsp3 = newUnitarySphere(newPoint3D(5, 5, 5))
            box = newBox((newPoint3D(-6, -6, -6), newPoint3D(-4, -4, -4)))
        
            # Be careful here, point and vectors must be in local reference system frame
            ray1 = newRay(newPoint3D(-4, -3, 2), newVec3f(1, 0, 0))
            ray2 = newRay(newPoint3D(-1, 1.5, -3), newVec3f(1, 0 ,0))
            ray3 = newRay(newPoint3D(-6, -11, 7), newVec3f(0, 1, 0))
            ray4 = newRay(newPoint3D(-1, -3, 2), newVec3f(-1, 0, 0))
            ray5 = newRay(newPoint3D(-4, -1.1, 0.1), newVec3f(1, 0, 0))
            ray6 = newRay(newPoint3D(-1, -3, 2), newVec3f(0, 0, -1))

        var appo: HitPayload

        # Creating scene and sceneTree in Specific Reference System
        # Remember: ray are given in shape local rfame of reference
        scene = newScene(@[shsp1, shsp2, shsp3, box])
        sceneTree = speRS.getSceneTree(scene, 1)


        #--------------------------#
        #         First ray        #
        #--------------------------#
        check speRS.getHitLeafs(sceneTree, ray1).isSome
        check speRS.getHitLeafs(sceneTree, ray1).get.len == 2
        hitPayloads = speRS.getHitPayloads(speRS.getHitLeafs(sceneTree, ray1).get[0], ray1)
        check hitPayloads.len == 1; appo = hitPayloads[0]
        check appo.t == 1
        check (appo.handler.shape.kind == skSphere) and (appo.handler.shape.radius == 2)
        check areClose(appo.ray.origin, newPoint3D(-3, 0, 0))
        check areClose(appo.ray.dir, eX)

        hitPayloads = speRS.getHitPayloads(speRS.getHitLeafs(sceneTree, ray1).get[1], ray1)
        check hitPayloads.len == 1; appo = hitPayloads[0]
        check appo.t == 6
        check (appo.handler.shape.kind == skSphere) and (appo.handler.shape.radius == 2)
        check areClose(appo.ray.origin, newPoint3D(-8, 0, 0))       # That's why we are giving ray in shape frame of reference
        check areClose(appo.ray.dir, eX)

        #--------------------------#
        #        Second ray        #
        #--------------------------#
        check speRS.getHitLeafs(sceneTree, ray2).isSome
        check speRS.getHitLeafs(sceneTree, ray2).get.len == 1

        hitPayloads = speRS.getHitPayloads(speRS.getHitLeafs(sceneTree, ray2).get[0], ray2)
        check hitPayloads.len == 1; appo = hitPayloads[0]
        check (appo.handler.shape.kind == skSphere) and (appo.handler.shape.radius == 1)
        check areClose(appo.ray.origin, newPoint3D(-5, 0, -0.5))
        check areClose(appo.ray.dir, eX)

        #-------------------------#
        #        Third ray        #
        #-------------------------#
        check speRS.getHitLeafs(sceneTree, ray3).isSome
        check speRS.getHitLeafs(sceneTree, ray3).get.len == 1

        hitPayloads = speRS.getHitPayloads(speRS.getHitLeafs(sceneTree, ray3).get[0], ray3)
        check hitPayloads.len == 1; appo = hitPayloads[0]
        check appo.t == 2
        check (appo.handler.shape.kind == skAABox)
        check areClose(appo.handler.shape.aabb.min, newPoint3D(-6, -6, -6))
        check areClose(appo.handler.shape.aabb.max, newPoint3D(-4, -4, -4))
        check areClose(appo.ray.origin, newPoint3D(-5, -5, -8))     # Box has not a specific reference system
        check areClose(appo.ray.dir, eZ)

        #--------------------------#
        #        Fourth ray        #
        #--------------------------#
        check speRS.getHitLeafs(sceneTree, ray4).isSome
        check speRS.getHitLeafs(sceneTree, ray4).get.len == 1

        hitPayloads = speRS.getHitPayloads(speRS.getHitLeafs(sceneTree, ray4).get[0], ray4)
        check hitPayloads.len == 1; appo = hitPayloads[0]
        check appo.t == 2
        check (appo.handler.shape.kind == skSphere) and (appo.handler.shape.radius == 2) 
        check areClose(appo.ray.origin, ORIGIN3D)     # We are exactly in shape frame of reference
        check areClose(appo.ray.dir, -eX)

        #------------------------#
        #        Fifth ray       #
        #------------------------#
        check speRS.getHitLeafs(sceneTree, ray5).isSome
        check speRS.getHitLeafs(sceneTree, ray5).get.len == 2
        check speRS.getHitPayloads(speRS.getHitLeafs(sceneTree, ray5).get[0], ray5).len == 0
        check speRS.getHitPayloads(speRS.getHitLeafs(sceneTree, ray5).get[1], ray5).len == 0

        #-------------------------#
        #        Sixth ray        #
        #-------------------------#
        check speRS.getHitLeafs(sceneTree, ray6).isSome
        check speRS.getHitLeafs(sceneTree, ray6).get.len == 1

        hitPayloads = speRS.getHitPayloads(speRS.getHitLeafs(sceneTree, ray6).get[0], ray6)
        check hitPayloads.len == 1; appo = hitPayloads[0]
        check appo.t == 2
        check (appo.handler.shape.kind == skSphere) and (appo.handler.shape.radius == 2) 
        check areClose(appo.ray.origin, ORIGIN3D)     # We are exactly in shape frame of reference
        check areClose(appo.ray.dir, eY)


    #-----------------------------------#
    #      getHitRecord proc tests      #
    #-----------------------------------#
    echo ""
    echo "     Testing getHitRecord procedure:"

    test "getHitRecord (Standard Reference System)":
        # Checking getHitRecord proc in standard reference system
        let
            shsp1 = newSphere(ORIGIN3D, 2)
            shsp2 = newSphere(newPoint3D(5, 0, 0), 2)
            shsp3 = newUnitarySphere(newPoint3D(5, 5, 5))
            box = newBox((newPoint3D(-6, -6, -6), newPoint3D(-4, -4, -4)))
        
            ray1 = newRay(newPoint3D(-3, 0, 0), eX)
            ray2 = newRay(newPoint3D(-5, -5, -8), eZ)
            ray3 = newRay(newPoint3D(-3, 1.9, 1.9), eX)

        var hitRecord: seq[HitPayload]

        # Creating scene and sceneTree
        scene = newScene(@[shsp1, shsp2, shsp3, box])
        sceneTree = stdRS.getSceneTree(scene, 1)


        #--------------------------#
        #         First ray        #
        #--------------------------#
        check stdRS.getHitLeafs(sceneTree, ray1).isSome
        check stdRS.getHitLeafs(sceneTree, ray1).get.len == 2

        check stdRS.getHitRecord(ray1, stdRS.getHitLeafs(sceneTree, ray1).get).isSome
        hitRecord = stdRS.getHitRecord(ray1, stdRS.getHitLeafs(sceneTree, ray1).get).get
        check hitRecord.len == 2 and hitRecord[0].t <= hitRecord[1].t

        check (hitRecord[0].handler.shape.kind == skSphere) and (hitRecord[0].handler.shape.radius == 2)
        check hitRecord[0].t == 1
        check areClose(hitRecord[0].ray.origin, newPoint3D(-3, 0, 0))
        check areClose(hitRecord[0].ray.dir, eX)

        check (hitRecord[1].handler.shape.kind == skSphere) and (hitRecord[1].handler.shape.radius == 2)
        check hitRecord[1].t == 6
        check areClose(hitRecord[1].ray.origin, newPoint3D(-8, 0, 0))
        check areClose(hitRecord[1].ray.dir, eX)

        #--------------------------#
        #        Second ray        #
        #--------------------------#
        check stdRS.getHitLeafs(sceneTree, ray2).isSome
        check stdRS.getHitLeafs(sceneTree, ray2).get.len == 1

        check stdRS.getHitRecord(ray2, stdRS.getHitLeafs(sceneTree, ray2).get).isSome
        hitRecord = stdRS.getHitRecord(ray2, stdRS.getHitLeafs(sceneTree, ray2).get).get
        check hitRecord.len == 1

        check (hitRecord[0].handler.shape.kind == skAABox) and hitRecord[0].t == 2
        check areClose(hitRecord[0].handler.shape.aabb.min, newPoint3D(-6, -6, -6))
        check areClose(hitRecord[0].handler.shape.aabb.max, newPoint3D(-4, -4, -4))
        check areClose(hitRecord[0].ray.origin, newPoint3D(-5, -5, -8))     # Box has not a specific reference system
        check areClose(hitRecord[0].ray.dir, eZ)

        #-------------------------#
        #        Third ray        #
        #-------------------------#
        check stdRS.getHitLeafs(sceneTree, ray3).isSome
        check stdRS.getHitLeafs(sceneTree, ray3).get.len == 2
        check not stdRS.getHitRecord(ray3, stdRS.getHitLeafs(sceneTree, ray3).get).isSome
