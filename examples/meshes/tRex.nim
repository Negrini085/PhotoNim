import PhotoNim


from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd

var pcg = newPCG((27.uint64, 12.uint64))

let 
    timeStart = cpuTime()
    outFile = "assets/images/examples/meshes/tRex"
    camera = newPerspectiveCamera(
        newPathTracer(1, 1, 1), 
        viewport = (1600, 900), distance = 3.0, 
        newComposition(newRotation(-90, axisY), newRotation(-90, axisX), newTranslation(newPoint3D(-5, 0, 1)))
    )

    comp2 = newScaling(0.01)

    mat = newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(WHITE)), newUniformPigment(WHITE))
    tRex = newMesh("assets/meshes/tRex.obj", tkBinary, 10, (pcg.random, pcg.random), mat, comp2)
    
    scene = newScene(BLACK, @[tRex], tkBinary, 1, (pcg.random, pcg.random))
    image = camera.sample(scene, (pcg.random, pcg.random))


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

image.savePFM(outFile & ".pfm")
image.savePNG(outFile & ".png", 0.18, 1.0)

discard execCmd fmt"open {outFile}.png"