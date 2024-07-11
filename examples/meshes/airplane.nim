import PhotoNim


from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd


let 
    nSamples: int = 1
    aaSamples: int = 1
    directSamples: int = 1
    indirectSamples: int = 1
    depthLimit: int = 1
    rgSetUp = newRandomSetUp(67, 4)
    outFile = "assets/images/examples/meshes/airplane.png"

var 
    rg = newPCG(rgSetUp)
    handlers: seq[ObjectHandler]


let
    room = newBox(
        (newPoint3D(-2, -2, -2), newPoint3D(2, 2, 2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(WHITE)))
    )    

    lwall = newBox(
        (newPoint3D(-2, 1.9, -2), newPoint3D(2, 2, 2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(GREEN)))
    ) 
    rwall = newBox(
        (newPoint3D(-2, -2, -2), newPoint3D(2, -1.9, 2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(RED)))
    ) 

    box1 = newBox(
        (newPoint3D(-0.5, -1.5, -2), newPoint3D(0.5, -0.9, 0.7)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(newColor(0.5, 0.5, 0.5)))), 
        newRotZ(40)
    )

    box2 = newBox(
        (newPoint3D(-0.5, 0.9, -2), newPoint3D(0.5, 1.5, 0.4)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(newColor(0.5, 0.5, 0.5)))), 
        newRotZ(-40)
    )


var timeStart = cpuTime()
let airplane = newMesh(
    source = "assets/meshes/airplane.obj", 
    material = newMaterial(
        newDiffuseBRDF(newUniformPigment(newColor(0.8, 0.6, 0.2))),
        # newCookTorranceBRDF(newUniformPigment(newColor(0.8, 0.6, 0.2)), 0.2, 0.8, 0.7, 1.3, ndfGGX), 
        newUniformPigment(BLACK)
    ),
    transformation = newComposition(
        newTranslation(-eX - 0.5.float32 * eY), 
        newRotZ(30), newRotY(20), newRotX(10), 
        newScaling(2 * 3e-4)
    ), 
    treeKind = tkOctonary, 
    maxShapesPerLeaf = 4, 
    newRandomSetUp(rg.random, rg.random)
)

echo fmt"Successfully loaded mesh in {cpuTime() - timeStart} seconds"
echo fmt"Mesh AABB: {airplane.getAABB}"   
timeStart = cpuTime()

handlers.add room; handlers.add lwall; handlers.add rwall; handlers.add airplane; handlers.add box1; handlers.add box2

for i in 0..<10: 
    for j in 0..<10: 
        handlers.add newPointLight(WHITE, newPoint3D(-0.5 + j / 5, -0.5 + i / 5, 0))
        # newSurfaceLight(WHITE, Shape(kind: skAABox, aabb: (newPoint3D(0.5, -0.5, 1.8), newPoint3D(1.5, 0.5, 2))))

let
    scene = newScene(
        bgColor = BLACK, 
        handlers, 
        newRandomSetUp(rg.random, rg.random), 
        treeKind = tkQuaternary, 
        maxShapesPerLeaf = 3
    )

    camera = newPerspectiveCamera(
        renderer = newPathTracer(directSamples, indirectSamples, depthLimit), 
        viewport = (600, 600), 
        distance = 1.0, 
        transformation = newTranslation(newPoint3D(-0.75, 0, 0))
    )

    image = camera.samples(scene, newRandomSetUp(rg.random, rg.random), nSamples, aaSamples)

echo fmt"Image luminosity {image.avLuminosity}"
echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."   

image.savePNG(outFile, 0.18, 1.0, 0.1)
discard execCmd fmt"open {outFile}"