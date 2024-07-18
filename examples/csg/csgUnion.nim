import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    rs: RandomSetUp = (42, 1)
    outFile = "assets/images/examples/csg/csgUnion"
    camera = newPerspectiveCamera(
        newPathTracer(1, 1, 1), 
        viewport = (1600, 900), distance = 3.0, 
        newTranslation(newPoint3D(-10, 0, 0))
    )

    csgUnion = newCSGUnion(@[
            newSphere(newPoint3D(0, 1, 0), 1.5, newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(newColor(1, 0, 0))), newUniformPigment(newColor(1, 0, 0)))),
            newSphere(newPoint3D(0,-1, 0), 1.5, newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(newColor(0, 1, 0))), newUniformPigment(newColor(0, 1, 0)))),
            newSphere(newPoint3D(0, 0, 1), 1.5, newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(newColor(0, 0, 1))), newUniformPigment(newColor(0, 0, 1))))
        ], tkBinary, 1, rs, 
        newRotation(5, axisZ)
    )
    scene = newScene(BLACK, @[csgUnion], tkBinary, 1, rs)
    image = camera.sample(scene, rs)


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."   

image.savePFM(outFile & ".pfm")
image.savePNG(outFile & ".png", 0.18, 1.0, 0.1)

discard execCmd fmt"open {outFile}.png"