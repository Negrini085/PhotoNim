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
        var 
            rg = newPCG()
            appo: Option[seq[SceneNode]]

        let 
            scene = newScene(@[newSphere(ORIGIN3D, 2), newUnitarySphere(newPoint3D(4, 4, 4))])
            
            ray1 = newRay(newPoint3D(-3, 0, 0), newVec3f(1, 0, 0))
            ray2 = newRay(newPoint3D(-4, 4, 4), newVec3f(1, 0, 0))
            ray3 = newRay(newPoint3D(-4, 4, 4), newVec3f(-1, 0, 0))
        
            toCheck = getBVHTree(scene, tkBinary, 1, rg)

        
        appo = toCheck.getHitLeafs(ray1);
        check appo.isSome
        check appo.get[0].handlers[0].shape.radius == 2

        appo = toCheck.getHitLeafs(ray2);
        check appo.isSome
        check appo.get[0].handlers[0].shape.radius == 1

        check not toCheck.getHitLeafs(ray3).isSome

    
    test "getHitLeafs proc (multiple hits, single ray)":
        # Checking getHitLeafs proc when you have more than one hit
        var 
            rg = newPCG()
            appo: Option[seq[SceneNode]]

        let 
            scene = newScene(@[newSphere(ORIGIN3D, 2), newSphere(newPoint3D(5, 0, 0), 2)])

            ray1 = newRay(newPoint3D(-3, 0, 0), eX)
            ray2 = newRay(newPoint3D(0, 3, 0), -eY)
            ray3 = newRay(newPoint3D(5, 0, 4), -eZ)
        
            toCheck = scene.getBVHTree(tkBinary, 1, rg)
        
        appo = toCheck.getHitLeafs(ray1)
        check appo.isSome
        check appo.get.len == 2
        check appo.get[0].handlers[0].shape.kind == skSphere and appo.get[0].handlers[0].shape.radius == 2
        check appo.get[1].handlers[0].shape.kind == skSphere and appo.get[1].handlers[0].shape.radius == 2


        appo = toCheck.getHitLeafs(ray2)
        check appo.isSome and (appo.get.len == 1)
        check appo.get[0].handlers[0].shape.kind == skSphere and appo.get[0].handlers[0].shape.radius == 2

        appo = toCheck.getHitLeafs(ray3)
        check appo.isSome and (appo.get.len == 1)
        check appo.get[0].handlers[0].shape.kind == skSphere and appo.get[0].handlers[0].shape.radius == 2


#-------------------------------------------#
#           HitPayload test suite           #
#-------------------------------------------#    
suite "HitPayload":

    setup:
        var
            rg = newPCG()
            scene: Scene
            sceneTree: SceneNode

            hitPayload: Option[HitPayload]
            hitPayloads: seq[HitPayload]
    
    teardown:
        discard rg
        discard scene
        discard sceneTree
