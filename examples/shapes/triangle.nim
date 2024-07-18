import PhotoNim

from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd

let 
    viewport = (1600, 900)
    filename = "assets/images/examples/shapes/triangle"

    mat1 = newEmissiveMaterial(
        newDiffuseBRDF(newUniformPigment(newColor(1, 0, 0))),
        newUniformPigment(newColor(1, 0, 0)) 
    )

    tri = newTriangle([newPoint3D(1, 0, 0), newPoint3D(1.0, 0.5, 0.5), newPoint3D(1.0,-0.5, 0.5)], mat1)

var
    handlers: seq[ObjectHandler]
    pcg = newPCG((42.uint64, 1.uint64))

let 
    scene = newScene(BLACK, @[tri], tkBinary, 1, (pcg.random, pcg.random))

    rend = newPathTracer(1, 1, 1)
    camera = newPerspectiveCamera(rend, viewport, 1.0, newTranslation(newVec3(-0.5, 0.0, 0.0)))
    image = camera.sample(scene, (pcg.random, pcg.random))

savePFM(image, filename & ".pfm")

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"