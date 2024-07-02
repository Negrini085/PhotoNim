import PhotoNim

from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd

let 
    viewport = (1600, 900)
    filename = "assets/images/examples/ellipsoid"

var handlers: seq[ShapeHandler]
handlers.add newEllipsoid(0.3, 0.2, 0.1, newTranslation(newVec3f(0, -0.5, 0.3)))
handlers.add newEllipsoid(0.1, 0.2, 0.3, newTranslation(newVec3f(0, 0.5, 0)))
handlers.add newEllipsoid(0.1, 0.5, 0.1, newComposition(newRotX(90), newTranslation(newVec3f(0, -0.8, 0))))

let
    mat1 = newMaterial(
        newDiffuseBRDF(newUniformPigment(newColor(1, 0, 0))), 
        newUniformPigment(newColor(1, 0, 0))
        )
    
    mat2 = newMaterial(
        newDiffuseBRDF(newCheckeredPigment(newColor(1, 0, 0), newColor(0, 1, 0), 2, 2)), 
        newCheckeredPigment(newColor(1, 0, 0), newColor(0, 1, 0), 2, 2)
        )
    
    mat3 = newMaterial(
        newSpecularBRDF(newUniformPigment(newColor(1, 0, 1))), 
        newUniformPigment(newColor(1, 0, 1))
        )

handlers[0].shape.material = mat1
handlers[1].shape.material = mat2
handlers[2].shape.material = mat3

let
    scene = newScene(handlers)
    renderer = newPathTracer(5, 5, 3)
    camera = newPerspectiveCamera(renderer, viewport, 1.0, newTranslation(newVec3f(-0.5, 0, 0)))

    image = camera.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 3, maxShapesPerLeaf = 1)

savePFM(image, filename & ".pfm")

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"