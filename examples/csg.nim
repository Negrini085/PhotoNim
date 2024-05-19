import PhotoNim

import std/[streams, options]
from std/times import cpuTime
from std/strformat import fmt
from math import sqrt, exp, pow

let 
    timeStart = cpuTime()
    (width, height) = (1600, 1000)
    filePFM = "images/csg.pfm"

    # Shapes to add to world
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

world.shapes.add(s1); world.shapes.add(s2); world.shapes.add(s3);
world.shapes.add(s4); world.shapes.add(s5); world.shapes.add(s6); 
world.shapes.add(s7);

proc fire_all_union*(tracer: var ImageTracer; scenary: World) = 
    for y in 0..<tracer.image.height:
        for x in 0..<tracer.image.width:

            # Coloring pixel based on wether ray intersects or not
            if unionCSG(world.shapes, tracer.fire_ray(x, y)).isNone:
                tracer.image.setPixel(x, y, newColor(0, 0, 0))
            else:
                let
                    r = (1 - exp(-float32(x + y))) * 255
                    g = y/tracer.image.height * 255
                    b = pow((1 - x / tracer.image.width), 2.5) * 255
                tracer.image.setPixel(x, y, newColor(r, g, b))

tracer.fire_all_union(world)

var stream = newFileStream(filePFM, fmWrite)
stream.writePFM(tracer.image)
echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."