import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    camera = newPerspectiveCamera((900, 600), 1.0, newTranslation(newPoint3D(-10, 0, 0)))
    renderer = newPathTracer(camera, numRays = 5, maxDepth = 2)

var 
    rg = newPCG()
    shapes = newSeq[ShapeHandler](500)

for i in 0..<500: 
    shapes[i] = newSphere(
        newPoint3D(rg.rand(-5, 5), rg.rand(-5, 5), rg.rand(-5, 5)), radius = rg.rand(0.1, 1.0), 
        newMaterial(newSpecularBRDF(), newUniformPigment(newColor(rg.rand, rg.rand, rg.rand)))
    )

let
    scene = newScene(shapes)
    image = renderer.sample(scene, rgState = 42, rgSeq = 1, samplesPerSide = 1, maxShapesPerLeaf = 10)

echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

let filename = "assets/images/examples/nspheres"
var stream = newFileStream(filename & ".pfm", fmWrite)
stream.writePFM image
stream.close

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"