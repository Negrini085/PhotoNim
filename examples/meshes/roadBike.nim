import PhotoNim


from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd

var 
    timeStart = cpuTime()
    pcg = newPCG((91.uint64, 3.uint64))

let
    outFile = "assets/images/examples/meshes/roadBike"
    camera = newPerspectiveCamera(
        newPathTracer(1, 1, 1), 
        viewport = (1600, 900), distance = 3.0, 
        newTranslation(newPoint3D(-10, 0, 0))
    )

    comp2 = newComposition(newRotation(90, axisX), newScaling(4.0))

    mat = newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(WHITE)), newUniformPigment(WHITE))
    roadBike = newMesh(
        "assets/meshes/roadBike.obj", tkOctonary, 40, 
        (pcg.random, pcg.random), mat, comp2
    )

echo fmt"Successfully loaded mesh in {cpuTime() - timeStart} seconds."   
timeStart = cpuTime()

let
    scene = newScene(BLACK, @[roadBike], tkBinary, 1, (pcg.random, pcg.random))
    image = camera.sample(scene, (pcg.random, pcg.random))


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."   

image.savePFM(outFile & ".pfm")
image.savePNG(outFile & ".png", 0.18, 1.0, 0.1)

discard execCmd fmt"open {outFile}.png"