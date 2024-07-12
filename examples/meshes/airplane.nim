import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd


let 
    nSamples: int = 1
    aaSamples: int = 1
    nRays: int = 10
    depthLimit: int = 1
    rrLimit: int = 3
    rgSetUp = newRandomSetUp(67, 4)
    outFile = "assets/images/examples/meshes/airplane.png"

var 
    rg = newPCG(rgSetUp)
    handlers: seq[ObjectHandler]

let 
    lamp = newBox(
        (newPoint3D(0.5, -0.5, 1.9), newPoint3D(1.5, 0.5, 1.999)), 
        brdf = nil,
        emittedRadiance = newUniformPigment(BLUE)
    ) 

    uwall = newBox(
        (newPoint3D(-2, -2, 2), newPoint3D(2, 2, 2)), 
        brdf = newDiffuseBRDF(newUniformPigment(WHITE)),
        # emittedRadiance = newUniformPigment(BLUE)
    ) 

    dwall = newBox(
        (newPoint3D(-2, -2, -2), newPoint3D(2, 2, -2)), 
        brdf = newDiffuseBRDF(newUniformPigment(WHITE)),
        # emittedRadiance = newUniformPigment(GREEN)
    ) 

    fwall = newBox(
        (newPoint3D(2, -2, -2), newPoint3D(2, 2, 2)), 
        brdf = newDiffuseBRDF(newUniformPigment(WHITE)),
        # emittedRadiance = newUniformPigment(BLUE)
    ) 

    lwall = newBox(
        (newPoint3D(-2, 2, -2), newPoint3D(2, 2, 2)), 
        brdf = newDiffuseBRDF(newUniformPigment(GREEN)),
        # emittedRadiance = newUniformPigment(BLUE)
    ) 

    rwall = newBox(
        (newPoint3D(-2, -2, -2), newPoint3D(2, -2, 2)), 
        brdf = newDiffuseBRDF(newUniformPigment(RED)),
        # emittedRadiance = newUniformPigment(BLUE)
    ) 


    box1 = newBox(
        (newPoint3D(-0.5, -1.0, -2), newPoint3D(0.5, -0.3, 0.7)), 
        transformation = newComposition(newTranslation(0.5.float32 * eX), newRotation(40, axisZ)),
        brdf = newDiffuseBRDF(newUniformPigment(newColor(0.5, 0.5, 0.5))),
    )

    box2 = newBox(
        (newPoint3D(-0.5, 0.9, -2), newPoint3D(0.5, 1.5, 0.4)), 
        transformation = newRotation(-40, axisZ),
        brdf = newDiffuseBRDF(newUniformPigment(newColor(0.5, 0.5, 0.5))),
    )


var timeStart = cpuTime()
let airplane = newMesh(
    source = "assets/meshes/airplane.obj", 
    treeKind = tkQuaternary, 
    maxShapesPerLeaf = 4, 
    newRandomSetUp(rg.random, rg.random),
    brdf = newDiffuseBRDF(newUniformPigment(WHITE)),
    transformation = newComposition(
        newTranslation(-0.3.float32 * eX - eY), 
        newRotation(30, axisZ), newRotation(20, axisY), newRotation(10, axisX), 
        newScaling(2 * 3e-4)
    )
)

echo fmt"Successfully loaded mesh in {cpuTime() - timeStart} seconds"
echo fmt"Mesh AABB: {airplane.getAABB}"   
timeStart = cpuTime()

handlers.add lamp
handlers.add uwall
handlers.add dwall
handlers.add fwall
handlers.add lwall
handlers.add rwall
handlers.add box1
handlers.add box2
handlers.add airplane


let
    scene = newScene(
        bgColor = BLACK, 
        handlers = handlers, 
        treeKind = tkBinary, 
        maxShapesPerLeaf = 3,
        newRandomSetUp(rg.random, rg.random)
    )

    camera = newPerspectiveCamera(
        renderer = newPathTracer(nRays, depthLimit, rrLimit), 
        viewport = (600, 600), 
        distance = 1.0, 
        transformation = newTranslation(newPoint3D(-1.0, 0.0, 0.2))
    )

    image = camera.samples(scene, newRandomSetUp(rg.random, rg.random), nSamples, aaSamples)


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."   

image.savePNG(outFile & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {outFile}.png"