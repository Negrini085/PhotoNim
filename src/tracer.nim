import geometry, camera, shapes, pcg, hitrecord

import std/options
import std/terminal
import std/strutils
from std/strformat import fmt

type ImageTracer* = object
    image*: HdrImage
    camera*: Camera
    sideSamples: int
    rg: PCG


proc newImageTracer*(width, height: int, camera: Camera, sideSamples = 4, randomGenerator = newPCG()): ImageTracer {.inline.} =
    ImageTracer(image: newHdrImage(width, height), camera: camera, sideSamples: sideSamples, rg: randomGenerator)


proc fire_ray*(tracer: ImageTracer; x, y: int, pixel = newPoint2D(0.5, 0.5)): Ray {.inline.} =   
    tracer.camera.fire_ray(newPoint2D((x.float32 + pixel.u) / tracer.image.width.float32, 1 - (y.float32 + pixel.v) / tracer.image.height.float32))


proc displayProgress(current, total: int) =
    let
        percentage = int(100 * current / total)
        progress = 50 * current div total
        bar = "[" & "#".repeat(progress) & "-".repeat(50 - progress) & "]"
        color = if percentage <= 50: fgYellow else: fgGreen

    stdout.eraseLine
    stdout.styledWrite(fgRed, "0% ", fgWhite, bar, color, fmt" {percentage}%")
    stdout.flushFile

proc fire_all_rays*(tracer: var ImageTracer; scenary: World, color_map: proc(ray: Ray): Color) = 
    for y in 0..<tracer.image.height:
        for x in 0..<tracer.image.width:
            if tracer.sideSamples > 0:
                var color = BLACK

                for u in 0..<tracer.sideSamples:
                    for v in 0..<tracer.sideSamples:
                        let 
                            pixelOffset = newPoint2D(
                                (u.float32 + tracer.rg.rand) / tracer.sideSamples.float32, 
                                (v.float32 + tracer.rg.rand) / tracer.sideSamples.float32
                            )

                            ray = tracer.fire_ray(x, y, pixelOffset)
                                                
                        for i in 0..<scenary.shapes.len:
                            let hit = rayIntersection(scenary.shapes[i], ray)
                            if hit.isSome: 
                                color += color_map(ray)

                tracer.image.setPixel(x, y, color / (tracer.sideSamples * tracer.sideSamples).float32)

            else:
                tracer.image.setPixel(x, y, color_map(tracer.fire_ray(x, y)))

        displayProgress(y + 1, tracer.image.height)
    
    stdout.eraseLine
    stdout.resetAttributes


type 
    RendererKind* = enum 
        OnOffRenderer, FlatRenderer, PathTracer
    
    Renderer* = object 
        world*: World
        back_col*: Color

        case kind*: RendererKind
        of FlatRenderer, PathTracer: discard 
        of OnOffRenderer:
            col_hit: Color
