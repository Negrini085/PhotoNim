let PhotoNimVersion* = "PhotoNim 0.1"

import src/[geometry, camera, shapes, hitrecord, pcg, tracer]
export geometry, camera, shapes, hitrecord, pcg, tracer

from std/times import cpuTime
from std/strformat import fmt

from std/strutils import split, parseFloat, parseInt
from std/streams import Stream, FileStream, newFileStream, close, write, writeLine, readLine, readFloat32
from std/endians import littleEndian32, bigEndian32
from nimPNG import savePNG24

from std/math import pow, exp


proc readFloat*(stream: Stream, endianness: Endianness = littleEndian): float32 = 
    ## Reads a float from a stream accordingly to the given endianness (default is littleEndian)
    var tmp: float32 = stream.readFloat32
    if endianness == littleEndian: littleEndian32(addr result, addr tmp)
    else: bigEndian32(addr result, addr tmp)

proc writeFloat*(stream: Stream, value: float32, endianness: Endianness = littleEndian) = 
    ## Writes a float to a stream accordingly to the given endianness (default is littleEndian)
    var tmp: float32
    if endianness == littleEndian: littleEndian32(addr tmp, addr value)
    else: bigEndian32(addr tmp, addr value)
    stream.write(tmp)


proc readPFM*(stream: FileStream): tuple[img: HdrImage, endian: Endianness] {.raises: [CatchableError].} =
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
            r = readFloat(stream, result.endian)
            g = readFloat(stream, result.endian)
            b = readFloat(stream, result.endian)
            result.img.setPixel(x, y, newColor(r, g, b))

proc writePFM*(stream: FileStream, img: HdrImage, endian: Endianness = littleEndian) = 
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


let pfm2pngDoc* = """
PhotoNim CLI `pfm2png` command:

Usage: 
    ./PhotoNim pfm2png <input> [<output>] [--a=<alpha> --g=<gamma> --lum=<avlum>]

Options:
    <input>             Path to the HDRImage to be converted from PFM to PNG. 
    <output>            Path to the LDRImage. [default: "input_dir/" & "input_name" & "_a_g" & ".png"]
    --a=<alpha>         Color renormalization factor. [default: 0.18]
    --g=<gamma>         Gamma correction factor. [default: 1.0]
    --lum=<avlum>       Average image luminosity. 
"""

proc pfm2png*(fileIn, fileOut: string, alpha, gamma: float32, avlum = 0.0) =
    var 
        img: HdrImage
        inFS = newFileStream(fileIn, fmRead)
    try: 
        img = readPFM(inFS).img
    except CatchableError: 
        quit getCurrentExceptionMsg()
    finally:
        inFS.close
       
    img.toneMapping(alpha, gamma, avlum)

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



let demoDoc* = """
PhotoNim CLI `demo` command:

Usage:
    ./PhotoNim demo (persp | ortho) [<output>] [--w=<width> --h=<height> --angle=<angle>]

Options:
    persp | ortho       Perspective or Orthogonal Camera kinds.
    <output>            Path to the output HDRImage. [default: "assets/images/demo.pfm"]
    --w=<width>         Image width. [default: 1600]
    --h=<height>        Image height. [default: 900]
    --angle=<angle>     Rotation angle around z axis. [default: 10]
"""

proc demo*(width, height: int, camera: Camera): HdrImage =
    let timeStart = cpuTime()

    let
        s0 = newSphere(center = newPoint3D( 0.5,  0.5,  0.5), radius = 0.1)
        s1 = newSphere(center = newPoint3D( 0.5,  0.5, -0.5), radius = 0.1)
        s2 = newSphere(center = newPoint3D( 0.5, -0.5,  0.5), radius = 0.1)
        s3 = newSphere(center = newPoint3D( 0.5, -0.5, -0.5), radius = 0.1)
        s4 = newSphere(center = newPoint3D(-0.5,  0.5,  0.5), radius = 0.1)
        s5 = newSphere(center = newPoint3D(-0.5,  0.5, -0.5), radius = 0.1)
        s6 = newSphere(center = newPoint3D(-0.5, -0.5,  0.5), radius = 0.1)
        s7 = newSphere(center = newPoint3D(-0.5, -0.5, -0.5), radius = 0.1)
        s8 = newSphere(center = newPoint3D(-0.5,  0.0,  0.0), radius = 0.1)
        s9 = newSphere(center = newPoint3D( 0.0,  0.5,  0.0), radius = 0.1)   

    var 
        scenary = World(shapes: @[s0, s1, s2, s3, s4, s5, s6, s7, s8, s9])
        tracer = newImageTracer(width, height, camera, sideSamples = 4)

    tracer.fire_all_rays(scenary, proc(ray: Ray): Color = newColor(0.3, 1.0, 0.2))

    echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

    tracer.image


