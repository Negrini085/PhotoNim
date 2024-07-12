import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/strutils import parseInt, parseUint
from std/cmdline import commandLineParams
from std/osproc import execCmd


let 
    timeStart = cpuTime()
    
    args = commandLineParams()
    nRays = parseInt(args[0])
    maxDepth = parseInt(args[1])
    rgState = parseUint(args[2])
    rgSeq = parseUint(args[3])

    filename = fmt"examples/cornell/frames/singlesample_{nRays}_{maxDepth}"

    renderer = newPathTracer(nRays, maxDepth)
    camera = newPerspectiveCamera(renderer, viewport = (900, 900), distance = 1.0, newTranslation(newPoint3D(-0.75, 0, 0)))


    room = newBox(
        (newPoint3D(-2, -2, -2), newPoint3D(2, 2, 2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(WHITE)), newUniformPigment(BLACK))
    )    

    lamp = newBox(
        (newPoint3D(0.5, -0.5, 1.8), newPoint3D(1.5, 0.5, 2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(newColor(0.5, 0.5, 0.5))))
    ) 

    lwall = newBox(
        (newPoint3D(-2, 1.9, -2), newPoint3D(2, 2, 2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(GREEN)), newUniformPigment(BLACK))
    ) 
    rwall = newBox(
        (newPoint3D(-2, -2, -2), newPoint3D(2, -1.9, 2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(RED)), newUniformPigment(BLACK))
    ) 

    box1 = newBox(
        (newPoint3D(-0.5, -1.5, -2), newPoint3D(0.5, -0.9, 0.2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(newColor(0.5, 0.5, 0.5))), newUniformPigment(BLACK)), 
        newRotation(40, axisZ)
    )

    box2 = newBox(
        (newPoint3D(-0.5, 0.9, -2), newPoint3D(0.5, 1.5, 0.2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(newColor(0.5, 0.5, 0.5))), newUniformPigment(BLACK)), 
        newRotation(-40, axisZ)
    )


    scene = newScene(@[room, lamp, lwall, rwall, box1, box2])

let image = camera.sample(scene, rgState, rgSeq, samplesPerSide = 1, tkOctonary, maxShapesPerLeaf = 1)


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

image.savePFM(fmt"{filename}.pfm")
image.savePNG(fmt"{filename}.png", 0.18, 1.0)

discard execCmd fmt"open {filename}.png"