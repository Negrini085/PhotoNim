import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd

var pcg = newPCG((42.uint64, 2.uint64))

let 
    timeStart = cpuTime()
    outFile = "assets/images/examples/meshes/koenigsegg"
    camera = newPerspectiveCamera(
        newPathTracer(1, 1, 1), viewport = (1600, 900), distance = 3.0, 
        newComposition(newRotation(-90, axisX), newTranslation(newPoint3D(-3, 0, 0)))
    )

    comp2 = newScaling(0.1)
    mat = newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(WHITE)), newUniformPigment(WHITE))
    koenigsegg = newMesh("assets/meshes/koenigsegg.obj", tkBinary, 10, (42.uint64, 2.uint64), mat, comp2)
    
    scene = newScene(BLACK, @[koenigsegg], tkBinary, 1, (pcg.random, pcg.random))
    image = camera.sample(scene, (pcg.random, pcg.random))


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

image.savePFM(outFile & ".pfm")
image.savePNG(outFile & ".png", 0.18, 1.0)

discard execCmd fmt"open {outFile}.png"