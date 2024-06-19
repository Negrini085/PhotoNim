import PhotoNim


from std/times import cpuTime
from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    camera = newPerspectiveCamera(viewport = (900, 600), distance = 4.0, newComposition(newTranslation(newPoint3D(-15, 0, 0))))
    renderer = newPathTracer(camera, numRays = 1, maxDepth = 1)

    teapotOBJ = "assets/meshes/teapot.obj"
    teapot = newMesh(loadMesh(teapotOBJ), transformation = newComposition(newScaling(0.05), newRotZ(90), newRotX(90)), treeKind = tkBinary, maxShapesPerLeaf = 4, rgState = 42, rgSeq = 2)

    scene = newScene(@[teapot])

    image = renderer.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 1, treeKind = tkBinary, maxShapesPerLeaf = 1)


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

let filename = "assets/images/examples/teapot"
var stream = newFileStream(filename & ".pfm", fmWrite)
stream.writePFM image
stream.close

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"