import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    (width, height) = (900, 600)
    filename = "assets/images/examples/triangle"

var 
    cam = newPerspectiveCamera(width / height, 1.0, newTranslation(newVec3f(-3, 0, 0)))
    tracer = newImageTracer(width, height, cam, samplesPerSide = 2)
    scenery = newWorld()

scenery.shapes.add newUnitarySphere(ORIGIN3D - eY * 2.0)
scenery.shapes.add newUnitarySphere(ORIGIN3D + eY)
scenery.shapes.add newTriangle(
    newPoint3D(0.0, 2.0, 3.0), newPoint3D(0.0, -2.0, 2.0), newPoint3D(0.0, -1.0, -1.0), 
    newComposition(newTranslation(eY * 4.0), newRotZ(-5), newRotY(10))
)

scenery.shapes.add newCylinder(transform = newComposition(newTranslation(newVec3f(0.0, 0.0, 1.5)), newRotY(10)))
scenery.shapes.add newAABox(transform = newComposition(newTranslation(newVec3f(-0.5, -2.5, 2.0)), newRotX(10)))

tracer.fireAllRays(scenery, proc(ray: Ray): Color = newColor(1.0, 0.0, 1.0))

echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

var stream = newFileStream(filename & ".pfm", fmWrite)
stream.writePFM tracer.image
stream.close

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"