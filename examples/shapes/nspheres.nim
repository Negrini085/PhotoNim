import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    (width, height) = (900, 600)
    filename = "assets/images/examples/nspheres"

var 
    cam = newPerspectiveCamera(width / height, 1.0, newTranslation(newVec3f(-1.5, 0, 0)))
    tracer = newImageTracer(width, height, cam, samplesPerSide = 4)
    scenery = newWorld()
    pcg = newPCG()

for i in 0..<30:
    scenery.shapes.add newSphere(newPoint3D(pcg.rand(0, 2), pcg.rand(-2, 2), pcg.rand(-2, 2)), radius = pcg.rand)
    scenery.shapes.add newSphere(newPoint3D(pcg.rand(0, 2), pcg.rand(-2, 2), pcg.rand(-2, 2)), radius = pcg.rand)

tracer.fireAllRays(scenery, proc(ray: Ray): Color = newColor(0.4, 0.2, 0.5))
echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

var stream = newFileStream(filename & ".pfm", fmWrite)
stream.writePFM tracer.image
stream.close

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"