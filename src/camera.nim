import pcg, geometry, color, hdrimage, brdf, pigment, scene, shape, hitrecord

from std/fenv import epsilon
from std/strutils import repeat
from std/terminal import fgWhite, fgRed, fgYellow, fgGreen, eraseLine, styledWrite, resetAttributes
from std/strformat import fmt
from std/math import pow
from std/sequtils import applyIt, filterIt

from std/threadpool import parallel, spawn, spawnX, sync
{.experimental.}

type
    RendererKind* = enum
        rkOnOff, rkFlat, rkPathTracer

    Renderer* = object
        case kind*: RendererKind
        of rkFlat: discard

        of rkOnOff: hitColor*: Color

        of rkPathTracer:
            nRays*, depthLimit*, rouletteLimit*: int


    CameraKind* = enum ckOrthogonal, ckPerspective
    Camera* = object
        renderer*: Renderer

        viewport*: tuple[width, height: int]
        transformation*: Transformation

        case kind*: CameraKind
        of ckOrthogonal: discard
        of ckPerspective: 
            distance*: float32 



proc newFlatRenderer*(): Renderer {.inline.} = Renderer(kind: rkFlat)
proc newOnOffRenderer*(hitColor = WHITE): Renderer {.inline.} = Renderer(kind: rkOnOff, hitColor: hitColor)

proc newPathTracer*(nRays, depthLimit, rouletteLimit: SomeInteger): Renderer {.inline.} =
    Renderer(kind: rkPathTracer, nRays: nRays, depthLimit: depthLimit, rouletteLimit: rouletteLimit)

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
    
    case camera.renderer.kind
    of rkOnOff: 
        let closestHit = scene.tree.getClosestHit(worldRay)
        if closestHit.info.hit.isNil: return scene.bgColor
        else: return camera.renderer.hitColor

    of rkFlat: 
        let closestHit = scene.tree.getClosestHit(worldRay)
        if closestHit.info.hit.isNil: return scene.bgColor
        elif closestHit.info.hit.brdf.isNil: 
            return closestHit.info.hit.emittedRadiance.getColor(closestHit.info.hit.shape.getUV(closestHit.pt))
        else: 
            return closestHit.info.hit.brdf.pigment.getColor(closestHit.info.hit.shape.getUV(closestHit.pt))

    of rkPathTracer: 
        if (worldRay.depth > camera.renderer.depthLimit): return BLACK

        let closestHit = scene.tree.getClosestHit(worldRay)
        if closestHit.info.hit.isNil: return scene.bgColor
        
        let 
            hitNormal = closestHit.info.hit.shape.getNormal(closestHit.pt, closestHit.rayDir)
            hitSurfacePt = closestHit.info.hit.shape.getUV(closestHit.pt)
            worldHitPt = apply(closestHit.info.hit.transformation, closestHit.pt)

        result = closestHit.info.hit.emittedRadiance.getColor(hitSurfacePt)

        if closestHit.info.hit.brdf.isNil: return result

        var hitColor = closestHit.info.hit.brdf.pigment.getColor(hitSurfacePt)
        if areClose(hitColor.luminosity, 0): return result
        
        if worldRay.depth >= camera.renderer.rouletteLimit:
            let q = max(0.05, 1 - hitColor.luminosity)
            if rg.rand > q: hitColor /= (1.0 - q)
            else: return result

        let nRaysInv = 1 / camera.renderer.nRays.float32
        for _ in 0..<camera.renderer.nRays:
            let 
                outDir = closestHit.info.hit.brdf.scatterDir(hitNormal, closestHit.rayDir, rg).normalize
                scatteredRay = Ray(
                    origin: worldHitPt, 
                    dir: apply(closestHit.info.hit.transformation, outDir),
                    tSpan: (1e-5.float32, Inf.float32),
                    depth: worldRay.depth + 1
                )

            result += nRaysInv * hitColor * camera.sampleRay(scene, scatteredRay, rg)


proc samplePixel(x, y: int, camera: Camera, scene: Scene, rgSetUp: RandomSetUp, aaSamples: int): Color =
    let aaFactor = 1 / aaSamples.float32

    var rg = newPCG(rgSetUp)
    for u in 0..<aaSamples:
        for v in 0..<aaSamples:
            let ray = camera.fireRay(
                newPoint2D(
                    (x.float32 + (u.float32 + rg.rand) * aaFactor) / camera.viewport.width.float32,
                    1 - (y.float32 + (v.float32 + rg.rand) * aaFactor) / camera.viewport.height.float32
                )
            )

            result += camera.sampleRay(scene, ray, rg)
    
    result *= pow(aaFactor, 2)


proc sample*(camera: Camera; scene: Scene, rgSetUp: RandomSetUp, aaSamples: int = 1, displayProgress = true): HDRImage =
    var rg = newPCG(rgSetUp)

    result = newHDRImage(camera.viewport.width, camera.viewport.height)
    for y in 0..<camera.viewport.height:
        if displayProgress: displayProgress(y, camera.viewport.height - 1)
        for x in 0..<camera.viewport.width: 
            result.setPixel(
                x, y,
                samplePixel(x, y, camera, scene, newRandomSetUp(rg.random, rg.random), aaSamples)
            )

    if displayProgress: stdout.eraseLine; stdout.resetAttributes


proc samples*(camera: Camera; scene: Scene, rgSetUp: RandomSetUp, nSamples: int = 1, aaSamples: int = 1, displayProgress = true): HDRImage =
    result = newHDRImage(camera.viewport.width, camera.viewport.height)

    if nSamples > 1:

        var rg = newPCG(rgSetUp)
        for _ in countup(0, nSamples): 
            spawnX stack(
                addr result, 
                camera.sample(scene, newRandomSetUp(rg.random, rg.random), aaSamples, displayProgress = false)
            )
        
        sync()
        result.pixels.applyIt(it / nSamples.float32)

    else: result = camera.sample(scene, rgSetUp, aaSamples, displayProgress = true)