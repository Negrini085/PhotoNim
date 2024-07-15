import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd

proc `+=`(a: var HDRImage, b: HDRImage) =
    for i in 0..<a.width*a.height: a.pixels[i] += b.pixels[i]

let 
    timeStart = cpuTime()
    (width, height) = (900, 600)
    filename = "assets/images/examples/BVH"

var 
    pcam = newPerspectiveCamera(width / height, 1.0, newTranslation(newVec3(-5.0, 0, 0)) @ newRotZ(20) @ newRotY(-10))
    image = newHDRImage(900, 600)
    appo = newHDRImage(900, 600)
    renderer = newOnOffRenderer(addr image, pcam)
    scenery: seq[Shape]
    aabb: seq[Shape]
    

scenery.add newSphere(
    newPoint3D(0.3, -0.5, -0.5), 
    radius = 0.1)
aabb.add getAABox(scenery[0])

scenery.add newSphere(
    newPoint3D(1.0, 1.5, -0.2), 
    radius = 0.5)
aabb.add getAABox(scenery[1])

scenery.add newSphere(
    newPoint3D(-0.5, -1.5, 0.0), 
    radius = 0.2)
aabb.add getAABox(scenery[2])

scenery.add newSphere(
    newPoint3D(0.0, 0.0, 0.0), 
    radius = 0.5)
aabb.add getAABox(scenery[3])

scenery.add newTriangle(
    newPoint3D(0, -1, -1), newPoint3D(-1, 1, 1), newPoint3D(-1, 0, 3), 
    newTranslation(newVec3(0, -3, -3)))
aabb.add getAABox(scenery[4])

scenery.add newTriangle(
    newPoint3D(-2, -1, -1), newPoint3D(-1, 1, 1), newPoint3D(-1, 0, 3), 
    newScaling(3) @ newTranslation(newVec3(0, 1, -2)))
aabb.add getAABox(scenery[5])

scenery.add newCylinder(
    transformation = newTranslation(newVec3(0.0, -2.0, 1.5)))
aabb.add getAABox(scenery[6])

#--------------------------------------#
#           Scene rendering            #
#--------------------------------------#
var scene = newScene(shapes = scenery)
echo "Starting to redender the scene."
scene.render(renderer, maxShapesPerLeaf = 2)
appo = renderer.image[]
scene = newScene(aabb)

renderer = newOnOffRenderer(addr image, pcam, hitCol = newColor(0, 1, 1))
scene.render(renderer, maxShapesPerLeaf = 2)
appo += renderer.image[]
echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."


#---------------------------------------#
#           Image conversion            #
#---------------------------------------#
var stream = newFileStream(filename & ".pfm", fmWrite)
stream.writePFM renderer.image[]
stream.close

pfm2png(filename & ".pfm", filename & ".png", 0.18, 1.0, 0.1)
discard execCmd fmt"open {filename}.png"