import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd

let 
    timeStart = cpuTime()
    (width, height) = (900, 600)
    filename = "assets/images/examples/triangle"

var shapes: seq[Shape]
shapes.add newUnitarySphere(ORIGIN3D - eY * 2)
shapes.add newUnitarySphere(ORIGIN3D + eY)
shapes.add newTriangle(newPoint3D(0.0, 2.0, 3.0), newPoint3D(0.0, -2.0, 2.0), newPoint3D(0.0, -1.0, -1.0), newComposition(newTranslation(eY * 4.0), newRotZ(-10), newRotY(10)))
shapes.add newCylinder(transformation = newComposition(newTranslation(newVec3f(0.0, 0.0, 1.5)), newRotY(10)))
shapes.add newAABox(transformation = newComposition(newTranslation(newVec3f(-0.5, -2.5, 2.0)), newRotX(10)))

var 
    scene = newScene(shapes)
    image = newHDRImage(width, height)
    camera = newPerspectiveCamera(width / height, 1.0, newTranslation(newVec3f(-4, 0, 0)))
    renderer = newOnOffRenderer(addr image, camera)

scene.render(renderer, maxShapesPerLeaf = 2, samplesPerSide = 10)
echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

var stream = newFileStream(filename & ".pfm", fmWrite)
stream.writePFM image
stream.close

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"