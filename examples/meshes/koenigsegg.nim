import PhotoNim


from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    outFile = "assets/images/examples/meshes/koenigsegg"
    camera = newPerspectiveCamera(
        newPathTracer(numRays = 5, maxDepth = 3), 
        viewport = (1600, 900), distance = 3.0, 
        newComposition(newRotX(-90), newTranslation(newPoint3D(-3, 0, 0)))
    )

    comp2 = newScaling(0.1)
    koenigsegg = newMesh("assets/meshes/koenigsegg.obj", transformation = comp2, treeKind = tkBinary, maxShapesPerLeaf = 10, rgState = 42, rgSeq = 2)
    
    scene = newScene(@[koenigsegg])
    image = camera.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 1, treeKind = tkBinary, maxShapesPerLeaf = 1)


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

image.savePFM(outFile & ".pfm")
image.savePNG(outFile & ".png", 0.18, 1.0)

discard execCmd fmt"open {outFile}.png"