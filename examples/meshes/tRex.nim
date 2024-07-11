import PhotoNim


from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd


var timeStart = cpuTime()
let 
    outFile = "assets/images/examples/meshes/tRex"
    camera = newPerspectiveCamera(
        newPathTracer(numRays = 1, maxDepth = 1), 
        viewport = (1600, 900), distance = 3.0, 
        newComposition(newRotation(-90, axisY), newRotation(-90, axisX), newTranslation(newPoint3D(-5, 0, 1.0)))
    )

    comp2 = newScaling(0.01)

    tRex = newMesh("assets/meshes/tRex.obj", transformation = comp2, treeKind = tkBinary, maxShapesPerLeaf = 10, rgState = 42, rgSeq = 2)
    scene = newScene(@[tRex])

echo fmt"Successfully loaded mesh in {cpuTime() - timeStart} seconds."
timeStart = cpuTime()

let image = camera.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 1, treeKind = tkBinary, maxShapesPerLeaf = 1)


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

image.savePFM(outFile & ".pfm")
image.savePNG(outFile & ".png", 0.18, 1.0)

discard execCmd fmt"open {outFile}.png"