import geometry, pcg, hdrimage, camera, shapes, scene, hitrecord

from std/strformat import fmt
from std/times import cpuTime
from std/sequtils import apply
import std/[options, strutils, threadpool, locks, terminal]


type
    RendererKind* = enum
        rkOnOff, rkFlat, rkPathTracer

    Renderer* = object
        image*: ptr HDRImage
        camera*: Camera

        case kind*: RendererKind
        of rkFlat: discard

        of rkOnOff:
            hitCol*: Color

        of rkPathTracer:
            nRays*, maxDepth*, rouletteLim*: int


proc newOnOffRenderer*(image: ptr HDRImage, camera: Camera, hitCol = WHITE): Renderer {.inline.} =
    Renderer(kind: rkOnOff, image: image, camera: camera, hitCol: hitCol,)

proc newFlatRenderer*(image: ptr HDRImage, camera: Camera): Renderer {.inline.} =
    Renderer(kind: rkFlat, image: image, camera: camera)

proc newPathTracer*(image: ptr HDRImage, camera: Camera, nRays = 25, maxDepth = 10, rouletteLim = 3): Renderer {.inline.} =
    Renderer(kind: rkPathTracer, image: image, camera: camera, nRays: nRays, maxDepth: maxDepth, rouletteLim: rouletteLim)


proc sampleRay(renderer: ptr Renderer, scene: ptr Scene, ray: Ray): Color =
    result = scene.bgCol
    if ray.intersect(scene.tree.root):
        case renderer.kind
        of rkOnOff:
            result = renderer.hitCol

        of rkFlat:
            let hitRecord = newHitRecord(scene, ray)
            if hitRecord.isSome:
                let
                    hit = hitRecord.get[0]
                    material = hit.shape[].material
                    hitPt = hit.ray.at(hit.t)
                    surfPt = hit.shape[].getUV(hitPt)

                result = material.brdf.pigment.getColor(surfPt) + material.radiance.getColor(surfPt)

        of rkPathTracer:
            discard
            # if (ray.depth > renderer.maxDepth): return BLACK

            # # Storing ray intersection, we check over the whole scene
            # # Clearly we need to check wether intersection actually occured or not
            # var hit = world.rayIntersection(ray)
            # if hit.isNone: return BLACK

            # var
            #     mat_hit = hit.get.material
            #     col_hit = mat_hit.brdf.pigment.getColor(hit.get.surface_pt)
            #     rad_em = mat_hit.radiance.getColor(hit.get.surface_pt)
            #     lum = max(col_hit.r, max(col_hit.g, col_hit.b))
            #     rad = BLACK

            # # We want to do russian roulette only if we happen to have a ray depth greater
            # # than rouletteLim, otherwise ww will simply chechk for other reflection
            # if ray.depth >= renderer.rouletteLim:
            #     var q = max(0.05, 1 - lum)

            #     if (renderer.rg.rand() > q): col_hit = col_hit * 1/(1-q)
            #     else: return rad_em

            # if lum > 0.0:
            #     var
            #         new_ray: Ray
            #         new_rad: Color

            #     for i in 0..<renderer.nRays:
            #         new_ray = mat_hit.brdf.scatterRay(renderer.rg,
            #                     hit.get.ray.dir, hit.get.world_pt, hit.get.normal,
            #                     ray.depth + 1)
            #         new_rad = renderer.call(new_ray)
            #         rad = rad + col_hit * new_rad

            # return rad_em + rad * (1/renderer.nRays)


proc sample(renderer: ptr Renderer; scene: ptr Scene, pixOffset: Point2D): PixelMap =
    result = newPixelMap(renderer.image.width, renderer.image.height)

    for y in 0..<renderer.image.height:
        for x in 0..<renderer.image.width:
            let ray = renderer.camera.fireRay(
                newPoint2D(
                    (x.float32 + pixOffset.u) / renderer.image.width.float32,
                    1 - (y.float32 + pixOffset.v) / renderer.image.height.float32
                )
            )

            result[renderer.image[].pixelOffset(x, y)] = renderer.sampleRay(scene, ray)


proc render*(scene: var Scene; renderer: var Renderer, maxShapesPerLeaf = 4, samplesPerSide = 4, rgState = 42, rgSeq = 54) =
    let startTime = cpuTime()

    scene.buildTree(renderer.camera.transform, maxShapesPerLeaf)

    var rg = newPCG(rgState.uint64, rgSeq.uint64)
    var completedTasks = 0

    proc displayProgress(current, total: int) =
        let
            percentage = int(100 * current / total)
            progress = 50 * current div total
            bar = "[" & "#".repeat(progress) & "-".repeat(50 - progress) & "]"
            color = if percentage <= 50: fgYellow else: fgGreen

        stdout.eraseLine
        stdout.styledWrite(fgWhite, "Rendering progress: ", fgRed, "0% ", fgWhite, bar, color, fmt" {percentage}%")
        stdout.flushFile

    var imageLock, progressLock: Lock
    initLock(imageLock)
    initLock(progressLock)

    proc `+=`(a: var PixelMap, b: PixelMap) = 
        assert a.len == b.len, fmt"Cannot sum two PixelMap with different sizes."
        for i in 0..<a.len: a[i] += b[i]

    proc task(scene: ptr Scene, renderer: ptr Renderer, imageLock, progressLock: ptr Lock, completedTasks: ptr int, rgState, rgSeq: uint64, u, v, samplesPerSide: int) =
        var rg = newPCG(rgState, rgSeq)
        let pixOffset = newPoint2D((u.float32 + rg.rand) / samplesPerSide.float32, (v.float32 + rg.rand) / samplesPerSide.float32)

        withLock imageLock[]:
            renderer.image[].pixels += renderer.sample(scene, pixOffset)

        withLock progressLock[]: 
            completedTasks[] += 1
            displayProgress(completedTasks[], samplesPerSide * samplesPerSide)

    for u in 0..<samplesPerSide:
        for v in 0..<samplesPerSide:
            spawn task(addr scene, addr renderer, addr imageLock, addr progressLock, addr completedTasks, rg.random, rg.random, u, v, samplesPerSide)

    sync()
    renderer.image[].pixels.apply(proc(pix: Color): Color = pix / (samplesPerSide * samplesPerSide).float32)

    stdout.eraseLine
    stdout.resetAttributes

    echo fmt"Successfully rendered image in {cpuTime() - startTime} seconds." # not so sure this is working...