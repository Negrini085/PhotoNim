import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    outFile = "assets/images/examples/trumpet"
    camera = newPerspectiveCamera(
        newPathTracer(numRays = 1, maxDepth = 1), 
        viewport = (1600, 900), distance = 3.0, 
        newTranslation(newPoint3D(-10, 0, -4))
    )

    comp = newComposition(newScaling(0.01), newRotX(90))
    trumpet = newMesh("assets/meshes/trumpet.obj", transformation = comp, treeKind = tkBinary, maxShapesPerLeaf = 10, rgState = 42, rgSeq = 2)
    
    scene = newScene(@[trumpet])
    image = camera.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 1, treeKind = tkBinary, maxShapesPerLeaf = 1)


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

image.savePFM(outFile & ".pfm")
image.savePNG(outFile & ".png", 0.18, 1.0)

discard execCmd fmt"open {outFile}.png"