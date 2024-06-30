import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    camera = newPerspectiveCamera(viewport = (900, 600), distance = 1.0, newComposition(newRotZ(10), newTranslation(newPoint3D(-5, -5, 1))))
    
    # renderer = newOnOffRenderer(camera)
    # renderer = newFlatRenderer(camera)
    renderer = newPathTracer(camera, numRays = 4, maxDepth = 2)


    plane = newPlane(
        newMaterial(
            newDiffuseBRDF(newCheckeredPigment(RED, WHITE, 2, 2)), 
            newCheckeredPigment(RED, WHITE, 2, 2)
        )
    )

    sphere1 = newSphere(
        ORIGIN3D, 2.0,
        newMaterial(newSpecularBRDF(), newUniformPigment(BLUE))
    )

    sphere2 = newUnitarySphere(
        Point3D(-4.0.float32 * eY),
        newMaterial(newDiffuseBRDF(), newUniformPigment(GREEN))
    )

    sphere3 = newUnitarySphere(
        Point3D(4.0.float32 * eZ),
        newMaterial(newDiffuseBRDF(), newUniformPigment(RED))
    )

    sphere4 = newSphere(
        ORIGIN3D + eX, Inf,
        newMaterial(newDiffuseBRDF(), newUniformPigment(WHITE))
    )


    scene = newScene(@[plane, sphere1, sphere2, sphere3])

    image = renderer.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 2, maxShapesPerLeaf = 2)

echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

let filename = "assets/images/examples/scene"
var stream = newFileStream(filename & ".pfm", fmWrite)
stream.writePFM image
stream.close

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"