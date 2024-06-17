import PhotoNim


from std/times import cpuTime
from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    camera = newPerspectiveCamera(viewport = (600, 600), distance = 3.0, newComposition(newTranslation(newPoint3D(-10, 0, 0))))
    renderer = newPathTracer(camera, numRays = 1, maxDepth = 1)

    miniOBJ = "assets/meshes/minicooper.obj"
    mini = newMesh(loadMesh(miniOBJ), transformation = newComposition(newScaling(0.05), newRotZ(-45)), treeKind = tkBinary, maxShapesPerLeaf = 10, rgState = 42, rgSeq = 2)

    scene = newScene(@[mini])

    image = renderer.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 1, treeKind = tkBinary, maxShapesPerLeaf = 1)


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

let filename = "assets/images/examples/minicooper"
var stream = newFileStream(filename & ".pfm", fmWrite)
stream.writePFM image
stream.close

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"