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
        of FlatRenderer: discard 

        of OnOffRenderer:
            hit_col*: Color

        of PathTracer:
            randgen*: PCG
            num_ray*: int
            max_depth*: int
            roulette_lim*: int


proc newOnOffRenderer*(world = newWorld(), back_col = newColor(0,0,0), hit_col = newColor(1,1,1)): Renderer {.inline.} =
    Renderer(kind: OnOffRenderer, world: world, back_col: back_col, hit_col: hit_col)

proc newFlatRenderer*(world = newWorld(), back_col = newColor(0,0,0)): Renderer {.inline.} =
    Renderer(kind: FlatRenderer, world: world, back_col: back_col)

proc newPathTracer*(world = newWorld(), back_col = newColor(0,0,0), randgen = newPCG(), n_ray = 10, max_depth = 10, roulette_lim = 3): Renderer {.inline.} =
    Renderer(kind: PathTracer, world: world, back_col: back_col,
            randgen: randgen, num_ray: n_ray, max_depth: max_depth, 
            roulette_lim: roulette_lim) 


#------------------------------------------------------------#
#     Call procedure --> proc to solve rendering equation    #
#------------------------------------------------------------#
proc call*(rend: var Renderer, ray: Ray): Color =
    # Procedure that gives as output needed color
    # We can chose between OnOffRenderer, FlatRenderer and PathTracer

    case rend.kind
    of OnOffRenderer: 
        # Here we just see if we have hit or not, meaning we will give as
        # output background color if there isn't hit, or hit color when we hit a shape
        if fastIntersection(rend.world, ray): return rend.hit_col
        return rend.back_col

    of FlatRenderer:
        # Here we want to solve rendering equation using only pigment of each surface
        if not fastIntersection(rend.world, ray): 
            return rend.back_col

        var
            hit = rayIntersection(rend.world, ray).get
            mat = hit.material

        return mat.brdf.pigment.getColor(hit.surface_pt) + mat.radiance.getColor(hit.surface_pt)
            
    of PathTracer:
        # Here we actually want to solve rendering equation using roussian roulette
        # algorithm in order to avoid having infinite recursion

        # We first need to check how many reflections did ray had
        if (ray.depth > rend.max_depth): return newColor(0, 0, 0)

        # Storing ray intersection, we check over the whole scenery
        # Clearly we need to check wether intersection actually occured or not
        var hit = rend.world.rayIntersection(ray)
        if hit.isNone: return newColor(0, 0, 0)

        var
            mat_hit = hit.get.material
            col_hit = mat_hit.brdf.pigment.getColor(hit.get.surface_pt)
            rad_em = mat_hit.radiance.getColor(hit.get.surface_pt)
            lum = max(col_hit.r, max(col_hit.g, col_hit.b))
            rad = newColor(0, 0, 0)

        # We want to do russian roulette only if we happen to have a ray depth greater
        # than roulette_lim, otherwise ww will simply chechk for other reflection
        if ray.depth >= rend.roulette_lim:
            var q = max(0.05, 1 - lum)

            if (rend.randgen.rand() > q): col_hit = col_hit * 1/(1-q)
            else: return rad_em

        if lum > 0.0:
            var
                new_ray: Ray
                new_rad: Color 

            for i in 0..<rend.num_ray:
                new_ray = mat_hit.brdf.scatter_ray(rend.randgen, 
                              hit.get.ray.dir, hit.get.world_pt, hit.get.normal,
                              ray.depth + 1)
                new_rad = rend.call(new_ray)
                rad = rad + col_hit * new_rad

        return rad_em + rad * (1/rend.num_ray)


proc fire_all_rays*(tracer: var ImageTracer, rend: var Renderer) = 
    # Proc to have rendered image: here we are not using anti-aliasing

    for y in 0..<tracer.image.height:
        for x in 0..<tracer.image.width:
            tracer.image.setPixel(x, y, rend.call(tracer.fire_ray(x, y)))
        
        displayProgress(y + 1, tracer.image.height)
    stdout.eraseLine
    stdout.resetAttributes