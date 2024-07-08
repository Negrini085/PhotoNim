import geometry, pcg, hdrimage, material, scene, shape, hitrecord

from std/fenv import epsilon
from std/strutils import repeat
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
    
    Ray(origin: origin, dir: dir, tSpan: (epsilon(float32), float32 Inf), depth: 0).transform(camera.transformation)



proc displayProgress(current, total: int) =
    let
        percentage = int(100 * current / total)
        progress = 50 * current div total
        bar = "[" & repeat("#", progress) & repeat("-", 50 - progress) & "]"
        color = if percentage <= 50: fgYellow else: fgGreen

    stdout.eraseLine
    stdout.styledWrite(fgWhite, "Rendering progress: ", fgRed, "0% ", fgWhite, bar, color, fmt" {percentage}%")
    stdout.flushFile


proc sampleRay(camera: Camera; scene: Scene, worldRay: Ray, rg: var PCG): Color =
    result = scene.bgColor
    
    case camera.renderer.kind
    of rkOnOff: discard
    of rkFlat: discard

    of rkPathTracer: 
        if (worldRay.depth > camera.renderer.maxDepth): return BLACK

        let closestHitInfo = scene.tree.getClosestHit(scene.handlers, worldRay)
        if closestHitInfo.hit.isNil: return result

        let 
            invRay = worldRay.transform(closestHitInfo.hit.transformation.inverse)
            hitPt = invRay.at(closestHitInfo.t)
            hitNormal = closestHitInfo.hit.shape.getNormal(hitPt, invRay.dir)
            surfacePt = closestHitInfo.hit.shape.getUV(hitPt)
            
        result = closestHitInfo.hit.shape.material.radiance.getColor(surfacePt)

        var hitCol = closestHitInfo.hit.shape.material.brdf.pigment.getColor(surfacePt)
        if worldRay.depth >= camera.renderer.rouletteLimit:
            let q = max(0.05, 1 - hitCol.luminosity)
            if rg.rand > q: hitCol /= (1.0 - q)
            else: return result

        if hitCol.luminosity > 0.0:
            var accumulatedRadiance = BLACK
            for _ in 0..<camera.renderer.numRays:
                let 
                    outDir = closestHitInfo.hit.shape.material.brdf.scatterDir(hitNormal, invRay.dir, rg).normalize
                    scatteredRay = Ray(
                        origin: apply(closestHitInfo.hit.transformation, hitPt), 
                        dir: apply(closestHitInfo.hit.transformation, outDir),
                        tSpan: (1e-5.float32, Inf.float32),
                        depth: worldRay.depth + 1
                    )

                accumulatedRadiance += hitCol * camera.sampleRay(scene, scatteredRay, rg)

            result += accumulatedRadiance / camera.renderer.numRays.float32


proc sample*(camera: Camera; scene: Scene, rg: var PCG, samplesPerSide: int = 1, displayProgress = true): HDRImage =

    result = newHDRImage(camera.viewport.width, camera.viewport.height)

    for y in 0..<camera.viewport.height:
        if displayProgress: displayProgress(y, camera.viewport.height - 1)

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
                    
                    accumulatedColor += camera.sampleRay(scene, ray, rg)

            result.setPixel(x, y, accumulatedColor / (samplesPerSide * samplesPerSide).float32)
                                    
    if displayProgress: stdout.eraseLine; stdout.resetAttributes