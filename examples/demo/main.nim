import PhotoNim

import docopt

from std/times import cpuTime
from std/strformat import fmt
from std/os import splitFile
from std/osproc import execCmd
from std/cmdline import commandLineParams
from std/strutils import parseInt, parseFloat


let demoDoc* = """
Welcome to `PhotoNim`, run this demo example and start rendering!

Usage: 
        nimble demo (persp | ortho) (OnOff | Flat | Path) [--w=<width> --h=<height> --angle=<angle>] [<output>]

Options:
        persp | ortho          Camera kind: Perspective or Orthogonal
        OnOff | Flat | Path    Renderer kind: OnOff (only shows hit), Flat (flat renderer), Path (path tracer)

        --w=<width>            Image width. [default: 1600]
        --h=<height>           Image height. [default: 900]
        --angle=<angle>        Rotation angle around z axis. [default: 10]

        <output>               Path to the output HDRImage. [default: "examples/demo/demo.pfm"]
"""

proc demoScene*(): Scene =
    let
        s0 = newSphere(center = newPoint3D( 0.5,  0.5,  0.5), radius = 0.1,
            newMaterial(newDiffuseBRDF(), newUniformPigment(newColor(1, 215/255, 0)))
        )

        s1 = newSphere(center = newPoint3D( 0.5,  0.5, -0.5), radius = 0.1,
            newMaterial(newDiffuseBRDF(), newUniformPigment(newColor(1, 0, 0)))
        )

        s2 = newSphere(center = newPoint3D( 0.5, -0.5,  0.5), radius = 0.1,
            newMaterial(newDiffuseBRDF(reflectance = 0), newUniformPigment(newColor(0, 1, 127/255)))
        )

        s3 = newSphere(center = newPoint3D( 0.5, -0.5, -0.5), radius = 0.1,
            newMaterial(newDiffuseBRDF(reflectance = 0), newUniformPigment(newColor(0, 1, 127/255)))
        )

        s4 = newSphere(center = newPoint3D(-0.5,  0.5,  0.5), radius = 0.1,
            newMaterial(newDiffuseBRDF(reflectance = 0), newCheckeredPigment(newColor(1, 0, 0), newColor(0, 1, 0), 2, 4))
        )
        
        s5 = newSphere(center = newPoint3D(-0.5,  0.5, -0.5), radius = 0.1,
            newMaterial(newDiffuseBRDF(reflectance = 0.5), newUniformPigment(newColor(139/255, 0, 139/255)))
        )

        s6 = newSphere(center = newPoint3D(-0.5, -0.5,  0.5), radius = 0.1,
            newMaterial(newDiffuseBRDF(reflectance = 0.5), newUniformPigment(newColor(244/255, 164/255, 96/255)))            
        )

        s7 = newSphere(center = newPoint3D(-0.5, -0.5, -0.5), radius = 0.1,
            newMaterial(newDiffuseBRDF(), newUniformPigment(newColor(244/255, 164/255, 96/255)))   
        )

        s8 = newSphere(center = newPoint3D(-0.5,  0.0,  0.0), radius = 0.1,
            newMaterial(newSpecularBRDF(), newUniformPigment(newColor(0, 0, 128/255)))   
        )            

        s9 = newSphere(center = newPoint3D( 0.0,  0.5,  0.0), radius = 0.1,
            newMaterial(newDiffuseBRDF(reflectance = 1), newUniformPigment(newColor(124/255, 252/255, 0)))   
        )    

    newScene(@[s0, s1, s2, s3, s4, s5, s6, s7, s8, s9])


let args = docopt(demoDoc, argv=commandLineParams())

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
    pfmOut = if args["<output>"]: $args["<output>"] else: "examples/demo/demo.pfm"
    (dir, name, _) = splitFile(pfmOut)
    pngOut = dir & '/' & name & ".png"
    
    renderer = 
        if args["OnOff"]: newOnOffRenderer(hitCol = newColor(1, 215.0 / 255, 0))
        elif args["Flat"]: newFlatRenderer()
        else: newPathTracer(numRays = 9, maxDepth = 1, rouletteLimit = 3)

    camera = 
        if args["persp"]: newPerspectiveCamera(renderer, (width, height), 3.0, newComposition(newRotZ(angle), newTranslation(-eX))) 
        else: newOrthogonalCamera(renderer, (width, height))
    
    timeStart = cpuTime()

    image = camera.sample(demoScene(), rgState = 42, rgSeq = 4, samplesPerSide = 1, maxShapesPerLeaf = 2)

echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."

image.savePFM(pfmOut)
image.savePNG(pngOut, 0.18, 1.0, 0.1)

discard execCmd fmt"open {pngOut}"