import PhotoNim/[hdrimage, geometry, shapes, camera]
import std/[math, streams, options]
from std/times import cpuTime
from std/strformat import fmt
from nimPNG import savePNG24


let 
    timeStart = cpuTime()
    (width, height) = (1600, 900)
    fileOut = "images/triangle.pfm"

var 
    cam = newPerspectiveCamera(width / height, 1.0, newTranslation(newVec3(float32 -2, 0, 0)))
    tracer = newImageTracer(newHdrImage(width, height), cam)
    world = newWorld()

world.shapes.add(newTriangle(newPoint3D(0.0, 1.0, 2.0), newPoint3D(0.0, -1.0, 2.0), newPoint3D(1.0, -1.0, 1.0)))


proc col_pix(im_tr: ImageTracer, ray: Ray, scenary: World, x, y: int): Color = 
    # Procedure to decide pixel color (it could be useful to check if scenary len is non zero)
    let dim = scenary.shapes.len
    if dim == 0:
        return newColor(0, 0, 0)
    
    else:
        for i in 0..<dim:
            if rayIntersection(scenary.shapes[i], ray).isSome: 
                let 
                    r = (1 - exp(-float32(x + y)))
                    g = y/im_tr.image.height
                    b = pow((1 - x/im_tr.image.width), 2.5)
                return newColor(r, g, b)
    
tracer.fire_all_rays(world, col_pix)

var stream = newFileStream(fileOut, fmWrite)
stream.writePFM(tracer.image)

echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."