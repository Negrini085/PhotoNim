import PhotoNim


from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    outFile = "assets/images/examples/meshes/dragon"
    camera = newPerspectiveCamera(
        newPathTracer(numRays = 1, maxDepth = 1), 
        viewport = (1600, 900), distance = 3.0, 
        newComposition(newRotation(-90, axisX), newTranslation(newPoint3D(-5, 1.5, 0.5)))
    )

    comp = newScaling(0.05)
    dragon = newMesh("assets/meshes/dragon.obj", transformation = comp, treeKind = tkBinary, maxShapesPerLeaf = 10, rgState = 42, rgSeq = 2)
    
    scene = newScene(@[dragon])
    image = camera.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 1, treeKind = tkBinary, maxShapesPerLeaf = 1)


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

image.savePFM(outFile & ".pfm")
image.savePNG(outFile & ".png", 0.18, 1.0)

discard execCmd fmt"open {outFile}.png"