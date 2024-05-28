import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    (width, height) = (900, 600)
    filename = "assets/images/examples/BVH"

var 
    cam = newPerspectiveCamera(width / height, 1.0, newTranslation(newVec3f(-5.0, 0, 0)) @ newRotZ(20) @ newRotY(-10))
    tracer = newImageTracer(width, height, cam, samplesPerSide = 4)
    scenery = newWorld()

scenery.shapes.add newSphere(newPoint3D(0.3, -0.5, -0.5), radius = 0.1)
scenery.shapes.add newSphere(newPoint3D(1.0, 1.5, -0.2), radius = 0.5)
scenery.shapes.add newSphere(newPoint3D(-0.5, -1.5, 0.0), radius = 0.2)
scenery.shapes.add newSphere(newPoint3D(0.0, 0.0, 0.0), radius = 0.5)

scenery.shapes.add newTriangle(newPoint3D(0, -1, -1), newPoint3D(-1, 1, 1), newPoint3D(-1, 0, 3), newTranslation(newVec3f(0, -3, -3)))
scenery.shapes.add newTriangle(newPoint3D(-2, -1, -1), newPoint3D(-1, 1, 1), newPoint3D(-1, 0, 3), newScaling(3) @ newTranslation(newVec3f(0, 1, -2)))

scenery.shapes.add newCylinder(transform = newTranslation(newVec3f(0.0, -2.0, 1.5)))


echo "Starting to redender the scene."
tracer.fireAllRays(scenery, proc(ray: Ray): Color = newColor(0.3, 0.7, 0.1))
echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

var stream = newFileStream(filename & ".pfm", fmWrite)
stream.writePFM tracer.image
stream.close

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"