import PhotoNim/[hdrimage, geometry]
import std/[math, os, streams, strutils, strformat]
import docopt
import nimPNG

let PhotoNimDoc = """PhotoNim: a CPU raytracer written in Nim.

Usage:
    ./PhotoNim convert <input> [<output>] [--alpha=<alpha> --gamma=<gamma>]
    
Options:
    --alpha=<alpha>     Color renormalization factor. [default: 0.18]
    --gamma=<gamma>     Gamma correction factor. [default: 1.0]
    
    -h --help           Show this helper screen.
    --version           Show PhotoNim version.
"""


proc convert(fileIn, fileOut: string, alpha, gamma: float32) =
    var 
        img: HdrImage
        fileStream = newFileStream(fileIn, fmRead)
    try: 
        img = readPFM(fileStream)
    except CatchableError: 
        quit getCurrentExceptionMsg()
    finally:
        fileStream.close
   
    normalizeImage(img, alpha)
    clampImage(img)

    var 
        i: int
        pixel: Color
        pixelsString = newString(3 * img.pixels.len)

    let gFactor = 1 / gamma
    for y in 0..<img.height:
        for x in 0..<img.width:
            pixel = img.getPixel(x, y)
            pixelsString[i] = (255 * pow(pixel.r, gFactor)).char; i += 1
            pixelsString[i] = (255 * pow(pixel.g, gFactor)).char; i += 1
            pixelsString[i] = (255 * pow(pixel.b, gFactor)).char; i += 1

    discard savePNG24(fileOut, pixelsString, img.width.int, img.height.int)
    echo fmt"Successfully converted {fileIn} to {fileOut}"


let args = docopt(PhotoNimDoc, version = "PhotoNim 0.1")

if args["convert"]:
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
    
    convert(fileIn, fileOut, alpha, gamma)

elif args["render"]: 
    quit "Not rendering! haahha gimme 5 bucks"
else: 
    quit "Unknown command. Available commands: convert, render."