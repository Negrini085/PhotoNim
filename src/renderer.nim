import geometry, pcg, hdrimage, camera, shapes, scene, hitrecord

from std/strformat import fmt
from std/math import cos, sin, sqrt, PI
import std/[options, strutils, terminal]


type
    RendererKind* = enum
        rkOnOff, rkFlat, rkPathTracer

    Renderer* = object
        camera*: Camera

        case kind*: RendererKind
        of rkFlat: discard

        of rkOnOff:
            hitCol*: Color

        of rkPathTracer:
            nRays*, maxDepth*, rouletteLim*: int


proc newOnOffRenderer*(camera: Camera, hitCol = WHITE): Renderer {.inline.} =
    Renderer(kind: rkOnOff, camera: camera, hitCol: hitCol,)

proc newFlatRenderer*(camera: Camera): Renderer {.inline.} =
    Renderer(kind: rkFlat, camera: camera)

proc newPathTracer*(camera: Camera, nRays = 25, maxDepth = 10, rouletteLim = 3): Renderer {.inline.} =
    Renderer(kind: rkPathTracer, camera: camera, nRays: nRays, maxDepth: maxDepth, rouletteLim: rouletteLim)


proc displayProgress(current, total: int) =
    let
        percentage = int(100 * current / total)
        progress = 50 * current div total
        bar = "[" & "#".repeat(progress) & "-".repeat(50 - progress) & "]"
        color = if percentage <= 50: fgYellow else: fgGreen

    stdout.eraseLine
    stdout.styledWrite(fgWhite, "Rendering progress: ", fgRed, "0% ", fgWhite, bar, color, fmt" {percentage}%")
    stdout.flushFile


proc scatterRay*(refSystem: ReferenceSystem, brdf: BRDF, ray: Ray, rg: var PCG): Ray =
    case brdf.kind:
    of DiffuseBRDF:
        let 
            cos2 = rg.rand
            (c, s) = (sqrt(cos2), sqrt(1 - cos2))
            phi = 2 * PI * rg.rand
        
        Ray(
            origin: ORIGIN3D, 
            dir: refSystem.fromCoeff([float32 c * cos(phi), c * sin(phi), s]), 
            tSpan: (float32 1e-3, float32 Inf), 
            depth: ray.depth + 1
        )

    of SpecularBRDF: 
        Ray(
            origin: ORIGIN3D,
            dir: ray.dir.normalize - 2 * dot(refSystem.base[2], ray.dir.normalize) * refSystem.base[2],
            tspan: (float32 1e-3, float32 Inf), 
            depth: ray.depth + 1
        )


proc sampleRay(renderer: Renderer; ray: Ray, scene: Scene, maxShapesPerLeaf: int, rg: var PCG): Color =
    result = scene.bgCol

    let hitLeafNodes = scene.tree.getHitLeafs(ray)
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
                    material = hit.shape.material
                    hitPt = hit.ray.at(hit.t)
                    surfPt = hit.shape.getUV(hitPt)

                result = material.brdf.pigment.getColor(surfPt) + material.radiance.getColor(surfPt)

        of rkPathTracer: 
            if (ray.depth > renderer.maxDepth): return BLACK

            let hitRecord = newHitRecord(hitLeafNodes.get, ray)
            if hitRecord.isNone: return result
        
            let 
                hit = hitRecord.get[0]

                hitPt = hit.ray.at(hit.t)
                hitNormal = hit.shape.getNormal(hitPt, ray.dir)

                rs = newReferenceSystem(hitPt, hitNormal)
                localScene = scene.fromObserver(rs, maxShapesPerLeaf)

                material = hit.shape.material
                surfacePt = hit.shape.getUV(hitPt)
                
            result = material.radiance.getColor(surfacePt)

            var hitCol = material.brdf.pigment.getColor(surfacePt)
            if ray.depth >= renderer.rouletteLim:
                let q = max(0.05, 1 - hitCol.luminosity)
                if rg.rand > q: hitCol /= (1.0 - q)
                else: return result

            if hitCol.luminosity > 0.0:
                var accumulatedRadiance = BLACK
                for _ in 0..<renderer.nRays: 
                    let ray = rs.scatterRay(material.brdf, ray, rg)
                    accumulatedRadiance += hitCol * renderer.sampleRay(ray, localScene, maxShapesPerLeaf, rg)
                
                result += accumulatedRadiance / renderer.nRays.float32
        

proc sample*(renderer: Renderer; scene: Scene, rgState, rgSeq: uint64, samplesPerSide, maxShapesPerLeaf: int, displayProgress = true): HDRImage =
    result = newHDRImage(renderer.camera.viewport.width, renderer.camera.viewport.height)
            
    let cameraScene = scene.fromObserver(renderer.camera.rs, maxShapesPerLeaf)

    var rg = newPCG(rgState, rgSeq)
    for y in 0..<renderer.camera.viewport.height:
        for x in 0..<renderer.camera.viewport.width:
            var 
                accumulatedColor = BLACK
                ray: Ray

            for u in 0..<samplesPerSide:
                for v in 0..<samplesPerSide:
                    ray = renderer.camera.fireRay(
                        newPoint2D(
                            (x.float32 + (u.float32 + rg.rand) / samplesPerSide.float32) / renderer.camera.viewport.width.float32,
                            1 - (y.float32 + (v.float32 + rg.rand) / samplesPerSide.float32) / renderer.camera.viewport.height.float32
                        )
                    )
                    accumulatedColor += renderer.sampleRay(ray, cameraScene, maxShapesPerLeaf, rg)

            result.setPixel(x, y, accumulatedColor / (samplesPerSide * samplesPerSide).float32)
                            
        if displayProgress: displayProgress(y + 1, renderer.camera.viewport.height)
        
    if displayProgress: stdout.eraseLine; stdout.resetAttributes


# proc sampleParallel*(renderer: var Renderer; scene: Scene, samplesPerSide, nSnaps: int, rgState: uint64 = 42, rgSeq: uint64 = 54) =
#     proc sampleScene(imageLock: ptr Lock, renderer: ptr Renderer, scene: ptr Scene, samplesPerSide: int, rgState, rgSeq: uint64) =
#         withLock imageLock[]:
#             let sampleRays = renderer[].sample(scene[], samplesPerSide, rgState, rgSeq, displayProgress = false)
#             for i in 0..<renderer.image.height * renderer.image.width:
#                 renderer.image[].pixels[i] += sampleRays[i]

#     var rg = newPCG(rgState, rgSeq)
#     var imageLock: Lock; initLock(imageLock) 

#     for i in 0..<nSnaps: 
#         spawnX sampleScene(addr imageLock, addr renderer, addr scene, samplesPerSide, rg.random, rg.random)
#         displayProgress(i, nSnaps)

#     sync()
#     renderer.image[].pixels.apply(proc(pix: Color): Color = pix / nSnaps.float32)