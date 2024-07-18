## PhotoNim: a CPU Monte Carlo path tracer based on Bounding Volume Hierarchy with kmeans clustering.

const PhotoNimVersion* = "PhotoNim 0.3.1"

import src/[pcg, geometry, color, hdrimage, scene, shape, mesh, csg, material, ray, hitrecord, camera, renderer, lexer, parser]
export pcg, geometry, color, hdrimage, scene, shape, mesh, csg, material, ray, hitrecord, camera, renderer, lexer, parser


from std/streams import newFileStream, close, FileStream
from std/strformat import fmt

const pfm2pngDoc* = """
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
    from std/strutils import parseFloat, parseInt
    from std/cmdline import commandLineParams
    from std/os import splitFile
    from std/options import get, isNone

    let PhotoNimDoc = """PhotoNim: PhotoNim: a CPU raytracer with BVH optimization based on kmeans clustering.

Usage:
    ./PhotoNim help [<command>]
    ./PhotoNim pfm2png <input> [<output>] [--a=<alpha> --g=<gamma> --lum=<avlum>]
    ./PhotoNim rend (OnOff|Flat|Path) <sceneFile> [<output>] [--nR=<numRays> --mD=<maxDepth> --rL=<rouletteLimit> --s=<sampleSide> --mS=<maxShapesPerLeaf>]

Options:
    -h | --help         Display the PhotoNim CLI helper screen.
    --version           Display which PhotoNim version is being used.

    <input>             Path to the HDRImage to be converted from PFM to PNG. 
    <output>            Path to the LDRImage. [default: "input_dir/" & "input_name" & "_a_g" & ".png"]
    --a=<alpha>         Color renormalization factor. [default: 0.18]
    --g=<gamma>         Gamma correction factor. [default: 1.0]
    --lum=<avlum>       Average image luminosity. 

    OnOff | Flat | Path         Choosing renderer: OnOff (only shows hit), Flat (flat renderer) or Path (path tracer)
    <sceneFile>                 File necessary for scene definition
    <output>                    Path for rendering result [default: "input_dir/" & "input_name" & "_a_g" & ".png"]
    --nR=<numRays>              Ray number for path tracer [default: 3]
    --mD=<maxDepth>             Depth for path tracer scattered rays [default: 2]
    --rL=<rouletteLimit>        Roulette limit for path tracer scattere rays [default: 1]
    --s=<sampleSide>            Number of samplesPerSide used in order to reduce aliasing
    --mS=<maxShapesPerLeaf>     Number of max shapes per leaf 
"""

    const rendDoc* = """
PhotoNim CLI `rend` command:

Usage: 
    ./PhotoNim rend (OnOff|Flat|Path) <sceneFile> [<output>] [--nR=<numRays> --mD=<maxDepth> --rL=<rouletteLimit> --s=<sampleSide> --mS=<maxShapesPerLeaf>]

Options:
    OnOff | Flat | Path         Choosing renderer: OnOff (only shows hit), Flat (flat renderer) or Path (path tracer)
    <sceneFile>                 File necessary for scene definition
    <output>                    Path for rendering result [default: "input_dir/" & "input_name" & "_a_g" & ".png"]
    --nR=<numRays>              Ray number for path tracer [default: 3]
    --mD=<maxDepth>             Depth for path tracer scattered rays [default: 2]
    --rL=<rouletteLimit>        Roulette limit for path tracer scattere rays [default: 1]
    --s=<sampleSide>            Number of samplesPerSide used in order to reduce aliasing
    --mS=<maxShapesPerLeaf>     Number of max shapes per leaf 
"""



    let args = docopt(PhotoNimDoc, argv=commandLineParams(), version=PhotoNimVersion)

    if args["help"]:
        if args["<command>"]:
            let command = $args["<command>"]
            if command == "pfm2png": echo pfm2pngDoc
            elif command == "rend": echo rendDoc
            else: quit fmt"Command `{command}` not found!"

        else: echo PhotoNimDoc


    #--------------------------------------------#
    #          pfm to png file conversion        #
    #--------------------------------------------#
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


    #--------------------------------------------#
    #               Scene rendering              #
    #--------------------------------------------#
    elif args["rend"]:
        let fileIn = $args["<sceneFile>"]
        var 
            pcg = newPCG((42.uint64, 1.uint64))
            img: HDRImage
            dSc: DefScene
            rLim: int = 1        
            rend: Renderer
            nSamp: int = 2
            pfmOut: string
            pngOut: string
            nRays: int = 3
            mDepth: int = 2
            mShapes: int = 2
            fStr: FileStream
            inStr: InputStream


        if args["--nR"]: 
            try: nRays = parseInt($args["--nR"]) 
            except: echo fmt"Warning: ray number must be an integer. Default value: <{nRays}> is used."

        if args["--mD"]: 
            try: mDepth = parseInt($args["--mD"]) 
            except: echo fmt"Warning: max ray depth must be an integer. Default value: <{mDepth}> is used."

        if args["--rL"]: 
            try: rLim = parseInt($args["--rL"]) 
            except: echo fmt"Warning: roulette limit must be an integer. Default value: <{rLim}> is used."

        if args["--s"]: 
            try: nSamp = parseInt($args["--s"]) 
            except: echo fmt"Warning: roulette limit must be an integer. Default value: <{nSamp}> is used."

        if args["--mS"]: 
            try: mShapes = parseInt($args["--mS"]) 
            except: echo fmt"Warning: max shapes per leaf must be an integer. Default value: <{mShapes}> is used."

        if args["<output>"]: 
            pngOut = $args["<output>"] & ".png"
            pfmOut = $args["<output>"] & ".pfm"
        else: 
            let (dir, name, _) = splitFile(fileIn)
            pngOut = dir & '/' & name & fmt"_{rend.kind}.png"
            pfmOut = dir & '/' & name & fmt"_{rend.kind}.pfm"
        
        if args["OnOff"]: rend = newOnOffRenderer()
        elif args["Flat"]: rend = newFlatRenderer()
        elif args["Path"]: rend = newPathTracer(nRays, mDepth, rLim)
        
        try:
            fStr = newFileStream(fileIn, fmRead)
        except:
            let msg = "Error in file scenery opening. Check name and path given as input parameter."
            raise newException(CatchableError, msg)

        inStr = newInputStream(fStr, fileIn, 4)
        dSc = inStr.parseDefScene()

        if dSc.camera.isNone:
            let msg = "Camera not defined in: " & fileIn
            raise newException(CatchableError, msg)

        dSc.camera.get.renderer = rend
        
        # Actual rendering proc
        img = dSc.camera.get.sample(scene = newScene(BLACK, dSc.scene, tkBinary, mShapes, newRandomSetup(pcg)), newRandomSetup(pcg), nSamp)

        img.savePFM(pfmOut)
        img.savePNG(pngOut, 0.18, 1.0, 0.1)
        
        let (dir, name, _) = splitFile(fileIn)
        echo "You can find both .pfm and .png images at: " & dir & '/'
