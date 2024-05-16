import src/[geometry, camera, shapes, pcg]
export geometry, camera, shapes, pcg

from std/strformat import fmt
from std/os import splitFile
from std/streams import Stream, newFileStream, write, writeLine, readLine, readFloat32, close
from std/strutils import split, parseInt, parseFloat
from std/endians import littleEndian32, bigEndian32
from std/math import sum, pow, exp, log10, sin, cos, degToRad
from std/times import cpuTime

import docopt
from nimPNG import savePNG24


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


proc parseFloat*(stream: Stream; endianness: Endianness = littleEndian): float32 = 
    ## Reads a float from a stream accordingly to the given endianness (default is littleEndian)
    var tmp: float32 = stream.readFloat32
    if endianness == littleEndian: littleEndian32(addr result, addr tmp)
    else: bigEndian32(addr result, addr tmp)

proc writeFloat*(stream: Stream; value: float32, endianness: Endianness = littleEndian) = 
    ## Writes a float to a stream accordingly to the given endianness (default is littleEndian)
    var tmp: float32
    if endianness == littleEndian: littleEndian32(addr tmp, addr value)
    else: bigEndian32(addr tmp, addr value)
    stream.write(tmp)


proc readPFM*(stream: Stream): tuple[img: HdrImage, endian: Endianness] {.raises: [CatchableError].} =
    assert stream.readLine == "PF", "Invalid PFM magic specification: required 'PF'"
    let sizes = stream.readLine.split(" ")
    assert sizes.len == 2, "Invalid image size specification: required 'width height'."

    var width, height: int
    try:
        width = parseInt(sizes[0])
        height = parseInt(sizes[1])
    except:
        raise newException(CatchableError, "Invalid image size specification: required 'width height' as unsigned integers")
    
    try:
        let endianFloat = parseFloat(stream.readLine)
        if endianFloat == 1.0:
            result.endian = bigEndian
        elif endianFloat == -1.0:
            result.endian = littleEndian
        else:
            raise newException(CatchableError, "")
    except:
        raise newException(CatchableError, "Invalid endianness specification: required bigEndian ('1.0') or littleEndian ('-1.0')")

    result.img = newHdrImage(width, height)

    var r, g, b: float32
    for y in countdown(height - 1, 0):
        for x in 0..<width:
            r = parseFloat(stream, result.endian)
            g = parseFloat(stream, result.endian)
            b = parseFloat(stream, result.endian)
            result.img.setPixel(x, y, newColor(r, g, b))


proc writePFM*(stream: Stream; img: HdrImage, endian: Endianness = littleEndian) = 
    stream.writeLine("PF")
    stream.writeLine(img.width, " ", img.height)
    stream.writeLine(if endian == littleEndian: -1.0 else: 1.0)

    var c: Color
    for y in countdown(img.height - 1, 0):
        for x in 0..<img.width:
            c = img.getPixel(x, y)
            stream.writeFloat(c.r, endian)
            stream.writeFloat(c.g, endian)
            stream.writeFloat(c.b, endian)


proc pfm2png*(fileIn, fileOut: string, alpha, gamma: float32) =
    var 
        img: HdrImage
        inFS = newFileStream(fileIn, fmRead)
    try: 
        img = readPFM(inFS).img
    except CatchableError: 
        quit getCurrentExceptionMsg()
    finally:
        inFS.close
   
    img.toneMapping(alpha, gamma)

    var 
        i: int
        pix: Color
        pixelsString = newString(3 * img.pixels.len)

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
    if dim == 0: return newColor(0, 0, 0)
    for i in 0..<dim:
        if fastIntersection(scenary.shapes[i], ray): 
            let 
                r = (1 - exp(-float32(x + y)))
                g = y/im_tr.image.height
                b = pow((1 - x/im_tr.image.width), 2.5)
            return newColor(r, g, b)
    

proc demo*(width, height: int) =
    discard


when isMainModule:

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
            height = 900
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
            a_ratio = width/height
            s1 = newSphere(newPoint3D(0.5, 0.5, 0.5), 0.1)
            s2 = newSphere(newPoint3D(0.5, 0.5, -0.5), 0.1)
            s3 = newSphere(newPoint3D(0.5, -0.5, 0.5), 0.2)
            s4 = newSphere(newPoint3D(0.5, -0.5, -0.5), 0.1)
            s5 = newSphere(newPoint3D(-0.5, 0.5, 0.5), 0.1)
            s6 = newSphere(newPoint3D(-0.5, 0.5, -0.5), 0.1)
            s7 = newSphere(newPoint3D(-0.5, -0.5, 0.5), 0.4)
            s8 = newSphere(newPoint3D(-0.5, -0.5, -0.5), 0.1)
            s9 = newSphere(newPoint3D(-0.5, 0.0, 0.0), 0.3)
            s10 = newSphere(newPoint3D(0.0, 0.5, 0.0), 0.1)   

        var 
            trasl: Translation
            rotz: Rotation
            cam: Camera
            ang: float32 = 10

        if args["--angle"]:
            try: ang = parseFloat($args["--angle"]) 
            except: echo "Warning: angle must be an integer. Default value is used."
        
        rotz = newRotZ(float32(ang))
        trasl = newTranslation(newVec3[float32](-1, 0, 0))
        
        if args["perspective"]:
            cam = newPerspectiveCamera(a_ratio, 1.0, rotz @ trasl)
        else:
            cam = newOrthogonalCamera(a_ratio, rotz @ trasl)

        var
            tracer = ImageTracer(image: newHdrImage(width, height), camera: cam)
            scenary = newWorld()

        scenary.shapes.add(s1); scenary.shapes.add(s2); scenary.shapes.add(s3); scenary.shapes.add(s4); scenary.shapes.add(s5)
        scenary.shapes.add(s6); scenary.shapes.add(s7); scenary.shapes.add(s8); scenary.shapes.add(s9); scenary.shapes.add(s10)

        tracer.fire_all_rays(scenary, col_pix)

        var
            fileOut: string
            pix: Color
            pixelsString = newString(3 * width * height)


        if args["<output>"]: fileOut = $args["<output>"]
        else: fileOut = "demo.png"
        var i: int = 0


        for y in 0..<height:
            for x in 0..<width:
                pix = tracer.image.getPixel(x, y)
                pixelsString[i] = (255 * pix.r).char; i += 1
                pixelsString[i] = (255 * pix.g).char; i += 1
                pixelsString[i] = (255 * pix.b).char; i += 1

        discard savePNG24(fileOut, pixelsString, width, height)
        echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."
        
        
    else: 
        quit "Unknown command. Available commands: pfm2png, demo."