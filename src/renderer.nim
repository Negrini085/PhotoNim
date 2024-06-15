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
            numRays*, maxDepth*, rouletteLimit*: int


proc newOnOffRenderer*(camera: Camera, hitCol = WHITE): Renderer {.inline.} =
    Renderer(kind: rkOnOff, camera: camera, hitCol: hitCol,)

proc newFlatRenderer*(camera: Camera): Renderer {.inline.} =
    Renderer(kind: rkFlat, camera: camera)

proc newPathTracer*(camera: Camera, numRays = 25, maxDepth = 10, rouletteLimit = 3): Renderer {.inline.} =
    Renderer(kind: rkPathTracer, camera: camera, numRays: numRays, maxDepth: maxDepth, rouletteLimit: rouletteLimit)


proc displayProgress(current, total: int) =
    let
        percentage = int(100 * current / total)
        progress = 50 * current div total
        bar = "[" & "#".repeat(progress) & "-".repeat(50 - progress) & "]"
        color = if percentage <= 50: fgYellow else: fgGreen

    stdout.eraseLine
    stdout.styledWrite(fgWhite, "Rendering progress: ", fgRed, "0% ", fgWhite, bar, color, fmt" {percentage}%")
    stdout.flushFile


proc scatterRay*(refSystem: ReferenceSystem, localRay: Ray, brdf: BRDF, rg: var PCG): Ray =
    case brdf.kind:
    of DiffuseBRDF:
        let 
            cos2 = rg.rand
            (c, s) = (sqrt(cos2), sqrt(1 - cos2))
            phi = 2 * PI * rg.rand
        
        Ray(
            origin: refSystem.origin, 
            dir: [float32 c * cos(phi), c * sin(phi), s], 
            tSpan: (float32 1e-3, float32 Inf), 
            depth: localRay.depth + 1
        )

    of SpecularBRDF: 
        Ray(
            origin: refSystem.origin,
            dir: localRay.dir - 2 * dot(refSystem.base[0], localRay.dir) * refSystem.base[0],
            tspan: (float32 1e-3, float32 Inf), 
            depth: localRay.depth + 1
        )


proc sampleRay(renderer: Renderer; scene: Scene, subScene: SubScene, ray: Ray, maxShapesPerLeaf: int, rg: var PCG): Color =
    result = scene.bgCol

    let hitLeafNodes = subScene.getHitLeafs(ray)
    if hitLeafNodes.isSome:

        case renderer.kind
        of rkOnOff:
            let worldRay = newRay(apply(newTranslation(subScene.rs.origin), ray.origin), subScene.rs.compose(ray.dir))

            for node in hitLeafNodes.get:
                for handler in node.handlers:
                    if handler.getHitPayload(worldRay.transform(handler.transformation.inverse)).isSome: 
                        result = renderer.hitCol
                        break

        of rkFlat:
            let hitRecord = subScene.rs.getHitRecord(ray, hitLeafNodes.get)
            if hitRecord.isSome:
                let
                    hit = hitRecord.get[0]
                    material = hit.handler.shape.material
                    hitPt = hit.ray.at(hit.t)
                    surfPt = hit.handler.shape.getUV(hitPt)

                result = material.brdf.pigment.getColor(surfPt) + material.radiance.getColor(surfPt)

        of rkPathTracer: 
            if (ray.depth > renderer.maxDepth): return BLACK

            let hitRecord = subScene.rs.getHitRecord(ray, hitLeafNodes.get)
            if hitRecord.isNone: return result

            let                
                closestHit = hitRecord.get[0]

                shapeLocalHitPt = closestHit.ray.at(closestHit.t)                                  
                hitNormal = closestHit.handler.shape.getNormal(shapeLocalHitPt, closestHit.ray.dir)
                surfacePt = closestHit.handler.shape.getUV(shapeLocalHitPt)
                material = closestHit.handler.shape.material

                localRS = newReferenceSystem(apply(closestHit.handler.transformation, shapeLocalHitPt), apply(closestHit.handler.transformation, hitNormal)) 
                localScene = scene.fromObserver(localRS, maxShapesPerLeaf)

                localRay = newRay(
                    apply(newComposition(newTranslation(localRS.origin), newTranslation(subScene.rs.origin).inverse), ray.origin), 
                    subScene.rs.project(localRS.compose(ray.dir)).normalize, 
                    # localRS.project(subScene.rs.compose(ray.dir)).normalize, 
                    closestHit.ray.depth
                )


            result = material.radiance.getColor(surfacePt)
            
            var hitCol = material.brdf.pigment.getColor(surfacePt)
            if ray.depth >= renderer.rouletteLimit:
                let q = max(0.05, 1 - hitCol.luminosity)
                if rg.rand > q: hitCol /= (1.0 - q)
                else: return result

            if hitCol.luminosity > 0.0:
                var accumulatedRadiance = BLACK
                for i in 0..<renderer.numRays: 
                    accumulatedRadiance += hitCol * renderer.sampleRay(scene, localScene, localRS.scatterRay(localRay, material.brdf, rg), maxShapesPerLeaf, rg)
                
                result += accumulatedRadiance / renderer.numRays.float32
    
    
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
                    accumulatedColor += renderer.sampleRay(scene, cameraScene, ray, maxShapesPerLeaf, rg)

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