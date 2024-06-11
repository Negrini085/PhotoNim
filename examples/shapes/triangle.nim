import PhotoNim

from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd

let 
    viewport = (900, 600)
    filename = "assets/images/examples/triangle"

var handlers: seq[ShapeHandler]
handlers.add newUnitarySphere(ORIGIN3D - eY * 2)
handlers.add newUnitarySphere(ORIGIN3D + eY)
handlers.add newShapeHandler(
    newTriangle(newPoint3D(0.0, 2.0, 3.0), newPoint3D(0.0, -2.0, 2.0), newPoint3D(0.0, -1.0, -1.0)), 
    newComposition(newTranslation(eY * 4.0), newRotZ(-10), newRotY(10))
)

handlers.add newShapeHandler(newCylinder(), newComposition(newTranslation([float32 0.0, 0.0, 1.5]), newRotY(10)))
handlers.add newShapeHandler(newAABox(), newComposition(newTranslation([float32 -0.5, -2.5, 2.0]), newRotX(50)))

let
    scene = newScene(handlers)
    camera = newPerspectiveCamera(viewport, 1.0, newPoint3D(-4, 0, 0))
    renderer = newFlatRenderer(camera)

    image = renderer.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 3, maxShapesPerLeaf = 1)

var stream = newFileStream(filename & ".pfm", fmWrite)
stream.writePFM image
stream.close

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"