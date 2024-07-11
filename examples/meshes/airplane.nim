import PhotoNim


from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd

var timeStart = cpuTime()
let 
    outFile = "assets/images/examples/meshes/airplane"
    camera = newPerspectiveCamera(
        newPathTracer(numRays = 1, maxDepth = 1), 
        viewport = (1600, 900), distance = 3.0, 
        newTranslation(newPoint3D(-10, 0, 0))
    )

    comp2 = newComposition(newScaling(3e-3), newTranslation(eX), newRotation(2, axisX))
    airplane = newMesh("assets/meshes/airplane.obj", transformation = comp2, treeKind = tkBinary, maxShapesPerLeaf = 10, rgState = 42, rgSeq = 2)
   
    scene = newScene(@[airplane])


echo fmt"Successfully loaded mesh in {cpuTime() - timeStart} seconds." 

timeStart = cpuTime()
let image = camera.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 1, treeKind = tkBinary, maxShapesPerLeaf = 1)

echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."   

image.savePFM(outFile & ".pfm")
image.savePNG(outFile & ".png", 0.18, 1.0, 0.1)

discard execCmd fmt"open {outFile}.png"