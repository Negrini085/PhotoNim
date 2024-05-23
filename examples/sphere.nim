import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/streams import newFileStream, close


let 
    timeStart = cpuTime()
    (width, height) = (600, 500)
    filePFM = "images/sphere.pfm"

var scenary = newWorld()
scenary.shapes.add(newSphere(newPoint3D(0.0, 0.5, 0.5), radius = 0.5))

var cam = newPerspectiveCamera(width / height, 1.0, newTranslation(newVec3(float32 -1.0, 0, 0)) @ newRotZ(10))
var tracer = newImageTracer(width, height, cam, sideSamples = 4)
tracer.fire_all_rays(scenary, proc(ray: Ray): Color = newColor(1.0, 0.0, 1.0))

var stream = newFileStream(filePFM, fmWrite)
stream.writePFM(tracer.image)
stream.close

echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."