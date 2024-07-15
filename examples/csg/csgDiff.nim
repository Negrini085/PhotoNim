import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    outFile = "assets/images/examples/csgDiff"
    camera = newPerspectiveCamera(
        newPathTracer(numRays = 1, maxDepth = 1), 
        viewport = (1600, 900), distance = 3.0, 
        newTranslation(newPoint3D(-10, 0, 0))
    )


var csgDiff = newCSGDiff(
        newSphere(newPoint3D(0,1,0), 2, newMaterial(newDiffuseBRDF(newUniformPigment(newColor(0, 0, 0))), newUniformPigment(newColor(1, 0, 0)))),
        newSphere(newPoint3D(0,-1,0), 2, newMaterial(newDiffuseBRDF(newUniformPigment(newColor(0, 0, 0))), newUniformPigment(newColor(0, 1, 0)))),
    )

csgDiff = newCSGDiff(
    csgDiff, newPlane(newMaterial(newDiffuseBRDF(newUniformPigment(newColor(0, 0, 0))), newUniformPigment(newColor(0, 0, 1)))),
    newComposition(newRotX(-45), newRotZ(-30), newRotY(20))
)

let 
    scene = newScene(@[csgDiff])
    image = camera.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 1, treeKind = tkBinary, maxShapesPerLeaf = 1)


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."   

image.savePFM(outFile & ".pfm")
image.savePNG(outFile & ".png", 0.18, 1.0, 0.1)

discard execCmd fmt"open {outFile}.png"