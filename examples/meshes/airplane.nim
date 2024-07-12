import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd


let 
    nSamples: int = 1
    aaSamples: int = 1
    directSamples: int = 1
    indirectSamples: int = 2
    depthLimit: int = 1
    rgSetUp = newRandomSetUp(67, 4)
    outFile = "assets/images/examples/meshes/airplane.png"

var 
    rg = newPCG(rgSetUp)
    handlers: seq[ObjectHandler]

let 
    uwall = newBox(
        (newPoint3D(-2, -2, 2), newPoint3D(2, 2, 2)), 
        brdf = newDiffuseBRDF(),
        pigment = newUniformPigment(WHITE)
    ) 

    dwall = newBox(
        (newPoint3D(-2, -2, -2), newPoint3D(2, 2, -2)), 
        brdf = newDiffuseBRDF(),
        pigment = newUniformPigment(WHITE)
    ) 

    fwall = newBox(
        (newPoint3D(2, -2, -2), newPoint3D(2, 2, 2)), 
        brdf = newDiffuseBRDF(),
        pigment = newUniformPigment(WHITE)
    ) 

    lwall = newBox(
        (newPoint3D(-2, 2, -2), newPoint3D(2, 2, 2)), 
        brdf = newDiffuseBRDF(),
        pigment = newUniformPigment(GREEN)
    ) 
    rwall = newBox(
        (newPoint3D(-2, -2, -2), newPoint3D(2, -2, 2)), 
        brdf = newDiffuseBRDF(),
        pigment = newUniformPigment(RED)
    ) 

    box1 = newBox(
        (newPoint3D(-0.5, -1.0, -2), newPoint3D(0.5, -0.3, 0.7)), 
        transformation = newComposition(newTranslation(0.5.float32 * eX), newRotZ(40)),
        brdf = newDiffuseBRDF(),
        pigment = newUniformPigment(newColor(0.5, 0.5, 0.5))
    )

    box2 = newBox(
        (newPoint3D(-0.5, 0.9, -2), newPoint3D(0.5, 1.5, 0.4)), 
        transformation = newRotZ(-40),
        brdf = newDiffuseBRDF(),
        pigment = newUniformPigment(newColor(0.5, 0.5, 0.5))
    )


var timeStart = cpuTime()
let airplane = newMesh(
    source = "assets/meshes/airplane.obj", 
    transformation = newComposition(
        newTranslation(-0.3.float32 * eX - eY), 
        newRotZ(30), newRotY(20), newRotX(10), 
        newScaling(2 * 3e-4)
    ), 
    brdf = newDiffuseBRDF(),
    pigment = newUniformPigment(newColor(0.8, 0.6, 0.2)),    
    treeKind = tkQuaternary, 
    maxShapesPerLeaf = 4, 
    newRandomSetUp(rg.random, rg.random)
)

echo fmt"Successfully loaded mesh in {cpuTime() - timeStart} seconds"
echo fmt"Mesh AABB: {airplane.getAABB}"   
timeStart = cpuTime()

handlers.add uwall
handlers.add dwall
handlers.add fwall
handlers.add lwall
handlers.add rwall
handlers.add box1
handlers.add box2
handlers.add airplane

for i in 0..<2: 
    for j in 0..<2: 
        handlers.add newPointLight(WHITE, newPoint3D(-0.5 + i.float32, -0.5 + j.float32, 2))
# handlers.add newPointLight(WHITE, newPoint3D(0, 0, 1.999))
        # newSurfaceLight(WHITE, Shape(kind: skAABox, aabb: (newPoint3D(0.5, -0.5, 1.8), newPoint3D(1.5, 0.5, 2))))

let
    scene = newScene(
        bgColor = BLACK, 
        handlers = handlers, 
        newRandomSetUp(rg.random, rg.random), 
        treeKind = tkBinary, 
        maxShapesPerLeaf = 1
    )

    camera = newPerspectiveCamera(
        # renderer = newFlatRenderer(), 
        renderer = newPathTracer(directSamples, indirectSamples, depthLimit), 
        viewport = (600, 600), 
        distance = 1.0, 
        transformation = newTranslation(newPoint3D(-1.0, 0, 0))
    )

    image = camera.samples(scene, newRandomSetUp(rg.random, rg.random), nSamples, aaSamples)


echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."   

image.savePNG(outFile & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {outFile}.png"