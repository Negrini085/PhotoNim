import geometry, pcg, hdrimage, camera, shapes, scene, hitrecord

from std/strformat import fmt
import std/[options, strutils, terminal]


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

from std/math import cos, sin, sqrt, PI

proc scatterRay*(refSystem: ReferenceSystem, inWorldDir: Vec3f, depth: int, brdf: BRDF, rg: var PCG): Ray =
    case brdf.kind:
    of DiffuseBRDF:
        let 
            cos2 = rg.rand
            (c, s) = (sqrt(cos2), sqrt(1 - cos2))
            phi = 2 * PI * rg.rand
        
        return Ray(
            origin: ORIGIN3D,
            dir: refSystem.base.getVector(newVec3f(cos(phi) * c, sin(phi) * c, s)),
            tSpan: (float32 1e-3, float32 Inf), depth: depth + 1
        )

    of SpecularBRDF: 
        
        return Ray(
            origin: ORIGIN3D,
            dir: inWorldDir.normalize - 2 * dot(refSystem.base[2], inWorldDir.normalize) * refSystem.base[2],
            tspan: (float32 1e-3, float32 Inf), depth: depth + 1
        )

proc sampleRay(renderer: Renderer; ray: Ray, scene: Scene, sceneTree: SceneNode, maxShapesPerLeaf: int, rg: var PCG): Color =
    result = scene.bgCol
    let hitLeafNodes = sceneTree.getHitLeafs(ray)

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
            if (ray.depth > renderer.maxDepth): return result

            let hitRecord = newHitRecord(hitLeafNodes.get, ray)
            if hitRecord.isNone: return result
        
            let 
                hit = hitRecord.get[0]
                hitPt = hit.ray.at(hit.t)
                hitNormal = hit.shape[].getNormal(hitPt, ray.dir)
                hitRefSystem = newReferenceSystem(hitPt, createONB(hitNormal))
                localSceneTree = hitRefSystem.buildSceneTree(scene, maxShapesPerLeaf)

            let
                surfacePt = hit.shape[].getUV(hitPt)
                material = hit.shape[].material
                radiance = material.radiance.getColor(surfacePt)

            var accumulatedRadiance = BLACK
            if ray.depth >= renderer.rouletteLim:
                var hitCol = material.brdf.pigment.getColor(surfacePt)
                let q = max(0.05, 1 - max(hitCol.r, max(hitCol.g, hitCol.b)))
                if rg.rand < q: return radiance
                hitCol /= (1.0 - q)

                var newRay: Ray
                for _ in 0..<renderer.nRays:
                    newRay = hitRefSystem.scatterRay(ray.dir, ray.depth, material.brdf, rg)
                    accumulatedRadiance += hitCol * renderer.sampleRay(newRay, scene, localSceneTree, maxShapesPerLeaf, rg)

            return radiance + accumulatedRadiance / renderer.nRays.float32


proc sample*(renderer: Renderer; scene: Scene, maxShapesPerLeaf, samplesPerSide: int, rgState, rgSeq: uint64, displayProgress = true): PixelMap =
    result = newPixelMap(renderer.image.width, renderer.image.height)
    
    let camRefSystem = 
        case renderer.camera.kind
        of ckOrthogonal: newReferenceSystem(apply(renderer.camera.transform, newPoint3D(-1, 0, 0)), stdONB)
        of ckPerspective: newReferenceSystem(apply(renderer.camera.transform, newPoint3D(-renderer.camera.distance, 0, 0)), stdONB)

    let sceneTree = camRefSystem.buildSceneTree(scene, maxShapesPerLeaf)
    # let sceneTree = renderer.camera.refSystem.buildSceneTree(scene, maxShapesPerLeaf)

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
                    result[renderer.image[].pixelOffset(x, y)] = renderer.sampleRay(ray, scene, sceneTree, maxShapesPerLeaf, rg) / (samplesPerSide * samplesPerSide).float32 
                            
        if displayProgress: displayProgress(y + 1, renderer.image.height)
        
    if displayProgress: stdout.eraseLine; stdout.resetAttributes


proc sampleParallel*(renderer: var Renderer; scene: Scene, samplesPerSide, nSnaps: int, rgState: uint64 = 42, rgSeq: uint64 = 54) =
    proc sampleScene(imageLock: ptr Lock, renderer: ptr Renderer, scene: ptr Scene, samplesPerSide: int, rgState, rgSeq: uint64) =
        withLock imageLock[]:
            let sampleRays = renderer[].sample(scene[], samplesPerSide, rgState, rgSeq, displayProgress = false)
            for i in 0..<renderer.image.height * renderer.image.width:
                renderer.image[].pixels[i] += sampleRays[i]

    var rg = newPCG(rgState, rgSeq)
    var imageLock: Lock; initLock(imageLock) 

    for i in 0..<nSnaps: 
        spawnX sampleScene(addr imageLock, addr renderer, addr scene, samplesPerSide, rg.random, rg.random)
        displayProgress(i, nSnaps)

    sync()
    renderer.image[].pixels.apply(proc(pix: Color): Color = pix / nSnaps.float32)