when isMainModule: 
    import docopt
    from std/cmdline import commandLineParams
    from std/os import splitFile

    let PhotoNimDoc = """PhotoNim: a CPU raytracer written in Nim.

Usage:
    ./PhotoNim help [<command>]
    ./PhotoNim pfm2png <input> [<output>] [--a=<alpha> --g=<gamma> --lum=<avlum>]
    ./PhotoNim demo (persp | ortho) [<output>] [--w=<width> --h=<height> --angle=<angle>]

Options:
    -h | --help         Display the PhotoNim CLI helper screen.
    --version           Display which PhotoNim version is being used.

    --a=<alpha>         Color renormalization factor. [default: 0.18]
    --g=<gamma>         Gamma correction factor. [default: 1.0]
    --lum=<avlum>       Average image luminosity. 

    persp | ortho       Perspective or Orthogonal Camera kinds.
    --w=<width>         Image width. [default: 1600]
    --h=<height>        Image height. [default: 900]
    --angle=<angle>     Rotation angle around z axis. [default: 10]
"""

    let args = docopt(PhotoNimDoc, argv=commandLineParams(), version=PhotoNimVersion)

    if args["help"]:
        if args["<command>"]:
            let command = $args["<command>"]
            case command
            of "pfm2png": echo pfm2pngDoc
            of "demo": echo demoDoc
            else: quit fmt"Command `{command}` not found!"
        else: echo PhotoNimDoc

    elif args["pfm2png"]:
        let fileIn = $args["<input>"]
        var 
            fileOut: string
            alpha = 0.18 
            gamma = 1.0
            avlum = 0.0

        if args["--a"]: 
            try: alpha = parseFloat($args["--a"]) 
            except: echo "Warning: alpha flag must be a float. Default value is used."

        if args["--g"]: 
            try: gamma = parseFloat($args["--g"]) 
            except: echo "Warning: gamma flag must be a float. Default value is used."

        if args["--lum"]: 
            try: avlum = parseFloat($args["--lum"])
            except: echo "Warning: lum flag must be a float. Default value is used."

        if args["<output>"]: fileOut = $args["<output>"]
        else: 
            let (dir, name, _) = splitFile(fileIn)
            fileOut = dir & '/' & name & "_a" & $alpha & "_g" & $gamma & ".png"
        
        pfm2png(fileIn, fileOut, alpha, gamma, avlum)


    elif args["demo"]:
        let 
            pfmOut = if args["<output>"]: $args["<output>"] else: "assets/images/demo.pfm"
            (dir, name, _) = splitFile(pfmOut)
            pngOut = dir & '/' & name & ".png"

        var 
            (width, height) = (1600, 900)
            angle = 10.0

        if args["--w"]: 
            try: width = parseInt($args["--w"]) 
            except: echo "Warning: width must be an integer. Default value is used."
        
        if args["--h"]: 
            try: height = parseInt($args["--h"]) 
            except: echo "Warning: height must be an integer. Default value is used."

        if args["--angle"]:
            try: angle = parseFloat($args["--angle"]) 
            except: echo "Warning: angle must be an integer. Default value is used."
            
        let
            a_ratio = width / height
            transform = newTranslation(newVec3(float32 -1, 0, 0)) @ newRotZ(angle)
            camera = if args["persp"]: newPerspectiveCamera(a_ratio, 1.0, transform) else: newOrthogonalCamera(a_ratio, transform)

        var stream = newFileStream(pfmOut, fmWrite) 
        stream.writePFM(demo(width, height, camera))
        stream.close

        pfm2png(pfmOut, pngOut, 0.18, 1.0, 0.1)

    else: quit PhotoNimDoc