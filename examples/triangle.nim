import PhotoNim

import std/[streams, options]
from std/times import cpuTime
from std/strformat import fmt
from math import pow, exp


let 
    timeStart = cpuTime()
    (width, height) = (1600, 900)
    filePFM = "images/triangle.pfm"

var 
    tracer = ImageTracer(
        image: newHdrImage(width, height), 
        camera: newPerspectiveCamera(width / height, 1.0, newTranslation(newVec3(float32 -3, 0, 0)))
    )
    world = newWorld()

world.shapes.add(newTriangle(newPoint3D(0.0, 2.0, 3.0), newPoint3D(0.0, -2.0, 2.0), newPoint3D(0.0, -1.0, -1.0)))

proc col_pix(tracer: ImageTracer, scenary: World, x, y: int): Color = 
    # Procedure to decide pixel color (it could be useful to check if scenary len is non zero)
    let dim = scenary.shapes.len
    if dim == 0: return newColor(0, 0, 0)
    for i in 0..<dim:
        if fastIntersection(scenary.shapes[i], tracer.fire_ray(x, y)): 
            let 
                r = (1 - exp(-float32(x + y)))
                g = y / tracer.image.height
                b = pow((1 - x / tracer.image.width), 2.5)
            return newColor(r, g, b)

    
tracer.fire_all_rays(world, col_pix)

var stream = newFileStream(filePFM, fmWrite)
stream.writePFM(tracer.image)
echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."