import PhotoNim

from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd

let 
    viewport = (1600, 900)
    filename = "assets/images/examples/shapes/ellipsoid"

var handlers: seq[ObjectHandler]

handlers.add newEllipsoid(
        0.3, 0.2, 0.1, newDiffuseBRDF(newUniformPigment(newColor(1, 0, 0))), 
        newUniformPigment(newColor(1, 0, 0)), newTranslation(newVec3f(0, -0.5, 0.3))
    )
handlers.add newEllipsoid(
        0.1, 0.2, 0.3, newDiffuseBRDF(newCheckeredPigment(newColor(1, 0, 0), newColor(0, 1, 0), 2, 2)), 
        newCheckeredPigment(newColor(1, 0, 0), newColor(0, 1, 0), 2, 2), newTranslation(newVec3f(0, 0.5, 0))
    )
handlers.add newEllipsoid(
        0.1, 0.5, 0.1, newSpecularBRDF(newUniformPigment(newColor(1, 0, 1))), newUniformPigment(newColor(1, 0, 1)),
        newComposition(newRotation(90, axisX), newTranslation(newVec3f(0, -0.8, 0)))
    )

let
    rs1 = newRandomSetUp(42, 1)
    rs2 = newRandomSetUp(42, 2)
    scene = newScene(BLACK, handlers, tkBinary, 1, rs1)

    renderer = newPathTracer(1, 1, 1)
    camera = newPerspectiveCamera(renderer, viewport, 1.0, newTranslation(newVec3f(-0.5, 0, 0)))

    image = camera.sample(scene, rs2, 2)

savePFM(image, filename & ".pfm")

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"