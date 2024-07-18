import PhotoNim

from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd

let 
    viewport = (1600, 900)
    filename = "assets/images/examples/shapes/cylinder"

    mat1 = newEmissiveMaterial(
        newDiffuseBRDF(newUniformPigment(newColor(1, 0, 0))),
        newUniformPigment(newColor(1, 0, 0)) 
    )
    mat2 = newEmissiveMaterial(
        newDiffuseBRDF(newCheckeredPigment(newColor(1, 0, 0), newColor(0, 1, 0), 2, 2)), 
        newCheckeredPigment(newColor(1, 0, 0), newColor(0, 1, 0), 2, 2),
    )
    mat3 = newEmissiveMaterial(
        newSpecularBRDF(newUniformPigment(newColor(1, 0, 1))), 
        newUniformPigment(newColor(1, 0, 1))
    )

var
    handlers: seq[ObjectHandler]
    pcg = newPCG((42.uint64, 1.uint64))

handlers.add newCylinder(material = mat1, transformation = newTranslation(newVec3(0.0, 1.5, 0.8)))
handlers.add newCylinder(2,-1, 2, 0.5, mat2, newTranslation(newVec3(0.0, 0.5, 0.0)))
handlers.add newCylinder(material = mat3, transformation = newComposition(newRotation(90, axisX), newTranslation(newVec3(0.0, 0.8, 0.0))))

let 
    scene = newScene(BLACK, handlers, tkBinary, 1, (pcg.random, pcg.random))

    rend = newPathTracer(1, 1, 1)
    camera = newPerspectiveCamera(rend, viewport, 1.0, newTranslation(newVec3(-0.5, 0, 0)))

    image = camera.sample(scene, (pcg.random, pcg.random))

savePFM(image, filename & ".pfm")

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"