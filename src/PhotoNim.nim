import PhotoNim/[geometry, hdrimage, camera]

import docopt
from nimPNG import savePNG24

from std/os import splitFile
from std/streams import Stream, newFileStream, close
from std/strutils import parseFloat
from std/strformat import fmt
from std/math import pow


let PhotoNimDoc = """PhotoNim: a CPU raytracer written in Nim.

Usage:
    ./PhotoNim pfm2png <input> [<output>] [--alpha=<alpha> --gamma=<gamma>]
    ./PhotoNim demo cam = <camType>

Options:
    --alpha=<alpha>     Color renormalization factor. [default: 0.18]
    --gamma=<gamma>     Gamma correction factor. [default: 1.0]
    
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


let args = docopt(PhotoNimDoc, version = "PhotoNim 0.1")

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

elif args["demo"]: 
    quit "Eh volevi"

else: 
    quit "Unknown command. Available commands: convert, render."