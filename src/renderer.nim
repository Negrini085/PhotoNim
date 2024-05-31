import geometry, pcg, hdrimage, camera, scene, hitrecord

from std/strformat import fmt
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


proc displayProgress(current, total: int) =
    let
        percentage = int(100 * current / total)
        progress = 50 * current div total
        bar = "[" & "#".repeat(progress) & "-".repeat(50 - progress) & "]"
        color = if percentage <= 50: fgYellow else: fgGreen

    stdout.eraseLine
    stdout.styledWrite(fgWhite, "Rendering progress: ", fgRed, "0% ", fgWhite, bar, color, fmt" {percentage}%")
    stdout.flushFile


proc sample*(renderer: Renderer; scene: Scene, samplesPerSide: int, 
                rgState: uint64 = 42, rgSeq: uint64 = 54, displayProgress = true): PixelMap =

    result = newPixelMap(renderer.image.width, renderer.image.height)
    let sceneTree = newSceneTree(addr scene, maxShapesPerLeaf = 4)

    var rg = newPCG(rgState, rgSeq)

    for y in 0..<renderer.image.height:
        for x in 0..<renderer.image.width:
            for u in 0..<samplesPerSide:
                for v in 0..<samplesPerSide:
                            
                    let ray = renderer.camera.fireRay(
                        newPoint2D(
                            (x.float32 + (u.float32 + rg.rand) / samplesPerSide.float32) / renderer.image.width.float32,
                            1 - (y.float32 + (v.float32 + rg.rand) / samplesPerSide.float32) / renderer.image.height.float32
                        )
                    )
                    
                    var color = scene.bgCol
                    if ray.intersect(sceneTree.root):
                        case renderer.kind
                        of rkOnOff: color = renderer.hitCol

                        of rkFlat:
                            let hitRecord = newHitRecord(addr scene, ray)
                            if hitRecord.isSome:
                                let
                                    hit = hitRecord.get[0]
                                    material = hit.shape[].material
                                    hitPt = hit.ray.at(hit.t)
                                    surfPt = hit.shape[].getUV(hitPt)

                                color = material.brdf.pigment.getColor(surfPt) + material.radiance.getColor(surfPt)

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

                    result[renderer.image[].pixelOffset(x, y)] = color #/ (samplesPerSide * samplesPerSide).float32 

                    # for shape in scene.getAllShapes:
                    #     if ray.intersect(newAABox(shape.getAABB(shape.transform))):
                    #         result[renderer.image[].pixelOffset(x, y)] += newColor(0.4, 0.0, 0.0)
                            
        if displayProgress: displayProgress(y + 1, renderer.image.height)
        
    if displayProgress: stdout.eraseLine; stdout.resetAttributes


proc sampleParallel*(renderer: var Renderer; scene: Scene, samplesPerSide, nSnaps: int, rgState: uint64 = 42, rgSeq: uint64 = 54) =
    proc sampleScene(imageLock: ptr Lock, renderer: ptr Renderer, scene: ptr Scene, samplesPerSide: int, rgState, rgSeq: uint64) =
        withLock imageLock[]:
            let samplePixels = renderer[].sample(scene[], samplesPerSide, rgState, rgSeq, displayProgress = false)
            for i in 0..<renderer.image.height * renderer.image.width:
                renderer.image[].pixels[i] += samplePixels[i]

    var rg = newPCG(rgState, rgSeq)
    var imageLock: Lock; initLock(imageLock) 

    for i in 0..<nSnaps: 
        spawnX sampleScene(addr imageLock, addr renderer, addr scene, samplesPerSide, rg.random, rg.random)
        displayProgress(i, nSnaps)

    sync()
    renderer.image[].pixels.apply(proc(pix: Color): Color = pix / nSnaps.float32)