import geometry, pcg, hdrimage, material, scene, shape, bvh, hitrecord

from std/algorithm import sorted 
from std/strutils import repeat
from std/options import isSome, isNone, get
from std/terminal import fgWhite, fgRed, fgYellow, fgGreen, eraseLine, styledWrite, resetAttributes
from std/strformat import fmt


type
    RendererKind* = enum
        rkOnOff, rkFlat, rkPathTracer

    Renderer* = object
        case kind*: RendererKind
        of rkFlat: discard

        of rkOnOff:
            hitCol*: Color

        of rkPathTracer:
            numRays*, maxDepth*, rouletteLimit*: int


    CameraKind* = enum
        ckOrthogonal, ckPerspective

    Camera* = object
        renderer*: Renderer

        viewport*: tuple[width, height: int]
        transformation*: Transformation

        case kind*: CameraKind
        of ckOrthogonal: discard
        of ckPerspective: 
            distance*: float32 



proc newFlatRenderer*(): Renderer {.inline.} = Renderer(kind: rkFlat)
proc newOnOffRenderer*(hitCol = WHITE): Renderer {.inline.} = Renderer(kind: rkOnOff, hitCol: hitCol)

proc newPathTracer*(numRays: SomeInteger = 25, maxDepth: SomeInteger = 10, rouletteLimit: SomeInteger = 3): Renderer {.inline.} =
    Renderer(kind: rkPathTracer, numRays: numRays, maxDepth: maxDepth, rouletteLimit: rouletteLimit)


proc newOrthogonalCamera*(renderer: Renderer, viewport: tuple[width, height: int], transformation = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckOrthogonal, renderer: renderer, viewport: viewport, transformation: transformation)

proc newPerspectiveCamera*(renderer: Renderer, viewport: tuple[width, height: int], distance: float32, transformation = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckPerspective, renderer: renderer, viewport: viewport, transformation: transformation, distance: distance)

proc aspectRatio*(camera: Camera): float32 {.inline.} = camera.viewport.width.float32 / camera.viewport.height.float32


proc fireRay*(camera: Camera; pixel: Point2D): Ray {.inline.} = 
    let (origin, dir) = 
        case camera.kind
        of ckOrthogonal: (newPoint3D(-1, (1 - 2 * pixel.u) * camera.aspectRatio, 2 * pixel.v - 1), eX)
        of ckPerspective: (newPoint3D(-camera.distance, 0, 0), newVec3f(camera.distance, (1 - 2 * pixel.u ) * camera.aspectRatio, 2 * pixel.v - 1))
    
    Ray(origin: origin, dir: dir, tSpan: (float32 1.0, float32 Inf), depth: 0).transform(camera.transformation)



proc displayProgress(current, total: int) =
    let
        percentage = int(100 * current / total)
        progress = 50 * current div total
        bar = "[" & repeat("#", progress) & repeat("-", 50 - progress) & "]"
        color = if percentage <= 50: fgYellow else: fgGreen

    stdout.eraseLine
    stdout.styledWrite(fgWhite, "Rendering progress: ", fgRed, "0% ", fgWhite, bar, color, fmt" {percentage}%")
    stdout.flushFile


proc sampleRay(camera: Camera; scene: Scene, sceneTree: BVHNode, worldRay: Ray, rg: var PCG): Color =
    result = scene.bgColor
    
    let hitLeafNodes = sceneTree.getHitLeafs(worldRay)
    if hitLeafNodes.isNone: return result

    case camera.renderer.kind
    of rkOnOff:
        for node in hitLeafNodes.get:
            for handler in node.handlers:
                if handler.getHitPayload(worldRay.transform(handler.transformation.inverse)).isSome: 
                    result = camera.renderer.hitCol
                    break

    of rkFlat:
        let hitRecord = hitLeafNodes.get.getHitRecord(worldRay)
        if hitRecord.isSome:
            let
                hit = hitRecord.get.sorted(proc(a, b: HitPayload): int = cmp(a.t, b.t))[0]
                material = hit.handler.shape.material
                hitPt = hit.ray.at(hit.t)
                surfPt = hit.handler.shape.getUV(hitPt)

            result = material.brdf.pigment.getColor(surfPt) + material.radiance.getColor(surfPt)

    of rkPathTracer: 
        if (worldRay.depth > camera.renderer.maxDepth): return BLACK

        let hitRecord = hitLeafNodes.get.getHitRecord(worldRay)
        if hitRecord.isNone: return result

        let                
            closestHit = hitRecord.get.sorted(proc(a, b: HitPayload): int = cmp(a.t, b.t))[0]

            shapeLocalHitPt = closestHit.ray.at(closestHit.t)
            shapeLocalHitNormal = closestHit.handler.shape.getNormal(shapeLocalHitPt, closestHit.ray.dir)
            
            surfacePt = closestHit.handler.shape.getUV(shapeLocalHitPt)
            
        result = closestHit.handler.shape.material.radiance.getColor(surfacePt)

        var hitCol = closestHit.handler.shape.material.brdf.pigment.getColor(surfacePt)
        if worldRay.depth >= camera.renderer.rouletteLimit:
            let q = max(0.05, 1 - hitCol.luminosity)
            if rg.rand > q: hitCol /= (1.0 - q)
            else: return result

        if hitCol.luminosity > 0.0:
            var accumulatedRadiance = BLACK
            for _ in 0..<camera.renderer.numRays: 
                let scatteredRay = Ray(
                    origin: apply(closestHit.handler.transformation, shapeLocalHitPt), 
                    dir: apply(closestHit.handler.transformation, closestHit.handler.shape.material.brdf.scatterDir(closestHit.ray.dir, shapeLocalHitNormal, rg)),
                    tSpan: (1e-3.float32, Inf.float32),
                    depth: closestHit.ray.depth + 1
                )

                accumulatedRadiance += hitCol * camera.sampleRay(scene, sceneTree, scatteredRay, rg)

            result += accumulatedRadiance / camera.renderer.numRays.float32


proc sample*(camera: Camera; scene: Scene, rgState, rgSeq: uint64, samplesPerSide: int = 1, treeKind: TreeKind = tkBinary, maxShapesPerLeaf: int = 4, displayProgress = true): HDRImage =

    result = newHDRImage(camera.viewport.width, camera.viewport.height)
    var rg = newPCG(rgState, rgSeq)

    let sceneTree = scene.getBVHTree(treeKind, maxShapesPerLeaf, rg)
    echo sceneTree.aabb

    for y in 0..<camera.viewport.height:
        for x in 0..<camera.viewport.width:

            var accumulatedColor = BLACK
            for u in 0..<samplesPerSide:
                for v in 0..<samplesPerSide:

                    let ray = camera.fireRay(
                        newPoint2D(
                            (x.float32 + (u.float32 + rg.rand) / samplesPerSide.float32) / camera.viewport.width.float32,
                            1 - (y.float32 + (v.float32 + rg.rand) / samplesPerSide.float32) / camera.viewport.height.float32
                        )
                    )
                    
                    accumulatedColor += camera.sampleRay(scene, sceneTree, ray, rg)

            result.setPixel(x, y, accumulatedColor / (samplesPerSide * samplesPerSide).float32)
                            
        if displayProgress: displayProgress(y + 1, camera.viewport.height)
        
    if displayProgress: stdout.eraseLine; stdout.resetAttributes