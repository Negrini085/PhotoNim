import PhotoNim/[color, hdrimage]
import std/[streams, strutils, math]
import docopt
import nimPNG


let doc = """
PhotoNim, a simple CPU raytracer written in Nim.

Usage: 
    ./PhotoNim convert <HDR> <LDR> [--alpha=<alpha> --gamma=<gamma>]

Options:
    --alpha=<alpha>     Color renormalization factor [default: 0.18]
    --gamma=<gamma>     LDR factor [default: 1.0]
    -h --help     
    --version     
"""


let args = docopt(doc, version = "PhotoNim 0.1")

if args["convert"]:
    let 
        fileIn = $args["<HDR>"]
        fileOut = $args["<LDR>"]

    var alpha, gamma: float32
    if args["--alpha"]: 
        try: alpha = parseFloat($args["--alpha"]) 
        except: echo "Warning: alpha flag must be a float. Default value is used."

    if args["--gamma"]: 
        try: gamma = parseFloat($args["--gamma"]) 
        except: echo "Warning: gamma flag must be a float. Default value is used."

    echo "Converting an HDRImage to a LDRImage."

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


elif args["render"]:
    quit "toDO"

else: 
    quit "No other commands are availables!"