import PhotoNim

from std/cmdline import commandLineParams
from std/strutils import parseInt
from std/strformat import fmt


let
    angle = parseInt(commandLineParams()[0])

    camera = newPerspectiveCamera(
        renderer = newPathTracer(4, 1),
        viewport = (600, 600), 
        distance = 1.0, 
        transformation = newComposition(newRotZ(angle), newTranslation(- 2.0.float32 * eX))
    ) 

    earthTexture = newTexturePigment("assets/textures/earth.pfm")

    earth = newUnitarySphere(ORIGIN3D, newMaterial(newDiffuseBRDF(earthTexture), earthTexture))
    scene = newScene(@[earth])
    image = camera.sample(scene, rgState = 42, rgSeq = 5, samplesPerSide = 4, maxShapesPerLeaf = 1, displayProgress = false)

image.savePNG(fmt"examples/earth/frames/img{angle:03}.png", 0.18, 1.0, 0.1)