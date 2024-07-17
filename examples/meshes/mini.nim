import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd

var pcg = newPCG((38.uint64, 21.uint64))

let 
    timeStart = cpuTime()
    outFile = "assets/images/examples/meshes/mini"
    camera = newPerspectiveCamera(
        newPathTracer(1, 1, 1), 
        viewport = (1600, 900), distance = 3.0, 
        newTranslation(newPoint3D(-10, 0, 0))
    )

    comp = newComposition(newScaling(0.05), newRotation(-45, axisZ))
    mat = newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(WHITE)), newUniformPigment(WHITE))
    mini = newMesh("assets/meshes/minicooper.obj", tkBinary, 10, (pcg.random, pcg.random), mat, comp)
    scene = newScene(BLACK, @[mini], tkBinary, 1, (pcg.random, pcg.random))

    image = camera.sample(scene, (pcg.random, pcg.random))


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

image.savePFM(outFile & ".pfm")
image.savePNG(outFile & ".png", 0.18, 1.0)

discard execCmd fmt"open {outFile}.png"