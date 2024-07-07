import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd


let 
    nSpheres = 512
    timeStart = cpuTime()
    camera = newPerspectiveCamera(
        renderer = newPathTracer(numRays = 1, maxDepth = 1),
        viewport = (600, 600), 
        distance = 1.0, 
        transformation = newTranslation(newPoint3D(-6, 0, 0))
    )

var 
    rg = newPCG()
    shapes = newSeq[ShapeHandler](nSpheres)

for i in 0..<nSpheres: 
    shapes[i] = newSphere(
        newPoint3D(rg.rand(-5, 5), rg.rand(-5, 5), rg.rand(-5, 5)), radius = rg.rand(0.1, 1.0), 
        newMaterial(newFresnelMetalBRDF(), newUniformPigment(newColor(rg.rand, rg.rand, rg.rand)))
    )

let
    scene = newScene(shapes)
    image = camera.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 1, treeKind = tkBinary, maxShapesPerLeaf = 4)

echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

let filename = fmt"assets/images/examples/old_nspheres_{nSpheres}.png"
image.savePNG(filename, 0.18, 1.0)
discard execCmd fmt"open {filename}"