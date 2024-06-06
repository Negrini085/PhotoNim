import std/[unittest, sequtils]
import PhotoNim

suite "Scene unittest":
    test "getWorldAABB proc":

        let 
            handler = (newTriangle(newPoint3D(0, -2, 0), newPoint3D(2, 1, 1), newPoint3D(0, 3, 0)), IDENTITY)
            worldRefSystem = newReferenceSystem(ORIGIN3D, stdONB)
            otherRefSystem = newReferenceSystem(newPoint3D(5.0, 0.0, 0.0), newONB(-eX, eY, -eZ))
            oRefSystem = newReferenceSystem(newPoint3D(5.0, 0.0, 0.0), stdONB)
    
            worldAABB = handler.getWorldAABB
            otherAABB = otherRefSystem.getAABB(handler)
            pAABB = oRefSystem.getAABB(handler)


        check areClose(worldAABB.min, newPoint3D(0, -2, 0))
        check areClose(worldAABB.max, newPoint3D(2, 3, 1))

        check areClose(otherAABB.min, newPoint3D(3, -2, -1))
        check areClose(otherAABB.max, newPoint3D(5, 3, 0))

        check areClose(pAABB.min, newPoint3D(-5, -2, 0))
        check areClose(pAABB.max, newPoint3D(-3, 3, 1))
        

    test "getAABB proc":
        let 
            handler1 = (newTriangle(newPoint3D(0, -2, 0), newPoint3D(2, 1, 1), newPoint3D(0, 3, 0)), newTranslation([float32 1, 1, -2]))
            handler2 = (newTriangle(newPoint3D(0, -2, 0), newPoint3D(2, 1, 1), newPoint3D(0, 3, 0)), IDENTITY)
            worldRefSystem = newReferenceSystem(ORIGIN3D, stdONB)
            otherRefSystem = newReferenceSystem(newPoint3D(5.0, 0.0, 0.0), newONB(-eX, eY, -eZ))
        
            sceneAABB = otherRefSystem.getAABB(@[handler1, handler2])

        echo sceneAABB