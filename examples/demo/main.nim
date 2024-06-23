import PhotoNim

import docopt

from std/times import cpuTime
from std/strformat import fmt
from std/cmdline import commandLineParams
from std/strutils import parseInt, parseFloat


let demoDoc* = """
Welcome to `PhotoNim`, run this demo example and start rendering!

Usage: 
        nimble demo (persp | ortho) (OnOff | Flat | Path) [<angle>] [<output>] [<width> <height>]

Options:
        persp | ortho          Camera kind: Perspective or Orthogonal

        OnOff | Flat | Path    Renderer kind: OnOff (only shows hit), Flat (flat renderer), Path (path tracer)

        <angle>                Rotation angle around z axis. [default: 10.0]

        <output>               Path to the LDRImage output. [default: "examples/demo/demo.png"]

        <width>                Image width. [default: 900]
        <height>               Image height. [default: 900]
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


let 
    args = docopt(demoDoc, argv=commandLineParams())

    width = if args["<width>"]: parseInt($args["<width>"]) else: 900
    height = if args["<height>"]: parseInt($args["<height>"]) else: 900

    renderer = 
        if args["OnOff"]: newOnOffRenderer(hitCol = newColor(1, 215.0 / 255, 0))
        elif args["Flat"]: newFlatRenderer()
        else: newPathTracer(numRays = 5, maxDepth = 5, rouletteLimit = 3)

    angle = if args["<angle>"]: parseFloat($args["<angle>"]) else: 10    

    pngOut = if args["<output>"]: $args["<output>"] else: "examples/demo/demo.png"

    camera = 
        if args["persp"]: newPerspectiveCamera(renderer, (width, height), 1.0, newComposition(newRotZ(angle), newTranslation(-eX))) 
        else: newOrthogonalCamera(renderer, (width, height), newRotZ(angle))
        
    timeStart = cpuTime()
    image = camera.sample(demoScene(), rgState = 42, rgSeq = 4, samplesPerSide = 2, maxShapesPerLeaf = 3)

echo fmt"Successfully rendered image in {cpuTime() - timeStart:.6f} seconds."

image.savePNG(pngOut, 0.18, 1.0, 0.1)
echo fmt"Successfully saved image to {pngOut}."
