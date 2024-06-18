import PhotoNim


from std/times import cpuTime
from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    comp1 = newComposition(newRotX(-90), newTranslation(newPoint3D(-5, 0, 0)))
    camera = newPerspectiveCamera(viewport = (1600, 900), distance = 3.0, comp1)
    renderer = newPathTracer(camera, numRays = 1, maxDepth = 1)

    koenigseggOBJ = "assets/meshes/koenigsegg.obj"
    comp2 = newScaling(0.1)
    mat = newMaterial(newDiffuseBRDF(), newUniformPigment(newColor(1, 223/255, 0)))
    koenigsegg = newMesh(loadMesh(koenigseggOBJ), material = mat, transformation = comp2, treeKind = tkBinary, maxShapesPerLeaf = 10, rgState = 42, rgSeq = 2)

let
    scene = newScene(@[koenigsegg])

    image = renderer.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 1, treeKind = tkBinary, maxShapesPerLeaf = 1)


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

let filename = "assets/images/examples/koenigsegg"
var stream = newFileStream(filename & ".pfm", fmWrite)
stream.writePFM image
stream.close

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"