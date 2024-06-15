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



#-------------------------------------------#
#           HitPayload test suite           #
#-------------------------------------------#    
suite "HitPayload":

    setup:
        let
            stdRS = newReferenceSystem(ORIGIN3D, [eX, eY, eZ])
            speRS = newReferenceSystem(ORIGIN3D, [eX, eZ, -eY])

        var
            scene: Scene
            sceneTree: SceneNode

            hitPayload: Option[HitPayload]
    
    teardown:
        discard hitPayload
        discard sceneTree
        discard stdRS
        discard speRS
        discard scene


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
        check hitPayload.get.t == 2                   # It's none, found another bug
        check hitPayload.get.handler.shape.kind == skCylinder
        check areClose(hitPayload.get.ray.dir, eZ)
        check areClose(hitPayload.get.ray.origin, newPoint3D(0, 0, -4))

        check not getHitPayload(shCylinder, ray4).isSome