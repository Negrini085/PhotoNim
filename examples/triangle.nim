import PhotoNim/[hdrimage, geometry, shapes, camera]
from std/times import cpuTime
from std/strformat import fmt
from nimPNG import savePNG24
import std/math


let 
    timeStart = cpuTime()
    (width, height) = (1600, 900)
    fileOut = "examples/triangle.png"

var 
    image = newHdrImage(width, height)
    cam = newPerspectiveCamera(width / height, 1.0, newTranslation(newVec3(float32 -1, 0, 0)))
    tracer = newImageTracer(image, cam)
    world = newWorld()

world.shapes.add(newTriangle(newPoint3D(1.0, 2.0, 3.0), newPoint3D(-1.0, 2.0, -3.0), newPoint3D(-3.0, -2.0, 1.0)))


proc col_pix(im_tr: ImageTracer, ray: Ray, scenary: World, x, y: int): Color = 
    # Procedure to decide pixel color (it could be useful to check if scenary len is non zero)
    let dim = scenary.shapes.len
    if dim == 0:
        return newColor(0, 0, 0)
    
    else:
        for i in 0..<dim:
            if fastIntersection(scenary.shapes[i], ray): 
                let 
                    r = (1 - exp(-float32(x + y)))
                    g = y/im_tr.image.height
                    b = pow((1 - x/im_tr.image.width), 2.5)
                return newColor(r, g, b)
    
tracer.fire_all_rays(world, col_pix)
image = tracer.image

var
    i: int = 0
    pix: Color
    pixelsString = newString(3 * width * height)

for y in 0..<height:
    for x in 0..<width:
        pix = image.getPixel(x, y)
        pixelsString[i] = (255 * pix.r).char; i += 1
        pixelsString[i] = (255 * pix.g).char; i += 1
        pixelsString[i] = (255 * pix.b).char; i += 1

discard savePNG24(fileOut, pixelsString, width, height)
echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."