import PhotoNim

import std/[streams, options]
from std/times import cpuTime
from std/strformat import fmt
from math import sqrt, exp, pow

proc col_pix(im_tr: ImageTracer, ray: Ray, scenary: World, x, y: int): Color = 
    # Procedure to decide pixel color (it could be useful to check if scenary len is non zero)
    let dim = scenary.shapes.len
    if dim == 0: return newColor(0, 0, 0)
    for i in 0..<dim:
        if fastIntersection(scenary.shapes[i], ray): 
            let 
                r = (1 - exp(-float32(x + y)))
                g = y/im_tr.image.height
                b = pow((1 - x/im_tr.image.width), 2.5)
            return newColor(r, g, b)
    

let 
    timeStart = cpuTime()
    (width, height) = (1600, 1000)
    filePFM = "images/csg.pfm"

    # Shapes to add to CSGUnion
    s1 = newSphere(newPoint3D(0, 0, 0), 0.5)
    s2 = newSphere(newPoint3D(0.5, 0, 0), 0.2)
    s3 = newSphere(newPoint3D(-0.5, 0, 0), 0.2)
    s4 = newSphere(newPoint3D(0, 0.5, 0), 0.2)
    s5 = newSphere(newPoint3D(0, -0.5, 0), 0.2)
    s6 = newSphere(newPoint3D(0, 0, 0.5), 0.2)
    s7 = newSphere(newPoint3D(0, 0, -0.5), 0.2)

var 
    tracer = ImageTracer(
        image: newHdrImage(width, height), 
        camera: newPerspectiveCamera(width / height, 1.0, newTranslation(newVec3(float32 -1, 0, 0)))
    )
    world = newWorld()
    union = newCSGUnion()

union.shapes.add(s1); union.shapes.add(s2); union.shapes.add(s3);
union.shapes.add(s4); union.shapes.add(s5); union.shapes.add(s6);
union.shapes.add(s7);

world.shapes.add(union);

tracer.fire_all_rays(world, col_pix)

var stream = newFileStream(filePFM, fmWrite)
stream.writePFM(tracer.image)
echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."