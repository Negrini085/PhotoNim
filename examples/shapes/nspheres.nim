import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd


let 
    nSpheres = 512  
    filename = fmt"assets/images/examples/shapes/nSpheres.png"

    timeStart = cpuTime()
    camera = newPerspectiveCamera(
        renderer = newPathTracer(3, 2, 1),
        viewport = (600, 600), 
        distance = 1.0, 
        transformation = newTranslation(newPoint3D(-10, 0, 0))
    )

var 
    col: Color
    pcg = newPCG((92.uint64, 72.uint64))
    shapes = newSeq[ObjectHandler](nSpheres)

for i in 0..<nSpheres: 
    col = newColor(pcg.rand, pcg.rand, pcg.rand)
    shapes[i] = newSphere(
        newPoint3D(pcg.rand(-15, 15), pcg.rand(-15, 15), pcg.rand(-15, 15)), radius = pcg.rand(0.1, 1.0), 
        newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(col)), newUniformPigment(col))
    )

let
    scene = newScene(BLACK, shapes, tkOctonary, 2, (pcg.random, pcg.random))
    image = camera.sample(scene, (pcg.random, pcg.random))

echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

image.savePNG(filename, 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}"