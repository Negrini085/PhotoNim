let PhotoNimVersion* = "PhotoNim 0.2"

import src/[geometry, pcg, hdrimage, scene, material, hitrecord, camera]
export geometry, pcg, hdrimage, scene, material, hitrecord, camera

from std/streams import newFileStream, close
from std/strformat import fmt


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

proc pfm2png*(pfmIN, pngOut: string, alpha, gamma: float32, avLum = 0.0) =
    var fileStream = newFileStream(pfmIN, fmRead)
    
    let image = 
        try: fileStream.readPFM.img
        except CatchableError: quit getCurrentExceptionMsg()
        finally: fileStream.close
       
    image.savePNG(pngOut, alpha, gamma, avLum)   
    echo fmt"Successfully converted {pfmIN} to {pngOut}"


when isMainModule: 
    import docopt
    from std/strutils import parseFloat
    from std/cmdline import commandLineParams
    from std/os import splitFile

    let PhotoNimDoc = """PhotoNim: a CPU raytracer written in Nim.

Usage:
    ./PhotoNim help [<command>]
    ./PhotoNim pfm2png <input> [<output>] [--a=<alpha> --g=<gamma> --lum=<avlum>]

Options:
    -h | --help         Display the PhotoNim CLI helper screen.
    --version           Display which PhotoNim version is being used.

    --a=<alpha>         Color renormalization factor. [default: 0.18]
    --g=<gamma>         Gamma correction factor. [default: 1.0]
    --lum=<avlum>       Average image luminosity. 

    persp | ortho           Perspective or Orthogonal Camera kinds.
    OnOff | Flat            Choosing renderer: OnOff (only shows hit), Flat (flat renderer)
    --w=<width>             Image width. [default: 1600]
    --h=<height>            Image height. [default: 900]
    --angle=<angle>         Rotation angle around z axis. [default: 10]
"""

    let args = docopt(PhotoNimDoc, argv=commandLineParams(), version=PhotoNimVersion)

    if args["help"]:
        if args["<command>"]:
            let command = $args["<command>"]
            if command == "pfm2png": echo pfm2pngDoc
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

    else: quit PhotoNimDoc