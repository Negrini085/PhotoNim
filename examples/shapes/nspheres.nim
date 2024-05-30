import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd


let timeStart = cpuTime()

var 
    shapes: seq[Shape]
    pcg = newPCG()

for i in 0..<300:
    shapes.add newSphere(newPoint3D(pcg.rand(-5, 5), pcg.rand(-5, 5), pcg.rand(-5, 5)), radius = pcg.rand(0.1, 1.0))
    shapes.add newSphere(newPoint3D(pcg.rand(-5, 5), pcg.rand(-5, 5), pcg.rand(-5, 5)), radius = pcg.rand(0.1, 1.0))

let
    filename = "assets/images/examples/nspheresBounded"
    image = newHDRImage(900, 600)

var 
    scene = newScene(shapes)
    renderer = newOnOffRenderer(
        addr image, 
        newPerspectiveCamera(image.width / image.height, 1.0, newTranslation(newVec3f(-10, 0, 0))),
        aa = 4
    )

scene.buildTree(4)
renderer.render(scene)
echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

var stream = newFileStream(filename & ".pfm", fmWrite)
stream.writePFM image
stream.close

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"
