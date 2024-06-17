import geometry, pcg, hdrimage, camera, scene, hitrecord

from std/strformat import fmt
from std/times import cpuTime
from std/strutils import repeat
import std/[options, terminal]


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


proc sampleRay(renderer: Renderer; sceneTree: SceneNode, worldRay: Ray, bgColor: Color, rg: var PCG): Color =
    result = bgColor
    
    let hitLeafNodes = sceneTree.getHitLeafs(worldRay)
    if hitLeafNodes.isSome:

        case renderer.kind
        of rkOnOff:
            for node in hitLeafNodes.get:
                for handler in node.handlers:
                    if handler.getHitPayload(worldRay.transform(handler.transformation.inverse)).isSome: 
                        result = renderer.hitCol
                        break

        of rkFlat:
            let hitRecord = hitLeafNodes.get.getHitRecord(worldRay)
            if hitRecord.isSome:
                let
                    hit = hitRecord.get[0]
                    material = hit.handler.shape.material
                    hitPt = hit.ray.at(hit.t)
                    surfPt = hit.handler.shape.getUV(hitPt)

                result = material.brdf.pigment.getColor(surfPt) + material.radiance.getColor(surfPt)

        of rkPathTracer: 
            if (worldRay.depth > renderer.maxDepth): return BLACK

            let hitRecord = hitLeafNodes.get.getHitRecord(worldRay)
            if hitRecord.isNone: return result

            let                
                closestHit = hitRecord.get[0]

                hitShape = closestHit.handler.shape
                hitWorldTransformation = closestHit.handler.transformation
                hitMaterial = hitShape.material

                shapeLocalHitPt = closestHit.ray.at(closestHit.t)
                shapeLocalHitNormal = hitShape.getNormal(shapeLocalHitPt, closestHit.ray.dir)
                
                surfacePt = hitShape.getUV(shapeLocalHitPt)
                
            result = hitMaterial.radiance.getColor(surfacePt)

            var hitCol = hitMaterial.brdf.pigment.getColor(surfacePt)
            if worldRay.depth >= renderer.rouletteLimit:
                let q = max(0.05, 1 - hitCol.luminosity)
                if rg.rand > q: hitCol /= (1.0 - q)
                else: return result

            if hitCol.luminosity > 0.0:

                var accumulatedRadiance = BLACK
                for _ in 0..<renderer.numRays: 
                    let scatteredRay = Ray(
                        origin: apply(hitWorldTransformation, shapeLocalHitPt), 
                        dir: apply(hitWorldTransformation, hitMaterial.brdf.scatterDir(closestHit.ray.dir, shapeLocalHitNormal, rg)),
                        tSpan: (1e-3.float32, Inf.float32),
                        depth: closestHit.ray.depth + 1
                    )

                    accumulatedRadiance += hitCol * renderer.sampleRay(sceneTree, scatteredRay, bgColor, rg)

                result += accumulatedRadiance / renderer.numRays.float32
    
    
proc sample*(
    renderer: Renderer; 
    scene: Scene, 
    rgState, rgSeq: uint64, samplesPerSide: int = 1, 
    treeKind: SceneTreeKind = tkBinary, maxShapesPerLeaf: int = 4,
    displayProgress = true): HDRImage =

    result = newHDRImage(renderer.camera.viewport.width, renderer.camera.viewport.height)
    var rg = newPCG(rgState, rgSeq)

    let 
        startTime = cpuTime()
        sceneTree = scene.getBVHTree(treeKind, maxShapesPerLeaf, rg)
    echo fmt"BVHTree builded in {cpuTime() - startTime}"
    echo "AABB ", sceneTree.aabb

    for y in 0..<renderer.camera.viewport.height:
        for x in 0..<renderer.camera.viewport.width:

            var accumulatedColor = BLACK
            for u in 0..<samplesPerSide:
                for v in 0..<samplesPerSide:

                    let ray = renderer.camera.fireRay(
                        newPoint2D(
                            (x.float32 + (u.float32 + rg.rand) / samplesPerSide.float32) / renderer.camera.viewport.width.float32,
                            1 - (y.float32 + (v.float32 + rg.rand) / samplesPerSide.float32) / renderer.camera.viewport.height.float32
                        )
                    )
                    # echo "fired new ray from the camera"
                    
                    accumulatedColor += renderer.sampleRay(sceneTree, ray, scene.bgCol, rg)

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