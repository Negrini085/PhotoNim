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
    outFile = "assets/images/examples/meshes/minicooper.png"

var 
    rg = newPCG(rgSetUp)
    timeStart = cpuTime()

let
    minicooper = newMesh(
        source = "assets/meshes/minicooper.obj", 
        material = newMaterial(newDiffuseBRDF(newUniformPigment(newColor(0.8, 0.6, 0.2))), newUniformPigment(WHITE)),
        transformation = newScaling(0.05), 
        treeKind = tkOctonary, maxShapesPerLeaf = 4, 
        newRandomSetUp(rg.random, rg.random)
    )

echo minicooper.mesh.tree.root.aabb
echo fmt"Successfully loaded mesh in {cpuTime() - timeStart} seconds."   
timeStart = cpuTime()

let
    scene = newScene(
        bgColor = BLACK, 
        @[minicooper], 
        newRandomSetUp(rg.random, rg.random), 
        treeKind = tkBinary, 
        maxShapesPerLeaf = 2
    )

    camera = newPerspectiveCamera(
        renderer = newPathTracer(directSamples, indirectSamples, depthLimit), 
        viewport = (600, 600), 
        distance = 1.0, 
        transformation = newTranslation(newPoint3D(-10, 0, 0))
    )

    image = camera.samples(scene, newRandomSetUp(rg.random, rg.random), nSamples, aaSamples)


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."   

image.savePNG(outFile, 0.18, 1.0, 0.1)

discard execCmd fmt"open {outFile}"