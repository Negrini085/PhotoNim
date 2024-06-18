let PhotoNimVersion* = "PhotoNim 0.1"

import src/[geometry, pcg, hdrimage, scene, material, hitrecord, camera]
export geometry, pcg, hdrimage, scene, material, hitrecord, camera

from std/math import pow, exp
from std/strutils import parseFloat, parseInt, split
from std/streams import Stream, FileStream, newFileStream, close, write, writeLine, readLine, readFloat32
from std/times import cpuTime
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
       
    try: image.savePNG(pngOut, alpha, gamma, avLum)
    except CatchableError: quit getCurrentExceptionMsg()     
    
    echo fmt"Successfully converted {pfmIN} to {pngOut}"


let demoDoc* = """
PhotoNim CLI `demo` command:

Usage:
    ./PhotoNim demo (persp | ortho) (OnOff | Flat) [<output>] [--w=<width> --h=<height> --angle=<angle>]

Options:
    persp | ortho           Perspective or Orthogonal Camera kinds.
    OnOff | Flat            Choosing renderer: OnOff (only shows hit), Flat (flat renderer)
    <output>                Path to the output HDRImage. [default: "assets/images/demo.pfm"]
    --w=<width>             Image width. [default: 1600]
    --h=<height>            Image height. [default: 900]
    --angle=<angle>         Rotation angle around z axis. [default: 10]
"""

proc demo*(camera: Camera, pfmOut, pngOut: string) =
    let timeStart = cpuTime()

    let
        s0 = newSphere(
            center = newPoint3D( 0.5,  0.5,  0.5), radius = 0.1,
            newMaterial(newDiffuseBRDF(), newUniformPigment(newColor(1, 215/255, 0)))
            )

        s1 = newSphere(
            center = newPoint3D( 0.5,  0.5, -0.5), radius = 0.1,
            newMaterial(newDiffuseBRDF(), newUniformPigment(newColor(1, 0, 0)))
            )

        s2 = newSphere(
            center = newPoint3D( 0.5, -0.5,  0.5), radius = 0.1,
            newMaterial(newDiffuseBRDF(reflectance = 0), 
                    newUniformPigment(newColor(0, 1, 127/255))
                )
            )

        s3 = newSphere(
            center = newPoint3D( 0.5, -0.5, -0.5), radius = 0.1,
            newMaterial(newDiffuseBRDF(reflectance = 0), 
                    newUniformPigment(newColor(0, 1, 127/255))
                )
            )

        s4 = newSphere(
            center = newPoint3D(-0.5,  0.5,  0.5), radius = 0.1,
            newMaterial(newDiffuseBRDF(reflectance = 0), 
                    newCheckeredPigment(newColor(1, 0, 0), newColor(0, 1, 0), 2, 4)
                )
            )
        
        s5 = newSphere(
            center = newPoint3D(-0.5,  0.5, -0.5), radius = 0.1,
            newMaterial(newDiffuseBRDF(reflectance = 0.5), 
                    newUniformPigment(newColor(139/255, 0, 139/255))
                )
        )

        s6 = newSphere(
            center = newPoint3D(-0.5, -0.5,  0.5), radius = 0.1,
            newMaterial(newDiffuseBRDF(reflectance = 0.5), 
                    newUniformPigment(newColor(244/255, 164/255, 96/255))
                )            
            )

        s7 = newSphere(
            center = newPoint3D(-0.5, -0.5, -0.5), radius = 0.1,
            newMaterial(newDiffuseBRDF(), 
                    newUniformPigment(newColor(244/255, 164/255, 96/255))
                )   
            )

        s8 = newSphere(
            center = newPoint3D(-0.5,  0.0,  0.0), radius = 0.1,
            newMaterial(newSpecularBRDF(), 
                    newUniformPigment(newColor(0, 0, 128/255))
                )   
            )            

        s9 = newSphere(
            center = newPoint3D( 0.0,  0.5,  0.0), radius = 0.1,
            newMaterial(newDiffuseBRDF(reflectance = 1), 
                    newUniformPigment(newColor(124/255, 252/255, 0))
                )   
            )                

    let 
        scene = newScene(@[s0, s1, s2, s3, s4, s5, s6, s7, s8, s9])
        image = camera.sample(scene, rgState = 42, rgSeq = 4, samplesPerSide = 1, maxShapesPerLeaf = 2)

    echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."
    
    image.savePFM(pfmOut)
    image.savePNG(pngOut, 0.18, 1.0, 0.1)


when isMainModule: 
    import docopt
    from std/cmdline import commandLineParams
    from std/os import splitFile

    let PhotoNimDoc = """PhotoNim: a CPU raytracer written in Nim.

Usage:
    ./PhotoNim help [<command>]
    ./PhotoNim pfm2png <input> [<output>] [--a=<alpha> --g=<gamma> --lum=<avlum>]
    ./PhotoNim demo (persp | ortho) (OnOff | Flat | Path) [<output>] [--w=<width> --h=<height> --angle=<angle>]
    ./PhotoNim earth [<output>] [--w=<width> --h=<height> --angle=<angle>]

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
            renderer = 
                if args["OnOff"]: newOnOffRenderer(hitCol = newColor(1, 215.0 / 255, 0))
                elif args["Flat"]: newFlatRenderer()
                else: newPathTracer(numRays = 9, maxDepth = 1, rouletteLimit = 3)

            camera = 
                if args["persp"]: newPerspectiveCamera(renderer, (width, height), 3.0, newComposition(newRotZ(angle), newTranslation(-eX))) 
                else: newOrthogonalCamera(renderer, (width, height))
    

        demo(camera, pfmOut, pngOut)


    elif args["earth"]:
        let 
            pfmOut = if args["<output>"]: $args["<output>"] else: "assets/images/earth.pfm"
            (dir, name, _) = splitFile(pfmOut)
            pngOut = dir & '/' & name & ".png"

        var 
            (width, height) = (600, 600)
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
            
            
        let camera = newPerspectiveCamera(newFlatRenderer(), viewport = (width, height), distance = 1.0, newComposition(newRotZ(angle), newTranslation(-eZ))) 

        var stream = newFileStream("assets/images/textures/earth.pfm", fmRead)
            
        let
            texture = try: stream.readPFM.img except: quit fmt"Could not read texture!" finally: stream.close
            scene = newScene(@[newUnitarySphere(ORIGIN3D, newMaterial(newDiffuseBRDF(newTexturePigment(texture)), newTexturePigment(texture)))])
            image = camera.sample(scene, rgState = 42, rgSeq = 4, samplesPerSide = 2, maxShapesPerLeaf = 4)
        
        image.savePFM(pfmOut)
        image.savePNG(pngOut, 0.18, 1.0, 0.1)


    else: quit PhotoNimDoc