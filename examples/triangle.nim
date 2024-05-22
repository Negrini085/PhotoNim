import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/streams import newFileStream, close


let 
    timeStart = cpuTime()
    (width, height) = (1600, 900)
    filePFM = "images/triangle.pfm"

var scenary = newWorld()
scenary.shapes.add(newTriangle(newPoint3D(0.0, 2.0, 3.0), newPoint3D(0.0, -2.0, 2.0), newPoint3D(0.0, -1.0, -1.0)))

var cam = newPerspectiveCamera(width / height, 1.0, newTranslation(newVec3(float32 -3, 0, 0)))
var tracer = newImageTracer(width, height, cam, sideSamples=10)
tracer.fire_all_rays(scenary, proc(ray: Ray): Color = newColor(1.0, 0.0, 1.0))

var stream = newFileStream(filePFM, fmWrite)
stream.writePFM(tracer.image)
stream.close

echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."