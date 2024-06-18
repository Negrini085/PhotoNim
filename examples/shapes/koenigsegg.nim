import PhotoNim


from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    outFile = "assets/images/examples/koenigsegg"
    camera = newPerspectiveCamera(
        newPathTracer(numRays = 5, maxDepth = 3), 
        viewport = (1600, 900), distance = 3.0, 
        newComposition(newRotX(-90), newTranslation(newPoint3D(-3, 0, 0)))
    )

    comp2 = newScaling(0.1)
    sphere = newSphere(Point3D(- 10.0.float32 * eX + eY + eZ), 0.5, newMaterial(newDiffuseBRDF(), newUniformPigment(RED)))

    koenigsegg = newMesh("assets/meshes/koenigsegg.obj", transformation = comp2, treeKind = tkBinary, maxShapesPerLeaf = 10, rgState = 42, rgSeq = 2)
    scene = newScene(@[koenigsegg, sphere])

    image = camera.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 1, treeKind = tkBinary, maxShapesPerLeaf = 1)


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

image.savePFM(outFile & ".pfm")
image.savePNG(outFile & ".png", 0.18, 1.0, 0.1)

discard execCmd fmt"open {outFile}.png"