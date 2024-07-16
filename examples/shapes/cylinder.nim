import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    (width, height) = (900, 600)
    filename = "assets/images/examples/cylinder"

var 
    cam = newPerspectiveCamera(width / height, 1.0, newTranslation(newVec3(-2, 0, 0)))
    tracer = newImageTracer(width, height, cam, samplesPerSide = 2)
    scenery = newWorld()

scenery.shapes.add newCylinder(transform = newTranslation(newVec3(0.0, 0.0, 1.5)))
scenery.shapes.add newUnitarySphere(newPoint3D(0.0, 0.0, 0.0))

tracer.fireAllRays(scenery, proc(ray: Ray): Color = newColor(1.0, 0.0, 1.0))

echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

var stream = newFileStream(filename & ".pfm", fmWrite)
stream.writePFM tracer.image
stream.close

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"