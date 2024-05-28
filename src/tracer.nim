import geometry, camera, shapes, bvh, pcg, hitrecord

import std/terminal
import std/strutils
from std/strformat import fmt


type 
    World* = object
        shapes*: seq[Shape]
        meshes*: seq[Mesh]

proc newWorld*(): World {.inline.} = World(shapes: @[], meshes: @[])

proc loadMesh*(world: World, source: string) = quit "to implement"
proc loadTexture*(world: World, source: string, shape: Shape) = quit "to implement"

proc getAllShapes*(world: World): seq[Shape] =
    result = world.shapes
    for mesh in world.meshes: 
        for element in mesh.items: result.add element


type ImageTracer* = object
    image*: HdrImage
    camera*: Camera
    samplesPerSide: int
    rg: PCG


proc newImageTracer*(width, height: int, camera: Camera, samplesPerSide = 4, randomGenerator = newPCG()): ImageTracer {.inline.} =
    ImageTracer(image: newHDRImage(width, height), camera: camera, samplesPerSide: samplesPerSide, rg: randomGenerator)


proc fireRay*(tracer: ImageTracer; x, y: int, pixel = newPoint2D(0.5, 0.5)): Ray {.inline.} =   
    tracer.camera.fireRay(newPoint2D((x.float32 + pixel.u) / tracer.image.width.float32, 1 - (y.float32 + pixel.v) / tracer.image.height.float32))


proc displayProgress(current, total: int) =
    let
        percentage = int(100 * current / total)
        progress = 50 * current div total
        bar = "[" & "#".repeat(progress) & "-".repeat(50 - progress) & "]"
        color = if percentage <= 50: fgYellow else: fgGreen

    stdout.eraseLine
    stdout.styledWrite(fgWhite, "Rendering progress: ", fgRed, "0% ", fgWhite, bar, color, fmt" {percentage}%")
    stdout.flushFile

proc fireAllRays*(tracer: var ImageTracer; scenery: World, color_map: proc(ray: Ray): Color) =
    let shapes = scenery.getAllShapes
    var 
        BVH = newSceneTree(shapes, 4)
        pixelOffset: Point2D
        ray: Ray

    for y in 0..<tracer.image.height:
        for x in 0..<tracer.image.width:
            if tracer.samplesPerSide > 0:
                var color = BLACK
                for u in 0..<tracer.samplesPerSide:
                    for v in 0..<tracer.samplesPerSide:
                        
                        pixelOffset = newPoint2D(
                            (u.float32 + tracer.rg.rand) / tracer.samplesPerSide.float32, 
                            (v.float32 + tracer.rg.rand) / tracer.samplesPerSide.float32
                        )

                        ray = tracer.fireRay(x, y, pixelOffset)
                    
                        # if fastIntersection(newAABox(BVH.root.aabb), ray): color += newColor(0.3, 0, 0)
                        # if BVH.root.left != nil and fastIntersection(newAABox(BVH.root.left.aabb.min, BVH.root.left.aabb.max), ray): color += newColor(0, 0.3, 0)
                        # if BVH.root.right != nil and fastIntersection(newAABox(BVH.root.right.aabb.min, BVH.root.right.aabb.max), ray): color += newColor(0, 0, 0.3)

                        for i in 0..<shapes.len:
                            if fastIntersection(shapes[i].getWorldAABox, ray): color += color_map(ray)
                            # if fastIntersection(shapes[i], ray): color += WHITE

                        if fastIntersection(BVH.root, ray): color += WHITE

                tracer.image.setPixel(x, y, color / (tracer.samplesPerSide * tracer.samplesPerSide).float32)

            else:
                tracer.image.setPixel(x, y, color_map(tracer.fireRay(x, y)))

        displayProgress(y + 1, tracer.image.height)
    
    stdout.eraseLine
    stdout.resetAttributes