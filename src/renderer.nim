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
            rgen*: PCG


proc newOnOffRenderer*(image: ptr HDRImage, camera: Camera, hitCol = WHITE): Renderer {.inline.} =
    Renderer(kind: rkOnOff, image: image, camera: camera, hitCol: hitCol,)

proc newFlatRenderer*(image: ptr HDRImage, camera: Camera): Renderer {.inline.} =
    Renderer(kind: rkFlat, image: image, camera: camera)

proc newPathTracer*(image: ptr HDRImage, camera: Camera, nRays = 25, maxDepth = 10, rouletteLim = 3, rgen = newPCG()): Renderer {.inline.} =
    Renderer(kind: rkPathTracer, image: image, camera: camera, 
        nRays: nRays, maxDepth: maxDepth, rgen: rgen,
        rouletteLim: rouletteLim)


proc displayProgress(current, total: int) =
    let
        percentage = int(100 * current / total)
        progress = 50 * current div total
        bar = "[" & "#".repeat(progress) & "-".repeat(50 - progress) & "]"
        color = if percentage <= 50: fgYellow else: fgGreen

    stdout.eraseLine
    stdout.styledWrite(fgWhite, "Rendering progress: ", fgRed, "0% ", fgWhite, bar, color, fmt" {percentage}%")
    stdout.flushFile



proc samplePixel(renderer: Renderer; scene: Scene, sceneTree: SceneTree, rg: var PCG, ray: Ray): Color =
    result = scene.bgCol

    let hitLeafNodes = sceneTree.root.getHitLeafNodes(ray)
    if hitLeafNodes.isSome:
        case renderer.kind
        of rkOnOff:
            for node in hitLeafNodes.get:
                for handler in node.handlers:
                    if checkIntersection(handler, ray): 
                        result = renderer.hitCol
                        break

        of rkFlat:
            let hitRecord = newHitRecord(hitLeafNodes.get, ray)
            if hitRecord.isSome:
                let
                    hit = hitRecord.get[0]
                    material = hit.shape[].material
                    hitPt = hit.ray.at(hit.t)
                    surfPt = hit.shape[].getUV(hitPt)

                result = material.brdf.pigment.getColor(surfPt) + material.radiance.getColor(surfPt)

        of rkPathTracer: 
            if (ray.depth > renderer.maxDepth): return BLACK

            let hitRecord = newHitRecord(hitLeafNodes.get, ray)
            if hitRecord.isNone: return BLACK
        
            let 
                hit = hitRecord.get[0]
                hitPt = hit.ray.at(hit.t)
                material = hit.shape[].material
                surfacePt = hit.shape[].getUV(hitPt)
                normal = hit.shape[].getNormal(hitPt, ray.dir)

                onb = newONB(normal)
                newTree = newSceneTree(scene.handlers, hitPt, onb, maxShapesPerLeaf = 4)
            
            var
                col_hit = material.brdf.pigment.getColor(surfacePt)
                rad_em = material.radiance.getColor(surfacePt)
                lum = max(col_hit.r, max(col_hit.g, col_hit.b))
                rad = BLACK

            if ray.depth >= renderer.roulette_lim:
                var q = max(0.05, 1 - lum)
 
                if (rg.rand > q): col_hit *= 1/(1-q)
                else: color = rad_em



            # color = renderer.call(scene, ray)

            # let hitRecord = newHitRecord(hitLeafNodes.get, ray)
            # if hitRecord.isNone: color = BLACK
            # else:
            #     let 
            #         hit = hitRecord.get[0]
            #         material = hit.shape[].material
            #         hitPt = hit.ray.at(hit.t)
            #         surfacePt = hit.shape[].getUV(hitPt)
            #     var
            #         col_hit = material.brdf.pigment.getColor(surfacePt)
            #         rad_em = material.radiance.getColor(surfacePt)
            #         lum = max(col_hit.r, max(col_hit.g, col_hit.b))
            #         rad = BLACK

            #     # We want to do russian roulette only if we happen to have a ray depth greater
            #     # than roulette_lim, otherwise ww will simply chechk for other reflection
            #     if ray.depth >= renderer.roulette_lim:
            #         var q = max(0.05, 1 - lum)

            #         if (rg.rand > q): col_hit *= 1/(1-q)
            #         else: color = rad_em

            #     if lum > 0.0:
            #         var
            #             new_ray: Ray
            #             new_rad: Color 

            #         for i in 0..<renderer.nRays:
            #             new_ray = material.brdf.scatter_ray(rg, hit.ray.dir, hitPt, hit.shape[].getNormal(hitPt, hit.ray.dir), ray.depth + 1)
            #             new_rad = renderer.call(new_ray)
            #             rad = rad + col_hit * new_rad

            #     color = rad_em + rad * (1/renderer.nRays)



proc sample*(renderer: Renderer; scene: Scene, samplesPerSide: int, rgState, rgSeq: uint64, displayProgress = true): PixelMap =
    var 
        rg = newPCG(rgState, rgSeq)
        sceneTree = newSceneTree(scene, renderer.camera.transform, maxShapesPerLeaf = 4)

    result = newPixelMap(renderer.image.width, renderer.image.height)

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
                    result[renderer.image[].pixelOffset(x, y)] = renderer.samplePixel(scene, sceneTree, rg, ray) #/ (samplesPerSide * samplesPerSide).float32 

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