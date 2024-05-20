import src/[geometry, camera, shapes, pcg]
export geometry, camera, shapes, pcg

from std/strformat import fmt
from std/times import cpuTime

import docopt
from nimPNG import savePNG24

from std/os import splitFile
from std/osproc import execCmd

from std/strutils import split, parseFloat, parseInt
from std/streams import Stream, newFileStream, close, write, writeLine, readLine, readFloat32
from std/endians import littleEndian32, bigEndian32

from std/math import pow, exp, sin, cos, degToRad


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
            r = readFloat(stream, result.endian)
            g = readFloat(stream, result.endian)
            b = readFloat(stream, result.endian)
            result.img.setPixel(x, y, newColor(r, g, b))

proc writePFM*(stream: Stream, img: HdrImage, endian: Endianness = littleEndian) = 
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


let pfm2pngDoc = """
PhotoNim `pfm2png` command:

Usage: 
    ./PhotoNim pfm2png <input> [<output>] [--alpha=<alpha> --gamma=<gamma> --avlum=<avlum>]

Options:
    <input>             Path to the HDRImage to be converted from PFM to PNG. 
    <output>            Path to the LDRImage. [default: "input_dir/" & "input_name" & "alpha_gamma" & ".png"]
    --alpha=<alpha>     Color renormalization factor. [default: 0.18]
    --gamma=<gamma>     Gamma correction factor. [default: 1.0]
    --avlum=<avlum>     Avarage image luminosity given as imput, necessary to render almost totally dark images.
"""

proc pfm2png(fileIn, fileOut: string, alpha, gamma: float32, avlum = 0.0) =
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



let demoDoc = """
PhotoNim `demo` command:

Usage:
    ./PhotoNim demo (p | o) [<output>] [--width=<width> --height=<height> --angle=<angle>]

Options:
    p | o               Camera kind: p for Perspective, o for Orthogonal 
    --width=<width>     Image width. [default: 1600]
    --height=<height>   Image height. [default: 900]
    --angle=<angle>     Rotation angle around z axis. [default: 10]
"""

proc demo*(width, height: int, camera: Camera): HdrImage =
    let 
        timeStart = cpuTime()
        s1 = newSphere(newPoint3D(0.5, 0.5, 0.5), 0.1)
        s2 = newSphere(newPoint3D(0.5, 0.5, -0.5), 0.1)
        s3 = newSphere(newPoint3D(0.5, -0.5, 0.5), 0.1)
        s4 = newSphere(newPoint3D(0.5, -0.5, -0.5), 0.1)
        s5 = newSphere(newPoint3D(-0.5, 0.5, 0.5), 0.1)
        s6 = newSphere(newPoint3D(-0.5, 0.5, -0.5), 0.1)
        s7 = newSphere(newPoint3D(-0.5, -0.5, 0.5), 0.1)
        s8 = newSphere(newPoint3D(-0.5, -0.5, -0.5), 0.1)
        s9 = newSphere(newPoint3D(-0.5, 0.0, 0.0), 0.1)
        s10 = newSphere(newPoint3D(0.0, 0.5, 0.0), 0.1)   

    var 
        tracer = ImageTracer(image: newHdrImage(width, height), camera: camera)
        scenary = newWorld()

    scenary.shapes.add(s1); scenary.shapes.add(s2); scenary.shapes.add(s3); scenary.shapes.add(s4); scenary.shapes.add(s5)
    scenary.shapes.add(s6); scenary.shapes.add(s7); scenary.shapes.add(s8); scenary.shapes.add(s9); scenary.shapes.add(s10)

    proc col_pix(tracer: ImageTracer, ray: Ray, scenary: World, x, y: int): Color = 
        let dim = scenary.shapes.len
        if dim == 0: return newColor(0, 0, 0)
        for i in 0..<dim:
            if fastIntersection(scenary.shapes[i], ray): 
                let 
                    r = (1 - exp(-float32(x + y)))
                    g = y / tracer.image.height
                    b = pow((1 - x / tracer.image.width), 2.5)
                return newColor(r, g, b)

    tracer.fire_all_rays(scenary, col_pix)
    echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

    tracer.image


