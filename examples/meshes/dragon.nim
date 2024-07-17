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
    transformation = newTranslation(newPoint3D(20, 20, 20)) @ newScaling(0.05), 
    brdf = newDiffuseBRDF(),
    pigment = newUniformPigment(RED),
    treeKind = tkOctonary, 
    maxShapesPerLeaf = 4, 
    newRandomSetUp(rg)
)

echo fmt"Successfully loaded mesh in {cpuTime() - timeStart} seconds"
echo fmt"Dragon AABB: {dragon.mesh.tree.root.aabb}"


timeStart = cpuTime()

handlers.add dragon

let
    scene = newScene(
        bgColor = BLUE, 
        handlers, 
        newRandomSetUp(rg), 
        treeKind = tkBinary, 
        maxShapesPerLeaf = 1
    )

    camera = newPerspectiveCamera(
        renderer = newOnOffRenderer(RED), # newPathTracer(directSamples, indirectSamples, depthLimit), 
        viewport = (600, 600), 
        distance = -1.0, 
        transformation = Transformation.id
    )

    image = camera.samples(scene, newRandomSetUp(rg), nSamples, aaSamples)

echo fmt"Image luminosity {image.avLuminosity}"
echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."   

image.savePNG(outFile, 0.18, 1.0, 0.1)
discard execCmd fmt"open {outFile}"