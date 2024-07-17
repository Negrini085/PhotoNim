import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/strutils import parseInt, parseUint
from std/cmdline import commandLineParams


var rg = newPCG((42.uint64, 1.uint64))


let 
    timeStart = cpuTime()
    args = commandLineParams()

    nRays = parseInt(args[0])
    maxDepth = parseInt(args[1])

    filename = fmt"examples/cornell/frames/singlesample_{nRays * nRays}_{maxDepth}"

    camera = newPerspectiveCamera(
        renderer = newPathTracer(nRays * nRays, maxDepth, maxDepth + 1), 
        viewport = (600, 600), distance = 1.0, 
        transformation = newTranslation(newPoint3D(-1, 0, 0))
    )

    lamp = newBox(
        (newPoint3D(0.5, -0.5, 1.9), newPoint3D(1.5, 0.5, 1.999)), 
        newEmissiveMaterial(
            newDiffuseBRDF(newUniformPigment(WHITE)),
            emittedRadiance = newUniformPigment(10 * WHITE)
        )
    ) 

    uwall = newBox(
        (newPoint3D(-2, -2, 2), newPoint3D(2, 2, 2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(WHITE)))
    ) 

    dwall = newBox(
        (newPoint3D(-2, -2, -2), newPoint3D(2, 2, -2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(WHITE)))
    ) 

    fwall = newBox(
        (newPoint3D(2, -2, -2), newPoint3D(2, 2, 2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(WHITE)))
    ) 

    lwall = newBox(
        (newPoint3D(-2, 2, -2), newPoint3D(2, 2, 2)), 
        newEmissiveMaterial(
            newDiffuseBRDF(newUniformPigment(GREEN)),
            emittedRadiance = newUniformPigment(0.2 * GREEN)
        )
    ) 

    rwall = newBox(
        (newPoint3D(-2, -2, -2), newPoint3D(2, -2, 2)), 
        newEmissiveMaterial(
            newDiffuseBRDF(newUniformPigment(RED)),
            emittedRadiance = newUniformPigment(0.2 * RED)
        )
    ) 

    sphere = newSphere(
        newPoint3D(0.0, 0.5, -1.0), 0.5,
        newMaterial(newSpecularBRDF(newUniformPigment(WHITE)))
    )

    airplane = newMesh(
        source = "assets/meshes/airplane.obj", 
        treeKind = tkOctonary, 
        maxShapesPerLeaf = 4, 
        newRandomSetUp(rg),
        newEmissiveMaterial(
            newDiffuseBRDF(newUniformPigment(newColor(0.8, 0.6, 0.2))),
            newUniformPigment(0.2 * newColor(0.8, 0.6, 0.2))
        ),
        transformation = newComposition(
            newTranslation(- 0.3 * eX - 0.5 * eY - 0.3 * eZ), 
            newRotation(30, axisZ), newRotation(20, axisY), newRotation(10, axisX), 
            newScaling(0.5e-3)
        )
    )

    scene = newScene(
        bgColor = BLACK, 
        handlers = @[fwall, lwall, rwall, uwall, dwall, lamp, sphere, airplane], 
        treeKind = tkQuaternary, 
        maxShapesPerLeaf = 2,
        newRandomSetUp(rg)
    )

    image = camera.sample(scene, newRandomSetUp(rg), aaSamples = 1)


echo fmt"Successfully rendered image with {nRays} rays of depth {maxDepth} in {cpuTime() - timeStart} seconds."

image.savePNG(fmt"{filename}.png", 0.18, 1.0)