let PhotoNimVersion = "PhotoNim 0.1"

let PhotoNimDoc = """
Usage:
    ./PhotoNim (-h | --help) --version
    ./PhotoNim help <command>
    ./PhotoNim pfm2png <input> [<output>] [--alpha=<alpha> --gamma=<gamma> --avlum=<avlum>]
    ./PhotoNim demo (p | o) [<output>] [--width=<width> --height=<height> --angle=<angle>]
"""

proc main(clp: seq[string]) =
    let args = docopt(PhotoNimDoc, argv=clp, version=PhotoNimVersion)

    if args["help"]:
        let command = $args["<command>"]
        case command
        of "pfm2png": echo pfm2pngDoc
        of "demo": echo demoDoc
        else: quit fmt"Command `{command}` not found!" & '\n' & PhotoNimDoc 

    elif args["pfm2png"]:
        let fileIn = $args["<input>"]
        var 
            fileOut: string
            alpha = 0.18 
            gamma = 1.0
            avlum = 0.0

        if args["--alpha"]: 
            try: alpha = parseFloat($args["--alpha"]) 
            except: echo "Warning: alpha flag must be a float. Default value is used."

        if args["--gamma"]: 
            try: gamma = parseFloat($args["--gamma"]) 
            except: echo "Warning: gamma flag must be a float. Default value is used."

        if args["--avlum"]: 
            try: avlum = parseFloat($args["--avlum"])
            except: echo "Warning: avlum flag must be a float. Default value is used."

        if args["<output>"]: fileOut = $args["<output>"]
        else: 
            let (dir, name, _) = splitFile(fileIn)
            fileOut = dir & '/' & name & "_a" & $alpha & "_g" & $gamma & ".png"
        
        pfm2png(fileIn, fileOut, alpha, gamma, avlum)


    elif args["demo"]:
        let 
            pfmOut = if args["<output>"]: $args["<output>"] else: "images/demo.pfm"
            (dir, name, _) = splitFile(pfmOut)
            pngOut = dir & '/' & name & ".png"

        var 
            (width, height) = (1600, 900)
            angle = 10.0

        if args["--width"]: 
            try: width = parseInt($args["--width"]) 
            except: echo "Warning: width must be an integer. Default value is used."
        
        if args["--height"]: 
            try: height = parseInt($args["--height"]) 
            except: echo "Warning: height must be an integer. Default value is used."

        if args["--angle"]:
            try: angle = parseFloat($args["--angle"]) 
            except: echo "Warning: angle must be an integer. Default value is used."
            
        let
            a_ratio = width / height
            transf = newTranslation(newVec3(float32 -1, 0, 0)) @ newRotZ(angle)
            camera = if args["p"]: newPerspectiveCamera(a_ratio, 1.0, transf) else: newOrthogonalCamera(a_ratio, transf)

        let stream = newFileStream(pfmOut, fmWrite)    
        stream.writePFM(demo(width, height, camera))
        stream.close

        pfm2png(pfmOut, pngOut, 0.18, 1.0, 0.1)
        discard execCmd fmt"open {pngOut}"

    else: quit PhotoNimDoc


when isMainModule: 
    from std/cmdline import commandLineParams
    main(commandLineParams())


#     import src/[geometry, camera, shapes, pcg]
# export geometry, camera, shapes, pcg

# from std/strformat import fmt
# from std/os import splitFile
# from std/streams import Stream, newFileStream, write, writeLine, readLine, readFloat32, close
# from std/strutils import split, parseInt, parseFloat
# from std/endians import littleEndian32, bigEndian32
# from std/math import sum, pow, exp, log10, sin, cos, degToRad
# from std/times import cpuTime
# import std/options

# import docopt
# from nimPNG import savePNG24