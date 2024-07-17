import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd

var pcg = newPCG((51.uint64, 13.uint64))

let 
    timeStart = cpuTime()
    outFile = "assets/images/examples/meshes/teapot"
    camera = newPerspectiveCamera(
        newPathTracer(1, 1, 1), 
        viewport = (1600, 900), distance = 3.0, 
        newTranslation(newPoint3D(-15, 0, 0))
    )
    
    comp = newComposition(newScaling(0.05), newRotation(90, axisZ), newRotation(90, axisX))
    mat = newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(WHITE)), newUniformPigment(WHITE))
    teapot = newMesh("assets/meshes/teapot.obj", tkBinary, 10, (pcg.random, pcg.random), mat, comp)
    scene = newScene(BLACK, @[teapot], tkBinary, 1, (pcg.random, pcg.random))

    image = camera.sample(scene, (pcg.random, pcg.random))


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

image.savePFM(outFile & ".pfm")
image.savePNG(outFile & ".png", 0.18, 1.0)

discard execCmd fmt"open {outFile}.png"
