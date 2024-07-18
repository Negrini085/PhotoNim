import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd

var pcg = newPCG((42.uint64, 2.uint64))

let 
    timeStart = cpuTime()
    outFile = "assets/images/examples/meshes/dragon"
    camera = newPerspectiveCamera(
        newPathTracer(1, 1, 1), 
        viewport = (1600, 900), distance = 3.0, 
        newComposition(newRotation(-90, axisX), newTranslation(newPoint3D(-5.0, 1.5, 0.5)))
    )

    comp = newScaling(0.05)
    mat = newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(WHITE)), newUniformPigment(WHITE))
    dragon = newMesh("assets/meshes/dragon.obj", tkBinary, 10, (pcg.random, pcg.random), mat, comp)
    
    scene = newScene(BLACK, @[dragon], tkBinary, 1, (pcg.random, pcg.random))
    image = camera.sample(scene, (pcg.random, pcg.random))


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

image.savePFM(outFile & ".pfm")
image.savePNG(outFile & ".png", 0.18, 1.0)

discard execCmd fmt"open {outFile}.png"