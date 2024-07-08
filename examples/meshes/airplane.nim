import PhotoNim


from std/times import cpuTime
from std/strformat import fmt
from std/osproc import execCmd


let 
    samplesPerSide: int = 1
    numRays: int = 1
    maxDepth: int = 1
    rgState: uint64 = 67
    rgSeq: uint64 = 24
    outFile = "assets/images/examples/meshes/airplane_continue"

var rg = newPCG(rgState, rgSeq)


let 
    room = newBox(
        (newPoint3D(-2, -2, -2), newPoint3D(2, 2, 2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(WHITE)))
    )    

    lamp = newBox(
        (newPoint3D(0.5, -0.5, 1.8), newPoint3D(1.5, 0.5, 2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(newColor(0.5, 0.5, 0.5))), newUniformPigment(WHITE))
    ) 

    lwall = newBox(
        (newPoint3D(-2, 1.9, -2), newPoint3D(2, 2, 2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(GREEN)))
    ) 
    rwall = newBox(
        (newPoint3D(-2, -2, -2), newPoint3D(2, -1.9, 2)), 
        newMaterial(newDiffuseBRDF(newUniformPigment(RED)))
    ) 


var timeStart = cpuTime()
let airplane = newMesh(
    source = "assets/meshes/airplane.obj", 
    material = newMaterial(
        newCookTorranceBRDF(newUniformPigment(newColor(0.8, 0.6, 0.2)), 0.2, 0.8, 0.7, 1.3, ndfGGX), 
        newUniformPigment(newColor(0.8, 0.6, 0.2))
    ),
    transformation = newComposition(
        newTranslation(-eY), 
        newRotZ(30), newRotY(20), newRotX(10), 
        newScaling(2 * 3e-4)
    ), 
    treeKind = tkQuaternary, 
    maxShapesPerLeaf = 4, 
    rg
)

echo fmt"Successfully loaded mesh in {cpuTime() - timeStart} seconds"
echo fmt"Mesh AABB: {airplane.getAABB}"   
timeStart = cpuTime()


let
    scene = newScene(
        bgColor = BLACK, 
        handlers = @[room, lamp, lwall, rwall, airplane], 
        rg, 
        treeKind = tkQuaternary, 
        maxShapesPerLeaf = 2
    )

    camera = newPerspectiveCamera(
        renderer = newPathTracer(numRays, maxDepth), 
        viewport = (600, 600), 
        distance = 1.0, 
        transformation = newTranslation(newPoint3D(-0.75, 0, 0))
    )

    image = camera.sample(scene, rg, samplesPerSide)

echo fmt"Image luminosity {image.avLuminosity}"
echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."   

image.savePNG(outFile & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {outFile}.png"