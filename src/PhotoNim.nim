import PhotoNim/[geometry, hdrimage, camera, shapes]

import docopt
from nimPNG import savePNG24

from std/os import splitFile
from std/streams import Stream, newFileStream, close
from std/strutils import parseFloat, parseInt
from std/strformat import fmt
from std/math import pow, exp
from std/times import cpuTime
import typetraits

let PhotoNimDoc = """PhotoNim: a CPU raytracer written in Nim.

Usage:
    ./PhotoNim pfm2png <input> [<output>] [--alpha=<alpha> --gamma=<gamma>]
    ./PhotoNim demo (perspective|orthogonal) [<output>] [--width=<width> --height=<height> --angle=<angle>]

Options:
    --alpha=<alpha>     Color renormalization factor. [default: 0.18]
    --gamma=<gamma>     Gamma correction factor. [default: 1.0]
    --width=<width>     Image wisth. [default: 1600]
    --height=<height>   Image height. [default: 1000]
    --angle=<angle>     Rotation angle around z axis
    
    -h --help           Show this helper screen.
    --version           Show PhotoNim version.
"""


proc pfm2png(fileIn, fileOut: string, alpha, gamma: float32) =
    var 
        img: HdrImage
        inFS = newFileStream(fileIn, fmRead)
    try: 
        img = readPFM(inFS).img
    except CatchableError: 
        quit getCurrentExceptionMsg()
    finally:
        inFS.close
   
    normalizeImage(img, alpha)
    clampImage(img)

    var 
        i: int
        pix: Color
        pixelsString = newString(3 * img.pixels.len)

    # Gamma compression
    let gFactor = 1 / gamma
    
    for y in 0..<img.height:
        for x in 0..<img.width:
            pix = img.getPixel(x, y)
            pixelsString[i] = (255 * pow(pix.r, gFactor)).char; i += 1
            pixelsString[i] = (255 * pow(pix.g, gFactor)).char; i += 1
            pixelsString[i] = (255 * pow(pix.b, gFactor)).char; i += 1

    discard savePNG24(fileOut, pixelsString, img.width, img.height)
    echo fmt"Successfully converted {fileIn} to {fileOut}"


proc col_pix(im_tr: ImageTracer, ray: Ray, scenary: World, x, y: int): Color = 
    # Procedure to decide pixel color (it could be useful to check if scenary len is non zero)
    let dim = scenary.shapes.len
    if dim == 0:
        return newColor(0, 0, 0)
    
    else:
        for i in 0..<dim:
            if fastIntersection(scenary.get(i), ray): 
                let 
                    r = (1 - exp(-float32(x + y)))
                    g = y/im_tr.image.height
                    b = pow((1 - x/im_tr.image.width), 2.5)
                return newColor(r, g, b)

    

let args = docopt(PhotoNimDoc, version = "PhotoNim 0.1")

#-----------------------------------#
#      Pfm convesion executable     #
#-----------------------------------#
if args["pfm2png"]:
    let fileIn = $args["<input>"]
    var 
        fileOut: string
        alpha, gamma: float

    if args["--alpha"]: 
        try: alpha = parseFloat($args["--alpha"]) 
        except: echo "Warning: alpha flag must be a float. Default value is used."

    if args["--gamma"]: 
        try: gamma = parseFloat($args["--gamma"]) 
        except: echo "Warning: gamma flag must be a float. Default value is used."

    if args["<output>"]: fileOut = $args["<output>"]
    else: 
        let (dir, name, _) = splitFile(fileIn)
        fileOut = dir & '/' & name & "_a" & $alpha & "_g" & $gamma & ".png"
    
    pfm2png(fileIn, fileOut, alpha, gamma)

#-----------------------------#
#       Demo executable       #
#-----------------------------#

elif args["demo"]: 
    var 
        height = 1000
        width = 1600

    if args["--width"]: 
        try: width = parseInt($args["--width"]) 
        except: echo "Warning: width must be an integer. Default value is used."
    
    if args["--height"]: 
        try: height = parseInt($args["--height"]) 
        except: echo "Warning: height must be an integer. Default value is used."

    
    #----------------------------------------------#
    #              Defining scenary                #
    #----------------------------------------------#

    let 
        timeStart = cpuTime()
        a_ratio = float32(width)/float32(height)
        sc = newScaling(0.1)    # Scaling needed in order to have 1/10 radius -> we will compose it with s translation
        s1 = newSphere(newTranslation(newVec3[float32](0.5, 0.5, 0.5)) @ sc)
        s2 = newSphere(newTranslation(newVec3[float32](0.5, 0.5, -0.5)) @ sc)
        s3 = newSphere(newTranslation(newVec3[float32](0.5, -0.5, 0.5)) @ sc)
        s4 = newSphere(newTranslation(newVec3[float32](0.5, -0.5, -0.5)) @ sc)
        s5 = newSphere(newTranslation(newVec3[float32](-0.5, 0.5, 0.5)) @ sc)
        s6 = newSphere(newTranslation(newVec3[float32](-0.5, 0.5, -0.5)) @ sc)
        s7 = newSphere(newTranslation(newVec3[float32](-0.5, -0.5, 0.5)) @ sc)
        s8 = newSphere(newTranslation(newVec3[float32](-0.5, -0.5, -0.5)) @ sc)
        s9 = newSphere(newTranslation(newVec3[float32](-0.5, 0.0, 0.0)) @ sc)
        s10 = newSphere(newTranslation(newVec3[float32](0.0, 0.5, 0.0)) @ sc)   
 
    var 
        image = newHdrImage(width, height)
        rotz: Rotation
        cam: Camera
        ang: int = 10

    if args["--angle"]:
        try: ang = parseInt($args["--angle"]) 
        except: echo "Warning: angle must be an integer. Default value is used."
    
    rotz = newRotZ(float32(ang))
    
    if args["perspective"]:
        cam = newPerspectiveCamera(a_ratio, 2.0, rotz)
    else:
        cam = newOrthogonalCamera(a_ratio, rotz)

    var
        tracer = newImageTracer(image, cam)
        scenary = newWorld()

    scenary.add(s1); scenary.add(s2); scenary.add(s3); scenary.add(s4); scenary.add(s5)
    scenary.add(s6); scenary.add(s7); scenary.add(s8); scenary.add(s9); scenary.add(s10)


    tracer.fire_all_rays(col_pix, scenary)
    image = tracer.image

    var
        fileOut: string
        pix: Color
        pixelsString = newString(3 * width * height)


    if args["<output>"]: fileOut = $args["<output>"]
    else: fileOut = "demo.png"
    var i: int = 0


    for y in 0..<height:
        for x in 0..<width:
            pix = image.getPixel(x, y)
            pixelsString[i] = (255 * pix.r).char; i += 1
            pixelsString[i] = (255 * pix.g).char; i += 1
            pixelsString[i] = (255 * pix.b).char; i += 1

    discard savePNG24(fileOut, pixelsString, width, height)
    echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."
    
    
else: 
    quit "Unknown command. Available commands: pfm2png, demo."