#          discard HitPayload
        discard hitPayloads


    #----------------------------------#
    #     getHitPayload proc tests     #
    #----------------------------------#
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


    test "getHitPayload proc (Ellipsoid)":
        # Checking getHitPayload for an Ellipsoid-Ray intersection
        let 
            ell1 = newEllipsoid(1, 2, 3)
            ell2 = newEllipsoid(3, 2, 1)

        var
            ray1 = newRay(newPoint3D(0, 0, 2), newVec3(float32 0, 0, -1))
            ray2 = newRay(newPoint3D(4, 0, 0), newVec3(float32 -1, 0, 0))
            ray3 = newRay(ORIGIN3D, newVec3(float32 1, 0, 0))
            ray4 = newRay(newPoint3D(5, 5, 5), eX)

        
        # First ellipsoid
        hitPayload = getHitPayload(ell1, ray1)
        check hitPayload.isSome
        check hitPayload.get.t == 5
        check hitPayload.get.handler.shape.kind == skEllipsoid 
        check areClose(hitPayload.get.handler.shape.axis.a, 1)
        check areClose(hitPayload.get.handler.shape.axis.b, 2)
        check areClose(hitPayload.get.handler.shape.axis.c, 3)
        check areClose(hitPayload.get.ray.dir, -eZ)
        check areClose(hitPayload.get.ray.origin, newPoint3D(0, 0, 2))

        hitPayload = getHitPayload(ell1, ray2)
        check hitPayload.isSome
        check hitPayload.get.t == 3
        check hitPayload.get.handler.shape.kind == skEllipsoid 
        check areClose(hitPayload.get.handler.shape.axis.a, 1)
        check areClose(hitPayload.get.handler.shape.axis.b, 2)
        check areClose(hitPayload.get.handler.shape.axis.c, 3)
        check areClose(hitPayload.get.ray.dir, -eX)
        check areClose(hitPayload.get.ray.origin, newPoint3D(4, 0, 0))

        hitPayload = getHitPayload(ell1, ray3)
        check hitPayload.isSome
        check hitPayload.get.t == 1
        check hitPayload.get.handler.shape.kind == skEllipsoid 
        check areClose(hitPayload.get.handler.shape.axis.a, 1)
        check areClose(hitPayload.get.handler.shape.axis.b, 2)
        check areClose(hitPayload.get.handler.shape.axis.c, 3)
        check areClose(hitPayload.get.ray.dir, eX)
        check areClose(hitPayload.get.ray.origin, ORIGIN3D)
        
        hitPayload = getHitPayload(ell1, ray4)
        check hitPayload.isNone

    
        # Second elipsoid
        hitPayload = getHitPayload(ell2, ray1)
        check hitPayload.isSome
        check areClose(hitPayload.get.t, 1, eps = 1e-6)
        check hitPayload.get.handler.shape.kind == skEllipsoid 
        check areClose(hitPayload.get.handler.shape.axis.a, 3)
        check areClose(hitPayload.get.handler.shape.axis.b, 2)
        check areClose(hitPayload.get.handler.shape.axis.c, 1)
        check areClose(hitPayload.get.ray.dir, -eZ)
        check areClose(hitPayload.get.ray.origin, newPoint3D(0, 0, 2))

        hitPayload = getHitPayload(ell2, ray2)
        check hitPayload.isSome
        check areClose(hitPayload.get.t, 1, eps = 1e-6)
        check hitPayload.get.handler.shape.kind == skEllipsoid 
        check areClose(hitPayload.get.handler.shape.axis.a, 3)
        check areClose(hitPayload.get.handler.shape.axis.b, 2)
        check areClose(hitPayload.get.handler.shape.axis.c, 1)
        check areClose(hitPayload.get.ray.origin, newPoint3D(4, 0, 0))

        hitPayload = getHitPayload(ell2, ray3)
        check hitPayload.isSome
        check areClose(hitPayload.get.t, 3, eps = 1e-6)
        check hitPayload.get.handler.shape.kind == skEllipsoid 
        check areClose(hitPayload.get.handler.shape.axis.a, 3)
        check areClose(hitPayload.get.handler.shape.axis.b, 2)
        check areClose(hitPayload.get.handler.shape.axis.c, 1)
        check areClose(hitPayload.get.ray.dir, eX)
        check areClose(hitPayload.get.ray.origin, ORIGIN3D)

        hitPayload = getHitPayload(ell2, ray4)
        check hitPayload.isNone


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

            ray1 = newRay(newPoint3D(0, 1, -2), eZ)
            ray2 = newRay(newPoint3D(0, 1, -2), eX)

        hitPayload = getHitPayload(triangle, ray1)
        check hitPayload.isSome
        check hitPayload.get.t == 2
        check hitPayload.get.handler.shape.kind == skTriangle
        check areClose(hitPayload.get.ray.dir, eZ)
        check areClose(hitPayload.get.ray.origin, newPoint3D(0, 1, -2))

        check not getHitPayload(triangle, ray2).isSome


    test "getHitPayload (Cylinder)":
        # Checking getHitPayload on cylinder shape
        var
            cylinder = newCylinder(2, -2, 2)

            ray1 = newRay(ORIGIN3D, eX)
            ray2 = newRay(newPoint3D(4, 0, 0), -eX)
            ray3 = newRay(newPoint3D(0, 0, -4), eZ)
            ray4 = newRay(newPoint3D(2, 3, 1), eY)

        hitPayload = getHitPayload(cylinder, ray1)
        check hitPayload.isSome
        check hitPayload.get.t == 2
        check hitPayload.get.handler.shape.kind == skCylinder
        check areClose(hitPayload.get.ray.dir, eX)
        check areClose(hitPayload.get.ray.origin, ORIGIN3D)

        hitPayload = getHitPayload(cylinder, ray2)
        check hitPayload.isSome
        check hitPayload.get.t == 2
        check hitPayload.get.handler.shape.kind == skCylinder
        check areClose(hitPayload.get.ray.dir, -eX)
        check areClose(hitPayload.get.ray.origin, newPoint3D(4, 0, 0))
        
        check not getHitPayload(cylinder, ray3).isSome
        check not getHitPayload(cylinder, ray4).isSome


    #----------------------------------#
    #     getHitPayloads proc test     #
    #----------------------------------#
    test "getHitPayloads":
        # Checking getHitPayloads
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
        sceneTree = scene.getBVHTree(tkBinary, 1, rg)


        #--------------------------#
        #         First ray        #
        #--------------------------#
        check getHitLeafs(sceneTree, ray1).isSome
        check getHitLeafs(sceneTree, ray1).get.len == 2

        hitPayloads = getHitPayloads(getHitLeafs(sceneTree, ray1).get[0], ray1)
        check hitPayloads.len == 1; appo = hitPayloads[0]
        check appo.t == 1
        check (appo.handler.shape.kind == skSphere) and (appo.handler.shape.radius == 2)
        check areClose(appo.ray.origin, newPoint3D(-3, 0, 0))
        check areClose(appo.ray.dir, eX)

        hitPayloads = getHitPayloads(getHitLeafs(sceneTree, ray1).get[1], ray1)
        check hitPayloads.len == 1; appo = hitPayloads[0]
        check appo.t == 6
        check (appo.handler.shape.kind == skSphere) and (appo.handler.shape.radius == 2)
        check areClose(appo.ray.origin, newPoint3D(-8, 0, 0))       # That's why we are giving ray in shape frame of reference
        check areClose(appo.ray.dir, eX)

        #--------------------------#
        #        Second ray        #
        #--------------------------#
        check getHitLeafs(sceneTree, ray2).isSome
        check getHitLeafs(sceneTree, ray2).get.len == 1

        hitPayloads = getHitPayloads(getHitLeafs(sceneTree, ray2).get[0], ray2)
        check hitPayloads.len == 1; appo = hitPayloads[0]
        check (appo.handler.shape.kind == skSphere) and (appo.handler.shape.radius == 1)
        check areClose(appo.ray.origin, newPoint3D(-5, 0, -0.5))
        check areClose(appo.ray.dir, eX)

        #-------------------------#
        #        Third ray        #
        #-------------------------#
        check getHitLeafs(sceneTree, ray3).isSome
        check getHitLeafs(sceneTree, ray3).get.len == 1

        hitPayloads = getHitPayloads(getHitLeafs(sceneTree, ray3).get[0], ray3)
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
        check getHitLeafs(sceneTree, ray4).isSome
        check getHitLeafs(sceneTree, ray4).get.len == 1

        hitPayloads = getHitPayloads(getHitLeafs(sceneTree, ray4).get[0], ray4)
        check hitPayloads.len == 1; appo = hitPayloads[0]
        check appo.t == 2
        check (appo.handler.shape.kind == skSphere) and (appo.handler.shape.radius == 2) 
        check areClose(appo.ray.origin, ORIGIN3D)     # We are exactly in shape frame of reference
        check areClose(appo.ray.dir, -eX)

        #------------------------#
        #        Fifth ray       #
        #------------------------#
        check getHitLeafs(sceneTree, ray5).isSome
        check getHitLeafs(sceneTree, ray5).get.len == 2
        check getHitPayloads(getHitLeafs(sceneTree, ray5).get[0], ray5).len == 0
        check getHitPayloads(getHitLeafs(sceneTree, ray5).get[1], ray5).len == 0


    test "getHitRecord proc":
        # Checking getHitRecord proc
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
        sceneTree = scene.getBVHTree(tkBinary, 1, rg)


        #--------------------------#
        #         First ray        #
        #--------------------------#
        check getHitLeafs(sceneTree, ray1).isSome
        check getHitLeafs(sceneTree, ray1).get.len == 2

        check getHitRecord(getHitLeafs(sceneTree, ray1).get, ray1).isSome
        hitRecord = getHitRecord(getHitLeafs(sceneTree, ray1).get, ray1).get
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
        check getHitLeafs(sceneTree, ray2).isSome
        check getHitLeafs(sceneTree, ray2).get.len == 1

        check getHitRecord(getHitLeafs(sceneTree, ray2).get, ray2).isSome
        hitRecord = getHitRecord(getHitLeafs(sceneTree, ray2).get, ray2).get
        check hitRecord.len == 1

        check (hitRecord[0].handler.shape.kind == skAABox) and hitRecord[0].t == 2
        check areClose(hitRecord[0].handler.shape.aabb.min, newPoint3D(-6, -6, -6))
        check areClose(hitRecord[0].handler.shape.aabb.max, newPoint3D(-4, -4, -4))
        check areClose(hitRecord[0].ray.origin, newPoint3D(-5, -5, -8))     # Box has not a specific reference system
        check areClose(hitRecord[0].ray.dir, eZ)

        #-------------------------#
        #        Third ray        #
        #-------------------------#
        check getHitLeafs(sceneTree, ray3).isSome
        check getHitLeafs(sceneTree, ray3).get.len == 2
        check not getHitRecord(getHitLeafs(sceneTree, ray3).get, ray3).isSome
