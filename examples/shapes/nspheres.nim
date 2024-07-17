import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd


let 
    nSpheres = 512  
    samplesPerSide: int = 1
    numRays: int = 1
    maxDepth: int = 1
    rgSetUp = newRandomSetUp(67, 4)
    filename = fmt"assets/images/examples/spheres_n{nSpheres}_r{numRays}_d{maxDepth}.png"

    timeStart = cpuTime()
    camera = newPerspectiveCamera(
        renderer = newPathTracer(numRays, maxDepth),
        viewport = (600, 600), 
        distance = 1.0, 
        transformation = newTranslation(newPoint3D(-10, 0, 0))
    )

var 
    rg = newPCG(rgSetUp)
    shapes = newSeq[ObjectHandler](nSpheres)

for i in 0..<nSpheres: 
    shapes[i] = newSphere(
        newPoint3D(rg.rand(-15, 15), rg.rand(-15, 15), rg.rand(-15, 15)), radius = rg.rand(0.1, 1.0), 
        newMaterial(newSpecularBRDF(), newUniformPigment(newColor(rg.rand, rg.rand, rg.rand)))
    )

let
    scene = newScene(BLACK, shapes, newRandomSetUp(rg), treeKind = tkOctonary, maxShapesPerLeaf = 8)
    image = camera.sample(scene, newRandomSetUp(rg), samplesPerSide)

echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

image.savePNG(filename, 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}"