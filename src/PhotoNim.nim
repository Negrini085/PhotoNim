import PhotoNim/[geometry, hdrimage, camera, shapes, pcg]

import docopt
from nimPNG import savePNG24

from std/os import splitFile
from std/osproc import execCmd
from std/streams import Stream, newFileStream, close
from std/strutils import parseFloat, parseInt
from std/strformat import fmt
from std/math import pow, exp, sin, cos, degToRad
from std/times import cpuTime
import std/cmdline


let PhotoNimVersion = "PhotoNim 0.1"

let PhotoNimDoc = """
Usage:
    ./PhotoNim (-h | --help) --version
    ./PhotoNim help <command>
    ./PhotoNim pfm2png <input> [<output>] [--alpha=<alpha> --gamma=<gamma>]
    ./PhotoNim demo (p | o) [<output>] [--width=<width> --height=<height> --angle=<angle>]
"""

let pfm2pngDoc = """
PhotoNim `pfm2png` command:

Usage: 
    ./PhotoNim pfm2png <input> [<output>] [--alpha=<alpha> --gamma=<gamma>]

Options:
    <input>             Path to the HDRImage to be converted from PFM to PNG. 
    <output>            Path to the LDRImage. [default: "input_dir/" & "input_name" & "alpha_gamma" & ".png"]
    --alpha=<alpha>     Color renormalization factor. [default: 0.18]
    --gamma=<gamma>     Gamma correction factor. [default: 1.0]
"""

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

let renderDoc = """
PhotoNim `render` command:
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


proc demo*(width, height: int, camera: Camera): HdrImage =
    let 
        timeStart = cpuTime()
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
        tracer = ImageTracer(image: newHdrImage(width, height), camera: camera)
        scenary = newWorld()

    scenary.shapes.add(s1); scenary.shapes.add(s2); scenary.shapes.add(s3); scenary.shapes.add(s4); scenary.shapes.add(s5)
    scenary.shapes.add(s6); scenary.shapes.add(s7); scenary.shapes.add(s8); scenary.shapes.add(s9); scenary.shapes.add(s10)

    proc col_pix(tracer: ImageTracer, ray: Ray, scenary: World, x, y: int): Color = 
        for i in 0..<scenary.shapes.len:
            if fastIntersection(scenary.shapes[i], ray): 
                let 
                    r = (1 - exp(-float32(x + y)))
                    g = y / tracer.image.height
                    b = pow((1 - x / tracer.image.width), 2.5)
                return newColor(r, g, b)

    tracer.fire_all_rays(col_pix, scenary)
    echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

    tracer.image


proc main(clp: seq[string]) =
    let args = docopt(PhotoNimDoc, argv=clp, version=PhotoNimVersion)

    if args["help"]:
        let command = $args["<command>"]
        case command
        of "pfm2png": echo pfm2pngDoc
        of "demo": echo demoDoc
        of "render": echo renderDoc
        else: quit fmt"Command `{command}` not found!" & '\n' & PhotoNimDoc 

    elif args["pfm2png"]:
        let fileIn = $args["<input>"]
        var 
            fileOut: string
            alpha = 0.18 
            gamma = 1.0

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

        pfm2png(pfmOut, pngOut, 0.18, 1.0)
        discard execCmd fmt"open {pngOut}"

    else: quit PhotoNimDoc


when isMainModule: 
    main(commandLineParams())