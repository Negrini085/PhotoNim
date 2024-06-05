import PhotoNim

from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd

let 
    (width, height) = (900, 600)
    filename = "assets/images/examples/triangle"

var handler: seq[ShapeHandler]
handler.add newUnitarySphere(ORIGIN3D - eY * 2)
handler.add newUnitarySphere(ORIGIN3D + eY)
handler.add newShapeHandler(
    newTriangle(newPoint3D(0.0, 2.0, 3.0), newPoint3D(0.0, -2.0, 2.0), newPoint3D(0.0, -1.0, -1.0)), 
    newComposition(newTranslation(eY * 4.0), newRotZ(-10), newRotY(10))
)

handler.add newShapeHandler(newCylinder(), newComposition(newTranslation([float32 0.0, 0.0, 1.5]), newRotY(10)))
handler.add newShapeHandler(newAABox(), newComposition(newTranslation([float32 -0.5, -2.5, 2.0]), newRotX(50)))

var 
    scene = newScene(handler)
    image = newHDRImage(width, height)
    camera = newPerspectiveCamera(width / height, 1.0, newTranslation([float32 -4, 0, 0]))
    renderer = newFlatRenderer(addr image, camera)

image.pixels = renderer.sample(scene, samplesPerSide = 4)

var stream = newFileStream(filename & ".pfm", fmWrite)
stream.writePFM image
stream.close

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"