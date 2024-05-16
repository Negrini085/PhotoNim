import PhotoNim

import std/[streams, options]
from std/times import cpuTime
from std/strformat import fmt
from nimPNG import savePNG24


let 
    timeStart = cpuTime()
    (width, height) = (1600, 900)
    filePFM = "images/triangle.pfm"

var 
    cam = newPerspectiveCamera(width / height, 1.0, newTranslation(newVec3(float32 -3, 0, 0)))
    tracer = newImageTracer(newHdrImage(width, height), cam)
    world = newWorld()

world.shapes.add(newTriangle(newPoint3D(2.0, 1.0, 0.0), newPoint3D(0.0, 2.0, 2.0), newPoint3D(0.0, -1.0, -1.0)))


proc col_pix(im_tr: ImageTracer, ray: Ray, scenary: World, x, y: int): Color =
    # Procedure to decide pixel color (it could be useful to check if scenary len is non zero)
    for i in 0..<scenary.shapes.len:
        if rayIntersection(scenary.shapes[i], ray).isSome: 
            return newColor(7, 2, 4)
    
tracer.fire_all_rays(world, col_pix)

var stream = newFileStream(filePFM, fmWrite)
stream.writePFM(tracer.image)
echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."