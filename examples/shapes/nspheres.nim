import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd


let 
    nSpheres = 2048  
    timeStart = cpuTime()
    camera = newPerspectiveCamera(
        renderer = newPathTracer(numRays = 4, maxDepth = 2),
        viewport = (600, 600), 
        distance = 1.0, 
        transformation = newTranslation(newPoint3D(-10, 0, 0))
    )

var 
    rg = newPCG()
    shapes = newSeq[ObjectHandler](nSpheres)

for i in 0..<nSpheres: 
    shapes[i] = newSphere(
        newPoint3D(rg.rand(-15, 15), rg.rand(-15, 15), rg.rand(-15, 15)), radius = rg.rand(0.1, 1.0), 
        newMaterial(newSpecularBRDF(), newUniformPigment(newColor(rg.rand, rg.rand, rg.rand)))
    )

let
    scene = newScene(shapes)
    image = camera.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 1, treeKind = tkOctonary, maxShapesPerLeaf = 4)

echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

let filename = fmt"assets/images/examples/spheres_n{nSpheres}_r{camera.renderer.numRays}_d{camera.renderer.maxDepth}.png"
image.savePNG(filename, 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}"