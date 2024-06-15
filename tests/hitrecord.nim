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
        check aabb1.checkIntersection(ray5)         # Why is this passing?? That should not happen, negative times


        # Second aabb
        check not aabb2.checkIntersection(ray1)
        check aabb2.checkIntersection(ray2)
        check not aabb2.checkIntersection(ray3)
        check not aabb2.checkIntersection(ray4)
        check not aabb2.checkIntersection(ray5)
  

#    test "getHitLeafs proc":
#        # Checking getHitLeafs proc
#        let scene = newScene(@[newSphere(ORIGIN3D, 2), newUnitarySphere(newPoint3D(4, 4, 4))])
#            
#        var
#            ray1 = newRay(newPoint3D(-3, 0, 0), newVec3f(1, 0, 0))
#            ray2 = newRay(newPoint3D(-4, 4, 4), newVec3f(1, 0, 0))
#            ray3 = newRay(newPoint3D(-4, 4, 4), newVec3f(-1, 0, 0))
#        
#            rs = newReferenceSystem(ORIGIN3D, [eX, eY, eZ])
#            toCheck = scene.fromObserver(rs, 1)
#            appo: Option[seq[SceneNode]]
#        
#        #------------------------------------------------------------#
#        #       Checking getHitLeafs in world reference system       #
#        #------------------------------------------------------------#
#        appo = toCheck.getHitLeafs(ray1)
#        check appo.isSome
#        check appo.get[0].handlers[0].shape.radius == 2
#
#        appo = toCheck.getHitLeafs(ray2)
#        check appo.isSome
#        check appo.get[0].handlers[0].shape.radius == 1
#
#        appo = toCheck.getHitLeafs(ray3)
#        check appo.isSome      # Why is true (Only if time is negative brodi)
#        check appo.get[0].handlers[0].shape.radius == 1
#
#        
#        #-------------------------------------------------------------#
#        #       Checking getHitLeafs in specific reference system     #
#        #-------------------------------------------------------------#
#        rs = newReferenceSystem(newPoint3D(1, 0, 0), [eX, eZ, -eY])
#        toCheck = scene.fromObserver(rs, 1)
#
#        appo = toCheck.getHitLeafs(ray1)
#        check appo.isSome
#        check appo.get[0].handlers[0].shape.radius == 2
#
#        check not toCheck.getHitLeafs(ray2).isSome
#        check not toCheck.getHitLeafs(ray3).isSome
#        
#        # Changing ray origin
#        ray2.origin = newPoint3D(-4, 4, -4);
#        ray3.origin = newPoint3D(6, 4, -4)
#
#        appo = toCheck.getHitLeafs(ray2)
#        check appo.isSome
#        check appo.get[0].handlers[0].shape.radius == 1
#
#        appo = toCheck.getHitLeafs(ray3)
#        check appo.isSome
#        check appo.get[0].handlers[0].shape.radius == 1
#
#
#
