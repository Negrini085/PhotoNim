import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd


let 
    nSamples: int = 1
    aaSamples: int = 1
    directSamples: int = 1
    indirectSamples: int = 1
    depthLimit: int = 1
    rgSetUp = newRandomSetUp(67, 4)
    outFile = "assets/images/examples/meshes/dragon.png"

var 
    rg = newPCG(rgSetUp)
    handlers: seq[ObjectHandler]

var timeStart = cpuTime()

let dragon = newMesh(
    source = "assets/meshes/dragon.obj", 
    material = newMaterial(
        newDiffuseBRDF(newUniformPigment(WHITE)),
        newUniformPigment(WHITE)
    ),
    transformation = newScaling(0.05), 
    treeKind = tkOctonary, 
    maxShapesPerLeaf = 4, 
    newRandomSetUp(rg.random, rg.random)
)

echo fmt"Successfully loaded mesh in {cpuTime() - timeStart} seconds"
timeStart = cpuTime()

handlers.add dragon

let
    scene = newScene(
        bgColor = BLACK, 
        handlers, 
        newRandomSetUp(rg.random, rg.random), 
        treeKind = tkBinary, 
        maxShapesPerLeaf = 1
    )

    camera = newPerspectiveCamera(
        renderer = newPathTracer(directSamples, indirectSamples, depthLimit), 
        viewport = (600, 600), 
        distance = 3.0, 
        transformation = newComposition(newRotation(-90, axisX), newTranslation(newPoint3D(-0.5, 1.5, 0.5)))
    )

    image = camera.samples(scene, newRandomSetUp(rg.random, rg.random), nSamples, aaSamples)

echo fmt"Image luminosity {image.avLuminosity}"
echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."   

image.savePNG(outFile, 0.18, 1.0, 0.1)
discard execCmd fmt"open {outFile}"