import PhotoNim

from std/times import cpuTime
from std/strformat import fmt
from std/streams import newFileStream, close
from std/osproc import execCmd
import std/terminal


proc earthRotation(angle: float32) = 
    let 
        (width, height) = (300, 300)
        filePath = "examples/demo/earth"

    var 
        stream = newFileStream("assets/images/textures/earth.pfm", fmRead)
        texture = try: stream.readPFM.img except: quit fmt"Could not read texture!"

        handler: seq[ShapeHandler]

    handler.add newUnitarySphere(ORIGIN3D, newMaterial(newDiffuseBRDF(), newTexturePigment(texture)))

    var 
        scene = newScene(handler)
        image = newHDRImage(width, height)
        camera = newPerspectiveCamera(width / height, 1.0, newTranslation([float32 -1, 0, 0]) @ newRotZ(angle))
        renderer = newFlatRenderer(addr image, camera)

    image.pixels = renderer.sample(scene, samplesPerSide = 4)

    stream = newFileStream(filePath & "frames/" & fileOut & ".pfm", fmWrite)
    stream.writePFM image
    stream.close

when isMainModule:
    let angle = 
    earthRotation(angle)


execCmd("
seq 0 360 | parallel -j 8 --eta
angleNNN=$(printf "%03d" {1});
./PhotoNim demo persp Flat examples/demo/frames/img${angleNNN}.png --w=400 --h=400 --angle={1}
')


ffmpeg -framerate 30 -i examples/demo/frames/img%03d.png -c:v libx264 -pix_fmt yuv420p examples/demo/demo.mp4
