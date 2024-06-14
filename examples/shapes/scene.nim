import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd

from std/sequtils import map


let 
    timeStart = cpuTime()
    camera = newPerspectiveCamera(viewport = (300, 200), distance = 1.0, origin = newPoint3D(-5, -5, 1))
    # renderer = newFlatRenderer(camera)
    renderer = newPathTracer(camera, nRays = 4, maxDepth = 5)

    plane = newPlane(
        newMaterial(
            newDiffuseBRDF(newCheckeredPigment(RED, WHITE, 2, 2)), 
            newCheckeredPigment(RED, WHITE, 2, 2)
        )
    )

    sphere = newUnitarySphere(
        ORIGIN3D,
        newMaterial(newSpecularBRDF(), newUniformPigment(BLUE))
    )

    scene = newScene(@[plane, sphere])


let image = renderer.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 3, maxShapesPerLeaf = 1)

echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

let filename = "assets/images/examples/scene"
var stream = newFileStream(filename & ".pfm", fmWrite)
stream.writePFM image
stream.close

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"