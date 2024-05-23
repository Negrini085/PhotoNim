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
    (width, height) = (1600, 900)
#--------------------------------------------#
#                 CSG Union                  #
#--------------------------------------------#  

let
    filePFM1 = "images/CSGUnion.pfm"

    # Shapes to add to CSGUnion
    s1 = newSphere(newPoint3D(0, 0, 0), 0.5)
    s2 = newSphere(newPoint3D(0.5, 0, 0), 0.2)
    s3 = newSphere(newPoint3D(-0.5, 0, 0), 0.2)
    s4 = newSphere(newPoint3D(0, 0.5, 0), 0.2)
    s5 = newSphere(newPoint3D(0, -0.5, 0), 0.2)
    s6 = newSphere(newPoint3D(0, 0, 0.5), 0.2)
    s7 = newSphere(newPoint3D(0, 0, -0.5), 0.2)

var 
    cam = newPerspectiveCamera(width / height, 1.0, newTranslation(newVec3(float32 -3, 0, 0)))
    tracer = newImageTracer(width, height, cam, sideSamples=2)
    world = newWorld()
    union = newCSGUnion()

union.shapes.add(s1); union.shapes.add(s2); union.shapes.add(s3);
union.shapes.add(s4); union.shapes.add(s5); union.shapes.add(s6);
union.shapes.add(s7);

world.shapes.add(union);

tracer.fire_all_rays(world, proc(ray: Ray): Color = newColor(1.0, 0.0, 1.0))
var stream = newFileStream(filePFM1, fmWrite)
stream.writePFM(tracer.image); stream.close()
var appo = cpuTime() - timeStart
echo fmt"Successfully rendered CSG Union image in {appo} seconds."

world.shapes = @[]

#--------------------------------------------#
#                 CSG Diff                   #
#--------------------------------------------#
let  
    filePFM2 = "images/CSGDiff.pfm"
    sp1 = newSphere(newPoint3D(0, 0.3, 0), radius = 0.5)
    sp2 = newSphere(newPoint3D(0, -0.3, 0), radius = 0.5)

var diff = newCSGDiff()

diff.shapes.add(sp1); diff.shapes.add(sp2)

world.shapes.add(diff);

tracer.fire_all_rays(world, proc(ray: Ray): Color = newColor(1.0, 0.0, 1.0))
stream = newFileStream(filePFM2, fmWrite)
stream.writePFM(tracer.image); stream.close()


echo fmt"Successfully rendered CSG Union image in {cpuTime()- appo} seconds."
