import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/strutils import parseInt, parseUint
from std/cmdline import commandLineParams
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    args = commandLineParams()

var
    nRays, maxDepth, rouLimit: int
    rgState, rgSeq: uint64

try:
    nRays = parseInt(args[0])
    maxDepth = parseInt(args[1])
    rouLimit = parseInt(args[2])
    rgState = parseUint(args[3])
    rgSeq = parseUint(args[4])
except:
    let msg = "Correct usage: executable <nRays> <maxDepth> <rouLimit> <rgState> <rgSeq>"
    raise newException(CatchableError, msg)

var pcg = newPCG((rgState, rgSeq))
let
    filename = fmt"examples/cornell/frames/singlesample_{nRays}_{maxDepth}"

    renderer = newPathTracer(nRays, maxDepth, rouLimit)
    camera = newPerspectiveCamera(renderer, viewport = (600, 600), distance = 1.0, newTranslation(newPoint3D(-0.75, 0, 0)))


    room = newBox(
        (newPoint3D(-2, -2, -2), newPoint3D(2, 2, 2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(WHITE)))
    )    

    lamp = newBox(
        (newPoint3D(0.5, -0.5, 1.8), newPoint3D(1.5, 0.5, 2)), 
        newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(newColor(0.5, 0.5, 0.5))), newUniformPigment(WHITE))
    ) 

    lwall = newBox(
        (newPoint3D(-2.0, 1.9, -2.0), newPoint3D(2, 2, 2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(GREEN)))
    ) 
    rwall = newBox(
        (newPoint3D(-2, -2, -2), newPoint3D(2.0, -1.9, 2.0)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(RED)))
    ) 

    box1 = newBox(
        (newPoint3D(-0.5, -1.5, -2), newPoint3D(0.5, -0.9, 0.2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(newColor(0.5, 0.5, 0.5)))), 
        newRotation( 40, axisZ)
    )

    box2 = newBox(
        (newPoint3D(-0.5, 0.9, -2.0), newPoint3D(0.5, 1.5, 0.2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(newColor(0.5, 0.5, 0.5)))), 
        newRotation(-40, axisZ)
    )

    scene = newScene(BLACK, @[room, lamp, lwall, rwall, box1, box2], tkBinary, 1, (pcg.random, pcg.random))
    image = camera.sample(scene, (pcg.random, pcg.random))


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

image.savePFM(fmt"{filename}.pfm")
image.savePNG(fmt"{filename}.png", 0.18, 1.0)

discard execCmd fmt"open {filename}.png"